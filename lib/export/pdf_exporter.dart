import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:payv/payv.dart';

import '../models/book.dart';
import 'exporter_base.dart';

/// Real vector PDF with OpenType shaping, so Urdu joins and ligatures render
/// correctly. Works on desktop, Android and web because payv is pure Dart.
class PdfExporter extends BookExporter {
  @override
  String get id => 'pdf';
  @override
  String get label => 'PDF document';
  @override
  String get extension => 'pdf';
  @override
  String get mimeType => 'application/pdf';

  @override
  Future<Uint8List> export(Book book) async {
    final nastaliq = await _loadFont('assets/fonts/NotoNastaliqUrdu.ttf');
    final naskh = await _loadFont('assets/fonts/NotoNaskhArabic.ttf');
    final document = PayvDocument(
      title: book.title,
      author: book.author,
      language: book.languageCode,
    );

    const margin = 56.0;
    const gap = 10.0;
    final width = PageFormat.a4.width - 2 * margin;
    var page = document.addPage(format: PageFormat.a4);
    var top = page.height - margin;

    void newPage() {
      page = document.addPage(format: PageFormat.a4);
      top = page.height - margin;
    }

    void write(String text, TextStyleData style, bool rtl, {double? sizeOverride}) {
      if (text.trim().isEmpty) return;
      final family = style.fontFamily == 'Noto Naskh Arabic' ? naskh : nastaliq;
      final font = style.bold ? family.weight(700) : family.weight(400);
      final size = sizeOverride ?? style.fontSize;
      final pdfStyle = TextStyle(
        font: font,
        size: size,
        color: PdfColor.hex(style.color & 0xFFFFFF),
        letterSpacing: style.letterSpacing,
        lineHeight: size * style.lineHeight,
        language: book.languageCode,
      );

      var remaining = text;
      for (var attempt = 0; attempt < 100 && remaining.isNotEmpty; attempt++) {
        final available = top - margin;
        if (available < size * 2) {
          newPage();
          continue;
        }
        final charsPerLine = math.max(1, width / (size * 0.55));
        final lines = (remaining.length / charsPerLine).ceil();
        final wanted = lines * size * style.lineHeight + size * 2;
        final height = math.min(wanted, available);
        final rest = page.textBox(
          remaining,
          rect: PdfRect(margin, top - height, width, height),
          style: pdfStyle,
          align: PayvTextAlign.start,
        );
        top -= height + gap;
        if (rest == null || rest == remaining) return;
        remaining = rest;
        newPage();
      }
    }

    final base = TextStyleData(
      fontFamily: book.isRtl ? 'Noto Nastaliq Urdu' : 'Noto Naskh Arabic',
    );
    write(book.title, base, book.isRtl, sizeOverride: 20);
    if (book.author.isNotEmpty) write(book.author, base, book.isRtl);
    for (final chapter in book.chapters) {
      newPage();
      write(chapter.title, base, book.isRtl, sizeOverride: 20);
      for (final block in chapter.blocks) {
        write(
          block.text,
          block.style,
          block.resolvedRtl(book.languageCode),
          sizeOverride: switch (block.type) {
            BlockType.heading1 => 20.0,
            BlockType.heading2 => 16.0,
            BlockType.heading3 => 14.0,
            _ => null,
          },
        );
      }
    }
    return document.save();
  }

  Future<PayvFont> _loadFont(String asset) async {
    final data = await rootBundle.load(asset);
    return PayvFont.load(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
