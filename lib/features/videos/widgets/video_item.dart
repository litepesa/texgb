// lib/features/videos/widgets/video_item.dart - TIKTOK/REELS STYLE LAYOUT UPDATE
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/videos/services/video_cache_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/widgets/video_reaction_input.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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
  final Function()? onCommentsPressed;
  final Function()? onDirectMessagePressed;

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
    this.onCommentsPressed,
    this.onDirectMessagePressed,
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

  // Download state management
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

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
        (user) => user.uid == widget.video.userId,
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

  // Follow user functionality
  Future<void> _followCurrentUser() async {
    final canInteract = await _requireAuthentication('follow users');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if trying to follow self
    if (widget.video.userId == currentUser!.uid) {
      _showCannotFollowSelfMessage();
      return;
    }

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      await authNotifier.followUser(widget.video.userId);

      _showSnackBar('You are now following ${widget.video.userName}');

      // Trigger UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error following user: $e');
      _showSnackBar('Failed to follow user. Please try again.');
    }
  }

  void _showCannotFollowSelfMessage() {
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
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off,
                color: Colors.blue,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Follow Yourself',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot follow your own account.',
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Gift functionality
  Future<void> _showVirtualGifts() async {
    final canInteract = await _requireAuthentication('send gifts');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if user is trying to gift their own video
    if (widget.video.userId == currentUser!.uid) {
      _showCannotGiftOwnVideoMessage();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientName: widget.video.userName,
        recipientImage: widget.video.userImage,
        onGiftSelected: (gift) {
          _handleGiftSent(gift);
        },
        onClose: () {},
      ),
    );
  }

  void _handleGiftSent(VirtualGift gift) {
    debugPrint(
        'Gift sent: ${gift.name} (KES ${gift.price}) to ${widget.video.userName}');
    _showSnackBar(
        '${gift.emoji} ${gift.name} sent to ${widget.video.userName}!');
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
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.orange,
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
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Buy product functionality (dummy for now - will add cart/payment later)
  Future<void> _buyProduct() async {
    final canInteract = await _requireAuthentication('buy this product');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if user is trying to buy their own product
    if (widget.video.userId == currentUser!.uid) {
      _showCannotBuyOwnProductMessage();
      return;
    }

    // Show coming soon message (placeholder until cart/payment is implemented)
    _showComingSoonMessage();
  }

  void _showCannotBuyOwnProductMessage() {
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
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Buy Own Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot purchase your own product.',
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
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonMessage() {
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
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.blue,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Checkout Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'re working on adding cart and payment features. Stay tuned!',
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
                backgroundColor: Colors.blue,
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

    if (widget.video.isMultipleImages) {
      _showSnackBar('Cannot download image posts');
      return;
    }

    if (widget.video.videoUrl.isEmpty) {
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
          'textgb_${widget.video.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

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
        widget.video.videoUrl,
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

  void _toggleCaptionExpansion() {
    setState(() {
      _showFullCaption = !_showFullCaption;
    });
  }

  // Like video functionality
  void _likeCurrentVideo() async {
    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.likeVideo(widget.video.id);
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
        builder: (context) => CommentsBottomSheet(
          video: widget.video,
          onClose: () {},
        ),
      );
    }
  }

  // Direct message functionality - Shows video reaction input
  Future<void> _openDirectMessage() async {
    final canInteract = await _requireAuthentication('send direct messages');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if trying to message own video
    if (widget.video.userId == currentUser!.uid) {
      _showCannotDMOwnVideoMessage();
      return;
    }

    if (widget.onDirectMessagePressed != null) {
      widget.onDirectMessagePressed!();
    } else {
      // Show video reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoReactionInput(
          video: widget.video,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send reaction
      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        try {
          final chatNotifier = ref.read(chatListProvider.notifier);

          // Create chat with video reaction
          final chatId = await chatNotifier.createChatWithVideoReaction(
            otherUserId: widget.video.userId,
            videoId: widget.video.id,
            videoUrl: widget.video.videoUrl,
            thumbnailUrl: widget.video.thumbnailUrl.isNotEmpty
                ? widget.video.thumbnailUrl
                : (widget.video.isMultipleImages &&
                        widget.video.imageUrls.isNotEmpty
                    ? widget.video.imageUrls.first
                    : ''),
            userName: widget.video.userName,
            userImage: widget.video.userImage,
            reaction: reaction,
          );

          if (chatId != null && mounted) {
            // Get video owner user data for chat screen
            final authNotifier = ref.read(authenticationProvider.notifier);
            final videoOwner =
                await authNotifier.getUserById(widget.video.userId);

            // Create UserModel for navigation
            final contact = videoOwner ??
                UserModel.fromMap({
                  'uid': widget.video.userId,
                  'name': widget.video.userName,
                  'profileImage': widget.video.userImage,
                  'isVerified': widget.video.isVerified,
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
            _showSnackBar('Failed to send reaction. Please try again.');
          }
        } catch (e) {
          debugPrint('Error sending video reaction: $e');
          _showSnackBar('Failed to send reaction. Please try again.');
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
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.message,
                color: Colors.blue,
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
              'You cannot send a direct message to your own video.',
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Timestamp parsing and formatting methods
  DateTime _parseVideoTimestamp() {
    try {
      return DateTime.parse(widget.video.createdAt);
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
          
          // Bottom left content area (TikTok/Reels style)
          if (!_isCommentsSheetOpen) _buildBottomLeftContent(),
          
          // Right side action menu (TikTok/Reels style)
          if (!_isCommentsSheetOpen) _buildRightSideActions(),
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

  // TIKTOK/REELS STYLE: Bottom left content area
  Widget _buildBottomLeftContent() {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 8;
    
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price tag for paid content (placed before username)
          if (widget.video.price > 0) ...[
            _buildPriceButton(),
            const SizedBox(height: 4),
          ],
          
          // Username with verification badge
          _buildUsernameRow(),
          
          const SizedBox(height: 1),
          
          // Caption with hashtags
          if (widget.video.caption.isNotEmpty || widget.video.tags.isNotEmpty)
            _buildCaptionWithHashtags(),
          
          const SizedBox(height: 1),
          
          // Timestamp
          _buildTimestamp(),
        ],
      ),
    );
  }

  Widget _buildPriceButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_offer,
          color: Colors.greenAccent[400],
          size: 16,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Text(
          widget.video.formattedPrice,
          style: TextStyle(
            color: Colors.greenAccent[400],
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameRow() {
    return Consumer(
      builder: (context, ref, child) {
        // Get the actual user data to check verification status
        final userData = _getUserDataIfAvailable();
        final isUserVerified = userData?.isVerified ?? false;

        return GestureDetector(
          onTap: _navigateToUserProfile,
          child: Row(
            children: [
              // Username
              Flexible(
                child: Text(
                  '@${widget.video.userName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Verification badge - based on USER verification, not video
              if (isUserVerified && widget.showVerificationBadge) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.verified,
                  color: Colors.blue[600],
                  size: 18,
                  /*shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],*/
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptionWithHashtags() {
    if (widget.video.caption.isEmpty && widget.video.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final captionStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      height: 1.4,
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
    String fullText = widget.video.caption;

    // Add hashtags if they exist
    if (widget.video.tags.isNotEmpty) {
      final hashtags = widget.video.tags.map((tag) => '#$tag').join(' ');
      if (fullText.isNotEmpty) {
        fullText += '\n$hashtags';
      } else {
        fullText = hashtags;
      }
    }

    return GestureDetector(
      onTap: _toggleCaptionExpansion,
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
            text: '  less',
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

  Widget _buildTimestamp() {
    return Text(
      _getRelativeTime(),
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 12,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  // TIKTOK/REELS STYLE: Right side action menu
  Widget _buildRightSideActions() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned(
      right: 8,
      bottom: bottomPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile avatar with follow badge
          _buildProfileAvatarWithFollowBadge(),
          
          const SizedBox(height: 14),
          
          // Like button
          _buildRightSideActionButton(
            icon: widget.video.isLiked == true
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            count: widget.video.likes,
            color: Colors.white,
            onTap: _likeCurrentVideo,
          ),
          
          const SizedBox(height: 14),
          
          // Comment button
          _buildRightSideActionButton(
            icon: CupertinoIcons.text_bubble,
            count: widget.video.comments,
            color: Colors.white,
            onTap: _showCommentsForCurrentVideo,
          ),
          
          const SizedBox(height: 14),
          
          // DM button
          _buildRightSideActionButton(
            icon: CupertinoIcons.chat_bubble_2,
            count: 0,
            color: Colors.white,
            onTap: _openDirectMessage,
          ),
          
          const SizedBox(height: 14),
          
          // Gift/Save or Buy button based on video price
          if (widget.video.price == 0) ...[
            // Gift button for free content
            _buildRightSideActionButton(
              icon: CupertinoIcons.gift,
              count: 0,
              color: Colors.white,
              onTap: _showVirtualGifts,
            ),
            
            const SizedBox(height: 14),
            
            // Save button for free content
            _buildRightSideActionButton(
              icon: _isDownloading ? Icons.downloading : Icons.download,
              count: 0,
              color: _isDownloading ? Colors.green : Colors.white,
              onTap: _downloadCurrentVideo,
              isDownloading: _isDownloading,
              downloadProgress: _downloadProgress,
            ),
          ] else ...[
            // Buy button for paid content
            _buildRightSideActionButton(
              icon: Icons.shopping_cart_checkout_rounded,
              count: 0,
              color: Colors.white,
              onTap: _buyProduct,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileAvatarWithFollowBadge() {
    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.read(currentUserProvider);
        final isCurrentUserVideo = currentUser?.uid == widget.video.userId;
        final isFollowing = ref
            .read(authenticationProvider.notifier)
            .isUserFollowed(widget.video.userId);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Profile avatar
            GestureDetector(
              onTap: _navigateToUserProfile,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.video.userImage.isNotEmpty == true
                      ? Image.network(
                          widget.video.userImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Center(
                                child: Text(
                                  widget.video.userName.isNotEmpty == true
                                      ? widget.video.userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              widget.video.userName.isNotEmpty == true
                                  ? widget.video.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            
            // Follow badge (+ button) - Only show if not current user's video and not already following
            if (!isCurrentUserVideo && currentUser != null && !isFollowing)
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _followCurrentUser,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRightSideActionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isDownloading = false,
    double downloadProgress = 0.0,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            child: Center(
              child: isDownloading && downloadProgress > 0
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: downloadProgress,
                        color: Colors.green,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (count > 0)
          Text(
            _formatCount(count),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselIndicators() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();

    final topPadding = MediaQuery.of(context).padding.top + 120;

    return Positioned(
      top: topPadding,
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

  void _navigateToUserProfile() {
    context.push(RoutePaths.userProfile(widget.video.userId));
  }
}