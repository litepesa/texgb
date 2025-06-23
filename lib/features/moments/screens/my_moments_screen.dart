// lib/features/moments/screens/my_moments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MyMomentsScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const MyMomentsScreen({super.key, required this.user});

  @override
  ConsumerState<MyMomentsScreen> createState() => _MyMomentsScreenState();
}

class _MyMomentsScreenState extends ConsumerState<MyMomentsScreen> {
  List<MomentModel> _myMoments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyMoments();
  }

  Future<void> _loadMyMoments() async {
    try {
      final moments = await ref.read(momentsNotifierProvider.notifier)
          .getUserMoments(widget.user.uid);
      
      if (mounted) {
        setState(() {
          _myMoments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1D1D1D),
                      ),
                    )
                  : _myMoments.isEmpty
                      ? _buildEmptyState()
                      : _buildMomentsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF1D1D1D),
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'My Moments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1D),
              ),
            ),
          ),
          const SizedBox(width: 20), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildMomentsList() {
    return RefreshIndicator(
      onRefresh: _loadMyMoments,
      color: const Color(0xFF1D1D1D),
      backgroundColor: Colors.white,
      child: ListView.builder(
        itemCount: _myMoments.length,
        itemBuilder: (context, index) {
          final moment = _myMoments[index];
          return MomentCard(
            moment: moment,
            onLike: () => _likeMoment(moment.momentId),
            onComment: () => _openComments(moment),
            onView: () => _addView(moment.momentId),
            onDelete: () => _deleteMoment(moment.momentId),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 40,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No moments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your first moment with friends',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Create Moment'),
          ),
        ],
      ),
    );
  }

  void _likeMoment(String momentId) {
    ref.read(momentsNotifierProvider.notifier).toggleLikeMoment(momentId);
    // Update local state
    setState(() {
      final momentIndex = _myMoments.indexWhere((m) => m.momentId == momentId);
      if (momentIndex != -1) {
        final moment = _myMoments[momentIndex];
        final isLiked = moment.likedBy.contains(widget.user.uid);
        final updatedLikedBy = List<String>.from(moment.likedBy);
        
        if (isLiked) {
          updatedLikedBy.remove(widget.user.uid);
        } else {
          updatedLikedBy.add(widget.user.uid);
        }
        
        _myMoments[momentIndex] = moment.copyWith(likedBy: updatedLikedBy);
      }
    });
  }

  void _addView(String momentId) {
    ref.read(momentsNotifierProvider.notifier).addViewToMoment(momentId);
  }

  void _openComments(MomentModel moment) {
    // Similar to the implementation in MomentsFeedScreen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF0F0F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1D),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MomentComment>>(
                  stream: ref.read(momentsNotifierProvider.notifier)
                      .getMomentComments(moment.momentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D1D1D),
                        ),
                      );
                    }

                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              userImageWidget(
                                imageUrl: comment.authorImage,
                                radius: 16,
                                onTap: () {},
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D1D1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(
                                        color: Color(0xFF1D1D1D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCommentTime(comment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
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
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFF0F0F0),
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
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF1D1D1D),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            final content = commentController.text.trim();
            if (content.isNotEmpty) {
              await ref.read(momentsNotifierProvider.notifier).addComment(
                momentId: momentId,
                content: content,
              );
              commentController.clear();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.send,
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
      onActionTap: (confirm) async {
        if (confirm) {
          await ref.read(momentsNotifierProvider.notifier).deleteMoment(momentId);
          // Remove from local state
          setState(() {
            _myMoments.removeWhere((moment) => moment.momentId == momentId);
          });
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