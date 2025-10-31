// lib/features/videos/providers/video_progress_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track current video playback progress (0.0 to 1.0)
final videoProgressProvider = StateProvider<double>((ref) => 0.0);

/// Provider to track if a video is currently playing
final isVideoPlayingProvider = StateProvider<bool>((ref) => false);
