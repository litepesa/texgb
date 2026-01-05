// ===============================
// Status Viewer Screen
// Full-screen status viewer with swipe navigation
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/widgets/status_interactions.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final StatusGroup statusGroup;
  final int initialIndex;

  const StatusViewerScreen({
    super.key,
    required this.statusGroup,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late List<StatusModel> _statuses;
  Timer? _progressTimer;
  Timer? _autoAdvanceTimer;
  VideoPlayerController? _videoController;
  bool _isPaused = false;
  double _progress = 0.0;

  // Animation controller for progress bar
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _statuses = widget.statusGroup.activeStatuses;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );

    // Mark first status as viewed
    _markAsViewed();

    // Load current status
    _loadStatus();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _videoController?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ===============================
  // STATUS LOADING
  // ===============================

  void _loadStatus() {
    final status = _statuses[_currentIndex];

    // Reset progress
    _progress = 0.0;
    _isPaused = false;

    // Cancel existing timers
    _progressTimer?.cancel();
    _autoAdvanceTimer?.cancel();

    if (status.mediaType.isVideo) {
      _loadVideo(status);
    } else {
      _startProgress(status.displayDuration);
    }
  }

  void _loadVideo(StatusModel status) async {
    // Dispose previous controller
    await _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(status.mediaUrl!),
    );

    try {
      await _videoController!.initialize();

      if (!mounted) return;

      setState(() {});

      // Start playing
      await _videoController!.play();

      // Get actual video duration
      final duration = _videoController!.value.duration.inSeconds;

      // Start progress
      _startProgress(duration);

      // Listen for video completion
      _videoController!.addListener(() {
        if (_videoController!.value.isCompleted && !_isPaused) {
          _onStatusCompleted();
        }
      });
    } catch (e) {
      print('Error loading video: $e');
      // If video fails, show for default duration
      _startProgress(5);
    }
  }

  void _startProgress(int durationSeconds) {
    const updateInterval = Duration(milliseconds: 50);
    final incrementPerTick = 1 / (durationSeconds * (1000 / 50));

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (_isPaused) return;

      setState(() {
        _progress += incrementPerTick;

        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _onStatusCompleted();
        }
      });
    });
  }

  void _onStatusCompleted() {
    if (_currentIndex < _statuses.length - 1) {
      // Move to next status
      _goToNext();
    } else {
      // All statuses completed, close viewer
      context.pop();
    }
  }

  // ===============================
  // NAVIGATION
  // ===============================

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _markAsViewed();
      _loadStatus();
    } else {
      // Already at first status, close viewer
      context.pop();
    }
  }

  void _goToNext() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markAsViewed();
      _loadStatus();
    } else {
      // Already at last status, close viewer
      context.pop();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_videoController != null) {
      if (_isPaused) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _markAsViewed() {
    final status = _statuses[_currentIndex];
    if (!status.isViewedByMe) {
      ref.read(statusFeedProvider.notifier).viewStatus(status.id);
    }
  }

  // ===============================
  // BUILD
  // ===============================

  @override
  Widget build(BuildContext context) {
    final status = _statuses[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _handleTap(details, context),
        onLongPress: _togglePause,
        onLongPressEnd: (_) {
          if (_isPaused) _togglePause();
        },
        child: Stack(
          children: [
            // Status content (background)
            _buildStatusContent(status),

            // Dark overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),

            // Progress bars at top
            _buildProgressBars(),

            // User info at top
            _buildUserInfo(status),

            // Interaction buttons on right
            Positioned(
              right: 16,
              bottom: 100,
              child: StatusInteractions(
                status: status,
                isMyStatus: widget.statusGroup.isMyStatus,
              ),
            ),

            // View count at bottom (privacy: only count, not viewer names)
            if (widget.statusGroup.isMyStatus) _buildViewCount(status),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    if (status.mediaType.isVideo) {
      return _buildVideoContent();
    } else if (status.mediaType.isImage) {
      return _buildImageContent(status);
    } else {
      return _buildTextContent(status);
    }
  }

  Widget _buildVideoContent() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildImageContent(StatusModel status) {
    return Center(
      child: CachedNetworkImage(
        imageUrl: status.mediaUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(StatusModel status) {
    return Container(
      decoration: BoxDecoration(
        gradient: status.textBackground != null
            ? LinearGradient(
                colors: status.textBackground!.colors
                    .map((hex) => _hexToColor(hex))
                    .toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            status.content ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 60, // Space for close button
      child: Row(
        children: List.generate(_statuses.length, (index) {
          double progress;
          if (index < _currentIndex) {
            progress = 1.0; // Completed
          } else if (index == _currentIndex) {
            progress = _progress; // Current
          } else {
            progress = 0.0; // Not started
          }

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserInfo(StatusModel status) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 24,
      left: 16,
      right: 80,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: CachedNetworkImageProvider(status.userAvatar),
          ),
          const SizedBox(width: 12),

          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  StatusTimeService.formatStatusTime(status.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewCount(StatusModel status) {
    return Positioned(
      bottom: 40,
      left: 16,
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            '${status.viewsCount} ${status.viewsCount == 1 ? 'view' : 'views'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      // Tapped left third - go to previous
      _goToPrevious();
    } else if (tapPosition > screenWidth * 2 / 3) {
      // Tapped right third - go to next
      _goToNext();
    }
    // Middle third - do nothing (reserved for interactions)
  }
}

// Helper function to convert hex color string to Color
Color _hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}
