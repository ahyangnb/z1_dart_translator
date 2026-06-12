import 'language.dart';
import 'token.dart';

class LexiconEntry {
  const LexiconEntry({
    required this.source,
    required this.sourceLanguage,
    required this.target,
    required this.partOfSpeech,
    required this.note,
    this.omitInTarget = false,
  });

  const LexiconEntry.zh(
    String source,
    String target,
    PartOfSpeech partOfSpeech,
    String note, {
    bool omitInTarget = false,
  }) : this(
          source: source,
          sourceLanguage: Language.chinese,
          target: target,
          partOfSpeech: partOfSpeech,
          note: note,
          omitInTarget: omitInTarget,
        );

  const LexiconEntry.en(
    String source,
    String target,
    PartOfSpeech partOfSpeech,
    String note, {
    bool omitInTarget = false,
  }) : this(
          source: source,
          sourceLanguage: Language.english,
          target: target,
          partOfSpeech: partOfSpeech,
          note: note,
          omitInTarget: omitInTarget,
        );

  final String source;
  final Language sourceLanguage;
  final String target;
  final PartOfSpeech partOfSpeech;
  final String note;
  final bool omitInTarget;
}

class TinyTranslationLexicon {
  TinyTranslationLexicon._(this._byLanguage, this._sourceTerms);

  factory TinyTranslationLexicon.standard() {
    final byLanguage = {
      Language.chinese: <String, LexiconEntry>{},
      Language.english: <String, LexiconEntry>{},
    };

    for (final entry in _entries) {
      final key = normalizeTerm(entry.sourceLanguage, entry.source);
      byLanguage[entry.sourceLanguage]![key] = entry;
    }

    final sourceTerms = <Language, List<String>>{};
    for (final language in Language.values) {
      sourceTerms[language] = byLanguage[language]!.keys.toList()
        ..sort((a, b) {
          final bySize = termSize(language, b).compareTo(termSize(language, a));
          if (bySize != 0) return bySize;
          return b.length.compareTo(a.length);
        });
    }

    return TinyTranslationLexicon._(byLanguage, sourceTerms);
  }

  final Map<Language, Map<String, LexiconEntry>> _byLanguage;
  final Map<Language, List<String>> _sourceTerms;

  LexiconEntry? lookup(Language language, String term) {
    return _byLanguage[language]![normalizeTerm(language, term)];
  }

  List<String> sourceTerms(Language language) {
    return List.unmodifiable(_sourceTerms[language]!);
  }

  int maxSourceTermSize(Language language) {
    final terms = _sourceTerms[language]!;
    if (terms.isEmpty) return 1;
    return terms.map((term) => termSize(language, term)).reduce((a, b) {
      return a > b ? a : b;
    });
  }

