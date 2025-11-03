// ===============================
// User Moments Screen
// Display all moments from a specific user (their timeline)
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';

class UserMomentsScreen extends ConsumerWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const UserMomentsScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsState = ref.watch(userMomentsProvider(userId));

    return Scaffold(
      backgroundColor: MomentsTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App bar with user info
          _buildAppBar(context, ref),

          // Moments list
          momentsState.when(
            data: (moments) {
              if (moments.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
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
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // User avatar
                CircleAvatar(
                  radius: 50,
                  backgroundImage: CachedNetworkImageProvider(userAvatar),
                ),
                const SizedBox(height: 12),
                // User name
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
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
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading moments...',
            style: TextStyle(
              color: MomentsTheme.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: MomentsTheme.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No moments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MomentsTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$userName hasn\'t posted any moments',
            style: TextStyle(
              fontSize: 14,
              color: MomentsTheme.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load moments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MomentsTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: MomentsTheme.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
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
            ),
          ),
        ],
      ),
    );
  }
}
