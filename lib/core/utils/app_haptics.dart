import 'package:flutter/services.dart';

/// Centralized Haptic Feedback utility for SoundShare.
class AppHaptics {
  AppHaptics._();

  /// Light impact for standard button taps, scans, back navigations.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for primary actions like Share Audio, Stop Sharing, and double-back exit toast.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for critical state changes or disconnections.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Subtle click for bottom navigation tab selections and toggle switches.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate pattern for warnings or failures.
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }
}
