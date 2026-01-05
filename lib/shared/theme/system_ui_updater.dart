import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_manager.dart';

/// A widget that automatically updates system UI colors to match the current theme
/// This ensures the system navigation bar colors are consistent
class SystemUIUpdater extends ConsumerStatefulWidget {
  final Widget child;

  const SystemUIUpdater({super.key, required this.child});

  @override
  ConsumerState<SystemUIUpdater> createState() => _SystemUIUpdaterState();
}

class _SystemUIUpdaterState extends ConsumerState<SystemUIUpdater>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUI();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateUI();
  }

  @override
  void didChangePlatformBrightness() {
    _updateUI();
    super.didChangePlatformBrightness();
  }

  void _updateUI() {
    // Get platform brightness as fallback
    final isPlatformDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    // Get theme state, with null safety
    final themeState = ref.read(themeManagerNotifierProvider);

    // Default to platform brightness if theme state is not available yet
    bool isDarkMode = isPlatformDark;

    // Only use theme state if it's available and has a value
    if (themeState.hasValue && themeState.value != null) {
      isDarkMode = themeState.value!.isDarkMode;
    }

    // Force edge-to-edge mode for better control of system bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    // Set the system UI colors based on the current theme - using transparent for nav bar
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Make navigation bar transparent
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced:
            false, // Prevent Android from overriding colors
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light // White icons for dark theme
            : Brightness.dark, // Dark icons for light theme
        statusBarIconBrightness: isDarkMode
            ? Brightness.light // White status bar icons for dark theme
            : Brightness.dark, // Dark status bar icons for light theme
      ),
    );

    // Apply a second time after a short delay to override any system defaults
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
            statusBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for theme changes
    final themeState = ref.watch(themeManagerNotifierProvider);

    // Update the UI whenever the theme changes and has a value
    if (themeState.hasValue && themeState.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateUI();
      });
    }

    return widget.child;
  }
}
