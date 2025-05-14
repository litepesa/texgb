import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/status_progress_bar.dart';
import 'package:video_player/video_player.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final UserStatusSummary userStatus;
  final int initialStatusIndex;

  const StatusViewerScreen({
    Key? key,
    required this.userStatus,
    this.initialStatusIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _isPaused = false;
  bool _isTapped = false;
  int _currentIndex = 0;
  
  // Duration for each status view
  final Duration _statusDuration = const Duration(seconds: 5); 
  // Duration for videos will be the video length itself

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialStatusIndex;
    
    // Set up the progress controller for status progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: _statusDuration,
    );
    
    // Initialize the first status
    _initializeStatus();
    
    // Mark status as viewed through the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statusNotifierProvider.notifier).viewStatus(
        widget.userStatus, 
        _currentIndex
      );
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeStatus() {
    setState(() {
      _isLoading = true;
      _isPaused = false;
    });
    
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    
    // Reset progress controller
    _progressController.reset();
    
    // Handle different status types
    if (currentStatus.type == StatusType.video) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(currentStatus.content)
        ..initialize().then((_) {
          setState(() {
            _isLoading = false;
          });
          
          // Set progress controller duration to match video duration
          _progressController.duration = _videoController!.value.duration;
          
          // Start playing the video
          _videoController!.play();
          _progressController.forward();
          
          // When video ends, go to next status
          _videoController!.addListener(() {
            if (_videoController!.value.position >= _videoController!.value.duration) {
              _goToNextStatus();
            }
          });
        });
    } else {
      // For non-video types, just start the progress controller
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _isLoading = false;
        });
        _progressController.forward().then((_) {
          if (mounted && !_isPaused) {
            _goToNextStatus();
          }
        });
      });
    }
  }

  void _goToNextStatus() {
    if (_currentIndex < widget.userStatus.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializeStatus();
      
      // Mark new status as viewed
      ref.read(statusNotifierProvider.notifier).viewStatus(
        widget.userStatus, 
        _currentIndex
      );
    } else {
      // We've reached the end of this user's statuses
      Navigator.pop(context);
    }
  }

  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializeStatus();
    } else {
      // We're already at the first status, close if user presses back
      Navigator.pop(context);
    }
  }

  void _pauseStatus() {
    if (_isPaused) return;
    _isPaused = true;
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStatus() {
    if (!_isPaused) return;
    _isPaused = false;
    _progressController.forward();
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) {
          _pauseStatus();
          setState(() => _isTapped = true);
        },
        onTapUp: (_) {
          _resumeStatus();
          setState(() => _isTapped = false);
        },
        onTapCancel: () {
          _resumeStatus();
          setState(() => _isTapped = false);
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swipe right (previous)
            _goToPreviousStatus();
          } else if (details.primaryVelocity! < 0) {
            // Swipe left (next)
            _goToNextStatus();
          }
        },
        onLongPress: () {
          // Show additional info or options on long press
          _showStatusInfoDialog(currentStatus);
        },
        child: Stack(
          children: [
            // Status content
            _buildStatusContent(currentStatus),
            
            // Top bar with progress indicators
            SafeArea(
              child: Column(
                children: [
                  // Progress bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      children: List.generate(
                        widget.userStatus.statuses.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: StatusProgressBar(
                              controller: index == _currentIndex ? _progressController : null,
                              isPaused: _isPaused,
                              isActive: index == _currentIndex,
                              isCompleted: index < _currentIndex,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // User info bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(widget.userStatus.userImage),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userStatus.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTimestamp(currentStatus.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            
            // Caption text at bottom
            if (currentStatus.caption.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16.0, 
                    right: 16.0, 
                    top: 16.0, 
                    bottom: MediaQuery.of(context).padding.bottom + 16.0,
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
                  child: Text(
                    currentStatus.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            
            // Left/right navigation areas
            Row(
              children: [
                // Left third of screen for previous
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _goToPreviousStatus(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Middle third - no action
                const Expanded(
                  flex: 1,
                  child: SizedBox.expand(),
                ),
                // Right third of screen for next
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _goToNextStatus(),
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    switch (status.type) {
      case StatusType.image:
        return Container(
          color: Colors.black,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: status.content,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(color: Colors.black),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
          ),
        );
        
      case StatusType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              if (_isPaused)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
            ],
          );
        } else {
          return Container(color: Colors.black);
        }
        
      case StatusType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              status.content,
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
          color: Colors.black87,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                status.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  void _showStatusInfoDialog(StatusModel status) {
    // Pause the status while dialog is showing
    _pauseStatus();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Status Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Posted by: ${status.userName}"),
            const SizedBox(height: 8),
            Text("Type: ${status.type.displayName}"),
            const SizedBox(height: 8),
            Text("Views: ${status.viewCount}"),
            const SizedBox(height: 8),
            Text("Posted: ${_formatTimestamp(status.createdAt)}"),
            const SizedBox(height: 8),
            Text("Expires: ${_formatTimestamp(status.expiresAt)}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeStatus();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
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
}