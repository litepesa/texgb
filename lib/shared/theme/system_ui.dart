import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class to handle system UI overlay styling
class AppSystemUI {
  /// Update the system UI overlay style based on theme brightness
  static void updateSystemUI(bool isDarkMode) {
    // Set the SYSTEM UI overlay style to transparent with proper contrast
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      // Status bar (top)
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      
      // Navigation bar (bottom)
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ));
    
    // Ensure we're in edge-to-edge mode
    _setEdgeToEdgeMode();
  }
  
  /// Set edge-to-edge mode for full-screen immersive experience
  static void _setEdgeToEdgeMode() {
    // Set system UI mode to edge-to-edge (content extends behind system UI)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
  
  /// Set preferred orientations for the app
  static Future<void> setPreferredOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  /// Apply initial system setup when app launches
  static Future<void> setupSystemUI() async {
    // Set preferred orientations
    await setPreferredOrientations();
    
    // Get the current platform brightness
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    // Initial UI update based on platform brightness 
    updateSystemUI(isPlatformDark);
    
    // Apply a second time after a delay to override any system defaults
    Future.delayed(const Duration(milliseconds: 300), () {
      updateSystemUI(isPlatformDark);
    });
  }
}