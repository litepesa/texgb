// lib/features/channels/screens/channels_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:video_player/video_player.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen>
    with AutomaticKeepAliveClientMixin {
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  final VideoCacheService _cacheService = VideoCacheService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _loadAndPlayFirstVideo();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadAndPlayFirstVideo() async {
    // Load videos first
    await ref.read(channelVideosProvider.notifier).loadVideos();
    
    if (mounted) {
      final videos = ref.read(channelVideosProvider).videos;
      if (videos.isNotEmpty) {
        await _initializeFirstVideo(videos.first);
        
        // Start intelligent preloading for smoother feed experience
        _cacheService.preloadVideosIntelligently(videos, 0);
      }
    }
  }

  Future<void> _initializeFirstVideo(video) async {
    // Only initialize if it's a video (not multiple images)
    if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
      try {
        // Try to get cached video first
        File? videoFile;
        if (await _cacheService.isVideoCached(video.videoUrl)) {
          videoFile = await _cacheService.getCachedVideo(video.videoUrl);
          debugPrint('Using cached video for splash: ${videoFile.path}');
        } else {
          debugPrint('Video not cached, downloading for splash: ${video.videoUrl}');
          videoFile = await _cacheService.preloadVideo(video.videoUrl);
        }

        if (videoFile != null && await videoFile.exists()) {
          // Use cached file
          _videoController = VideoPlayerController.file(
            videoFile,
            videoPlayerOptions: VideoPlayerOptions(
              allowBackgroundPlayback: false,
              mixWithOthers: false,
            ),
          );
        } else {
          // Fallback to network
          debugPrint('Fallback to network video for splash');
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(video.videoUrl),
            videoPlayerOptions: VideoPlayerOptions(
              allowBackgroundPlayback: false,
              mixWithOthers: false,
            ),
          );
        }

        await _videoController!.initialize();
        
        if (mounted && !_hasNavigated) {
          setState(() {
            _isVideoInitialized = true;
          });
          
          // Play muted and looped
          _videoController!.setVolume(0.0);
          _videoController!.setLooping(true);
          _videoController!.play();
        }
      } catch (error) {
        debugPrint('Error initializing splash video: $error');
        // Fallback to network if cache fails
        _initializeNetworkVideo(video);
      }
    }
  }

  Future<void> _initializeNetworkVideo(video) async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(video.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await _videoController!.initialize();
      
      if (mounted && !_hasNavigated) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Play muted and looped
        _videoController!.setVolume(0.0);
        _videoController!.setLooping(true);
        _videoController!.play();
      }
    } catch (error) {
      debugPrint('Error initializing network video: $error');
    }
  }

  void _navigateToChannelsFeed() {
    if (_hasNavigated) return;
    
    setState(() {
      _hasNavigated = true;
    });

    // Pause the splash video
    _videoController?.pause();

    // Navigate to the existing channels feed screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChannelsFeedScreen(),
      ),
    ).then((_) {
      // Resume splash video when returning (if still mounted)
      if (mounted) {
        setState(() {
          _hasNavigated = false;
        });
        _videoController?.play();
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _cacheService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final channelVideosState = ref.watch(channelVideosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navigateToChannelsFeed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _buildContent(channelVideosState),
        ),
      ),
    );
  }

  Widget _buildContent(ChannelVideosState videosState) {
    if (videosState.isLoading) {
      return _buildLoadingState();
    }

    if (videosState.videos.isEmpty) {
      return _buildEmptyState();
    }

    final firstVideo = videosState.videos.first;

    // If it's multiple images, show the first image
    if (firstVideo.isMultipleImages && firstVideo.imageUrls.isNotEmpty) {
      return _buildImageContent(firstVideo.imageUrls.first);
    }

    // If it's a video, show the video player or fallback
    if (firstVideo.videoUrl.isNotEmpty) {
      return _buildVideoContent(firstVideo);
    }

    // Fallback to empty state
    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: Colors.white,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Videos Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to explore channels',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            );
          },
        ),
        // Subtle gradient overlay to ensure any text would be readable
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent(video) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        // Subtle gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}