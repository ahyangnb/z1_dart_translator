# 显微镜翻译引擎算法讲解

这份文档面向刚开始学习编程、自然语言处理或 Dart 的读者。它把项目里每一步算法都摊开讲：输入一句话之后，程序如何判断语言、切词、查词典、套语法规则，最后渲染成译文。

这个项目故意做得很小。它不是为了替代真正的在线翻译，而是像显微镜一样，把翻译流水线中常见的环节展示出来。

## 一句话总览

入口在 `bin/z1_translate.dart`，核心引擎在 `lib/engine.dart`。

完整流程是：

```text
原文
  -> 判断源语言和目标语言
  -> 分词 tokenization
  -> 词典查找 lexical lookup
  -> 生成翻译单元 translation units
  -> 应用语法规则
  -> 渲染成目标语言句子
  -> 输出显微镜报告
```

对应代码：

| 阶段       | 文件                          | 做什么                         |
|----------|-----------------------------|-----------------------------|
| 命令行入口    | `bin/z1_translate.dart`     | 解析参数，调用翻译器，打印报告             |
| 总调度      | `lib/engine.dart`           | 串起语言判断、分词、分析、规则和渲染          |
| 语言判断     | `lib/language.dart`         | 用字符数量粗略判断中文或英文              |
| 分词       | `lib/tokenizer.dart`        | 把字符串切成 token，并识别词、短语、数字、标点  |
| token 类型 | `lib/token.dart`            | 定义 token 和词性枚举              |
| 词典       | `lib/lexicon.dart`          | 保存中英双向词条、词性和教学说明            |
| 词典分析     | `lib/analyzer.dart`         | 给每个 token 找翻译、词性、说明和省略标记    |
| 翻译单元     | `lib/translation_unit.dart` | 规则引擎处理的中间数据结构               |
| 语法规则     | `lib/rules.dart`            | 处理所有格、助词省略、be 变形、to、冠词等     |
| 渲染       | `lib/renderer.dart`         | 根据目标语言拼接文本、调整标点和空格          |
| 结果       | `lib/result.dart`           | 保存输出和每一步 trace              |
| 对外导出     | `lib/translator.dart`       | 统一 export，方便外部只 import 一个文件 |

## 运行入口如何工作

`bin/z1_translate.dart` 是用户真正运行的文件：

```bash
dart run bin/z1_translate.dart "我喜欢学习自然语言处理。"
```

它做三件事：

1. 如果参数里有 `--help` 或 `-h`，打印用法。
2. 用 `_parseArgs` 解析 `--from=zh|en`、`--to=zh|en` 和正文。
3. 创建 `MicroscopeTranslator()`，调用 `translate`，把 `TranslationResult.toMicroscopeReport()` 打印出来。

如果没有传入正文，程序使用默认句子：

```text
我喜欢学习自然语言处理。
```

如果没有指定 `--from` 和 `--to`，引擎会自动判断源语言，再把目标语言设成源语言的相反方向。

## 总调度：MicroscopeTranslator

`lib/engine.dart` 里的 `MicroscopeTranslator.translate` 是总控函数。它的算法可以写成伪代码：

```text
source = 用户指定的源语言，或者自动判断
target = 用户指定的目标语言，或者 source 的相反语言

tokenizer = MicroscopeTokenizer(lexicon)
analyzer = TokenAnalyzer(lexicon)

tokens = tokenizer.tokenize(source, text)
analyzedTokens = analyzer.analyze(source, tokens)
ruleResult = ruleEngine.apply(source, analyzedTokens)
output = renderer.render(target, ruleResult.units)

return TranslationResult(...)
```

这段代码的关键思想是分层：

- 分词器只关心“怎么切开文本”。
- 分析器只关心“词典里有没有这个词”。
- 规则引擎只关心“词序和语法如何变得更自然”。
- 渲染器只关心“最后怎么拼成一段目标语言文字”。

