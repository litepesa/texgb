// lib/features/status/screens/my_statuses_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/screens/status_viewer_screen.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/constants.dart';

class MyStatusesScreen extends StatefulWidget {
  const MyStatusesScreen({Key? key}) : super(key: key);

  @override
  State<MyStatusesScreen> createState() => _MyStatusesScreenState();
}

class _MyStatusesScreenState extends State<MyStatusesScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, VideoPlayerController?> _videoControllers = {};
  late AnimationController _animationController;
  PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _refreshStatuses();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }
  
  Future<void> _initializeVideoPreview(StatusPostModel status) async {
    if (status.type != StatusType.video || 
        status.mediaUrls.isEmpty || 
        _videoControllers.containsKey(status.statusId)) {
      return;
    }
    
    try {
      final controller = VideoPlayerController.network(status.mediaUrls.first);
      _videoControllers[status.statusId] = controller;
      
      await controller.initialize();
      await controller.setLooping(true);
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing video preview: $e');
    }
  }
  
  void _playCurrentVideo(int index, List<StatusPostModel> statuses) {
    if (index < 0 || index >= statuses.length) return;
    
    // Pause all videos first
    for (final controller in _videoControllers.values) {
      controller?.pause();
    }
    
    // Play the current video if it's a video type
    final currentStatus = statuses[index];
    if (currentStatus.type == StatusType.video && 
        _videoControllers.containsKey(currentStatus.statusId)) {
      _videoControllers[currentStatus.statusId]?.play();
      _videoControllers[currentStatus.statusId]?.setVolume(1.0);
    }
  }
  
  Future<void> _refreshStatuses() async {
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await Provider.of<StatusProvider>(context, listen: false).fetchAllStatuses(
        currentUserId: currentUser.uid,
        contactIds: currentUser.contactsUIDs,
      );
      
      // Initialize video controllers
      final statuses = Provider.of<StatusProvider>(context, listen: false).myStatuses;
      for (final status in statuses) {
        if (status.type == StatusType.video) {
          _initializeVideoPreview(status);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statuses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStatus(StatusPostModel status) async {
    setState(() => _isLoading = true);

    try {
      final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
      if (currentUser == null) return;

      if (_videoControllers.containsKey(status.statusId)) {
        await _videoControllers[status.statusId]?.dispose();
        _videoControllers.remove(status.statusId);
      }

      await Provider.of<StatusProvider>(context, listen: false).deleteStatus(
        statusId: status.statusId,
        creatorUid: currentUser.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteStatus(StatusPostModel status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStatus(status);
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

  void _navigateToStatusDetail(StatusPostModel status) {
    // Pause all video previews
    for (final controller in _videoControllers.values) {
      controller?.pause();
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _buildFullScreenStatus(status),
    ).then((_) {
      // Resume video previews when returning
      if (status.type == StatusType.video && 
          _videoControllers.containsKey(status.statusId) &&
          mounted) {
        _videoControllers[status.statusId]?.play();
      }
    });
  }
  
  Widget _buildFullScreenStatus(StatusPostModel status) {
    final isVideo = status.type == StatusType.video;
    final videoController = isVideo ? _videoControllers[status.statusId] : null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar for dragging
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          // Content area (video/image/text)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _buildFullScreenContent(status),
            ),
          ),
          
          // Analytics and controls
          _buildFullScreenControls(status),
        ],
      ),
    );
  }
  
  Widget _buildFullScreenContent(StatusPostModel status) {
    switch (status.type) {
      case StatusType.video:
        final controller = _videoControllers[status.statusId];
        final isInitialized = controller?.value.isInitialized ?? false;
        
        // Auto-play the video
        if (isInitialized && controller != null) {
          controller.play();
          controller.setVolume(1.0); // Enable sound
        }
        
        return Stack(
          alignment: Alignment.center,
          children: [
            if (isInitialized && controller != null)
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            else if (status.mediaUrls.isNotEmpty)
              Center(
                child: CachedNetworkImage(
                  imageUrl: status.mediaUrls.first,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.video_file, color: Colors.white, size: 64),
                  ),
                ),
              ),
              
            if (!isInitialized)
              const CircularProgressIndicator(color: Colors.white),
              
            // Video controls overlay
            if (isInitialized && controller != null)
              GestureDetector(
                onTap: () {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                  setState(() {});
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: controller.value.isPlaying
                        ? Container()
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        );
        
      case StatusType.text:
        return Container(
          color: Colors.blue, // You can use a gradient or customize background
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              status.caption,
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
          padding: const EdgeInsets.all(24),
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 72, color: Colors.blue[400]),
                const SizedBox(height: 24),
                if (status.caption.isNotEmpty)
                  Text(
                    status.caption,
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
        
      case StatusType.image:
      default:
        return Container(
          color: Colors.black,
          child: status.mediaUrls.isNotEmpty
              ? Center(
                  child: CachedNetworkImage(
                    imageUrl: status.mediaUrls.first,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
        );
    }
  }
  
  Widget _buildFullScreenControls(StatusPostModel status) {
    final timeLeft = _getTimeLeftText(status.expiresAt, false);
    final timeAgo = _getTimeAgo(status.createdAt);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption
          if (status.caption.isNotEmpty) ...[
            Text(
              status.caption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Stats row
          Row(
            children: [
              // Views
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${status.viewCount}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Text('Views', style: TextStyle(color: Colors.grey)),
                ],
              ),
              
              const SizedBox(width: 24),
              
              // Posted time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeAgo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('Posted', style: TextStyle(color: Colors.grey)),
                ],
              ),
              
              const Spacer(),
              
              // Time remaining
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLeft,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Remaining', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  // Share functionality
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Delete',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteStatus(status);
                },
              ),
              _buildActionButton(
                icon: Icons.info_outline,
                label: 'Info',
                onTap: () {
                  Navigator.pop(context);
                  // Show more detailed analytics
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Detailed analytics coming soon')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToCreateStatus() {
    for (final controller in _videoControllers.values) {
      controller?.pause();
    }
    
    Navigator.pushNamed(context, Constants.createStatusScreen)
        .then((_) => _refreshStatuses());
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final statusProvider = Provider.of<StatusProvider>(context);
    final myStatuses = statusProvider.myStatuses;
    
    // Sort statuses - active first, then expired
    final activeStatuses = myStatuses
        .where((status) => !status.expiresAt.difference(DateTime.now()).isNegative)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
    final expiredStatuses = myStatuses
        .where((status) => status.expiresAt.difference(DateTime.now()).isNegative)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // All statuses for the feed view (active first, then expired)
    final allStatuses = [...activeStatuses, ...expiredStatuses];

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (myStatuses.isEmpty) {
      return Scaffold(
        body: _buildEmptyState(context),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreateStatus,
          child: const Icon(Icons.add),
          backgroundColor: modernTheme.primaryColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Statuses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Removed the + icon from the app bar
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: allStatuses.length,
        onPageChanged: (index) {
          _playCurrentVideo(index, allStatuses);
        },
        itemBuilder: (context, index) {
          final status = allStatuses[index];
          final isExpired = status.expiresAt.difference(DateTime.now()).isNegative;
          
          return _buildFullPageStatus(status, isExpired: isExpired);
        },
      ),
    );
  }
  
  Widget _buildFullPageStatus(StatusPostModel status, {bool isExpired = false}) {
    final timeLeftText = _getTimeLeftText(status.expiresAt, isExpired);
    
    return Column(
      children: [
        // Main content area
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Content
              _buildFullscreenContent(status, isExpired: isExpired),
              
              // Top-left time indicator
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeLeftText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Caption overlay at bottom
              if (status.caption.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    status.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
              // Expired overlay
              if (isExpired)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EXPIRED',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Stats bar
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Views - removed the eye icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${status.viewCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Views',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              
              const SizedBox(width: 32),
              
              // Posted time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTimeAgo(status.createdAt),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Text('Posted', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              
              const Spacer(),
              
              // Privacy
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPrivacyText(status.privacyType),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Text('Privacy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        
        // Action buttons - only showing Delete button
        Container(
          color: Colors.black,
          padding: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.center,
          child: _buildBottomActionButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _confirmDeleteStatus(status),
          ),
        ),
        
        // Home indicator line
        Container(
          width: 134,
          height: 5,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullscreenContent(StatusPostModel status, {bool isExpired = false}) {
    switch (status.type) {
      case StatusType.video:
        final controller = _videoControllers[status.statusId];
        final isInitialized = controller?.value.isInitialized ?? false;
        
        return Container(
          color: Colors.black,
          child: status.mediaUrls.isNotEmpty
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isInitialized && controller != null)
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.size.width,
                            height: controller.value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      )
                    else
                      SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: status.mediaUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.video_file, color: Colors.white, size: 64),
                          ),
                        ),
                      ),
                      
                    if (!isInitialized || controller?.value.isPlaying == false)
                      GestureDetector(
                        onTap: () {
                          if (controller != null) {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
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
                      ),
                  ],
                )
              : const Center(
                  child: Text(
                    'No video available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
        
      case StatusType.text:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[800]!, Colors.blue[500]!],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text(
              status.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
        
      case StatusType.link:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[900]!, Colors.grey[800]!],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_rounded, size: 100, color: Colors.blue[400]),
                const SizedBox(height: 32),
                if (status.caption.isNotEmpty)
                  Text(
                    status.caption,
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        );
        
      case StatusType.image:
      default:
        return Container(
          color: Colors.black,
          child: status.mediaUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: status.mediaUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                )
              : const Center(
                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                ),
        );
    }
  }
  
  // Remove this unused method that's causing the error
  String _getPrivacyText(StatusPrivacyType privacyType) {
    switch (privacyType) {
      case StatusPrivacyType.except:
        return 'Filtered';
      case StatusPrivacyType.only:
        return 'Selected';
      case StatusPrivacyType.all_contacts:
      default:
        return 'All Contacts';
    }
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Status Updates',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Share photos, videos or text updates with your contacts',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _navigateToCreateStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Create Status'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSummary(BuildContext context, List<StatusPostModel> statuses) {
    final totalViews = statuses.fold<int>(0, (sum, status) => sum + status.viewCount);
    final photoCount = statuses.where((s) => s.type == StatusType.image).length;
    final videoCount = statuses.where((s) => s.type == StatusType.video).length;
    final textCount = statuses.where((s) => s.type == StatusType.text).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.photo_library,
                label: 'Total',
                value: statuses.length.toString(),
              ),
              _buildStatItem(
                icon: Icons.visibility,
                label: 'Views',
                value: totalViews.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.photo,
                label: 'Photos',
                value: photoCount.toString(),
                small: true,
              ),
              _buildStatItem(
                icon: Icons.videocam,
                label: 'Videos',
                value: videoCount.toString(),
                small: true,
              ),
              _buildStatItem(
                icon: Icons.text_fields,
                label: 'Text',
                value: textCount.toString(),
                small: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool small = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: small ? 20 : 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: small ? 16 : 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: small ? 12 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(StatusPostModel status, {bool isExpired = false}) {
    final timeLeft = status.expiresAt.difference(DateTime.now());
    final timeLeftText = _getTimeLeftText(status.expiresAt, isExpired);
    
    // Play video preview when card is built
    if (status.type == StatusType.video && 
        _videoControllers.containsKey(status.statusId) &&
        !isExpired) {
      _videoControllers[status.statusId]?.play();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToStatusDetail(status),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status preview
            AspectRatio(
              aspectRatio: 16/9,
              child: _buildStatusPreview(status, isExpired: isExpired),
            ),
            
            // Status info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption preview
                  if (status.caption.isNotEmpty) ...[
                    Text(
                      status.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Stats row
                  Row(
                    children: [
                      // Views
                      _buildViewCount(status.viewCount),
                      
                      const Spacer(),
                      
                      // Time left
                      _buildTimeLeftIndicator(timeLeftText, isExpired),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Bottom row with privacy and actions
                  Row(
                    children: [
                      // Privacy indicator
                      _buildPrivacyIndicator(status.privacyType),
                      
                      const Spacer(),
                      
                      // Delete button
                      IconButton(
                        onPressed: () => _confirmDeleteStatus(status),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete status',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildViewCount(int viewCount) {
    return Chip(
      avatar: const Icon(Icons.visibility, size: 16),
      label: Text('$viewCount'),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.blue.withOpacity(0.1),
      labelStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildTimeLeftIndicator(String text, bool isExpired) {
    return Chip(
      avatar: Icon(
        Icons.timer,
        size: 16,
        color: isExpired ? Colors.red : Colors.green,
      ),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      backgroundColor: isExpired 
          ? Colors.red.withOpacity(0.1)
          : Colors.green.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isExpired ? Colors.red : Colors.green,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildSectionHeader({
    required String title,
    required int count,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusPreview(StatusPostModel status, {bool isExpired = false}) {
    return Stack(
      children: [
        // Content
        _buildStatusContent(status, isExpired),
        
        // Overlays
        Positioned(
          top: 12,
          left: 12,
          child: _buildStatusTypeBadge(status.type),
        ),
        
        Positioned(
          top: 12,
          right: 12,
          child: _buildTimeAgoBadge(status.createdAt),
        ),
        
        if (isExpired)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'EXPIRED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildStatusContent(StatusPostModel status, bool isExpired) {
    switch (status.type) {
      case StatusType.video:
        final controller = _videoControllers[status.statusId];
        final isInitialized = controller?.value.isInitialized ?? false;
        
        if (isExpired && controller != null) {
          controller.pause();
        }
        
        return Container(
          color: Colors.black,
          child: status.mediaUrls.isNotEmpty
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isInitialized && controller != null)
                      VideoPlayer(controller)
                    else if (status.mediaUrls.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: status.mediaUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.video_file, color: Colors.white, size: 48),
                        ),
                      ),
                    
                    if (!isInitialized || controller?.value.isPlaying == false)
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                  ],
                )
              : const Center(
                  child: Text(
                    'No video available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
      
      case StatusType.text:
        return Container(
          color: Colors.blue, // Default color
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              status.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      
      case StatusType.link:
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link, size: 48, color: Colors.blue[700]),
                const SizedBox(height: 12),
                if (status.caption.isNotEmpty)
                  Text(
                    status.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      
      case StatusType.image:
      default:
        return Container(
          color: Colors.grey[200],
          child: status.mediaUrls.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: status.mediaUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                )
              : const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
        );
    }
  }
  
  Widget _buildStatusTypeBadge(StatusType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusTypeIcon(type),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusTypeDisplay(type),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeAgoBadge(DateTime createdAt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getTimeAgo(createdAt),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPrivacyIndicator(StatusPrivacyType privacyType) {
    IconData icon;
    String text;
    
    switch (privacyType) {
      case StatusPrivacyType.except:
        icon = Icons.person_remove;
        text = 'Filtered contacts';
        break;
      case StatusPrivacyType.only:
        icon = Icons.people;
        text = 'Selected contacts';
        break;
      case StatusPrivacyType.all_contacts:
      default:
        icon = Icons.people;
        text = 'All contacts';
    }
    
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.grey.withOpacity(0.1),
    );
  }
  
  String _getTimeLeftText(DateTime expiresAt, bool isExpired) {
    if (isExpired) {
      final expiredTime = DateTime.now().difference(expiresAt);
      if (expiredTime.inDays > 0) {
        return 'Expired ${expiredTime.inDays}d ago';
      } else if (expiredTime.inHours > 0) {
        return 'Expired ${expiredTime.inHours}h ago';
      } else {
        return 'Expired ${expiredTime.inMinutes}m ago';
      }
    }
    
    final timeLeft = expiresAt.difference(DateTime.now());
    if (timeLeft.inHours > 0) {
      return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m left';
    }
    return '${timeLeft.inMinutes}m ${timeLeft.inSeconds % 60}s left';
  }
  
  IconData _getStatusTypeIcon(StatusType type) {
    switch (type) {
      case StatusType.video: return Icons.videocam;
      case StatusType.text: return Icons.text_fields;
      case StatusType.link: return Icons.link;
      case StatusType.image: return Icons.photo;
      default: return Icons.photo_library;
    }
  }
  
  String _getStatusTypeDisplay(StatusType type) {
    switch (type) {
      case StatusType.video: return 'Video';
      case StatusType.text: return 'Text';
      case StatusType.link: return 'Link';
      case StatusType.image: return 'Photo';
      default: return 'Status';
    }
  }
  
  String _getTimeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}