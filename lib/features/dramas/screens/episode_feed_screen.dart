// lib/features/dramas/screens/episode_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Find initial episode index if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findInitialEpisodeIndex();
    });
  }

  @override
  void dispose() {
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
      controller?.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
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
        });
        
        // Auto play if this is the current page
        if (index == _currentIndex) {
          controller.play();
          controller.setLooping(true);
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
    });

    // Pause old video
    _videoControllers[oldIndex]?.pause();

    // Play new video
    final newController = _videoControllers[index];
    if (newController != null && _videoInitialized[index] == true) {
      newController.play();
      newController.setLooping(true);
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
              'Unlock ${episode.displayTitle}',
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
    final coinsBalance = ref.watch(userCoinBalanceProvider);
    final isFavorited = ref.watch(isDramaFavoritedProvider(drama.dramaId));

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Text(
                    drama.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$coinsBalance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom info and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Episode info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        episode.displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatCount(episode.episodeViewCount)} views',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action buttons
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button
                    _buildActionButton(
                      icon: isFavorited ? Icons.favorite : Icons.favorite_border,
                      label: _formatCount(drama.favoriteCount),
                      color: isFavorited ? Colors.red.shade400 : Colors.white,
                      onTap: () => _toggleFavorite(),
                    ),

                    const SizedBox(height: 16),

                    // Share button
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.white,
                      onTap: () => _shareEpisode(drama, episode),
                    ),

                    const SizedBox(height: 16),

                    // More options
                    _buildActionButton(
                      icon: Icons.more_vert,
                      label: 'More',
                      color: Colors.white,
                      onTap: () => _showMoreOptions(drama, episode),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video controls (if video is playing)
          if (canWatch && controller != null)
            _buildVideoControls(controller),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls(VideoPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            _formatDuration(controller.value.position),
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
              ),
              child: Slider(
                value: controller.value.position.inMilliseconds.toDouble(),
                min: 0,
                max: controller.value.duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  controller.seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(controller.value.duration),
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

  void _toggleFavorite() {
    ref.read(dramaActionsProvider.notifier).toggleFavorite(widget.dramaId);
  }

  void _shareEpisode(DramaModel drama, EpisodeModel episode) {
    // Implement share functionality
    showSnackBar(context, 'Share functionality coming soon!');
  }

  void _showMoreOptions(DramaModel drama, EpisodeModel episode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report, color: Colors.white),
              title: const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showSnackBar(context, 'Report functionality coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('Episode Details', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  Constants.dramaDetailsScreen,
                  arguments: {'dramaId': drama.dramaId},
                );
              },
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}