这样拆开以后，每一步都可以单独观察，这就是“显微镜翻译引擎”的名字来源。

## 语言判断算法

代码在 `lib/language.dart`。

`detectLanguage` 会遍历输入文本的每个 Unicode rune，并分别统计：

- CJK 字符数量：中文常用汉字区间 `0x4E00..0x9FFF`，以及扩展区间 `0x3400..0x4DBF`。
- 拉丁字母数量：`A..Z` 和 `a..z`。

算法规则：

```text
如果没有中文字符，也没有英文字母：
  默认中文
否则：
  中文字符数量 >= 英文字母数量 -> 中文
  英文字母数量更多 -> 英文
```

例子：

| 输入          | CJK 数 | Latin 数 | 判断 |
|-------------|------:|--------:|----|
| `我喜欢 Dart`  |     3 |       4 | 英文 |
| `我喜欢学习`     |     4 |       0 | 中文 |
| `I like AI` |     0 |       7 | 英文 |
| `123!?`     |     0 |       0 | 中文 |

这个算法很简单，适合教学。它没有做复杂的语言检测，所以中英混写时可能判断得很粗糙。如果需要稳定结果，可以在命令行里显式传 `--from=zh` 或 `--from=en`。

## 词典如何组织

代码在 `lib/lexicon.dart`。

`LexiconEntry` 是一个词条。每个词条包含：

- `source`：源语言里的词或短语。
- `sourceLanguage`：这个词条属于中文还是英文。
- `target`：目标语言翻译。
- `partOfSpeech`：词性，例如名词、动词、代词。
- `note`：给显微镜报告看的解释。
- `omitInTarget`：翻译到目标语言时是否省略。

例如中文助词：

```dart
LexiconEntry.zh('的', '', PartOfSpeech.particle, '结构助词，常由英文词序或所有格表达',
    omitInTarget: true)
```

它的意思是：

- 中文 `的` 是结构助词。
- 它不一定要翻译成某个英文单词。
- 在输出里先省略，但规则引擎可以解释为什么省略。

`TinyTranslationLexicon.standard()` 会做两件重要的预处理。

### 1. 建立查找表

词典会被整理成：

```text
Map<Language, Map<String, LexiconEntry>>
```

也就是：

```text
中文 -> { 归一化词: 词条 }
英文 -> { 归一化词: 词条 }
```

查找时先根据语言选表，再用归一化后的词作为 key。

### 2. 给源词按长度排序

中文分词需要优先匹配长词，例如：

```text
自然语言处理
自然
语言
处理
```

如果词典里有长短多个候选，应该先匹配 `自然语言处理`，否则就可能被拆碎。

所以词典会把每种语言的源词列表按长度降序排序：

```text
长短语排前面，短词排后面
```

这为中文的最长匹配分词服务，也为英文短语合并提供最大短语长度。

## 归一化 normalize

归一化的代码是 `TinyTranslationLexicon.normalizeTerm`。

中文归一化：

```text
trim 去掉两端空白
```

英文归一化：

```text
trim 去掉两端空白
toLowerCase 转小写
连续空白合并成一个空格
```

这样 `Natural   Language Processing` 会归一化成：

```text
natural language processing
```

词典里只需要存一份小写形式，用户大小写和空格有差异时仍然能查到。

## 分词算法

代码在 `lib/tokenizer.dart`。

分词器的任务是把字符串变成 `List<Token>`。`Token` 在 `lib/token.dart` 里定义，包含：

- `text`：原文片段。
- `normalized`：归一化后的片段。
- `kind`：词、短语、数字、标点或未知。
- `start` / `end`：在原字符串里的位置。

### 中文分词：最长词典匹配

中文不像英文那样天然用空格分词，所以这里使用一个简单的最长匹配算法。

伪代码：

