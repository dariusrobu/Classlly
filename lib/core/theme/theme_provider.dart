import 'package:flutter/material.dart';
import 'package:classlly/core/theme/app_theme.dart';
import 'package:classlly/data/repositories/notes_repository.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppTheme.primaryPurple;

  ThemeProvider() {
    loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  void loadPreferences() {
    try {
      final repository = NotesRepository();
      final prefs = repository.getPreferences();

      _themeMode = _parseThemeMode(prefs.themeMode);
      _accentColor = Color(prefs.accentColor);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _savePreferences();
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void _savePreferences() {
    try {
      final repository = NotesRepository();
      final prefs = repository.getPreferences();
      prefs.themeMode = _themeModeToString(_themeMode);
      prefs.accentColor = _accentColor.toARGB32();
      repository.savePreferences(prefs);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }
}
