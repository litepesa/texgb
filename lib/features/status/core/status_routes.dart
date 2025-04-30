import 'package:flutter/material.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/presentation/widgets/status_empty_state.dart';
import '../presentation/screens/status_feed_screen.dart';
import '../presentation/screens/create_status_screen.dart';
import '../presentation/screens/status_detail_screen.dart';
import '../presentation/widgets/status_settings_screen.dart';
import '../presentation/widgets/status_media_viewer.dart';

/// Routes for the Status feature
class StatusRoutes {
  /// Get all routes for Status feature
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      Constants.statusFeedScreen: (context) => const StatusFeedScreen(),
      Constants.createStatusScreen: (context) => const CreateStatusScreen(),
      Constants.statusSettingsScreen: (context) => const StatusSettingsScreen(),
    };
  }
  
  /// Route generator for Status feature
  /// Used for routes that need parameters
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // Extract route name and arguments
    final name = settings.name;
    final args = settings.arguments;
    
    switch (name) {
      case Constants.statusDetailScreen:
        final postId = args as String;
        return MaterialPageRoute(
          builder: (context) => StatusDetailScreen(postId: postId),
        );
        
      case Constants.statusMediaViewScreen:
        final arguments = args as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => StatusMediaViewer(
            mediaItems: arguments['mediaItems'],
            initialIndex: arguments['initialIndex'] ?? 0,
            autoPlayVideos: arguments['autoPlayVideos'] ?? false,
          ),
        );
        
      case Constants.editStatusScreen:
        final postId = args as String;
        // This would be implemented once you have an edit screen
        return MaterialPageRoute(
          builder: (context) => StatusDetailScreen(postId: postId), // Temporary redirect
        );
        
      default:
        return null;
    }
  }
}