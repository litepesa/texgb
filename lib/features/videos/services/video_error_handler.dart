// lib/features/videos/services/video_error_handler.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_controller_manager.dart';
import 'video_initialization_handler.dart';

/// Handles video errors and recovery mechanisms
class VideoErrorHandler {
  static const Duration healthCheckInterval = Duration(seconds: 30);
  static const Duration stuckDetectionThreshold = Duration(seconds: 10);
  
  Timer? _healthCheckTimer;
  Duration _lastPosition = Duration.zero;
  DateTime _lastPositionUpdate = DateTime.now();
  bool _isRecovering = false;
  
  VideoErrorRecoveryCallback? _onRecoveryNeeded;
  
  bool get isRecovering => _isRecovering;
  
  /// Start monitoring video health
  void startHealthMonitoring({
    required VideoControllerManager manager,
    VideoErrorRecoveryCallback? onRecoveryNeeded,
  }) {
    _onRecoveryNeeded = onRecoveryNeeded;
    
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _checkVideoHealth(manager);
    });
  }
  
  /// Stop health monitoring
  void stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }
  
  /// Handle video player errors
  Future<ErrorRecoveryResult> handleVideoError({
    required VideoControllerManager manager,
    required VideoInitializationHandler initHandler,
    required String videoUrl,
    String? errorMessage,
  }) async {
    if (_isRecovering) {
      return ErrorRecoveryResult.alreadyRecovering();
    }
    
    _isRecovering = true;
    
    try {
      debugPrint('VideoErrorHandler: Handling error: $errorMessage');
      
      // Determine error type and recovery strategy
      final errorType = _classifyError(errorMessage);
      final strategy = _getRecoveryStrategy(errorType);
      
      debugPrint('VideoErrorHandler: Error type: $errorType, Strategy: $strategy');
      
      return await _executeRecoveryStrategy(
        strategy: strategy,
        manager: manager,
        initHandler: initHandler,
        videoUrl: videoUrl,
      );
      
    } finally {
      _isRecovering = false;
    }
  }
  
  /// Check if controller is healthy
  void _checkVideoHealth(VideoControllerManager manager) {
    if (!manager.isInitialized) return;
    
    try {
      // Check for controller health issues
      if (!manager.isControllerHealthy()) {
        debugPrint('VideoErrorHandler: Controller unhealthy detected');
        _triggerRecovery(VideoErrorType.controllerCorrupted);
        return;
      }
      
      // Check for playback stalling
      final currentPosition = manager.position;
      final now = DateTime.now();
      
      if (manager.isPlaying) {
        if (currentPosition == _lastPosition) {
          final stallDuration = now.difference(_lastPositionUpdate);
          if (stallDuration > stuckDetectionThreshold) {
            debugPrint('VideoErrorHandler: Playback stalled detected (${stallDuration.inSeconds}s)');
            _triggerRecovery(VideoErrorType.playbackStalled);
          }
        } else {
          _lastPosition = currentPosition;
          _lastPositionUpdate = now;
        }
      } else {
        _lastPositionUpdate = now;
      }
      
    } catch (e) {
      debugPrint('VideoErrorHandler: Health check error: $e');
      _triggerRecovery(VideoErrorType.unknown);
    }
  }
  
  /// Trigger recovery callback
  void _triggerRecovery(VideoErrorType errorType) {
    _onRecoveryNeeded?.call(errorType);
  }
  
  /// Classify error type from message
  VideoErrorType _classifyError(String? errorMessage) {
    if (errorMessage == null) return VideoErrorType.unknown;
    
    final message = errorMessage.toLowerCase();
    
    if (message.contains('network') || 
        message.contains('connection') || 
        message.contains('timeout')) {
      return VideoErrorType.network;
    }
    
    if (message.contains('format') || 
        message.contains('codec') || 
        message.contains('unsupported')) {
      return VideoErrorType.format;
    }
    
    if (message.contains('not found') || 
        message.contains('404') || 
        message.contains('invalid')) {
      return VideoErrorType.invalidUrl;
    }
    
    if (message.contains('permission') || 
        message.contains('access') || 
        message.contains('forbidden')) {
      return VideoErrorType.permission;
    }
    
    return VideoErrorType.unknown;
  }
  
  /// Get recovery strategy for error type
  RecoveryStrategy _getRecoveryStrategy(VideoErrorType errorType) {
    switch (errorType) {
      case VideoErrorType.network:
        return RecoveryStrategy.retryWithDelay;
      case VideoErrorType.controllerCorrupted:
      case VideoErrorType.playbackStalled:
        return RecoveryStrategy.recreateController;
      case VideoErrorType.format:
      case VideoErrorType.invalidUrl:
        return RecoveryStrategy.showError;
      case VideoErrorType.permission:
        return RecoveryStrategy.showError;
      case VideoErrorType.unknown:
        return RecoveryStrategy.retryOnce;
    }
  }
  
  /// Execute recovery strategy
  Future<ErrorRecoveryResult> _executeRecoveryStrategy({
    required RecoveryStrategy strategy,
    required VideoControllerManager manager,
    required VideoInitializationHandler initHandler,
    required String videoUrl,
  }) async {
    switch (strategy) {
      case RecoveryStrategy.retryWithDelay:
        await Future.delayed(const Duration(seconds: 2));
        return await _retryInitialization(manager, initHandler, videoUrl);
        
      case RecoveryStrategy.retryOnce:
        return await _retryInitialization(manager, initHandler, videoUrl);
        
      case RecoveryStrategy.recreateController:
        await manager.disposeController();
        await Future.delayed(const Duration(milliseconds: 500));
        return await _retryInitialization(manager, initHandler, videoUrl);
        
      case RecoveryStrategy.showError:
        return ErrorRecoveryResult.permanentFailure('Video cannot be played');
    }
  }
  
  /// Retry initialization
  Future<ErrorRecoveryResult> _retryInitialization(
    VideoControllerManager manager,
    VideoInitializationHandler initHandler,
    String videoUrl,
  ) async {
    final result = await initHandler.initializeVideo(
      manager: manager,
      videoUrl: videoUrl,
    );
    
    if (result.isSuccess) {
      return ErrorRecoveryResult.recovered();
    } else {
      return ErrorRecoveryResult.retryFailed(result.error ?? 'Retry failed');
    }
  }
  
  /// Reset error handler state
  void reset() {
    _lastPosition = Duration.zero;
    _lastPositionUpdate = DateTime.now();
    _isRecovering = false;
  }
  
  /// Dispose error handler
  void dispose() {
    stopHealthMonitoring();
    reset();
  }
}