```text
把文本拆成字符列表 chars
i = 0

while i < chars.length:
  char = chars[i]

  如果 char 是空白:
    跳过

  如果 char 是标点:
    生成 punctuation token
    i += 1

  如果 char 是 ASCII 字母、数字、下划线或连字符:
    连续读取这些字符
    生成英文词或数字 token

  否则:
    remaining = 从 i 开始的剩余字符串
    在词典源词里按长到短查找第一个 startsWith 的词

    如果找到 matched:
      生成 word 或 phrase token
      i += matched 的字符数
    如果没找到:
      当前字符生成 unknown token
      i += 1
```

例子：

```text
输入：我喜欢学习自然语言处理。
输出：
我 / 喜欢 / 学习 / 自然语言处理 / 。
```

`自然语言处理` 会被整体切出来，因为它在词典里，并且长词优先。

### 英文分词：正则先切，再合并短语

英文分词分两步。

第一步用正则表达式切出原始 token：

```text
[A-Za-z]+(?:'[A-Za-z]+)?    英文单词，允许 don't 这样的撇号
\d+(?:\.\d+)?               整数或小数
[^\sA-Za-z\d]               其他非空白、非字母、非数字字符，作为标点或未知字符
```

第二步调用 `_groupEnglishPhrases` 合并词典里的英文短语。

伪代码：

```text
rawTokens = 正则切出来的 token
maxPhraseSize = 英文词典里最长短语的词数
i = 0

while i < rawTokens.length:
  如果当前 token 不是 word:
    直接加入结果

  否则:
    从 maxPhraseSize 到 2 递减尝试
      取 rawTokens[i..i+size]
      如果这段里全是 word:
        用空格拼成 phrase
        如果词典能查到 phrase:
          合并成 phrase token
          i += phrase 的词数
          停止尝试

    如果没有匹配短语:
      保留当前单词
      i += 1
```

例子：

```text
输入：I like natural language processing.
正则初切：I / like / natural / language / processing / .
短语合并：I / like / natural language processing / .
```

这里也使用“最长优先”的思想。先试长短语，可以避免把 `large language model` 误拆成 `language model` 加其他词。

## 词典分析算法

代码在 `lib/analyzer.dart`。

`TokenAnalyzer` 会把 `Token` 变成 `AnalyzedToken`。它不会改变词序，也不会套语法规则，只做“这是什么东西”的判断。

处理逻辑：

```text
如果 token 是标点:
  targetText = 原标点
  partOfSpeech = punctuation
  note = 标点先保留，最后由渲染器按目标语言调整

如果 token 是数字:
  targetText = 原数字
  partOfSpeech = number
  note = 数字通常跨语言保留

否则:
  用 sourceLanguage 和 token.normalized 查词典

  如果查不到:
    targetText = 原文
    partOfSpeech = unknown
    note = 词典未收录，先原样保留

  如果查到:
    targetText = entry.target
    partOfSpeech = entry.partOfSpeech
    note = entry.note
    omitInTarget = entry.omitInTarget
```

`isKnown` 的含义是：

```text
查到词典，或者它是标点 -> 已知
否则 -> 未知
```

未知词不会让程序失败。教学引擎会保留原文，让你在显微镜报告里看到词典缺口。

## 翻译单元 TranslationUnit

代码在 `lib/translation_unit.dart`。

规则引擎不直接修改 `AnalyzedToken`，而是先把它们转换成 `TranslationUnit`。

`TranslationUnit` 是规则阶段的工作单元，包含：

- `sourceText`：原文。
- `targetText`：当前目标文本，后续规则可能修改它。
- `partOfSpeech`：词性。
- `kind`：token 类型。
- `note`：解释。
- `unknown`：是否是未知词。
- `omitted`：是否在目标语言输出中省略。

它有一个 `copyWith` 方法。规则要修改某个字段时，会复制一份新单元，而不是直接改原对象。这让每个规则的变化更容易追踪。

`microscopeText` 用于报告，例如：

```text
的 -> （省略）
unknown_word -> unknown_word（未知）
```

