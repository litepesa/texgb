// lib/features/dramas/providers/video_player_provider.dart
import 'dart:async';
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
class VideoPlayer extends _$VideoPlayer {
  Timer? _progressTimer;

  @override
  VideoPlayerState build(String dramaId) {
    // Load episode list when provider is initialized
    _loadEpisodeList();
    
    // Clean up timer on dispose
    ref.onDispose(() {
      _progressTimer?.cancel();
    });

    return VideoPlayerState(dramaId: dramaId);
  }

  // Load the episode list for this drama
  Future<void> _loadEpisodeList() async {
    final episodes = await ref.read(dramaEpisodesProvider(dramaId).future);
    state = state.copyWith(episodeList: episodes);
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
    );

    try {
      // In real app, initialize video player controller here
      // For now, simulate loading
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        isLoading: false,
        totalDuration: Duration(seconds: episode.videoDuration),
        currentPosition: Duration.zero,
        isCompleted: false,
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
        error: 'Failed to load episode: $e',
      );
    }
  }

  // Play/Pause controls
  void play() {
    state = state.copyWith(isPlaying: true);
    _startProgressTimer();
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
    _stopProgressTimer();
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  // Seek controls
  void seekTo(Duration position) {
    state = state.copyWith(currentPosition: position);
    // In real app, seek the actual video player here
  }

  void seekForward([Duration duration = const Duration(seconds: 10)]) {
    final newPosition = state.currentPosition + duration;
    final maxPosition = state.totalDuration;
    seekTo(newPosition > maxPosition ? maxPosition : newPosition);
  }

  void seekBackward([Duration duration = const Duration(seconds: 10)]) {
    final newPosition = state.currentPosition - duration;
    seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // Episode navigation
  Future<void> playNextEpisode() async {
    final nextEp = state.nextEpisode;
    if (nextEp != null) {
      await loadEpisode(nextEp);
      play();
    }
  }

  Future<void> playPreviousEpisode() async {
    final prevEp = state.previousEpisode;
    if (prevEp != null) {
      await loadEpisode(prevEp);
      play();
    }
  }

  // Auto-play next episode when current ends
  Future<void> _onEpisodeCompleted() async {
    state = state.copyWith(isCompleted: true, isPlaying: false);
    _stopProgressTimer();

    // Check user preferences for auto-play
    final user = ref.read(currentUserProvider);
    if (user?.preferences.autoPlay == true) {
      // Wait a moment then play next episode
      await Future.delayed(const Duration(seconds: 3));
      
      if (state.hasNextEpisode && !state.isCompleted) return; // User manually changed episode
      
      final nextEp = state.nextEpisode;
      if (nextEp != null) {
        // Check if user can watch next episode
        final canWatch = ref.read(canWatchEpisodeProvider(dramaId, nextEp.episodeNumber));
        if (canWatch) {
          await loadEpisode(nextEp);
          play();
        }
      }
    }
  }

  // Volume and playback controls
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
    // In real app, update actual player speed here
  }

  // Fullscreen controls
  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void exitFullscreen() {
    state = state.copyWith(isFullscreen: false);
  }

  // Progress timer for tracking playback
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying && !state.isBuffering) {
        final newPosition = state.currentPosition + const Duration(seconds: 1);
        
        if (newPosition >= state.totalDuration) {
          // Episode completed
          _onEpisodeCompleted();
        } else {
          state = state.copyWith(currentPosition: newPosition);
        }
      }
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
  }

  // Buffering controls (called by actual video player)
  void setBuffering(bool isBuffering) {
    state = state.copyWith(isBuffering: isBuffering);
  }

  // Error handling
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false, isPlaying: false);
    _stopProgressTimer();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Dispose and cleanup
  void dispose() {
    _stopProgressTimer();
    state = VideoPlayerState(dramaId: dramaId);
  }
}

// Convenience providers for video player UI

@riverpod
bool isVideoPlaying(IsVideoPlayingRef ref, String dramaId) {
  final player = ref.watch(videoPlayerProvider(dramaId));
  return player.isPlaying;
}

@riverpod
double videoProgress(VideoProgressRef ref, String dramaId) {
  final player = ref.watch(videoPlayerProvider(dramaId));
  return player.progressPercentage;
}

@riverpod
String currentEpisodeTitle(CurrentEpisodeTitleRef ref, String dramaId) {
  final player = ref.watch(videoPlayerProvider(dramaId));
  return player.currentEpisode?.displayTitle ?? '';
}

@riverpod
bool canPlayNext(CanPlayNextRef ref, String dramaId) {
  final player = ref.watch(videoPlayerProvider(dramaId));
  if (!player.hasNextEpisode) return false;
  
  final nextEp = player.nextEpisode;
  if (nextEp == null) return false;
  
  return ref.watch(canWatchEpisodeProvider(dramaId, nextEp.episodeNumber));
}

@riverpod
bool canPlayPrevious(CanPlayPreviousRef ref, String dramaId) {
  final player = ref.watch(videoPlayerProvider(dramaId));
  return player.hasPreviousEpisode;
}