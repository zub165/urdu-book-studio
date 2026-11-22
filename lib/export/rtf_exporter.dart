import 'dart:convert';
import 'dart:typed_data';

import '../models/book.dart';
import 'exporter_base.dart';

/// Builds Rich Text Format. Non-ASCII text is written as \uN escapes with a
/// fallback character, so Urdu survives in any RTF reader.
class RtfExporter extends BookExporter {
  @override
  String get id => 'rtf';
  @override
  String get label => 'Rich Text (RTF)';
  @override
  String get extension => 'rtf';
  @override
  String get mimeType => 'application/rtf';

  @override
  Future<Uint8List> export(Book book) async =>
      Uint8List.fromList(utf8.encode(buildRtf(book)));

  String buildRtf(Book book) {
    final lang = book.languageCode;
    final fonts = <String, int>{};
    int fontIndex(String name) => fonts.putIfAbsent(name, () => fonts.length);
    final body = StringBuffer();

    void para(String text, BlockType type, TextStyleData s, bool rtl) {
      final heading = type == BlockType.heading1 ||
          type == BlockType.heading2 ||
          type == BlockType.heading3;
      final sizePt = switch (type) {
        BlockType.heading1 => 20.0,
        BlockType.heading2 => 16.0,
        BlockType.heading3 => 14.0,
        _ => s.fontSize,
      };
      final fs = (sizePt * 2).round();
      final centered = type == BlockType.centered || type == BlockType.heading1;
      final align = centered ? r'\qc' : (rtl ? r'\qr' : r'\ql');
      final dir = rtl ? r'\rtlpar' : r'\ltrpar';
      final bold = heading || s.bold;
      final italic = type == BlockType.quote || s.italic;
      final flags = [
        bold ? r'\b' : r'\b0',
        italic ? r'\i' : r'\i0',
        s.underline ? r'\ul' : r'\ulnone',
        if (s.letterSpacing != 0)
          '\\expndtw${(s.letterSpacing * 20).round()}',
        if (rtl) r'\rtlch',
        if (lang == 'ur') r'\lang1056',
      ].join();
      final f = fontIndex(s.fontFamily);
      body.write('\\pard$dir$align\\f$f\\fs$fs$flags ${_rtfEscape(text)}\\par\n');
    }

    final base = TextStyleData(fontFamily: book.isRtl ? 'Noto Nastaliq Urdu' : 'Roboto');
        for (final chapter in book.allChapters) {
      body.write('\\page\n');
      para(chapter.title, BlockType.heading1, base, book.isRtl);
      for (final block in chapter.blocks) {
        para(block.text, block.type, block.style, block.resolvedRtl(lang));
      }
    }

    fontIndex('Roboto'); // make sure the font table is never empty
    final fontTable = fonts.entries
        .map((e) => '{\\f${e.value}\\fnil ${e.key};}')
        .join();
    return '{\\rtf1\\ansi\\ansicpg1252\\deff0\\uc1\\deflang1056\n'
        '{\\fonttbl$fontTable}\n'
        '\\paperw11906\\paperh16838\\margl1440\\margr1440\\margt1440\\margb1440\n'
        '$body}';
  }
}

String _rtfEscape(String text) {
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    if (unit == 0x5C || unit == 0x7B || unit == 0x7D) {
      out.write('\\${String.fromCharCode(unit)}');
    } else if (unit == 0x0A) {
      out.write('\\line ');
    } else if (unit < 0x80) {
      out.writeCharCode(unit);
    } else {
      final signed = unit > 0x7FFF ? unit - 0x10000 : unit;
      out.write('\\u$signed?');
    }
  }
  return out.toString();
}
