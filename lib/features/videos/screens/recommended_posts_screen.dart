// lib/features/channels/screens/recommended_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class RecommendedPostsScreen extends ConsumerStatefulWidget {
  const RecommendedPostsScreen({super.key});

  @override
  ConsumerState<RecommendedPostsScreen> createState() => _RecommendedPostsScreenState();
}

class _RecommendedPostsScreenState extends ConsumerState<RecommendedPostsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85, // Shows part of adjacent pages
  );
  
  // Cache for recommended videos to avoid reloading
  List<VideoModel> _recommendedVideos = [];
  bool _isLoadingRecommendations = false;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load recommended videos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendedVideos();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load recommended videos efficiently
  /// This method loads featured videos from the backend
  Future<void> _loadRecommendedVideos({bool forceRefresh = false}) async {
    if (_isLoadingRecommendations && !forceRefresh) return;

    setState(() {
      _isLoadingRecommendations = true;
      _error = null;
      if (forceRefresh) _recommendedVideos.clear();
    });

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      
      // Get current state
      final authState = ref.read(authenticationProvider);
      final currentAuthState = authState.valueOrNull;
      
      // If no data and not forcing refresh, try to load it
      if (currentAuthState == null || currentAuthState.videos.isEmpty) {
        debugPrint('📹 No videos in state, loading from backend...');
        
        // Force refresh data if needed
        await authNotifier.loadVideos();
        await authNotifier.loadUsers();
        
        // Get updated state after loading
        final updatedAuthState = ref.read(authenticationProvider).valueOrNull;
        if (updatedAuthState == null) {
          throw Exception('Authentication state not available after loading');
        }
        
        // Use updated state
        _processVideos(updatedAuthState.videos);
      } else {
        // Force refresh if requested
        if (forceRefresh) {
          debugPrint('🔄 Force refreshing videos from backend...');
          await authNotifier.loadVideos();
          await authNotifier.loadUsers();
          
          final updatedAuthState = ref.read(authenticationProvider).valueOrNull;
          if (updatedAuthState != null) {
            _processVideos(updatedAuthState.videos);
          } else {
            _processVideos(currentAuthState.videos);
          }
        } else {
          // Use existing state
          _processVideos(currentAuthState.videos);
        }
      }

    } catch (e) {
      debugPrint('❌ Error loading recommendations: $e');
      setState(() {
        _error = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }

  /// Extract video processing logic into separate method
  void _processVideos(List<VideoModel> allVideos) {
    if (allVideos.isEmpty) {
      setState(() {
        _recommendedVideos = [];
        _isLoadingRecommendations = false;
      });
      return;
    }

    // Filter featured videos
    final featuredVideos = allVideos
        .where((video) => video.isFeatured)
        .toList();

    // Sort by creation time (most recent first)
    featuredVideos.sort((a, b) => b.createdAtDateTime.compareTo(a.createdAtDateTime));

    // Limit to 9 featured videos
    const maxTotalVideos = 9;
    final finalRecommendations = featuredVideos.take(maxTotalVideos).toList();

    setState(() {
      _recommendedVideos = finalRecommendations;
      _isLoadingRecommendations = false;
    });
    
    debugPrint('✅ Processed ${_recommendedVideos.length} featured videos');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    // Listen to authentication provider changes and reload when data becomes available
    ref.listen<AsyncValue<AuthenticationState>>(
      authenticationProvider,
      (previous, next) {
        next.whenData((authState) {
          // When auth state updates with new videos, reload recommendations if needed
          if (authState.videos.isNotEmpty && 
              _recommendedVideos.isEmpty && 
              !_isLoadingRecommendations) {
            debugPrint('🔄 Auth state updated with videos, reloading recommendations');
            _loadRecommendedVideos();
          }
        });
      },
    );
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = context.modernTheme;
    
    if (_isLoadingRecommendations && _recommendedVideos.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _recommendedVideos.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_recommendedVideos.isEmpty && !_isLoadingRecommendations) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecommendedVideos(forceRefresh: true),
      backgroundColor: theme.surfaceColor,
      color: theme.primaryColor,
      child: Column(
        children: [
          // Page indicator dots with enhanced styling
          if (_recommendedVideos.isNotEmpty) _buildPageIndicator(),
          
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
                itemCount: _recommendedVideos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                    child: _buildVideoThumbnail(_recommendedVideos[index], index),
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
          _recommendedVideos.length,
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
              // Main thumbnail with enhanced styling
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
                    // Enhanced avatar with styling from users list
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
                    
                    // Enhanced user info with bio
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
                          Text(
                            _getUserBio(video.userId),
                            style: TextStyle(
                              color: theme.textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  String _getUserBio(String userId) {
    final authState = ref.read(authenticationProvider);
    final currentAuthState = authState.valueOrNull;
    if (currentAuthState == null) return 'No bio available';
    
    try {
      final user = currentAuthState.users.firstWhere(
        (user) => user.uid == userId,
      );
      return user.bio.isNotEmpty ? user.bio : 'No bio available';
    } catch (e) {
      return 'No bio available';
    }
  }

  Widget _buildThumbnailContent(VideoModel video) {
    // Use backend thumbnail for all content types
    if (video.thumbnailUrl.isNotEmpty) {
      return Image.network(
        video.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingThumbnail();
        },
        errorBuilder: (context, error, stackTrace) {
          // Fallback to first image if thumbnail fails and it's an image post
          if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
            return Image.network(
              video.imageUrls.first,
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
    }
    
    // Fallback: if no thumbnail, use first image for image posts
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
    }
    
    // No valid content
    return _buildErrorThumbnail();
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
              'Loading...',
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
                onTap: () => _loadRecommendedVideos(forceRefresh: true),
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
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.video_library_outlined,
                color: theme.primaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No recommendations available',
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
                  // Navigate to videos feed screen
                  context.push(RoutePaths.videosFeed);
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
                        'Explore Posts',
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
    context.push(
      RoutePaths.videosFeed,
      extra: {
        'startVideoId': video.id,
        'userId': video.userId,
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

/// Helper class for scoring videos during recommendation calculation
class _ScoredVideo {
  final VideoModel video;
  final double score;
  final UserModel user;

  _ScoredVideo({
    required this.video,
    required this.score,
    required this.user,
  });

  @override
  String toString() {
    return '_ScoredVideo(videoId: ${video.id}, score: ${score.toStringAsFixed(2)}, user: ${user.name})';
  }
}