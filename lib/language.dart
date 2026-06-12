enum Language {
  chinese,
  english,
}

extension LanguageLabel on Language {
  String get label {
    switch (this) {
      case Language.chinese:
        return '中文';
      case Language.english:
        return '英文';
    }
  }

  Language get opposite {
    switch (this) {
      case Language.chinese:
        return Language.english;
      case Language.english:
        return Language.chinese;
    }
  }
}

Language detectLanguage(String text) {
  var cjk = 0;
  var latin = 0;

  for (final rune in text.runes) {
    if (_isCjkRune(rune)) {
      cjk++;
    } else if (_isLatinRune(rune)) {
      latin++;
    }
  }

  if (cjk == 0 && latin == 0) return Language.chinese;
  return cjk >= latin ? Language.chinese : Language.english;
}

bool _isCjkRune(int rune) {
  return (rune >= 0x4E00 && rune <= 0x9FFF) ||
      (rune >= 0x3400 && rune <= 0x4DBF);
}

bool _isLatinRune(int rune) {
  return (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
}
