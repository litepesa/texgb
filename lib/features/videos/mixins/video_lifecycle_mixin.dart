// lib/features/videos/mixins/video_lifecycle_mixin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/video_controller_manager.dart';
import '../services/video_initialization_handler.dart';
import '../services/video_error_handler.dart';

/// Mixin for managing video widget lifecycle and cleanup
mixin VideoLifecycleMixin<T extends StatefulWidget> on State<T> {
  
  // Services
  late VideoControllerManager _controllerManager;
  late VideoInitializationHandler _initHandler;
  late VideoErrorHandler _errorHandler;
  
  // Lifecycle state
  bool _isDisposed = false;
  bool _isInitialized = false;
  Timer? _cleanupTimer;
  
  // Getters for lifecycle state  
  bool get isDisposed => _isDisposed;
  bool get isVideoInitialized => _isInitialized && !_isDisposed;
  VideoControllerManager get controllerManager => _controllerManager;
  VideoInitializationHandler get initHandler => _initHandler;
  VideoErrorHandler get errorHandler => _errorHandler;
  
  // Override these in implementing class
  void onVideoInitialized();
  void onVideoDisposed();
  void onVideoError(String error);
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  @override
  void dispose() {
    _disposeVideoResources();
    super.dispose();
  }
  
  /// Initialize video services
  void _initializeServices() {
    _controllerManager = VideoControllerManager();
    _initHandler = VideoInitializationHandler();
    _errorHandler = VideoErrorHandler();
    
    debugPrint('VideoLifecycleMixin: Services initialized');
  }
  
  /// Initialize video with proper lifecycle management
  Future<bool> initializeVideo(String videoUrl) async {
    if (_isDisposed || videoUrl.isEmpty) return false;
    
    debugPrint('VideoLifecycleMixin: Initializing video: $videoUrl');
    
    try {
      final result = await _initHandler.initializeVideo(
        manager: _controllerManager,
        videoUrl: videoUrl,
        onProgress: () {
          if (!_isDisposed && mounted) {
            setState(() {});
          }
        },
      );
      
      if (result.isSuccess && !_isDisposed) {
        _isInitialized = true;
        
        // Start error monitoring
        _errorHandler.startHealthMonitoring(
          manager: _controllerManager,
          onRecoveryNeeded: _handleRecoveryNeeded,
        );
        
        // Schedule periodic cleanup
        _schedulePeriodicCleanup();
        
        if (mounted) {
          onVideoInitialized();
        }
        
        return true;
      } else {
        if (mounted) {
          onVideoError(result.error ?? 'Unknown initialization error');
        }
        return false;
      }
    } catch (e) {
      debugPrint('VideoLifecycleMixin: Initialize error: $e');
      if (mounted) {
        onVideoError(e.toString());
      }
      return false;
    }
  }
  
  /// Handle error recovery
  void _handleRecoveryNeeded(VideoErrorType errorType) {
    if (_isDisposed || !mounted) return;
    
    debugPrint('VideoLifecycleMixin: Recovery needed for error type: $errorType');
    
    // Trigger recovery in next frame to avoid state conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _attemptRecovery(errorType);
      }
    });
  }
  
  /// Attempt to recover from error
  Future<void> _attemptRecovery(VideoErrorType errorType) async {
    // Get current video URL if available
    final videoUrl = _getCurrentVideoUrl();
    if (videoUrl == null || videoUrl.isEmpty) return;
    
    try {
      final result = await _errorHandler.handleVideoError(
        manager: _controllerManager,
        initHandler: _initHandler,
        videoUrl: videoUrl,
        errorMessage: errorType.toString(),
      );
      
      if (result.isRecovered) {
        debugPrint('VideoLifecycleMixin: Successfully recovered from error');
        if (mounted) {
          setState(() {});
        }
      } else if (result.isPermanentFailure) {
        debugPrint('VideoLifecycleMixin: Permanent failure: ${result.message}');
        if (mounted) {
          onVideoError(result.message ?? 'Permanent video failure');
        }
      } else {
        debugPrint('VideoLifecycleMixin: Recovery failed: ${result.message}');
      }
    } catch (e) {
      debugPrint('VideoLifecycleMixin: Recovery attempt failed: $e');
      if (mounted) {
        onVideoError('Recovery failed: $e');
      }
    }
  }
  
  /// Get current video URL (override in implementing class)
  String? _getCurrentVideoUrl() {
    // This should be overridden by implementing class
    // to return the current video URL
    return null;
  }
  
  /// Play video with lifecycle checks
  Future<bool> playVideo() async {
    if (!isVideoInitialized) return false;
    
    return await _controllerManager.play();
  }
  
  /// Pause video with lifecycle checks  
  Future<bool> pauseVideo() async {
    if (!isVideoInitialized) return false;
    
    return await _controllerManager.pause();
  }
  
  /// Seek video with lifecycle checks
  Future<bool> seekVideo(Duration position) async {
    if (!isVideoInitialized) return false;
    
    return await _controllerManager.seekTo(position);
  }
  
  /// Reset video to beginning
  Future<bool> resetVideo() async {
    if (!isVideoInitialized) return false;
    
    return await _controllerManager.reset();
  }
  
  /// Check if video is healthy and playing correctly
  bool isVideoHealthy() {
    if (!isVideoInitialized) return false;
    
    return _controllerManager.isControllerHealthy();
  }
  
  /// Get video controller safely
  VideoPlayerController? getVideoController() {
    if (!isVideoInitialized) return null;
    
    return _controllerManager.controller;
  }
  
  /// Schedule periodic cleanup to prevent memory leaks
  void _schedulePeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performPeriodicCleanup();
    });
  }
  
  /// Perform periodic cleanup
  void _performPeriodicCleanup() {
    if (_isDisposed) return;
    
    // Check if controller is still healthy
    if (!_controllerManager.isControllerHealthy()) {
      debugPrint('VideoLifecycleMixin: Controller unhealthy detected during cleanup');
      
      // Attempt to recover if we have a video URL
      final videoUrl = _getCurrentVideoUrl();
      if (videoUrl != null && videoUrl.isNotEmpty) {
        _handleRecoveryNeeded(VideoErrorType.controllerCorrupted);
      }
    }
  }
  
  /// Dispose video resources with proper cleanup
  Future<void> _disposeVideoResources() async {
    if (_isDisposed) return;
    
    debugPrint('VideoLifecycleMixin: Disposing video resources');
    _isDisposed = true;
    
    // Cancel timers
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    // Stop health monitoring
    _errorHandler.stopHealthMonitoring();
    
    // Cancel any ongoing initialization
    _initHandler.cancelInitialization();
    
    // Dispose controller
    await _controllerManager.disposeController();
    
    // Dispose services
    _errorHandler.dispose();
    _initHandler.dispose();
    
    _isInitialized = false;
    
    onVideoDisposed();
    
    debugPrint('VideoLifecycleMixin: Video resources disposed');
  }
  
  /// Force cleanup and recreation (useful for error recovery)
  Future<bool> forceRecreateVideo(String videoUrl) async {
    if (_isDisposed) return false;
    
    debugPrint('VideoLifecycleMixin: Force recreating video');
    
    // Stop current resources
    _errorHandler.stopHealthMonitoring();
    await _controllerManager.disposeController();
    _isInitialized = false;
    
    // Small delay to ensure cleanup
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (_isDisposed || !mounted) return false;
    
    // Reinitialize
    return await initializeVideo(videoUrl);
  }
  
  /// Get video state information for debugging
  Map<String, dynamic> getVideoState() {
    return {
      'isDisposed': _isDisposed,
      'isInitialized': _isInitialized,
      'isControllerHealthy': isVideoInitialized ? _controllerManager.isControllerHealthy() : false,
      'isPlaying': isVideoInitialized ? _controllerManager.isPlaying : false,
      'position': isVideoInitialized ? _controllerManager.position.inSeconds : 0,
      'duration': isVideoInitialized ? _controllerManager.duration.inSeconds : 0,
      'hasController': _controllerManager.hasController,
    };
  }
}