// lib/features/videos/screens/single_video_screen.dart - WeChat Channels Style Layout
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/widgets/video_item.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/widgets/video_reaction_input.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SingleVideoScreen extends ConsumerStatefulWidget {
  final String videoId;

  const SingleVideoScreen({
    super.key,
    required this.videoId,
    String? userId,
  });

  @override
  ConsumerState<SingleVideoScreen> createState() => _SingleVideoScreenState();
}

class _SingleVideoScreenState extends ConsumerState<SingleVideoScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();

  int _currentVideoIndex = 0;
  bool _isAppInForeground = true;
  final bool _isScreenActive = true;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;

  UserModel? _videoAuthor;
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;
  bool _isOwner = false;

  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _loadVideoData();
    _setupCacheCleanup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
    final brightness = Theme.of(context).brightness;
    _originalSystemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.black,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer =
        Timer.periodic(const Duration(minutes: 10), (timer) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive && !_isNavigatingAway && !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _stopPlayback();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadVideoData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allVideos = ref.read(videosProvider);
      final targetVideo = allVideos.firstWhere(
        (video) => video.id == widget.videoId,
        orElse: () => throw Exception('Video not found'),
      );

      final allUsers = ref.read(usersProvider);
      final author = allUsers.firstWhere(
        (user) => user.uid == targetVideo.userId,
        orElse: () => throw Exception('User not found'),
      );

      final userVideos = allVideos
          .where((video) => video.userId == targetVideo.userId)
          .toList();

      userVideos.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.createdAt);
          final bTime = DateTime.parse(b.createdAt);
          return bTime.compareTo(aTime);
        } catch (e) {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      final targetIndex =
          userVideos.indexWhere((video) => video.id == widget.videoId);

      final followedUsers = ref.read(followedUsersProvider);
      final isFollowing = followedUsers.contains(targetVideo.userId);
      final currentUser = ref.read(currentUserProvider);
      final isOwner =
          currentUser != null && currentUser.uid == targetVideo.userId;

      if (mounted) {
        setState(() {
          _videoAuthor = author;
          _videos = userVideos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
          _isLoading = false;
          _currentVideoIndex = targetIndex >= 0 ? targetIndex : 0;
        });

        if (targetIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        _startIntelligentPreloading();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }
    if (_videos.isEmpty) return;
  }

  void _startFreshPlayback() {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isManuallyPaused ||
        _isCommentsSheetOpen) {
      return;
    }

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
    } else {
      if (_videos.isNotEmpty && _currentVideoIndex < _videos.length) {
        setState(() {});
      }
    }

    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  void _pauseForNavigation() {
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    _isNavigatingAway = false;
    if (_isScreenActive &&
        _isAppInForeground &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted &&
            !_isNavigatingAway &&
            _isScreenActive &&
            _isAppInForeground &&
            !_isManuallyPaused &&
            !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
  }

  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
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
                Positioned.fill(child: _buildVideoContentOnly()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContentOnly() {
    if (_videos.isEmpty || _currentVideoIndex >= _videos.length) {
      return Container(color: Colors.black);
    }

    final currentVideo = _videos[_currentVideoIndex];

    if (currentVideo.isMultipleImages) {
      return _buildImageCarouselOnly(currentVideo.imageUrls);
    } else {
      return _buildVideoPlayerOnly();
    }
  }

  Widget _buildVideoPlayerOnly() {
    if (_currentVideoController?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _currentVideoController!.value.size.width,
          height: _currentVideoController!.value.size.height,
          child: VideoPlayer(_currentVideoController!),
        ),
      ),
    );
  }

  Widget _buildImageCarouselOnly(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 32)),
      );
    }

    return PageView.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 32)),
            );
          },
        );
      },
    );
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    setState(() {
      _currentVideoController = controller;
    });

    controller.seekTo(Duration.zero);
    WakelockPlus.enable();

    if (_isScreenActive &&
        _isAppInForeground &&
        !_isNavigatingAway &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
    }
  }

  void onManualPlayPause(bool isPlaying) {
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    if (index >= _videos.length || !_isScreenActive) return;

    setState(() {
      _currentVideoIndex = index;
      _isManuallyPaused = false;
    });

    if (_isScreenActive &&
        _isAppInForeground &&
        !_isNavigatingAway &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }

    ref
        .read(authenticationProvider.notifier)
        .incrementViewCount(_videos[index].id);
  }

  void _handleBackNavigation() {
    if (_isCommentsSheetOpen) {
      Navigator.of(context).pop();
      return;
    }

    _stopPlayback();

    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showCommentsForCurrentVideo(VideoModel video) {
    _setVideoWindowMode(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        video: video,
        onClose: () {
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      _setVideoWindowMode(false);
    });
  }

  Future<void> _openDirectMessage(VideoModel video) async {
    _pauseForNavigation();

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _showSnackBar('Please log in to send messages');
      _resumeFromNavigation();
      return;
    }

    if (video.userId == currentUser.uid) {
      _showSnackBar('You cannot message yourself');
      _resumeFromNavigation();
      return;
    }

    try {
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoReactionInput(
          video: video,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        final chatNotifier = ref.read(chatListProvider.notifier);
        final chatId = await chatNotifier.createOrGetChat(video.userId);

        if (chatId != null) {
          final chatRepository = ref.read(chatRepositoryProvider);
          final videoReaction = VideoReactionModel.fromVideoAndUser(
            videoId: video.id,
            videoUrl: video.videoUrl,
            thumbnailUrl: video.thumbnailUrl,
            userName: video.userName,
            userImage: video.userImage,
            reaction: reaction,
          );

          await chatRepository.sendVideoReactionMessage(
            chatId: chatId,
            senderId: currentUser.uid,
            videoReaction: videoReaction,
          );

          final contact = UserModel(
            uid: video.userId,
            name: video.userName,
            profileImage: video.userImage,
            phoneNumber: '',
            bio: '',
            coverImage: '',
            followers: 0,
            following: 0,
            videosCount: 0,
            likesCount: 0,
            isVerified: video.isVerified,
            tags: const [],
            followerUIDs: const [],
            followingUIDs: const [],
            likedVideos: const [],
            createdAt: '',
            updatedAt: '',
            lastSeen: '',
            isActive: true,
            isFeatured: false,
          );

          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                contact: contact,
              ),
            ),
          );
        } else {
          _showSnackBar('Failed to open chat. Please try again.');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error opening direct message: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSnackBar('Error: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _resumeFromNavigation();
        }
      });
    }
  }

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPlayback();

    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    }

    _cacheCleanupTimer?.cancel();
    _pageController.dispose();
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final topPadding = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Black status bar area
            Container(
              height: topPadding,
              color: Colors.black,
            ),
            // Video content area with header overlay inside
            Expanded(
              child: Stack(
                children: [
                  _buildVideoFeed(),
                  // Header overlay inside video area
                  if (!_isCommentsSheetOpen) _buildHeaderOverlay(),
                  // Small video window when comments are open
                  if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: _handleBackNavigation,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
            // User name in center
            Expanded(
              child: Center(
                child: Text(
                  _videoAuthor?.name ?? 'Videos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Spacer for symmetry
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFeed() {
    if (_videos.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen
          ? null
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = _videos[index];

        return VideoItem(
          video: video,
          isActive: index == _currentVideoIndex &&
              _isScreenActive &&
              _isAppInForeground &&
              !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          showVerificationBadge: true,
          onCommentsPressed: () => _showCommentsForCurrentVideo(video),
          onDirectMessagePressed: () => _openDirectMessage(video),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined,
              color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Videos Yet',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isOwner
                ? 'Create your first video to share with your followers'
                : 'This user hasn\'t posted any videos yet',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, Constants.createPostScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0050),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Video'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Content',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleBackNavigation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0050),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
