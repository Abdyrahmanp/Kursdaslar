import 'package:flutter/material.dart';

/// Global color tokens for the "Fifteen" design system.
///
/// The primary seed is a warm terracotta-amber that generates a full
/// Material 3 tonal palette with approachable, friendly warmth —
/// avoiding cold corporate blues.
abstract final class AppColors {
  // ── M3 Seed ───────────────────────────────────────────────────────────────
  /// Primary warm terracotta seed. Fed into [ColorScheme.fromSeed].
  static const Color warmSeed = Color(0xFFE8734A);

  // ── Semantic Surfaces ─────────────────────────────────────────────────────
  static const Color warmSurface = Color(0xFFFFF8F4);
  static const Color warmSurfaceDark = Color(0xFF1E1612);

  // ── Offline / Online Status ───────────────────────────────────────────────
  /// Used for "GSM Offline" badge background.
  static const Color offlineAmber = Color(0xFFFFA726);

  /// Used for "Online" status indicator.
  static const Color onlineGreen = Color(0xFF4CAF50);

  // ── Avatar Palette (12 warm + cool tones, cycling per student index) ──────
  /// HSL-tuned palette that balances warmth and variety. Each entry is
  /// paired with a corresponding foreground text color in [avatarForegrounds].
  static const List<Color> avatarPalette = [
    Color(0xFFFF7043), // Deep Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFFB300), // Amber
    Color(0xFFFF5722), // Deep Orange 700
    Color(0xFF795548), // Brown
  ];

  static const List<Color> avatarForegrounds = [
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
    Colors.white,
  ];

  /// Returns the avatar background color for the given student [index].
  static Color avatarBg(int index) => avatarPalette[index % avatarPalette.length];

  /// Returns the avatar foreground (text/icon) color for the given [index].
  static Color avatarFg(int index) => avatarForegrounds[index % avatarForegrounds.length];
}
