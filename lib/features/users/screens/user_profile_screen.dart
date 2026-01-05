import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoading = true;
  UserModel? _user;
  List<VideoModel> _userVideos = [];
  String? _error;
  bool _isFollowing = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _videoThumbnails = {};

  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'userVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);

      // Get user profile
      final user = await authNotifier.getUserById(widget.userId);

      if (user == null) {
        throw Exception('User not found');
      }

      // Get user videos - filter from all videos
      final allVideos = ref.read(videosProvider);
      final userVideos =
          allVideos.where((video) => video.userId == widget.userId).toList();

      // Check if current user is following this user
      final currentUserId = ref.read(currentUserIdProvider);
      bool isFollowing = false;
      if (currentUserId != null && currentUserId != widget.userId) {
        isFollowing = ref.read(isUserFollowedProvider(widget.userId));
      }

      if (mounted) {
        setState(() {
          _user = user;
          _userVideos = userVideos;
          _isFollowing = isFollowing;
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
    for (final video in _userVideos) {
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        try {
          // Check if thumbnail is already cached
          final cacheKey = 'thumb_${video.id}';
          final fileInfo =
              await _thumbnailCacheManager.getFileFromCache(cacheKey);

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

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    // Check if user is authenticated
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      final shouldLogin = await requireLogin(
        context,
        ref,
        customTitle: 'Follow User',
        customSubtitle:
            'Sign in to follow ${_user!.name} and see their latest content.',
        customIcon: Icons.person_add,
      );

      if (shouldLogin) {
        // User signed in, reload data
        _loadUserData();
      }
      return;
    }

    try {
      // Update local state first (optimistic update)
      setState(() {
        _isFollowing = !_isFollowing;
      });

      // Update in provider
      await ref.read(authenticationProvider.notifier).followUser(_user!.id);

      // Show feedback
      showSnackBar(
          context,
          _isFollowing
              ? 'Following ${_user!.name}'
              : 'Unfollowed ${_user!.name}');

      // Refresh data to get updated counts
      _loadUserData();
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFollowing = !_isFollowing;
      });

      showSnackBar(
          context, 'Failed to ${_isFollowing ? 'follow' : 'unfollow'} user');
    }
  }

  void _openVideoDetails(VideoModel video) {
    // Navigate to SingleVideoScreen using GoRouter with push to maintain back stack
    context.push(RoutePaths.singleVideo(video.id),
        extra: {'userId': widget.userId});
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: _isLoading
          ? _buildLoadingView(theme)
          : _error != null
              ? _buildErrorView(theme)
              : _buildProfileView(theme, isAuthenticated, isGuest),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension theme) {
    return Center(
      child: CircularProgressIndicator(
        color: theme.primaryColor,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorView(ModernThemeExtension theme) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: theme.textColor,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
                      color: theme.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'User not found',
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This user may have been deleted or doesn\'t exist',
                      style: TextStyle(
                        color: theme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildProfileView(
      ModernThemeExtension theme, bool isAuthenticated, bool isGuest) {
    if (_user == null) {
      return Center(
        child: Text(
          'User not found',
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: theme.backgroundColor,
            elevation: 0,
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 340,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: theme.textColor,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 60,
                      bottom: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.dividerColor!,
                              width: 2,
                            ),
                          ),
                          child: _user!.profileImage.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _user!.profileImage,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    placeholder: (context, url) => Container(
                                      color: theme.surfaceColor,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            theme.primaryColor!,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: theme.surfaceColor,
                                      child: Center(
                                        child: Text(
                                          _user!.name.isNotEmpty
                                              ? _user!.name[0].toUpperCase()
                                              : "U",
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 36,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.surfaceColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _user!.name.isNotEmpty
                                          ? _user!.name[0].toUpperCase()
                                          : "U",
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // User Name and Verification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _user!.name,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_user!.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                color: theme.primaryColor,
                                size: 18,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              _formatCount(_user!.followers),
                              'Followers',
                              theme,
                            ),
                            _buildStatColumn(
                              _formatCount(_user!.following),
                              'Following',
                              theme,
                            ),
                            _buildStatColumn(
                              _formatCount(_user!.likesCount),
                              'Likes',
                              theme,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Follow Button
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            onPressed: _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? theme.surfaceColor
                                  : theme.primaryColor,
                              foregroundColor:
                                  _isFollowing ? theme.textColor : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: _isFollowing
                                    ? BorderSide(color: theme.dividerColor!)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Text(
                              _isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: Column(
        children: [
          // Content Section
          Expanded(
            child: _userVideos.isEmpty
                ? _buildEmptyState(theme, isAuthenticated)
                : GridView.builder(
                    padding: const EdgeInsets.all(1),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 9 / 16, // TikTok-like aspect ratio
                    ),
                    itemCount: _userVideos.length,
                    itemBuilder: (context, index) {
                      final video = _userVideos[index];

                      return GestureDetector(
                        onTap: () => _openVideoDetails(video),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.surfaceColor,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Video Thumbnail
                              if (video.thumbnailUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 600, // Optimize memory usage
                                  placeholder: (context, url) => Container(
                                    color: theme.surfaceColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.primaryColor!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return _buildThumbnailPlaceholder(theme);
                                  },
                                )
                              else if (video.isMultipleImages &&
                                  video.imageUrls.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: video.imageUrls.first,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 600, // Optimize memory usage
                                  placeholder: (context, url) => Container(
                                    color: theme.surfaceColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.primaryColor!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return _buildThumbnailPlaceholder(theme);
                                  },
                                )
                              else if (!video.isMultipleImages &&
                                  _videoThumbnails.containsKey(video.id))
                                Image.file(
                                  File(_videoThumbnails[video.id]!),
                                  fit: BoxFit.cover,
                                )
                              else
                                _buildThumbnailPlaceholder(theme),

                              // Multiple Images Indicator
                              if (video.isMultipleImages &&
                                  video.imageUrls.length > 1)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.collections,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),

                              // View Count
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatCount(video.views),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String count, String label, ModernThemeExtension theme) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme, bool isAuthenticated) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: theme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No videos yet',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This user hasn\'t shared any videos yet',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),

          // Show sign-in prompt for guests
          if (!isAuthenticated) ...[
            const SizedBox(height: 24),
            const InlineLoginRequiredWidget(
              title: 'Join the Community',
              subtitle:
                  'Sign in to follow creators and discover amazing content.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(ModernThemeExtension theme) {
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: theme.primaryColor,
          size: 32,
        ),
      ),
    );
  }
}
