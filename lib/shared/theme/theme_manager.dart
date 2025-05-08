import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';
import 'modern_colors.dart';

part 'theme_manager.g.dart';

enum ThemeOption {
  light,
  dark,
  system
}

class ThemeManagerState {
  final ThemeOption currentTheme;
  final ThemeData activeTheme;
  final bool isDarkMode;

  const ThemeManagerState({
    required this.currentTheme,
    required this.activeTheme,
    required this.isDarkMode,
  });

  ThemeManagerState copyWith({
    ThemeOption? currentTheme,
    ThemeData? activeTheme,
    bool? isDarkMode,
  }) {
    return ThemeManagerState(
      currentTheme: currentTheme ?? this.currentTheme,
      activeTheme: activeTheme ?? this.activeTheme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

@riverpod
class ThemeManager extends _$ThemeManager {
  static const String _themePreferenceKey = 'app_theme';
  
  @override
  ThemeManagerState build() {
    // Get initial platform brightness
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    // Start with system theme
    final initialTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
    
    // Load saved theme preference
    _loadSavedTheme();
    
    return ThemeManagerState(
      currentTheme: ThemeOption.system,
      activeTheme: initialTheme,
      isDarkMode: isPlatformDark,
    );
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
        final themeOption = ThemeOption.values.firstWhere(
          (element) => element.toString() == savedTheme,
          orElse: () => ThemeOption.system,
        );
        
        setTheme(themeOption);
      }
    } catch (e) {
      // Default to system theme if there's an error
      setTheme(ThemeOption.system);
    }
  }
  
  // Update the active theme based on current theme selection
  void _updateActiveTheme(ThemeOption option) {
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    ThemeData newTheme;
    bool isDark;
    
    switch (option) {
      case ThemeOption.light:
        newTheme = modernLightTheme();
        isDark = false;
        break;
      case ThemeOption.dark:
        newTheme = modernDarkTheme();
        isDark = true;
        break;
      case ThemeOption.system:
        newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
        isDark = isPlatformDark;
        break;
    }
    
    state = state.copyWith(
      currentTheme: option,
      activeTheme: newTheme,
      isDarkMode: isDark,
    );
    
    // Update system navigation bar to match theme
    updateSystemNavigation();
  }
  
  // Update system UI to match theme
  void updateSystemNavigation() {
    final isDark = state.isDarkMode;
    
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
    _updateActiveTheme(theme);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, theme.toString());
    } catch (e) {
      // Handle preference saving error
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  // Toggle between light and dark themes
  Future<void> toggleTheme() async {
    ThemeOption newTheme;
    
    // If system theme is active, check the current brightness
    if (state.currentTheme == ThemeOption.system) {
      final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      newTheme = isPlatformDark ? ThemeOption.light : ThemeOption.dark;
    } else if (state.currentTheme == ThemeOption.light) {
      newTheme = ThemeOption.dark;
    } else {
      newTheme = ThemeOption.light;
    }
    
    await setTheme(newTheme);
  }
  
  // Listen to system theme changes
  void handleSystemThemeChange() {
    if (state.currentTheme == ThemeOption.system) {
      _updateActiveTheme(ThemeOption.system);
    }
  }
}