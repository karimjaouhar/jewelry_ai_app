import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
