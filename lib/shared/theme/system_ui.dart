import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class to handle system UI overlay styling
class AppSystemUI {
  /// Update the system UI overlay style based on theme brightness
  static void updateSystemUI(bool isDarkMode) {
    final uiStyle = SystemUiOverlayStyle(
      // Always transparent status bar
      statusBarColor: Colors.transparent,
      
      // Navigation bar settings
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false, // Prevent Android from overriding colors
      
      // Icons brightness based on theme
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    );
    
    // Apply UI style
    SystemChrome.setSystemUIOverlayStyle(uiStyle);
    
    // Apply a second time after a short delay to ensure it takes effect
    // This helps override any system defaults that might interfere
    Future.delayed(const Duration(milliseconds: 100), () {
      SystemChrome.setSystemUIOverlayStyle(uiStyle);
    });
  }
  
  /// Set edge-to-edge mode for full-screen immersive experience
  static void setEdgeToEdgeMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
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
    
    // Set edge-to-edge mode
    setEdgeToEdgeMode();
    
    // Initial UI update based on platform brightness
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    updateSystemUI(isPlatformDark);
  }
}