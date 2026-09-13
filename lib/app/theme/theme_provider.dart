import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for app-wide ThemeMode (Light / Dark).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  static const _kPrefTheme = 'app_theme_mode';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_kPrefTheme);
      if (isDark != null) {
        state = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefTheme, next == ThemeMode.dark);
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefTheme, mode == ThemeMode.dark);
    } catch (_) {}
  }
}
