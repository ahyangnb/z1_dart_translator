enum TokenKind {
  word,
  phrase,
  number,
  punctuation,
  unknown,
}

extension TokenKindLabel on TokenKind {
  String get label {
    switch (this) {
      case TokenKind.word:
        return '词';
      case TokenKind.phrase:
        return '短语';
      case TokenKind.number:
        return '数字';
      case TokenKind.punctuation:
        return '标点';
      case TokenKind.unknown:
        return '未知';
    }
  }
}

enum PartOfSpeech {
  pronoun,
  verb,
  noun,
  adjective,
  adverb,
  preposition,
  conjunction,
  determiner,
  particle,
  punctuation,
  number,
  unknown,
}

extension PartOfSpeechLabel on PartOfSpeech {
  String get label {
    switch (this) {
      case PartOfSpeech.pronoun:
        return '代词';
      case PartOfSpeech.verb:
        return '动词';
      case PartOfSpeech.noun:
        return '名词';
      case PartOfSpeech.adjective:
        return '形容词';
      case PartOfSpeech.adverb:
        return '副词';
      case PartOfSpeech.preposition:
        return '介词';
      case PartOfSpeech.conjunction:
        return '连词';
      case PartOfSpeech.determiner:
        return '限定词';
      case PartOfSpeech.particle:
        return '语气/结构助词';
      case PartOfSpeech.punctuation:
        return '标点';
      case PartOfSpeech.number:
        return '数字';
      case PartOfSpeech.unknown:
        return '未知词性';
    }
  }
}

class Token {
  const Token({
    required this.text,
    required this.normalized,
    required this.kind,
    required this.start,
    required this.end,
  });

  final String text;
  final String normalized;
  final TokenKind kind;
  final int start;
  final int end;

  bool get isPunctuation => kind == TokenKind.punctuation;

  @override
  String toString() => text;
}
