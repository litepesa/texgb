// lib/features/status/screens/status_viewer_screen.dart (Enhanced with Download)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/providers/status_highlights_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final StatusModel status;
  final int initialIndex;
  final List<StatusModel> allStatuses;

  const StatusViewerScreen({
    super.key,
    required this.status,
    this.initialIndex = 0,
    this.allStatuses = const [],
  });

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  Timer? _timer;
  
  int _currentStatusIndex = 0;
  int _currentUpdateIndex = 0;
  bool _isPaused = false;
  bool _showViews = false;

  @override
  void initState() {
    super.initState();
    _currentStatusIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStatusTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _getCurrentStatus();
    final highlightsState = ref.watch(statusHighlightsNotifierProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Status content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.allStatuses.isNotEmpty 
                ? widget.allStatuses.length 
                : 1,
            itemBuilder: (context, index) {
              final status = widget.allStatuses.isNotEmpty 
                  ? widget.allStatuses[index]
                  : widget.status;
              return _buildStatusContent(status);
            },
          ),
          
          // Top overlay with progress and info
          _buildTopOverlay(currentStatus),
          
          // Bottom overlay with views (if showing)
          if (_showViews) _buildViewsOverlay(currentStatus),
          
          // Download progress overlay
          if (highlightsState.isDownloading) _buildDownloadOverlay(highlightsState),
          
          // Touch zones for navigation
          _buildTouchZones(),
        ],
      ),
    );
  }

  StatusModel _getCurrentStatus() {
    if (widget.allStatuses.isNotEmpty && 
        _currentStatusIndex < widget.allStatuses.length) {
      return widget.allStatuses[_currentStatusIndex];
    }
    return widget.status;
  }

  Widget _buildStatusContent(StatusModel status) {
    if (status.activeUpdates.isEmpty) {
      return const Center(
        child: Text(
          'No active updates',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    final currentUpdate = status.activeUpdates[_currentUpdateIndex];
    
    return GestureDetector(
      onLongPressStart: (_) => _pauseStatus(),
      onLongPressEnd: (_) => _resumeStatus(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildUpdateContent(currentUpdate),
          
          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateContent(StatusUpdate update) {
    switch (update.type) {
      case StatusType.text:
        return _buildTextUpdate(update);
      case StatusType.image:
        return _buildImageUpdate(update);
      case StatusType.video:
        return _buildVideoUpdate(update);
      default:
        return const Center(
          child: Text(
            'Unsupported status type',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  Widget _buildTextUpdate(StatusUpdate update) {
    return Container(
      color: update.backgroundColor ?? Colors.blue,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                update.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  fontFamily: update.fontFamily,
                  height: 1.2,
                ),
              ),
              if (update.content.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  _formatTimestamp(update.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpdate(StatusUpdate update) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (update.mediaUrl != null)
          CachedNetworkImage(
            imageUrl: update.mediaUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        
        if (update.content.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                update.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoUpdate(StatusUpdate update) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.play_circle,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video Status',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
                if (update.displayDuration.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    update.displayDuration,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        if (update.content.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                update.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopOverlay(StatusModel status) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress indicators
              _buildProgressIndicators(status),
              const SizedBox(height: 16),
              
              // User info and actions
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: status.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(status.userImage)
                        : null,
                    child: status.userImage.isEmpty
                        ? const Icon(CupertinoIcons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (status.activeUpdates.isNotEmpty)
                          Text(
                            _formatTimestamp(status.activeUpdates[_currentUpdateIndex].timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Download button
                  IconButton(
                    icon: Icon(
                      _isStatusDownloaded(status.activeUpdates[_currentUpdateIndex])
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.arrow_down_circle,
                      color: _isStatusDownloaded(status.activeUpdates[_currentUpdateIndex])
                          ? Colors.green
                          : Colors.white,
                    ),
                    onPressed: () => _downloadCurrentStatus(),
                  ),
                  
                  // Views button (only for own status)
                  if (_isOwnStatus(status))
                    IconButton(
                      icon: const Icon(CupertinoIcons.eye, color: Colors.white),
                      onPressed: () => _toggleViews(),
                    ),
                  
                  // More options
                  IconButton(
                    icon: const Icon(CupertinoIcons.ellipsis, color: Colors.white),
                    onPressed: () => _showMoreOptions(status),
                  ),
                  
                  // Close button
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators(StatusModel status) {
    final updates = status.activeUpdates;
    if (updates.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: updates.asMap().entries.map((entry) {
        final index = entry.key;
        final isActive = index == _currentUpdateIndex;
        
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index < updates.length - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                double progress = 0.0;
                
                if (index < _currentUpdateIndex) {
                  progress = 1.0; // Completed
                } else if (index == _currentUpdateIndex) {
                  progress = _progressController.value; // Current progress
                }
                
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDownloadOverlay(StatusHighlightsState highlightsState) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.arrow_down_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Downloading status...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: highlightsState.downloadProgress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${(highlightsState.downloadProgress * 100).toStringAsFixed(0)}% complete',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewsOverlay(StatusModel status) {
    final currentUpdate = status.activeUpdates.isNotEmpty 
        ? status.activeUpdates[_currentUpdateIndex]
        : null;
    
    if (currentUpdate == null) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentUpdate.viewCount} views',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                    onPressed: () => _toggleViews(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currentUpdate.views.length,
                itemBuilder: (context, index) {
                  final view = currentUpdate.views[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[700],
                      backgroundImage: view.viewerImage?.isNotEmpty == true
                          ? CachedNetworkImageProvider(view.viewerImage!)
                          : null,
                      child: view.viewerImage?.isEmpty != false
                          ? const Icon(CupertinoIcons.person, color: Colors.white, size: 20)
                          : null,
                    ),
                    title: Text(
                      view.viewerName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _formatTimestamp(view.viewedAt),
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchZones() {
    return Row(
      children: [
        // Left zone - previous
        Expanded(
          child: GestureDetector(
            onTap: _previousStatus,
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Right zone - next
        Expanded(
          child: GestureDetector(
            onTap: _nextStatus,
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  void _startStatusTimer() {
    final currentStatus = _getCurrentStatus();
    if (currentStatus.activeUpdates.isEmpty) return;
    
    const duration = Duration(seconds: 5); // Default viewing time
    _progressController.reset();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused && mounted) {
        _progressController.value += 0.01; // 5 seconds total
        
        if (_progressController.value >= 1.0) {
          _nextStatus();
        }
      }
    });
  }

  void _nextStatus() {
    final currentStatus = _getCurrentStatus();
    
    // Check if there are more updates in current status
    if (_currentUpdateIndex < currentStatus.activeUpdates.length - 1) {
      setState(() {
        _currentUpdateIndex++;
      });
      _markAsViewed(currentStatus);
      _startStatusTimer();
    } else {
      // Move to next status
      if (widget.allStatuses.isNotEmpty && 
          _currentStatusIndex < widget.allStatuses.length - 1) {
        setState(() {
          _currentStatusIndex++;
          _currentUpdateIndex = 0;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // No more statuses, close viewer
        Navigator.pop(context);
      }
    }
  }

  void _previousStatus() {
    // Check if there are previous updates in current status
    if (_currentUpdateIndex > 0) {
      setState(() {
        _currentUpdateIndex--;
      });
      _startStatusTimer();
    } else {
      // Move to previous status
      if (_currentStatusIndex > 0) {
        setState(() {
          _currentStatusIndex--;
          _currentUpdateIndex = widget.allStatuses[_currentStatusIndex].activeUpdates.length - 1;
        });
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentStatusIndex = index;
      _currentUpdateIndex = 0;
    });
    _markAsViewed(_getCurrentStatus());
    _startStatusTimer();
  }

  void _pauseStatus() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeStatus() {
    setState(() {
      _isPaused = false;
    });
  }

  void _toggleViews() {
    setState(() {
      _showViews = !_showViews;
    });
  }

  void _markAsViewed(StatusModel status) {
    if (_isOwnStatus(status)) return; // Don't mark own status as viewed
    
    if (status.activeUpdates.isNotEmpty && _currentUpdateIndex < status.activeUpdates.length) {
      final update = status.activeUpdates[_currentUpdateIndex];
      ref.read(statusNotifierProvider.notifier).viewStatus(
        statusOwnerId: status.uid,
        updateId: update.id,
      );
    }
  }

  bool _isOwnStatus(StatusModel status) {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.uid == status.uid;
  }

  bool _isStatusDownloaded(StatusUpdate statusUpdate) {
    final highlightsNotifier = ref.read(statusHighlightsNotifierProvider.notifier);
    return highlightsNotifier.isStatusDownloaded(statusUpdate.id);
  }

  void _downloadCurrentStatus() {
    final currentStatus = _getCurrentStatus();
    if (currentStatus.activeUpdates.isNotEmpty && _currentUpdateIndex < currentStatus.activeUpdates.length) {
      final currentUpdate = currentStatus.activeUpdates[_currentUpdateIndex];
      
      // Check if already downloaded
      if (_isStatusDownloaded(currentUpdate)) {
        showSnackBar(context, 'Status already downloaded');
        return;
      }
      
      // Start download
      ref.read(statusHighlightsNotifierProvider.notifier)
          .downloadStatus(currentUpdate, currentStatus)
          .then((_) {
        final state = ref.read(statusHighlightsNotifierProvider);
        if (state.error != null) {
          showSnackBar(context, state.error!);
        } else {
          showSnackBar(context, 'Status saved to gallery!');
        }
      });
    }
  }

  void _showMoreOptions(StatusModel status) {
    final currentUpdate = status.activeUpdates.isNotEmpty 
        ? status.activeUpdates[_currentUpdateIndex]
        : null;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Download option
            if (currentUpdate != null)
              ListTile(
                leading: Icon(
                  _isStatusDownloaded(currentUpdate)
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.arrow_down_circle,
                  color: _isStatusDownloaded(currentUpdate) ? Colors.green : Colors.white,
                ),
                title: Text(
                  _isStatusDownloaded(currentUpdate) ? 'Downloaded' : 'Download Status',
                  style: TextStyle(
                    color: _isStatusDownloaded(currentUpdate) ? Colors.green : Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (!_isStatusDownloaded(currentUpdate)) {
                    _downloadCurrentStatus();
                  }
                },
              ),
            
            // Download all updates from this status
            if (status.activeUpdates.length > 1)
              ListTile(
                leading: const Icon(CupertinoIcons.tray_arrow_down, color: Colors.white),
                title: const Text('Download All Updates', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAllUpdates(status);
                },
              ),
            
            // Delete option (only for own status)
            if (_isOwnStatus(status) && currentUpdate != null) ...[
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(CupertinoIcons.delete, color: Colors.red),
                title: const Text('Delete Status', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteStatus(status, currentUpdate),
              ),
            ],
            
            // Status info
            ListTile(
              leading: const Icon(CupertinoIcons.info, color: Colors.white),
              title: const Text('Status Info', style: TextStyle(color: Colors.white)),
              onTap: () => _showStatusInfo(status, currentUpdate),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _downloadAllUpdates(StatusModel status) {
    ref.read(statusHighlightsNotifierProvider.notifier)
        .downloadMultipleStatus(status.activeUpdates, status)
        .then((_) {
      final state = ref.read(statusHighlightsNotifierProvider);
      if (state.error != null) {
        showSnackBar(context, state.error!);
      }
    });
  }

  void _deleteStatus(StatusModel status, StatusUpdate update) {
    Navigator.pop(context); // Close bottom sheet
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: const Text('Are you sure you want to delete this status update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(statusNotifierProvider.notifier).deleteStatusUpdate(update.id);
              Navigator.pop(context); // Close status viewer
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStatusInfo(StatusModel status, StatusUpdate? update) {
    Navigator.pop(context); // Close bottom sheet
    
    if (update == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${update.type.displayName}'),
            const SizedBox(height: 8),
            Text('Posted: ${_formatDetailedTimestamp(update.timestamp)}'),
            const SizedBox(height: 8),
            Text('Views: ${update.viewCount}'),
            if (update.hasExpired) ...[
              const SizedBox(height: 8),
              const Text('Status: Expired', style: TextStyle(color: Colors.red)),
            ],
            if (_isStatusDownloaded(update)) ...[
              const SizedBox(height: 8),
              const Text('Downloaded: Yes', style: TextStyle(color: Colors.green)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDetailedTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return 'Today at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}