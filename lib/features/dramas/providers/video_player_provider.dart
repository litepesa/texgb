// lib/features/dramas/providers/video_player_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/models/episode_model.dart';

part 'video_player_provider.g.dart';

// Video player state
class VideoPlayerState {
  final EpisodeModel? currentEpisode;
  final String dramaId;
  final List<EpisodeModel> episodeList;
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
    this.currentEpisode,
    required this.dramaId,
    this.episodeList = const [],
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
    EpisodeModel? currentEpisode,
    String? dramaId,
    List<EpisodeModel>? episodeList,
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
      currentEpisode: currentEpisode ?? this.currentEpisode,
      dramaId: dramaId ?? this.dramaId,
      episodeList: episodeList ?? this.episodeList,
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

  // Helper getters
  bool get hasNextEpisode {
    if (currentEpisode == null) return false;
    return episodeList.any((ep) => ep.episodeNumber > currentEpisode!.episodeNumber);
  }

  bool get hasPreviousEpisode {
    if (currentEpisode == null) return false;
    return episodeList.any((ep) => ep.episodeNumber < currentEpisode!.episodeNumber);
  }

  EpisodeModel? get nextEpisode {
    if (currentEpisode == null) return null;
    try {
      return episodeList.firstWhere(
        (ep) => ep.episodeNumber == currentEpisode!.episodeNumber + 1
      );
    } catch (e) {
      return null;
    }
  }

  EpisodeModel? get previousEpisode {
    if (currentEpisode == null) return null;
    try {
      return episodeList.firstWhere(
        (ep) => ep.episodeNumber == currentEpisode!.episodeNumber - 1
      );
    } catch (e) {
      return null;
    }
  }

  double get progressPercentage {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  String get formattedCurrentPosition {
    return _formatDuration(currentPosition);
  }

  String get formattedTotalDuration {
    return _formatDuration(totalDuration);
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
    // Load episode list when provider is initialized
    _loadEpisodeList();
    
    // Clean up resources on dispose
    ref.onDispose(() {
      _disposeController();
    });

    return VideoPlayerState(dramaId: dramaId);
  }

  // Load the episode list for this drama
  Future<void> _loadEpisodeList() async {
    try {
      final episodes = await ref.read(dramaEpisodesProvider(dramaId).future);
      state = state.copyWith(episodeList: episodes);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load episodes: $e');
    }
  }

  // Initialize player with specific episode
  Future<void> loadEpisode(EpisodeModel episode) async {
    if (!episode.isWatchable) {
      state = state.copyWith(error: 'Episode video not available');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentEpisode: episode,
      isCompleted: false,
    );

    try {
      // Dispose previous controller if exists
      await _disposeController();

      // Create new video controller with the episode video URL
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(episode.videoUrl),
      );

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

      // Mark episode as watched
      await ref.read(dramaActionsProvider.notifier).markEpisodeWatched(
        episode.episodeId,
        dramaId,
        episode.episodeNumber,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: false,
        error: 'Failed to load episode: $e',
      );
    }
  }

  // Video player update listener
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

  // Play/Pause controls
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

  // Seek controls
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

  // Episode navigation
  Future<void> playNextEpisode() async {
    final nextEp = state.nextEpisode;
    if (nextEp != null) {
      await loadEpisode(nextEp);
      await play();
    }
  }

  Future<void> playPreviousEpisode() async {
    final prevEp = state.previousEpisode;
    if (prevEp != null) {
      await loadEpisode(prevEp);
      await play();
    }
  }

  // Auto-play next episode when current ends
  Future<void> _onEpisodeCompleted() async {
    state = state.copyWith(isCompleted: true, isPlaying: false);

    // Check user preferences for auto-play
    final user = ref.read(currentUserProvider);
    if (user?.preferences.autoPlay == true) {
      // Wait a moment then play next episode
      await Future.delayed(const Duration(seconds: 3));
      
      if (!state.isCompleted) return; // User manually changed episode
      
      final nextEp = state.nextEpisode;
      if (nextEp != null) {
        // Check if user can watch next episode
        final canWatch = ref.read(canWatchEpisodeProvider(dramaId, nextEp.episodeNumber));
        if (canWatch) {
          await loadEpisode(nextEp);
          await play();
        }
      }
    }
  }

  // Volume and playback controls
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

  // Fullscreen controls
  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void exitFullscreen() {
    state = state.copyWith(isFullscreen: false);
  }

  // Buffering controls (called by video player)
  void setBuffering(bool isBuffering) {
    state = state.copyWith(isBuffering: isBuffering);
  }

  // Error handling
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false, isPlaying: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Dispose controller and cleanup
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

  // Public dispose method
  Future<void> dispose() async {
    await _disposeController();
    state = VideoPlayerState(dramaId: dramaId);
  }
}

// Convenience providers for video player UI
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
  return player.currentEpisode?.displayTitle ?? '';
}

@riverpod
bool canPlayNext(CanPlayNextRef ref, String dramaId) {
  final player = ref.watch(videoPlayerNotifierProvider(dramaId));
  if (!player.hasNextEpisode) return false;
  
  final nextEp = player.nextEpisode;
  if (nextEp == null) return false;
  
  return ref.watch(canWatchEpisodeProvider(dramaId, nextEp.episodeNumber));
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