import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/book.dart';
import 'exporter_base.dart';

/// Builds a .docx (Office Open XML) file. Right-to-left paragraphs use
/// w:bidi and w:rtl, and runs carry the language tag so Word shapes Urdu.
class DocxExporter extends BookExporter {
  @override
  String get id => 'docx';
  @override
  String get label => 'Word (DOCX)';
  @override
  String get extension => 'docx';
  @override
  String get mimeType =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  @override
  Future<Uint8List> export(Book book) async {
    final archive = Archive()
      ..addFile(zipTextEntry('[Content_Types].xml', _contentTypes))
      ..addFile(zipTextEntry('_rels/.rels', _rels))
      ..addFile(zipTextEntry('word/document.xml', _document(book)));
    return zipToBytes(archive);
  }

  static const _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';

  static const _rels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';

  String _document(Book book) {
    final rtl = book.isRtl;
    final lang = book.languageCode;
    final base = TextStyleData(fontFamily: rtl ? 'Noto Nastaliq Urdu' : 'Roboto');
    final body = StringBuffer()
      ..write(_para(book.title, BlockType.heading1, base, rtl: rtl, lang: lang));
    if (book.author.isNotEmpty) {
      body.write(_para(book.author, BlockType.centered, base, rtl: rtl, lang: lang));
    }
    for (final chapter in book.chapters) {
      body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      body.write(_para(chapter.title, BlockType.heading1, base, rtl: rtl, lang: lang));
      for (final block in chapter.blocks) {
        body.write(_para(block.text, block.type, block.style,
            rtl: block.resolvedRtl(lang), lang: lang));
      }
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>$body'
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>'
        '</w:sectPr></w:body></w:document>';
  }

  String _para(String text, BlockType type, TextStyleData s,
      {required bool rtl, required String lang}) {
    final heading = type == BlockType.heading1 ||
        type == BlockType.heading2 ||
        type == BlockType.heading3;
    final sizePt = switch (type) {
      BlockType.heading1 => 20.0,
      BlockType.heading2 => 16.0,
      BlockType.heading3 => 14.0,
      _ => s.fontSize,
    };
    final half = (sizePt * 2).round();
    final bold = heading || s.bold;
    final italic = type == BlockType.quote || s.italic;
    final font = xmlEscape(s.fontFamily);

    final pPr = StringBuffer('<w:pPr>');
    if (rtl) pPr.write('<w:bidi/>');
    pPr.write('<w:spacing w:val="${(s.letterSpacing * 20).round()}" '
        'w:line="${(s.lineHeight * 240).round()}" w:lineRule="auto"/>');
    if (type == BlockType.quote) pPr.write('<w:ind w:left="720" w:right="720"/>');
    if (type == BlockType.centered || type == BlockType.heading1) {
      pPr.write('<w:jc w:val="center"/>');
    }
    pPr.write('</w:pPr>');

    final rPr = '<w:rPr>'
        '<w:rFonts w:ascii="$font" w:hAnsi="$font" w:cs="$font" w:eastAsia="$font"/>'
        '${bold ? '<w:b/>' : ''}'
        '${italic ? '<w:i/>' : ''}'
        '<w:color w:val="${hexRgb(s.color)}"/>'
        '<w:sz w:val="$half"/><w:szCs w:val="$half"/>'
        '${s.underline ? '<w:u w:val="single"/>' : ''}'
        '${rtl ? '<w:rtl/>' : ''}'
        '<w:lang w:val="$lang" w:bidi="$lang"/>'
        '</w:rPr>';

    final runs = text
        .split('\n')
        .map((line) => '<w:r>$rPr<w:t xml:space="preserve">${xmlEscape(line)}</w:t></w:r>')
        .join('<w:r>$rPr<w:br/></w:r>');
    return '<w:p>$pPr$runs</w:p>';
  }
}
