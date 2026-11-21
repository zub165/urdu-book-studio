import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urdu_book_studio/core/text_direction.dart';
import 'package:urdu_book_studio/export/exporter.dart';
import 'package:urdu_book_studio/models/book.dart';

Book sampleBook() {
  final book = Book.create(title: 'اردو کتاب', author: 'ملک', languageCode: 'ur');
  book.chapters.first.blocks.add(Block(text: 'یہ ایک جملہ ہے۔'));
  return book;
}

void main() {
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

    test('every registered exporter returns bytes', () async {
      for (final exporter in kExporters) {
        final bytes = await exporter.export(sampleBook());
        expect(bytes, isNotEmpty, reason: exporter.id);
      }
    });
  });
}
