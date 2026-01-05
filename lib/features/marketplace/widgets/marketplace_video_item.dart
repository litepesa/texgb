// lib/features/marketplace/widgets/marketplace_video_item.dart - WeChat Channels Style Layout for Marketplace
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/marketplace/services/marketplace_cache_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_comments_bottom_sheet.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_reaction_input.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class MarketplaceItem extends ConsumerStatefulWidget {
  final MarketplaceVideoModel marketplaceVideo;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final Function(bool isPlaying)? onManualPlayPause;
  final VideoPlayerController? preloadedController;
  final bool isLoading;
  final bool hasFailed;
  final bool isCommentsOpen;
  final bool showVerificationBadge;
  final bool isFeedScreen;
  final Function()? onCommentsPressed;
  final Function()? onDirectMessagePressed;

  const MarketplaceItem({
    super.key,
    required this.marketplaceVideo,
    required this.isActive,
    this.onVideoControllerReady,
    this.onManualPlayPause,
    this.preloadedController,
    this.isLoading = false,
    this.hasFailed = false,
    this.isCommentsOpen = false,
    this.showVerificationBadge = true,
    this.isFeedScreen = false,
    this.onCommentsPressed,
    this.onDirectMessagePressed,
  });

  @override
  ConsumerState<MarketplaceItem> createState() => _MarketplaceItemState();
}

