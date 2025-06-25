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

  // Facebook 2025 Modern Design System
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbBlueLight = Color(0xFF42A5F5);
  static const Color fbGreen = Color(0xFF00A400);
  static const Color fbRed = Color(0xFFE41E3F);
  static const Color fbOrange = Color(0xFFFF7043);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF0F2F5);
  static const Color surfaceVariant = Color(0xFFF7F8FA);
  static const Color outline = Color(0xFFDADDE1);
  static const Color outlineVariant = Color(0xFFE4E6EA);
  
  // Text Colors
  static const Color onSurface = Color(0xFF1C1E21);
  static const Color onSurfaceVariant = Color(0xFF65676B);
  static const Color onSurfaceSecondary = Color(0xFF8A8D91);
  static const Color onSurfaceTertiary = Color(0xFFBCC0C4);

  @override
  void initState() {
    super.initState();
    
    // Set modern status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
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
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: fbBlue,
          secondary: fbBlueLight,
          surface: surface,
          background: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          iconTheme: IconThemeData(color: onSurface),
          titleTextStyle: TextStyle(
            color: onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: background,
        body: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: momentsState.when(
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error.toString()),
                data: (state) => _buildMomentsFeed(state, authState),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildModernFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(color: outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: onSurface,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          const Expanded(
            child: Text(
              'Moments',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Search button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // More options
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: onSurfaceVariant,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: fbBlue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading moments...',
              style: TextStyle(
                fontSize: 16,
                color: onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
            color: fbBlue,
            backgroundColor: surface,
            strokeWidth: 2.5,
            displacement: 60,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // My Moment Header
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
                                      color: surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          offset: const Offset(0, 2),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const CircularProgressIndicator(
                                      color: fbBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final moment = state.moments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 0),
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
                
                // Bottom padding
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      fbBlue.withOpacity(0.1),
                      fbBlueLight.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 48,
                  color: fbBlue,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to Moments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share photos, videos, and thoughts\nwith your friends and family',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              _buildModernButton(
                'Create your first moment',
                fbBlue,
                Icons.add_rounded,
                () => _navigateToCreateMoment(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: surface, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: surface,
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
    return Container(
      color: background,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 16,
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
                  color: fbRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: fbRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _buildModernButton(
                'Try Again',
                fbBlue,
                Icons.refresh_rounded,
                _refreshFeed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: fbBlue.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _navigateToCreateMoment();
        },
        backgroundColor: fbBlue,
        foregroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),
    );
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
        transitionDuration: const Duration(milliseconds: 300),
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
            color: surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
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
                  color: outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: onSurfaceVariant,
                          size: 20,
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
                        child: CircularProgressIndicator(color: fbBlue),
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
                              size: 64,
                              color: onSurfaceSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                fontSize: 14,
                                color: onSurfaceSecondary,
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
                            horizontal: 20,
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
                                    color: surfaceVariant,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: onSurface,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(
                                          color: onSurface,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatCommentTime(comment.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: onSurfaceSecondary,
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
                      },
                    );
                  },
                ),
              ),
              
              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                decoration: const BoxDecoration(
                  color: surface,
                  border: Border(
                    top: BorderSide(color: outlineVariant),
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
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(
                  color: onSurfaceSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: onSurface,
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: fbBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: surface,
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