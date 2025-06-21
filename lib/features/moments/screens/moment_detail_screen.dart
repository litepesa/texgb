// lib/features/moments/screens/moment_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/moment_card.dart';
import 'package:textgb/features/moments/widgets/comment_item.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentDetailScreen extends ConsumerStatefulWidget {
  final MomentModel moment;
  final bool showComments;

  const MomentDetailScreen({
    super.key,
    required this.moment,
    this.showComments = false,
  });

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyToUID;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    if (widget.showComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final currentUser = authState.value?.userModel;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Moment card
                SliverToBoxAdapter(
                  child: MomentCard(
                    moment: widget.moment,
                    currentUserUID: currentUser?.uid ?? '',
                    onLike: () => _handleLike(),
                    onComment: () => _focusCommentField(),
                    onDelete: () => _handleDelete(),
                  ),
                ),
                
                // Divider
                SliverToBoxAdapter(
                  child: Container(
                    height: 8,
                    color: Color(0xFFF2F2F7),
                  ),
                ),
                
                // Comments section
                SliverToBoxAdapter(
                  child: _buildCommentsHeader(),
                ),
                
                // Comments list
                StreamBuilder<List<MomentCommentModel>>(
                  stream: ref.read(momentsNotifierProvider.notifier)
                      .getCommentsStream(widget.moment.momentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CupertinoActivityIndicator()),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Error loading comments',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final comments = snapshot.data ?? [];
                    
                    if (comments.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyComments(),
                      );
                    }
                    
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comment = comments[index];
                          return CommentItem(
                            comment: comment,
                            currentUserUID: currentUser?.uid ?? '',
                            onReply: () => _replyToComment(comment),
                            onLike: () => _likeComment(comment.commentId),
                          );
                        },
                        childCount: comments.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Comment input
          _buildCommentInput(context),
        ],
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
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          CupertinoIcons.back,
          color: Color(0xFF007AFF),
        ),
      ),
      title: const Text(
        'Moment',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _shareMoment(),
          icon: const Icon(
            CupertinoIcons.share,
            color: Color(0xFF007AFF),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          Text(
            '${widget.moment.commentsCount}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble,
              size: 30,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share your thoughts',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyToName != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.reply,
                    size: 16,
                    color: Color(0xFF007AFF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Replying to $_replyToName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Comment input field
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _canSendComment() ? _sendComment : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _canSendComment() 
                        ? const Color(0xFF007AFF) 
                        : const Color(0xFFE5E5EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: _canSendComment() 
                        ? Colors.white 
                        : const Color(0xFF8E8E93),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSendComment() {
    return _commentController.text.trim().isNotEmpty;
  }

  void _handleLike() {
    ref.read(momentsNotifierProvider.notifier).toggleLikeMoment(widget.moment.momentId);
  }

  void _handleDelete() {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Moment',
      content: 'Are you sure you want to delete this moment? This action cannot be undone.',
      textAction: 'Delete',
      onActionTap: (confirmed) {
        if (confirmed) {
          ref.read(momentsNotifierProvider.notifier).deleteMoment(widget.moment.momentId);
          Navigator.pop(context);
        }
      },
    );
  }

  void _focusCommentField() {
    _commentFocusNode.requestFocus();
  }

  void _replyToComment(MomentCommentModel comment) {
    setState(() {
      _replyToUID = comment.authorUID;
      _replyToName = comment.authorName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToUID = null;
      _replyToName = null;
    });
  }

  void _sendComment() async {
    if (!_canSendComment()) return;

    final content = _commentController.text.trim();
    _commentController.clear();

    try {
      await ref.read(momentsNotifierProvider.notifier).addComment(
        momentId: widget.moment.momentId,
        content: content,
        replyToUID: _replyToUID,
        replyToName: _replyToName,
      );

      _cancelReply();
    } catch (e) {
      showSnackBar(context, 'Failed to post comment: $e');
    }
  }

  void _likeComment(String commentId) {
    // TODO: Implement comment like functionality
    showSnackBar(context, 'Comment like feature coming soon');
  }

  void _shareMoment() {
    // TODO: Implement share functionality
    showSnackBar(context, 'Share feature coming soon');
  }
}