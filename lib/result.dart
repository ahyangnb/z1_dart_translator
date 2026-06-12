import 'analyzer.dart';
import 'language.dart';
import 'rules.dart';
import 'token.dart';
import 'translation_unit.dart';

class TraceSection {
  const TraceSection({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}

class TranslationResult {
  const TranslationResult({
    required this.sourceText,
    required this.outputText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.tokens,
    required this.analyzedTokens,
    required this.units,
    required this.ruleApplications,
    required this.trace,
  });

  final String sourceText;
  final String outputText;
  final Language sourceLanguage;
  final Language targetLanguage;
  final List<Token> tokens;
  final List<AnalyzedToken> analyzedTokens;
  final List<TranslationUnit> units;
  final List<RuleApplication> ruleApplications;
  final List<TraceSection> trace;

  String toMicroscopeReport() {
    final buffer = StringBuffer()
      ..writeln('--- 显微镜翻译结果 ---')
      ..writeln('原文[${sourceLanguage.label}]: $sourceText')
      ..writeln('译文[${targetLanguage.label}]: $outputText');

    for (var i = 0; i < trace.length; i++) {
      buffer
        ..writeln()
        ..writeln('[${i + 1}] ${trace[i].title}');
      for (final line in trace[i].lines) {
        buffer.writeln('  - $line');
      }
    }

    return buffer.toString();
  }
}
