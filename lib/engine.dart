import 'analyzer.dart';
import 'language.dart';
import 'lexicon.dart';
import 'renderer.dart';
import 'result.dart';
import 'rules.dart';
import 'token.dart';
import 'tokenizer.dart';
import 'translation_unit.dart';

class MicroscopeTranslator {
  MicroscopeTranslator({
    TinyTranslationLexicon? lexicon,
    MicroscopeRuleEngine? ruleEngine,
    TranslationRenderer? renderer,
  })  : lexicon = lexicon ?? TinyTranslationLexicon.standard(),
        ruleEngine = ruleEngine ?? const MicroscopeRuleEngine(),
        renderer = renderer ?? const TranslationRenderer();

  final TinyTranslationLexicon lexicon;
  final MicroscopeRuleEngine ruleEngine;
  final TranslationRenderer renderer;

  TranslationResult translate(
    String text, {
    Language? sourceLanguage,
    Language? targetLanguage,
  }) {
    final source = sourceLanguage ?? detectLanguage(text);
    final target = targetLanguage ?? source.opposite;
    final tokenizer = MicroscopeTokenizer(lexicon);
    final analyzer = TokenAnalyzer(lexicon);

    final tokens = tokenizer.tokenize(source, text);
    final analyzedTokens = analyzer.analyze(source, tokens);
    final ruleResult = ruleEngine.apply(source, analyzedTokens);
    final output = renderer.render(target, ruleResult.units);

    return TranslationResult(
      sourceText: text,
      outputText: output,
      sourceLanguage: source,
      targetLanguage: target,
      tokens: tokens,
      analyzedTokens: analyzedTokens,
      units: ruleResult.units,
      ruleApplications: ruleResult.applications,
      trace: _buildTrace(
        source,
        target,
        tokens,
        analyzedTokens,
        ruleResult,
        output,
      ),
    );
  }

  List<TraceSection> _buildTrace(
    Language source,
    Language target,
    List<Token> tokens,
    List<AnalyzedToken> analyzedTokens,
    RuleResult ruleResult,
    String output,
  ) {
    return [
      TraceSection(
        title: '语言判断',
        lines: [
          '源语言：${source.label}',
          '目标语言：${target.label}',
          '判断方法：统计中日韩字符和拉丁字母，数量更多的一侧作为源语言。',
        ],
      ),
      TraceSection(
        title: '分词',
        lines: [
          if (tokens.isEmpty)
            '没有得到 token。'
          else ...[
            for (var i = 0; i < tokens.length; i++)
              '${i + 1}. "${tokens[i].text}" -> normalized="${tokens[i].normalized}", 类型=${tokens[i].kind.label}',
          ],
        ],
      ),
      TraceSection(
        title: '词典查找',
        lines: [
          for (final item in analyzedTokens)
            '"${item.token.text}" => "${item.targetText}"，词性=${item.partOfSpeech.label}，说明=${item.note}',
        ],
      ),
      TraceSection(
        title: '语法规则',
        lines: [
          for (final rule in ruleResult.applications)
            '${rule.name}: ${rule.before} -> ${rule.after}；${rule.explanation}',
        ],
      ),
      TraceSection(
        title: '渲染',
        lines: [
          '可见单元：${_visibleUnits(ruleResult.units)}',
          '最终输出：$output',
        ],
      ),
    ];
  }

  String _visibleUnits(List<TranslationUnit> units) {
    return units
        .where((unit) => !unit.omitted)
        .map((unit) => unit.targetText)
        .where((text) => text.isNotEmpty)
        .join(' | ');
  }
}
