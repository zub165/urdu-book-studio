import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';

import '../models/book.dart';
import 'exporter_base.dart';
import 'html_exporter.dart';

/// Builds an EPUB 3 e-book (reflowable). Right-to-left books get
/// page-progression-direction="rtl". Export EPUB to Kindle Create or KDP to
/// make a Kindle (KPF) file. KPF itself is proprietary to Amazon.
class EpubExporter extends BookExporter {
  @override
  String get id => 'epub';
  @override
  String get label => 'E-book (EPUB 3)';
  @override
  String get extension => 'epub';
  @override
  String get mimeType => 'application/epub+zip';

  @override
  Future<Uint8List> export(Book book) async {
    final archive = Archive();
    // The mimetype entry must come first and be stored uncompressed.
    archive.addFile(zipTextEntry('mimetype', 'application/epub+zip')
      ..compress = false);
    archive.addFile(zipTextEntry('META-INF/container.xml', _container));
    archive.addFile(zipTextEntry('OEBPS/style.css', _css));
    archive.addFile(zipTextEntry('OEBPS/nav.xhtml', _nav(book)));
    for (var i = 0; i < book.chapters.length; i++) {
      archive.addFile(
          zipTextEntry('OEBPS/chapter_${i + 1}.xhtml', _chapter(book, i)));
    }
    archive.addFile(zipTextEntry('OEBPS/content.opf', _opf(book)));
    return zipToBytes(archive);
  }

  static const _container =
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
      '<rootfiles><rootfile full-path="OEBPS/content.opf" '
      'media-type="application/oebps-package+xml"/></rootfiles></container>';

  static const _css = 'body{font-family:serif;line-height:1.8;margin:5%;}\n'
      'h1{text-align:center;font-weight:bold;}\n'
      'h2,h3{font-weight:bold;}\n'
      'blockquote{margin:1em 2em;font-style:italic;}\n'
      '.center{text-align:center;}\n';

  String _opf(Book book) {
    final lang = book.languageCode;
    final uid = 'urn:uuid:${const Uuid().v4()}';
    final modified =
        '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
    final manifest = StringBuffer()
      ..write('<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>')
      ..write('<item id="css" href="style.css" media-type="text/css"/>');
    final spine = StringBuffer();
    for (var i = 0; i < book.chapters.length; i++) {
      manifest.write('<item id="c${i + 1}" href="chapter_${i + 1}.xhtml" '
          'media-type="application/xhtml+xml"/>');
      spine.write('<itemref idref="c${i + 1}"/>');
    }
    final direction = book.isRtl ? 'rtl' : 'ltr';
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" '
        'unique-identifier="bookid" xml:lang="$lang">\n'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">\n'
        '<dc:identifier id="bookid">$uid</dc:identifier>\n'
        '<dc:title>${xmlEscape(book.title)}</dc:title>\n'
        '<dc:language>$lang</dc:language>\n'
        '<dc:creator>${xmlEscape(book.author)}</dc:creator>\n'
        '<meta property="dcterms:modified">$modified</meta>\n'
        '</metadata>\n'
        '<manifest>$manifest</manifest>\n'
        '<spine page-progression-direction="$direction">$spine</spine>\n'
        '</package>';
  }

  String _nav(Book book) {
    final items = StringBuffer();
    for (var i = 0; i < book.chapters.length; i++) {
      items.write('<li><a href="chapter_${i + 1}.xhtml">'
          '${xmlEscape(book.chapters[i].title)}</a></li>');
    }
    final lang = book.languageCode;
    final dir = book.isRtl ? 'rtl' : 'ltr';
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<html xmlns="http://www.w3.org/1999/xhtml" '
        'xmlns:epub="http://www.idpf.org/2007/ops" lang="$lang" xml:lang="$lang" dir="$dir">\n'
        '<head><meta charset="utf-8"/><title>Contents</title>'
        '<link rel="stylesheet" type="text/css" href="style.css"/></head>\n'
        '<body><nav epub:type="toc" id="toc"><h1>Contents</h1>'
        '<ol>$items</ol></nav></body>\n</html>';
  }

  String _chapter(Book book, int index) {
    final chapter = book.chapters[index];
    final lang = book.languageCode;
    final dir = book.isRtl ? 'rtl' : 'ltr';
    final body = StringBuffer()
      ..write('<h1>${xmlEscape(chapter.title)}</h1>\n');
    for (final block in chapter.blocks) {
      body.writeln(blockToHtml(block, lang));
    }
    return '<?xml version="1.0" encoding="utf-8"?>\n'
        '<html xmlns="http://www.w3.org/1999/xhtml" lang="$lang" xml:lang="$lang" dir="$dir">\n'
        '<head><meta charset="utf-8"/><title>${xmlEscape(chapter.title)}</title>'
        '<link rel="stylesheet" type="text/css" href="style.css"/></head>\n'
        '<body dir="$dir">\n$body</body>\n</html>';
  }
}
