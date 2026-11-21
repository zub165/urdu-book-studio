import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/book.dart';

abstract class BookExporter {
  String get id;
  String get label;
  String get extension;
  String get mimeType;

  Future<Uint8List> export(Book book);
}

/// A UTF-8 text entry for a zip archive.
ArchiveFile zipTextEntry(String name, String content) {
  final data = utf8.encode(content);
  return ArchiveFile(name, data.length, data);
}

Uint8List zipToBytes(Archive archive) =>
    Uint8List.fromList(ZipEncoder().encode(archive) ?? const <int>[]);

/// Escapes text for XML and HTML content and attributes.
String xmlEscape(String input) => input
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// "RRGGBB" from an ARGB int.
String hexRgb(int argb) =>
    (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
