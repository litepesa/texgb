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
    themeManager.updateSystemNavigation();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}