## 语法规则引擎

代码在 `lib/rules.dart`。

`MicroscopeRuleEngine.apply` 先把分析结果变成翻译单元，再按源语言选择规则：

```text
中文 -> 英文:
  所有格折叠
  中文助词省略说明
  be 动词变形
  插入不定式 to
  插入英文冠词

英文 -> 中文:
  英文虚词省略说明
  中文连续书写说明
```

每条规则如果真的产生了变化，都会追加一个 `RuleApplication`，用于最后的显微镜报告。

如果没有任何规则触发，引擎会添加一条 `默认词序`，说明只是按词典顺序渲染。

### 规则一：所有格折叠

函数：`_applyChinesePossessive`

这个规则处理：

```text
我 的 模型
```

如果看到：

```text
代词 + 的
```

并且代词能映射到英文所有格，就替换代词的目标文本：

| 原目标文本 | 所有格 |
| --- | --- |
| I | my |
| you | your |
| he | his |
| she | her |
| it | its |
| we | our |
| they | their |

例如：

```text
我的模型
I + 的 + model
my + model
```

这里的重点是：英文不是逐字翻成 `I of model`，而是把“代词 + 的”折叠成一个所有格。

### 规则二：解释省略的虚词或助词

函数：`_explainOmittedParticles`

词典里有些词条设置了 `omitInTarget: true`，比如：

- 中文的 `的`、`了`、`吗`、`个`。
- 英文的 `to`、`a`、`an`、`the`。

规则本身不删除它们，因为它们已经在 `TranslationUnit.omitted` 里被标记为省略。这个规则做的是把省略原因写入报告：

```text
有些结构词不直接变成目标语言单词，而是交给词序、标点或上下文表达。
```

这能帮助新手理解：翻译不是每个词都必须对应一个词。

### 规则三：be 动词变形

函数：`_conjugateEnglishBe`

中文的 `是` 在词典里先翻译成 `be`。但是英文里真正输出时通常不能直接写 `be`，要看主语：

| 主语 | be 形式 |
| --- | --- |
| I | am |
| you | are |
| we | are |
| they | are |
| 其他或找不到主语 | is |

算法：

```text
遍历所有翻译单元
如果当前 targetText 是 be，且没有被省略:
  向前找最近的可见非标点单元作为主语
  用 _beForSubject 选择 am/is/are
  替换当前 targetText
```

例子：

```text
我是学生
I be student
I am student
```

后续冠词规则会继续变成：

```text
I am a student
```

### 规则四：插入不定式 to

函数：`_insertEnglishInfinitiveTo`

有些中文动词后面接另一个动词时，英文常需要加 `to`。

当前规则只处理四个控制动词：

```text
like, love, want, need
```

算法：

```text
遍历翻译单元
每加入一个单元后，检查它是否是 like/love/want/need

如果是:
  找后面最近的可见非标点单元
  如果后面这个单元是动词:
    插入一个新的 TranslationUnit，targetText = to
```

例子：

```text
我喜欢学习自然语言处理
I like learn natural language processing
I like to learn natural language processing
```

这个 `to` 不是来自原文某个字符，而是来自语法规则，所以它的 `sourceText` 是 `[规则]`。

### 规则五：插入英文冠词

函数：`_insertEnglishArticleAfterBe`

中文没有冠词，英文单数可数名词作表语时常需要 `a`。

算法：

```text
遍历翻译单元
查看当前单元 current 和已经输出的上一个可见词 previous

如果 current 是名词
并且 previous 是 am/is/are
并且 current 不是不可数名词或专有名词:
  先插入 a
再加入 current
```

例子：

```text
我是学生
I am student
I am a student
```

引擎用 `_isMassOrProperNoun` 维护一个小集合，避免给这些词加 `a`：

```text
AI, Chinese, Dart, English, GPT,
artificial intelligence, code, data,
deep learning, machine learning,
natural language processing, text
```

