import 'language.dart';
import 'token.dart';
import 'translation_unit.dart';

class TranslationRenderer {
  const TranslationRenderer();

  String render(Language targetLanguage, List<TranslationUnit> units) {
    switch (targetLanguage) {
      case Language.chinese:
        return _renderChinese(units);
      case Language.english:
        return _renderEnglish(units);
    }
  }

  String _renderChinese(List<TranslationUnit> units) {
    final buffer = StringBuffer();
    for (final unit in units.where((unit) => !unit.omitted)) {
      if (unit.kind == TokenKind.punctuation) {
        buffer.write(_toChinesePunctuation(unit.targetText));
      } else {
        buffer.write(unit.targetText);
      }
    }
    return buffer.toString();
  }

  String _renderEnglish(List<TranslationUnit> units) {
    final buffer = StringBuffer();

    for (final unit in units.where((unit) => !unit.omitted)) {
      if (unit.targetText.isEmpty) continue;
      if (unit.kind == TokenKind.punctuation) {
        buffer.write(_toEnglishPunctuation(unit.targetText));
        continue;
      }

      if (buffer.isNotEmpty &&
          !_endsWithOpeningPunctuation(buffer.toString())) {
        buffer.write(' ');
      }
      buffer.write(unit.targetText);
    }

    return _capitalizeFirstLetter(buffer.toString());
  }

  String _capitalizeFirstLetter(String text) {
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      final isLowercase = code >= 0x61 && code <= 0x7A;
      if (isLowercase) {
        return text.replaceRange(i, i + 1, String.fromCharCode(code - 32));
      }
      final isUppercase = code >= 0x41 && code <= 0x5A;
      if (isUppercase) return text;
    }
    return text;
  }

  bool _endsWithOpeningPunctuation(String text) {
    return text.endsWith('(') ||
        text.endsWith('[') ||
        text.endsWith('{') ||
        text.endsWith('"') ||
        text.endsWith("'");
  }

  String _toChinesePunctuation(String text) {
    return const {
          ',': '，',
          '.': '。',
          '?': '？',
          '!': '！',
          ':': '：',
          ';': '；',
          '(': '（',
          ')': '）',
        }[text] ??
        text;
  }

  String _toEnglishPunctuation(String text) {
    return const {
          '，': ',',
          '。': '.',
          '？': '?',
          '！': '!',
          '：': ':',
          '；': ';',
          '（': '(',
          '）': ')',
          '、': ',',
        }[text] ??
        text;
  }
}
