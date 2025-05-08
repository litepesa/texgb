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
class ThemeManagerNotifier extends _$ThemeManagerNotifier {
  static const String _themePreferenceKey = 'app_theme';
  
  @override
  FutureOr<ThemeManagerState> build() async {
    // Get initial platform brightness
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    // Start with system theme
    final initialTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
    
    // Load saved theme preference
    final savedTheme = await _loadSavedTheme();
    
    // If we have a saved theme, use that
    if (savedTheme != null) {
      return _getStateForThemeOption(savedTheme);
    }
    
    // Otherwise use system theme
    return ThemeManagerState(
      currentTheme: ThemeOption.system,
      activeTheme: initialTheme,
      isDarkMode: isPlatformDark,
    );
  }
  
  // Load saved theme preference from shared preferences
  Future<ThemeOption?> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      
      if (savedTheme != null) {
        final themeOption = ThemeOption.values.firstWhere(
          (element) => element.toString() == savedTheme,
          orElse: () => ThemeOption.system,
        );
        
        return themeOption;
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
    
    return null;
  }
  
  // Create the state for a given theme option
  ThemeManagerState _getStateForThemeOption(ThemeOption option) {
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
    
    return ThemeManagerState(
      currentTheme: option,
      activeTheme: newTheme,
      isDarkMode: isDark,
    );
  }
  
  // Update system UI to match theme
  void updateSystemNavigation(bool isDark) {
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
    // Update the state
    state = const AsyncLoading();
    state = AsyncData(_getStateForThemeOption(theme));
    
    // Update system navigation
    if (state.value != null) {
      updateSystemNavigation(state.value!.isDarkMode);
    }
    
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
    if (state.isLoading || !state.hasValue) return;
    
    final currentState = state.value!;
    ThemeOption newTheme;
    
    // If system theme is active, check the current brightness
    if (currentState.currentTheme == ThemeOption.system) {
      final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      newTheme = isPlatformDark ? ThemeOption.light : ThemeOption.dark;
    } else if (currentState.currentTheme == ThemeOption.light) {
      newTheme = ThemeOption.dark;
    } else {
      newTheme = ThemeOption.light;
    }
    
    await setTheme(newTheme);
  }
  
  // Handle system theme changes
  void handleSystemThemeChange() {
    if (state.hasValue && state.value!.currentTheme == ThemeOption.system) {
      final updatedState = _getStateForThemeOption(ThemeOption.system);
      state = AsyncData(updatedState);
      updateSystemNavigation(updatedState.isDarkMode);
    }
  }
}

// Extension getters for better readability
extension ThemeManagerStateExtension on AsyncValue<ThemeManagerState> {
  bool get isDarkMode => hasValue ? value!.isDarkMode : false;
  ThemeOption get currentTheme => hasValue ? value!.currentTheme : ThemeOption.system;
  ThemeData get activeTheme => hasValue 
      ? value!.activeTheme 
      : WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
          ? modernDarkTheme()
          : modernLightTheme();
}