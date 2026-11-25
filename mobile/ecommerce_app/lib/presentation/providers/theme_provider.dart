import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  final SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider([this._prefs]) {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadFromPrefs() {
    final prefs = _prefs;
    if (prefs == null) return;
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = _prefs;
    if (prefs != null) {
      if (mode == ThemeMode.light) {
        await prefs.setString(_prefKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_prefKey, 'dark');
      } else {
        await prefs.setString(_prefKey, 'system');
      }
    }
  }
}
