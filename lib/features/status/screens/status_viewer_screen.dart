// lib/features/status/screens/status_viewer_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final UserStatusGroup statusGroup;
  final int initialIndex;
  final String currentUserId;

  const StatusViewerScreen({
    super.key,
    required this.statusGroup,
    required this.currentUserId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _progressTimer;
  
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStatusTimer();
      _markCurrentStatusAsViewed();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startStatusTimer() {
    _progressTimer?.cancel();
    _progressController.reset();
    
    const duration = Duration(seconds: 5); // Each status shows for 5 seconds
    _progressController.duration = duration;
    
    _progressController.forward();
    
    _progressTimer = Timer(duration, () {
      if (mounted && !_isPaused) {
        _nextStatus();
      }
    });
  }

  void _pauseStatus() {
    setState(() => _isPaused = true);
    _progressController.stop();
    _progressTimer?.cancel();
  }

  void _resumeStatus() {
    setState(() => _isPaused = false);
    _progressController.forward();
    
    final remainingTime = Duration(
      milliseconds: ((1 - _progressController.value) * 5000).round(),
    );
    
    _progressTimer = Timer(remainingTime, () {
      if (mounted && !_isPaused) {
        _nextStatus();
      }
    });
  }

  void _nextStatus() {
    if (_currentIndex < widget.statusGroup.statuses.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStatusTimer();
      _markCurrentStatusAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStatusTimer();
      _markCurrentStatusAsViewed();
    }
  }

  void _markCurrentStatusAsViewed() {
    if (_currentIndex < widget.statusGroup.statuses.length) {
      final status = widget.statusGroup.statuses[_currentIndex];
      if (!status.hasUserViewed(widget.currentUserId)) {
        ref.read(statusNotifierProvider.notifier).markStatusAsViewed(
          statusId: status.statusId,
          viewerId: widget.currentUserId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _pauseStatus(),
        onTapUp: (details) {
          _resumeStatus();
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < screenWidth * 0.3) {
            _previousStatus();
          } else if (details.localPosition.dx > screenWidth * 0.7) {
            _nextStatus();
          }
        },
        onTapCancel: () => _resumeStatus(),
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _startStatusTimer();
                _markCurrentStatusAsViewed();
              },
              itemCount: widget.statusGroup.statuses.length,
              itemBuilder: (context, index) {
                return _buildStatusContent(widget.statusGroup.statuses[index]);
              },
            ),
            
            // Top overlay with progress and user info
            _buildTopOverlay(theme),
            
            // Bottom overlay with actions (if own status)
            if (widget.statusGroup.isMyStatus) _buildBottomOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusModel status) {
    switch (status.type) {
      case StatusType.text:
        return _buildTextStatus(status);
      case StatusType.image:
        return _buildImageStatus(status);
      case StatusType.video:
        return _buildVideoStatus(status);
      default:
        return _buildTextStatus(status);
    }
  }

  Widget _buildTextStatus(StatusModel status) {
    Color backgroundColor = Colors.black;
    Color textColor = Colors.white;
    
    if (status.backgroundColor != null) {
      backgroundColor = Color(
        int.parse(status.backgroundColor!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }
    
    if (status.fontColor != null) {
      textColor = Color(
        int.parse(status.fontColor!.substring(1, 7), radix: 16) + 0xFF000000,
      );
    }
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            status.content,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontFamily: status.fontFamily == 'default' ? null : status.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildImageStatus(StatusModel status) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: status.content,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        ),
        
        // Caption overlay
        if (status.caption != null && status.caption!.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.caption!,
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

  Widget _buildVideoStatus(StatusModel status) {
    // For now, show a placeholder. In a real app, you'd implement video player
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Video Placeholder',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        
        // Caption overlay
        if (status.caption != null && status.caption!.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.caption!,
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

  Widget _buildTopOverlay(ModernThemeExtension theme) {
    return SafeArea(
      child: Column(
        children: [
          // Progress indicators
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                widget.statusGroup.statuses.length,
                (index) => Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.only(
                      right: index < widget.statusGroup.statuses.length - 1 ? 4 : 0,
                    ),
                    child: LinearProgressIndicator(
                      value: index < _currentIndex
                          ? 1.0
                          : index == _currentIndex
                              ? _progressController.value
                              : 0.0,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // User info and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Profile picture
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: widget.statusGroup.userImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.statusGroup.userImage,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                          )
                        : Container(
                            color: Colors.grey,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.statusGroup.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_currentIndex < widget.statusGroup.statuses.length)
                        Text(
                          _getStatusTimeText(widget.statusGroup.statuses[_currentIndex]),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(ModernThemeExtension theme) {
    if (_currentIndex >= widget.statusGroup.statuses.length) return const SizedBox();
    
    final currentStatus = widget.statusGroup.statuses[_currentIndex];
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // View count
              GestureDetector(
                onTap: () => _showViewers(currentStatus),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${currentStatus.viewCount}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Delete button
              GestureDetector(
                onTap: () => _deleteStatus(currentStatus),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTimeText(StatusModel status) {
    final now = DateTime.now();
    final difference = now.difference(status.createdAt);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showViewers(StatusModel status) async {
    final viewers = await ref.read(statusNotifierProvider.notifier).getStatusViewers(status.statusId);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = context.modernTheme;
        return Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Viewed by ${viewers.length}',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No views yet',
                    style: TextStyle(color: theme.textSecondaryColor),
                  ),
                )
              else
                ...viewers.map((viewer) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: viewer.image.isNotEmpty
                        ? CachedNetworkImageProvider(viewer.image)
                        : null,
                    child: viewer.image.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    viewer.name,
                    style: TextStyle(color: theme.textColor),
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }

  void _deleteStatus(StatusModel status) {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Status',
      content: 'Are you sure you want to delete this status?',
      textAction: 'Delete',
      onActionTap: (confirmed) async {
        if (confirmed) {
          await ref.read(statusNotifierProvider.notifier).deleteStatus(status.statusId);
          if (mounted) {
            // If this was the only status, close viewer
            if (widget.statusGroup.statuses.length == 1) {
              Navigator.pop(context);
            } else {
              // Move to next status or close if this was the last
              if (_currentIndex >= widget.statusGroup.statuses.length - 1) {
                Navigator.pop(context);
              } else {
                _nextStatus();
              }
            }
          }
        }
      },
    );
  }
}
