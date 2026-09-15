import 'package:flutter/services.dart';

/// Utility wrappers for haptic feedback micro-interactions.
///
/// Centralises haptic calls so that future updates (e.g., switching from
/// built-in [HapticFeedback] to device-specific vibration patterns) only
/// require changes here.
abstract final class HapticUtils {
  /// Light tap — for checkbox toggles, chip selects.
  static void light() => HapticFeedback.selectionClick();

  /// Medium thud — for toggle switches, FAB presses.
  static void medium() => HapticFeedback.lightImpact();

  /// Strong pulse — for completion events, errors.
  static void heavy() => HapticFeedback.heavyImpact();

  /// Warning vibration pattern — error states.
  static void error() => HapticFeedback.mediumImpact();
}
