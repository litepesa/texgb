// lib/features/moments/screens/moments_feed_screen.dart
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
import 'package:textgb/features/moments/widgets/moment_actions.dart';
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

  @override
  ConsumerState<MomentsFeedScreen> createState() => _MomentsFeedScreenState();
}

class _MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  
  // State management
  int _currentIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  
  // Video controllers
  Map<int, VideoPlayerController> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Map<int, bool> _videoHasError = {};
  
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
    
    // Initialize the starting moment if specified
    if (!_hasInitialized && widget.startMomentId != null) {
      final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
      if (momentsAsyncValue.hasValue) {
        final moments = momentsAsyncValue.value!;
        final startIndex = moments.indexWhere((m) => m.id == widget.startMomentId!);
        if (startIndex != -1) {
          _currentIndex = startIndex;
          final moment = moments[startIndex];
          if (moment.hasVideo) {
            _initializeVideoController(startIndex, moment.videoUrl!);
          }
        }
      }
      _hasInitialized = true;
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
        if (_isScreenActive) {
          _playCurrentVideo();
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

  @override
  void dispose() {
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
    _videoHasError.clear();
    
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
    if (!_isScreenActive || !_isAppInForeground) {
      WakelockPlus.disable();
      return;
    }
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null && _videoInitialized[_currentIndex] == true && !_videoHasError[_currentIndex]!) {
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
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (_currentIndex >= moments.length) return;
    
    final currentMoment = moments[_currentIndex];
    if (!currentMoment.hasVideo) return;
    
    final controller = _videoControllers[_currentIndex];
    if (controller != null && _videoInitialized[_currentIndex] == true && !_videoHasError[_currentIndex]!) {
      if (controller.value.isPlaying) {
        controller.pause();
        WakelockPlus.disable();
      } else {
        controller.play();
        WakelockPlus.enable();
      }
    }
  }

  void _handleDoubleTap() {
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

  void _handleBackNavigation() {
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
      // Dispose existing controller if any
      _videoControllers[index]?.dispose();
      
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
          _videoHasError[index] = false;
        });
      }
      
      if (index == _currentIndex && _isScreenActive && _isAppInForeground) {
        controller.play();
        WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('Error initializing video $index: $e');
      if (mounted) {
        setState(() {
          _videoInitialized[index] = false;
          _videoHasError[index] = true;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
    if (!momentsAsyncValue.hasValue) return;
    
    final moments = momentsAsyncValue.value!;
    if (index >= moments.length) return;

    // Pause current video and disable wakelock
    _pauseCurrentVideo();
    
    setState(() {
      _currentIndex = index;
    });

    // Initialize video controller if needed
    final moment = moments[index];
    if (moment.hasVideo) {
      // Dispose existing controller if any
      _videoControllers[index]?.dispose();
      _initializeVideoController(index, moment.videoUrl!);
    } else {
      // For non-video content, ensure wakelock is enabled
      if (_isScreenActive && _isAppInForeground) {
        WakelockPlus.enable();
      }
    }

    // Play new video (this will enable wakelock if appropriate)
    _playCurrentVideo();
    
    // Record view
    ref.read(momentsProvider.notifier).recordView(moment.id);
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
              // Main content - positioned to avoid covering status bar and system nav
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
              
              // Top bar overlay - Enhanced back button
              Positioned(
                top: systemTopPadding + 16,
                left: 4,
                child: Material(
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
              ),
              
              // TikTok-style right side menu
              _buildRightSideMenu(),
            ],
          ),
        ),
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

        // Find starting index if startMomentId is provided
        int startIndex = 0;
        if (widget.startMomentId != null) {
          startIndex = moments.indexWhere((m) => m.id == widget.startMomentId!);
          if (startIndex == -1) startIndex = 0;
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: moments.length,
          //initialPage: startIndex,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
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
                    
                    // Gradient overlay for better text readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Content overlay - positioned at bottom
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 16,
                      child: _buildMomentInfo(moment),
                    ),
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
    if (moment.hasVideo) {
      return _buildVideoPlayer(index);
    } else if (moment.hasImages) {
      return _buildImageCarousel(moment.imageUrls);
    } else {
      return _buildTextContent(moment);
    }
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;
    final hasError = _videoHasError[index] ?? false;
    
    if (controller == null || !isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final momentsAsyncValue = ref.read(momentsFeedStreamProvider);
                if (momentsAsyncValue.hasValue) {
                  final moments = momentsAsyncValue.value!;
                  if (index < moments.length && moments[index].hasVideo) {
                    _initializeVideoController(index, moments[index].videoUrl!);
                  }
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
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

  Widget _buildMomentInfo(MomentModel moment) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  Text(
                    _getTimeAgo(moment.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (moment.content.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            moment.content,
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
          ),
        ],

        const SizedBox(height: 8),
        
        // Time remaining and privacy info
        Row(
          children: [
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
                    Icons.timer,
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moment.timeRemainingText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                    _getPrivacyIcon(moment.privacy),
                    color: Colors.white.withOpacity(0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moment.privacy.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                  ? Icons.favorite 
                  : Icons.favorite_border,
              color: currentMoment?.likedBy.contains(ref.read(currentUserProvider)?.uid) == true 
                  ? Colors.red 
                  : Colors.white,
              size: 26,
            ),
            label: _formatCount(currentMoment?.likesCount ?? 0),
            onTap: () => _likeCurrentMoment(currentMoment),
          ),
          
          const SizedBox(height: 10),
          
          // Comment button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.chat_bubble,
              color: Colors.white,
              size: 26,
            ),
            label: _formatCount(currentMoment?.commentsCount ?? 0),
            onTap: () => _showCommentsForCurrentMoment(currentMoment),
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

  void _showCommentsForCurrentMoment(MomentModel? moment) {
    if (moment == null) return;
    
    // Pause current video and disable wakelock when showing comments
    _pauseCurrentVideo();
    
    // Navigate to comments screen
    Navigator.pushNamed(
      context,
      Constants.momentCommentsScreen,
      arguments: moment,
    ).whenComplete(() {
      // Resume video and re-enable wakelock when comments are closed
      if (_isScreenActive && _isAppInForeground) {
        _playCurrentVideo();
      }
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

  IconData _getPrivacyIcon(MomentPrivacy privacy) {
    switch (privacy) {
      case MomentPrivacy.public:
        return Icons.public;
      case MomentPrivacy.contacts:
        return Icons.contacts;
      case MomentPrivacy.selectedContacts:
        return Icons.people;
      case MomentPrivacy.exceptSelected:
        return Icons.people_outline;
    }
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}