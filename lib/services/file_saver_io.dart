import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveBookFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save $fileName',
    fileName: fileName,
    bytes: mobile ? bytes : null,
  );
  if (path == null) return false;
  if (!mobile) await File(path).writeAsBytes(bytes, flush: true);
  return true;
}
