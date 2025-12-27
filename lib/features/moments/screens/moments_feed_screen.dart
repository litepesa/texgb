// ===============================
// Moments Feed Screen
// Main timeline displaying all moments from contacts
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/core/router/route_paths.dart';

class MomentsFeedScreen extends ConsumerStatefulWidget {
  const MomentsFeedScreen({super.key});

  @override
  ConsumerState<MomentsFeedScreen> createState() => _MomentsFeedScreenState();
}

class _MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(momentsFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(momentsFeedProvider.notifier).refresh();
  }

  void _navigateToCreateMoment() {
    context.push(RoutePaths.createMoment);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(momentsFeedProvider);

    return Scaffold(
      backgroundColor: MomentsTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Moments'),
        backgroundColor: MomentsTheme.lightSurface,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        actions: [
          // Camera button - Facebook style
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: _navigateToCreateMoment,
            color: MomentsTheme.lightTextPrimary,
          ),
        ],
      ),
      body: feedState.when(
        data: (state) => _buildFeed(state),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateMoment,
        backgroundColor: MomentsTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFeed(MomentsFeedState state) {
    if (state.moments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: MomentsTheme.primaryBlue,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Top spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: MomentsTheme.cardSpacing),
          ),

          // Moments list with Facebook-style spacing
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.moments.length) {
                  final moment = state.moments[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: MomentsTheme.cardSpacing,
                      right: MomentsTheme.cardSpacing,
                      bottom: MomentsTheme.cardSpacing,
                    ),
                    child: MomentCard(moment: moment),
                  );
                }
                return null;
              },
              childCount: state.moments.length,
            ),
          ),

          // Loading more indicator
          if (state.isLoadingMore)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),

          // End indicator
          if (!state.hasMore && state.moments.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Text(
                  'No more moments',
                  style: TextStyle(
                    color: MomentsTheme.lightTextTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: MomentsTheme.primaryBlue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading moments...',
            style: MomentsTheme.timestampStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MomentsTheme.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: MomentsTheme.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No moments yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MomentsTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your first moment with friends',
              style: MomentsTheme.timestampStyle.copyWith(
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _navigateToCreateMoment,
              style: MomentsTheme.primaryButtonStyle,
              child: const Text('Create Moment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MomentsTheme.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: MomentsTheme.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load moments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: MomentsTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: MomentsTheme.timestampStyle.copyWith(
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRefresh,
              style: MomentsTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}