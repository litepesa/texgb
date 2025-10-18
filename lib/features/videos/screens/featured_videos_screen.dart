// lib/features/videos/screens/featured_videos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class FeaturedVideosScreen extends ConsumerStatefulWidget {
  const FeaturedVideosScreen({super.key});

  @override
  ConsumerState<FeaturedVideosScreen> createState() => _FeaturedVideosScreenState();
}

class _FeaturedVideosScreenState extends ConsumerState<FeaturedVideosScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep screen alive when switching tabs
  
  final PageController _pageController = PageController(
    viewportFraction: 0.85, // Shows part of adjacent pages
  );
  
  // Cache for featured videos to avoid reloading
  List<VideoModel> _featuredVideos = [];
  bool _isLoadingFeatured = false;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeaturedVideos(forceRefresh: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadFeaturedVideos();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load featured videos efficiently
  /// This method selects videos marked as featured from the available videos
  Future<void> _loadFeaturedVideos({bool forceRefresh = false}) async {
    if (_isLoadingFeatured && !forceRefresh) return;

    setState(() {
      _isLoadingFeatured = true;
      _error = null;
      if (forceRefresh) _featuredVideos.clear();
    });

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      
      // Force refresh data if needed
      if (forceRefresh) {
        await authNotifier.loadVideos();
        await authNotifier.loadUsers();
      }

      // Get current state
      final authState = ref.read(authenticationProvider);
      final currentAuthState = authState.value;
      
      if (currentAuthState == null) {
        throw Exception('Authentication state not available');
      }

      // Step 1: Get all videos
      final allVideos = currentAuthState.videos;
      
      if (allVideos.isEmpty) {
        setState(() {
          _featuredVideos = [];
          _isLoadingFeatured = false;
        });
        return;
      }

      // Step 2: Filter videos that are marked as featured
      final featuredVideos = allVideos
          .where((video) => video.isFeatured && video.isActive)
          .toList();

      // Step 3: Sort featured videos by creation time (most recent first)
      featuredVideos.sort((a, b) => b.createdAtDateTime.compareTo(a.createdAtDateTime));

      // Step 4: Limit total featured videos for performance
      final maxFeaturedVideos = 20; // Maximum featured videos to show
      final finalFeaturedVideos = featuredVideos.take(maxFeaturedVideos).toList();

      setState(() {
        _featuredVideos = finalFeaturedVideos;
        _isLoadingFeatured = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingFeatured = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final theme = context.modernTheme;
    
    // Watch for video data changes and refresh automatically
    ref.listen(videosProvider, (previous, next) {
      if (mounted && previous != next) {
        Future.microtask(() => _loadFeaturedVideos());
      }
    });
    
    // Load immediately if we don't have data
    if (_featuredVideos.isEmpty && !_isLoadingFeatured && _error == null) {
      Future.microtask(() => _loadFeaturedVideos(forceRefresh: true));
    }
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = context.modernTheme;
    
    if (_isLoadingFeatured && _featuredVideos.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _featuredVideos.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_featuredVideos.isEmpty && !_isLoadingFeatured) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadFeaturedVideos(forceRefresh: true),
      backgroundColor: theme.surfaceColor,
      color: theme.primaryColor,
      child: Column(
        children: [
          // Page indicator dots with enhanced styling
          if (_featuredVideos.isNotEmpty) _buildPageIndicator(),
          
          // Main carousel with enhanced container
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _featuredVideos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                    child: _buildVideoThumbnail(_featuredVideos[index], index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final theme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _featuredVideos.length,
          (index) {
            bool isActive = index == _currentIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8.0,
              width: isActive ? 24.0 : 8.0,
              decoration: BoxDecoration(
                color: isActive 
                    ? theme.primaryColor 
                    : theme.textSecondaryColor!.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ] : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(VideoModel video, int index) {
    final theme = context.modernTheme;
    
    // Calculate scale based on current page position
    double scale = 1.0;
    if (_pageController.hasClients && _pageController.page != null) {
      scale = 1.0 - ((_pageController.page! - index).abs() * 0.1).clamp(0.0, 0.3);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: () => _navigateToVideoFeed(video),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor!.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor!.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main thumbnail with enhanced styling and featured badge
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Main thumbnail content
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: _buildThumbnailContent(video),
                        ),
                        
                        // Featured badge at top-right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Enhanced gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  video.caption.isNotEmpty ? video.caption : 'No caption',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_formatCount(video.views)} views',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_formatCount(video.likes)} likes',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Enhanced User info section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: [
                    // Enhanced avatar with styling
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.dividerColor!.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor!.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: video.userImage.isNotEmpty
                                ? Image.network(
                                    video.userImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor!.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            video.userName.isNotEmpty 
                                                ? video.userName[0].toUpperCase()
                                                : "U",
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor!.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        video.userName.isNotEmpty 
                                            ? video.userName[0].toUpperCase()
                                            : "U",
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 14),
                    
                    // Enhanced user info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.userName,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.surfaceVariantColor!.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor!.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 14,
                                  color: theme.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_formatCount(_getUserFollowers(video.userId))} followers',
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getUserFollowers(String userId) {
    final authState = ref.read(authenticationProvider);
    final currentAuthState = authState.value;
    if (currentAuthState == null) return 0;
    
    try {
      final user = currentAuthState.users.firstWhere(
        (user) => user.uid == userId,
      );
      return user.followers;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildThumbnailContent(VideoModel video) {
    if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
      return Image.network(
        video.imageUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingThumbnail();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorThumbnail();
        },
      );
    } else if (video.videoUrl.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _generateVideoThumbnail(video.videoUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingThumbnail();
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          }
          
          if (video.thumbnailUrl.isNotEmpty) {
            return Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorThumbnail();
              },
            );
          }
          
          return _buildErrorThumbnail();
        },
      );
    } else {
      return _buildErrorThumbnail();
    }
  }

  Future<Uint8List?> _generateVideoThumbnail(String videoUrl) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
        timeMs: 1000,
      );
      return thumbnail;
    } catch (e) {
      return null;
    }
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      color: context.modernTheme.surfaceVariantColor,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: context.modernTheme.textColor,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: context.modernTheme.surfaceVariantColor,
      child: Center(
        child: Icon(
          Icons.video_library,
          color: context.modernTheme.textSecondaryColor,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = context.modernTheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor!.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor!.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading featured videos...',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = context.modernTheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor!.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor!.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _loadFeaturedVideos(forceRefresh: true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.modernTheme;
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor!.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor!.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.star_outline,
                color: Colors.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No featured videos yet',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for featured content',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  // Navigate to Videos Feed Screen
                  Navigator.pushNamed(context, Constants.videosFeedScreen);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor!.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Explore Videos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToVideoFeed(VideoModel video) {
    Navigator.pushNamed(
      context,
      Constants.videosFeedScreen,
      arguments: {
        Constants.startVideoId: video.id,
        Constants.userId: video.userId, 
      },
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}