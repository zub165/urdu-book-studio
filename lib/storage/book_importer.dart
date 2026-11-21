import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../models/book.dart';

/// Reads a book file back into the editor. JSON keeps all formatting; the
/// text formats create an editable book from their paragraphs and headings.
class BookImporter {
  final String languageCode;

  const BookImporter({this.languageCode = 'ur'});

  Future<Book> import(Uint8List bytes, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'json' => _fromJson(bytes),
      'txt' => _fromPlainText(utf8.decode(bytes, allowMalformed: true)),
      'md' || 'markdown' => _fromMarkdown(utf8.decode(bytes, allowMalformed: true)),
      'docx' => await _fromDocx(bytes),
      'rtf' => _fromRtf(utf8.decode(bytes, allowMalformed: true)),
      _ => throw UnsupportedError('Unsupported file type: .$extension'),
    };
  }

  Book _fromJson(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    decoded['id'] = const Uuid().v4();
    return Book.fromJson(decoded);
  }

  Book _withBlocks(List<Block> blocks, {String title = 'Imported book'}) {
    final book = Book.create(
      title: title,
      author: '',
      languageCode: languageCode,
    );
    book.chapters
      ..clear()
      ..add(Chapter(title: 'Imported chapter', blocks: blocks));
    if (book.chapters.first.blocks.isEmpty) {
      book.chapters.first.blocks.add(Block(style: defaultStyleFor(languageCode)));
    }
    return book;
  }

  Book _fromPlainText(String text) {
    final style = defaultStyleFor(languageCode);
    final blocks = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => Block(text: line, style: style))
        .toList();
    return _withBlocks(blocks);
  }

  Book _fromMarkdown(String text) {
    final style = defaultStyleFor(languageCode);
    final blocks = <Block>[];
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) continue;
      if (line.startsWith('### ')) {
        blocks.add(Block(type: BlockType.heading3, text: line.substring(4), style: style));
      } else if (line.startsWith('## ')) {
        blocks.add(Block(type: BlockType.heading2, text: line.substring(3), style: style));
      } else if (line.startsWith('# ')) {
        blocks.add(Block(type: BlockType.heading1, text: line.substring(2), style: style));
      } else if (line.startsWith('> ')) {
        blocks.add(Block(type: BlockType.quote, text: line.substring(2), style: style));
      } else {
        blocks.add(Block(text: line.trim(), style: style));
      }
    }
    return _withBlocks(blocks);
  }

  Future<Book> _fromDocx(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final document = archive.findFile('word/document.xml');
    if (document == null) throw const FormatException('Not a valid DOCX file.');
    final xml = XmlDocument.parse(utf8.decode(document.content as List<int>));
    final style = defaultStyleFor(languageCode);
    final blocks = <Block>[];
    for (final paragraph in xml.descendants.whereType<XmlElement>()) {
      if (paragraph.name.local != 'p') continue;
      final text = paragraph.descendants
          .whereType<XmlText>()
          .map((node) => node.value)
          .join()
          .trim();
      if (text.isEmpty) continue;
      final styleName = paragraph.descendants.whereType<XmlElement>().firstWhere(
            (node) => node.name.local == 'pStyle',
            orElse: () => paragraph,
          );
      final value = styleName.attributes
          .where((attribute) => attribute.name.local == 'val')
          .map((attribute) => attribute.value.toLowerCase())
          .join();
      final type = switch (value) {
        final v when v.contains('heading1') || v == '1' => BlockType.heading1,
        final v when v.contains('heading2') || v == '2' => BlockType.heading2,
        final v when v.contains('heading3') || v == '3' => BlockType.heading3,
        _ => BlockType.paragraph,
      };
      blocks.add(Block(type: type, text: text, style: style));
    }
    return _withBlocks(blocks);
  }

  Book _fromRtf(String source) {
    final plain = source
        .replaceAll(RegExp(r'\\fonttbl.*?\}'), '')
        .replaceAll(RegExp(r'\\colortbl.*?\}'), '')
        .replaceAll(RegExp(r'\\stylesheet.*?\}'), '')
        .replaceAllMapped(RegExp(r'\\u(-?\d+)\??'), (match) {
          final code = int.parse(match.group(1)!);
          return String.fromCharCode(code < 0 ? code + 65536 : code);
        })
        .replaceAll(RegExp(r'\\(par|line|row)\b ?'), '\n')
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '')
        .replaceAll(RegExp(r'[{}]'), '');
    return _fromPlainText(plain);
  }
}
