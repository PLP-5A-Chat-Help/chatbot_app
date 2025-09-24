import 'package:flutter/material.dart';

/// Gestion centralisée des préférences d'interface.
class AppPreferences extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String? _downloadDirectory;

  ThemeMode get themeMode => _themeMode;
  String? get downloadDirectory => _downloadDirectory;
  bool get isLightMode => _themeMode == ThemeMode.light;

  void updateTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleLightMode(bool enableLightMode) {
    updateTheme(enableLightMode ? ThemeMode.light : ThemeMode.dark);
  }

  void setDownloadDirectory(String? path) {
    if (_downloadDirectory == path) return;
    _downloadDirectory = (path == null || path.isEmpty) ? null : path;
    notifyListeners();
  }
}
