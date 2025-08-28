// lib/features/dramas/screens/episode_feed_screen.dart - SIMPLIFIED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/widgets/drama_unlock_dialog.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class EpisodeFeedScreen extends ConsumerStatefulWidget {
  final String dramaId;
  final int initialEpisodeNumber;

  const EpisodeFeedScreen({
    super.key,
    required this.dramaId,
    this.initialEpisodeNumber = 1,
  });

  @override
  ConsumerState<EpisodeFeedScreen> createState() => _EpisodeFeedScreenState();
}

class _EpisodeFeedScreenState extends ConsumerState<EpisodeFeedScreen> {
  late PageController _pageController;
  int _currentEpisodeNumber = 1;
  Map<int, VideoPlayerController?> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Map<int, bool> _episodeCompleted = {};
  bool _isAutoPlaying = false;
  DramaModel? _drama;

  @override
  void initState() {
    super.initState();
    _currentEpisodeNumber = widget.initialEpisodeNumber;
    _pageController = PageController(initialPage: widget.initialEpisodeNumber - 1);
    
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _disposeAllVideoControllers();
    _pageController.dispose();
    super.dispose();
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

  void _initializeVideoController(int episodeNumber) {
    if (_videoControllers[episodeNumber] != null || _drama == null) return;

    // Get video URL from drama model
    final videoUrl = _drama!.getEpisodeVideo(episodeNumber);
    if (videoUrl == null || videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _videoControllers[episodeNumber] = controller;

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoInitialized[episodeNumber] = true;
          _episodeCompleted[episodeNumber] = false;
        });
        
        // Auto play if this is the current episode
        if (episodeNumber == _currentEpisodeNumber) {
          controller.play();
          controller.addListener(_videoProgressListener);
        }
      }
    }).catchError((error) {
      print('Video initialization error for episode $episodeNumber: $error');
      if (mounted) {
        setState(() {
          _videoInitialized[episodeNumber] = false;
        });
      }
    });
  }

  void _onPageChanged(int pageIndex) {
    final newEpisodeNumber = pageIndex + 1; // Convert to 1-indexed
    final oldEpisodeNumber = _currentEpisodeNumber;
    
    setState(() {
      _currentEpisodeNumber = newEpisodeNumber;
      _isAutoPlaying = false;
    });

    // Pause old video
    final oldController = _videoControllers[oldEpisodeNumber];
    if (oldController != null) {
      oldController.pause();
      oldController.removeListener(_videoProgressListener);
    }

    // Play new video
    final newController = _videoControllers[newEpisodeNumber];
    if (newController != null && _videoInitialized[newEpisodeNumber] == true) {
      newController.play();
      _episodeCompleted[newEpisodeNumber] = false;
      newController.addListener(_videoProgressListener);
    }

    // Mark episode as watched
    _markEpisodeWatched(newEpisodeNumber);
  }

  void _videoProgressListener() {
    final controller = _videoControllers[_currentEpisodeNumber];
    if (controller == null || !mounted) return;

    final position = controller.value.position;
    final duration = controller.value.duration;
    
    // Check if video completed
    if (duration.inMilliseconds > 0) {
      final remainingTime = duration.inMilliseconds - position.inMilliseconds;
      final isCompleted = remainingTime <= 50; // 50ms buffer
      
      if (isCompleted && 
          !(_episodeCompleted[_currentEpisodeNumber] ?? false) && 
          !_isAutoPlaying) {
        
        _episodeCompleted[_currentEpisodeNumber] = true;
        _handleVideoCompleted();
      }
    }

    setState(() {}); // Update progress bar
  }

  void _handleVideoCompleted() async {
    if (_isAutoPlaying || _drama == null) return;
    _isAutoPlaying = true;

    try {
      final isDramaUnlocked = ref.read(isDramaUnlockedProvider(widget.dramaId));
      
      // Check if there's a next episode
      if (_currentEpisodeNumber < _drama!.totalEpisodes) {
        final nextEpisodeNumber = _currentEpisodeNumber + 1;
        final canWatchNext = _drama!.canWatchEpisode(nextEpisodeNumber, isDramaUnlocked);
        
        if (canWatchNext) {
          // Auto-advance to next episode
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted && _isAutoPlaying) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        } else {
          // Can't watch next - restart current video
          final currentController = _videoControllers[_currentEpisodeNumber];
          if (currentController != null) {
            await currentController.seekTo(Duration.zero);
            currentController.play();
          }
          _isAutoPlaying = false;
        }
      } else {
        // No more episodes - restart current video
        final currentController = _videoControllers[_currentEpisodeNumber];
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

  void _markEpisodeWatched(int episodeNumber) {
    // Update user's drama progress to this episode
    ref.read(dramaActionsProvider.notifier).markEpisodeWatched(
      'episode_${widget.dramaId}_$episodeNumber', // Simple episode ID
      widget.dramaId,
      episodeNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: dramaAsync.when(
        data: (drama) {
          if (drama == null) {
            return _buildError('Drama not found', 'This drama is no longer available.');
          }
          
          _drama = drama; // Store for use in other methods
          
          if (drama.totalEpisodes == 0) {
            return _buildError('No episodes', 'This drama has no episodes yet.');
          }
          
          return _buildFeedScreen(drama);
        },
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError('Failed to load', error.toString()),
      ),
    );
  }

  Widget _buildFeedScreen(DramaModel drama) {
    final isDramaUnlocked = ref.watch(isDramaUnlockedProvider(widget.dramaId));

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: drama.totalEpisodes,
      itemBuilder: (context, pageIndex) {
        final episodeNumber = pageIndex + 1; // Convert to 1-indexed
        final canWatch = drama.canWatchEpisode(episodeNumber, isDramaUnlocked);
        
        // Initialize video controller for watchable episodes
        if (canWatch) {
          _initializeVideoController(episodeNumber);
        }

        return _buildEpisodeItem(drama, episodeNumber, canWatch);
      },
    );
  }

  Widget _buildEpisodeItem(DramaModel drama, int episodeNumber, bool canWatch) {
    final controller = _videoControllers[episodeNumber];
    final isInitialized = _videoInitialized[episodeNumber] == true;

    return Stack(
      children: [
        // Video or placeholder background
        Positioned.fill(
          child: canWatch && controller != null && isInitialized
              ? _buildVideoPlayer(controller)
              : _buildEpisodePlaceholder(drama, episodeNumber),
        ),

        // Lock overlay for premium episodes
        if (!canWatch)
          _buildLockOverlay(drama, episodeNumber),

        // UI overlays
        _buildUIOverlays(drama, episodeNumber, controller, canWatch),
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

  Widget _buildEpisodePlaceholder(DramaModel drama, int episodeNumber) {
    return Container(
      color: Colors.black,
      child: drama.bannerImage.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Use drama banner as background
                Image.network(
                  drama.bannerImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildDefaultPlaceholder(),
                ),
                // Dark overlay
                Container(
                  color: Colors.black.withOpacity(0.4),
                ),
                // Episode number overlay
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$episodeNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Episode $episodeNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildDefaultPlaceholder(),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Episode $_currentEpisodeNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockOverlay(DramaModel drama, int episodeNumber) {
    return Container(
      color: Colors.black.withOpacity(0.8),
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
              child: const Icon(Icons.lock, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Episode $episodeNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Premium Episode - Unlock Required',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showUnlockDialog(drama),
              icon: const Icon(Icons.workspace_premium),
              label: Text('Unlock All Episodes (${Constants.dramaUnlockCost} coins)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUIOverlays(DramaModel drama, int episodeNumber, VideoPlayerController? controller, bool canWatch) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                ),
                const Spacer(),
                // Episode counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$episodeNumber / ${drama.totalEpisodes}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drama title
                Text(
                  drama.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Simple episode title
                Text(
                  'Episode $episodeNumber',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                
                // Video controls (if playing)
                if (canWatch && controller != null)
                  _buildVideoControls(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    final currentPosition = controller.value.position;
    final totalDuration = controller.value.duration;
    
    final progress = totalDuration.inMilliseconds > 0 
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds 
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
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
                trackHeight: 2,
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
                onChangeStart: (value) => controller.pause(),
                onChangeEnd: (value) {
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
            'Loading drama...',
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
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
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
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
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
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}

// MASSIVELY SIMPLIFIED compared to original:
// - No complex episode state management
// - No separate episode providers
// - Episodes are just numbered videos in the drama
// - Single video player logic
// - TikTok-style vertical feed
// - Drama-centric unlock logic