  static String normalizeTerm(Language language, String term) {
    final trimmed = term.trim();
    if (language == Language.chinese) return trimmed;
    return trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static int termSize(Language language, String term) {
    if (language == Language.chinese) return term.runes.length;
    return normalizeTerm(language, term).split(' ').length;
  }
}

const _entries = <LexiconEntry>[
  LexiconEntry.zh('自然语言处理', 'natural language processing', PartOfSpeech.noun,
      '固定技术短语，整体翻译优先于逐字翻译'),
  LexiconEntry.zh(
      '人工智能', 'artificial intelligence', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.zh('机器学习', 'machine learning', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.zh('深度学习', 'deep learning', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.zh('神经网络', 'neural network', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.zh('翻译引擎', 'translation engine', PartOfSpeech.noun, '项目核心短语'),
  LexiconEntry.zh('语言模型', 'language model', PartOfSpeech.noun, '技术短语'),
  LexiconEntry.zh('大模型', 'large language model', PartOfSpeech.noun, '技术短语'),
  LexiconEntry.zh('我', 'I', PartOfSpeech.pronoun, '第一人称主语'),
  LexiconEntry.zh('你', 'you', PartOfSpeech.pronoun, '第二人称'),
  LexiconEntry.zh('他', 'he', PartOfSpeech.pronoun, '第三人称男性'),
  LexiconEntry.zh('她', 'she', PartOfSpeech.pronoun, '第三人称女性'),
  LexiconEntry.zh('它', 'it', PartOfSpeech.pronoun, '第三人称事物'),
  LexiconEntry.zh('我们', 'we', PartOfSpeech.pronoun, '第一人称复数'),
  LexiconEntry.zh('他们', 'they', PartOfSpeech.pronoun, '第三人称复数'),
  LexiconEntry.zh('这', 'this', PartOfSpeech.pronoun, '指示代词'),
  LexiconEntry.zh('那', 'that', PartOfSpeech.pronoun, '指示代词'),
  LexiconEntry.zh('是', 'be', PartOfSpeech.verb, '系动词，英文需要按主语变形'),
  LexiconEntry.zh('喜欢', 'like', PartOfSpeech.verb, '动词，可接不定式'),
  LexiconEntry.zh('爱', 'love', PartOfSpeech.verb, '动词，可接不定式'),
  LexiconEntry.zh('想', 'want', PartOfSpeech.verb, '动词，可接不定式'),
  LexiconEntry.zh('需要', 'need', PartOfSpeech.verb, '动词，可接不定式'),
  LexiconEntry.zh('学习', 'learn', PartOfSpeech.verb, '动词：学习/学会'),
  LexiconEntry.zh('理解', 'understand', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('使用', 'use', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('写', 'write', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('训练', 'train', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('生成', 'generate', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('翻译', 'translate', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('解释', 'explain', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('帮助', 'help', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('研究', 'study', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('运行', 'run', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('读取', 'read', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('计算', 'calculate', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('预测', 'predict', PartOfSpeech.verb, '动词'),
  LexiconEntry.zh('很', 'very', PartOfSpeech.adverb, '程度副词'),
  LexiconEntry.zh('不', 'not', PartOfSpeech.adverb, '否定副词'),
  LexiconEntry.zh('也', 'also', PartOfSpeech.adverb, '副词'),
  LexiconEntry.zh('可以', 'can', PartOfSpeech.verb, '情态动词'),
  LexiconEntry.zh('能', 'can', PartOfSpeech.verb, '情态动词'),
  LexiconEntry.zh('和', 'and', PartOfSpeech.conjunction, '并列连词'),
  LexiconEntry.zh('在', 'in', PartOfSpeech.preposition, '介词'),
  LexiconEntry.zh('用', 'with', PartOfSpeech.preposition, '介词：使用某工具'),
  LexiconEntry.zh('的', '', PartOfSpeech.particle, '结构助词，常由英文词序或所有格表达',
      omitInTarget: true),
  LexiconEntry.zh('了', '', PartOfSpeech.particle, '时态/完成助词，微型引擎先省略',
      omitInTarget: true),
  LexiconEntry.zh('吗', '', PartOfSpeech.particle, '疑问语气助词，靠问号表达',
      omitInTarget: true),
  LexiconEntry.zh('个', '', PartOfSpeech.particle, '量词，微型引擎先省略',
      omitInTarget: true),
  LexiconEntry.zh('模型', 'model', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('数据', 'data', PartOfSpeech.noun, '不可数名词'),
  LexiconEntry.zh('文本', 'text', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('文字', 'text', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('句子', 'sentence', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('单词', 'word', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('词', 'word', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('代码', 'code', PartOfSpeech.noun, '不可数名词'),
  LexiconEntry.zh('文件', 'file', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('项目', 'project', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('用户', 'user', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('学生', 'student', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('老师', 'teacher', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('示例', 'example', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('原理', 'principle', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('过程', 'process', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('结果', 'result', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('输入', 'input', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('输出', 'output', PartOfSpeech.noun, '名词'),
  LexiconEntry.zh('中文', 'Chinese', PartOfSpeech.noun, '语言名'),
  LexiconEntry.zh('英文', 'English', PartOfSpeech.noun, '语言名'),
  LexiconEntry.zh('Dart', 'Dart', PartOfSpeech.noun, '专有名词'),
  LexiconEntry.zh('GPT', 'GPT', PartOfSpeech.noun, '专有名词'),
  LexiconEntry.zh('AI', 'AI', PartOfSpeech.noun, '专有名词'),
  LexiconEntry.en('natural language processing', '自然语言处理', PartOfSpeech.noun,
      '固定技术短语，整体翻译'),
  LexiconEntry.en(
      'artificial intelligence', '人工智能', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.en('machine learning', '机器学习', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.en('deep learning', '深度学习', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.en('neural network', '神经网络', PartOfSpeech.noun, '固定技术短语'),
  LexiconEntry.en('translation engine', '翻译引擎', PartOfSpeech.noun, '项目核心短语'),
  LexiconEntry.en('language model', '语言模型', PartOfSpeech.noun, '技术短语'),
  LexiconEntry.en('large language model', '大模型', PartOfSpeech.noun, '技术短语'),
  LexiconEntry.en('i', '我', PartOfSpeech.pronoun, '第一人称主语'),
  LexiconEntry.en('me', '我', PartOfSpeech.pronoun, '第一人称宾语'),
  LexiconEntry.en('my', '我的', PartOfSpeech.pronoun, '所有格'),
  LexiconEntry.en('you', '你', PartOfSpeech.pronoun, '第二人称'),
  LexiconEntry.en('he', '他', PartOfSpeech.pronoun, '第三人称男性'),
  LexiconEntry.en('she', '她', PartOfSpeech.pronoun, '第三人称女性'),
  LexiconEntry.en('it', '它', PartOfSpeech.pronoun, '第三人称事物'),
  LexiconEntry.en('we', '我们', PartOfSpeech.pronoun, '第一人称复数'),
  LexiconEntry.en('they', '他们', PartOfSpeech.pronoun, '第三人称复数'),
  LexiconEntry.en('this', '这', PartOfSpeech.pronoun, '指示代词'),
  LexiconEntry.en('that', '那', PartOfSpeech.pronoun, '指示代词'),
  LexiconEntry.en('am', '是', PartOfSpeech.verb, '系动词'),
  LexiconEntry.en('is', '是', PartOfSpeech.verb, '系动词'),
  LexiconEntry.en('are', '是', PartOfSpeech.verb, '系动词'),
  LexiconEntry.en('be', '是', PartOfSpeech.verb, '系动词'),
  LexiconEntry.en('like', '喜欢', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('love', '爱', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('want', '想', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('need', '需要', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('learn', '学习', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('learning', '学习', PartOfSpeech.noun, '名词/动名词'),
  LexiconEntry.en('understand', '理解', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('use', '使用', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('write', '写', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('train', '训练', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('generate', '生成', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('translate', '翻译', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('explain', '解释', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('help', '帮助', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('study', '研究', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('run', '运行', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('read', '读取', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('calculate', '计算', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('predict', '预测', PartOfSpeech.verb, '动词'),
  LexiconEntry.en('very', '很', PartOfSpeech.adverb, '程度副词'),
  LexiconEntry.en('not', '不', PartOfSpeech.adverb, '否定副词'),
  LexiconEntry.en('also', '也', PartOfSpeech.adverb, '副词'),
  LexiconEntry.en('can', '可以', PartOfSpeech.verb, '情态动词'),
  LexiconEntry.en('and', '和', PartOfSpeech.conjunction, '并列连词'),
  LexiconEntry.en('in', '在', PartOfSpeech.preposition, '介词'),
  LexiconEntry.en('with', '用', PartOfSpeech.preposition, '介词'),
  LexiconEntry.en('of', '的', PartOfSpeech.particle, '所有/从属关系'),
  LexiconEntry.en('to', '', PartOfSpeech.particle, '英文不定式标记，中文常省略',
      omitInTarget: true),
  LexiconEntry.en('a', '', PartOfSpeech.determiner, '冠词，中文常省略',
      omitInTarget: true),
  LexiconEntry.en('an', '', PartOfSpeech.determiner, '冠词，中文常省略',
      omitInTarget: true),
  LexiconEntry.en('the', '', PartOfSpeech.determiner, '冠词，中文常省略',
      omitInTarget: true),
  LexiconEntry.en('model', '模型', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('data', '数据', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('text', '文本', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('sentence', '句子', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('word', '单词', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('code', '代码', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('file', '文件', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('project', '项目', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('user', '用户', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('student', '学生', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('teacher', '老师', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('example', '示例', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('principle', '原理', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('process', '过程', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('result', '结果', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('input', '输入', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('output', '输出', PartOfSpeech.noun, '名词'),
  LexiconEntry.en('chinese', '中文', PartOfSpeech.noun, '语言名'),
  LexiconEntry.en('english', '英文', PartOfSpeech.noun, '语言名'),
  LexiconEntry.en('dart', 'Dart', PartOfSpeech.noun, '专有名词'),
  LexiconEntry.en('gpt', 'GPT', PartOfSpeech.noun, '专有名词'),
  LexiconEntry.en('ai', 'AI', PartOfSpeech.noun, '专有名词'),
];
