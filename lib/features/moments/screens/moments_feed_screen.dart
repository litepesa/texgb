// lib/features/moments/screens/moments_feed_screen.dart - With lifecycle methods like ChannelsFeedScreen
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_comments_bottom_sheet.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MomentsFeedScreen extends ConsumerStatefulWidget {
  final String? startMomentId;

  const MomentsFeedScreen({
    super.key,
    this.startMomentId,
  });

  // Static method to create from route arguments
  static MomentsFeedScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? startMomentId;
    
    if (args is Map<String, dynamic>) {
      startMomentId = args['startMomentId'] as String?;
    }
    
    return MomentsFeedScreen(
      startMomentId: startMomentId,
    );
  }

  @override
  ConsumerState<MomentsFeedScreen> createState() => MomentsFeedScreenState();
}

class MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  
  // State management
  int _currentIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasNavigatedToStart = false;
  bool _isCommentsSheetOpen = false;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false; // Track navigation state
  bool _isManuallyPaused = false; // Track if user manually paused the video
  
  // Video controllers
  Map<int, VideoPlayerController> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  
  // Caption expansion state
  final Map<int, bool> _captionExpanded = {};
  
  // Animation controllers for like effect
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  late AnimationController _burstAnimationController;
  late Animation<double> _burstAnimation;
  bool _showLikeAnimation = false;
  
  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimationControllers();
    _setupSystemUI();
    _hasInitialized = true;
    
    // Enable wakelock for video playback
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store original system UI after dependencies are available
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
    // Store the current system UI style before making changes
    final brightness = Theme.of(context).brightness;
    _originalSystemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  void _setupSystemUI() {
    // Set both status bar and navigation bar to black for immersive TikTok-style experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _restoreOriginalSystemUI() {
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      // Fallback: restore based on current theme
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }
  }

  void _initializeAnimationControllers() {
    // Like animation controllers
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _heartScaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _heartScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartScaleController,
      curve: Curves.elasticOut,
    ));
    
    _burstAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _burstAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _burstAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive && !_isCommentsSheetOpen && !_isNavigatingAway) {
          _startFreshPlayback();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _pauseAllVideos();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // Lifecycle methods matching ChannelsFeedScreen
  void onScreenBecameActive() {
    if (!_hasInitialized) return;
    
    debugPrint('MomentsFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false; // Reset navigation state
    
    // Setup system UI when becoming active
    _setupSystemUI();
    
    if (_isAppInForeground && !_isManuallyPaused) {
      _startFreshPlayback();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('MomentsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _pauseAllVideos();
    
    // Restore original system UI when becoming inactive
    _restoreOriginalSystemUI();
    
    WakelockPlus.disable();
  }

  // New method to handle navigation away from feed
  void _pauseForNavigation() {
    debugPrint('MomentsFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _pauseAllVideos();
  }

  // New method to handle returning from navigation
  void _resumeFromNavigation() {
    debugPrint('MomentsFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused) {
      // Add a small delay to ensure the screen is fully visible before starting playback
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused) return;
    
    debugPrint('MomentsFeedScreen: Starting fresh playback');
    _playCurrentVideo();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    debugPrint('MomentsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop all playback and disable wakelock before disposing
    _pauseAllVideos();
    
    // Restore original system UI on dispose
    _restoreOriginalSystemUI();
    
    // Dispose animation controllers
    _likeAnimationController.dispose();
    _heartScaleController.dispose();
    _burstAnimationController.dispose();
    
    // Dispose video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    
    _pageController.dispose();
    
    // Final wakelock disable
    WakelockPlus.disable();
    
    super.dispose();
  }

  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      controller.pause();
    }
    WakelockPlus.disable();
  }

  void _playCurrentVideo() {
    if (!_isScreenActive || !_isAppInForeground || _isCommentsSheetOpen) {
      WakelockPlus.disable();
      return;
    }
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null && _videoInitialized[_currentIndex] == true) {
      controller.seekTo(Duration.zero);
      controller.play();
      WakelockPlus.enable();
    } else {
      // For images or when video is not ready, still enable wakelock
      WakelockPlus.enable();
    }
  }

  void _pauseCurrentVideo() {
    final controller = _videoControllers[_currentIndex];
    if (controller != null && _videoInitialized[_currentIndex] == true) {
      controller.pause();
    }
    WakelockPlus.disable();
  }

  void _togglePlayPause() {
    if (_isCommentsSheetOpen) return; // Don't toggle when comments are open
    
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (_currentIndex >= moments.length) return;
    
    final currentMoment = moments[_currentIndex];
    if (!currentMoment.hasVideo) return;
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null && _videoInitialized[_currentIndex] == true) {
      if (controller.value.isPlaying) {
        controller.pause();
        _isManuallyPaused = true;
        WakelockPlus.disable();
      } else {
        controller.play();
        _isManuallyPaused = false;
        WakelockPlus.enable();
      }
    }
  }

  void _handleDoubleTap() {
    if (_isCommentsSheetOpen) return; // Don't handle double tap when comments are open
    
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (_currentIndex >= moments.length) return;
    
    // Trigger like animation
    setState(() {
      _showLikeAnimation = true;
    });
    
    // Start all animations
    _heartScaleController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _heartScaleController.reverse();
      });
    });
    
    _burstAnimationController.forward().then((_) {
      _burstAnimationController.reset();
    });
    
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
    
    // Like the current moment
    final currentMoment = moments[_currentIndex];
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && !currentMoment.likedBy.contains(currentUser.uid)) {
      ref.read(momentsProvider.notifier).toggleLikeMoment(currentMoment.id, false);
    }
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  // Enhanced back navigation with proper system UI restoration
  void _handleBackNavigation() {
    // Close comments sheet if open
    if (_isCommentsSheetOpen) {
      Navigator.of(context).pop();
      return;
    }
    
    // Pause playback and disable wakelock before leaving
    _pauseCurrentVideo();
    
    // Restore the original system UI style
    _restoreOriginalSystemUI();
    
    // Small delay to ensure system UI is properly restored
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _initializeVideoController(int index, String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });
      }
      
      if (index == _currentIndex && _isScreenActive && _isAppInForeground && !_isCommentsSheetOpen) {
        controller.play();
        WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('Error initializing video $index: $e');
    }
  }

  // Simplified page change method (pure chronological)
  void _onPageChanged(int index) {
    if (_isCommentsSheetOpen) return; // Don't change pages when comments are open
    
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (index >= moments.length) {
      // Loop back to beginning when reaching the end
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      return;
    }

    // Pause current video and disable wakelock
    _pauseCurrentVideo();
    
    setState(() {
      _currentIndex = index;
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    // Initialize video controller if needed
    final moment = moments[index];
    if (moment.hasVideo && !_videoControllers.containsKey(index)) {
      _initializeVideoController(index, moment.videoUrl!);
    }

    // Play new video (this will enable wakelock if appropriate)
    _playCurrentVideo();
    
    // Record view
    ref.read(momentsProvider.notifier).recordView(moment.id);
  }

  // Simplified navigation method (chronological)
  void _navigateToStartMoment(List<MomentModel> moments) {
    if (_hasNavigatedToStart) return;
    
    // Find start moment index or use 0 (chronologically first)
    int startIndex = 0;
    if (widget.startMomentId != null) {
      final foundIndex = moments.indexWhere((m) => m.id == widget.startMomentId!);
      if (foundIndex != -1) {
        startIndex = foundIndex;
      }
    }
    
    _hasNavigatedToStart = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.animateToPage(
          startIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        setState(() {
          _currentIndex = startIndex;
        });
        
        final moment = moments[startIndex];
        if (moment.hasVideo && !_videoControllers.containsKey(startIndex)) {
          _initializeVideoController(startIndex, moment.videoUrl!);
        }
        
        Future.delayed(const Duration(milliseconds: 100), () {
          _playCurrentVideo();
        });
        
        ref.read(momentsProvider.notifier).recordView(moment.id);
      }
    });
  }

  Widget _buildCurrentVideoWidget() {
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return const SizedBox.shrink();
    
    final moments = momentsAsyncValue.value!;
    if (_currentIndex >= moments.length) return const SizedBox.shrink();
    
    final currentMoment = moments[_currentIndex];
    
    if (currentMoment.hasVideo) {
      return _buildVideoPlayer(_currentIndex);
    } else if (currentMoment.hasImages) {
      return _buildImageCarousel(currentMoment.imageUrls);
    } else {
      return _buildTextContent(currentMoment);
    }
  }

  // Add this method to control video window mode
  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
  }

  // Add this new method to build the small video window
  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;
    
    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          // Close comments and return to full screen
          Navigator.of(context).pop();
          _setVideoWindowMode(false);
        },
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Video content
                Positioned.fill(
                  child: _buildCurrentVideoWidget(),
                ),
                
                // Close button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add the expandable caption method from status viewer
  Widget _buildExpandableCaption(String caption, int momentIndex) {
    // Check if caption needs truncation (more than 2 lines estimated)
    final isLongCaption = caption.length > 100 || caption.split('\n').length > 2;
    final isExpanded = _captionExpanded[momentIndex] ?? false;
    
    // Create truncated version
    String displayText = caption;
    if (isLongCaption && !isExpanded) {
      // Split by lines first
      final lines = caption.split('\n');
      if (lines.length > 2) {
        displayText = lines.take(2).join('\n');
        // If the second line is too long, truncate it
        final secondLineWords = displayText.split(' ');
        if (secondLineWords.length > 15) {
          displayText = secondLineWords.take(15).join(' ');
        }
      } else {
        // Single long line - truncate by words
        final words = caption.split(' ');
        if (words.length > 15) {
          displayText = words.take(15).join(' ');
        }
      }
    }
    
    return GestureDetector(
      onTap: () {
        if (isLongCaption) {
          setState(() {
            _captionExpanded[momentIndex] = !isExpanded;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.3,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
            children: [
              TextSpan(text: displayText),
              if (isLongCaption) ...[
                if (!isExpanded) ...[
                  const TextSpan(text: '... '),
                  TextSpan(
                    text: 'more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ] else ...[
                  if (displayText != caption)
                    TextSpan(
                      text: caption.substring(displayText.length),
                    ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'less',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Ensure system UI is properly set
    _setupSystemUI();
    
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Stack(
            children: [
              // Main video content - positioned to avoid covering status bar and system nav
              Positioned(
                top: systemTopPadding,
                left: 0,
                right: 0,
                bottom: systemBottomPadding,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: _buildBody(),
                ),
              ),
              
              // Small video window when comments are open
              if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
              
              // Top bar with back button and title
              if (!_isCommentsSheetOpen) // Hide top bar when comments are open
                _buildTopBar(systemTopPadding),
              
              // TikTok-style right side menu (hide when comments are open)
              if (!_isCommentsSheetOpen) _buildRightSideMenu(),
            ],
          ),
        ),
      ),
    );
  }

  // Simplified top bar
  Widget _buildTopBar(double systemTopPadding) {
    return Positioned(
      top: systemTopPadding + 16,
      left: 0,
      right: 0,
      child: Row(
        children: [
          // Back button
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              onPressed: _handleBackNavigation,
              icon: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 28,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              iconSize: 28,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              splashRadius: 24,
              tooltip: 'Back',
            ),
          ),
          
          // Title
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  'Moments',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search button
          IconButton(
            onPressed: () {
              // TODO: Add search functionality
            },
            icon: const Icon(
              CupertinoIcons.search,
              color: Colors.white,
              size: 28,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            iconSize: 28,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            splashRadius: 24,
            tooltip: 'Search',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final momentsStream = ref.watch(momentsFeedStreamProvider);

    return momentsStream.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (moments) {
        if (moments.isEmpty) {
          return _buildEmptyState();
        }

        // Handle navigation to start moment when data is available
        _navigateToStartMoment(moments);

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: moments.length + 1, // +1 for loop detection
          onPageChanged: _onPageChanged,
          physics: _isCommentsSheetOpen ? const NeverScrollableScrollPhysics() : null,
          itemBuilder: (context, index) {
            // Handle loop back to beginning
            if (index >= moments.length) {
              return const SizedBox.shrink();
            }
            
            final moment = moments[index];
            
            return GestureDetector(
              onTap: _togglePlayPause,
              onDoubleTap: _handleDoubleTap,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMomentContent(moment, index),
                    
                    // Like animation overlay
                    if (_showLikeAnimation && index == _currentIndex)
                      _buildLikeAnimationOverlay(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMomentContent(MomentModel moment, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content
        if (moment.hasVideo)
          _buildVideoPlayer(index)
        else if (moment.hasImages)
          _buildImageCarousel(moment.imageUrls)
        else
          _buildTextContent(moment),
        
        // Bottom info overlay - minimal like ChannelFeedScreen
        Positioned(
          left: 16,
          right: 80, // Leave space for right side menu  
          bottom: 16,
          child: _buildMomentInfo(moment, index),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;
    
    if (controller == null || !isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) return _buildPlaceholder();
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: imageUrls.length > 1,
        autoPlay: imageUrls.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      items: imageUrls.map((imageUrl) {
        return SizedBox.expand(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextContent(MomentModel moment) {
    return Container(
      color: context.modernTheme.primaryColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            moment.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildMomentInfo(MomentModel moment, int momentIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Author info
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: moment.authorImage.isNotEmpty
                  ? NetworkImage(moment.authorImage)
                  : null,
              backgroundColor: Colors.grey[300],
              child: moment.authorImage.isEmpty
                  ? Text(
                      moment.authorName.isNotEmpty 
                          ? moment.authorName[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                moment.authorName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Expandable caption with professional styling like status viewer
        if (moment.content.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildExpandableCaption(moment.content, momentIndex),
        ],

        const SizedBox(height: 8),
        
        // Simple timestamp only - keeping same styling as before
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _getTimeAgo(moment.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TikTok-style right side menu - with Gift and DM icons
  Widget _buildRightSideMenu() {
    final momentsAsyncValue = ref.watch(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return const SizedBox.shrink();
    
    final moments = momentsAsyncValue.value!;
    final currentMoment = moments.isNotEmpty && _currentIndex < moments.length 
        ? moments[_currentIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4,
      bottom: systemBottomPadding + 16,
      child: Column(
        children: [
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentMoment?.likedBy.contains(ref.read(currentUserProvider)?.uid) == true 
                  ? CupertinoIcons.heart
                  : CupertinoIcons.heart,
              color: currentMoment?.likedBy.contains(ref.read(currentUserProvider)?.uid) == true 
                  ? Colors.red 
                  : Colors.white,
              size: 28,
            ),
            label: _formatCount(currentMoment?.likesCount ?? 0),
            onTap: () => _likeCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // Comment button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.captions_bubble,
              color: Colors.white,
              size: 28,
            ),
            label: _formatCount(currentMoment?.commentsCount ?? 0),
            onTap: () => _showCommentsForCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // Gift button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.gift,
              color: Colors.white,
              size: 28,
            ),
            label: 'Gift',
            onTap: () {
              // TODO: Add gift functionality
            },
          ),
          
          const SizedBox(height: 10),
          
          // DM button - custom white rounded square with 'DM' text
          _buildRightMenuItem(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'DM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            label: 'Inbox',
            onTap: () {
              // TODO: Add DM functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRightMenuItem({
    required Widget child,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Like animation overlay - More exciting with burst effect and floating hearts
  Widget _buildLikeAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Burst effect background
            Center(
              child: AnimatedBuilder(
                animation: _burstAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _burstAnimation.value * 3,
                    child: Opacity(
                      opacity: (1 - _burstAnimation.value).clamp(0.0, 0.5),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.red.withOpacity(0.6),
                              Colors.pink.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Center heart that scales
            Center(
              child: AnimatedBuilder(
                animation: _heartScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Floating hearts
            ..._buildFloatingHearts(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    const heartCount = 8;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return List.generate(heartCount, (index) {
      final offsetX = (index * 0.25 - 1) * screenWidth * 0.5;
      final startY = screenHeight * 0.6;
      final endY = screenHeight * 0.1;
      
      return AnimatedBuilder(
        animation: _likeAnimationController,
        builder: (context, child) {
          final progress = _likeAnimationController.value;
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final y = startY + (endY - startY) * progress;
          
          return Positioned(
            left: screenWidth / 2 + offsetX,
            top: y,
            child: Transform.rotate(
              angle: (index - 4) * 0.3 + progress * 2,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: index % 2 == 0 ? Colors.red : Colors.pink,
                    size: 25 + (index % 3) * 10.0,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No moments yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a moment!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createMomentScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Moment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(momentsFeedStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _likeCurrentMoment(MomentModel? moment) {
    if (moment == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isLiked = moment.likedBy.contains(currentUser.uid);
    ref.read(momentsProvider.notifier).toggleLikeMoment(moment.id, isLiked);
    
    // Trigger animation when liking via button
    if (!isLiked) {
      setState(() {
        _showLikeAnimation = true;
      });
      
      // Start all animations
      _heartScaleController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _heartScaleController.reverse();
        });
      });
      
      _burstAnimationController.forward().then((_) {
        _burstAnimationController.reset();
      });
      
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reset();
        if (mounted) {
          setState(() {
            _showLikeAnimation = false;
          });
        }
      });
      
      HapticFeedback.mediumImpact();
    }
  }

  // Updated method to control video window mode
  void _showCommentsForCurrentMoment(MomentModel? moment) {
    if (moment == null || _isCommentsSheetOpen) return;
    
    // Set video to small window mode
    _setVideoWindowMode(true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => MomentCommentsBottomSheet(
        moment: moment,
        onClose: () {
          // Reset video to full screen mode
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      // Ensure video returns to full screen mode
      _setVideoWindowMode(false);
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}