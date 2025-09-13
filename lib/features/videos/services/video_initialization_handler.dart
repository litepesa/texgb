// lib/features/videos/services/video_initialization_handler.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_controller_manager.dart';

/// Handles video initialization with retry logic and timeout
class VideoInitializationHandler {
  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);
  static const Duration initializationTimeout = Duration(seconds: 15);
  
  bool _isInitializing = false;
  int _currentAttempt = 0;
  Timer? _timeoutTimer;
  
  bool get isInitializing => _isInitializing;
  
  /// Initialize video with retry logic
  Future<InitializationResult> initializeVideo({
    required VideoControllerManager manager,
    required String videoUrl,
    VoidCallback? onProgress,
  }) async {
    if (_isInitializing) {
      return InitializationResult.alreadyInitializing();
    }
    
    if (videoUrl.isEmpty) {
      return InitializationResult.error('Empty video URL');
    }
    
    _isInitializing = true;
    _currentAttempt = 0;
    
    try {
      final result = await _attemptInitialization(manager, videoUrl, onProgress);
      return result;
    } finally {
      _isInitializing = false;
      _currentAttempt = 0;
      _timeoutTimer?.cancel();
      _timeoutTimer = null;
    }
  }
  
  /// Attempt initialization with retries
  Future<InitializationResult> _attemptInitialization(
    VideoControllerManager manager,
    String videoUrl,
    VoidCallback? onProgress,
  ) async {
    while (_currentAttempt < maxRetryAttempts) {
      _currentAttempt++;
      
      debugPrint('VideoInitializationHandler: Attempt $_currentAttempt of $maxRetryAttempts for $videoUrl');
      onProgress?.call();
      
      try {
        // Create controller with timeout
        final controller = await _createControllerWithTimeout(manager, videoUrl);
        if (controller == null) {
          throw Exception('Failed to create controller');
        }
        
        // Initialize with timeout
        final success = await _initializeWithTimeout(manager);
        if (success) {
          debugPrint('VideoInitializationHandler: Successfully initialized on attempt $_currentAttempt');
          return InitializationResult.success(controller);
        }
        
        throw Exception('Initialization failed');
        
      } catch (e) {
        debugPrint('VideoInitializationHandler: Attempt $_currentAttempt failed: $e');
        
        // If this isn't the last attempt, wait before retrying
        if (_currentAttempt < maxRetryAttempts) {
          final delay = _calculateRetryDelay(_currentAttempt);
          debugPrint('VideoInitializationHandler: Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }
    
    return InitializationResult.error('Failed to initialize after $maxRetryAttempts attempts');
  }
  
  /// Create controller with timeout
  Future<VideoPlayerController?> _createControllerWithTimeout(
    VideoControllerManager manager,
    String videoUrl,
  ) async {
    final completer = Completer<VideoPlayerController?>();
    
    _timeoutTimer = Timer(initializationTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    
    try {
      final controller = await manager.createController(videoUrl);
      
      if (!completer.isCompleted) {
        completer.complete(controller);
      }
      
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    }
  }
  
  /// Initialize controller with timeout
  Future<bool> _initializeWithTimeout(VideoControllerManager manager) async {
    final completer = Completer<bool>();
    
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(initializationTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    try {
      final success = await manager.initializeController();
      
      if (!completer.isCompleted) {
        completer.complete(success);
      }
      
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }
  
  /// Calculate exponential backoff delay
  Duration _calculateRetryDelay(int attemptNumber) {
    final multiplier = pow(2, attemptNumber - 1).toInt();
    final delayMs = baseRetryDelay.inMilliseconds * multiplier;
    
    // Add jitter (±25%) to avoid thundering herd
    final jitter = Random().nextDouble() * 0.5 - 0.25; // -0.25 to 0.25
    final jitteredDelayMs = (delayMs * (1 + jitter)).round();
    
    return Duration(milliseconds: jitteredDelayMs.clamp(
      baseRetryDelay.inMilliseconds,
      Duration(seconds: 10).inMilliseconds,
    ));
  }
  
  /// Check if URL is valid
  bool isValidVideoUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Cancel current initialization
  void cancelInitialization() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isInitializing = false;
  }
  
  /// Reset handler state
  void reset() {
    cancelInitialization();
    _currentAttempt = 0;
  }
  
  /// Dispose handler
  void dispose() {
    cancelInitialization();
  }
}

/// Result of initialization attempt
class InitializationResult {
  final bool isSuccess;
  final String? error;
  final VideoPlayerController? controller;
  final bool isAlreadyInitializing;
  
  const InitializationResult._({
    required this.isSuccess,
    this.error,
    this.controller,
    this.isAlreadyInitializing = false,
  });
  
  factory InitializationResult.success(VideoPlayerController controller) {
    return InitializationResult._(
      isSuccess: true,
      controller: controller,
    );
  }
  
  factory InitializationResult.error(String error) {
    return InitializationResult._(
      isSuccess: false,
      error: error,
    );
  }
  
  factory InitializationResult.alreadyInitializing() {
    return const InitializationResult._(
      isSuccess: false,
      error: 'Already initializing',
      isAlreadyInitializing: true,
    );
  }
}