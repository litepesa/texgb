// lib/features/moments/screens/moments_recommendations_screen.dart - Updated with user grouping
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
  
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state and user-grouped moments
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
              
              // User is authenticated, show grouped moments
              return _buildAuthenticatedBody();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedBody() {
    final userGroupsStream = ref.watch(userGroupedMomentsStreamProvider);
    
    return userGroupsStream.when(
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(error.toString()),
      data: (userGroups) {
        if (userGroups.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userGroupedMomentsStreamProvider);
          },
          backgroundColor: context.modernTheme.surfaceColor,
          color: context.modernTheme.textColor,
          child: Column(
            children: [
              // Page indicator dots
              if (userGroups.isNotEmpty) _buildPageIndicator(userGroups.length),
              
              // Main carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: userGroups.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: _buildUserMomentThumbnail(userGroups[index], index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildPageIndicator(int totalItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalItems > 10 ? 10 : totalItems, // Limit dots to 10
          (index) {
            // For more than 10 items, show relative position
            int displayIndex = totalItems > 10 
                ? (_currentIndex < 5 ? index : (_currentIndex > totalItems - 6 ? index + totalItems - 10 : index + _currentIndex - 4))
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

  Widget _buildUserMomentThumbnail(UserMomentGroup userGroup, int index) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();
    
    // Calculate scale based on current page position
    double scale = 1.0;
    if (_pageController.hasClients && _pageController.page != null) {
      scale = 1.0 - ((_pageController.page! - index).abs() * 0.1).clamp(0.0, 0.3);
    }

    // Get the moment to display as thumbnail
    final thumbnailMoment = userGroup.getThumbnailMoment(currentUser.uid);
    if (thumbnailMoment == null) return const SizedBox.shrink();
    
    // Check if user has unviewed moments for ring indicator
    final hasUnviewedMoments = userGroup.hasUnviewedMoments(currentUser.uid);

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: () => _navigateToUserMoments(userGroup),
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
                        child: _buildThumbnailContent(thumbnailMoment),
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
                                thumbnailMoment.content.isNotEmpty 
                                    ? thumbnailMoment.content 
                                    : 'Moment by ${thumbnailMoment.authorName}',
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
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${userGroup.activeMomentsCount} posts',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatCount(thumbnailMoment.likesCount)}',
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


                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Author info outside thumbnail with ring
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Profile picture with ring indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnviewedMoments 
                            ? context.modernTheme.primaryColor! 
                            : context.modernTheme.dividerColor!,
                        width: hasUnviewedMoments ? 2.5 : 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: userGroup.userImage.isNotEmpty
                            ? Image.network(
                                userGroup.userImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: context.modernTheme.surfaceVariantColor,
                                  child: Icon(
                                    Icons.person,
                                    color: context.modernTheme.textColor,
                                    size: 16,
                                  ),
                                ),
                              )
                            : Container(
                                color: context.modernTheme.surfaceVariantColor,
                                child: Icon(
                                  Icons.person,
                                  color: context.modernTheme.textColor,
                                  size: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userGroup.userName,
                          style: TextStyle(
                            color: context.modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userGroup.latestMomentTime,
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
            onPressed: () => ref.invalidate(userGroupedMomentsStreamProvider),
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

  // Navigation method to show user's unviewed moments first
  void _navigateToUserMoments(UserMomentGroup userGroup) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    // Get the first unviewed moment ID to start viewing from
    final unviewedMoments = userGroup.getUnviewedMoments(currentUser.uid);
    String? startMomentId;
    
    if (unviewedMoments.isNotEmpty) {
      // Start with first unviewed moment
      startMomentId = unviewedMoments.first.id;
    } else {
      // If all viewed, start with latest moment
      startMomentId = userGroup.latestMoment?.id;
    }
    
    Navigator.pushNamed(
      context,
      Constants.momentsFeedScreen,
      arguments: {
        'startMomentId': startMomentId,
        'prioritizeUser': userGroup.userId, // NEW: Prioritize this user's content
      },
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
}