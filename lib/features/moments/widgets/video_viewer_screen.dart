// ===============================
// Video Viewer Screen
// Full-screen video player with dark theme
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/core/router/route_paths.dart';

class VideoViewerScreen extends ConsumerStatefulWidget {
  final String videoUrl;
  final MomentModel moment;

  const VideoViewerScreen({
    super.key,
    required this.videoUrl,
    required this.moment,
  });

  @override
  ConsumerState<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends ConsumerState<VideoViewerScreen> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Set dark theme status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Restore original status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Auto-play
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });

      // Listen for completion
      _controller!.addListener(() {
        if (_controller!.value.position >= _controller!.value.duration) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _handleLike() async {
    try {
      await ref.read(momentsFeedProvider.notifier).toggleLike(
            widget.moment.id,
            widget.moment.isLikedByMe,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like: $e'),
            backgroundColor: MomentsTheme.darkBackground,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomentsTheme.darkBackground,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragEnd: (details) {
          // Swipe down to close
          if (details.primaryVelocity! > 300) {
            context.pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            Center(
              child: _buildVideoPlayer(),
            ),

            // Top bar (overlay)
            if (_showControls) _buildTopBar(),

            // Bottom controls (overlay)
            if (_showControls) _buildBottomControls(),

            // Center play/pause button
            if (!_isPlaying && _isInitialized) _buildCenterPlayButton(),

            // Loading indicator
            if (!_isInitialized && _errorMessage == null)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),

            // Error message
            if (_errorMessage != null) _buildErrorWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_errorMessage != null) {
      return const SizedBox.shrink();
    }

    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),

            const SizedBox(width: 8),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.moment.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.moment.content != null &&
                      widget.moment.content!.isNotEmpty)
                    Text(
                      widget.moment.content!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // More options
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showMoreOptions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Like and comment buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Like button
                _buildActionButton(
                  icon: widget.moment.isLikedByMe
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: widget.moment.likesCount > 0
                      ? '${widget.moment.likesCount}'
                      : 'Like',
                  color: widget.moment.isLikedByMe
                      ? MomentsTheme.likeRed
                      : Colors.white,
                  onPressed: _handleLike,
                ),

                // Comment button
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: widget.moment.commentsCount > 0
                      ? '${widget.moment.commentsCount}'
                      : 'Comment',
                  color: Colors.white,
                  onPressed: () {
                    context.push(
                        '${RoutePaths.userProfile}/${widget.moment.userId}');
                  },
                ),

                // Share button
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.white,
                  onPressed: _shareVideo,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Video progress bar
            if (_isInitialized) _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
            thumbColor: Colors.white,
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
          ),
          child: Slider(
            value: _controller!.value.position.inMilliseconds.toDouble(),
            min: 0.0,
            max: _controller!.value.duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              _controller!.seekTo(Duration(milliseconds: value.toInt()));
            },
          ),
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller!.value.position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MomentsTheme.darkBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Copy link',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                _copyVideoLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Download video',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                _downloadVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.white),
              title:
                  const Text('Report', style: TextStyle(color: Colors.white)),
              onTap: () {
                context.pop();
                _reportVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Share video
  Future<void> _shareVideo() async {
    try {
      final text = '''
Check out this video from ${widget.moment.userName}!

${widget.moment.content ?? ''}

View on WemaShop: wemachat://moment/${widget.moment.id}
      '''
          .trim();

      await Share.share(text, subject: 'Video from ${widget.moment.userName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Copy video link
  void _copyVideoLink() {
    final link = 'wemachat://moment/${widget.moment.id}';
    Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  // Download video
  Future<void> _downloadVideo() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading video...'),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Download video
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'moment_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${tempDir.path}/$fileName';

      await Dio().download(
        widget.videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
      );

      // Save to gallery
      await Gal.putVideo(filePath);

      // Clean up temp file
      await File(filePath).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Report video
  Future<void> _reportVideo() async {
    final reasons = [
      'Spam or misleading',
      'Harassment or hate speech',
      'Violence or dangerous content',
      'Nudity or sexual content',
      'False information',
      'Other',
    ];

    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Video'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this video?'),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() => selectedReason = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && selectedReason != null && mounted) {
      // In a real app, send report to backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video reported: $selectedReason'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }
}
