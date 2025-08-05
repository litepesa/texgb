// lib/features/channels/screens/mini_series_viewer_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/mini_series_models.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MiniSeriesViewerScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final int? startEpisode; // Optional starting episode

  const MiniSeriesViewerScreen({
    Key? key,
    required this.seriesId,
    this.startEpisode,
  }) : super(key: key);

  @override
  ConsumerState<MiniSeriesViewerScreen> createState() => _MiniSeriesViewerScreenState();
}

class _MiniSeriesViewerScreenState extends ConsumerState<MiniSeriesViewerScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // Core controllers
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  MiniSeriesModel? _series;
  int _currentEpisodeIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isAppInForeground = true;
  bool _isScreenActive = true;
  
  // Video controllers
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  
  // Progress tracking
  Timer? _progressTimer;
  double _currentProgress = 0.0;
  
  // Animation controllers
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  bool _showLikeAnimation = false;
  
  // Bottom sheet controller
  final DraggableScrollableController _episodeSheetController = DraggableScrollableController();
  
  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _initializeAnimationControllers();
    _loadSeriesData();
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
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  void _initializeAnimationControllers() {
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
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive) {
          _playCurrentEpisode();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _pauseCurrentEpisode();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadSeriesData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Load series data from repository
      // For now, we'll create a mock series
      _series = _createMockSeries();
      
      // Set starting episode
      if (widget.startEpisode != null && widget.startEpisode! > 0) {
        _currentEpisodeIndex = (widget.startEpisode! - 1).clamp(0, _series!.episodes.length - 1);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Initialize video for current episode
      await _initializeCurrentEpisode();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Mock series data - replace with actual repository call
  MiniSeriesModel _createMockSeries() {
    List<MiniSeriesEpisode> episodes = [];
    for (int i = 1; i <= 25; i++) {
      episodes.add(MiniSeriesEpisode(
        id: 'ep_$i',
        episodeNumber: i,
        title: 'Episode $i: The Adventure Continues',
        videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        thumbnailUrl: 'https://via.placeholder.com/320x180/000000/FFFFFF?text=EP+$i',
        duration: Duration(seconds: 60 + (i * 5)), // 1-2 minutes
        views: 1000 + (i * 100),
        likes: 50 + (i * 5),
        comments: 10 + (i * 2),
        createdAt: Timestamp.now(),
        isActive: true,
      ));
    }

    return MiniSeriesModel(
      id: widget.seriesId,
      channelId: 'channel_123',
      channelName: 'Adventure Stories',
      channelImage: 'https://via.placeholder.com/100x100/FF0000/FFFFFF?text=AS',
      userId: 'user_123',
      title: 'The Great Adventure Series',
      description: 'Join us on an epic adventure through mystical lands and exciting challenges!',
      trailerUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      thumbnailUrl: 'https://via.placeholder.com/320x180/FF0000/FFFFFF?text=TRAILER',
      episodes: episodes,
      totalEpisodes: episodes.length,
      views: 50000,
      likes: 2500,
      comments: 500,
      tags: ['adventure', 'series', 'fantasy'],
      createdAt: Timestamp.now(),
      lastEpisodeAt: Timestamp.now(),
      isActive: true,
      isFeatured: true,
      isCompleted: false,
    );
  }

  Future<void> _initializeCurrentEpisode() async {
    if (_series == null || _currentEpisodeIndex >= _series!.episodes.length) return;
    
    final currentEpisode = _series!.episodes[_currentEpisodeIndex];
    
    try {
      _videoController?.dispose();
      
      // Try to get cached video first
      File? cachedFile;
      try {
        if (await _cacheService.isVideoCached(currentEpisode.videoUrl)) {
          cachedFile = await _cacheService.getCachedVideo(currentEpisode.videoUrl);
        } else {
          cachedFile = await _cacheService.preloadVideo(currentEpisode.videoUrl);
        }
      } catch (e) {
        debugPrint('Cache error, falling back to network: $e');
      }

      if (cachedFile != null && await cachedFile.exists()) {
        _videoController = VideoPlayerController.file(cachedFile);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(currentEpisode.videoUrl));
      }
      
      await _videoController!.initialize();
      _videoController!.setLooping(false); // Don't loop episodes
      
      setState(() {
        _isVideoInitialized = true;
      });
      
      if (_isScreenActive && _isAppInForeground) {
        _playCurrentEpisode();
      }
      
    } catch (e) {
      debugPrint('Error initializing episode: $e');
    }
  }

  void _playCurrentEpisode() {
    if (_isVideoInitialized && _videoController != null) {
      _videoController!.play();
      WakelockPlus.enable();
      setState(() {
        _isPlaying = true;
      });
      _startProgressTracking();
    }
  }

  void _pauseCurrentEpisode() {
    if (_isVideoInitialized && _videoController != null) {
      _videoController!.pause();
      WakelockPlus.disable();
      setState(() {
        _isPlaying = false;
      });
      _stopProgressTracking();
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseCurrentEpisode();
    } else {
      _playCurrentEpisode();
    }
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_isScreenActive || !_isAppInForeground) {
        timer.cancel();
        return;
      }
      
      if (_videoController != null && _videoController!.value.isInitialized) {
        final position = _videoController!.value.position;
        final duration = _videoController!.value.duration;
        
        if (duration.inMilliseconds > 0) {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          setState(() {
            _currentProgress = progress;
          });
          
          // Auto-advance to next episode when current ends
          if (progress >= 0.95 && _currentEpisodeIndex < _series!.episodes.length - 1) {
            _goToNextEpisode();
          }
        }
      }
    });
  }

  void _stopProgressTracking() {
    _progressTimer?.cancel();
  }

  void _goToNextEpisode() {
    if (_currentEpisodeIndex < _series!.episodes.length - 1) {
      setState(() {
        _currentEpisodeIndex++;
        _currentProgress = 0.0;
      });
      _initializeCurrentEpisode();
    }
  }

  void _goToPreviousEpisode() {
    if (_currentEpisodeIndex > 0) {
      setState(() {
        _currentEpisodeIndex--;
        _currentProgress = 0.0;
      });
      _initializeCurrentEpisode();
    }
  }

  void _goToEpisode(int episodeIndex) {
    if (episodeIndex >= 0 && episodeIndex < _series!.episodes.length) {
      setState(() {
        _currentEpisodeIndex = episodeIndex;
        _currentProgress = 0.0;
      });
      _initializeCurrentEpisode();
    }
  }

  void _handleDoubleTap() {
    // Trigger like animation
    setState(() {
      _showLikeAnimation = true;
    });
    
    _heartScaleController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _heartScaleController.reverse();
      });
    });
    
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
    
    // TODO: Like the current episode
    HapticFeedback.mediumImpact();
  }

  void _showEpisodeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildEpisodeSelectorSheet(),
    );
  }

  void _showComments() {
    if (_series == null) return;
    
    final currentEpisode = _series!.episodes[_currentEpisodeIndex];
    _pauseCurrentEpisode();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsBottomSheet(videoId: currentEpisode.id),
    ).whenComplete(() {
      if (_isScreenActive && _isAppInForeground) {
        _playCurrentEpisode();
      }
    });
  }

  void _handleBackNavigation() {
    _pauseCurrentEpisode();
    
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
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
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseCurrentEpisode();
    
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    }
    
    _videoController?.dispose();
    _progressTimer?.cancel();
    _likeAnimationController.dispose();
    _heartScaleController.dispose();
    _episodeSheetController.dispose();
    
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }
    
    if (_series == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Series not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          children: [
            // Main video content
            _buildVideoPlayer(),
            
            // Like animation overlay
            if (_showLikeAnimation)
              _buildLikeAnimationOverlay(),
            
            // Top bar overlay
            _buildTopBar(),
            
            // Bottom content overlay
            _buildBottomContent(),
            
            // Episode navigation controls
            _buildEpisodeControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
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
            if (_isVideoInitialized && _videoController != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            
            // Play indicator when paused
            if (_isVideoInitialized && !_isPlaying)
              const Center(
                child: Icon(
                  CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 80,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 4,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ),
          ),
          
          // Series info
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _series!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Episode selector button
          Material(
            type: MaterialType.transparency,
            child: IconButton(
              onPressed: _showEpisodeSelector,
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.list,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentEpisodeIndex + 1}/${_series!.totalEpisodes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomContent() {
    final currentEpisode = _series!.episodes[_currentEpisodeIndex];
    
    return Positioned(
      bottom: 80, // Above controls
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Episode title
          Text(
            currentEpisode.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Episode info
          Text(
            'Episode ${currentEpisode.episodeNumber} • ${_formatViews(currentEpisode.views)} views',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _currentProgress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeControls() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous episode
          if (_currentEpisodeIndex > 0)
            _buildControlButton(
              icon: CupertinoIcons.backward_fill,
              onPressed: _goToPreviousEpisode,
            ),
          
          const Spacer(),
          
          // Like button
          _buildControlButton(
            icon: CupertinoIcons.heart,
            onPressed: _handleDoubleTap,
            count: _series!.episodes[_currentEpisodeIndex].likes,
          ),
          
          const SizedBox(width: 16),
          
          // Comments button
          _buildControlButton(
            icon: CupertinoIcons.chat_bubble,
            onPressed: _showComments,
            count: _series!.episodes[_currentEpisodeIndex].comments,
          ),
          
          const Spacer(),
          
          // Next episode
          if (_currentEpisodeIndex < _series!.episodes.length - 1)
            _buildControlButton(
              icon: CupertinoIcons.forward_fill,
              onPressed: _goToNextEpisode,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    int? count,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            if (count != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeSelectorSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _series!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_series!.totalEpisodes} episodes',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Episodes list
          Expanded(
            child: ListView.builder(
              itemCount: _series!.episodes.length,
              itemBuilder: (context, index) {
                final episode = _series!.episodes[index];
                final isCurrentEpisode = index == _currentEpisodeIndex;
                
                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: NetworkImage(episode.thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: isCurrentEpisode
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    episode.title,
                    style: TextStyle(
                      color: isCurrentEpisode ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_formatDuration(episode.duration)} • ${_formatViews(episode.views)} views',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _goToEpisode(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Center heart that scales
            Center(
              child: AnimatedBuilder(
                animation: _heartScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
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
                  Icons.favorite,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Series',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 16,
            ),
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

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String _formatViews(int views) {
    return _formatCount(views);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}