import 'package:flutter/services.dart';

abstract final class AppPalette {
  // 60% — Neutral
  static const background = Color(0xFFF7FAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFEEF6F0);

  // 30% — Primary Green
  static const primary = Color(0xFF176B45);
  static const primaryDark = Color(0xFF125536);
  static const primarySoft = Color(0xFFDDEFE5);

  // 10% — Deep Accent
  static const accent = Color(0xFF0B3D2E);
  static const accentSoft = Color(0xFFD5E8E0);

  // Text
  static const textPrimary = Color(0xFF17211C);
  static const textSecondary = Color(0xFF637069);
  static const textMuted = Color(0xFF8A958E);

  // Supporting semantic colors
  static const success = Color(0xFF238B57);
  static const warning = Color(0xFFC88719);
  static const danger = Color(0xFFC94A4A);

  // Borders
  static const border = Color(0xFFDCE7DF);
}
