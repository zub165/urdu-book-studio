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

    test('every registered exporter returns bytes', () async {
      for (final exporter in kExporters) {
        final bytes = await exporter.export(sampleBook());
        expect(bytes, isNotEmpty, reason: exporter.id);
      }
    });
  });
}
