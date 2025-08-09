// lib/features/moments/screens/moment_comments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_comment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentCommentsScreen extends ConsumerStatefulWidget {
  final MomentModel moment;

  const MomentCommentsScreen({
    super.key,
    required this.moment,
  });

  @override
  ConsumerState<MomentCommentsScreen> createState() => _MomentCommentsScreenState();
}

class _MomentCommentsScreenState extends ConsumerState<MomentCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = ref.watch(momentCommentsStreamProvider(widget.moment.id));

    return Scaffold(
      backgroundColor: context.modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.modernTheme.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comments',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Moment info header
          _buildMomentHeader(),
          
          // Comments list
          Expanded(
            child: commentsStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (comments) => _buildCommentsList(comments),
            ),
          ),

          // Comment input
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildMomentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.modernTheme.borderColor!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.moment.authorImage.isNotEmpty
                ? NetworkImage(widget.moment.authorImage)
                : null,
            backgroundColor: context.modernTheme.surfaceVariantColor,
            child: widget.moment.authorImage.isEmpty
                ? Text(
                    widget.moment.authorName.isNotEmpty 
                        ? widget.moment.authorName[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      color: context.modernTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.moment.authorName,
                  style: TextStyle(
                    color: context.modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.moment.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.moment.content,
                    style: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeago.format(widget.moment.createdAt),
                  style: TextStyle(
                    color: context.modernTheme.textTertiaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<MomentCommentModel> comments) {
    if (comments.isEmpty) {
      return _buildEmptyCommentsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(MomentCommentModel comment) {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser != null && comment.likedBy.contains(currentUser.uid);
    final isOwn = currentUser?.uid == comment.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.authorImage.isNotEmpty
                ? NetworkImage(comment.authorImage)
                : null,
            backgroundColor: context.modernTheme.surfaceVariantColor,
            child: comment.authorImage.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty 
                        ? comment.authorName[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      color: context.modernTheme.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment content
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.modernTheme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: TextStyle(
                          color: context.modernTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (comment.isReply && comment.repliedToAuthorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Replying to ${comment.repliedToAuthorName}',
                          style: TextStyle(
                            color: context.modernTheme.primaryColor,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: TextStyle(
                          color: context.modernTheme.textColor,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Comment actions
                Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        color: context.modernTheme.textTertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked 
                                ? Colors.red 
                                : context.modernTheme.textTertiaryColor,
                            size: 16,
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              comment.likesCount.toString(),
                              style: TextStyle(
                                color: context.modernTheme.textTertiaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _replyToComment(comment),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: context.modernTheme.textTertiaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _deleteComment(comment),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: context.modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment on this moment',
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load comments',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(momentCommentsStreamProvider(widget.moment.id));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.modernTheme.borderColor!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null) _buildReplyingIndicator(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null 
                        ? 'Reply to $_replyingToAuthorName...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
                    ),
                    filled: true,
                    fillColor: context.modernTheme.surfaceVariantColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: context.modernTheme.textColor),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.modernTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyingIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.modernTheme.primaryColor?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: context.modernTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToAuthorName',
              style: TextStyle(
                color: context.modernTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(
              Icons.close,
              color: context.modernTheme.primaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _likeComment(MomentCommentModel comment) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final isLiked = comment.likedBy.contains(currentUser.uid);
    ref.read(momentCommentActionsProvider)
        .toggleLikeComment(comment.id, isLiked);
  }

  void _replyToComment(MomentCommentModel comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToAuthorName = comment.authorName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _deleteComment(MomentCommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(momentCommentActionsProvider)
                  .deleteComment(comment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await ref
        .read(momentCommentActionsProvider)
        .addComment(
          momentId: widget.moment.id,
          content: content,
          repliedToCommentId: _replyingToCommentId,
          repliedToAuthorName: _replyingToAuthorName,
        );

    if (success) {
      _commentController.clear();
      _cancelReply();
      // Hide keyboard
      FocusScope.of(context).unfocus();
    } else {
      showSnackBar(context, 'Failed to send comment');
    }
  }
}