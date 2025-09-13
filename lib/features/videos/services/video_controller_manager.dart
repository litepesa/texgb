// lib/features/videos/services/video_controller_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Manages VideoPlayerController lifecycle and state
class VideoControllerManager {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _currentVideoUrl;
  
  // State tracking
  bool get isInitialized => _isInitialized && !_isDisposed;
  bool get isDisposed => _isDisposed;
  bool get hasController => _controller != null && !_isDisposed;
  VideoPlayerController? get controller => _isDisposed ? null : _controller;
  
  /// Create and initialize a new controller
  Future<VideoPlayerController?> createController(String videoUrl) async {
    if (_currentVideoUrl == videoUrl && isInitialized) {
      return _controller;
    }
    
    // Dispose existing controller
    await disposeController();
    
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );
      
      _currentVideoUrl = videoUrl;
      _isDisposed = false;
      
      return _controller;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to create controller: $e');
      return null;
    }
  }
  
  /// Initialize the current controller
  Future<bool> initializeController() async {
    if (_isDisposed || _controller == null) return false;
    
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to initialize: $e');
      _isInitialized = false;
      return false;
    }
  }
  
  /// Play the video
  Future<bool> play() async {
    if (!isInitialized) return false;
    
    try {
      await _controller!.play();
      return true;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to play: $e');
      return false;
    }
  }
  
  /// Pause the video
  Future<bool> pause() async {
    if (!isInitialized) return false;
    
    try {
      await _controller!.pause();
      return true;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to pause: $e');
      return false;
    }
  }
  
  /// Seek to position
  Future<bool> seekTo(Duration position) async {
    if (!isInitialized) return false;
    
    try {
      await _controller!.seekTo(position);
      return true;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to seek: $e');
      return false;
    }
  }
  
  /// Check if controller is healthy (initialized and not stuck)
  bool isControllerHealthy() {
    if (!isInitialized) return false;
    
    try {
      // Basic health checks
      final value = _controller!.value;
      return value.isInitialized && 
             !value.hasError && 
             value.size.width > 0 && 
             value.size.height > 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Get current playback position
  Duration get position {
    if (!isInitialized) return Duration.zero;
    try {
      return _controller!.value.position;
    } catch (e) {
      return Duration.zero;
    }
  }
  
  /// Get video duration
  Duration get duration {
    if (!isInitialized) return Duration.zero;
    try {
      return _controller!.value.duration;
    } catch (e) {
      return Duration.zero;
    }
  }
  
  /// Check if video is currently playing
  bool get isPlaying {
    if (!isInitialized) return false;
    try {
      return _controller!.value.isPlaying;
    } catch (e) {
      return false;
    }
  }
  
  /// Reset controller to beginning
  Future<bool> reset() async {
    if (!isInitialized) return false;
    
    try {
      await _controller!.seekTo(Duration.zero);
      await _controller!.pause();
      return true;
    } catch (e) {
      debugPrint('VideoControllerManager: Failed to reset: $e');
      return false;
    }
  }
  
  /// Dispose the current controller
  Future<void> disposeController() async {
    if (_controller != null && !_isDisposed) {
      try {
        await _controller!.dispose();
      } catch (e) {
        debugPrint('VideoControllerManager: Error disposing controller: $e');
      }
    }
    
    _controller = null;
    _isInitialized = false;
    _isDisposed = true;
    _currentVideoUrl = null;
  }
  
  /// Add listener to controller
  void addListener(VoidCallback listener) {
    if (isInitialized) {
      _controller!.addListener(listener);
    }
  }
  
  /// Remove listener from controller
  void removeListener(VoidCallback listener) {
    if (hasController) {
      try {
        _controller!.removeListener(listener);
      } catch (e) {
        debugPrint('VideoControllerManager: Error removing listener: $e');
      }
    }
  }
}