import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../variables.dart';
import 'pdf_saver_stub.dart'
    if (dart.library.html) 'pdf_saver_web.dart'
    if (dart.library.io) 'pdf_saver_io.dart';

Future<void> savePdf(Uint8List bytes, String filename, BuildContext context) async {
  try {
    final savedPath = await savePdfBytes(
      bytes,
      filename,
      directoryPath: appPreferences.downloadDirectory,
    );
    if (!context.mounted) return;
    final message = savedPath != null
        ? 'Rapport enregistré dans :\n$savedPath'
        : 'Téléchargement du rapport démarré';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Impossible d\'enregistrer le rapport : $e'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}

Future<String?> resolveDefaultDownloadDirectory() {
  return getDefaultDownloadDirectory();
}
