import 'analyzer.dart';
import 'language.dart';
import 'token.dart';
import 'translation_unit.dart';

class RuleApplication {
  const RuleApplication({
    required this.name,
    required this.before,
    required this.after,
    required this.explanation,
  });

  final String name;
  final String before;
  final String after;
  final String explanation;
}

class RuleResult {
  const RuleResult({
    required this.units,
    required this.applications,
  });

  final List<TranslationUnit> units;
  final List<RuleApplication> applications;
}

class MicroscopeRuleEngine {
  const MicroscopeRuleEngine();

  RuleResult apply(
      Language sourceLanguage, List<AnalyzedToken> analyzedTokens) {
    var units = [
      for (final analyzed in analyzedTokens)
        TranslationUnit(
          sourceText: analyzed.token.text,
          targetText: analyzed.targetText,
          partOfSpeech: analyzed.partOfSpeech,
          kind: analyzed.token.kind,
          note: analyzed.note,
          unknown: !analyzed.isKnown,
          omitted: analyzed.omitInTarget,
        ),
    ];
    final applications = <RuleApplication>[];

    switch (sourceLanguage) {
      case Language.chinese:
        units = _applyChineseToEnglish(units, applications);
        break;
      case Language.english:
        units = _applyEnglishToChinese(units, applications);
        break;
    }

    if (applications.isEmpty) {
      applications.add(RuleApplication(
        name: '默认词序',
        before: _visibleSignature(units),
        after: _visibleSignature(units),
        explanation: '没有触发额外语法规则，直接使用词典顺序渲染。',
      ));
    }

    return RuleResult(units: units, applications: applications);
  }

  List<TranslationUnit> _applyChineseToEnglish(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    units = _applyChinesePossessive(units, applications);
    units = _explainOmittedParticles(units, applications, '中文助词省略');
    units = _conjugateEnglishBe(units, applications);
    units = _insertEnglishInfinitiveTo(units, applications);
    units = _insertEnglishArticleAfterBe(units, applications);
    return units;
  }

  List<TranslationUnit> _applyEnglishToChinese(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    units = _explainOmittedParticles(units, applications, '英文虚词省略');
    applications.add(RuleApplication(
      name: '中文连续书写',
      before: _visibleSignature(units),
      after: _visibleSignature(units),
      explanation: '中文目标句通常不在词与词之间加空格，最后由渲染器直接拼接。',
    ));
    return units;
  }

  List<TranslationUnit> _applyChinesePossessive(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    const possessive = {
      'I': 'my',
      'you': 'your',
      'he': 'his',
      'she': 'her',
      'it': 'its',
      'we': 'our',
      'they': 'their',
    };
    final next = [...units];
    var changed = false;
    final before = _visibleSignature(next);

    for (var i = 0; i < next.length - 1; i++) {
      if (next[i].partOfSpeech != PartOfSpeech.pronoun) continue;
      if (next[i + 1].sourceText != '的') continue;
      final replacement = possessive[next[i].targetText];
      if (replacement == null) continue;
      next[i] = next[i].copyWith(
        targetText: replacement,
        note: '“代词 + 的”在英文里常折叠为所有格',
      );
      changed = true;
    }

    if (changed) {
      applications.add(RuleApplication(
        name: '所有格折叠',
        before: before,
        after: _visibleSignature(next),
        explanation: '例如“我的模型”不是逐词译成“I of model”，而是折叠成“my model”。',
      ));
    }

    return next;
  }

  List<TranslationUnit> _explainOmittedParticles(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
    String ruleName,
  ) {
    if (!units.any((unit) => unit.omitted)) return units;

    applications.add(RuleApplication(
      name: ruleName,
      before: units.map((unit) => unit.microscopeText).join(' | '),
      after: _visibleSignature(units),
      explanation: '有些结构词不直接变成目标语言单词，而是交给词序、标点或上下文表达。',
    ));
    return units;
  }

  List<TranslationUnit> _conjugateEnglishBe(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    final next = [...units];
    var changed = false;
    final before = _visibleSignature(next);

    for (var i = 0; i < next.length; i++) {
      if (next[i].targetText != 'be' || next[i].omitted) continue;
      final subject = _previousVisibleWord(next, i);
      final be = _beForSubject(subject);
      next[i] = next[i].copyWith(
        targetText: be,
        note: '英文 be 动词需要根据主语变形',
      );
      changed = true;
    }

    if (changed) {
      applications.add(RuleApplication(
        name: 'be 动词变形',
        before: before,
        after: _visibleSignature(next),
        explanation: '中文“是”不变形；英文要根据主语选择 am/is/are。',
      ));
    }

    return next;
  }

