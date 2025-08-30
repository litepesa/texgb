// lib/features/dramas/providers/video_player_provider.dart - SIMPLIFIED FOR UNIFIED MODEL
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/drama_model.dart';

part 'video_player_provider.g.dart';

// Simplified video player state - no complex episode objects
class VideoPlayerState {
  final int? currentEpisodeNumber;
  final String dramaId;
  final DramaModel? drama;
  final bool isPlaying;
  final bool isLoading;
  final bool isBuffering;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isCompleted;
  final double playbackSpeed;
  final double volume;
  final bool isMuted;
  final bool isFullscreen;
  final String? error;
  final VideoPlayerController? controller;
  final bool isInitialized;

  const VideoPlayerState({
    this.currentEpisodeNumber,
    required this.dramaId,
    this.drama,
    this.isPlaying = false,
    this.isLoading = false,
    this.isBuffering = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isCompleted = false,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.isFullscreen = false,
    this.error,
    this.controller,
    this.isInitialized = false,
  });

  VideoPlayerState copyWith({
    int? currentEpisodeNumber,
    String? dramaId,
    DramaModel? drama,
    bool? isPlaying,
    bool? isLoading,
    bool? isBuffering,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isCompleted,
    double? playbackSpeed,
    double? volume,
    bool? isMuted,
    bool? isFullscreen,
    String? error,
    VideoPlayerController? controller,
    bool? isInitialized,
  }) {
    return VideoPlayerState(
      currentEpisodeNumber: currentEpisodeNumber ?? this.currentEpisodeNumber,
      dramaId: dramaId ?? this.dramaId,
      drama: drama ?? this.drama,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      isBuffering: isBuffering ?? this.isBuffering,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      error: error,
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // Simplified helper getters
  bool get hasNextEpisode {
    if (currentEpisodeNumber == null || drama == null) return false;
    return currentEpisodeNumber! < drama!.totalEpisodes;
  }

  bool get hasPreviousEpisode {
    if (currentEpisodeNumber == null) return false;
    return currentEpisodeNumber! > 1;
  }

  int? get nextEpisodeNumber {
    if (currentEpisodeNumber == null || drama == null) return null;
    final next = currentEpisodeNumber! + 1;
    return next <= drama!.totalEpisodes ? next : null;
  }

  int? get previousEpisodeNumber {
    if (currentEpisodeNumber == null) return null;
    final previous = currentEpisodeNumber! - 1;
    return previous >= 1 ? previous : null;
  }

  double get progressPercentage {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  String get formattedCurrentPosition => _formatDuration(currentPosition);
  String get formattedTotalDuration => _formatDuration(totalDuration);

  String get currentEpisodeTitle {
    if (currentEpisodeNumber == null || drama == null) return '';
    return '${drama!.title} - Episode $currentEpisodeNumber';
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}

@riverpod
class VideoPlayerNotifier extends _$VideoPlayerNotifier {
  Timer? _progressTimer;

  @override
  VideoPlayerState build(String dramaId) {
    // Load drama data when provider is initialized
    _loadDrama();
    
    // Clean up resources on dispose
    ref.onDispose(() {
      _disposeController();
    });

    return VideoPlayerState(dramaId: dramaId);
  }

  // Load the drama data
  Future<void> _loadDrama() async {
    try {
      final drama = await ref.read(dramaProvider(dramaId).future);
      state = state.copyWith(drama: drama);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load drama: $e');
    }
  }

  // Initialize player with specific episode number (simplified)
  Future<void> loadEpisode(int episodeNumber) async {
    final drama = state.drama;
    if (drama == null) {
      state = state.copyWith(error: 'Drama not loaded');
      return;
    }

    final videoUrl = drama.getEpisodeVideo(episodeNumber);
    if (videoUrl == null || videoUrl.isEmpty) {
      state = state.copyWith(error: 'Episode $episodeNumber not available');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentEpisodeNumber: episodeNumber,
      isCompleted: false,
    );

    try {
      // Dispose previous controller if exists
      await _disposeController();

      // Create new video controller with the episode video URL
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      // Initialize the controller
      await controller.initialize();

      // Set up listeners
      controller.addListener(_onVideoPlayerUpdate);

      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        isLoading: false,
        totalDuration: controller.value.duration,
        currentPosition: Duration.zero,
        volume: controller.value.volume,
        playbackSpeed: controller.value.playbackSpeed,
      );

      // Mark episode as watched (simplified episode ID)
      await ref.read(dramaActionsProvider.notifier).markEpisodeWatched(
        'episode_${dramaId}_$episodeNumber', // Simple episode ID
        dramaId,
        episodeNumber,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: false,
        error: 'Failed to load episode $episodeNumber: $e',
      );
    }
  }

  // Video player update listener (unchanged)
  void _onVideoPlayerUpdate() {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized) return;

    final value = controller.value;
    
    state = state.copyWith(
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      currentPosition: value.position,
      totalDuration: value.duration,
      volume: value.volume,
      playbackSpeed: value.playbackSpeed,
    );

    // Check if video completed
    if (value.position >= value.duration && value.duration > Duration.zero) {
      _onEpisodeCompleted();
    }

    // Handle errors
    if (value.hasError && value.errorDescription != null) {
      state = state.copyWith(error: value.errorDescription);
    }
  }

  // Play/Pause controls (unchanged)
  Future<void> play() async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    try {
      await controller.play();
      state = state.copyWith(isPlaying: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to play: $e');
    }
  }

  Future<void> pause() async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    try {
      await controller.pause();
      state = state.copyWith(isPlaying: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  // Seek controls (unchanged)
  Future<void> seekTo(Duration position) async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    try {
      await controller.seekTo(position);
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      state = state.copyWith(error: 'Failed to seek: $e');
    }
  }

  Future<void> seekForward([Duration duration = const Duration(seconds: 10)]) async {
    final newPosition = state.currentPosition + duration;
    final maxPosition = state.totalDuration;
    await seekTo(newPosition > maxPosition ? maxPosition : newPosition);
  }

  Future<void> seekBackward([Duration duration = const Duration(seconds: 10)]) async {
    final newPosition = state.currentPosition - duration;
    await seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // Episode navigation (simplified)
  Future<void> playNextEpisode() async {
    final nextEpisodeNum = state.nextEpisodeNumber;
    if (nextEpisodeNum != null) {
      await loadEpisode(nextEpisodeNum);
      await play();
    }
  }

  Future<void> playPreviousEpisode() async {
    final prevEpisodeNum = state.previousEpisodeNumber;
    if (prevEpisodeNum != null) {
      await loadEpisode(prevEpisodeNum);
      await play();
    }
  }

  // Auto-play next episode when current ends (simplified)
  Future<void> _onEpisodeCompleted() async {
    state = state.copyWith(isCompleted: true, isPlaying: false);

    // Check user preferences for auto-play
    final user = ref.read(currentUserProvider);
    if (user?.preferences.autoPlay == true) {
      // Wait a moment then play next episode
      await Future.delayed(const Duration(seconds: 3));
      
      if (!state.isCompleted) return; // User manually changed episode
      
      final nextEpisodeNum = state.nextEpisodeNumber;
      if (nextEpisodeNum != null) {
        // Check if user can watch next episode
        final canWatch = ref.read(canWatchEpisodeProvider(dramaId, nextEpisodeNum));
        if (canWatch) {
          await loadEpisode(nextEpisodeNum);
          await play();
        }
      }
    }
  }

  // Volume and playback controls (unchanged)
  Future<void> setVolume(double volume) async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    final clampedVolume = volume.clamp(0.0, 1.0);
    
    try {
      await controller.setVolume(clampedVolume);
      state = state.copyWith(volume: clampedVolume);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set volume: $e');
    }
  }

  Future<void> toggleMute() async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    try {
      final newMutedState = !state.isMuted;
      await controller.setVolume(newMutedState ? 0.0 : state.volume);
      state = state.copyWith(isMuted: newMutedState);
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle mute: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final controller = state.controller;
    if (controller == null || !state.isInitialized) return;

    try {
      await controller.setPlaybackSpeed(speed);
      state = state.copyWith(playbackSpeed: speed);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set playback speed: $e');
    }
  }

  // Fullscreen controls (unchanged)
  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void exitFullscreen() {
    state = state.copyWith(isFullscreen: false);
  }

  // Buffering controls (unchanged)
  void setBuffering(bool isBuffering) {
    state = state.copyWith(isBuffering: isBuffering);
  }

  // Error handling (unchanged)
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false, isPlaying: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Dispose controller and cleanup (unchanged)
  Future<void> _disposeController() async {
    final controller = state.controller;
    if (controller != null) {
      controller.removeListener(_onVideoPlayerUpdate);
      await controller.dispose();
    }
    
    _progressTimer?.cancel();
    _progressTimer = null;
    
    state = state.copyWith(
      controller: null,
      isInitialized: false,
      isPlaying: false,
      currentPosition: Duration.zero,
      totalDuration: Duration.zero,
    );
  }

  // Public dispose method (unchanged)
  Future<void> dispose() async {
    await _disposeController();
    state = VideoPlayerState(dramaId: dramaId);
  }
}

// ===============================
// SIMPLIFIED CONVENIENCE PROVIDERS
// ===============================

@riverpod
bool isVideoPlaying(IsVideoPlayingRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.isPlaying;
}

@riverpod
double videoProgress(VideoProgressRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.progressPercentage;
}

@riverpod
String currentEpisodeTitle(CurrentEpisodeTitleRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.currentEpisodeTitle;
}

@riverpod
bool canPlayNext(CanPlayNextRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  if (!player.hasNextEpisode) return false;
  
  final nextEpisodeNum = player.nextEpisodeNumber;
  if (nextEpisodeNum == null) return false;
  
  return ref.watch(canWatchEpisodeProvider(dramaId, nextEpisodeNum));
}

@riverpod
bool canPlayPrevious(CanPlayPreviousRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.hasPreviousEpisode;
}

@riverpod
VideoPlayerController? videoController(VideoControllerRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.controller;
}

@riverpod
int? currentEpisodeNumber(CurrentEpisodeNumberRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  return player.currentEpisodeNumber;
}

// ===============================
// WHAT CHANGED FROM ORIGINAL:
// ===============================

/*
SIMPLIFIED FROM COMPLEX EPISODE MODEL TO SIMPLE EPISODE NUMBERS:

BEFORE:
- VideoPlayerState had EpisodeModel objects
- Complex episode list management
- Episode-specific metadata handling
- Separate episode loading logic

AFTER:
- VideoPlayerState has simple episode numbers
- Episodes are just numbered videos from drama model
- No complex episode objects or metadata
- Drama-centric video loading

BENEFITS:
- Much simpler state management
- No episode model dependencies
- Works directly with unified drama model
- Easier to maintain and debug
- Less memory usage (no complex episode objects)
*/