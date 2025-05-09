import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

enum ThemeOption {
  light,
  dark,
  system
}

// Define the state class for the theme manager
class ThemeState {
  final ThemeOption currentTheme;
  final ThemeData activeTheme;

  ThemeState({required this.currentTheme, required this.activeTheme});

  bool get isDarkMode => activeTheme.brightness == Brightness.dark;

  ThemeState copyWith({ThemeOption? currentTheme, ThemeData? activeTheme}) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      activeTheme: activeTheme ?? this.activeTheme,
    );
  }
}

// Create the AsyncNotifier to manage theme state
class ThemeManagerNotifier extends AsyncNotifier<ThemeState> {
  static const String _themePreferenceKey = 'app_theme';
  
  @override
  Future<ThemeState> build() async {
    // Create initial state with the system's current brightness
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final initialTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
    
    // Load saved theme preference
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeString = prefs.getString(_themePreferenceKey);
      
      // If no saved preference, use system default
      if (savedThemeString == null) {
        final initialState = ThemeState(
          currentTheme: ThemeOption.system,
          activeTheme: initialTheme,
        );
        
        // Update system UI
        _updateSystemNavigation(initialState.isDarkMode);
        
        return initialState;
      }
      
      // Use saved preference
      final savedTheme = _parseThemeOption(savedThemeString);
      
      // Determine the active theme based on the saved preference
      ThemeData activeTheme;
      switch (savedTheme) {
        case ThemeOption.light:
          activeTheme = modernLightTheme();
          break;
        case ThemeOption.dark:
          activeTheme = modernDarkTheme();
          break;
        case ThemeOption.system:
        default:
          activeTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
          break;
      }
      
      final themeState = ThemeState(
        currentTheme: savedTheme,
        activeTheme: activeTheme,
      );
      
      // Update system UI
      _updateSystemNavigation(themeState.isDarkMode);
      
      return themeState;
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      
      // Return default state on error
      final defaultState = ThemeState(
        currentTheme: ThemeOption.system,
        activeTheme: initialTheme,
      );
      
      // Update system UI
      _updateSystemNavigation(defaultState.isDarkMode);
      
      return defaultState;
    }
  }
  
  // Safely parse string to ThemeOption enum
  ThemeOption _parseThemeOption(String value) {
    try {
      return ThemeOption.values.firstWhere(
        (element) => element.toString() == value,
        orElse: () => ThemeOption.system,
      );
    } catch (e) {
      debugPrint('Error parsing theme option: $e');
      return ThemeOption.system;
    }
  }
  
  // Update system UI to match theme
  void _updateSystemNavigation(bool isDark) {
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
    // Don't do anything if state is loading or has error
    if (state.isLoading || state.hasError) return;
    
    // Get current state value with null safety
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    
    // Don't do anything if the theme is the same
    if (currentState.currentTheme == theme) return;
    
    // Update state based on the new theme option
    await update((currentState) async {
      ThemeData newTheme;
      
      switch (theme) {
        case ThemeOption.light:
          newTheme = modernLightTheme();
          break;
        case ThemeOption.dark:
          newTheme = modernDarkTheme();
          break;
        case ThemeOption.system:
          final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
          newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
          break;
      }
      
      // Save preference
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themePreferenceKey, theme.toString());
      } catch (e) {
        debugPrint('Error saving theme preference: $e');
        // Continue even if save fails
      }
      
      final newState = ThemeState(
        currentTheme: theme,
        activeTheme: newTheme,
      );
      
      // Update system UI
      _updateSystemNavigation(newState.isDarkMode);
      
      return newState;
    });
  }
  
  // Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (state.hasValue && state.valueOrNull != null) {
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
  }
  
  // Handle system theme changes
  Future<void> handleSystemThemeChange() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    
    if (currentState.currentTheme == ThemeOption.system) {
      await update((currentState) async {
        final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        final newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
        
        final updatedState = currentState.copyWith(activeTheme: newTheme);
        
        // Update system UI
        _updateSystemNavigation(updatedState.isDarkMode);
        
        return updatedState;
      });
    }
  }
}

// Create a provider for the ThemeManagerNotifier
final themeManagerNotifierProvider = AsyncNotifierProvider<ThemeManagerNotifier, ThemeState>(() {
  return ThemeManagerNotifier();
});