import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    // Application always opens in Light Mode by default on every launch
    _clearSavedDarkTheme();
    return ThemeMode.light;
  }

  Future<void> _clearSavedDarkTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, false);
    } catch (_) {}
  }

  void toggleTheme() {
    // Allows toggling during active session, but app will restart in light mode
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
