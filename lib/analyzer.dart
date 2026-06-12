import 'language.dart';
import 'lexicon.dart';
import 'token.dart';

class AnalyzedToken {
  const AnalyzedToken({
    required this.token,
    required this.entry,
    required this.targetText,
    required this.partOfSpeech,
    required this.note,
    required this.omitInTarget,
  });

  final Token token;
  final LexiconEntry? entry;
  final String targetText;
  final PartOfSpeech partOfSpeech;
  final String note;
  final bool omitInTarget;

  bool get isKnown => entry != null || token.kind == TokenKind.punctuation;
}

class TokenAnalyzer {
  const TokenAnalyzer(this.lexicon);

  final TinyTranslationLexicon lexicon;

  List<AnalyzedToken> analyze(Language sourceLanguage, List<Token> tokens) {
    return [
      for (final token in tokens) _analyzeOne(sourceLanguage, token),
    ];
  }

  AnalyzedToken _analyzeOne(Language sourceLanguage, Token token) {
    if (token.kind == TokenKind.punctuation) {
      return AnalyzedToken(
        token: token,
        entry: null,
        targetText: token.text,
        partOfSpeech: PartOfSpeech.punctuation,
        note: '标点先原样保留，最后由渲染器按目标语言调整',
        omitInTarget: false,
      );
    }

    if (token.kind == TokenKind.number) {
      return AnalyzedToken(
        token: token,
        entry: null,
        targetText: token.text,
        partOfSpeech: PartOfSpeech.number,
        note: '数字通常跨语言保留',
        omitInTarget: false,
      );
    }

    final entry = lexicon.lookup(sourceLanguage, token.normalized);
    if (entry == null) {
      return AnalyzedToken(
        token: token,
        entry: null,
        targetText: token.text,
        partOfSpeech: PartOfSpeech.unknown,
        note: '词典未收录：教学引擎先原样保留，方便看到词典缺口',
        omitInTarget: false,
      );
    }

    return AnalyzedToken(
      token: token,
      entry: entry,
      targetText: entry.target,
      partOfSpeech: entry.partOfSpeech,
      note: entry.note,
      omitInTarget: entry.omitInTarget,
    );
  }
}
