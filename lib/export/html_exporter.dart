import 'dart:convert';
import 'dart:typed_data';

import '../models/book.dart';
import 'exporter_base.dart';

String cssForStyle(TextStyleData s) =>
    "font-family:'${s.fontFamily}',serif;"
    'font-size:${s.fontSize}pt;'
    'font-weight:${s.bold ? 'bold' : 'normal'};'
    'font-style:${s.italic ? 'italic' : 'normal'};'
    'text-decoration:${s.underline ? 'underline' : 'none'};'
    'color:#${hexRgb(s.color)};'
    'line-height:${s.lineHeight};';

/// Renders one block as an HTML element with direction and inline style.
/// Also used by the EPUB exporter (output is valid XHTML).
String blockToHtml(Block b, String languageCode) {
  final tag = switch (b.type) {
    BlockType.heading1 => 'h1',
    BlockType.heading2 => 'h2',
    BlockType.heading3 => 'h3',
    BlockType.quote => 'blockquote',
    _ => 'p',
  };
  final centered = b.type == BlockType.centered;
  final cls = centered ? ' class="center"' : '';
  final dir = b.resolvedRtl(languageCode) ? 'rtl' : 'ltr';
  final style = cssForStyle(b.style) + (centered ? 'text-align:center;' : '');
  final inner = xmlEscape(b.text).replaceAll('\n', '<br/>');
  return '<$tag$cls dir="$dir" style="$style">$inner</$tag>';
}

/// A complete HTML document. With [forWord] it adds the Office namespaces
/// so Microsoft Word opens it as a document.
String bookToHtml(Book book, {bool forWord = false}) {
  final lang = book.languageCode;
  final dir = book.isRtl ? 'rtl' : 'ltr';
  final ns = forWord
      ? ' xmlns:w="urn:schemas-microsoft-com:office:word"'
          ' xmlns:o="urn:schemas-microsoft-com:office:office"'
      : '';
  final buffer = StringBuffer()
    ..write('<!DOCTYPE html>\n<html$ns lang="$lang" dir="$dir">\n<head>\n')
    ..write('<meta charset="utf-8"/>\n')
    ..write('<title>${xmlEscape(book.title)}</title>\n')
    ..write('<style>'
        'body{font-family:serif;line-height:1.8;}'
        'h1{text-align:center;font-weight:bold;}'
        'h2,h3{font-weight:bold;}'
        '.center{text-align:center;}'
        'blockquote{margin:1em 2em;font-style:italic;}'
        '</style>\n')
    ..write('</head>\n<body dir="$dir">\n')
    ..write('<h1 class="center">${xmlEscape(book.title)}</h1>\n');
  if (book.author.isNotEmpty) {
    buffer.write('<p class="center">${xmlEscape(book.author)}</p>\n');
  }
  for (final chapter in book.chapters) {
    buffer
      ..write('<div style="page-break-before:always"></div>\n')
      ..write('<section>\n<h1>${xmlEscape(chapter.title)}</h1>\n');
    for (final block in chapter.blocks) {
      buffer.writeln(blockToHtml(block, lang));
    }
    buffer.write('</section>\n');
  }
  buffer.write('</body>\n</html>\n');
  return buffer.toString();
}

class HtmlExporter extends BookExporter {
  @override
  String get id => 'html';
  @override
  String get label => 'Web page (HTML)';
  @override
  String get extension => 'html';
  @override
  String get mimeType => 'text/html';

  @override
  Future<Uint8List> export(Book book) async =>
      Uint8List.fromList(utf8.encode(bookToHtml(book)));
}

/// Legacy .doc. Word reads HTML saved with this extension. It is not the
/// binary Word 97-2003 format; use DOCX when possible.
class DocExporter extends BookExporter {
  @override
  String get id => 'doc';
  @override
  String get label => 'Word 97-2003 (DOC, HTML-based)';
  @override
  String get extension => 'doc';
  @override
  String get mimeType => 'application/msword';

  @override
  Future<Uint8List> export(Book book) async =>
      Uint8List.fromList(utf8.encode(bookToHtml(book, forWord: true)));
}
