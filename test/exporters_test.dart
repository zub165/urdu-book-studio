import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urdu_book_studio/core/text_direction.dart';
import 'package:urdu_book_studio/export/exporter.dart';
import 'package:urdu_book_studio/models/book.dart';
import 'package:urdu_book_studio/services/ai_service.dart';
import 'package:urdu_book_studio/storage/book_importer.dart';

Book sampleBook() {
  final book = Book.create(title: 'اردو کتاب', author: 'ملک', languageCode: 'ur');
  book.chapters.first.blocks.add(Block(text: 'یہ ایک جملہ ہے۔'));
  return book;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('language helpers', () {
    test('Urdu and Arabic are right-to-left', () {
      expect(isRtlLanguage('ur'), isTrue);
      expect(isRtlLanguage('ur-PK'), isTrue);
      expect(isRtlLanguage('ar'), isTrue);
    });

    test('English is left-to-right', () {
      expect(isRtlLanguage('en'), isFalse);
    });

    test('Western digits convert to Urdu digits', () {
      expect(toUrduDigits('2026'), '۲۰۲۶');
    });
  });

  group('EPUB import', () {
    test('round-trips exported chapters and metadata', () async {
      final book = sampleBook();
      book.chapters.first.title = 'پہلا باب';
      final bytes = await EpubExporter().export(book);
      final restored = await const BookImporter(languageCode: 'ur')
          .import(bytes, 'book.epub');
      expect(restored.title, book.title);
      expect(restored.author, book.author);
      expect(restored.languageCode, 'ur');
      expect(restored.allChapters, isNotEmpty);
      final allText = restored.allChapters
          .expand((c) => c.blocks)
          .map((block) => block.text)
          .join('\n');
      final titles = restored.allChapters.map((c) => c.title).join('\n');
      expect(allText, contains('یہ ایک جملہ ہے۔'));
      expect('$titles\n$allText', contains('پہلا باب'));
    });

    test('reads a third-party EPUB with relative paths and entities', () async {
      final archive = Archive()
        ..addFile(zipTextEntry('mimetype', 'application/epub+zip'))
        ..addFile(zipTextEntry(
          'META-INF/container.xml',
          '<?xml version="1.0"?><container xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
          '<rootfiles><rootfile full-path="OPS/package.opf" '
          'media-type="application/oebps-package+xml"/></rootfiles></container>',
        ))
        ..addFile(zipTextEntry(
          'OPS/package.opf',
          '<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" '
          'xmlns:dc="http://purl.org/dc/elements/1.1/" version="3.0" '
          'unique-identifier="bookid"><metadata>'
          '<dc:title>Sample EPUB</dc:title><dc:creator>Tester</dc:creator>'
          '<dc:language>en</dc:language></metadata><manifest>'
          '<item id="c1" href="Text/ch1.xhtml" media-type="application/xhtml+xml"/>'
          '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" '
          'properties="nav"/></manifest><spine>'
          '<itemref idref="nav" linear="no"/><itemref idref="c1"/>'
          '</spine></package>',
        ))
        ..addFile(zipTextEntry(
          'OPS/Text/ch1.xhtml',
          '<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml">'
          '<head><title>Chapter One</title></head><body>'
          '<h1>Chapter One</h1><p>Hello &amp; welcome</p>'
          '<blockquote>Quoted text</blockquote></body></html>',
        ));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      final restored = await const BookImporter(languageCode: 'ur')
          .import(bytes, 'book.epub');
      expect(restored.title, 'Sample EPUB');
      expect(restored.author, 'Tester');
      expect(restored.languageCode, 'en');
      expect(restored.chapters, hasLength(1));
      expect(restored.chapters.first.title, 'Chapter One');
      final blocks = restored.chapters.first.blocks;
      expect(blocks[0].text, 'Hello & welcome');
      expect(blocks[0].type, BlockType.paragraph);
      expect(blocks[1].text, 'Quoted text');
      expect(blocks[1].type, BlockType.quote);
    });

    test('rejects a zip without a container', () async {
      final archive = Archive()
        ..addFile(zipTextEntry('mimetype', 'application/epub+zip'));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
      await expectLater(
        () => const BookImporter().import(bytes, 'broken.epub'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('exporters', () {
    test('DOCX is a zip containing word/document.xml with bidi paragraphs', () async {
      final bytes = await DocxExporter().export(sampleBook());
      final archive = ZipDecoder().decodeBytes(bytes);
      final doc = archive.findFile('word/document.xml');
      expect(doc, isNotNull);
      final xml = utf8.decode(doc!.content as List<int>);
      expect(xml, contains('<w:bidi/>'));
      expect(xml, contains('یہ ایک جملہ ہے۔'));
    });

    test('EPUB starts with an uncompressed mimetype entry', () async {
      final bytes = await EpubExporter().export(sampleBook());
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.files.first.name, 'mimetype');
      expect(archive.findFile('OEBPS/content.opf'), isNotNull);
      final opf = utf8.decode(
          archive.findFile('OEBPS/content.opf')!.content as List<int>);
      expect(opf, contains('page-progression-direction="rtl"'));
    });

    test('RTF escapes Urdu as Unicode codes', () async {
      final bytes = await RtfExporter().export(sampleBook());
      final rtf = utf8.decode(bytes);
      expect(rtf, startsWith('{\\rtf1'));
      expect(rtf, contains('\\rtlpar'));
      expect(rtf, contains('\\u'));
    });

    test('PDF is a real PDF document with embedded fonts', () async {
      final bytes = await PdfExporter().export(sampleBook());
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes), contains('NotoNastaliqUrdu'));
    });

    test('text style keeps letter spacing in JSON', () {
      const style = TextStyleData(letterSpacing: 1.5, color: 0xFF123456);
      final restored = TextStyleData.fromJson(style.toJson());
      expect(restored.letterSpacing, 1.5);
      expect(restored.color, 0xFF123456);
    });

    test('legacy centered blocks keep center alignment', () {
      final block = Block.fromJson({'type': 'centered', 'text': 'Centered'});
      expect(block.alignment, BlockAlignment.center);
    });

    test('paragraph alignment round-trips in JSON', () async {
      final book = sampleBook();
      book.chapters.first.blocks.first.alignment = BlockAlignment.justify;
      final bytes = await JsonExporter().export(book);
      final restored = await const BookImporter(languageCode: 'ur')
          .import(bytes, 'book.json');
      expect(
        restored.chapters.first.blocks.first.alignment,
        BlockAlignment.justify,
      );
    });

    test('alignment is written to DOCX, HTML and RTF', () async {
      final book = sampleBook();
      book.chapters.first.blocks.first.alignment = BlockAlignment.justify;

      final docx = ZipDecoder().decodeBytes(await DocxExporter().export(book));
      final xml = utf8.decode(docx.findFile('word/document.xml')!.content as List<int>);
      expect(xml, contains('<w:jc w:val="both"/>'));

      final html = bookToHtml(book);
      expect(html, contains('text-align:justify;'));

      final rtf = utf8.decode(await RtfExporter().export(book));
      expect(rtf, contains(r'\qj'));
    });

    test('JSON book file round-trips with styles', () async {
      final book = sampleBook();
      book.chapters.first.blocks.first.style = const TextStyleData(
        fontFamily: 'Noto Naskh Arabic',
        color: 0xFF123456,
        letterSpacing: 1.5,
      );
      final bytes = await JsonExporter().export(book);
      final restored = await const BookImporter(languageCode: 'ur')
          .import(bytes, 'book.json');
      expect(restored.title, book.title);
      expect(restored.chapters.first.blocks.length,
          book.chapters.first.blocks.length);
      expect(
        restored.chapters.first.blocks.first.style.color,
        0xFF123456,
      );
      expect(
        restored.chapters.first.blocks.first.style.letterSpacing,
        1.5,
      );
    });

    test('markdown import keeps heading templates', () async {
      final bytes = Uint8List.fromList(utf8.encode('# Title\n## سرخی\nمتن'));
      final book = await const BookImporter(languageCode: 'ur')
          .import(bytes, 'book.md');
      final blocks = book.chapters.first.blocks;
      expect(blocks[0].type, BlockType.heading1);
      expect(blocks[1].type, BlockType.heading2);
      expect(blocks[2].type, BlockType.paragraph);
    });

    test('AI prompts include source, target and outline markers', () {
      final translation = translationPrompt(
        text: 'Hello',
        sourceLanguage: 'English',
        targetLanguage: 'Urdu',
        urduDigits: true,
      );
      expect(translation, contains('English'));
      expect(translation, contains('Urdu'));
      expect(translation, contains(' Urdu digits'));
      final outline = outlinePrompt(topic: 'Poetry', language: 'Urdu');
      expect(outline, contains('H1:'));
      expect(outline, contains('H2:'));
    });

    test('Ollama uses a model available on the configured server', () {
      expect(AiProvider.ollama.defaultModel, 'qwen2.5:3b');
      expect(const AiSettings().model, 'qwen2.5:3b');
      final restored = AiSettings.fromJson({
        'provider': 'ollama',
        'model': 'llama3.2',
        'apiKey': '',
        'backendUrl': 'https://api.docsoncalls.com/ollama',
      });
      expect(restored.model, 'qwen2.5:3b');
    });

    test('every registered exporter returns bytes', () async {
      for (final exporter in kExporters) {
        final bytes = await exporter.export(sampleBook());
        expect(bytes, isNotEmpty, reason: exporter.id);
      }
    });
  });
}
