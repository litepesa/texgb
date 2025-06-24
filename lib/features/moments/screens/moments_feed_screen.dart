// lib/features/moments/screens/moments_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/widgets/my_moments_header.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentsFeedScreen extends ConsumerStatefulWidget {
  const MomentsFeedScreen({super.key});

  @override
  ConsumerState<MomentsFeedScreen> createState() => _MomentsFeedScreenState();
}

class _MomentsFeedScreenState extends ConsumerState<MomentsFeedScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Premium color palette - Sophisticated blues and greens
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF7F8FC);
  static const Color softGray = Color(0xFFEFF1F6);
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF5A6175);
  static const Color textTertiary = Color(0xFF9BA3B4);
  static const Color premiumBlue = Color(0xFF2563EB); // Premium royal blue
  static const Color accentBlue = Color(0xFF3B82F6); // Bright blue
  static const Color premiumGreen = Color(0xFF059669); // Premium emerald green
  static const Color accentGreen = Color(0xFF10B981); // Bright green
  static const Color premiumPurple = Color(0xFF7C3AED); // Premium violet
  static const Color dividerColor = Color(0xFFE2E5EA);
  static const Color shadowColor = Color(0x0A1A1D29);

  @override
  void initState() {
    super.initState();
    
    // Set status bar style for white background - always black icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Black icons
        statusBarBrightness: Brightness.light, // Light status bar
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _scrollController.addListener(_onScroll);
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    final state = ref.read(momentsNotifierProvider).value;
    if (state == null || !state.hasMore || state.isLoading) return;

    setState(() => _isLoadingMore = true);
    await ref.read(momentsNotifierProvider.notifier).loadMomentsFeed();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _refreshFeed() async {
    HapticFeedback.lightImpact();
    await ref.read(momentsNotifierProvider.notifier).loadMomentsFeed(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final momentsState = ref.watch(momentsNotifierProvider);
    final authState = ref.watch(authenticationProvider);

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundGray,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.light(
          primary: accentBlue,
          surface: primaryWhite,
          background: backgroundGray,
        ),
      ),
      child: Scaffold(
        backgroundColor: primaryWhite, // Changed to white instead of gray
        extendBodyBehindAppBar: true, // Extend body behind status bar
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: momentsState.when(
                    loading: () => _buildLoadingState(),
                    error: (error, stack) => _buildErrorState(error.toString()),
                    data: (state) => _buildMomentsFeed(state, authState),
                  ),
                ),
              ],
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: accentBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Loading moments...',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentsFeed(MomentsState state, AsyncValue authState) {
    if (!state.isInitialized && state.isLoading) {
      return _buildLoadingState();
    }

    if (state.moments.isEmpty && state.isInitialized && !state.isLoading) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: RefreshIndicator(
            onRefresh: _refreshFeed,
            color: accentBlue,
            backgroundColor: primaryWhite,
            strokeWidth: 2.5,
            displacement: 60,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // My Moment Header - no extra padding needed
                SliverToBoxAdapter(
                  child: authState.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (auth) => auth.userModel != null
                        ? MyMomentHeader(user: auth.userModel!)
                        : const SizedBox.shrink(),
                  ),
                ),
                
                // Moments List
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.moments.length) {
                        return _isLoadingMore
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: primaryWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: shadowColor,
                                          offset: const Offset(0, 4),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const CircularProgressIndicator(
                                      color: accentBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final moment = state.moments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        child: MomentCard(
                          moment: moment,
                          onLike: () => _likeMoment(moment.momentId),
                          onComment: () => _openComments(moment),
                          onView: () => _addView(moment.momentId),
                          onDelete: moment.authorUID == 
                              authState.value?.userModel?.uid
                              ? () => _deleteMoment(moment.momentId)
                              : null,
                        ),
                      );
                    },
                    childCount: state.moments.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
                
                // Bottom padding for floating navigation
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: textTertiary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No moments yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your first moment with friends\nand start building memories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildEmptyStateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateButton() {
    return GestureDetector(
      onTap: _navigateToCreateMoment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [premiumBlue, accentBlue],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: premiumBlue.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
            BoxShadow(
              color: premiumBlue.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Text(
          'Create Your First Moment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: primaryWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _refreshFeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        child: _buildFloatingNavBar(),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: primaryWhite,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 8),
            blurRadius: 32,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: true,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Chats',
              isActive: false,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            _buildCenterFAB(),
            _buildNavItem(
              icon: Icons.people_rounded,
              label: 'Friends',
              isActive: false,
              onTap: () {
                HapticFeedback.lightImpact();
              },
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isActive: false,
              onTap: () {
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? premiumBlue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive ? premiumBlue : textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? premiumBlue : textTertiary,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFAB() {
    return Container(
      width: 80,
      height: double.infinity,
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _navigateToCreateMoment();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  premiumGreen,
                  accentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: premiumGreen.withOpacity(0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: premiumGreen.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return const SizedBox.shrink(); // No longer needed as FAB is integrated
  }

  void _navigateToCreateMoment() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CreateMomentScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      _refreshFeed();
    });
  }

  void _likeMoment(String momentId) {
    HapticFeedback.lightImpact();
    ref.read(momentsNotifierProvider.notifier).toggleLikeMoment(momentId);
  }

  void _addView(String momentId) {
    ref.read(momentsNotifierProvider.notifier).addViewToMoment(momentId);
  }

  void _openComments(MomentModel moment) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: primaryWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: softGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comments content
              Expanded(
                child: StreamBuilder<List<MomentComment>>(
                  stream: ref.read(momentsNotifierProvider.notifier)
                      .getMomentComments(moment.momentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: accentBlue,
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: textTertiary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                fontSize: 14,
                                color: textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              userImageWidget(
                                imageUrl: comment.authorImage,
                                radius: 18,
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: softGray,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(
                                          color: textPrimary,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatCommentTime(comment.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: primaryWhite,
                  border: Border(
                    top: BorderSide(
                      color: dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildCommentInput(moment.momentId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(String momentId) {
    final commentController = TextEditingController();
    
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: softGray,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final content = commentController.text.trim();
            if (content.isNotEmpty) {
              HapticFeedback.lightImpact();
              await ref.read(momentsNotifierProvider.notifier).addComment(
                momentId: momentId,
                content: content,
              );
              commentController.clear();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [premiumBlue, accentBlue],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: premiumBlue.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  void _deleteMoment(String momentId) {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Moment',
      content: 'Are you sure you want to delete this moment?',
      textAction: 'Delete',
      onActionTap: (confirm) {
        if (confirm) {
          HapticFeedback.mediumImpact();
          ref.read(momentsNotifierProvider.notifier).deleteMoment(momentId);
        }
      },
    );
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}