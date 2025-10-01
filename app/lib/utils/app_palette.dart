import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._(this._scheme);

  factory AppPalette.of(BuildContext context) {
    return AppPalette._(Theme.of(context).colorScheme);
  }

  final ColorScheme _scheme;

  bool get isLight => _scheme.brightness == Brightness.light;

  Color get background => isLight ? const Color(0xFFF6F7FB) : const Color(0xFF0B101A);
  Color get surface => isLight ? Colors.white : const Color(0xFF111827);
  Color get mutedSurface => isLight ? const Color(0xFFE8ECF5) : const Color(0xFF1F2937);
  Color get badgeSurface => isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color get primary => _scheme.primary;
  Color get secondary => const Color(0xFF7C3AED);
  Color get border => isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.06);
  Color get strongBorder => isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.2);
  Color get shadow => isLight ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.3);
  Color get textPrimary => isLight ? const Color(0xFF111827) : Colors.white;
  Color get textSecondary => isLight ? const Color(0xFF4B5563) : Colors.white.withOpacity(0.75);
  Color get textMuted => isLight ? const Color(0xFF6B7280) : Colors.white.withOpacity(0.6);
  Color get accentTextOnPrimary => Colors.white;
  Color get overlay => Colors.black.withOpacity(isLight ? 0.55 : 0.6);
  Color get dialogSurface => isLight ? Colors.white : const Color(0xF0111827);
  Color get success => const Color(0xFF16A34A);
  Color get warning => const Color(0xFFEAB308);
  Color get danger => const Color(0xFFDC2626);

  Color statusColor(int score) {
    if (score >= 60) return danger;
    if (score >= 30) return warning;
    return success;
  }
}
