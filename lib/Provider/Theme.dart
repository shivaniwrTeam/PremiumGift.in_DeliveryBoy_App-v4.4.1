import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode;
  ThemeNotifier(this._themeMode);
  getThemeMode() => _themeMode;
  setThemeMode(final ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
  }
}
