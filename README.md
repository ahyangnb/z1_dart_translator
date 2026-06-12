# z1_dart_translator
一个最原始方便学习的翻译引擎，无需联网，算法完整，展示全过程。


翻译学习引擎入口是：

```bash
bin/z1_translate.dart
```

运行显微镜翻译引擎：

```bash
dart run bin/z1_translate.dart "我喜欢学习自然语言处理。"
```

也可以指定方向：

```bash
dart run bin/z1_translate.dart --from=en --to=zh "I like to learn natural language processing."
```

这个翻译引擎不是联网翻译器，而是一个方便学习的中英双向微型 NLP 流水线。它会展示：

1. 语言判断。
2. 分词。
3. 词典查找。
4. 语法规则，例如省略中文助词、英文 `be` 变形、插入 `to` 和冠词。
5. 最终渲染。

![img.png](img.png)