  List<TranslationUnit> _insertEnglishInfinitiveTo(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    const controlVerbs = {'like', 'love', 'want', 'need'};
    final next = <TranslationUnit>[];
    var changed = false;
    final before = _visibleSignature(units);

    for (var i = 0; i < units.length; i++) {
      next.add(units[i]);
      if (units[i].omitted || !controlVerbs.contains(units[i].targetText)) {
        continue;
      }

      final following = _nextVisibleUnit(units, i);
      if (following == null || following.partOfSpeech != PartOfSpeech.verb) {
        continue;
      }

      next.add(const TranslationUnit(
        sourceText: '[规则]',
        targetText: 'to',
        partOfSpeech: PartOfSpeech.preposition,
        kind: TokenKind.word,
        note: '英文控制动词后接动词时常加入不定式 to',
      ));
      changed = true;
    }

    if (changed) {
      applications.add(RuleApplication(
        name: '插入不定式 to',
        before: before,
        after: _visibleSignature(next),
        explanation: '“喜欢学习”在英文里更自然地写成“like to learn”。',
      ));
    }

    return next;
  }

  List<TranslationUnit> _insertEnglishArticleAfterBe(
    List<TranslationUnit> units,
    List<RuleApplication> applications,
  ) {
    final next = <TranslationUnit>[];
    var changed = false;
    final before = _visibleSignature(units);

    for (var i = 0; i < units.length; i++) {
      final previous = _lastVisibleUnit(next);
      final current = units[i];

      if (!current.omitted &&
          current.partOfSpeech == PartOfSpeech.noun &&
          previous != null &&
          const {'am', 'is', 'are'}.contains(previous.targetText) &&
          !_isMassOrProperNoun(current.targetText)) {
        next.add(const TranslationUnit(
          sourceText: '[规则]',
          targetText: 'a',
          partOfSpeech: PartOfSpeech.determiner,
          kind: TokenKind.word,
          note: '英文单数可数名词作表语时常需要冠词',
        ));
        changed = true;
      }

      next.add(current);
    }

    if (changed) {
      applications.add(RuleApplication(
        name: '插入英文冠词',
        before: before,
        after: _visibleSignature(next),
        explanation: '中文没有冠词；英文里“我是学生”通常写成“I am a student”。',
      ));
    }

    return next;
  }

  String? _previousVisibleWord(List<TranslationUnit> units, int beforeIndex) {
    for (var i = beforeIndex - 1; i >= 0; i--) {
      if (!units[i].omitted && units[i].kind != TokenKind.punctuation) {
        return units[i].targetText;
      }
    }
    return null;
  }

  TranslationUnit? _nextVisibleUnit(
      List<TranslationUnit> units, int afterIndex) {
    for (var i = afterIndex + 1; i < units.length; i++) {
      if (!units[i].omitted && units[i].kind != TokenKind.punctuation) {
        return units[i];
      }
    }
    return null;
  }

  TranslationUnit? _lastVisibleUnit(List<TranslationUnit> units) {
    for (var i = units.length - 1; i >= 0; i--) {
      if (!units[i].omitted && units[i].kind != TokenKind.punctuation) {
        return units[i];
      }
    }
    return null;
  }

  String _beForSubject(String? subject) {
    switch (subject) {
      case 'I':
        return 'am';
      case 'you':
      case 'we':
      case 'they':
        return 'are';
      default:
        return 'is';
    }
  }

  bool _isMassOrProperNoun(String text) {
    return const {
      'AI',
      'Chinese',
      'Dart',
      'English',
      'GPT',
      'artificial intelligence',
      'code',
      'data',
      'deep learning',
      'machine learning',
      'natural language processing',
      'text',
    }.contains(text);
  }

  String _visibleSignature(List<TranslationUnit> units) {
    return units
        .where((unit) => !unit.omitted)
        .map((unit) => unit.targetText)
        .where((text) => text.isNotEmpty)
        .join(' ');
  }
}
