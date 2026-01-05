import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

enum ThemeOption { light, dark, system }

// Define the state class for the theme manager
class ThemeState {
  final ThemeOption currentTheme;
  final ThemeData activeTheme;
  final bool isTemporaryOverride; // For shop mode

  ThemeState({
    required this.currentTheme,
    required this.activeTheme,
    this.isTemporaryOverride = false,
  });

  bool get isDarkMode => activeTheme.brightness == Brightness.dark;

  ThemeState copyWith({
    ThemeOption? currentTheme,
    ThemeData? activeTheme,
    bool? isTemporaryOverride,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      activeTheme: activeTheme ?? this.activeTheme,
      isTemporaryOverride: isTemporaryOverride ?? this.isTemporaryOverride,
    );
  }
}

// Create the AsyncNotifier to manage theme state
class ThemeManagerNotifier extends AsyncNotifier<ThemeState> {
  static const String _themePreferenceKey = 'app_theme';

  // Store the user's actual theme preference (separate from temporary overrides)
  ThemeOption? _userThemePreference;

  @override
  Future<ThemeState> build() async {
    // Create initial state with the system's current brightness
    final isPlatformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final initialTheme =
        isPlatformDark ? modernDarkTheme() : modernLightTheme();

    // Load saved theme preference
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeString = prefs.getString(_themePreferenceKey);

      // If no saved preference, use system default
      if (savedThemeString == null) {
        _userThemePreference = ThemeOption.system;

        final initialState = ThemeState(
          currentTheme: ThemeOption.system,
          activeTheme: initialTheme,
          isTemporaryOverride: false,
        );

        // Update system UI
        _updateSystemNavigation(initialState.isDarkMode);

        return initialState;
      }

      // Use saved preference
      final savedTheme = _parseThemeOption(savedThemeString);
      _userThemePreference = savedTheme;

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
        isTemporaryOverride: false,
      );

      // Update system UI
      _updateSystemNavigation(themeState.isDarkMode);

      return themeState;
    } catch (e) {
      debugPrint('Error loading theme preference: $e');

      // Return default state on error
      _userThemePreference = ThemeOption.system;

      final defaultState = ThemeState(
        currentTheme: ThemeOption.system,
        activeTheme: initialTheme,
        isTemporaryOverride: false,
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
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
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
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      );
    });
  }

  // Set theme temporarily (for shop mode) without saving to preferences
  Future<void> setTemporaryTheme(ThemeOption theme) async {
    // Don't do anything if state is loading or has error
    if (state.isLoading || state.hasError) return;

    // Get current state value with null safety
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Update state with temporary override
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
          final isPlatformDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark;
          newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
          break;
      }

      final newState = ThemeState(
        currentTheme: theme,
        activeTheme: newTheme,
        isTemporaryOverride: true,
      );

      // Update system UI
      _updateSystemNavigation(newState.isDarkMode);

      debugPrint('Set temporary theme: $theme');

      return newState;
    });
  }

  // Restore user's original theme preference
  Future<void> restoreUserTheme() async {
    // Don't do anything if state is loading or has error
    if (state.isLoading || state.hasError) return;

    // Get current state value with null safety
    final currentState = state.valueOrNull;
    if (currentState == null || _userThemePreference == null) return;

    // Only restore if we're currently in a temporary override
    if (!currentState.isTemporaryOverride) return;

    debugPrint('Restoring user theme: $_userThemePreference');

    // Update state back to user's preference
    await update((currentState) async {
      ThemeData newTheme;

      switch (_userThemePreference!) {
        case ThemeOption.light:
          newTheme = modernLightTheme();
          break;
        case ThemeOption.dark:
          newTheme = modernDarkTheme();
          break;
        case ThemeOption.system:
          final isPlatformDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark;
          newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
          break;
      }

      final newState = ThemeState(
        currentTheme: _userThemePreference!,
        activeTheme: newTheme,
        isTemporaryOverride: false,
      );

      // Update system UI
      _updateSystemNavigation(newState.isDarkMode);

      return newState;
    });
  }

  // Change theme and save preference (for permanent changes)
  Future<void> setTheme(ThemeOption theme) async {
    // Don't do anything if state is loading or has error
    if (state.isLoading || state.hasError) return;

    // Get current state value with null safety
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Update user preference
    _userThemePreference = theme;

    // Don't do anything if the theme is the same and not a temporary override
    if (currentState.currentTheme == theme && !currentState.isTemporaryOverride)
      return;

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
          final isPlatformDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark;
          newTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
          break;
      }

      // Save preference
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themePreferenceKey, theme.toString());
        debugPrint('Saved theme preference: $theme');
      } catch (e) {
        debugPrint('Error saving theme preference: $e');
        // Continue even if save fails
      }

      final newState = ThemeState(
        currentTheme: theme,
        activeTheme: newTheme,
        isTemporaryOverride: false,
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

      // Use the actual user preference for toggle logic, not temporary overrides
      final baseTheme = _userThemePreference ?? currentState.currentTheme;

      // If system theme is active, check the current brightness
      if (baseTheme == ThemeOption.system) {
        final isPlatformDark =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        newTheme = isPlatformDark ? ThemeOption.light : ThemeOption.dark;
      } else if (baseTheme == ThemeOption.light) {
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

    // Only update if user preference is system and we're not in temporary override
    if (_userThemePreference == ThemeOption.system &&
        !currentState.isTemporaryOverride) {
      await update((currentState) async {
        final isPlatformDark =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        final newTheme =
            isPlatformDark ? modernDarkTheme() : modernLightTheme();

        final updatedState = currentState.copyWith(activeTheme: newTheme);

        // Update system UI
        _updateSystemNavigation(updatedState.isDarkMode);

        return updatedState;
      });
    }
  }

  // Get user's actual theme preference (ignoring temporary overrides)
  ThemeOption? get userThemePreference => _userThemePreference;
}

// Create a provider for the ThemeManagerNotifier
final themeManagerNotifierProvider =
    AsyncNotifierProvider<ThemeManagerNotifier, ThemeState>(() {
  return ThemeManagerNotifier();
});