这也是一个教学简化。真实翻译器需要更复杂的名词数、语义和上下文判断。

### 规则六：英文到中文的虚词省略

英文翻译成中文时，词典里这些词常被标成省略：

```text
to, a, an, the
```

比如：

```text
I like to learn natural language processing.
```

`to` 在中文里通常不需要单独翻译，目标句可以是：

```text
我喜欢学习自然语言处理。
```

规则引擎会在报告里说明“英文虚词省略”，让学习者知道它不是漏翻。

### 规则七：中文连续书写

英文到中文时，规则引擎会添加一条说明：

```text
中文目标句通常不在词与词之间加空格，最后由渲染器直接拼接。
```

这条规则不改变单元内容，但解释了后续渲染为什么会把中文词直接连起来。

## 渲染算法

代码在 `lib/renderer.dart`。

规则引擎产出的 `TranslationUnit` 还不是最终字符串。渲染器负责处理：

- 哪些单元真的输出。
- 词和词之间是否加空格。
- 标点应该用中文样式还是英文样式。
- 英文首字母是否需要大写。

### 渲染中文

算法：

```text
创建 StringBuffer
遍历没有 omitted 的单元

如果单元是标点:
  转成中文标点后写入
否则:
  直接写入 targetText

返回 buffer.toString()
```

中文不在词之间加空格，所以：

```text
我 / 喜欢 / 学习 / 自然语言处理 / 。
```

会渲染成：

```text
我喜欢学习自然语言处理。
```

中文标点映射包括：

| 英文标点 | 中文标点 |
|------|------|
| `,`  | `，`  |
| `.`  | `。`  |
| `?`  | `？`  |
| `!`  | `！`  |
| `:`  | `：`  |
| `;`  | `；`  |
| `(`  | `（`  |
| `)`  | `）`  |

### 渲染英文

算法：

```text
创建 StringBuffer
遍历没有 omitted 的单元

如果 targetText 为空:
  跳过

如果是标点:
  转成英文标点，直接追加
  不在标点前加空格

如果是普通词:
  如果 buffer 不是空，并且前面不是左括号、左中括号、左大括号、引号:
    先追加一个空格
  追加 targetText

最后把第一个英文小写字母转成大写
```

英文标点映射包括：

| 中文标点 | 英文标点 |
|------|------|
| `，`  | `,`  |
| `。`  | `.`  |
| `？`  | `?`  |
| `！`  | `!`  |
| `：`  | `:`  |
| `；`  | `;`  |
| `（`  | `(`  |
| `）`  | `)`  |
| `、`  | `,`  |

例子：

```text
i / like / to / learn / natural language processing / .
```

会变成：

```text
I like to learn natural language processing.
```

注意：首字母大写只处理 ASCII 英文字母。它会找到字符串里的第一个小写字母并转成大写。

## 显微镜报告如何生成

代码在 `lib/result.dart` 和 `lib/engine.dart`。

`TranslationResult` 保存了所有中间结果：

- 原文和译文。
- 源语言和目标语言。
- 分词结果。
- 词典分析结果。
- 规则后的翻译单元。
- 触发过的规则。
- trace 报告。

`MicroscopeTranslator._buildTrace` 会组织五个章节：

1. 语言判断。
2. 分词。
3. 词典查找。
4. 语法规则。
5. 渲染。

`toMicroscopeReport()` 再把这些章节格式化成可读文本。

这就是为什么命令行输出不只是译文，而是会告诉你每一步发生了什么。

## 完整例子：中文到英文

输入：

```text
我喜欢学习自然语言处理。
```

流程：

```text
语言判断：
  中文字符更多 -> 源语言中文，目标语言英文

分词：
  我 / 喜欢 / 学习 / 自然语言处理 / 。

词典查找：
  我 -> I
  喜欢 -> like
  学习 -> learn
  自然语言处理 -> natural language processing
  。 -> 。

规则：
  喜欢 后面接动词 学习 -> 插入 to

渲染：
  英文词之间加空格
  中文句号转英文句号
  首字母大写

输出：
  I like to learn natural language processing.
```

