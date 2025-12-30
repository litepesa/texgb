// ===============================
// User Moments Screen
// Display all moments from a specific user (their timeline)
// Shows management options when viewing own moments
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/core/router/route_paths.dart';

class UserMomentsScreen extends ConsumerWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const UserMomentsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsState = ref.watch(userMomentsProvider(userId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = currentUser?.uid == userId;

    return Scaffold(
      backgroundColor: MomentsTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App bar with user info
          _buildAppBar(context, ref, isOwnProfile),

          // Moments list
          momentsState.when(
            data: (moments) {
              if (moments.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(isOwnProfile, context),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MomentCard(moment: moments[index]),
                    );
                  },
                  childCount: moments.length,
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: _buildLoadingState(),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: _buildErrorState(context, ref, error.toString()),
            ),
          ),
        ],
      ),
      // FAB to create moment (only for own profile)
      floatingActionButton: isOwnProfile
          ? FloatingActionButton(
              onPressed: () => context.push(RoutePaths.createMoment),
              backgroundColor: MomentsTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, bool isOwnProfile) {
    final displayName = isOwnProfile ? 'My Moments' : userName;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                MomentsTheme.primaryBlue.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  // User avatar
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: userAvatar.isNotEmpty
                        ? CachedNetworkImageProvider(userAvatar)
                        : null,
                    child: userAvatar.isEmpty
                        ? Icon(Icons.person, size: 45, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // User name
                  Text(
                    displayName.isNotEmpty ? displayName : 'Moments',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isOwnProfile)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Your posts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          color: Colors.black87,
          onPressed: () {
            ref.read(userMomentsProvider(userId).notifier).refresh();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: MomentsTheme.primaryBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading moments...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isOwnProfile, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No moments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwnProfile
                  ? 'Share your first moment with friends'
                  : '$userName hasn\'t posted any moments',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwnProfile) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push(RoutePaths.createMoment),
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Create Moment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MomentsTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load moments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(userMomentsProvider(userId).notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MomentsTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
