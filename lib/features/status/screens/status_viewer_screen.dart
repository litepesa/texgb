// lib/features/status/screens/status_viewer_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
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

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> 
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _fadeController;
  VideoPlayerController? _videoController;
  TextEditingController _replyController = TextEditingController();
  FocusNode _replyFocusNode = FocusNode();
  
  bool _isLoading = true;
  bool _isPaused = false;
  bool _showUI = true;
  bool _isReplying = false;
  int _currentIndex = 0;
  String _statusThumbnailUrl = '';
  
  final Duration _statusDuration = const Duration(seconds: 5);
  final Duration _uiFadeDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialStatusIndex;
    
    // Set up controllers
    _progressController = AnimationController(
      vsync: this,
      duration: _statusDuration,
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: _uiFadeDuration,
      value: 1.0,
    );
    
    // Initialize status
    _initializeStatus();
    _updateStatusThumbnailUrl();
    
    // Mark status as viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statusNotifierProvider.notifier).viewStatus(
        widget.userStatus, 
        _currentIndex
      );
    });

    // Listen for keyboard visibility
    _replyFocusNode.addListener(() {
      setState(() {
        _isReplying = _replyFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    
    super.dispose();
  }

  void _initializeStatus() {
    setState(() {
      _isLoading = true;
      _isPaused = false;
    });
    
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    _progressController.reset();
    
    if (currentStatus.type == StatusType.video) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(currentStatus.content)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            _progressController.duration = _videoController!.value.duration;
            _videoController!.play();
            _progressController.forward();
            
            _videoController!.addListener(_videoListener);
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _goToNextStatus();
          }
        });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _progressController.forward().then((_) {
            if (mounted && !_isPaused) {
              _goToNextStatus();
            }
          });
        }
      });
    }
  }

  void _videoListener() {
    if (_videoController != null && 
        _videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration) {
      _goToNextStatus();
    }
  }

  void _updateStatusThumbnailUrl() {
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    setState(() {
      _statusThumbnailUrl = (currentStatus.type == StatusType.image || 
                            currentStatus.type == StatusType.video) 
          ? currentStatus.content 
          : '';
    });
  }

  void _goToNextStatus() {
    if (_currentIndex < widget.userStatus.statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializeStatus();
      _updateStatusThumbnailUrl();
      
      ref.read(statusNotifierProvider.notifier).viewStatus(
        widget.userStatus, 
        _currentIndex
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializeStatus();
      _updateStatusThumbnailUrl();
    } else {
      Navigator.pop(context);
    }
  }

  void _togglePlayPause() {
    if (_isPaused) {
      _resumeStatus();
    } else {
      _pauseStatus();
    }
  }

  void _pauseStatus() {
    if (_isPaused) return;
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStatus() {
    if (!_isPaused) return;
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    final replyText = _replyController.text.trim();
    
    _replyController.clear();
    _replyFocusNode.unfocus();
    
    try {
      await ref.read(statusNotifierProvider.notifier).sendStatusReply(
        statusId: currentStatus.statusId,
        receiverId: currentStatus.userId,
        message: replyText,
        statusThumbnail: _statusThumbnailUrl,
        statusType: currentStatus.type,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply sent'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send reply'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showStatusOptions() {
    _pauseStatus();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Status Info'),
              onTap: () {
                Navigator.pop(context);
                _showStatusInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report Status'),
              onTap: () {
                Navigator.pop(context);
                _resumeStatus();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) => _resumeStatus());
  }

  void _showStatusInfo() {
    final status = widget.userStatus.statuses[_currentIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Status Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Posted by', status.userName),
            _buildInfoRow('Type', status.type.name.toUpperCase()),
            _buildInfoRow('Views', status.viewCount.toString()),
            _buildInfoRow('Posted', _formatTimestamp(status.createdAt)),
            _buildInfoRow('Expires', _formatTimestamp(status.expiresAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.userStatus.statuses[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _toggleUI,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            _goToPreviousStatus();
          } else if (details.primaryVelocity! < -300) {
            _goToNextStatus();
          }
        },
        child: Stack(
          children: [
            // Status content
            Positioned.fill(
              child: _buildStatusContent(currentStatus),
            ),
            
            // Touch areas for navigation
            _buildNavigationAreas(),
            
            // Top UI elements
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) => Opacity(
                opacity: _fadeController.value,
                child: _buildTopUI(currentStatus),
              ),
            ),
            
            // Bottom UI elements
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) => Opacity(
                opacity: _fadeController.value,
                child: _buildBottomUI(currentStatus),
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            
            // Pause indicator
            if (_isPaused && !_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    switch (status.type) {
      case StatusType.image:
        return Hero(
          tag: 'status_${status.statusId}',
          child: CachedNetworkImage(
            imageUrl: status.content,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
      case StatusType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          );
        }
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        );
        
      case StatusType.text:
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                status.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        
      case StatusType.link:
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black87,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    status.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildNavigationAreas() {
    return Row(
      children: [
        // Left area (previous)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _goToPreviousStatus,
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
        // Middle area (pause/play)
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _togglePlayPause,
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
        // Right area (next)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _goToNextStatus,
            behavior: HitTestBehavior.translucent,
            child: Container(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopUI(StatusModel currentStatus) {
    return SafeArea(
      child: Column(
        children: [
          // Progress indicators
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: List.generate(
                widget.userStatus.statuses.length,
                (index) => Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        double progress = 0.0;
                        if (index < _currentIndex) {
                          progress = 1.0; // Completed
                        } else if (index == _currentIndex) {
                          progress = _progressController.value; // Current
                        }
                        
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Header with user info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${widget.userStatus.userId}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: CachedNetworkImageProvider(
                        widget.userStatus.userImage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userStatus.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTimestamp(currentStatus.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showStatusOptions,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomUI(StatusModel currentStatus) {
    return Column(
      children: [
        const Spacer(),
        
        // Caption
        if (currentStatus.caption.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentStatus.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.3,
              ),
            ),
          ),
        
        // Reply section
        SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _replyController,
                    focusNode: _replyFocusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Reply to ${widget.userStatus.userName}...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendReply(),
                  ),
                ),
                IconButton(
                  onPressed: _sendReply,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return "${difference.inDays}d";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m";
      } else {
        return "now";
      }
    } catch (e) {
      return "now";
    }
  }
}