// lib/features/videos/mixins/video_navigation_mixin.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mixin for handling video navigation states and transitions
mixin VideoNavigationMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver, RouteAware {
  
  // Navigation state tracking
  bool _isScreenActive = false;
  bool _isAppInForeground = true;
  bool _isNavigatingAway = false;
  bool _hasInitialized = false;
  
  // Getters for navigation state
  bool get isScreenActive => _isScreenActive;
  bool get isAppInForeground => _isAppInForeground;
  bool get isNavigatingAway => _isNavigatingAway;
  bool get hasInitialized => _hasInitialized;
  bool get canPlayVideos => _isScreenActive && _isAppInForeground && !_isNavigatingAway;
  
  // Navigation callbacks - override in implementing class
  void onScreenBecameActive();
  void onScreenBecameInactive();
  void onNavigatingAway();
  void onNavigatingBack();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasInitialized = true;
    
    // Check if screen is initially active
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkInitialRouteState();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  /// Check if this route is currently active
  void _checkInitialRouteState() {
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      _setScreenActive(true);
    }
  }
  
  /// Set screen active state and notify
  void _setScreenActive(bool isActive) {
    if (_isScreenActive == isActive) return;
    
    debugPrint('VideoNavigationMixin: Screen active changed to $isActive');
    _isScreenActive = isActive;
    
    if (isActive) {
      _isNavigatingAway = false;
      onScreenBecameActive();
    } else {
      onScreenBecameInactive();
    }
  }
  
  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final wasInForeground = _isAppInForeground;
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (!wasInForeground && _isScreenActive) {
          debugPrint('VideoNavigationMixin: App resumed, reactivating screen');
          onScreenBecameActive();
        }
        break;
        
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        if (wasInForeground && _isScreenActive) {
          debugPrint('VideoNavigationMixin: App backgrounded, deactivating screen');
          onScreenBecameInactive();
        }
        break;
        
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  /// Route observer callbacks
  @override
  void didPopNext() {
    // Returning to this screen from another screen
    super.didPopNext();
    debugPrint('VideoNavigationMixin: didPopNext - returning to screen');
    
    _isNavigatingAway = false;
    _setScreenActive(true);
    onNavigatingBack();
  }
  
  @override
  void didPushNext() {
    // Navigating away from this screen to another screen
    super.didPushNext();
    debugPrint('VideoNavigationMixin: didPushNext - navigating away');
    
    _isNavigatingAway = true;
    _setScreenActive(false);
    onNavigatingAway();
  }
  
  @override
  void didPush() {
    // This screen was just pushed onto the stack
    super.didPush();
    debugPrint('VideoNavigationMixin: didPush - screen pushed');
    _setScreenActive(true);
  }
  
  @override
  void didPop() {
    // This screen was just popped from the stack
    super.didPop();
    debugPrint('VideoNavigationMixin: didPop - screen popped');
    _setScreenActive(false);
  }
  
  /// Manual navigation state control
  void setNavigatingAway(bool navigating) {
    if (_isNavigatingAway == navigating) return;
    
    _isNavigatingAway = navigating;
    debugPrint('VideoNavigationMixin: Manual navigation state: $navigating');
    
    if (navigating) {
      onNavigatingAway();
    } else {
      onNavigatingBack();
    }
  }
  
  /// Force screen activation (useful for tab switches)
  void forceActivate() {
    debugPrint('VideoNavigationMixin: Force activating screen');
    _setScreenActive(true);
  }
  
  /// Force screen deactivation
  void forceDeactivate() {
    debugPrint('VideoNavigationMixin: Force deactivating screen');
    _setScreenActive(false);
  }
  
  /// Check if navigation conditions allow video playback
  bool shouldAllowVideoPlayback() {
    return _hasInitialized && 
           _isScreenActive && 
           _isAppInForeground && 
           !_isNavigatingAway;
  }
  
  /// Wait for screen to become ready for video operations
  Future<bool> waitForScreenReady({Duration timeout = const Duration(seconds: 5)}) async {
    if (shouldAllowVideoPlayback()) return true;
    
    final completer = Completer<bool>();
    late Timer timeoutTimer;
    
    void checkReady() {
      if (shouldAllowVideoPlayback()) {
        timeoutTimer.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    }
    
    // Check periodically
    final checkTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => checkReady());
    
    // Timeout fallback
    timeoutTimer = Timer(timeout, () {
      checkTimer.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    return await completer.future;
  }
  
  /// Get current navigation state as string (for debugging)
  String getNavigationStateString() {
    return 'NavigationState(active: $_isScreenActive, foreground: $_isAppInForeground, '
           'navigating: $_isNavigatingAway, initialized: $_hasInitialized)';
  }
}