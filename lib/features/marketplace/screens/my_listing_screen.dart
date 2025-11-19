// lib/features/marketplace/screens/my_listing_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/marketplace/models/marketplace_item_model.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/marketplace/providers/marketplace_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_boost_tab_widget.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_edit_tab_widget.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_analytics_tab_widget.dart';
import 'package:intl/intl.dart';

class MyListingScreen extends ConsumerStatefulWidget {
  final String itemId;
  
  const MyListingScreen({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends ConsumerState<MyListingScreen>
    with TickerProviderStateMixin {
  MarketplaceItemModel? _marketplaceItem;
  bool _isLoading = true;
  String? _error;
  String? _videoThumbnail;
  late AnimationController _rocketAnimationController;
  late Animation<double> _rocketAnimation;
  late TabController _tabController;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'postVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize rocket animation
    _rocketAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rocketAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rocketAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadVideoData();
  }

  @override
  void dispose() {
    _rocketAnimationController.dispose();
    _tabController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the specific marketplaceItem from the authentication provider
      final marketplaceItems = ref.read(marketplaceItemsProvider);
      final marketplaceItem = marketplaceItems.firstWhere(
        (v) => v.id == widget.itemId,
        orElse: () => throw Exception('Video not found'),
      );
      
      if (mounted) {
        setState(() {
          _marketplaceItem = marketplaceItem;
          _isLoading = false;
        });

        // Generate thumbnail if it's a video
        if (!marketplaceItem.isMultipleImages && marketplaceItem.itemUrl.isNotEmpty) {
          _generateVideoThumbnail();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateVideoThumbnail() async {
    if (_marketplaceItem == null || _marketplaceItem!.itemUrl.isEmpty) return;

    try {
      // Check if thumbnail is already cached
      final cacheKey = 'post_thumb_${_marketplaceItem!.id}';
      final fileInfo = await _thumbnailCacheManager.getFileFromCache(cacheKey);

      if (fileInfo != null && fileInfo.file.existsSync()) {
        // Use cached thumbnail
        if (mounted) {
          setState(() {
            _videoThumbnail = fileInfo.file.path;
          });
        }
      } else {
        // Generate new thumbnail
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: _marketplaceItem!.itemUrl,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 400,
          quality: 85,
        );

        if (thumbnailPath != null && mounted) {
          // Cache the thumbnail
          final thumbnailFile = File(thumbnailPath);
          if (thumbnailFile.existsSync()) {
            await _thumbnailCacheManager.putFile(
              cacheKey,
              thumbnailFile.readAsBytesSync(),
            );
          }

          setState(() {
            _videoThumbnail = thumbnailPath;
          });
        }
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_marketplaceItem == null || _marketplaceItem!.isMultipleImages || _marketplaceItem!.itemUrl.isEmpty) return;

    try {
      _videoController = VideoPlayerController.network(_marketplaceItem!.itemUrl);
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _initializeVideoPlayer().then((_) {
        if (_videoController != null && _videoController!.value.isInitialized) {
          _videoController!.play();
          setState(() {
            _isPlaying = true;
          });
        }
      });
    } else {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _boostPost(String boostTier) async {
    if (_marketplaceItem == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tierInfo = _getBoostTierInfo(boostTier);
        final modernTheme = context.modernTheme;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.rocket_launch,
                color: modernTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Confirm Boost'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boost this listing with ${tierInfo['name']}?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('View Target:', tierInfo['viewRange'], Icons.visibility),
              _buildInfoRow('Duration:', tierInfo['duration'], Icons.schedule),
              _buildInfoRow('Cost:', 'KES ${tierInfo['price']}', Icons.payments),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coins will be deducted from your wallet',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Boost Now'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (!confirmed) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: context.modernTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text('Boosting your listing...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Call boost function
    await ref.read(marketplaceProvider.notifier).boostMarketplaceItem(
      itemId: _marketplaceItem!.id,
      boostTier: boostTier,
      onSuccess: (message) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Reload marketplaceItem data
        _loadVideoData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      onError: (error) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  // Helper method for info rows in dialog
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get boost tier info
  Map<String, dynamic> _getBoostTierInfo(String boostTier) {
    switch (boostTier.toLowerCase()) {
      case 'basic':
        return {
          'name': 'Basic Boost',
          'price': 99,
          'viewRange': '1,713 - 10K views',
          'duration': '72 hours',
        };
      case 'standard':
        return {
          'name': 'Standard Boost',
          'price': 999,
          'viewRange': '17,138 - 100K views',
          'duration': '72 hours',
        };
      case 'advanced':
        return {
          'name': 'Advanced Boost',
          'price': 9999,
          'viewRange': '171,388 - 1M views',
          'duration': '72 hours',
        };
      default:
        return {
          'name': 'Unknown',
          'price': 0,
          'viewRange': 'N/A',
          'duration': '0 hours',
        };
    }
  }

  void _editPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit feature coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addBannerText() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Banner text editor coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deletePost() async {
    if (_marketplaceItem == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Delete Post'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref.read(marketplaceProvider.notifier).deleteMarketplaceItem(
                  _marketplaceItem!.id,
                  (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
                
                // Go back to previous screen after successful deletion
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Constants.videoDeleted),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting listing: ${e.toString()}'),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // UPDATED: Handle RFC3339 string timestamps instead of Firestore Timestamps
  String _formatTimeAgo(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return DateFormat('MMM d, y').format(dateTime);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      // Fallback for invalid timestamp
      return 'Unknown';
    }
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: _isLoading || _error != null || _marketplaceItem == null
          ? null
          : AppBar(
              backgroundColor: modernTheme.backgroundColor,
              foregroundColor: modernTheme.textColor,
              elevation: 0,
              title: const Text('My Listing'),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: modernTheme.textColor,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPost();
                        break;
                      case 'delete':
                        _deletePost();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Post'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _error != null
              ? _buildErrorView(modernTheme)
              : _marketplaceItem != null
                  ? _buildPostView(modernTheme)
                  : _buildErrorView(modernTheme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'My Listing',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: modernTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading listing details...',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'My Listing',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: modernTheme.primaryColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Post Not Found',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error ?? 'The listing you\'re looking for doesn\'t exist.',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go Back'),
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

  Widget _buildPostView(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Tab Bar at the top
        Container(
          color: modernTheme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: modernTheme.primaryColor,
            unselectedLabelColor: modernTheme.textSecondaryColor,
            indicatorColor: modernTheme.primaryColor,
            isScrollable: true,
            tabs: const [
              Tab(
                icon: Icon(Icons.rocket_launch),
                text: 'Boost',
              ),
              Tab(
                icon: Icon(Icons.image),
                text: 'Preview',
              ),
              Tab(
                icon: Icon(Icons.analytics),
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.edit),
                text: 'Edit',
              ),
            ],
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Boost Tab
              BoostTabWidget(
                rocketAnimationController: _rocketAnimationController,
                rocketAnimation: _rocketAnimation,
                onBoostPost: _boostPost,
              ),
              // Preview Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPostPreviewCard(_marketplaceItem!, modernTheme),
                    _buildActionButtons(modernTheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Analytics Tab
              AnalyticsTabWidget(marketplaceItem: _marketplaceItem!),
              // Edit Tab
              EditTabWidget(
                marketplaceItem: _marketplaceItem,
                onAddBannerText: _addBannerText,
                onEditPost: _editPost,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostPreviewCard(MarketplaceItemModel marketplaceItem, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: Constants.videoAspectRatio, // TikTok-style aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Content - Full coverage
              if (marketplaceItem.isMultipleImages && marketplaceItem.imageUrls.isNotEmpty)
                PageView.builder(
                  itemCount: marketplaceItem.imageUrls.length,
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: marketplaceItem.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: modernTheme.surfaceColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            modernTheme.primaryColor!,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: modernTheme.primaryColor,
                        size: 48,
                      ),
                    ),
                  ),
                )
              else if (!marketplaceItem.isMultipleImages && _videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else if (!marketplaceItem.isMultipleImages && _videoThumbnail != null)
                Image.file(
                  File(_videoThumbnail!),
                  fit: BoxFit.cover,
                )
              else if (!marketplaceItem.isMultipleImages && marketplaceItem.thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: marketplaceItem.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: modernTheme.surfaceColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          modernTheme.primaryColor!,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    child: Icon(
                      Icons.video_library,
                      color: modernTheme.primaryColor,
                      size: 48,
                    ),
                  ),
                )
              else
                Container(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  child: Icon(
                    marketplaceItem.isMultipleImages ? Icons.photo_library : Icons.play_circle_fill,
                    color: modernTheme.primaryColor,
                    size: 64,
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Play/Pause button for videos
              if (!marketplaceItem.isMultipleImages)
                Center(
                  child: GestureDetector(
                    onTap: _toggleVideoPlayback,
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Post Info Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundImage: marketplaceItem.userImage.isNotEmpty
                                  ? CachedNetworkImageProvider(marketplaceItem.userImage)
                                  : null,
                              child: marketplaceItem.userImage.isEmpty
                                  ? Text(
                                      marketplaceItem.userName.isNotEmpty
                                          ? marketplaceItem.userName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  marketplaceItem.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(marketplaceItem.createdAt), // UPDATED: Pass string directly
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Caption
                      Text(
                        marketplaceItem.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Tags
                      if (marketplaceItem.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: marketplaceItem.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Stats
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.favorite,
                            _formatViewCount(marketplaceItem.likes),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.comment,
                            _formatViewCount(marketplaceItem.comments),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.visibility,
                            _formatViewCount(marketplaceItem.views),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.share,
                            _formatViewCount(marketplaceItem.shares),
                            modernTheme,
                            isOverlay: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Page indicator for multiple images
              if (marketplaceItem.isMultipleImages && marketplaceItem.imageUrls.length > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${marketplaceItem.imageUrls.length} photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, ModernThemeExtension modernTheme, {bool isOverlay = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverlay 
            ? Colors.white.withOpacity(0.2)
            : modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isOverlay 
            ? Border.all(color: Colors.white.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isOverlay ? Colors.white : modernTheme.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: isOverlay ? Colors.white : modernTheme.textSecondaryColor,
              fontSize: 14,
              fontWeight: isOverlay ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the Boost tab
                _tabController.animateTo(2); // Index 2 is the Boost tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: AnimatedBuilder(
                animation: _rocketAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_rocketAnimation.value * 10),
                    child: Transform.rotate(
                      angle: _rocketAnimation.value * 0.5,
                      child: const Icon(Icons.rocket_launch, size: 20),
                    ),
                  );
                },
              ),
              label: const Text('Boost Post'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editPost,
              style: OutlinedButton.styleFrom(
                foregroundColor: modernTheme.primaryColor,
                side: BorderSide(color: modernTheme.primaryColor!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }
}