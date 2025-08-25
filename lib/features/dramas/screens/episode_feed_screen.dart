// lib/features/dramas/screens/episode_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/providers/video_player_provider.dart';
import 'package:textgb/features/dramas/widgets/drama_unlock_dialog.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class EpisodeFeedScreen extends ConsumerStatefulWidget {
  final String dramaId;
  final String? initialEpisodeId;

  const EpisodeFeedScreen({
    super.key,
    required this.dramaId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<EpisodeFeedScreen> createState() => _EpisodeFeedScreenState();
}

class _EpisodeFeedScreenState extends ConsumerState<EpisodeFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<int, VideoPlayerController?> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Map<int, bool> _episodeCompleted = {}; // Track completion status
  bool _isAutoPlaying = false; // Prevent multiple auto-play triggers

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Enable wakelock to prevent screen from sleeping during video playback
    WakelockPlus.enable();
    
    // Find initial episode index if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findInitialEpisodeIndex();
    });
  }

  @override
  void dispose() {
    // Disable wakelock when leaving the screen
    WakelockPlus.disable();
    _disposeAllVideoControllers();
    _pageController.dispose();
    super.dispose();
  }

  void _findInitialEpisodeIndex() async {
    if (widget.initialEpisodeId == null) return;
    
    final episodes = await ref.read(dramaEpisodesProvider(widget.dramaId).future);
    final initialIndex = episodes.indexWhere((ep) => ep.episodeId == widget.initialEpisodeId);
    
    if (initialIndex != -1 && mounted) {
      _currentIndex = initialIndex;
      _pageController.animateToPage(
        initialIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _disposeAllVideoControllers() {
    for (final controller in _videoControllers.values) {
      controller?.removeListener(_videoProgressListener);
      controller?.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    _episodeCompleted.clear();
  }

  void _initializeVideoController(int index, EpisodeModel episode) {
    if (_videoControllers[index] != null) return;

    // For demo purposes, we'll use a placeholder video URL
    // In a real app, you'd get this from episode.videoUrl
    final videoUrl = episode.videoUrl.isNotEmpty 
        ? episode.videoUrl 
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[index] = controller;

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
          _episodeCompleted[index] = false; // Reset completion status
        });
        
        // Auto play if this is the current page
        if (index == _currentIndex) {
          controller.play();
          // Don't set looping here - we'll handle completion manually
          // Add progress listener for real-time updates
          controller.addListener(_videoProgressListener);
        }
      }
    }).catchError((error) {
      print('Video initialization error: $error');
      if (mounted) {
        setState(() {
          _videoInitialized[index] = false;
        });
      }
    });
  }

  void _onPageChanged(int index) {
    final oldIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
      _isAutoPlaying = false; // Reset auto-play flag when manually changing
    });

    // Pause old video and remove listeners
    final oldController = _videoControllers[oldIndex];
    if (oldController != null) {
      oldController.pause();
      oldController.removeListener(_videoProgressListener);
    }

    // Play new video and add listeners
    final newController = _videoControllers[index];
    if (newController != null && _videoInitialized[index] == true) {
      newController.play();
      // Reset completion status for new episode
      _episodeCompleted[index] = false;
      newController.addListener(_videoProgressListener);
    }
  }

  void _videoProgressListener() {
    final controller = _videoControllers[_currentIndex];
    if (controller == null || !mounted) return;

    final position = controller.value.position;
    final duration = controller.value.duration;
    
    // Check if video completed (at the very end)
    if (duration.inMilliseconds > 0) {
      // Use a very small buffer (50ms) to account for timing precision
      final remainingTime = duration.inMilliseconds - position.inMilliseconds;
      final isCompleted = remainingTime <= 50; // Less than 50ms remaining
      
      if (isCompleted && 
          !(_episodeCompleted[_currentIndex] ?? false) && 
          !_isAutoPlaying) {
        
        // Mark this episode as completed
        _episodeCompleted[_currentIndex] = true;
        _handleVideoCompleted();
      }
    }

    // Trigger rebuild to update progress bar
    setState(() {});
  }

  void _handleVideoCompleted() async {
    if (_isAutoPlaying) return; // Prevent multiple triggers
    _isAutoPlaying = true;

    try {
      final episodes = await ref.read(dramaEpisodesProvider(widget.dramaId).future);
      final isDramaUnlocked = ref.read(isDramaUnlockedProvider(widget.dramaId));
      
      // Check if there's a next episode
      if (_currentIndex + 1 < episodes.length) {
        final nextEpisode = episodes[_currentIndex + 1];
        final drama = await ref.read(dramaProvider(widget.dramaId).future);
        
        if (drama != null) {
          final canWatchNext = drama.canWatchEpisode(nextEpisode.episodeNumber, isDramaUnlocked);
          
          if (canWatchNext) {
            // Show a brief "Next Episode" indicator
            if (mounted) {
              // Pause current video to prevent looping
              final currentController = _videoControllers[_currentIndex];
              currentController?.pause();
              
              // Auto-advance to next episode after a brief delay
              await Future.delayed(const Duration(milliseconds: 1500));
              
              if (mounted && _isAutoPlaying) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            }
          } else {
            // Can't watch next episode - restart current video or show unlock option
            final currentController = _videoControllers[_currentIndex];
            if (currentController != null) {
              await currentController.seekTo(Duration.zero);
              currentController.play();
            }
            _isAutoPlaying = false;
          }
        }
      } else {
        // No more episodes - restart current video
        final currentController = _videoControllers[_currentIndex];
        if (currentController != null) {
          await currentController.seekTo(Duration.zero);
          currentController.play();
        }
        _isAutoPlaying = false;
      }
    } catch (e) {
      print('Error in auto-play: $e');
      _isAutoPlaying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));
    final episodesAsync = ref.watch(dramaEpisodesProvider(widget.dramaId));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: dramaAsync.when(
        data: (drama) => episodesAsync.when(
          data: (episodes) => _buildFeedScreen(drama, episodes),
          loading: () => _buildLoading(),
          error: (error, stack) => _buildError('Failed to load episodes', error.toString()),
        ),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError('Failed to load drama', error.toString()),
      ),
    );
  }

  Widget _buildFeedScreen(DramaModel? drama, List<EpisodeModel> episodes) {
    if (drama == null || episodes.isEmpty) {
      return _buildError('No content', 'No episodes available for this drama.');
    }

    final isDramaUnlocked = ref.watch(isDramaUnlockedProvider(widget.dramaId));

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final canWatch = drama.canWatchEpisode(episode.episodeNumber, isDramaUnlocked);
        
        // Initialize video controller for this episode
        if (canWatch) {
          _initializeVideoController(index, episode);
        }

        return _buildEpisodeItem(drama, episode, index, canWatch);
      },
    );
  }

  Widget _buildEpisodeItem(DramaModel drama, EpisodeModel episode, int index, bool canWatch) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] == true;

    return Stack(
      children: [
        // Video background
        Positioned.fill(
          child: canWatch && controller != null && isInitialized
              ? _buildVideoPlayer(controller)
              : _buildVideoPlaceholder(episode),
        ),

        // Lock overlay for premium episodes
        if (!canWatch)
          _buildLockOverlay(drama, episode),

        // UI overlays
        _buildUIOverlays(drama, episode, controller, canWatch),
      ],
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(EpisodeModel episode) {
    return Container(
      color: Colors.black,
      child: episode.thumbnailUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: episode.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.video_library_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.video_library_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
    );
  }

  Widget _buildLockOverlay(DramaModel drama, EpisodeModel episode) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Episode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unlock Episode ${episode.episodeNumber}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showUnlockDialog(drama),
              icon: const Icon(Icons.workspace_premium),
              label: Text('Unlock for ${Constants.dramaUnlockCost} coins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUIOverlays(DramaModel drama, EpisodeModel episode, VideoPlayerController? controller, bool canWatch) {
    return SafeArea(
      child: Column(
        children: [
          // Simple top bar with only back button
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Bottom episode info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Episode ${episode.episodeNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Video controls (if video is playing)
          if (canWatch && controller != null)
            _buildVideoControls(controller),
        ],
      ),
    );
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    // Get current position and duration safely
    final currentPosition = controller.value.position;
    final totalDuration = controller.value.duration;
    
    // Calculate progress as a value between 0.0 and 1.0
    final progress = totalDuration.inMilliseconds > 0 
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds 
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _formatDuration(currentPosition),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFE2C55),
                inactiveTrackColor: Colors.white24,
                thumbColor: const Color(0xFFFE2C55),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 1,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * totalDuration.inMilliseconds).round(),
                  );
                  controller.seekTo(newPosition);
                },
                onChangeStart: (value) {
                  // Pause video while seeking
                  controller.pause();
                },
                onChangeEnd: (value) {
                  // Resume playing after seeking (if it was playing before)
                  if (controller.value.isBuffering == false) {
                    controller.play();
                  }
                },
              ),
            ),
          ),
          Text(
            _formatDuration(totalDuration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFE2C55)),
          SizedBox(height: 16),
          Text(
            'Loading episodes...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(DramaModel drama) {
    showDialog(
      context: context,
      builder: (context) => DramaUnlockDialog(drama: drama),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}