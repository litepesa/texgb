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
    context.go(RoutePaths.createMoment);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(momentsFeedProvider);

    return Scaffold(
      backgroundColor: MomentsTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Moments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Camera button
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: _navigateToCreateMoment,
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
        child: const Icon(Icons.add),
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
          // Moments list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.moments.length) {
                  final moment = state.moments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
            'Share your first moment!',
            style: TextStyle(
              fontSize: 14,
              color: MomentsTheme.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToCreateMoment,
            icon: const Icon(Icons.add),
            label: const Text('Create Moment'),
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

  Widget _buildErrorState(String error) {
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
            onPressed: _handleRefresh,
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
