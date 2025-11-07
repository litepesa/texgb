// lib/features/videos/widgets/video_item.dart - COMPLETE VERSION with Timestamp Only Display
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
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
  final bool isFeedScreen;

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
    this.isFeedScreen = false,
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
  Timer? _retryTimer;

  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  bool _showLikeAnimation = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMedia();
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

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

    if (widget.isCommentsOpen != oldWidget.isCommentsOpen) {
      _handleCommentsStateChange();
    }

    if (widget.video.id != oldWidget.video.id) {
      _cleanupCurrentController();
      _showFullCaption = false;
      if (widget.isActive) {
        _initializeMedia();
      }
    } else if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
  }

  void _cleanupCurrentController() {
    _retryTimer?.cancel();
    _retryTimer = null;
    
    if (_videoPlayerController != null && widget.preloadedController == null) {
      try {
        if (_videoPlayerController!.value.isInitialized) {
          _videoPlayerController!.pause();
        }
      } catch (e) {
        // Silent error handling
      }
      
      try {
        _videoPlayerController!.dispose();
      } catch (e) {
        // Silent error handling
      }
    }
    
    _videoPlayerController = null;
    _isInitialized = false;
    _isPlaying = false;
    _isInitializing = false;
  }

  void _handleActiveStateChange() {
    if (widget.video.isMultipleImages) return;

    if (widget.isActive) {
      _cleanupCurrentController();
      _initializeMedia();
    } else {
      if (_isInitialized && _isPlaying) {
        _pauseVideo();
      }
    }
  }

  void _handleCommentsStateChange() {
    setState(() {
      _isCommentsSheetOpen = widget.isCommentsOpen;
    });

    if (!widget.isCommentsOpen &&
        widget.isActive &&
        _isInitialized &&
        !_isPlaying) {
      _playVideo();
    }
  }

  UserModel? _getUserDataIfAvailable() {
    final users = ref.read(usersProvider);
    final isUsersLoading = ref.read(isAuthLoadingProvider);

    if (isUsersLoading || users.isEmpty) {
      return null;
    }

    try {
      return users.firstWhere(
        (user) => user.uid == widget.video.channelId,
      );
    } catch (e) {
      return null;
    }
  }

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

    return true;
  }

  IconData _getIconForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'like videos':
      case 'like':
        return Icons.favorite;
      case 'follow users':
      case 'follow':
        return Icons.people;
      case 'buy this product':
      case 'buy':
        return Icons.shopping_cart;
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
    if (_isInitializing) {
      return;
    }

    try {
      setState(() {
        _isInitializing = true;
      });

      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        await _createControllerFromNetwork();
      }

      if (_videoPlayerController != null && mounted) {
        await _setupVideoController();
      }
    } catch (e) {
      _scheduleRetry();
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _scheduleRetry() {
    if (_isInitialized || _isPlaying) {
      return;
    }
    
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInitialized && !_isPlaying) {
        _initializeMedia();
      }
    });
  }

  Future<void> _usePreloadedController() async {
    _videoPlayerController = widget.preloadedController;

    if (!_videoPlayerController!.value.isInitialized) {
      await _videoPlayerController!.initialize();
    }
  }

  Future<void> _createControllerFromNetwork() async {
    final cachedUri = VideoCacheService().getLocalUri(widget.video.videoUrl);
    
    _videoPlayerController = VideoPlayerController.networkUrl(
      cachedUri,
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );

    await _videoPlayerController!.initialize().timeout(
      const Duration(seconds: 15),
    );
  }

  Future<void> _setupVideoController() async {
    if (_videoPlayerController == null) return;
    
    _videoPlayerController!.setLooping(true);

    _retryTimer?.cancel();
    _retryTimer = null;

    setState(() {
      _isInitialized = true;
    });

    if (widget.isActive && !widget.isCommentsOpen) {
      _videoPlayerController!.seekTo(Duration.zero);
      _playVideo();
    }

    if (widget.onVideoControllerReady != null) {
      widget.onVideoControllerReady!(_videoPlayerController!);
    }
  }

  void _playVideo() {
    if (_isInitialized && _videoPlayerController != null && mounted) {
      _videoPlayerController!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _videoPlayerController != null && mounted) {
      _videoPlayerController!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.video.isMultipleImages || _isCommentsSheetOpen) return;

    if (!_isInitialized) {
      if (!_isInitializing) {
        _initializeMedia();
      }
      return;
    }

    bool willBePlaying;
    if (_isPlaying) {
      _pauseVideo();
      willBePlaying = false;
    } else {
      _playVideo();
      willBePlaying = true;
    }

    if (widget.onManualPlayPause != null) {
      widget.onManualPlayPause!(willBePlaying);
    }
  }

  void _handleDoubleTap() async {
    if (_isCommentsSheetOpen) return;

    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

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

    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.likeVideo(widget.video.id);

    if (mounted) {
      setState(() {});
    }
  }

  void _handleFollowToggle() async {
    final canInteract = await _requireAuthentication('follow users');
    if (!canInteract) return;

    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.followUser(widget.video.channelId);

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCaptionExpansion() {
    setState(() {
      _showFullCaption = !_showFullCaption;
    });
  }

  DateTime _parseVideoTimestamp() {
    try {
      return DateTime.parse(widget.video.createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _likeAnimationController.dispose();
    _heartScaleController.dispose();

    if (_videoPlayerController != null && widget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    
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
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(),

                if (widget.isLoading || _isInitializing)
                  _buildLoadingIndicator(),

                if (!widget.video.isMultipleImages &&
                    _isInitialized &&
                    !_isPlaying &&
                    !_isCommentsSheetOpen)
                  _buildTikTokPlayIndicator(),

                if (_showLikeAnimation && !_isCommentsSheetOpen)
                  _buildLikeAnimation(),

                if (widget.video.isMultipleImages &&
                    widget.video.imageUrls.length > 1 &&
                    !_isCommentsSheetOpen)
                  _buildCarouselIndicators(),
              ],
            ),
          ),

          if (!_isCommentsSheetOpen) _buildBottomContentOverlay(),
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
        fit: BoxFit.cover,
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
        child: (widget.isLoading || _isInitializing) 
            ? _buildLoadingIndicator() 
            : Container(color: Colors.black),
      );
    }

    return _buildFullScreenVideo();
  }

  Widget _buildFullScreenVideo() {
    final controller = _videoPlayerController!;

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

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
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

        if (!textPainter.didExceedMaxLines) {
          return Text(fullText, style: captionStyle);
        }

        final firstLineHeight = textPainter.preferredLineHeight;
        final oneAndHalfLineHeight = firstLineHeight * 1.5;

        final cutPosition = textPainter
            .getPositionForOffset(Offset(maxWidth * 0.7, oneAndHalfLineHeight));

        var cutIndex = cutPosition.offset;

        while (cutIndex > 0 && fullText[cutIndex] != ' ') {
          cutIndex--;
        }

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

  // Bottom overlay with system padding positioning and timestamp only
  Widget _buildBottomContentOverlay() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    final bottomPadding = MediaQuery.of(context).padding.bottom ;

    return Positioned(
      bottom: bottomPadding,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserNameWithVerification(),
          const SizedBox(height: 6),
          if (widget.video.caption.isNotEmpty) ...[
            _buildSmartCaption(),
            const SizedBox(height: 8),
          ],
          _buildTimestampDisplay(),
        ],
      ),
    );
  }

  Widget _buildUserNameWithVerification() {
    return Consumer(
      builder: (context, ref, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.video.channelName,
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
          ],
        );
      },
    );
  }

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

  String _getRelativeTime() {
    final now = DateTime.now();
    final videoTime = _parseVideoTimestamp();
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

  Widget _buildCarouselIndicators() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    final topPosition = MediaQuery.of(context).padding.top + 120;

    return Positioned(
      top: topPosition,
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

  Widget _buildTopLeftFollowButton() {
    final videoUser = _getUserDataIfAvailable();
    final currentUser = ref.watch(currentUserProvider);

    if (videoUser == null) {
      return const SizedBox.shrink();
    }

    final isOwner = currentUser != null && currentUser.uid == widget.video.channelId;
    if (isOwner) return const SizedBox.shrink();

    final followedUsers = ref.watch(followedUsersProvider);
    final isFollowing = followedUsers.contains(widget.video.channelId);

    final topPosition = MediaQuery.of(context).padding.top + 8;

    return Positioned(
      top: topPosition,
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      ),
    );
  }
}