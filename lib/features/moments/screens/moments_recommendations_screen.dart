// lib/features/moments/screens/moments_recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MomentsRecommendationsScreen extends ConsumerStatefulWidget {
  const MomentsRecommendationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MomentsRecommendationsScreen> createState() => _MomentsRecommendationsScreenState();
}

class _MomentsRecommendationsScreenState extends ConsumerState<MomentsRecommendationsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85, // Shows part of adjacent pages
  );
  
  // Cache for recommended moments to avoid reloading
  List<MomentModel> _recommendedMoments = [];
  bool _isLoadingRecommendations = false;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Don't load moments immediately - wait for auth state
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load recommended moments efficiently
  /// This method selects moments from contacts and public moments with recent activity
  Future<void> _loadRecommendedMoments({bool forceRefresh = false}) async {
    if (_isLoadingRecommendations && !forceRefresh) return;

    setState(() {
      _isLoadingRecommendations = true;
      _error = null;
      if (forceRefresh) _recommendedMoments.clear();
    });

    try {
      // Wait for authentication state to be available
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) {
        throw Exception('Please sign in to view moments');
      }

      // Get moments directly from repository
      final repository = ref.read(momentsRepositoryProvider);
      final momentsStream = repository.getMomentsStream(currentUser.uid, currentUser.contactsUIDs);
      
      // Listen to the first emission from the stream
      final moments = await momentsStream.first;
      
      if (moments.isNotEmpty) {
        // Filter and sort moments for recommendations
        final activeMoments = moments
            .where((moment) => moment.isActive && !moment.isExpired)
            .toList();

        // Sort by creation time (most recent first) and apply recommendation logic
        activeMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Apply recommendation algorithm
        final List<MomentModel> recommendedMoments = [];
        
        // 1. Prioritize moments from contacts with high engagement
        final contactMoments = activeMoments
            .where((moment) => 
                currentUser.contactsUIDs.contains(moment.authorId) &&
                (moment.likesCount > 0 || moment.commentsCount > 0 || moment.viewsCount > 5))
            .take(15)
            .toList();
        recommendedMoments.addAll(contactMoments);

        // 2. Add recent public moments with high engagement
        final publicMoments = activeMoments
            .where((moment) => 
                moment.privacy == MomentPrivacy.public &&
                !recommendedMoments.contains(moment) &&
                (moment.likesCount > 2 || moment.commentsCount > 1 || moment.viewsCount > 10))
            .take(10)
            .toList();
        recommendedMoments.addAll(publicMoments);

        // 3. Fill with recent moments from contacts (even with low engagement)
        final recentContactMoments = activeMoments
            .where((moment) => 
                currentUser.contactsUIDs.contains(moment.authorId) &&
                !recommendedMoments.contains(moment))
            .take(10)
            .toList();
        recommendedMoments.addAll(recentContactMoments);

        // 4. Add some trending public moments
        final trendingPublicMoments = activeMoments
            .where((moment) => 
                moment.privacy == MomentPrivacy.public &&
                !recommendedMoments.contains(moment))
            .take(5)
            .toList();
        recommendedMoments.addAll(trendingPublicMoments);

        // Limit total recommendations for performance
        final maxTotalMoments = 50;
        final finalRecommendations = recommendedMoments.take(maxTotalMoments).toList();

        if (mounted) {
          setState(() {
            _recommendedMoments = finalRecommendations;
            _isLoadingRecommendations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recommendedMoments = [];
            _isLoadingRecommendations = false;
          });
        }
      }

    } catch (e) {
      debugPrint('Error loading moment recommendations: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state
    final authState = ref.watch(authenticationProvider);
    
    return Scaffold(
      backgroundColor: context.modernTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: authState.when(
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildAuthErrorState(error.toString()),
            data: (authData) {
              // Check if user is authenticated
              if (authData.userModel == null) {
                return _buildNotAuthenticatedState();
              }
              
              // User is authenticated, now show moments
              return _buildAuthenticatedBody();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedBody() {
    // Load moments when we know user is authenticated
    if (_recommendedMoments.isEmpty && !_isLoadingRecommendations && _error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecommendedMoments();
      });
    }
    
    if (_isLoadingRecommendations && _recommendedMoments.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _recommendedMoments.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_recommendedMoments.isEmpty && !_isLoadingRecommendations) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecommendedMoments(forceRefresh: true),
      backgroundColor: context.modernTheme.surfaceColor,
      color: context.modernTheme.textColor,
      child: Column(
        children: [
          // Page indicator dots
          if (_recommendedMoments.isNotEmpty) _buildPageIndicator(),
          
          // Main carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _recommendedMoments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                  child: _buildMomentThumbnail(_recommendedMoments[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticatedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 64,
            color: context.modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in required',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in to view moments',
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, 
              Constants.landingScreen, 
              (route) => false,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Error',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(authenticationProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _recommendedMoments.length > 10 ? 10 : _recommendedMoments.length, // Limit dots to 10
          (index) {
            // For more than 10 items, show relative position
            int displayIndex = _recommendedMoments.length > 10 
                ? (_currentIndex < 5 ? index : (_currentIndex > _recommendedMoments.length - 6 ? index + _recommendedMoments.length - 10 : index + _currentIndex - 4))
                : index;
            
            bool isActive = displayIndex == _currentIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              height: 6.0,
              width: isActive ? 20.0 : 6.0,
              decoration: BoxDecoration(
                color: isActive 
                    ? context.modernTheme.textColor 
                    : context.modernTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(3.0),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMomentThumbnail(MomentModel moment, int index) {
    // Calculate scale based on current page position
    double scale = 1.0;
    if (_pageController.hasClients && _pageController.page != null) {
      scale = 1.0 - ((_pageController.page! - index).abs() * 0.1).clamp(0.0, 0.3);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: () => _navigateToMomentsFeed(moment),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main thumbnail
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Main thumbnail content
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: _buildThumbnailContent(moment),
                      ),
                      
                      // Gradient overlay for caption and stats
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
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                moment.content.isNotEmpty ? moment.content : 'Moment by ${moment.authorName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatCount(moment.likesCount)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatCount(moment.viewsCount)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Time remaining indicator
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                moment.timeRemainingText,
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

                      // Privacy indicator
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPrivacyIcon(moment.privacy),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Author info outside thumbnail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: moment.authorImage.isNotEmpty
                        ? NetworkImage(moment.authorImage)
                        : null,
                    backgroundColor: context.modernTheme.surfaceVariantColor,
                    child: moment.authorImage.isEmpty
                        ? Text(
                            moment.authorName.isNotEmpty 
                                ? moment.authorName[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              color: context.modernTheme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.authorName,
                          style: TextStyle(
                            color: context.modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(moment.createdAt),
                          style: TextStyle(
                            color: context.modernTheme.textSecondaryColor,
                            fontSize: 12,
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
    );
  }

  Widget _buildThumbnailContent(MomentModel moment) {
    if (moment.hasVideo && moment.videoThumbnail != null) {
      return Stack(
        children: [
          Image.network(
            moment.videoThumbnail!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingThumbnail();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildVideoThumbnailFromUrl(moment);
            },
          ),
          // Play icon overlay for videos
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      );
    } else if (moment.hasVideo && moment.videoUrl != null) {
      return _buildVideoThumbnailFromUrl(moment);
    } else if (moment.hasImages && moment.imageUrls.isNotEmpty) {
      return Stack(
        children: [
          Image.network(
            moment.imageUrls.first,
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
          ),
          // Multiple images indicator
          if (moment.imageUrls.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
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
                      '${moment.imageUrls.length}',
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
      );
    } else if (moment.content.isNotEmpty) {
      // Text-only moment
      return Container(
        color: context.modernTheme.primaryColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              moment.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    } else {
      return _buildErrorThumbnail();
    }
  }

  Widget _buildVideoThumbnailFromUrl(MomentModel moment) {
    return FutureBuilder<Uint8List?>(
      future: _generateVideoThumbnail(moment.videoUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingThumbnail();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Stack(
            children: [
              Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Play icon overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        
        return _buildErrorThumbnail();
      },
    );
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
      debugPrint('Error generating video thumbnail: $e');
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
          Icons.photo_library,
          color: context.modernTheme.textSecondaryColor,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.modernTheme.textColor),
          const SizedBox(height: 16),
          Text(
            'Loading moments...',
            style: TextStyle(color: context.modernTheme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadRecommendedMoments(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: context.modernTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No moments available',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or follow others to see moments',
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Constants.createMomentScreen),
            icon: const Icon(Icons.add),
            label: const Text('Create Moment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Fixed navigation method to properly pass the startMomentId
  void _navigateToMomentsFeed(MomentModel moment) {
    Navigator.pushNamed(
      context,
      Constants.momentsFeedScreen,
      arguments: {'startMomentId': moment.id}, // Pass as Map
    );
  }

  IconData _getPrivacyIcon(MomentPrivacy privacy) {
    switch (privacy) {
      case MomentPrivacy.public:
        return Icons.public;
      case MomentPrivacy.contacts:
        return Icons.contacts;
      case MomentPrivacy.selectedContacts:
        return Icons.people;
      case MomentPrivacy.exceptSelected:
        return Icons.people_outline;
    }
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