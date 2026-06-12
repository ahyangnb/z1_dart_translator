import 'dart:io';

import 'package:z1_dart_translator/translator.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final parsed = _parseArgs(args);
  if (parsed.error != null) {
    stderr.writeln(parsed.error);
    _printUsage();
    exitCode = 64;
    return;
  }

  final input = parsed.text.isEmpty ? '我喜欢学习自然语言处理。' : parsed.text;
  final engine = MicroscopeTranslator();
  final result = engine.translate(
    input,
    sourceLanguage: parsed.from,
    targetLanguage: parsed.to,
  );

  stdout.write(result.toMicroscopeReport());
}

void _printUsage() {
  stdout.writeln(
      '用法: dart run bin/z1_translate.dart [--from=zh|en] [--to=zh|en] 文本');
  stdout.writeln('示例: dart run bin/z1_translate.dart "我喜欢学习自然语言处理。"');
  stdout.writeln(
      '示例: dart run bin/z1_translate.dart --from=en --to=zh "I like to learn natural language processing."');
}

_ParsedArgs _parseArgs(List<String> args) {
  Language? from;
  Language? to;
  final words = <String>[];

  for (final arg in args) {
    if (arg.startsWith('--from=')) {
      from = _parseLanguage(arg.substring('--from='.length));
      if (from == null) return const _ParsedArgs(error: '无法识别 --from 参数。');
    } else if (arg.startsWith('--to=')) {
      to = _parseLanguage(arg.substring('--to='.length));
      if (to == null) return const _ParsedArgs(error: '无法识别 --to 参数。');
    } else {
      words.add(arg);
    }
  }

  return _ParsedArgs(
    text: words.join(' '),
    from: from,
    to: to,
  );
}

Language? _parseLanguage(String raw) {
  switch (raw.toLowerCase()) {
    case 'zh':
    case 'cn':
    case 'chinese':
    case '中文':
      return Language.chinese;
    case 'en':
    case 'english':
    case '英文':
      return Language.english;
    default:
      return null;
  }
}

class _ParsedArgs {
  const _ParsedArgs({
    this.text = '',
    this.from,
    this.to,
    this.error,
  });

  final String text;
  final Language? from;
  final Language? to;
  final String? error;
}
