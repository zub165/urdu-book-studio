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
      'epub' => await _fromEpub(bytes),
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

  Future<Book> _fromEpub(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (file.isFile) files[_normalizeZipPath(file.name)] = file;
    }
    final containerFile = files['META-INF/container.xml'];
    if (containerFile == null) {
      throw const FormatException('Not a valid EPUB: missing META-INF/container.xml.');
    }
    final container = XmlDocument.parse(_readEntry(files, containerFile));
    final rootfile = container.descendants.whereType<XmlElement>().firstWhere(
          (node) => node.name.local == 'rootfile',
          orElse: () => throw const FormatException('EPUB has no root package.'),
        );
    final opfPath = _normalizeZipPath(_attr(rootfile, 'full-path'));
    final opfFile = files[opfPath];
    if (opfFile == null) {
      throw FormatException('EPUB package not found: $opfPath');
    }
    final opf = XmlDocument.parse(_readEntry(files, opfFile));

    String metaText(String localName) {
      for (final node in opf.descendants.whereType<XmlElement>()) {
        if (node.name.local == localName) {
          final value = _cleanText(_textContent(node));
          if (value.isNotEmpty) return value;
        }
      }
      return '';
    }

    final title = metaText('title').isEmpty ? 'Imported book' : metaText('title');
    final author = metaText('creator');
    final metaLanguage = metaText('language');
    final effectiveLanguage = metaLanguage.isEmpty ? languageCode : metaLanguage;
    final style = defaultStyleFor(effectiveLanguage);

    final manifest = <String, _ManifestItem>{};
    for (final item in opf.descendants.whereType<XmlElement>()) {
      if (item.name.local != 'item') continue;
      final id = _attr(item, 'id');
      if (id.isEmpty) continue;
      manifest[id] = _ManifestItem(
        href: _attr(item, 'href'),
        mediaType: _attr(item, 'media-type'),
        properties: _attr(item, 'properties'),
      );
    }

    final spineIds = <String>[];
    for (final ref in opf.descendants.whereType<XmlElement>()) {
      if (ref.name.local != 'itemref') continue;
      final linear = _attr(ref, 'linear');
      if (linear.isNotEmpty && linear.toLowerCase() == 'no') continue;
      final idref = _attr(ref, 'idref');
      if (idref.isNotEmpty && manifest.containsKey(idref)) spineIds.add(idref);
    }

    final chapters = <Chapter>[];
    for (final id in spineIds) {
      final item = manifest[id]!;
      final properties = item.properties.toLowerCase().split(RegExp(r'\s+'));
      if (properties.contains('nav')) continue;
      final path = _resolveZipPath(opfPath, item.href);
      final entry = files[path];
      if (entry == null) continue;
      final html = _readEntry(files, entry);
      final extracted = _parseXhtml(html, style);
      if (extracted.blocks.isEmpty && extracted.title.isEmpty) continue;
      chapters.add(Chapter(
        title: extracted.title.isEmpty ? 'Chapter ${chapters.length + 1}' : extracted.title,
        blocks: extracted.blocks.isEmpty
            ? [Block(style: style)]
            : extracted.blocks,
      ));
    }

    if (chapters.isEmpty) {
      throw const FormatException('EPUB has no readable chapters.');
    }
    final now = DateTime.now();
    return Book(
      id: const Uuid().v4(),
      title: title,
      author: author,
      languageCode: effectiveLanguage,
      createdAt: now,
      updatedAt: now,
      chapters: chapters,
    );
  }

  _EpubChapter _parseXhtml(String html, TextStyleData style) {
    try {
      final document = XmlDocument.parse(html);
      return _extractFromXml(document, style);
    } catch (_) {
      return _extractFromHtml(html, style);
    }
  }

  _EpubChapter _extractFromXml(XmlDocument document, TextStyleData style) {
    final body = document.descendants.whereType<XmlElement>().firstWhere(
          (node) => node.name.local == 'body',
          orElse: () => document.rootElement,
        );
    final blocks = <Block>[];
    var title = '';

    void walk(XmlElement element) {
      final local = element.name.local.toLowerCase();
      if (local == 'script' ||
          local == 'style' ||
          local == 'nav' ||
          local == 'head') {
        return;
      }
      if (local == 'h1') {
        final text = _cleanText(_textContent(element));
        if (title.isEmpty) {
          if (text.isNotEmpty) title = text;
          return;
        }
        if (text.isNotEmpty) {
          blocks.add(Block(type: BlockType.heading1, text: text, style: style));
        }
        return;
      }
      final type = _typeForTag(local);
      if (type != null) {
        final text = _cleanText(_textContent(element));
        if (text.isNotEmpty) blocks.add(Block(type: type, text: text, style: style));
        return;
      }
      final before = blocks.length;
      for (final child in element.children) {
        if (child is XmlElement) walk(child);
      }
      if (blocks.length == before) {
        final text = _cleanText(_textContent(element));
        if (text.isNotEmpty) blocks.add(Block(text: text, style: style));
      }
    }

    for (final child in body.children) {
      if (child is XmlElement) walk(child);
    }
    if (title.isEmpty) {
      for (final node in document.descendants.whereType<XmlElement>()) {
        if (node.name.local == 'title') {
          title = _cleanText(_textContent(node));
          if (title.isNotEmpty) break;
        }
      }
    }
    return _EpubChapter(title: title, blocks: blocks);
  }

  _EpubChapter _extractFromHtml(String html, TextStyleData style) {
    final blocks = <Block>[];
    var title = '';
    final pattern = RegExp(
      r'<(h[1-6]|p|blockquote|li|pre|center)\b[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );
    for (final match in pattern.allMatches(html)) {
      final tag = match.group(1)!.toLowerCase();
      final raw = match.group(2)!
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '');
      final text = _cleanText(_decodeEntities(raw));
      if (text.isEmpty) continue;
      if (tag == 'h1' && title.isEmpty) {
        title = text;
        continue;
      }
      final type = _typeForTag(tag) ?? BlockType.paragraph;
      blocks.add(Block(type: type, text: text, style: style));
    }
    if (title.isEmpty) {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>',
          caseSensitive: false, dotAll: true).firstMatch(html);
      if (titleMatch != null) {
        title = _cleanText(_decodeEntities(titleMatch.group(1)!));
      }
    }
    return _EpubChapter(title: title, blocks: blocks);
  }

  BlockType? _typeForTag(String tag) => switch (tag) {
        'h1' => BlockType.heading1,
        'h2' => BlockType.heading2,
        'h3' => BlockType.heading3,
        'h4' || 'h5' || 'h6' => BlockType.heading3,
        'blockquote' => BlockType.quote,
        'center' => BlockType.centered,
        _ => null,
      };

  String _textContent(XmlNode node) {
    final buffer = StringBuffer();
    void visit(XmlNode current) {
      if (current is XmlText) {
        buffer.write(current.value);
        return;
      }
      if (current is! XmlElement) return;
      final local = current.name.local.toLowerCase();
      if (local == 'script' || local == 'style') return;
      if (local == 'br') {
        buffer.write('\n');
        return;
      }
      for (final child in current.children) {
        visit(child);
      }
    }
    visit(node);
    return buffer.toString();
  }

  String _cleanText(String text) => text
      .replaceAll('\u00A0', ' ')
      .split(RegExp(r'\r\n?|\n'))
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');

  String _decodeEntities(String text) => text.replaceAllMapped(
        RegExp(r'&(#x[0-9a-fA-F]+|#\d+|amp|lt|gt|quot|apos|nbsp);'),
        (match) {
          final value = match.group(1)!;
          if (value.startsWith('#x')) {
            return String.fromCharCode(int.parse(value.substring(2), radix: 16));
          }
          if (value.startsWith('#')) {
            return String.fromCharCode(int.parse(value.substring(1)));
          }
          return switch (value) {
            'amp' => '&',
            'lt' => '<',
            'gt' => '>',
            'quot' => '"',
            'apos' => "'",
            'nbsp' => ' ',
            _ => match.group(0)!,
          };
        },
      );

  String _attr(XmlElement element, String localName) => element.attributes
      .where((attribute) => attribute.name.local == localName)
      .map((attribute) => attribute.value)
      .firstOrNull ?? '';

  String _readEntry(Map<String, ArchiveFile> files, ArchiveFile file) =>
      utf8.decode(file.content as List<int>, allowMalformed: true);

  String _normalizeZipPath(String name) {
    var path = name.replaceAll('\\', '/');
    while (path.startsWith('./')) {
      path = path.substring(2);
    }
    if (path.startsWith('/')) path = path.substring(1);
    return path;
  }

  String _resolveZipPath(String opfPath, String href) {
    final clean = Uri.decodeComponent(href.split('#').first.split('?').first)
        .replaceAll('\\', '/');
    if (clean.startsWith('/')) return _normalizeZipPath(clean);
    final opfParts = opfPath.split('/')..removeLast();
    final parts = [...opfParts, ...clean.split('/')];
    final resolved = <String>[];
    for (final part in parts) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (resolved.isNotEmpty) resolved.removeLast();
      } else {
        resolved.add(part);
      }
    }
    return resolved.join('/');
  }
}

class _ManifestItem {
  final String href;
  final String mediaType;
  final String properties;

  const _ManifestItem({
    required this.href,
    required this.mediaType,
    required this.properties,
  });
}

class _EpubChapter {
  final String title;
  final List<Block> blocks;

  const _EpubChapter({required this.title, required this.blocks});
}
