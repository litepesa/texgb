import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final String contactUid;
  final String initialStatusId;

  const StatusViewerScreen({
    Key? key,
    required this.contactUid,
    required this.initialStatusId,
  }) : super(key: key);

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final TextEditingController _replyController = TextEditingController();
  
  int _currentIndex = 0;
  bool _isReplyInputVisible = false;
  bool _isPaused = false;
  bool _isInitialized = false;
  
  // Progress segments
  List<double> _progressSegments = [];
  double _totalProgress = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Default duration
    );
    
    _progressController.addListener(() {
      setState(() {
        _totalProgress = _progressController.value;
      });
    });
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
    
    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [], // Hide all system overlays
    );
    
    // Initialize after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewer();
    });
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    _replyController.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    super.dispose();
  }
  
  Future<void> _initializeViewer() async {
    final statusNotifier = ref.read(statusProvider.notifier);
    final statuses = statusNotifier.getStatusesForUser(widget.contactUid);
    
    // Find the initial index if provided
    if (widget.initialStatusId.isNotEmpty) {
      final initialIndex = statuses.indexWhere((s) => s.statusId == widget.initialStatusId);
      if (initialIndex != -1) {
        _currentIndex = initialIndex;
      }
    }
    
    // Setup progress segments
    _progressSegments = List.generate(statuses.length, (_) => 0.0);
    
    // Load current status
    if (statuses.isNotEmpty) {
      _loadStatus(statuses[_currentIndex]);
    }
    
    setState(() {
      _isInitialized = true;
    });
  }
  
  Future<void> _loadStatus(StatusModel status) async {
    // Mark as seen
    ref.read(statusProvider.notifier).markStatusAsSeen(status.statusId);
    
    // Reset progress controller
    _progressController.reset();
    
    // Dispose previous video controllers
    await _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    
    // Set appropriate duration based on media type
    Duration statusDuration = const Duration(seconds: 5);
    
    // Handle different media types
    if (status.type == StatusType.video) {
      await _initializeVideoPlayer(status.content);
      
      if (_videoPlayerController != null) {
        final videoDuration = _videoPlayerController!.value.duration;
        // Cap video status duration to 30 seconds max
        statusDuration = videoDuration.inSeconds > 30
            ? const Duration(seconds: 30)
            : videoDuration;
      }
    }
    
    // Update progress controller duration
    _progressController.duration = statusDuration;
    
    // Start progress
    if (!_isPaused) {
      _progressController.forward();
    }
  }
  
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
      
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }
  
  void _nextStatus() {
    final statusNotifier = ref.read(statusProvider.notifier);
    final statuses = statusNotifier.getStatusesForUser(widget.contactUid);
    
    // Save progress for current status
    _progressSegments[_currentIndex] = 1.0;
    
    // Move to next status
    if (_currentIndex < statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStatus(statuses[_currentIndex]);
    } else {
      // No more statuses, close the viewer
      Navigator.pop(context);
    }
  }
  
  void _previousStatus() {
    final statusNotifier = ref.read(statusProvider.notifier);
    final statuses = statusNotifier.getStatusesForUser(widget.contactUid);
    
    // Save progress for current status
    _progressSegments[_currentIndex] = 0.0;
    
    // Move to previous status
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStatus(statuses[_currentIndex]);
    }
  }
  
  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      
      if (_isPaused) {
        _progressController.stop();
        _videoPlayerController?.pause();
      } else {
        _progressController.forward();
        _videoPlayerController?.play();
      }
    });
  }
  
  void _toggleReplyInput() {
    setState(() {
      _isReplyInputVisible = !_isReplyInputVisible;
      
      // Pause when reply input is shown
      if (_isReplyInputVisible) {
        _isPaused = true;
        _progressController.stop();
        _videoPlayerController?.pause();
      } else {
        _isPaused = false;
        _progressController.forward();
        _videoPlayerController?.play();
      }
    });
  }
  
  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    
    final statusNotifier = ref.read(statusProvider.notifier);
    final statuses = statusNotifier.getStatusesForUser(widget.contactUid);
    
    if (_currentIndex < statuses.length) {
      try {
        await statusNotifier.replyToStatus(
          status: statuses[_currentIndex],
          message: _replyController.text.trim(),
        );
        
        // Clear input and hide keyboard
        _replyController.clear();
        FocusScope.of(context).unfocus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent')),
          );
        }
        
        // Close reply input
        setState(() {
          _isReplyInputVisible = false;
          _isPaused = false;
          _progressController.forward();
          _videoPlayerController?.play();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending reply: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Consumer(
              builder: (context, ref, child) {
                final statusNotifier = ref.watch(statusProvider.notifier);
                final statuses = statusNotifier.getStatusesForUser(widget.contactUid);
                
                if (statuses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No statuses available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                
                final currentStatus = statuses[_currentIndex];
                
                return Stack(
                  children: [
                    // Status content
                    GestureDetector(
                      onTapDown: (details) {
                        // Determine tap position (left/right side)
                        final screenWidth = MediaQuery.of(context).size.width;
                        if (details.globalPosition.dx < screenWidth / 2) {
                          // Left side - go to previous
                          _previousStatus();
                        } else {
                          // Right side - go to next
                          _nextStatus();
                        }
                      },
                      onLongPressStart: (_) {
                        // Hold to pause
                        if (!_isPaused) _togglePlayPause();
                      },
                      onLongPressEnd: (_) {
                        // Release to resume
                        if (_isPaused) _togglePlayPause();
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: _buildStatusContent(currentStatus),
                      ),
                    ),
                    
                    // Progress bar
                    Positioned(
                      top: MediaQuery.of(context).padding.top,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: List.generate(
                          statuses.length,
                          (index) {
                            final double segmentProgress = index == _currentIndex 
                                ? _totalProgress 
                                : _progressSegments[index];
                                
                            return Expanded(
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: segmentProgress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // User info header
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey.withOpacity(0.5),
                            radius: 20,
                            backgroundImage: currentStatus.userImage.isNotEmpty
                                ? CachedNetworkImageProvider(currentStatus.userImage)
                                : null,
                            child: currentStatus.userImage.isEmpty
                                ? Text(
                                    currentStatus.username.isNotEmpty
                                        ? currentStatus.username.substring(0, 1)
                                        : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentStatus.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentStatus.timeAgo,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Caption (if any)
                    if (currentStatus.caption != null && currentStatus.caption!.isNotEmpty)
                      Positioned(
                        bottom: _isReplyInputVisible
                            ? MediaQuery.of(context).viewInsets.bottom + 80
                            : 60,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentStatus.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    
                    // Reply bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildReplyBar(currentStatus),
                    ),
                  ],
                );
              },
            ),
    );
  }
  
  Widget _buildStatusContent(StatusModel status) {
    switch (status.type) {
      case StatusType.text:
        return Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade600,
              ],
            ),
          ),
          child: Text(
            status.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
        
      case StatusType.image:
        return CachedNetworkImage(
          imageUrl: status.content,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white, size: 50),
          ),
        );
        
      case StatusType.video:
        if (_chewieController != null && _videoPlayerController!.value.isInitialized) {
          return Chewie(controller: _chewieController!);
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        
      case StatusType.link:
        return Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900,
                Colors.purple.shade600,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.link,
                color: Colors.white,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                'Link: ${status.content}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
  
  Widget _buildReplyBar(StatusModel status) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      child: _isReplyInputVisible
          ? Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: status.userImage.isNotEmpty
                      ? CachedNetworkImageProvider(status.userImage)
                      : null,
                  child: status.userImage.isEmpty
                      ? Text(
                          status.username.isNotEmpty
                              ? status.username.substring(0, 1)
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Reply to ${status.username}...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white24,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: context.modernTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _sendReply,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleReplyInput,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}