// lib/features/moments/screens/my_moments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/constants.dart';

class MyMomentsScreen extends ConsumerStatefulWidget {
  const MyMomentsScreen({super.key});

  @override
  ConsumerState<MyMomentsScreen> createState() => _MyMomentsScreenState();
}

class _MyMomentsScreenState extends ConsumerState<MyMomentsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: context.modernTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.modernTheme.appBarColor,
          elevation: 0,
          title: Text(
            'My Moments',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text('Please login to view your moments'),
        ),
      );
    }

    final userMomentsStream = ref.watch(userMomentsStreamProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: context.modernTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.modernTheme.appBarColor,
        elevation: 0,
        title: Text(
          'My Moments',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: context.modernTheme.textColor,
            ),
            onPressed: () => Navigator.pushNamed(context, Constants.createMomentScreen),
          ),
        ],
      ),
      body: userMomentsStream.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
        data: (moments) => _buildMomentsList(moments),
      ),
    );
  }

  Widget _buildMomentsList(List<MomentModel> moments) {
    if (moments.isEmpty) {
      return _buildEmptyState();
    }

    // Separate active and expired moments
    final activeMoments = moments.where((m) => m.isActive && !m.isExpired).toList();
    final expiredMoments = moments.where((m) => !m.isActive || m.isExpired).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userMomentsStreamProvider(ref.read(currentUserProvider)!.uid));
      },
      backgroundColor: context.modernTheme.surfaceColor,
      color: context.modernTheme.primaryColor,
      child: CustomScrollView(
        slivers: [
          // Active moments section
          if (activeMoments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Active Moments (${activeMoments.length})',
                  style: TextStyle(
                    color: context.modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMomentCard(activeMoments[index], isActive: true),
                  childCount: activeMoments.length,
                ),
              ),
            ),
          ],

          // Expired moments section
          if (expiredMoments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Text(
                  'Expired Moments (${expiredMoments.length})',
                  style: TextStyle(
                    color: context.modernTheme.textSecondaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMomentCard(expiredMoments[index], isActive: false),
                  childCount: expiredMoments.length,
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentCard(MomentModel moment, {required bool isActive}) {
    return GestureDetector(
      onTap: isActive ? () => _viewMoment(moment) : null,
      onLongPress: () => _showMomentOptions(moment),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.modernTheme.backgroundColor,
          border: Border.all(
            color: isActive 
                ? context.modernTheme.borderColor!
                : context.modernTheme.textSecondaryColor!.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: context.modernTheme.surfaceVariantColor,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      // Main content
                      Positioned.fill(
                        child: _buildThumbnailContent(moment, isActive),
                      ),

                      // Overlay for expired moments
                      if (!isActive)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.access_time_filled,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),

                      // Status indicator
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isActive ? 'Active' : 'Expired',
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

                      // Time remaining/expired indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? moment.timeRemainingText : 'Expired',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Moment details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.content.isNotEmpty)
                    Text(
                      moment.content,
                      style: TextStyle(
                        color: isActive 
                            ? context.modernTheme.textColor
                            : context.modernTheme.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  if (moment.content.isNotEmpty) const SizedBox(height: 8),
                  
                  // Stats row
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: isActive 
                            ? context.modernTheme.textSecondaryColor
                            : context.modernTheme.textTertiaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${moment.likesCount}',
                        style: TextStyle(
                          color: isActive 
                              ? context.modernTheme.textSecondaryColor
                              : context.modernTheme.textTertiaryColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: isActive 
                            ? context.modernTheme.textSecondaryColor
                            : context.modernTheme.textTertiaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${moment.viewsCount}',
                        style: TextStyle(
                          color: isActive 
                              ? context.modernTheme.textSecondaryColor
                              : context.modernTheme.textTertiaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    timeago.format(moment.createdAt),
                    style: TextStyle(
                      color: isActive 
                          ? context.modernTheme.textTertiaryColor
                          : context.modernTheme.textSecondaryColor?.withOpacity(0.7),
                      fontSize: 11,
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

  Widget _buildThumbnailContent(MomentModel moment, bool isActive) {
    final opacity = isActive ? 1.0 : 0.6;
    
    if (moment.hasVideo) {
      return FutureBuilder<Uint8List?>(
        future: _generateVideoThumbnail(moment.videoUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingThumbnail();
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return Opacity(
              opacity: opacity,
              child: Stack(
                children: [
                  Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  // Play icon
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return _buildErrorThumbnail();
        },
      );
    } else if (moment.hasImages) {
      return Opacity(
        opacity: opacity,
        child: Stack(
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
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 10,
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
        ),
      );
    } else if (moment.content.isNotEmpty) {
      // Text-only moment
      return Opacity(
        opacity: opacity,
        child: Container(
          color: context.modernTheme.primaryColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                moment.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
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
        maxWidth: 200,
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
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: context.modernTheme.textSecondaryColor,
            strokeWidth: 2,
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
          Icons.broken_image,
          color: context.modernTheme.textSecondaryColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: context.modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No moments yet',
              style: TextStyle(
                color: context.modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your first moment to get started',
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Constants.createMomentScreen),
              icon: const Icon(Icons.add),
              label: const Text('Create Moment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: context.modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final currentUser = ref.read(currentUserProvider);
                if (currentUser != null) {
                  ref.invalidate(userMomentsStreamProvider(currentUser.uid));
                }
              },
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewMoment(MomentModel moment) {
    Navigator.pushNamed(
      context,
      Constants.momentsFeedScreen,
      arguments: {
        'startMomentId': moment.id,
      },
    );
  }

  void _showMomentOptions(MomentModel moment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: context.modernTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Moment info
            Text(
              moment.content.isNotEmpty 
                  ? moment.content
                  : 'Moment from ${timeago.format(moment.createdAt)}',
              style: TextStyle(
                color: context.modernTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Options
            if (moment.isActive && !moment.isExpired)
              ListTile(
                leading: Icon(
                  Icons.visibility,
                  color: context.modernTheme.textColor,
                ),
                title: Text(
                  'View Moment',
                  style: TextStyle(color: context.modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewMoment(moment);
                },
              ),

            ListTile(
              leading: Icon(
                Icons.comment,
                color: context.modernTheme.textColor,
              ),
              title: Text(
                'View Comments (${moment.commentsCount})',
                style: TextStyle(color: context.modernTheme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  Constants.momentCommentsScreen,
                  arguments: moment,
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              title: const Text(
                'Delete Moment',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMoment(moment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMoment(MomentModel moment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Moment'),
        content: const Text(
          'Are you sure you want to delete this moment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await ref
                  .read(momentsProvider.notifier)
                  .deleteMoment(moment.id);

              if (success) {
                showSnackBar(context, 'Moment deleted successfully');
              } else {
                final momentsState = ref.read(momentsProvider);
                showSnackBar(context, momentsState.error ?? 'Failed to delete moment');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}