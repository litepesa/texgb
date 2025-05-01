// lib/features/status/core/status_module.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/status_provider.dart';

/// Core module for Status feature implementation
class StatusModule {
  static bool _isInitialized = false;
  
  /// Initialize the Status module
  static void initialize() {
    if (_isInitialized) return;
    
    // Register dependencies, etc.
    _isInitialized = true;
  }
  
  /// Generate route for Status-related screens
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // Extract route name
    final routeName = settings.name;
    final args = settings.arguments;
    
    // Handle status-specific routes
    switch (routeName) {
      case Constants.statusDetailScreen:
        final String postId = args as String;
        return MaterialPageRoute(
          builder: (context) => StatusDetailScreen(postId: postId),
        );
      default:
        return null;
    }
  }
}