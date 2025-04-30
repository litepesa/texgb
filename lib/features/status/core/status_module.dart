import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/presentation/widgets/status_empty_state.dart';
import 'package:uuid/uuid.dart';

import '../application/providers/status_providers.dart';
import '../data/data_sources/media_upload_service.dart';
import '../data/repositories/firebase_status_repository.dart';
import '../presentation/screens/create_status_screen.dart';
import '../presentation/screens/status_detail_screen.dart';
import '../presentation/screens/status_feed_screen.dart';
import '../presentation/widgets/status_media_viewer.dart';
import '../presentation/widgets/status_settings_screen.dart';

/// Module for Status feature initialization and routing
class StatusModule {
  static final List<Override> _overrides = [];

  /// Initialize the Status module
  static void initialize() {
    // Set up dependency overrides for testing or custom configurations
    _overrides.addAll([
      firebaseFirestoreProvider.overrideWithValue(FirebaseFirestore.instance),
      firebaseStorageProvider.overrideWithValue(FirebaseStorage.instance),
      uuidProvider.overrideWithValue(const Uuid()),
      
      // Initialize MediaUploadService
      mediaUploadServiceProvider.overrideWithValue(
        MediaUploadService(
          storage: FirebaseStorage.instance,
          uuid: const Uuid(),
        ),
      ),
      
      // Initialize repository
      statusRepositoryProvider.overrideWithValue(
        FirebaseStatusRepository(
          firestore: FirebaseFirestore.instance,
          storage: FirebaseStorage.instance,
          uuid: const Uuid(),
          mediaUploadService: MediaUploadService(
            storage: FirebaseStorage.instance,
            uuid: const Uuid(),
          ),
        ),
      ),
    ]);
    
    // You could also perform other initialization tasks here,
    // such as registering analytics events, setting up listeners, etc.
  }
  
  /// Get all overrides for Status feature
  /// Used for testing or custom configurations
  static List<Override> getOverrides() {
    return _overrides;
  }
  
  /// Get all routes for Status feature
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      Constants.statusFeedScreen: (context) => const StatusFeedScreen(),
      Constants.createStatusScreen: (context) => const CreateStatusScreen(),
      Constants.statusSettingsScreen: (context) => const StatusSettingsScreen(),
      // Constants.editStatusScreen is handled in generateRoute since it needs parameters
    };
  }
  
  /// Route generator for Status feature
  /// Used for routes that need parameters
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    // Extract route name and arguments
    final name = settings.name;
    final args = settings.arguments;
    
    // Handle status detail screen
    if (name == Constants.statusDetailScreen) {
      final postId = args as String;
      return MaterialPageRoute(
        builder: (context) => StatusDetailScreen(postId: postId),
      );
    }
    
    // Handle media viewer screen
    if (name == Constants.statusMediaViewScreen) {
      final arguments = args as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => StatusMediaViewer(
          mediaItems: arguments['mediaItems'],
          initialIndex: arguments['initialIndex'] ?? 0,
          autoPlayVideos: arguments['autoPlayVideos'] ?? false,
        ),
      );
    }
    
    // Handle edit status screen (if implemented)
    if (name == Constants.editStatusScreen) {
      final postId = args as String;
      // This would be implemented once you have an edit screen
      return MaterialPageRoute(
        builder: (context) => StatusDetailScreen(postId: postId), // Temporary redirect
      );
    }
    
    // If no matching route found, return null to let the app handle it
    return null;
  }
  
  /// Register listeners for the Status feature
  /// For example, background notification handlers, etc.
  static void registerListeners() {
    // Example: Register for push notifications about status updates
    // final messaging = FirebaseMessaging.instance;
    // messaging.onMessage.listen(_handleStatusNotification);
  }
  
  /// Clean up resources used by the Status feature
  static void dispose() {
    // Clean up any resources that need to be disposed
    // For example, cancel streams, close controllers, etc.
  }
}