import 'docx_exporter.dart';
import 'epub_exporter.dart';
import 'exporter_base.dart';
import 'html_exporter.dart';
import 'json_exporter.dart';
import 'pdf_exporter.dart';
import 'rtf_exporter.dart';
import 'text_exporter.dart';

export 'docx_exporter.dart';
export 'epub_exporter.dart';
export 'exporter_base.dart';
export 'html_exporter.dart';
export 'json_exporter.dart';
export 'pdf_exporter.dart';
export 'rtf_exporter.dart';
export 'text_exporter.dart';

/// Every format the app can export. KPF is not listed because it is
/// Amazon's proprietary format; see the KPF guide in the book menu.
final List<BookExporter> kExporters = [
  DocxExporter(),
  DocExporter(),
  PdfExporter(),
  JsonExporter(),
  RtfExporter(),
  EpubExporter(),
  HtmlExporter(),
  TxtExporter(),
  MarkdownExporter(),
];

BookExporter exporterById(String id) =>
    kExporters.firstWhere((e) => e.id == id);
