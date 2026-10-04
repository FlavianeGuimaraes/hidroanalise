// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0B1220);
  static const blue = Color(0xFF2F7BF6);
  static const cyan = Color(0xFF22D3EE);
  static const danger = Color(0xFFF87171);
  static const ok = Color(0xFF4ADE80);
  static const warn = Color(0xFFFBBF24);
  static const gradient = LinearGradient(
      colors: [cyan, blue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
}

/// Cores que mudam entre tema claro e escuro.
class Palette {
  const Palette(
      {required this.bg,
      required this.card,
      required this.text,
      required this.muted,
      required this.border});
  final Color bg, card, text, muted, border;
  static const dark = Palette(
      bg: Color(0xFF080D18),
      card: Color(0xFF101A2C),
      text: Color(0xFFE8EEF7),
      muted: Color(0xFF8A97AC),
      border: Color(0x1FFFFFFF));
  static const light = Palette(
      bg: Color(0xFFEEF1F5),
      card: Colors.white,
      text: Color(0xFF101828),
      muted: Color(0xFF5B6472),
      border: Color(0xFFDFE3E9));
  static Palette of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  static ThemeData build(Brightness b) {
    final p = b == Brightness.dark ? Palette.dark : Palette.light;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w));
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: p.bg,
      colorScheme:
          ColorScheme.fromSeed(seedColor: AppColors.blue, brightness: b),
      appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: p.card,
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.cyan, 1.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
