// lib/features/moments/screens/moments_feed_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/moment_detail_screen.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/widgets/my_moments_header.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

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
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(momentsNotifierProvider.notifier).loadMomentsFeed(refresh: true);
      ref.read(momentsNotifierProvider.notifier).loadMyMoments();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(momentsNotifierProvider.notifier).loadMomentsFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final momentsState = ref.watch(momentsNotifierProvider);
    final authState = ref.watch(authenticationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: momentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (state) => _buildFeedContent(context, state, authState.value?.userModel),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      title: const Text(
        'Moments',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _navigateToCreateMoment(context),
          icon: const Icon(
            CupertinoIcons.camera,
            color: Color(0xFF007AFF),
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: Color(0xFF8E8E93),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(momentsNotifierProvider.notifier).loadMomentsFeed(refresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(BuildContext context, MomentsState state, dynamic currentUser) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(momentsNotifierProvider.notifier).loadMomentsFeed(refresh: true);
        await ref.read(momentsNotifierProvider.notifier).loadMyMoments();
      },
      color: Color(0xFF007AFF),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // My Moments Header
          SliverToBoxAdapter(
            child: MyMomentsHeader(
              myMoments: state.myMoments,
              onCreateMoment: () => _navigateToCreateMoment(context),
              onViewMyMoments: () => _navigateToMyMoments(context),
            ),
          ),
          
          // Divider
          SliverToBoxAdapter(
            child: Container(
              height: 8,
              color: Color(0xFFF2F2F7),
            ),
          ),
          
          // Moments Feed
          if (state.moments.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < state.moments.length) {
                    final moment = state.moments[index];
                    return Column(
                      children: [
                        MomentCard(
                          moment: moment,
                          currentUserUID: currentUser?.uid ?? '',
                          onLike: () => _handleLike(moment.momentId),
                          onComment: () => _navigateToComments(context, moment),
                          onDelete: () => _handleDelete(moment.momentId),
                          onTap: () => _navigateToDetail(context, moment),
                        ),
                        Container(
                          height: 8,
                          color: Color(0xFFF2F2F7),
                        ),
                      ],
                    );
                  } else if (state.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                        ),
                      ),
                    );
                  } else if (!state.hasMore) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No more moments to show',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: state.moments.length + (state.isLoadingMore || !state.hasMore ? 1 : 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              CupertinoIcons.camera_circle,
              size: 40,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No moments yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your first moment with friends',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateMoment(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            icon: const Icon(CupertinoIcons.add, size: 20),
            label: const Text(
              'Create Moment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLike(String momentId) {
    ref.read(momentsNotifierProvider.notifier).toggleLikeMoment(momentId);
  }

  void _handleDelete(String momentId) {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Moment',
      content: 'Are you sure you want to delete this moment? This action cannot be undone.',
      textAction: 'Delete',
      onActionTap: (confirmed) {
        if (confirmed) {
          ref.read(momentsNotifierProvider.notifier).deleteMoment(momentId);
        }
      },
    );
  }

  void _navigateToCreateMoment(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const CreateMomentScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToComments(BuildContext context, MomentModel moment) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MomentDetailScreen(moment: moment, showComments: true),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, MomentModel moment) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MomentDetailScreen(moment: moment),
      ),
    );
  }

  void _navigateToMyMoments(BuildContext context) {
    // TODO: Implement My Moments screen
    showSnackBar(context, 'My Moments screen coming soon');
  }
}