// lib/features/videos/widgets/video_item.dart - NETWORK ONLY VERSION
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:carousel_slider/carousel_slider.dart';

class VideoItem extends ConsumerStatefulWidget {
  final VideoModel video;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final Function(bool isPlaying)? onManualPlayPause;
  final VideoPlayerController? preloadedController;
  final bool isLoading;
  final bool hasFailed;
  final bool isCommentsOpen;
  final bool showVerificationBadge;

  const VideoItem({
    super.key,
    required this.video,
    required this.isActive,
    this.onVideoControllerReady,
    this.onManualPlayPause,
    this.preloadedController,
    this.isLoading = false,
    this.hasFailed = false,
    this.isCommentsOpen = false,
    this.showVerificationBadge = true,
  });

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentImageIndex = 0;
  bool _isInitializing = false;
  bool _showFullCaption = false;
  bool _isCommentsSheetOpen = false;

  // Animation controllers for like effect
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  bool _showLikeAnimation = false;

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMedia();
  }

  void _initializeAnimations() {
    // Animation for the floating hearts
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animation for the heart scale effect
    _heartScaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heartScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartScaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }

    if (widget.isCommentsOpen != oldWidget.isCommentsOpen) {
      _handleCommentsStateChange();
    }

    if (_shouldReinitializeMedia(oldWidget)) {
      _cleanupCurrentController(oldWidget);
      _initializeMedia();
    }

    // Reset caption state if video changes
    if (widget.video.id != oldWidget.video.id) {
      _showFullCaption = false;
    }
  }

  bool _shouldReinitializeMedia(VideoItem oldWidget) {
    return widget.video.videoUrl != oldWidget.video.videoUrl ||
        widget.video.isMultipleImages != oldWidget.video.isMultipleImages ||
        widget.preloadedController != oldWidget.preloadedController;
  }

  void _cleanupCurrentController(VideoItem oldWidget) {
    if (_isInitialized &&
        _videoPlayerController != null &&
        oldWidget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }

    _videoPlayerController = null;
    _isInitialized = false;
  }

  void _handleActiveStateChange() {
    if (widget.video.isMultipleImages) return;

    if (widget.isActive && _isInitialized && !_isPlaying) {
      _playVideo();
    } else if (!widget.isActive && _isInitialized && _isPlaying) {
      _pauseVideo();
    }
  }

  void _handleCommentsStateChange() {
    setState(() {
      _isCommentsSheetOpen = widget.isCommentsOpen;
    });

    // Don't pause video when comments open - video should continue playing
    // The small window will show the same video stream

    // Only manage play state based on isActive, not comments state
    if (!widget.isCommentsOpen &&
        widget.isActive &&
        _isInitialized &&
        !_isPlaying) {
      _playVideo();
    }
  }

  // 🔧 SIMPLIFIED: Only get user data when it's actually available
  UserModel? _getUserDataIfAvailable() {
    final users = ref.read(usersProvider);
    final isUsersLoading = ref.read(isAuthLoadingProvider);

    // Don't try to find user if still loading or empty
    if (isUsersLoading || users.isEmpty) {
      return null;
    }

    try {
      return users.firstWhere(
        (user) => user.uid == widget.video.userId,
      );
    } catch (e) {
      // User not found in current list
      return null;
    }
  }

  // Helper method to require authentication before actions
  Future<bool> _requireAuthentication(String actionName) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!isAuthenticated) {
      final result = await requireLogin(
        context,
        ref,
        customTitle: 'Sign In Required',
        customSubtitle: 'Please sign in to $actionName.',
        customActionText: 'Sign In',
        customIcon: _getIconForAction(actionName),
      );
      return result;
    }

    return true; // User is authenticated
  }

  // Helper method to get appropriate icon for different actions
  IconData _getIconForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'like videos':
      case 'like':
        return Icons.favorite;
      case 'follow users':
      case 'follow':
        return Icons.people;
      default:
        return Icons.video_call;
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.video.isMultipleImages) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    if (widget.video.videoUrl.isEmpty) {
      return;
    }

    await _initializeVideoFromNetwork();
  }

  Future<void> _initializeVideoFromNetwork() async {
    if (_isInitializing) return;

    try {
      setState(() {
        _isInitializing = true;
      });

      debugPrint('Initializing video from network: ${widget.video.videoUrl}');

      // Use preloaded controller if available
      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        // Always use network URL directly
        await _createControllerFromNetwork();
      }

      if (_videoPlayerController != null && mounted) {
        await _setupVideoController();
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _usePreloadedController() async {
    _videoPlayerController = widget.preloadedController;

    if (!_videoPlayerController!.value.isInitialized) {
      await _videoPlayerController!.initialize();
    }
  }

  Future<void> _createControllerFromNetwork() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );

    await _videoPlayerController!.initialize().timeout(
          const Duration(seconds: 15), // Increased timeout for network videos
        );
  }

  Future<void> _setupVideoController() async {
    _videoPlayerController!.setLooping(true);

    setState(() {
      _isInitialized = true;
    });

    // Only start playing if active and comments are not open
    if (widget.isActive && !widget.isCommentsOpen) {
      // Only seek to beginning for truly new videos, not when resuming
      _videoPlayerController!.seekTo(Duration.zero);
      _playVideo();
    }

    if (widget.onVideoControllerReady != null) {
      widget.onVideoControllerReady!(_videoPlayerController!);
    }
  }

  void _playVideo() {
    if (_isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.video.isMultipleImages || _isCommentsSheetOpen) return;

    if (!_isInitialized) return;

    bool willBePlaying;
    if (_isPlaying) {
      _pauseVideo();
      willBePlaying = false;
    } else {
      // Resume from current position, don't seek to beginning
      _playVideo();
      willBePlaying = true;
    }

    // Notify parent about manual play/pause
    if (widget.onManualPlayPause != null) {
      widget.onManualPlayPause!(willBePlaying);
    }
  }

  void _handleDoubleTap() async {
    if (_isCommentsSheetOpen) return;

    // Check if user is authenticated before allowing like
    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    // Trigger like animation
    _showLikeAnimation = true;
    _heartScaleController.forward().then((_) {
      _heartScaleController.reverse();
    });

    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });

    // Like the video using the authentication provider
    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.likeVideo(widget.video.id);

    // Haptic feedback
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFollowToggle() async {
    // Check if user is authenticated before allowing follow
    final canInteract = await _requireAuthentication('follow users');
    if (!canInteract) return;

    // Follow the user using the authentication provider
    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.followUser(widget.video.userId);

    // Optional: Add haptic feedback
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCaptionExpansion() {
    setState(() {
      _showFullCaption = !_showFullCaption;
    });
  }

  // Helper method to parse RFC3339 timestamp to DateTime
  DateTime _parseVideoTimestamp() {
    try {
      return DateTime.parse(widget.video.createdAt);
    } catch (e) {
      debugPrint('Error parsing video timestamp: $e');
      // Fallback to current time if parsing fails
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _heartScaleController.dispose();

    if (_isInitialized &&
        _videoPlayerController != null &&
        widget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    _videoPlayerController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main content area
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media content with proper full-screen coverage
                _buildMediaContent(),

                // Loading indicator
                if (widget.isLoading || _isInitializing)
                  _buildLoadingIndicator(),

                // Error state
                if (widget.hasFailed) _buildErrorState(),

                // Play indicator for paused videos (TikTok style)
                if (!widget.video.isMultipleImages &&
                    _isInitialized &&
                    !_isPlaying &&
                    !_isCommentsSheetOpen)
                  _buildTikTokPlayIndicator(),

                // Like animation overlay
                if (_showLikeAnimation && !_isCommentsSheetOpen)
                  _buildLikeAnimation(),

                // Image carousel indicators
                if (widget.video.isMultipleImages &&
                    widget.video.imageUrls.length > 1 &&
                    !_isCommentsSheetOpen)
                  _buildCarouselIndicators(),
              ],
            ),
          ),

          // Bottom content overlay (TikTok style) - positioned relative to screen safe area
          if (!_isCommentsSheetOpen) _buildBottomContentOverlay(),

          // Follow Button - positioned relative to screen safe area
          if (!_isCommentsSheetOpen) _buildTopLeftFollowButton(),
        ],
      ),
    );
  }

  Widget _buildLikeAnimation() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _likeAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Center heart that scales
              Center(
                child: AnimatedBuilder(
                  animation: _heartScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartScaleAnimation.value,
                      child: const Icon(
                        CupertinoIcons.heart,
                        color: Colors.red,
                        size: 80,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Floating hearts
              ..._buildFloatingHearts(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    const heartCount = 6;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return List.generate(heartCount, (index) {
      final offsetX = (index * 0.15 - 0.4) * screenWidth;
      final startY = screenHeight * 0.6;
      final endY = screenHeight * 0.2;

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
              angle: (index - 2) * 0.3,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  CupertinoIcons.heart,
                  color: Colors.red,
                  size: 20 + (index % 3) * 10.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMediaContent() {
    if (widget.video.isMultipleImages) {
      return _buildImageCarousel();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageCarousel() {
    if (widget.video.imageUrls.isEmpty) {
      return _buildPlaceholder(Icons.broken_image);
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.video.imageUrls.length > 1,
        autoPlay: widget.isActive &&
            widget.video.imageUrls.length > 1 &&
            !_isCommentsSheetOpen,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        onPageChanged: (index, reason) {
          setState(() {
            _currentImageIndex = index;
          });
        },
      ),
      items: widget.video.imageUrls.map((imageUrl) {
        return _buildFullScreenImage(imageUrl);
      }).toList(),
    );
  }

  Widget _buildFullScreenImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover, // Changed to cover for full screen like video feed
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(Icons.broken_image);
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: widget.isLoading || _isInitializing
            ? _buildLoadingIndicator()
            : null,
      );
    }

    return _buildFullScreenVideo();
  }

  // Full screen video like video feed screen - using cover fit
  Widget _buildFullScreenVideo() {
    final controller = _videoPlayerController!;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover, // Changed to cover for full screen like video feed
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                });
                _initializeMedia();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.3),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildTikTokPlayIndicator() {
    return const Center(
      child: Icon(
        CupertinoIcons.play,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  // Smart caption widget that shows truncated or full text with hashtags
  Widget _buildSmartCaption() {
    if (widget.video.caption.isEmpty) return const SizedBox.shrink();

    final captionStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.3,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.7),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    final moreStyle = captionStyle.copyWith(
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    );

    // Combine caption with hashtags on new line
    String fullText = widget.video.caption;
    if (widget.video.tags.isNotEmpty) {
      final hashtags = widget.video.tags.map((tag) => '#$tag').join(' ');
      fullText += '\n$hashtags';
    }

    return GestureDetector(
      onTap: _toggleCaptionExpansion,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _showFullCaption
            ? _buildExpandedText(fullText, captionStyle, moreStyle)
            : _buildTruncatedText(fullText, captionStyle, moreStyle),
      ),
    );
  }

  Widget _buildExpandedText(
      String fullText, TextStyle captionStyle, TextStyle moreStyle) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: fullText,
            style: captionStyle,
          ),
          TextSpan(
            text: ' less',
            style: moreStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildTruncatedText(
      String fullText, TextStyle captionStyle, TextStyle moreStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final textPainter = TextPainter(
          text: TextSpan(text: fullText, style: captionStyle),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        );
        textPainter.layout(maxWidth: maxWidth);

        // If text doesn't exceed 2 lines, show it fully
        if (!textPainter.didExceedMaxLines) {
          return Text(fullText, style: captionStyle);
        }

        // Find where the text should be cut for 1.5 lines
        final firstLineHeight = textPainter.preferredLineHeight;
        final oneAndHalfLineHeight = firstLineHeight * 1.5;

        final cutPosition = textPainter
            .getPositionForOffset(Offset(maxWidth * 0.7, oneAndHalfLineHeight));

        var cutIndex = cutPosition.offset;

        // Find the last space before cut position to avoid cutting words
        while (cutIndex > 0 && fullText[cutIndex] != ' ') {
          cutIndex--;
        }

        // Ensure we have some text to show
        if (cutIndex < 10) {
          cutIndex = fullText.indexOf(' ', 10);
          if (cutIndex == -1) cutIndex = fullText.length ~/ 3;
        }

        final truncatedText = fullText.substring(0, cutIndex);

        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: truncatedText,
                style: captionStyle,
              ),
              TextSpan(
                text: '... more',
                style: moreStyle,
              ),
            ],
          ),
        );
      },
    );
  }

  // TikTok-style bottom content overlay - positioned relative to screen safe area
  Widget _buildBottomContentOverlay() {
    // Hide all overlay content when comments are open
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    final followedUsers = ref.watch(followedUsersProvider);
    final isFollowing = followedUsers.contains(widget.video.userId);
    final currentUser = ref.watch(currentUserProvider);
    final isOwner =
        currentUser != null && currentUser.uid == widget.video.userId;

    return Positioned(
      bottom:
          MediaQuery.of(context).padding.bottom, // Account for safe area bottom
      left: 16,
      right: 80, // Leave space for right side menu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // User name with verified badge immediately after name
          _buildUserNameWithVerification(),

          const SizedBox(height: 6),

          // Smart caption with hashtags (combined)
          _buildSmartCaption(),

          const SizedBox(height: 8),

          // Always show timestamp at the bottom for consistency
          _buildTimestampDisplay(),
        ],
      ),
    );
  }

  // 🔧 SIMPLIFIED: User name with verification - only show when data is ready
  Widget _buildUserNameWithVerification() {
    return Consumer(
      builder: (context, ref, child) {
        final videoUser = _getUserDataIfAvailable();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User name directly from video metadata
            Flexible(
              child: Text(
                widget.video.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 2,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 6),

            // Keep original verification logic
            if (widget.showVerificationBadge && videoUser != null) ...[
              if (videoUser.isVerified)
                // CUSTOM STYLING FOR VERIFIED USERS
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1DA1F2), // Twitter blue
                        Color(0xFF0D8BD9), // Darker blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DA1F2).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // STYLING FOR NON-VERIFIED USERS
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Not Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  // Helper method to format timestamp as relative time with better formatting - UPDATED
  String _getRelativeTime() {
    final now = DateTime.now();
    final videoTime =
        _parseVideoTimestamp(); // Use helper method to parse RFC3339
    final difference = now.difference(videoTime);

    if (difference.inSeconds < 30) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return 'Less than a minute ago';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return days == 1 ? 'Yesterday' : '$days days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  // Helper method to format timestamp as absolute date/time - UPDATED
  String _getFormattedDateTime() {
    final videoTime =
        _parseVideoTimestamp(); // Use helper method to parse RFC3339
    final now = DateTime.now();
    final difference = now.difference(videoTime);

    if (difference.inDays == 0) {
      // Today - show just time
      return 'Today ${_formatTime(videoTime)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${_formatTime(videoTime)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return '${_formatDayOfWeek(videoTime)} ${_formatTime(videoTime)}';
    } else {
      // Older - show date and time
      return '${_formatDate(videoTime)} ${_formatTime(videoTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDayOfWeek(DateTime dateTime) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dateTime.weekday % 7];
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  // Method to build timestamp display (kept for other screens)
  Widget _buildTimestampDisplay() {
    final timestampStyle = TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.3,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.7),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    return Text(
      _getRelativeTime(),
      style: timestampStyle,
    );
  }

  Widget _buildCarouselIndicators() {
    // Hide indicators when comments are open
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top +
          120, // Account for safe area top + offset
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.video.imageUrls.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentImageIndex == index ? 8 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _currentImageIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // 🔧 SIMPLIFIED: Follow button - positioned relative to screen safe area
  Widget _buildTopLeftFollowButton() {
    final videoUser = _getUserDataIfAvailable();
    final currentUser = ref.watch(currentUserProvider);

    // Don't show anything if user data isn't ready
    if (videoUser == null) {
      return const SizedBox.shrink();
    }

    // Don't show follow button if user owns this video
    final isOwner =
        currentUser != null && currentUser.uid == widget.video.userId;
    if (isOwner) return const SizedBox.shrink();

    final followedUsers = ref.watch(followedUsersProvider);
    final isFollowing = followedUsers.contains(widget.video.userId);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16, // Account for safe area top
      left: 16,
      child: AnimatedScale(
        scale: isFollowing ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: isFollowing ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: _handleFollowToggle,
            child: const Text(
              'Follow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
