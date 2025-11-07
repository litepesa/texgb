// lib/features/videos/screens/manage_posts_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:intl/intl.dart';

class ManagePostsScreen extends ConsumerStatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  ConsumerState<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends ConsumerState<ManagePostsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  UserModel? _user;
  List<VideoModel> _userVideos = [];
  String? _error;
  bool _isDeleting = false;
  late TabController _tabController;
  final Map<String, String> _videoThumbnails = {};
  bool _hasNoProfile = false;
  
  // Selection state for bulk operations
  bool _isSelectionMode = false;
  Set<String> _selectedVideoIds = {};

  // Sorting and filtering
  String _sortBy = 'date'; // 'date', 'views', 'likes', 'engagement'
  bool _sortDescending = true;
  String _filterBy = 'all'; // 'all', 'active', 'inactive', 'featured'

  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'managePostsThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasNoProfile = false;
    });

    try {
      // Check if user is authenticated
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Get fresh user profile from backend
      final authNotifier = ref.read(authenticationProvider.notifier);
      final freshUserProfile = await authNotifier.getUserProfile();

      if (freshUserProfile == null) {
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isLoading = false;
          });
        }
        return;
      }

      // Load user's videos
      await authNotifier.loadVideos();
      await authNotifier.loadUserVideos(freshUserProfile.uid);

      final videos = ref.read(videosProvider);
      final userVideos = videos
          .where((video) => video.channelId == freshUserProfile.uid)
          .toList();

      if (mounted) {
        setState(() {
          _user = freshUserProfile;
          _userVideos = userVideos;
          _isLoading = false;
        });

        // Generate thumbnails for video content
        _generateVideoThumbnails();
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateVideoThumbnails() async {
    for (final video in _userVideos) {
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        try {
          final cacheKey = 'manage_thumb_${video.id}';
          final fileInfo = await _thumbnailCacheManager.getFileFromCache(cacheKey);

          if (fileInfo != null && fileInfo.file.existsSync()) {
            if (mounted) {
              setState(() {
                _videoThumbnails[video.id] = fileInfo.file.path;
              });
            }
          } else {
            final thumbnailPath = await VideoThumbnail.thumbnailFile(
              video: video.videoUrl,
              thumbnailPath: (await getTemporaryDirectory()).path,
              imageFormat: ImageFormat.JPEG,
              maxHeight: 400,
              quality: 85,
            );

            if (thumbnailPath != null && mounted) {
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
          debugPrint('❌ Error generating thumbnail for video ${video.id}: $e');
        }
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedVideoIds.clear();
      }
    });
  }

  void _toggleVideoSelection(String videoId) {
    setState(() {
      if (_selectedVideoIds.contains(videoId)) {
        _selectedVideoIds.remove(videoId);
      } else {
        _selectedVideoIds.add(videoId);
      }
    });
  }

  void _selectAllVideos() {
    setState(() {
      if (_selectedVideoIds.length == _getFilteredAndSortedVideos().length) {
        _selectedVideoIds.clear();
      } else {
        _selectedVideoIds = _getFilteredAndSortedVideos()
            .map((video) => video.id)
            .toSet();
      }
    });
  }

  Future<void> _deleteSelectedVideos() async {
    if (_selectedVideoIds.isEmpty || _isDeleting) return;

    final confirmed = await _showDeleteConfirmation(_selectedVideoIds.length);
    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      
      // Delete videos one by one
      for (final videoId in _selectedVideoIds) {
        await authNotifier.deleteVideo(
          videoId,
          (error) {
            debugPrint('Error deleting video $videoId: $error');
          },
        );
      }

      // Reload data
      await _loadUserData();

      setState(() {
        _selectedVideoIds.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedVideoIds.length} posts deleted successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting posts: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation(int count) async {
    return await showDialog<bool>(
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
            const Text('Delete Posts'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete $count post${count > 1 ? 's' : ''}? This action cannot be undone.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
    ) ?? false;
  }

  Future<void> _deleteSingleVideo(String videoId) async {
    final confirmed = await _showDeleteConfirmation(1);
    if (!confirmed || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(authenticationProvider.notifier).deleteVideo(
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

      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: ${e.toString()}'),
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

  void _openVideoDetails(VideoModel video) {
    Navigator.pushNamed(
      context,
      Constants.myPostScreen,
      arguments: {
        Constants.videoId: video.id,
        Constants.videoModel: video,
      },
    ).then((_) => _loadUserData());
  }

  List<VideoModel> _getFilteredAndSortedVideos() {
    List<VideoModel> filteredVideos = _userVideos;

    // Apply filters
    switch (_filterBy) {
      case 'active':
        filteredVideos = filteredVideos.where((video) => video.isActive).toList();
        break;
      case 'inactive':
        filteredVideos = filteredVideos.where((video) => !video.isActive).toList();
        break;
      case 'featured':
        filteredVideos = filteredVideos.where((video) => video.isFeatured).toList();
        break;
      case 'all':
      default:
        // No filtering
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case 'views':
        filteredVideos.sort((a, b) => _sortDescending 
            ? b.views.compareTo(a.views) 
            : a.views.compareTo(b.views));
        break;
      case 'likes':
        filteredVideos.sort((a, b) => _sortDescending 
            ? b.likes.compareTo(a.likes) 
            : a.likes.compareTo(b.likes));
        break;
      case 'engagement':
        filteredVideos.sort((a, b) => _sortDescending 
            ? b.engagementRate.compareTo(a.engagementRate) 
            : a.engagementRate.compareTo(b.engagementRate));
        break;
      case 'date':
      default:
        filteredVideos.sort((a, b) => _sortDescending 
            ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
            : a.createdAtDateTime.compareTo(b.createdAtDateTime));
        break;
    }

    return filteredVideos;
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

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
      return 'Unknown';
    }
  }

  double _calculateEngagementRate() {
    if (_userVideos.isEmpty) return 0.0;

    final totalEngagement = _userVideos.fold<int>(
      0,
      (sum, video) => sum + video.likes + video.comments,
    );
    final totalViews = _userVideos.fold<int>(
      0,
      (sum, video) => sum + video.views,
    );

    if (totalViews == 0) return 0.0;
    return (totalEngagement / totalViews) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      appBar: _buildAppBar(modernTheme),
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _hasNoProfile
              ? _buildProfileRequiredView(modernTheme)
              : _error != null
                  ? _buildErrorView(modernTheme)
                  : _buildManagePostsView(modernTheme),
    );
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme) {
    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      foregroundColor: modernTheme.textColor,
      elevation: 0,
      title: Text(
        _isSelectionMode 
            ? '${_selectedVideoIds.length} selected'
            : 'Manage Posts',
      ),
      actions: [
        if (!_isLoading && !_hasNoProfile && _error == null && _userVideos.isNotEmpty) ...[
          if (_isSelectionMode) ...[
            // Selection mode actions
            IconButton(
              icon: Icon(
                _selectedVideoIds.length == _getFilteredAndSortedVideos().length
                    ? Icons.deselect
                    : Icons.select_all,
                color: modernTheme.primaryColor,
              ),
              onPressed: _selectAllVideos,
              tooltip: _selectedVideoIds.length == _getFilteredAndSortedVideos().length
                  ? 'Deselect All'
                  : 'Select All',
            ),
            if (_selectedVideoIds.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red.shade600,
                ),
                onPressed: _isDeleting ? null : _deleteSelectedVideos,
                tooltip: 'Delete Selected',
              ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
              tooltip: 'Cancel Selection',
            ),
          ] else ...[
            // Normal mode actions
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select Posts',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (value) {
                setState(() {
                  if (value == 'toggle_order') {
                    _sortDescending = !_sortDescending;
                  } else {
                    _sortBy = value;
                  }
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text('Sort by Date'),
                      if (_sortBy == 'date') 
                        Icon(Icons.check, color: modernTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'views',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      const SizedBox(width: 8),
                      Text('Sort by Views'),
                      if (_sortBy == 'views') 
                        Icon(Icons.check, color: modernTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'likes',
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 20),
                      const SizedBox(width: 8),
                      Text('Sort by Likes'),
                      if (_sortBy == 'likes') 
                        Icon(Icons.check, color: modernTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'engagement',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 20),
                      const SizedBox(width: 8),
                      Text('Sort by Engagement'),
                      if (_sortBy == 'engagement') 
                        Icon(Icons.check, color: modernTheme.primaryColor, size: 16),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'toggle_order',
                  child: Row(
                    children: [
                      Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward, size: 20),
                      const SizedBox(width: 8),
                      Text(_sortDescending ? 'Descending' : 'Ascending'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
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
            'Loading your posts...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRequiredView(ModernThemeExtension modernTheme) {
    return const LoginRequiredWidget(
      title: 'Sign In Required',
      subtitle: 'Please sign in to manage your posts.',
      actionText: 'Sign In',
      icon: Icons.post_add,
    );
  }

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Something went wrong',
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
              onPressed: _loadUserData,
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
    );
  }

  Widget _buildManagePostsView(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Filter chips
        _buildFilterChips(modernTheme),

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
              Tab(
                icon: Icon(Icons.insights),
                text: 'Insights',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(modernTheme),
              _buildAnalyticsTab(modernTheme),
              _buildInsightsTab(modernTheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', modernTheme),
            const SizedBox(width: 8),
            _buildFilterChip('Active', 'active', modernTheme),
            const SizedBox(width: 8),
            _buildFilterChip('Inactive', 'inactive', modernTheme),
            const SizedBox(width: 8),
            _buildFilterChip('Featured', 'featured', modernTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ModernThemeExtension modernTheme) {
    final isSelected = _filterBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? modernTheme.primaryColor 
              : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? modernTheme.primaryColor! 
                : modernTheme.primaryColor!.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : modernTheme.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab(ModernThemeExtension modernTheme) {
    final filteredVideos = _getFilteredAndSortedVideos();
    
    if (filteredVideos.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 9 / 16,
      ),
      itemCount: filteredVideos.length,
      itemBuilder: (context, index) {
        final video = filteredVideos[index];
        return _buildVideoCard(video, modernTheme);
      },
    );
  }

  Widget _buildVideoCard(VideoModel video, ModernThemeExtension modernTheme) {
    final isSelected = _selectedVideoIds.contains(video.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleVideoSelection(video.id);
        } else {
          _openVideoDetails(video);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _toggleSelectionMode();
          _toggleVideoSelection(video.id);
        }
      },
      child: Stack(
        children: [
          // Main card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? modernTheme.primaryColor! 
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail
                  if (video.isMultipleImages && video.imageUrls.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: video.imageUrls.first,
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
                          Icons.photo_library,
                          color: modernTheme.primaryColor,
                          size: 32,
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
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      child: Icon(
                        video.isMultipleImages
                            ? Icons.photo_library
                            : Icons.play_circle_fill,
                        color: modernTheme.primaryColor,
                        size: 32,
                      ),
                    ),

                  // Gradient overlay
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
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Post info
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatViewCount(video.views),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatViewCount(video.likes),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Post date
                        Text(
                          _formatTimeAgo(video.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status indicators
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        if (!video.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (video.isFeatured)
                          Container(
                            margin: EdgeInsets.only(left: video.isActive ? 0 : 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Featured',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
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
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${video.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Selection overlay
                  if (_isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? modernTheme.primaryColor 
                              : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Quick action menu
          if (!_isSelectionMode)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showQuickActionsMenu(video, modernTheme),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu(VideoModel video, ModernThemeExtension modernTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Post title
            Text(
              video.caption.length > 50 
                  ? '${video.caption.substring(0, 50)}...' 
                  : video.caption,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickAction(
              'View Details',
              Icons.visibility,
              () {
                Navigator.pop(context);
                _openVideoDetails(video);
              },
              modernTheme,
            ),
            _buildQuickAction(
              'Share',
              Icons.share,
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Share feature coming soon!'),
                    backgroundColor: modernTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              modernTheme,
            ),
            _buildQuickAction(
              'Delete',
              Icons.delete_outline,
              () {
                Navigator.pop(context);
                _deleteSingleVideo(video.id);
              },
              modernTheme,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    VoidCallback onTap,
    ModernThemeExtension modernTheme, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : modernTheme.textColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : modernTheme.textColor,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
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
              _filterBy == 'all' ? 'No posts yet' : 'No $_filterBy posts',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _filterBy == 'all' 
                  ? 'Start creating content to see your posts here'
                  : 'No posts match the current filter',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (_filterBy != 'all') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterBy = 'all';
                  });
                },
                child: Text(
                  'Show All Posts',
                  style: TextStyle(
                    color: modernTheme.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Stats Cards
          Text(
            'Performance Overview',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildAnalyticsCard(
                'Total Posts',
                _userVideos.length.toString(),
                Icons.video_library,
                '${_userVideos.where((v) => v.isActive).length} active',
                Colors.blue,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Total Views',
                _formatViewCount(_userVideos.fold<int>(0, (sum, video) => sum + video.views)),
                Icons.visibility,
                'Across all posts',
                Colors.green,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Total Likes',
                _formatViewCount(_userVideos.fold<int>(0, (sum, video) => sum + video.likes)),
                Icons.favorite,
                '${(_calculateEngagementRate()).toStringAsFixed(1)}% engagement',
                Colors.red,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Total Comments',
                _formatViewCount(_userVideos.fold<int>(0, (sum, video) => sum + video.comments)),
                Icons.comment,
                'Community feedback',
                Colors.orange,
                modernTheme,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Top Performing Posts
          Text(
            'Top Performing Posts',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...(() {
            final sortedVideos = _userVideos.toList();
            sortedVideos.sort((a, b) => b.views.compareTo(a.views));
            return sortedVideos.take(3);
          })().map((video) => _buildTopPostItem(video, modernTheme)),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...(() {
            final sortedVideos = _userVideos.toList();
            sortedVideos.sort((a, b) => b.createdAtDateTime.compareTo(a.createdAtDateTime));
            return sortedVideos.take(5);
          })().map((video) => _buildRecentActivityItem(video, modernTheme)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    String subtitle,
    Color iconColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPostItem(VideoModel video, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: modernTheme.primaryColor!.withOpacity(0.1),
            ),
            child: video.isMultipleImages && video.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: video.imageUrls.first,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.photo_library,
                        color: modernTheme.primaryColor,
                      ),
                    ),
                  )
                : Icon(
                    video.isMultipleImages ? Icons.photo_library : Icons.play_circle_fill,
                    color: modernTheme.primaryColor,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Post info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.caption.length > 40 
                      ? '${video.caption.substring(0, 40)}...' 
                      : video.caption,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: modernTheme.textSecondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatViewCount(video.views),
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.favorite,
                      color: modernTheme.textSecondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatViewCount(video.likes),
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // View button
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: modernTheme.primaryColor,
              size: 16,
            ),
            onPressed: () => _openVideoDetails(video),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(VideoModel video, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            video.isMultipleImages ? Icons.photo_library : Icons.video_library,
            color: modernTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.caption.length > 30 
                      ? '${video.caption.substring(0, 30)}...' 
                      : video.caption,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Posted ${_formatTimeAgo(video.createdAt)}',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatViewCount(video.views)} views',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [  
          // Content Analysis
          Text(
            'Content Analysis',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildContentTypeCard(
                  'Videos',
                  _userVideos.where((v) => !v.isMultipleImages).length,
                  Icons.play_circle_fill,
                  Colors.red,
                  modernTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContentTypeCard(
                  'Images',
                  _userVideos.where((v) => v.isMultipleImages).length,
                  Icons.photo_library,
                  Colors.blue,
                  modernTheme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildContentTypeCard(
                  'Active',
                  _userVideos.where((v) => v.isActive).length,
                  Icons.visibility,
                  Colors.green,
                  modernTheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContentTypeCard(
                  'Featured',
                  _userVideos.where((v) => v.isFeatured).length,
                  Icons.star,
                  Colors.amber,
                  modernTheme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Engagement Insights
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Engagement Insights',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your average engagement rate is ${_calculateEngagementRate().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Industry average: 3-5%',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon, ModernThemeExtension modernTheme) {
    return Row(
      children: [
        Icon(
          icon,
          color: modernTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentTypeCard(
    String title,
    int count,
    IconData icon,
    Color color,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}