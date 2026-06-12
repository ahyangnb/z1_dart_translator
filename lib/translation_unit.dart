import 'token.dart';

class TranslationUnit {
  const TranslationUnit({
    required this.sourceText,
    required this.targetText,
    required this.partOfSpeech,
    required this.kind,
    required this.note,
    this.unknown = false,
    this.omitted = false,
  });

  final String sourceText;
  final String targetText;
  final PartOfSpeech partOfSpeech;
  final TokenKind kind;
  final String note;
  final bool unknown;
  final bool omitted;

  TranslationUnit copyWith({
    String? sourceText,
    String? targetText,
    PartOfSpeech? partOfSpeech,
    TokenKind? kind,
    String? note,
    bool? unknown,
    bool? omitted,
  }) {
    return TranslationUnit(
      sourceText: sourceText ?? this.sourceText,
      targetText: targetText ?? this.targetText,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      unknown: unknown ?? this.unknown,
      omitted: omitted ?? this.omitted,
    );
  }

  String get microscopeText {
    final hidden = omitted ? '（省略）' : '';
    final unknownText = unknown ? '（未知）' : '';
    return '$sourceText -> $targetText$hidden$unknownText';
  }
}
