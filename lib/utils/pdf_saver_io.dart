import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> savePdfBytes(Uint8List bytes, String filename, {String? directoryPath}) async {
  Directory baseDir;
  if (directoryPath != null && directoryPath.isNotEmpty) {
    baseDir = Directory(directoryPath);
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
  } else {
    Directory? preferred;
    try {
      preferred = await getDownloadsDirectory();
    } catch (_) {
      preferred = null;
    }
    preferred ??= await getApplicationDocumentsDirectory();
    baseDir = preferred;
  }
  final file = File(p.join(baseDir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String?> getDefaultDownloadDirectory() async {
  Directory? preferred;
  try {
    preferred = await getDownloadsDirectory();
  } catch (_) {
    preferred = null;
  }
  preferred ??= await getApplicationDocumentsDirectory();
  return preferred.path;
}
