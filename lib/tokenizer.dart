import 'dart:math' as math;

import 'language.dart';
import 'lexicon.dart';
import 'token.dart';

class MicroscopeTokenizer {
  const MicroscopeTokenizer(this.lexicon);

  final TinyTranslationLexicon lexicon;

  List<Token> tokenize(Language language, String text) {
    switch (language) {
      case Language.chinese:
        return _tokenizeChinese(text);
      case Language.english:
        return _tokenizeEnglish(text);
    }
  }

  List<Token> _tokenizeChinese(String text) {
    final chars = text.runes.map(String.fromCharCode).toList();
    final terms = lexicon.sourceTerms(Language.chinese);
    final tokens = <Token>[];
    var i = 0;

    while (i < chars.length) {
      final char = chars[i];
      if (char.trim().isEmpty) {
        i++;
        continue;
      }

      if (_isPunctuation(char)) {
        tokens.add(Token(
          text: char,
          normalized: char,
          kind: TokenKind.punctuation,
          start: i,
          end: i + 1,
        ));
        i++;
        continue;
      }

      if (_isAsciiWordChar(char)) {
        final start = i;
        while (i < chars.length && _isAsciiWordChar(chars[i])) {
          i++;
        }
        final raw = chars.sublist(start, i).join();
        tokens.add(Token(
          text: raw,
          normalized: raw,
          kind: RegExp(r'^\d+$').hasMatch(raw)
              ? TokenKind.number
              : TokenKind.word,
          start: start,
          end: i,
        ));
        continue;
      }

      final remaining = chars.sublist(i).join();
      String? matched;
      for (final term in terms) {
        if (remaining.startsWith(term)) {
          matched = term;
          break;
        }
      }

      if (matched == null) {
        tokens.add(Token(
          text: char,
          normalized: char,
          kind: TokenKind.unknown,
          start: i,
          end: i + 1,
        ));
        i++;
      } else {
        final size = matched.runes.length;
        tokens.add(Token(
          text: matched,
          normalized: matched,
          kind: size > 1 ? TokenKind.phrase : TokenKind.word,
          start: i,
          end: i + size,
        ));
        i += size;
      }
    }

    return tokens;
  }

  List<Token> _tokenizeEnglish(String text) {
    final rawTokens = <Token>[];
    final pattern =
        RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?|\d+(?:\.\d+)?|[^\sA-Za-z\d]");

    for (final match in pattern.allMatches(text)) {
      final raw = match.group(0)!;
      final kind = _tokenKindForEnglish(raw);
      rawTokens.add(Token(
        text: raw,
        normalized: TinyTranslationLexicon.normalizeTerm(Language.english, raw),
        kind: kind,
        start: match.start,
        end: match.end,
      ));
    }

    return _groupEnglishPhrases(rawTokens);
  }

  List<Token> _groupEnglishPhrases(List<Token> rawTokens) {
    final grouped = <Token>[];
    final maxPhraseSize = lexicon.maxSourceTermSize(Language.english);
    var i = 0;

    while (i < rawTokens.length) {
      final token = rawTokens[i];
      if (token.kind != TokenKind.word) {
        grouped.add(token);
        i++;
        continue;
      }

      Token? matched;
      final maxSize = math.min(maxPhraseSize, rawTokens.length - i);
      for (var size = maxSize; size >= 2; size--) {
        final slice = rawTokens.sublist(i, i + size);
        if (slice.any((item) => item.kind != TokenKind.word)) continue;

        final phrase = slice.map((item) => item.normalized).join(' ');
        if (lexicon.lookup(Language.english, phrase) == null) continue;

        matched = Token(
          text: slice.map((item) => item.text).join(' '),
          normalized: phrase,
          kind: TokenKind.phrase,
          start: slice.first.start,
          end: slice.last.end,
        );
        break;
      }

      if (matched == null) {
        grouped.add(token);
        i++;
      } else {
        grouped.add(matched);
        i += TinyTranslationLexicon.termSize(
            Language.english, matched.normalized);
      }
    }

    return grouped;
  }

  TokenKind _tokenKindForEnglish(String raw) {
    if (_isPunctuation(raw)) return TokenKind.punctuation;
    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(raw)) return TokenKind.number;
    if (RegExp(r'^[A-Za-z]').hasMatch(raw)) return TokenKind.word;
    return TokenKind.unknown;
  }
}

bool _isAsciiWordChar(String char) {
  final rune = char.runes.single;
  return (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5A) ||
      (rune >= 0x61 && rune <= 0x7A) ||
      char == '_' ||
      char == '-';
}

bool _isPunctuation(String text) {
  return const {
    ',',
    '.',
    '?',
    '!',
    ':',
    ';',
    '(',
    ')',
    '[',
    ']',
    '{',
    '}',
    '"',
    "'",
    '，',
    '。',
    '？',
    '！',
    '：',
    '；',
    '、',
    '（',
    '）',
    '“',
    '”',
    '‘',
    '’',
  }.contains(text);
}
