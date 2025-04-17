import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class StatusViewScreen extends StatefulWidget {
  final String userId;

  const StatusViewScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen> with SingleTickerProviderStateMixin {
  List<StatusModel> _statusList = [];
  bool _isLoading = true;
  bool _isMyStatus = false;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  AnimationController? _progressController;
  Duration _defaultDuration = const Duration(milliseconds: 5000); // Default 5 seconds per status
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default duration, will be updated for videos
    _progressController = AnimationController(
      vsync: this,
      duration: _defaultDuration,
    )..addListener(() {
      setState(() {});
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStatus();
      }
    });
    
    _loadStatuses();
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadStatuses() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();

    // Check if viewing own status
    _isMyStatus = widget.userId == currentUser.uid;

    try {
      if (_isMyStatus) {
        _statusList = statusProvider.myStatuses;
      } else if (statusProvider.contactStatuses.containsKey(widget.userId)) {
        _statusList = statusProvider.contactStatuses[widget.userId]!;
      }

      // If no statuses found, fetch from firebase
      if (_statusList.isEmpty) {
        final statuses = await FirebaseFirestore.instance
            .collection('status')
            .doc(widget.userId)
            .collection('userStatus')
            .orderBy('createdAt', descending: false)
            .get();

        _statusList = statuses.docs
            .map((doc) => StatusModel.fromMap(doc.data()))
            .where((status) => !status.isExpired)
            .toList();
      }

      // Mark as viewed if not own status
      if (!_isMyStatus && _statusList.isNotEmpty) {
        for (var status in _statusList) {
          statusProvider.markStatusAsViewed(
            statusOwnerUid: widget.userId,
            statusId: status.statusId,
            viewerUid: currentUser.uid,
          );
        }
      }

      // Start showing the first status
      if (_statusList.isNotEmpty) {
        _showStatus(_currentIndex);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, 'Error loading statuses: $e');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showStatus(int index) async {
    if (index < 0 || index >= _statusList.length) {
      Navigator.pop(context);
      return;
    }

    _currentIndex = index;
    _isPaused = false;

    // Reset video controller if exists
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    // Reset progress controller
    _progressController?.reset();

    // Get the current status
    final status = _statusList[index];
    
    // Set the appropriate duration based on content type
    if (status.statusType == StatusType.video) {
      // For videos, initialize the controller and use video duration
      _videoController = VideoPlayerController.network(status.statusUrl);
      await _videoController!.initialize();
      
      // Get the actual video duration for the progress bar
      final videoDuration = _videoController!.value.duration;
      print("Video duration: ${videoDuration.inSeconds} seconds");
      
      // Update the progress controller duration to match the video
      _progressController?.duration = videoDuration;
      
      // Start playing the video
      _videoController!.play();
      _videoController!.setLooping(false);
      
      // Add listener to detect when video ends
      _videoController!.addListener(_onVideoProgressChanged);
    } else {
      // For non-video content, use the default duration
      _progressController?.duration = _defaultDuration;
    }

    // Start progress
    _progressController?.forward();
    
    setState(() {});
  }
  
  void _onVideoProgressChanged() {
    if (_videoController != null && 
        _videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration - const Duration(milliseconds: 300)) {
      // Video has finished, move to next status
      _goToNextStatus();
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      // Pause both the progress and the video
      _progressController?.stop();
      _videoController?.pause();
    } else {
      // Resume both the progress and the video
      _progressController?.forward();
      _videoController?.play();
    }
  }

  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      _showStatus(_currentIndex - 1);
    } else {
      // At first status, just restart it
      _progressController?.reset();
      _progressController?.forward();
      
      if (_videoController != null) {
        _videoController!.seekTo(Duration.zero);
        _videoController!.play();
      }
    }
  }

  void _goToNextStatus() {
    // If the video controller has a listener, remove it
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoProgressChanged);
    }
    
    if (_currentIndex < _statusList.length - 1) {
      _showStatus(_currentIndex + 1);
    } else {
      // At last status, exit
      Navigator.pop(context);
    }
  }

  // Delete a status (only for own statuses)
  Future<void> _deleteStatus() async {
    if (!_isMyStatus || _currentIndex >= _statusList.length) return;
    
    final statusProvider = context.read<StatusProvider>();
    final status = _statusList[_currentIndex];
    
    try {
      await statusProvider.deleteStatus(
        statusId: status.statusId,
        onSuccess: () {
          // Remove from local list
          _statusList.removeAt(_currentIndex);
          
          showSnackBar(context, 'Status deleted successfully');
          
          // If no statuses left, go back
          if (_statusList.isEmpty) {
            Navigator.pop(context);
          } else {
            // Show the next status or previous if we deleted the last one
            if (_currentIndex >= _statusList.length) {
              _currentIndex = _statusList.length - 1;
            }
            _showStatus(_currentIndex);
          }
        },
        onError: (error) {
          showSnackBar(context, 'Error deleting status: $error');
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error deleting status: $e');
    }
  }

  // Convert hex color string to Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (!hexString.startsWith('#')) hexString = '#$hexString';
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.black; // Default color on error
    }
  }

  // Get font style based on style
  TextStyle _getTextStyle(String fontStyle, String textColor) {
    final color = _hexToColor(textColor);
    
    switch (fontStyle) {
      case 'italic':
        return TextStyle(
          color: color,
          fontSize: 30,
          fontStyle: FontStyle.italic,
        );
      case 'bold':
        return TextStyle(
          color: color,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        );
      case 'handwriting':
        return TextStyle(
          color: color,
          fontSize: 30,
          fontFamily: 'DancingScript',
        );
      case 'fancy':
        return TextStyle(
          color: color,
          fontSize: 30,
          fontFamily: 'Pacifico',
        );
      case 'normal':
      default:
        return TextStyle(
          color: color,
          fontSize: 30,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_statusList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No status updates available',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Current status and user info
    final status = _statusList[_currentIndex];
    final userName = status.userName;
    final userImage = status.userImage;
    final timeAgo = _getTimeAgo(status.createdAt);
    final isVideo = status.statusType == StatusType.video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // Determine if tap is on left or right side of screen
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth / 3) {
            _goToPreviousStatus();
          } else if (tapPosition > screenWidth * 2/3) {
            _goToNextStatus();
          } else {
            // Center tap toggles play/pause for videos
            if (isVideo) {
              _togglePlayPause();
            }
          }
        },
        onLongPress: _isMyStatus ? _deleteStatus : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Status content
            _buildStatusContent(status),
            
            // Progress indicator at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  _statusList.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value: index < _currentIndex
                            ? 1.0
                            : index == _currentIndex
                                ? _progressController?.value ?? 0.0
                                : 0.0,
                        backgroundColor: Colors.grey.withOpacity(0.5),
                        color: Colors.white,
                        minHeight: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Status owner info at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  userImageWidget(
                    imageUrl: userImage,
                    radius: 20,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMyStatus ? 'My Status' : userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Video duration indicator
                  if (isVideo && _videoController != null && _videoController!.value.isInitialized)
                    Text(
                      '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Play/Pause button for videos
                  if (isVideo)
                    IconButton(
                      icon: Icon(
                        _isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  // Delete button for own statuses
                  if (_isMyStatus)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      onPressed: _deleteStatus,
                    ),
                ],
              ),
            ),
            
            // Caption at bottom (if exists)
            if (status.caption.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
            // Navigation hint
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  isVideo ? "Tap left/right to navigate • Tap center to play/pause" : "Tap left/right to navigate",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Build the main status content based on type
  Widget _buildStatusContent(StatusModel status) {
    switch (status.statusType) {
      case StatusType.text:
        return Container(
          color: _hexToColor(status.backgroundColor),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                status.statusUrl, // For text status, URL contains the text
                style: _getTextStyle(status.fontStyle, status.textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        
      case StatusType.image:
        return Image.network(
          status.statusUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            );
          },
        );
        
      case StatusType.video:
        return _videoController != null && _videoController!.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      if (_isPaused)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator());
    }
  }

  // Calculate time ago from DateTime
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}