import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MyChannelScreen extends ConsumerStatefulWidget {
  const MyChannelScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends ConsumerState<MyChannelScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isEnsuring = false; // NEW: Track channel auto-creation
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  String? _error;
  bool _isDeleting = false;
  late TabController _tabController;
  Map<String, String> _videoThumbnails = {};
  
  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'channelVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // FIXED: Use post-frame callback to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureChannelAndLoadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Clear thumbnail cache on dispose if needed
    // _thumbnailCacheManager.emptyCache();
    super.dispose();
  }

  // NEW: Ensure user has channel before loading data
  Future<void> _ensureChannelAndLoadData() async {
    setState(() {
      _isLoading = true;
      _isEnsuring = true;
      _error = null;
    });

    try {
      debugPrint('MyChannelScreen: Ensuring user has channel');
      
      // Ensure user has a channel first
      final channel = await ref.read(channelsProvider.notifier).ensureUserHasChannel();
      
      if (channel != null) {
        debugPrint('MyChannelScreen: Channel ensured, loading data');
        setState(() {
          _isEnsuring = false;
        });
        
        // Load channel data after ensuring channel exists
        await _loadChannelData();
      } else {
        debugPrint('MyChannelScreen: Failed to ensure channel');
        setState(() {
          _error = 'Failed to set up your channel. Please try again.';
          _isLoading = false;
          _isEnsuring = false;
        });
      }
    } catch (e) {
      debugPrint('MyChannelScreen: Error ensuring channel: $e');
      setState(() {
        _error = 'Failed to set up your channel: $e';
        _isLoading = false;
        _isEnsuring = false;
      });
    }
  }

  Future<void> _loadChannelData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user's channel data
      final userChannel = ref.read(channelsProvider).userChannel;
      
      if (userChannel == null) {
        // This shouldn't happen after auto-creation, but handle it
        throw Exception('Channel not found after setup');
      }
      
      // Get channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(userChannel.id);
      
      if (mounted) {
        setState(() {
          _channel = userChannel;
          _channelVideos = videos;
          _isLoading = false;
        });
        
        // Generate thumbnails for video content
        _generateVideoThumbnails();
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

  Future<void> _generateVideoThumbnails() async {
    for (final video in _channelVideos) {
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        try {
          // Check if thumbnail is already cached
          final cacheKey = 'thumb_${video.id}';
          final fileInfo = await _thumbnailCacheManager.getFileFromCache(cacheKey);
          
          if (fileInfo != null && fileInfo.file.existsSync()) {
            // Use cached thumbnail
            if (mounted) {
              setState(() {
                _videoThumbnails[video.id] = fileInfo.file.path;
              });
            }
          } else {
            // Generate new thumbnail
            final thumbnailPath = await VideoThumbnail.thumbnailFile(
              video: video.videoUrl,
              thumbnailPath: (await getTemporaryDirectory()).path,
              imageFormat: ImageFormat.JPEG,
              maxHeight: 400, // Higher quality for better display
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
                _videoThumbnails[video.id] = thumbnailPath;
              });
            }
          }
        } catch (e) {
          print('Error generating thumbnail for video ${video.id}: $e');
        }
      }
    }
  }

  void _editChannel() {
    if (_channel == null) return;
    
    Navigator.pushNamed(
      context, 
      Constants.editChannelScreen,
      arguments: _channel,
    ).then((_) => _loadChannelData());
  }

  void _createPost() {
    Navigator.pushNamed(context, Constants.createChannelPostScreen)
        .then((result) {
      if (result == true) {
        _loadChannelData();
      }
    });
  }

  Future<void> _deleteVideo(String videoId) async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      await ref.read(channelVideosProvider.notifier).deleteVideo(
        videoId,
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
      
      _loadChannelData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting video: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _confirmDeleteVideo(ChannelVideoModel video) {
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
            const Text('Delete Content'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${video.caption}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 16),
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
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVideo(video.id);
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

  void _openVideoDetails(ChannelVideoModel video) {
    Navigator.pushNamed(
      context, 
      Constants.myPostScreen,
      arguments: video.id,
    ).then((_) => _loadChannelData());
  }

  // NEW: Retry channel setup
  void _retryChannelSetup() {
    _ensureChannelAndLoadData();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final channelsState = ref.watch(channelsProvider);
    
    // Show loading screen while ensuring channel
    if (_isEnsuring || channelsState.isEnsuring) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        body: _buildChannelSetupView(modernTheme),
      );
    }
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      extendBodyBehindAppBar: true, // FIXED: Extend behind system bars
      extendBody: true,
      // FIXED: Ensure proper layout constraints and extend behind system UI
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildChannelView(modernTheme),
      floatingActionButton: _channel != null
          ? Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16, // Account for system nav bar
              ),
              child: FloatingActionButton.extended(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                onPressed: _createPost,
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
                elevation: 8,
              ),
            )
          : null,
    );
  }

  // NEW: Channel setup loading view
  Widget _buildChannelSetupView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom App Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
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
                      'My Channel',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Loading content
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Setting up your channel...',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Using your profile information to create\nyour personalized channel',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your channel...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Better error handling with retry option
  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Custom App Bar
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'My Channel',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Setup Failed',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _retryChannelSetup,
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
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelView(ModernThemeExtension modernTheme) {
    if (_channel == null) {
      return const Center(child: Text('Channel not found'));
    }

    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make transparent to show background
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Channel Header - extends behind status bar
              _buildChannelHeader(modernTheme),
              
              // Channel Info Card
              _buildChannelInfoCard(modernTheme),
              
              // Tab Bar
              Container(
                color: modernTheme.surfaceColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: modernTheme.primaryColor,
                  unselectedLabelColor: modernTheme.textSecondaryColor,
                  indicatorColor: modernTheme.primaryColor,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.grid_view),
                      text: 'Posts',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Analytics',
                    ),
                  ],
                ),
              ),
              
              // Tab Content - Fixed height to prevent infinite height
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(modernTheme),
                    _buildAnalyticsTab(modernTheme),
                  ],
                ),
              ),
              
              // Bottom padding for FAB and system nav bar
              SizedBox(height: 100 + systemBottomPadding),
            ],
          ),
        ),
        // Back button overlay - positioned to account for status bar
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: Padding(
            padding: EdgeInsets.only(top: systemTopPadding * 0.3), // Slight adjustment for better positioning
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(top: systemTopPadding * 0.3),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                onPressed: _channel != null ? _editChannel : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: systemTopPadding * 0.3, right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                ),
                onPressed: () => _showChannelOptions(),
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
      ),
    );
  }

  Widget _buildChannelHeader(ModernThemeExtension modernTheme) {
    final systemTopPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      height: 280 + systemTopPadding, // FIXED: Add system top padding to extend behind status bar
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cover Image - extends behind status bar
          if (_channel!.coverImage.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _channel!.coverImage,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        modernTheme.primaryColor!,
                        modernTheme.primaryColor!.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        modernTheme.primaryColor!,
                        modernTheme.primaryColor!.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white30,
                    size: 48,
                  ),
                ),
              ),
            ),
          
          // Gradient Overlay - extends behind status bar
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Channel Content - positioned below status bar
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _channel!.profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _channel!.profileImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: modernTheme.primaryColor!.withOpacity(0.1),
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
                              color: modernTheme.primaryColor,
                              child: Center(
                                child: Text(
                                  _channel!.name.isNotEmpty
                                      ? _channel!.name[0].toUpperCase()
                                      : "C",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: modernTheme.primaryColor,
                            child: Center(
                              child: Text(
                                _channel!.name.isNotEmpty
                                    ? _channel!.name[0].toUpperCase()
                                    : "C",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Channel Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _channel!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_channel!.isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_channel!.followers} followers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelInfoCard(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // FIXED: Prevent unnecessary expansion
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_channel!.description.isNotEmpty) ...[
            Text(
              _channel!.description,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                height: 1.5,
              ),
              maxLines: 3, // FIXED: Limit description lines to prevent overflow
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                _channel!.followers.toString(),
                'Followers',
                Icons.people,
                modernTheme,
              ),
              _buildStatItem(
                _channel!.videosCount.toString(),
                'Posts',
                Icons.video_library,
                modernTheme,
              ),
              _buildStatItem(
                _channel!.likesCount.toString(),
                'Likes',
                Icons.favorite,
                modernTheme,
              ),
            ],
          ),
          
          // Tags
          if (_channel!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            // FIXED: Make tags scrollable horizontally if they overflow
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _channel!.tags.length,
                itemBuilder: (context, index) {
                  final tag = _channel!.tags[index];
                  return Container(
                    margin: EdgeInsets.only(right: index < _channel!.tags.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: modernTheme.primaryColor!.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String count,
    String label,
    IconData icon,
    ModernThemeExtension modernTheme,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: modernTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(ModernThemeExtension modernTheme) {
    if (_channelVideos.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    return RefreshIndicator(
      onRefresh: _loadChannelData,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 4,
          right: 4,
          top: 4,
          bottom: 80, // Add bottom padding to prevent FAB overlap
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 9 / 16, // TikTok-style aspect ratio
        ),
        itemCount: _channelVideos.length,
        itemBuilder: (context, index) {
          final video = _channelVideos[index];
          return _buildVideoCard(video, modernTheme);
        },
      ),
    );
  }

  Widget _buildVideoCard(ChannelVideoModel video, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _openVideoDetails(video),
      onLongPress: () => _confirmDeleteVideo(video),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail covering the entire tile
          if (video.isMultipleImages && video.imageUrls.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.imageUrls.first,
              fit: BoxFit.cover,
              memCacheHeight: 600, // Optimize memory usage
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
                  Icons.photo_library,
                  color: modernTheme.primaryColor,
                  size: 48,
                ),
              ),
            )
          else if (!video.isMultipleImages && _videoThumbnails.containsKey(video.id))
            Image.file(
              File(_videoThumbnails[video.id]!),
              fit: BoxFit.cover,
            )
          else if (!video.isMultipleImages && video.thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              memCacheHeight: 600, // Optimize memory usage
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
                  Icons.play_circle_fill,
                  color: modernTheme.primaryColor,
                  size: 48,
                ),
              ),
            )
          else
            Container(
              color: modernTheme.primaryColor!.withOpacity(0.1),
              child: Icon(
                video.isMultipleImages ? Icons.photo_library : Icons.play_circle_fill,
                color: modernTheme.primaryColor,
                size: 48,
              ),
            ),
          
          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
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
            ),
          ),
          
          // View count at bottom left (TikTok style)
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatViewCount(video.views),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          
          // Multiple images indicator
          if (video.isMultipleImages && video.imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${video.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                color: modernTheme.primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No content yet',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your first post to connect with your audience',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            // REMOVED: Create Post button to prevent overlap with FAB
            // The FAB will handle the create post action
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100, // Add bottom padding to prevent FAB overlap
      ),
      child: Column(
        children: [
          // Analytics Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Views',
                  _channelVideos.fold<int>(0, (sum, video) => sum + video.views).toString(),
                  Icons.visibility,
                  modernTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Likes',
                  _channelVideos.fold<int>(0, (sum, video) => sum + video.likes).toString(),
                  Icons.favorite,
                  modernTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Comments',
                  _channelVideos.fold<int>(0, (sum, video) => sum + video.comments).toString(),
                  Icons.comment,
                  modernTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Avg. Engagement',
                  '${_calculateEngagementRate().toStringAsFixed(1)}%',
                  Icons.trending_up,
                  modernTheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateEngagementRate() {
    if (_channelVideos.isEmpty) return 0.0;
    
    final totalEngagement = _channelVideos.fold<int>(
      0,
      (sum, video) => sum + video.likes + video.comments,
    );
    final totalViews = _channelVideos.fold<int>(
      0,
      (sum, video) => sum + video.views,
    );
    
    if (totalViews == 0) return 0.0;
    return (totalEngagement / totalViews) * 100;
  }

  void _showChannelOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.modernTheme.textSecondaryColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: context.modernTheme.primaryColor,
                ),
                title: const Text('Edit Channel'),
                onTap: () {
                  Navigator.pop(context);
                  _editChannel();
                },
              ),
              
              ListTile(
                leading: Icon(
                  Icons.share,
                  color: context.modernTheme.primaryColor,
                ),
                title: const Text('Share Channel'),
                onTap: () {
                  Navigator.pop(context);
                  _shareChannel();
                },
              ),
              
              ListTile(
                leading: Icon(
                  Icons.analytics,
                  color: context.modernTheme.primaryColor,
                ),
                title: const Text('View Analytics'),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(1);
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _shareChannel() {
    // Implement channel sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Channel sharing feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.modernTheme.primaryColor,
      ),
    );
  }
}