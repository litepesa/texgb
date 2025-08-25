// lib/features/dramas/screens/episode_player_screen.dart
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

class EpisodePlayerScreen extends ConsumerStatefulWidget {
  final String dramaId;
  final String episodeId;

  const EpisodePlayerScreen({
    super.key,
    required this.dramaId,
    required this.episodeId,
  });

  @override
  ConsumerState<EpisodePlayerScreen> createState() => _EpisodePlayerScreenState();
}

class _EpisodePlayerScreenState extends ConsumerState<EpisodePlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isControlsVisible = true;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );
    
    _controlsAnimationController.forward();
    
    // Auto-hide controls after 3 seconds
    _startControlsTimer();
    
    // Load the episode when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialEpisode();
    });
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    // Reset system UI when leaving
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  void _loadInitialEpisode() async {
    final episode = await ref.read(episodeProvider(widget.episodeId).future);
    if (episode != null && mounted) {
      ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).loadEpisode(episode);
    }
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    
    if (_isControlsVisible) {
      _controlsAnimationController.forward();
      _startControlsTimer();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isControlsVisible) {
        final playerState = ref.read(videoPlayerNotifierProvider(widget.dramaId));
        if (playerState.isPlaying && !_isFullscreen) {
          setState(() {
            _isControlsVisible = false;
          });
          _controlsAnimationController.reverse();
        }
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    
    ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).toggleFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final dramaAsync = ref.watch(dramaProvider(widget.dramaId));
    final episodeAsync = ref.watch(episodeProvider(widget.episodeId));
    final playerState = ref.watch(videoPlayerNotifierProvider(widget.dramaId));

    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          _toggleFullscreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: dramaAsync.when(
            data: (drama) => episodeAsync.when(
              data: (episode) => _buildPlayerScreen(modernTheme, drama, episode, playerState),
              loading: () => _buildLoading(),
              error: (error, stack) => _buildError('Failed to load episode', error.toString()),
            ),
            loading: () => _buildLoading(),
            error: (error, stack) => _buildError('Failed to load drama', error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerScreen(
    ModernThemeExtension modernTheme,
    DramaModel? drama,
    EpisodeModel? episode,
    VideoPlayerState playerState,
  ) {
    if (drama == null || episode == null) {
      return _buildError('Content not found', 'The requested episode is not available.');
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Video player area
          Container(
            width: double.infinity,
            height: _isFullscreen ? double.infinity : 250,
            color: Colors.black,
            child: _buildVideoPlayer(episode, playerState),
          ),
          
          // Controls overlay
          AnimatedBuilder(
            animation: _controlsAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _controlsAnimation.value,
                child: _buildControlsOverlay(modernTheme, drama, episode, playerState),
              );
            },
          ),
          
          // Episode info and list (only in portrait mode)
          if (!_isFullscreen)
            Positioned(
              top: 250,
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildEpisodeInfo(modernTheme, drama, episode),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(EpisodeModel episode, VideoPlayerState playerState) {
    if (playerState.error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Playback Error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                playerState.error!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).clearError(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (playerState.isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFFE2C55),
              ),
              SizedBox(height: 16),
              Text(
                'Loading episode...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Real video player widget
    if (playerState.controller != null && playerState.isInitialized) {
      return Stack(
        children: [
          // Video player
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: playerState.controller!.value.size.width,
                height: playerState.controller!.value.size.height,
                child: VideoPlayer(playerState.controller!),
              ),
            ),
          ),
          
          // Play/Pause button overlay (only when paused)
          if (!playerState.isPlaying && !playerState.isBuffering)
            Center(
              child: GestureDetector(
                onTap: () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).togglePlayPause(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          
          // Buffering indicator
          if (playerState.isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFE2C55),
              ),
            ),
        ],
      );
    }

    // Fallback to thumbnail while video loads or if no controller
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video thumbnail
          if (episode.thumbnailUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
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
              ),
            ),
          
          // Play button overlay
          Center(
            child: GestureDetector(
              onTap: () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).togglePlayPause(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay(
    ModernThemeExtension modernTheme,
    DramaModel drama,
    EpisodeModel episode,
    VideoPlayerState playerState,
  ) {
    return Stack(
      children: [
        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drama.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        episode.displayTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: Icon(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                _buildProgressBar(playerState),
                
                const SizedBox(height: 16),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous episode
                    IconButton(
                      onPressed: playerState.hasPreviousEpisode
                          ? () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).playPreviousEpisode()
                          : null,
                      icon: Icon(
                        Icons.skip_previous,
                        color: playerState.hasPreviousEpisode ? Colors.white : Colors.white38,
                        size: 32,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Rewind 10s
                    IconButton(
                      onPressed: playerState.isInitialized
                          ? () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).seekBackward()
                          : null,
                      icon: Icon(
                        Icons.replay_10,
                        color: playerState.isInitialized ? Colors.white : Colors.white38,
                        size: 32,
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Play/Pause
                    GestureDetector(
                      onTap: () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).togglePlayPause(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE2C55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    // Forward 10s
                    IconButton(
                      onPressed: playerState.isInitialized
                          ? () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).seekForward()
                          : null,
                      icon: Icon(
                        Icons.forward_10,
                        color: playerState.isInitialized ? Colors.white : Colors.white38,
                        size: 32,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Next episode
                    IconButton(
                      onPressed: playerState.hasNextEpisode && ref.watch(canPlayNextProvider(widget.dramaId))
                          ? () => _playNextEpisode(drama, playerState.nextEpisode!)
                          : null,
                      icon: Icon(
                        Icons.skip_next,
                        color: (playerState.hasNextEpisode && ref.watch(canPlayNextProvider(widget.dramaId))) 
                            ? Colors.white 
                            : Colors.white38,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Time and settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${playerState.formattedCurrentPosition} / ${playerState.formattedTotalDuration}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    
                    Row(
                      children: [
                        // Playback speed
                        PopupMenuButton<double>(
                          icon: const Icon(
                            Icons.speed,
                            color: Colors.white,
                            size: 20,
                          ),
                          onSelected: (speed) => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).setPlaybackSpeed(speed),
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 0.5, child: Text('0.5x')),
                            PopupMenuItem(value: 0.75, child: Text('0.75x')),
                            PopupMenuItem(value: 1.0, child: Text('1x')),
                            PopupMenuItem(value: 1.25, child: Text('1.25x')),
                            PopupMenuItem(value: 1.5, child: Text('1.5x')),
                            PopupMenuItem(value: 2.0, child: Text('2x')),
                          ],
                        ),
                        
                        // Volume
                        IconButton(
                          onPressed: playerState.isInitialized
                              ? () => ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).toggleMute()
                              : null,
                          icon: Icon(
                            playerState.isMuted ? Icons.volume_off : Icons.volume_up,
                            color: playerState.isInitialized ? Colors.white : Colors.white38,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(VideoPlayerState playerState) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFE2C55),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFFFE2C55),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: playerState.isInitialized ? playerState.progressPercentage.clamp(0.0, 1.0) : 0.0,
            onChanged: playerState.isInitialized ? (value) {
              final newPosition = Duration(
                milliseconds: (value * playerState.totalDuration.inMilliseconds).round(),
              );
              ref.read(videoPlayerNotifierProvider(widget.dramaId).notifier).seekTo(newPosition);
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeInfo(
    ModernThemeExtension modernTheme,
    DramaModel drama,
    EpisodeModel episode,
  ) {
    final episodes = ref.watch(dramaEpisodesProvider(widget.dramaId));
    final isDramaUnlocked = ref.watch(isDramaUnlockedProvider(widget.dramaId));

    return Container(
      color: modernTheme.backgroundColor,
      child: Column(
        children: [
          // Episode details
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.displayTitle,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Duration: ${episode.formattedDuration}',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${episode.episodeViewCount} views',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Episodes list
          Expanded(
            child: episodes.when(
              data: (episodeList) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: episodeList.length,
                itemBuilder: (context, index) {
                  final ep = episodeList[index];
                  final canWatch = drama.canWatchEpisode(ep.episodeNumber, isDramaUnlocked);
                  final isCurrentEpisode = ep.episodeId == episode.episodeId;
                  
                  return _buildEpisodeListItem(modernTheme, drama, ep, canWatch, isCurrentEpisode);
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Failed to load episodes',
                  style: TextStyle(color: modernTheme.textSecondaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeListItem(
    ModernThemeExtension modernTheme,
    DramaModel drama,
    EpisodeModel episode,
    bool canWatch,
    bool isCurrentEpisode,
  ) {
    final hasWatched = ref.watch(currentUserProvider)?.hasWatched(episode.episodeId) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentEpisode 
            ? const Color(0xFFFE2C55).withOpacity(0.1)
            : modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentEpisode
            ? Border.all(color: const Color(0xFFFE2C55).withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: modernTheme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: episode.thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: episode.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: modernTheme.surfaceVariantColor,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.play_circle_outline,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.play_circle_outline,
                      color: modernTheme.textSecondaryColor,
                    ),
            ),
            if (hasWatched)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE2C55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          episode.displayTitle,
          style: TextStyle(
            color: isCurrentEpisode 
                ? const Color(0xFFFE2C55)
                : hasWatched 
                    ? modernTheme.textColor?.withOpacity(0.7)
                    : modernTheme.textColor,
            fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          episode.formattedDuration,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: !canWatch
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${Constants.dramaUnlockCost}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : isCurrentEpisode
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Playing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.play_arrow,
                    size: 20,
                    color: Color(0xFFFE2C55),
                  ),
        onTap: () => _playEpisode(drama, episode, canWatch),
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
            'Loading...',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(dramaProvider(widget.dramaId));
                    ref.invalidate(episodeProvider(widget.episodeId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playEpisode(DramaModel drama, EpisodeModel episode, bool canWatch) {
    if (!canWatch) {
      // Show unlock dialog
      showDialog(
        context: context,
        builder: (context) => DramaUnlockDialog(drama: drama),
      );
      return;
    }

    if (episode.episodeId != widget.episodeId) {
      // Navigate to new episode
      Navigator.pushReplacementNamed(
        context,
        Constants.episodePlayerScreen,
        arguments: {
          'dramaId': widget.dramaId,
          'episodeId': episode.episodeId,
        },
      );
    }
  }

  void _playNextEpisode(DramaModel drama, EpisodeModel nextEpisode) {
    final canWatch = drama.canWatchEpisode(
      nextEpisode.episodeNumber,
      ref.read(isDramaUnlockedProvider(widget.dramaId)),
    );
    
    _playEpisode(drama, nextEpisode, canWatch);
  }
}