// lib/features/dramas/screens/episode_feed_screen.dart - ENHANCED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/widgets/drama_unlock_dialog.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class EpisodeFeedScreen extends ConsumerStatefulWidget {
  final String dramaId;
  final String? initialEpisodeId;
  final int? initialEpisodeNumber;

  const EpisodeFeedScreen({
    super.key,
    required this.dramaId,
    this.initialEpisodeId,
    this.initialEpisodeNumber,
  });

  @override
  ConsumerState<EpisodeFeedScreen> createState() => _EpisodeFeedScreenState();
}

class _EpisodeFeedScreenState extends ConsumerState<EpisodeFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<int, VideoPlayerController?> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Map<int, bool> _episodeCompleted = {};
  bool _isAutoPlaying = false;
  DramaModel? _drama;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Enable wakelock to prevent screen from sleeping during video playback
    WakelockPlus.enable();
    
    // Listen for unlock success messages to refresh video access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupUnlockListener();
      _findInitialEpisodeIndex();
    });
  }

  void _setupUnlockListener() {
    // Listen to unlock success to refresh episode access immediately
    ref.listenManual(dramaActionsProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage!.contains('unlocked')) {
        // Drama was unlocked - refresh current episode and allow access to all episodes
        setState(() {
          // This will trigger a rebuild and re-check episode access permissions
        });
        
        // If current episode was locked, try to initialize its video
        final currentEpisodeNumber = _currentIndex + 1;
        final canWatch = ref.read(canWatchDramaEpisodeEnhancedProvider(widget.dramaId, currentEpisodeNumber));
        if (canWatch && _videoControllers[currentEpisodeNumber] == null) {
          _initializeVideoController(currentEpisodeNumber);
        }
        
        showSnackBar(context, 'All episodes are now available!');
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _disposeAllVideoControllers();
    _pageController.dispose();
    super.dispose();
  }

  void _findInitialEpisodeIndex() {
    int initialIndex = 0;
    
    if (widget.initialEpisodeNumber != null) {
      initialIndex = (widget.initialEpisodeNumber! - 1).clamp(0, 999);
    } else if (widget.initialEpisodeId != null) {
      final parts = widget.initialEpisodeId!.split('_');
      if (parts.length >= 3) {
        final episodeNum = int.tryParse(parts.last);
        if (episodeNum != null) {
          initialIndex = (episodeNum - 1).clamp(0, 999);
        }
      }
    }
    
    if (initialIndex > 0 && mounted) {
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

  void _initializeVideoController(int episodeNumber) {
    if (_videoControllers[episodeNumber] != null || _drama == null) return;

    final videoUrl = _drama!.getEpisodeVideo(episodeNumber);
    if (videoUrl == null || videoUrl.isEmpty) {
      const fallbackUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
      final controller = VideoPlayerController.networkUrl(Uri.parse(fallbackUrl));
      _videoControllers[episodeNumber] = controller;
    } else {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[episodeNumber] = controller;
    }

    final controller = _videoControllers[episodeNumber]!;

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _videoInitialized[episodeNumber] = true;
          _episodeCompleted[episodeNumber] = false;
        });
        
        if (episodeNumber == (_currentIndex + 1)) {
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

  void _onPageChanged(int index) {
    final oldEpisodeNumber = _currentIndex + 1;
    final newEpisodeNumber = index + 1;
    
    setState(() {
      _currentIndex = index;
      _isAutoPlaying = false;
    });

    final oldController = _videoControllers[oldEpisodeNumber];
    if (oldController != null) {
      oldController.pause();
      oldController.removeListener(_videoProgressListener);
    }

    final newController = _videoControllers[newEpisodeNumber];
    if (newController != null && _videoInitialized[newEpisodeNumber] == true) {
      newController.play();
      _episodeCompleted[newEpisodeNumber] = false;
      newController.addListener(_videoProgressListener);
    }

    _markEpisodeWatched(newEpisodeNumber);
  }

  void _videoProgressListener() {
    final currentEpisodeNumber = _currentIndex + 1;
    final controller = _videoControllers[currentEpisodeNumber];
    if (controller == null || !mounted) return;

    final position = controller.value.position;
    final duration = controller.value.duration;
    
    if (duration.inMilliseconds > 0) {
      final remainingTime = duration.inMilliseconds - position.inMilliseconds;
      final isCompleted = remainingTime <= 50;
      
      if (isCompleted && 
          !(_episodeCompleted[currentEpisodeNumber] ?? false) && 
          !_isAutoPlaying) {
        
        _episodeCompleted[currentEpisodeNumber] = true;
        _handleVideoCompleted();
      }
    }

    setState(() {});
  }

  void _handleVideoCompleted() async {
    if (_isAutoPlaying || _drama == null) return;
    _isAutoPlaying = true;

    try {
      final currentEpisodeNumber = _currentIndex + 1;
      
      if (currentEpisodeNumber < _drama!.totalEpisodes) {
        final nextEpisodeNumber = currentEpisodeNumber + 1;
        
        // Use enhanced provider to check if user can watch next episode
        final canWatchNext = ref.read(canWatchDramaEpisodeEnhancedProvider(widget.dramaId, nextEpisodeNumber));
        
        if (canWatchNext) {
          final currentController = _videoControllers[currentEpisodeNumber];
          currentController?.pause();
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted && _isAutoPlaying) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        } else {
          final currentController = _videoControllers[currentEpisodeNumber];
          if (currentController != null) {
            await currentController.seekTo(Duration.zero);
            currentController.play();
          }
          _isAutoPlaying = false;
        }
      } else {
        final currentController = _videoControllers[currentEpisodeNumber];
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
    ref.read(dramaActionsProvider.notifier).markEpisodeWatched(
      'episode_${widget.dramaId}_$episodeNumber',
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
          
          _drama = drama;
          
          if (drama.totalEpisodes == 0) {
            return _buildError('No episodes', 'This drama has no episodes yet.');
          }
          
          return _buildFeedScreen(drama);
        },
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError('Failed to load drama', error.toString()),
      ),
    );
  }

  Widget _buildFeedScreen(DramaModel drama) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: drama.totalEpisodes,
      itemBuilder: (context, index) {
        final episodeNumber = index + 1;
        
        // Use enhanced provider for real-time unlock status
        final canWatch = ref.watch(canWatchDramaEpisodeEnhancedProvider(drama.dramaId, episodeNumber));
        
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
        Positioned.fill(
          child: canWatch && controller != null && isInitialized
              ? _buildVideoPlayer(controller)
              : _buildVideoPlaceholder(drama, episodeNumber),
        ),

        if (!canWatch)
          _buildEnhancedLockOverlay(drama, episodeNumber),

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

  Widget _buildVideoPlaceholder(DramaModel drama, int episodeNumber) {
    return Container(
      color: Colors.black,
      child: drama.bannerImage.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: drama.bannerImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultPlaceholder(episodeNumber),
                ),
                Container(color: Colors.black.withOpacity(0.4)),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFE2C55),
                            width: 2,
                          ),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Episode $episodeNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildDefaultPlaceholder(episodeNumber),
    );
  }

  Widget _buildDefaultPlaceholder(int episodeNumber) {
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
              'Episode $episodeNumber',
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

  // Enhanced lock overlay with real-time unlock button updates
  Widget _buildEnhancedLockOverlay(DramaModel drama, int episodeNumber) {
    final coinsBalance = ref.watch(coinsBalanceProvider) ?? 0;
    final canAfford = ref.watch(canAffordDramaUnlockProvider());
    final isLoading = ref.watch(dramaActionsProvider).isLoading;

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
              'Unlock Episode $episodeNumber',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Balance: $coinsBalance coins',
              style: TextStyle(
                color: canAfford ? Colors.green.shade300 : Colors.red.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: canAfford ? () => _showUnlockDialog(drama) : null,
                      icon: Icon(canAfford ? Icons.workspace_premium : Icons.account_balance_wallet),
                      label: Text(
                        canAfford 
                            ? 'Unlock for ${Constants.dramaUnlockCost} coins'
                            : 'Insufficient coins',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? const Color(0xFFFE2C55) : Colors.grey,
                        disabledBackgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, Constants.walletScreen),
                child: const Text(
                  'Get more coins',
                  style: TextStyle(
                    color: Color(0xFFFE2C55),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUIOverlays(DramaModel drama, int episodeNumber, VideoPlayerController? controller, bool canWatch) {
    return SafeArea(
      child: Column(
        children: [
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ep $episodeNumber',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (canWatch && controller != null)
            _buildVideoControls(controller),
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
                  controller.pause();
                },
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