// lib/features/users/screens/my_profile_screen.dart
// FIXED: Null-safe theme access with fallback values
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/features/users/widgets/verification_widget.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isRefreshing = false;
  UserModel? _user;
  List<VideoModel> _userVideos = [];
  String? _error;
  final Map<String, String> _videoThumbnails = {};
  bool _hasNoProfile = false;
  bool _isInitialized = false;

  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'userVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ?? 
        ModernThemeExtension(
          primaryColor: const Color(0xFFFE2C55),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // NEW: Initialize screen with cached data first
  void _initializeScreen() {
    final currentUser = ref.read(currentUserProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!isAuthenticated || currentUser == null) {
      setState(() {
        _hasNoProfile = true;
        _isInitialized = true;
      });
      return;
    }

    // Use cached data immediately
    final videos = ref.read(videosProvider);
    final userVideos = videos
        .where((video) => video.userId == currentUser.uid)
        .take(1)
        .toList();

    setState(() {
      _user = currentUser;
      _userVideos = userVideos;
      _isInitialized = true;
    });

    // Generate thumbnail for cached video if available
    if (_userVideos.isNotEmpty) {
      _generateVideoThumbnail();
    }
  }

  // UPDATED: Only called by pull-to-refresh
  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Check if user is authenticated
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isRefreshing = false;
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
            _isRefreshing = false;
          });
        }
        return;
      }

      // Get user's videos (limited to recent 1 for profile preview)
      await authNotifier.loadVideos();
      await authNotifier.loadUserVideos(freshUserProfile.uid);

      final videos = ref.read(videosProvider);
      final userVideos = videos
          .where((video) => video.userId == freshUserProfile.uid)
          .take(1)
          .toList();

      if (mounted) {
        setState(() {
          _user = freshUserProfile;
          _userVideos = userVideos;
          _isRefreshing = false;
        });

        // Generate thumbnail only for the single post
        _generateVideoThumbnail();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  // Generate thumbnail only for single post
  Future<void> _generateVideoThumbnail() async {
    if (_userVideos.isEmpty) return;
    
    final video = _userVideos.first;
    if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
      try {
        final cacheKey = 'thumb_${video.id}';
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
        debugPrint('Error generating thumbnail for video ${video.id}: $e');
      }
    }
  }

  void _editProfile() {
    if (_user == null) return;

    Navigator.pushNamed(
      context,
      Constants.editProfileScreen,
      arguments: _user,
    ).then((_) => _refreshUserData()); // Refresh after edit
  }

  void _openVideoDetails(VideoModel video) {
    Navigator.pushNamed(
      context,
      Constants.myPostScreen,
      arguments: {
        Constants.videoId: video.id,
        Constants.videoModel: video,
      },
    ).then((_) => _refreshUserData()); // Refresh when coming back
  }

  void _navigateToManagePosts() {
    Navigator.pushNamed(
      context,
      Constants.managePostsScreen,
    ).then((_) => _refreshUserData()); // Refresh when coming back
  }

  // ENHANCED: Profile creation callback with cache clearing
  void _onProfileCreated() async {
    debugPrint('Profile created, refreshing data...');

    // Clear any cached network images
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(_user!.profileImage);
    }

    // Clear thumbnail cache
    await _thumbnailCacheManager.emptyCache();

    // Force refresh authentication state to get latest user data
    final authNotifier = ref.read(authenticationProvider.notifier);
    await authNotifier.loadUserDataFromSharedPreferences();

    // Reload the screen data after profile creation
    await _refreshUserData();

    debugPrint('Profile data refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = _getSafeTheme(context);

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: !_isInitialized
          ? _buildLoadingView(modernTheme)
          : _hasNoProfile
              ? _buildProfileRequiredView(modernTheme)
              : _error != null
                  ? _buildErrorView(modernTheme)
                  : _buildProfileView(modernTheme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor ?? Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRequiredView(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: const LoginRequiredWidget(
        title: 'Sign In Required',
        subtitle: 'Please sign in to view your profile and manage your content.',
        actionText: 'Sign In',
        icon: Icons.person,
      ),
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
                color: modernTheme.textColor ?? Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
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

  Widget _buildProfileView(ModernThemeExtension modernTheme) {
    if (_user == null) {
      return const Center(child: Text('Profile not found'));
    }

    return RefreshIndicator(
      onRefresh: _refreshUserData,
      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
      backgroundColor: modernTheme.surfaceColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content fits
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(modernTheme),

            // Profile Info Card
            _buildProfileInfoCard(modernTheme),

            // Quick Actions Section
            _buildQuickActionsSection(modernTheme),

            // Bottom padding for navigation
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Rest of the methods with safe theme access...
  Widget _buildProfileHeader(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFE2C55),
            Color(0xFFFE2C55).withOpacity(0.8),
            Color(0xFFFE2C55).withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Add safe area padding at the top
          SizedBox(height: MediaQuery.of(context).padding.top),

          // App bar with theme switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - placeholder for symmetry
                const SizedBox(width: 40),

                // Center - Profile title
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                // Right side - Theme switcher
                GestureDetector(
                  onTap: () => showThemeSelector(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.brightness_6,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              children: [
                // Profile Image with enhanced R2 handling
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow effect
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _user!.profileImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _user!.profileImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, error, stackTrace) {
                                  debugPrint('Failed to load profile image: ${_user!.profileImage}');
                                  debugPrint('Error: $error');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                memCacheWidth: 110,
                                memCacheHeight: 110,
                                maxWidthDiskCache: 220,
                                maxHeightDiskCache: 220,
                                httpHeaders: const {
                                  'User-Agent': 'WeiBao-App/1.0',
                                },
                                cacheKey: _user!.profileImage,
                                imageBuilder: (context, imageProvider) {
                                  debugPrint('Profile image loaded successfully: ${_user!.profileImage}');
                                  return Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // User name
                Text(
                  _user!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // User bio
                if (_user!.bio.isNotEmpty)
                  Text(
                    _user!.bio,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 20),

                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Verification status button
                    GestureDetector(
                      onTap: () => VerificationInfoWidget.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _user!.isVerified
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF0D47A1),
                                    Color(0xFF0A1E3D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF1565C0),
                                    Color(0xFF0D47A1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: _user!.isVerified
                                  ? const Color(0xFF1565C0).withOpacity(0.4)
                                  : const Color(0xFF1976D2).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _user!.isVerified
                                  ? Icons.verified_rounded
                                  : Icons.star_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _user!.isVerified ? 'Verified' : 'Get Verified',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Edit Profile Button
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFE2C55).withOpacity(0.6),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                _user!.videosCount.toString(),
                'Posts',
                Icons.video_library,
                modernTheme,
              ),
              _buildStatItem(
                _user!.followers.toString(),
                'Followers',
                Icons.people,
                modernTheme,
              ),
              _buildStatItem(
                _user!.following.toString(),
                'Following',
                Icons.person_add,
                modernTheme,
              ),
              _buildStatItem(
                _user!.likesCount.toString(),
                'Likes',
                Icons.favorite,
                modernTheme,
              ),
            ],
          ),

          // Tags
          if (_user!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _user!.tags.length,
                itemBuilder: (context, index) {
                  final tag = _user!.tags[index];
                  return Container(
                    margin: EdgeInsets.only(right: index < _user!.tags.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
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
          color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: modernTheme.textColor ?? Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor ?? Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Manage Posts Button - Primary Action
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _navigateToManagePosts,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dashboard,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Manage Posts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Post Button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, Constants.createPostScreen),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for time ago formatting
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}