## 完整例子：英文到中文

输入：

```text
I like to learn natural language processing.
```

流程：

```text
语言判断：
  英文字母更多 -> 源语言英文，目标语言中文

分词：
  I / like / to / learn / natural language processing / .

词典查找：
  I -> 我
  like -> 喜欢
  to -> 省略
  learn -> 学习
  natural language processing -> 自然语言处理
  . -> .

规则：
  to 是英文不定式标记，中文常省略
  中文连续书写

渲染：
  跳过 omitted 单元
  中文词直接拼接
  英文句号转中文句号

输出：
  我喜欢学习自然语言处理。
```

## 这个引擎“礼貌”的地方

这里的“礼貌”可以理解成：程序尽量不假装自己很聪明，而是诚实地告诉学习者它做了什么、没做什么。

它的礼貌体现在几处：

- 查不到词时不报错，也不胡乱猜测，而是原样保留并标成未知。
- 省略助词和虚词时会写入报告，避免学习者以为漏翻。
- 规则触发时保留 before 和 after，让变化看得见。
- 语言判断很简单，所以允许用户用 `--from` 和 `--to` 显式指定。
- 词典条目自带 `note`，每个翻译都有一句教学解释。

这也是它适合学习的原因：真实翻译器经常只给最终答案，而这个引擎把推理台阶都留在报告里。

## 已知限制

这个项目是教学用微型引擎，所以有很多有意简化：

- 语言检测只数中文字符和英文字母，不处理复杂混合文本。
- 中文分词完全依赖小词典和最长匹配。
- 英文分词没有处理所有缩写、连字符、复杂标点和词形变化。
- 词典很小，很多常用词没有收录。
- 英文语法规则只覆盖少量现象。
- 没有处理复数、时态、从句、被动语态、语义消歧、上下文一致性。
- 冠词规则只用一个小集合判断不可数名词和专有名词。
- 标点映射是固定表，不处理全部 Unicode 标点。

这些限制不是 bug，而是教学边界。它把翻译系统拆成最小可理解版本，方便继续扩展。

## 想扩展时从哪里下手

如果想添加一个新词：

1. 在 `lib/lexicon.dart` 的 `_entries` 里添加 `LexiconEntry.zh` 或 `LexiconEntry.en`。
2. 给它写清楚词性和 `note`。
3. 运行命令行，看显微镜报告是否能查到词。

如果想添加一个新语法规则：

1. 在 `lib/rules.dart` 里写一个小函数，输入 `List<TranslationUnit>`，输出新的列表。
2. 只在真的改变结果时添加 `RuleApplication`。
3. 在 `_applyChineseToEnglish` 或 `_applyEnglishToChinese` 里按顺序调用。
4. 准备一个能触发规则的例句，用命令行验证 before、after 和最终译文。

如果想改变输出样式：

1. 修改 `lib/renderer.dart`。
2. 中文输出重点看是否该加空格。
3. 英文输出重点看空格、标点和首字母大写。

## 阅读源码建议

推荐按这个顺序读：

1. `bin/z1_translate.dart`：先知道程序从哪里开始。
2. `lib/engine.dart`：看完整流水线。
3. `lib/language.dart`：理解语言判断。
4. `lib/token.dart` 和 `lib/tokenizer.dart`：理解文本如何变成 token。
5. `lib/lexicon.dart` 和 `lib/analyzer.dart`：理解 token 如何找到翻译。
6. `lib/translation_unit.dart` 和 `lib/rules.dart`：理解语法规则如何改写中间结果。
7. `lib/renderer.dart`：理解中间结果如何变成最终句子。
8. `lib/result.dart`：理解显微镜报告如何被组织出来。

按这个顺序读，能从用户输入一路跟到最终输出，不容易迷路。