class _MarketplaceItemState extends ConsumerState<MarketplaceItem>
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

  // Download state management
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Bottom nav bar height
  static const double _bottomNavHeight = 60.0;
  // Top rounded corner radius
  static const double _topCornerRadius = 16.0;

  // Marketplace brand colors - teal/green theme to differentiate from video feature
  static const Color _primaryColor = Color(0xFF00BFA5); // Teal
  static const Color _secondaryColor = Color(0xFF00897B); // Darker teal
  static const Color _accentColor = Color(0xFF4DB6AC); // Light teal
  static const Color _dmButtonColor = Color(0xFF00ACC1); // Cyan for DM

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
  void didUpdateWidget(MarketplaceItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCommentsOpen != oldWidget.isCommentsOpen) {
      _handleCommentsStateChange();
    }

    if (widget.marketplaceVideo.id != oldWidget.marketplaceVideo.id) {
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
    if (widget.marketplaceVideo.isMultipleImages) return;

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
        (user) => user.uid == widget.marketplaceVideo.userId,
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
      case 'comment on videos':
      case 'comment':
        return Icons.comment;
      case 'send direct messages':
      case 'dm':
        return Icons.message;
      case 'send gifts':
      case 'gift':
        return Icons.card_giftcard;
      case 'download videos':
      case 'download':
        return Icons.download;
      case 'follow users':
      case 'follow':
        return Icons.person_add;
      case 'buy this product':
      case 'buy':
        return Icons.shopping_cart;
      default:
        return Icons.video_call;
    }
  }

  // Gift functionality
  Future<void> _showVirtualGifts() async {
    final canInteract = await _requireAuthentication('send gifts');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if user is trying to gift their own video
    if (widget.marketplaceVideo.userId == currentUser!.uid) {
      _showCannotGiftOwnVideoMessage();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientName: widget.marketplaceVideo.userName,
        recipientImage: widget.marketplaceVideo.userImage,
        onGiftSelected: (gift) {
          _handleGiftSent(gift);
        },
        onClose: () {},
      ),
    );
  }

  void _handleGiftSent(VirtualGift gift) {
    debugPrint(
        'Gift sent: ${gift.name} (KES ${gift.price}) to ${widget.marketplaceVideo.userName}');
    _showSnackBar(
        '${gift.emoji} ${gift.name} sent to ${widget.marketplaceVideo.userName}!');
  }

  void _showCannotGiftOwnVideoMessage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard,
                color: _primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Gift Your Own Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send gifts to your own videos.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Download functionality
  Future<void> _downloadCurrentVideo() async {
    final canInteract = await _requireAuthentication('download videos');
    if (!canInteract) return;

    if (_isDownloading) {
      _showSnackBar('Video is already downloading...');
      return;
    }

    if (widget.marketplaceVideo.isMultipleImages) {
      _showSnackBar('Cannot download image posts');
      return;
    }

    if (widget.marketplaceVideo.videoUrl.isEmpty) {
      _showSnackBar('Invalid video URL');
      return;
    }

    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showSnackBar('Storage permission required to download videos');
        return;
      }

      await _downloadVideo();
    } catch (e) {
      debugPrint('Error downloading video: $e');
      _showSnackBar('Failed to download video');
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await [
          Permission.videos,
          Permission.photos,
        ].request();

        return status.values.every((status) => status.isGranted);
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true;
  }

  Future<void> _downloadVideo() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();

      Directory? directory;
      String fileName =
          'textgb_${widget.marketplaceVideo.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      final savePath = '${directory.path}/$fileName';

      await dio.download(
        widget.marketplaceVideo.videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      _showSnackBar('Video saved successfully!');

      if (Platform.isAndroid) {
        await _addToGallery(savePath);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
            _showSnackBar('Download timeout. Please try again.');
            break;
          case DioExceptionType.connectionError:
            _showSnackBar('Network error. Check your connection.');
            break;
          default:
            _showSnackBar('Download failed. Please try again.');
        }
      } else {
        _showSnackBar('Download failed. Please try again.');
      }
    }
  }

  Future<void> _addToGallery(String filePath) async {
    try {
      debugPrint('Video saved to: $filePath');
    } catch (e) {
      debugPrint('Error adding to gallery: $e');
    }
  }

  // Helper method to show snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.marketplaceVideo.isMultipleImages) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    if (widget.marketplaceVideo.videoUrl.isEmpty) {
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
    final cachedUri =
        MarketplaceCacheService().getLocalUri(widget.marketplaceVideo.videoUrl);

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
    if (widget.marketplaceVideo.isMultipleImages || _isCommentsSheetOpen)
      return;

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

    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
    marketplaceNotifier.likeMarketplaceVideo(widget.marketplaceVideo.id);

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCaptionExpansion() {
    setState(() {
      _showFullCaption = !_showFullCaption;
    });
  }

  // Like video functionality
  void _likeCurrentVideo() async {
    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
    marketplaceNotifier.likeMarketplaceVideo(widget.marketplaceVideo.id);
  }

  // Show comments functionality
  void _showCommentsForCurrentVideo() async {
    if (_isCommentsSheetOpen) return;

    final canInteract = await _requireAuthentication('comment on videos');
    if (!canInteract) return;

    if (widget.onCommentsPressed != null) {
      widget.onCommentsPressed!();
    } else {
      // Fallback to local implementation
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        builder: (context) => MarketplaceCommentsBottomSheet(
          marketplaceVideo: widget.marketplaceVideo,
          onClose: () {},
        ),
      );
    }
  }

  // Direct message functionality - Shows marketplace reaction input
  Future<void> _openDirectMessage() async {
    final canInteract = await _requireAuthentication('send direct messages');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if trying to message own listing
    if (widget.marketplaceVideo.userId == currentUser!.uid) {
      _showCannotDMOwnVideoMessage();
      return;
    }

    if (widget.onDirectMessagePressed != null) {
      widget.onDirectMessagePressed!();
    } else {
      // Show marketplace reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MarketplaceReactionInput(
          listing: widget.marketplaceVideo,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send message
      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        try {
          final chatNotifier = ref.read(chatListProvider.notifier);

          // Create chat with video reaction (reusing for marketplace)
          final chatId = await chatNotifier.createChatWithVideoReaction(
            otherUserId: widget.marketplaceVideo.userId,
            videoId: widget.marketplaceVideo.id,
            videoUrl: widget.marketplaceVideo.videoUrl,
            thumbnailUrl: widget.marketplaceVideo.thumbnailUrl.isNotEmpty
                ? widget.marketplaceVideo.thumbnailUrl
                : (widget.marketplaceVideo.isMultipleImages &&
                        widget.marketplaceVideo.imageUrls.isNotEmpty
                    ? widget.marketplaceVideo.imageUrls.first
                    : ''),
            userName: widget.marketplaceVideo.userName,
            userImage: widget.marketplaceVideo.userImage,
            reaction: reaction,
          );

          if (chatId != null && mounted) {
            // Get listing owner user data for chat screen
            final authNotifier = ref.read(authenticationProvider.notifier);
            final listingOwner =
                await authNotifier.getUserById(widget.marketplaceVideo.userId);

            // Create UserModel for navigation
            final contact = listingOwner ??
                UserModel.fromMap({
                  'uid': widget.marketplaceVideo.userId,
                  'name': widget.marketplaceVideo.userName,
                  'profileImage': widget.marketplaceVideo.userImage,
                });

            // Navigate to chat screen
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chatId,
                    contact: contact,
                  ),
                ),
              );
            }
          } else {
            _showSnackBar('Failed to send message. Please try again.');
          }
        } catch (e) {
          debugPrint('Error sending marketplace message: $e');
          _showSnackBar('Failed to send message. Please try again.');
        }
      }
    }
  }

  void _showCannotDMOwnVideoMessage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _dmButtonColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.message,
                color: _dmButtonColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Message Yourself',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send a direct message to your own listing.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _dmButtonColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to user profile
  void _navigateToUserProfile() {
    context.push(RoutePaths.userProfile(widget.marketplaceVideo.userId));
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
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

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        children: [
          // Video content area with rounded top corners
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_topCornerRadius),
                topRight: Radius.circular(_topCornerRadius),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video/Image content
                  GestureDetector(
                    onTap: _togglePlayPause,
                    onDoubleTap: _handleDoubleTap,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaContent(),
                        if (widget.isLoading || _isInitializing)
                          _buildLoadingIndicator(),
                        if (!widget.marketplaceVideo.isMultipleImages &&
                            _isInitialized &&
                            !_isPlaying &&
                            !_isCommentsSheetOpen)
                          _buildTikTokPlayIndicator(),
                        if (_showLikeAnimation && !_isCommentsSheetOpen)
                          _buildLikeAnimation(),
                        if (widget.marketplaceVideo.isMultipleImages &&
                            widget.marketplaceVideo.imageUrls.length > 1 &&
                            !_isCommentsSheetOpen)
                          _buildCarouselIndicators(),
                      ],
                    ),
                  ),
                  // Caption overlay at bottom of video area
                  if (!_isCommentsSheetOpen) _buildCaptionOverlay(),
                ],
              ),
            ),
          ),
          // Bottom navigation bar
          if (!_isCommentsSheetOpen)
            Container(
              height: _bottomNavHeight + bottomPadding,
              padding: EdgeInsets.only(bottom: bottomPadding),
              color: Colors.black,
              child: _buildBottomNavBar(),
            ),
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
                      child: Icon(
                        CupertinoIcons.heart_fill,
                        color: _primaryColor,
                        size: 80,
                        shadows: const [
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
                  CupertinoIcons.heart_fill,
                  color: _primaryColor,
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
    if (widget.marketplaceVideo.isMultipleImages) {
      return _buildImageCarousel();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageCarousel() {
    if (widget.marketplaceVideo.imageUrls.isEmpty) {
      return _buildPlaceholder(Icons.broken_image);
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.marketplaceVideo.imageUrls.length > 1,
        autoPlay: widget.isActive &&
            widget.marketplaceVideo.imageUrls.length > 1 &&
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
      items: widget.marketplaceVideo.imageUrls.map((imageUrl) {
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
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: _primaryColor,
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
        CupertinoIcons.play_fill,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  // Caption overlay at bottom of video area
  Widget _buildCaptionOverlay() {
    return Positioned(
      bottom: 2,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Caption and hashtags
          if (widget.marketplaceVideo.caption.isNotEmpty ||
              widget.marketplaceVideo.tags.isNotEmpty)
            GestureDetector(
              onTap: _toggleCaptionExpansion,
              child: _buildCaptionText(),
            ),
          // Timestamp - sits right above bottom nav
          Text(
            _getRelativeTime(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w400,
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
    );
  }

  // Timestamp parsing and formatting methods
  DateTime _parseVideoTimestamp() {
    try {
      return DateTime.parse(widget.marketplaceVideo.createdAt);
    } catch (e) {
      return DateTime.now();
    }
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

  Widget _buildCaptionText() {
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

    // Build text with caption and hashtags
    String fullText = widget.marketplaceVideo.caption;

    // Add hashtags if they exist
    if (widget.marketplaceVideo.tags.isNotEmpty) {
      final hashtags =
          widget.marketplaceVideo.tags.map((tag) => '#$tag').join(' ');
      if (fullText.isNotEmpty) {
        fullText += ' $hashtags';
      } else {
        fullText = hashtags;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showFullCaption
          ? _buildExpandedCaption(fullText, captionStyle, moreStyle)
          : _buildTruncatedCaption(fullText, captionStyle, moreStyle),
    );
  }

  Widget _buildExpandedCaption(
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

  Widget _buildTruncatedCaption(
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

  // Bottom navigation bar with user info, price, and action buttons
  Widget _buildBottomNavBar() {
    return Consumer(
      builder: (context, ref, child) {
        final hasPrice = widget.marketplaceVideo.price > 0;

        return Container(
          height: _bottomNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Left side: User avatar + username + price
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToUserProfile,
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: widget.marketplaceVideo.userImage.isNotEmpty
                              ? Image.network(
                                  widget.marketplaceVideo.userImage,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildAvatarPlaceholder();
                                  },
                                )
                              : _buildAvatarPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Username and price
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.marketplaceVideo.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (hasPrice) ...[
                              const SizedBox(height: 2),
                              _buildPriceTag(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side: Action buttons - DM, Like, Comment (original styling)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DM button - Primary action with gradient
                  _buildActionButton(
                    icon: CupertinoIcons.chat_bubble_2,
                    label: 'DM',
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00BCD4), // Cyan
                        Color(0xFF00ACC1), // Darker cyan
                      ],
                    ),
                    onTap: _openDirectMessage,
                  ),
                  const SizedBox(width: 10),
                  // Like button
                  _buildActionButton(
                    icon: widget.marketplaceVideo.isLiked == true
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    count: widget.marketplaceVideo.likes,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF5252), // Red
                        Color(0xFFFF1744), // Darker red
                      ],
                    ),
                    onTap: _likeCurrentVideo,
                  ),
                  const SizedBox(width: 10),
                  // Comment button
                  _buildActionButton(
                    icon: CupertinoIcons.text_bubble,
                    count: widget.marketplaceVideo.comments,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4FC3F7), // Light blue
                        Color(0xFF29B6F6), // Blue
                      ],
                    ),
                    onTap: _showCommentsForCurrentVideo,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Price tag widget
  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor,
            _secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.marketplaceVideo.formattedPrice,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          widget.marketplaceVideo.userName.isNotEmpty
              ? widget.marketplaceVideo.userName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Original action button styling with gradient and integrated count
  Widget _buildActionButton({
    required IconData icon,
    int? count,
    String? label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label ?? (count != null ? _formatCount(count) : '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            List.generate(widget.marketplaceVideo.imageUrls.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentImageIndex == index ? 8 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _currentImageIndex == index
                  ? _primaryColor
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
}
