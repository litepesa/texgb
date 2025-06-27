import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';
import 'package:video_player/video_player.dart';

class StatusDetailScreen extends ConsumerStatefulWidget {
  final StatusModel status;
  
  const StatusDetailScreen({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  ConsumerState<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends ConsumerState<StatusDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize video player if this is a video status
    if (widget.status.type == StatusType.video) {
      _initializeVideoPlayer();
    } else {
      // For non-video types, just set loading to false
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.network(widget.status.content);
    
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    
    setState(() {
      _isVideoInitialized = true;
      _isLoading = false;
    });
    
    _videoController!.play();
  }
  
  Future<void> _deleteStatus() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text(
          'Are you sure you want to delete this status? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              setState(() {
                _isLoading = true;
              });
              
              try {
                await ref.read(statusNotifierProvider.notifier).deleteStatus(
                  widget.status.statusId,
                );
                
                if (mounted) {
                  Navigator.pop(context); // Go back to previous screen
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting status: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteStatus,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Status content
          _buildStatusContent(modernTheme),
          
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Caption and info at bottom
          if (widget.status.caption.isNotEmpty || widget.status.type == StatusType.video)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.status.caption.isNotEmpty)
                      Text(
                        widget.status.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.status.viewCount} ${widget.status.viewCount == 1 ? 'view' : 'views'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(widget.status.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (widget.status.type == StatusType.video && _isVideoInitialized)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.white,
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white10,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          Text(
                            _formatDuration(_videoController!.value.position) +
                            ' / ' +
                            _formatDuration(_videoController!.value.duration),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatusContent(ModernThemeExtension modernTheme) {
    switch (widget.status.type) {
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: widget.status.content,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.white, size: 48),
            ),
          ),
        );
        
      case StatusType.video:
        if (_isVideoInitialized) {
          return Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          );
        } else {
          return Container(color: Colors.black);
        }
        
      case StatusType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: modernTheme.primaryColor,
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              widget.status.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
        
      case StatusType.link:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: modernTheme.surfaceColor,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_rounded,
                size: 72,
                color: modernTheme.textColor!.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  // Here you could implement opening the link in a browser
                },
                child: Text(
                  widget.status.content,
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
    }
  }
  
  String _formatTimestamp(String timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}