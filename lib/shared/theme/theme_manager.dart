import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';
import 'modern_colors.dart';

enum ThemeOption {
  light,
  dark,
  system
}

class ThemeManager extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme';
  
  // Current selected theme
  ThemeOption _currentTheme = ThemeOption.system;
  
  // Current active theme based on system or user preference
  late ThemeData _activeTheme;
  
  // Getter for current theme option
  ThemeOption get currentTheme => _currentTheme;
  
  // Getter for active theme data
  ThemeData get activeTheme => _activeTheme;
  
  // Getter to check if dark mode is active
  bool get isDarkMode => _activeTheme.brightness == Brightness.dark;
  
  // Constructor initializes with system theme
  ThemeManager() {
    _loadSavedTheme();
  }
  
  // Initialize theme manager and load saved preference
  Future<void> initialize() async {
    await _loadSavedTheme();
  }
  
  // Load saved theme preference from shared preferences
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      
      if (savedTheme != null) {
        _currentTheme = ThemeOption.values.firstWhere(
          (element) => element.toString() == savedTheme,
          orElse: () => ThemeOption.system,
        );
      }
      
      _updateActiveTheme();
      notifyListeners();
    } catch (e) {
      // Default to system theme if there's an error
      _currentTheme = ThemeOption.system;
      _updateActiveTheme();
    }
  }
  
  // Update the active theme based on current theme selection
  void _updateActiveTheme() {
    switch (_currentTheme) {
      case ThemeOption.light:
        _activeTheme = modernLightTheme();
        break;
      case ThemeOption.dark:
        _activeTheme = modernDarkTheme();
        break;
      case ThemeOption.system:
        final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        _activeTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
        break;
    }
    
    // Update system navigation bar to match theme
    updateSystemNavigation();
  }
  
  // Update system UI to match theme
  void updateSystemNavigation() {
    final isDark = _activeTheme.brightness == Brightness.dark;
    
    // Set system navigation bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    // Apply a second time after a short delay to override any system defaults
    // This helps on some Android versions that might reset the navigation bar color
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      );
    });
  }
  
  // Change theme and save preference
  Future<void> setTheme(ThemeOption theme) async {
    if (_currentTheme == theme) return;
    
    _currentTheme = theme;
    _updateActiveTheme();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, theme.toString());
    } catch (e) {
      // Handle preference saving error
      debugPrint('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }
  
  // Toggle between light and dark themes
  Future<void> toggleTheme() async {
    ThemeOption newTheme;
    
    // If system theme is active, check the current brightness
    if (_currentTheme == ThemeOption.system) {
      final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      newTheme = isPlatformDark ? ThemeOption.light : ThemeOption.dark;
    } else if (_currentTheme == ThemeOption.light) {
      newTheme = ThemeOption.dark;
    } else {
      newTheme = ThemeOption.light;
    }
    
    await setTheme(newTheme);
  }
  
  // Listen to system theme changes
  void handleSystemThemeChange() {
    if (_currentTheme == ThemeOption.system) {
      _updateActiveTheme();
      notifyListeners();
    }
  }

  void setDarkMode() {}

  void setLightMode() {}
}