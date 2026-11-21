import 'dart:convert';
import 'dart:typed_data';

import '../models/book.dart';
import 'exporter_base.dart';

/// Plain text with a UTF-8 byte-order mark, so Windows Notepad shows Urdu
/// correctly.
class TxtExporter extends BookExporter {
  @override
  String get id => 'txt';
  @override
  String get label => 'Plain text (TXT)';
  @override
  String get extension => 'txt';
  @override
  String get mimeType => 'text/plain';

  @override
  Future<Uint8List> export(Book book) async =>
      Uint8List.fromList(utf8.encode('\uFEFF${buildPlainText(book)}'));

  static String buildPlainText(Book book) {
    final out = StringBuffer()
      ..writeln(book.title);
    if (book.author.isNotEmpty) out.writeln(book.author);
    out.writeln();
    for (final chapter in book.chapters) {
      out.writeln(chapter.title);
      out.writeln();
      for (final block in chapter.blocks) {
        if (block.text.trim().isEmpty) continue;
        out.writeln(block.text);
        out.writeln();
      }
    }
    return out.toString();
  }
}

class MarkdownExporter extends BookExporter {
  @override
  String get id => 'md';
  @override
  String get label => 'Markdown (MD)';
  @override
  String get extension => 'md';
  @override
  String get mimeType => 'text/markdown';

  @override
  Future<Uint8List> export(Book book) async =>
      Uint8List.fromList(utf8.encode(buildMarkdown(book)));

  static String buildMarkdown(Book book) {
    final lang = book.languageCode;
    final out = StringBuffer()..writeln('# ${book.title}');
    if (book.author.isNotEmpty) out.writeln('\n*${book.author}*');
    out.writeln();
    for (final chapter in book.chapters) {
      out.writeln('## ${chapter.title}\n');
      for (final block in chapter.blocks) {
        final text = block.text.trim();
        if (text.isEmpty) continue;
        final prefix = switch (block.type) {
          BlockType.heading1 => '# ',
          BlockType.heading2 => '## ',
          BlockType.heading3 => '### ',
          BlockType.quote => '> ',
          _ => '',
        };
        final line = '$prefix$text';
        // Markdown has no direction, so wrap RTL blocks in a dir="rtl" div.
        if (block.resolvedRtl(lang)) {
          out.writeln('<div dir="rtl">\n\n$line\n\n</div>\n');
        } else {
          out.writeln('$line\n');
        }
      }
    }
    return out.toString();
  }
}
