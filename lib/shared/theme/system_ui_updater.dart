import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:textgb/shared/theme/theme_manager.dart';

/// A widget that automatically updates system UI colors to match the current theme
/// This ensures the system navigation bar colors are consistent
class SystemUIUpdater extends StatefulWidget {
  final Widget child;
  
  const SystemUIUpdater({super.key, required this.child});
  
  @override
  State<SystemUIUpdater> createState() => _SystemUIUpdaterState();
}

class _SystemUIUpdaterState extends State<SystemUIUpdater> with WidgetsBindingObserver {
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
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDarkMode = themeManager.isDarkMode;
    
    // Set the system UI colors based on the current theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Use the appropriate color based on the theme
        systemNavigationBarColor: isDarkMode 
            ? const Color(0xFF262624)  // New dark theme for navigation bar
            : Colors.white,            // Light theme navigation bar
        systemNavigationBarIconBrightness: isDarkMode 
            ? Brightness.light         // White icons for dark theme
            : Brightness.dark,         // Dark icons for light theme
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode 
            ? Brightness.light         // White status bar icons for dark theme
            : Brightness.dark,         // Dark status bar icons for light theme
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Listen for theme changes
    final themeManager = Provider.of<ThemeManager>(context);
    
    // Update the UI whenever the theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUI();
    });
    
    return widget.child;
  }
}