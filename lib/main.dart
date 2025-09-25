import 'dart:io';

import 'package:chatbot_app/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

import 'variables.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  main.dart
---------------------------------- */

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    setWindowMinSize(const Size(512, 640));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  ThemeData _buildDarkTheme() {
    const baseScheme = ColorScheme.dark(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF7C3AED),
      surface: Color(0xFF111827),
      surfaceTint: Color(0xFF111827),
      background: Color(0xFF0B101A),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: baseScheme.background,
      dialogBackgroundColor: baseScheme.surface,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: Colors.cyan.withOpacity(0.35),
      ),
    );
  }


  ThemeData _buildLightTheme() {
    const baseScheme = ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF7C3AED),
      surface: Colors.white,
      surfaceTint: Colors.white,
      background: Color(0xFFF6F7FB),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: baseScheme.background,
      dialogBackgroundColor: baseScheme.surface,
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color(0x662563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appPreferences,
      builder: (context, _) {
        return MaterialApp(
          title: 'Chatbot App',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: appPreferences.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
