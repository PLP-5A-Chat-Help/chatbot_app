import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> savePdfBytes(Uint8List bytes, String filename) async {
  Directory? baseDir;
  try {
    baseDir = await getDownloadsDirectory();
  } catch (_) {
    baseDir = null;
  }
  baseDir ??= await getApplicationDocumentsDirectory();
  final file = File('${baseDir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