/// Types of video errors
enum VideoErrorType {
  network,
  format,
  invalidUrl,
  permission,
  controllerCorrupted,
  playbackStalled,
  unknown,
}

/// Recovery strategies
enum RecoveryStrategy {
  retryWithDelay,
  retryOnce,
  recreateController,
  showError,
}

/// Error recovery result
class ErrorRecoveryResult {
  final bool isRecovered;
  final bool isPermanentFailure;
  final bool isAlreadyRecovering;
  final String? message;
  
  const ErrorRecoveryResult._({
    required this.isRecovered,
    required this.isPermanentFailure,
    required this.isAlreadyRecovering,
    this.message,
  });
  
  factory ErrorRecoveryResult.recovered() {
    return const ErrorRecoveryResult._(
      isRecovered: true,
      isPermanentFailure: false,
      isAlreadyRecovering: false,
    );
  }
  
  factory ErrorRecoveryResult.retryFailed(String message) {
    return ErrorRecoveryResult._(
      isRecovered: false,
      isPermanentFailure: false,
      isAlreadyRecovering: false,
      message: message,
    );
  }
  
  factory ErrorRecoveryResult.permanentFailure(String message) {
    return ErrorRecoveryResult._(
      isRecovered: false,
      isPermanentFailure: true,
      isAlreadyRecovering: false,
      message: message,
    );
  }
  
  factory ErrorRecoveryResult.alreadyRecovering() {
    return const ErrorRecoveryResult._(
      isRecovered: false,
      isPermanentFailure: false,
      isAlreadyRecovering: true,
      message: 'Already recovering',
    );
  }
}

/// Callback for recovery events
typedef VideoErrorRecoveryCallback = void Function(VideoErrorType errorType);