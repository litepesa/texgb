// lib/features/status/screens/status_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/models/message_reply_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusViewerScreen extends StatefulWidget {
  final String userId;
  
  const StatusViewerScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  VideoPlayerController? _videoController;
  
  List<StatusPostModel> _statuses = [];
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _shouldContinue = true;
  
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _shouldContinue) {
        _goToNextStatus();
      }
    });
    
    _replyFocusNode.addListener(_handleFocusChange);
    _loadStatuses();
  }

  void _handleFocusChange() {
    if (_replyFocusNode.hasFocus) {
      _pauseStatus();
    } else {
      _resumeStatus();
    }
  }

  void _loadStatuses() {
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
    
    _statuses = widget.userId == authProvider.userModel?.uid
        ? statusProvider.myStatuses
        : statusProvider.userStatusMap[widget.userId] ?? [];
    
    if (_statuses.isNotEmpty) _initializeStatus(0);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _initializeStatus(int index) {
    if (index < 0 || index >= _statuses.length) return;
    
    _disposeVideoController();
    final status = _statuses[index];
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    
    if (currentUser != null && widget.userId != currentUser.uid) {
      Provider.of<StatusProvider>(context, listen: false).viewStatus(
        statusId: status.statusId,
        viewerUid: currentUser.uid,
      );
    }
    
    _progressController.duration = status.type == StatusType.text 
        ? const Duration(seconds: 6)
        : const Duration(seconds: 5);
    
    if (status.type == StatusType.video && status.mediaUrls.isNotEmpty) {
      _initializeVideoController(status.mediaUrls.first);
    } else {
      _startProgress();
    }
  }

  Future<void> _initializeVideoController(String videoUrl) async {
    _videoController = VideoPlayerController.network(videoUrl);
    
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
        _progressController.duration = _videoController!.value.duration;
        _videoController!.play();
        _startProgress();
      }
    } catch (e) {
      _startProgress();
    }
  }

  void _disposeVideoController() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _pauseStatus() {
    setState(() => _isPaused = true);
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeStatus() {
    if (!_replyFocusNode.hasFocus) {
      setState(() => _isPaused = false);
      _progressController.forward();
      _videoController?.play();
    }
  }

  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      _shouldContinue = false;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      _shouldContinue = false;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;
    
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    final status = _statuses[_currentIndex];
    
    try {
      // Determine appropriate thumbnail URL based on status type
      String? thumbnailUrl;
      String statusCaption = status.caption.isNotEmpty 
          ? status.caption 
          : "(${status.type.name} status)";
      
      // Get thumbnail URL based on status type
      if (status.type == StatusType.image || status.type == StatusType.video) {
        thumbnailUrl = status.mediaUrls.isNotEmpty ? status.mediaUrls.first : null;
      } else if (status.type == StatusType.link && status.linkPreviewImage != null) {
        thumbnailUrl = status.linkPreviewImage;
      }
      
      final messageReply = MessageReplyModel(
        message: statusCaption,
        senderUID: status.uid,
        senderName: status.username,
        senderImage: status.userImage,
        messageType: status.type.toMessageEnum(),
        isMe: status.uid == currentUser.uid,
        statusThumbnailUrl: thumbnailUrl,
      );
      
      Provider.of<ChatProvider>(context, listen: false).setMessageReplyModel(messageReply);
      
      await Provider.of<ChatProvider>(context, listen: false).sendTextMessage(
        sender: currentUser,
        contactUID: status.uid,
        contactName: status.username,
        contactImage: status.userImage,
        message: _replyController.text.trim(),
        messageType: MessageEnum.text,
        groupId: '',
        onSucess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reply sent'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reply: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      
      Provider.of<ChatProvider>(context, listen: false).setMessageReplyModel(null);
      _replyController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    if (_statuses.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No status updates found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTapUp: (details) {
            final screenWidth = mediaQuery.size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _goToPreviousStatus();
            } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
              _goToNextStatus();
            } else {
              if (_isPaused) _resumeStatus();
              else _pauseStatus();
            }
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _statuses.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _initializeStatus(index);
                  _shouldContinue = true;
                },
                itemBuilder: (context, index) {
                  return _buildStatusContent(_statuses[index]);
                },
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          _statuses.length,
                          (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: index < _currentIndex 
                                      ? 1.0 
                                      : (index == _currentIndex 
                                          ? _progressController.value 
                                          : 0.0),
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  minHeight: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _statuses[_currentIndex].userImage.isNotEmpty
                                ? CachedNetworkImageProvider(_statuses[_currentIndex].userImage)
                                : AssetImage(AssetsManager.userImage) as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _statuses[_currentIndex].username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(_statuses[_currentIndex].createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 24),
                            color: Colors.white,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _replyController,
                              focusNode: _replyFocusNode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Send a reply...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: InputBorder.none,
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send_rounded,
                            color: const Color(0xFF25D366)), // WhatsApp green color
                          onPressed: _sendReply,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_isPaused)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusPostModel status) {
    switch (status.type) {
      case StatusType.video:
        return _buildVideoStatus(status);
      case StatusType.text:
        return _buildTextStatus(status);
      case StatusType.image:
      default:
        return _buildImageStatus(status);
    }
  }

  Widget _buildImageStatus(StatusPostModel status) {
    if (status.mediaUrls.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              status.caption.isNotEmpty ? status.caption : 'No content',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: status.mediaUrls.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          errorWidget: (context, url, error) => Center(
            child: Icon(Icons.error, color: Colors.white, size: 42),
          ),
        ),

        if (status.caption.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80 + MediaQuery.of(context).padding.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
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
      ],
    );
  }

  Widget _buildVideoStatus(StatusPostModel status) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),

        if (status.caption.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80 + MediaQuery.of(context).padding.bottom,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
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
      ],
    );
  }

  Widget _buildTextStatus(StatusPostModel status) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade800,
            Colors.blue.shade800,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Text(
              status.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return 'Yesterday';
  }
}