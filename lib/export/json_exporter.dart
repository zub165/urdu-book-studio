import 'dart:convert';
import 'dart:typed_data';

import '../models/book.dart';
import 'exporter_base.dart';

/// Full-fidelity book file. Importing it back restores every chapter, block
/// and style, so it is the recommended format for editing a book elsewhere.
class JsonExporter extends BookExporter {
  @override
  String get id => 'json';
  @override
  String get label => 'Book file (JSON, editable)';
  @override
  String get extension => 'json';
  @override
  String get mimeType => 'application/json';

  @override
  Future<Uint8List> export(Book book) async => Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(book.toJson())),
      );
}
