// lib/features/public_groups/screens/public_group_post_comments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/models/post_comment_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PublicGroupPostCommentsScreen extends ConsumerStatefulWidget {
  final PublicGroupPostModel post;
  final PublicGroupModel publicGroup;

  const PublicGroupPostCommentsScreen({
    super.key,
    required this.post,
    required this.publicGroup,
  });

  @override
  ConsumerState<PublicGroupPostCommentsScreen> createState() => _PublicGroupPostCommentsScreenState();
}

class _PublicGroupPostCommentsScreenState extends ConsumerState<PublicGroupPostCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PostCommentModel? _replyingTo;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(publicGroupProvider.notifier).addComment(
        postId: widget.post.postId,
        content: content,
        repliedToCommentId: _replyingTo?.commentId,
      );

      _commentController.clear();
      _cancelReply();

      if (mounted) {
        showSnackBar(context, 'Comment added');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error adding comment: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _replyToComment(PostCommentModel comment) {
    setState(() {
      _replyingTo = comment;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final commentsStream = ref.watch(postCommentsStreamProvider(widget.post.postId));

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comments',
          style: TextStyle(color: theme.textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            width: double.infinity,
            color: theme.dividerColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Post preview
          _buildPostPreview(theme),
          
          const SizedBox(height: 8),
          
          // Comments list
          Expanded(
            child: commentsStream.when(
              data: (comments) => _buildCommentsList(comments, theme),
              loading: () => _buildLoadingState(theme),
              error: (error, stack) => _buildErrorState(error.toString(), theme),
            ),
          ),
          
          // Reply indicator
          if (_replyingTo != null) _buildReplyIndicator(theme),
          
          // Comment input
          _buildCommentInput(theme),
        ],
      ),
    );
  }

  Widget _buildPostPreview(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor!.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Author avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            backgroundImage: widget.post.authorImage.isNotEmpty
                ? NetworkImage(widget.post.authorImage)
                : null,
            child: widget.post.authorImage.isEmpty
                ? Text(
                    widget.post.authorName.isNotEmpty 
                        ? widget.post.authorName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Post info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.authorName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                if (widget.post.content.isNotEmpty)
                  Text(
                    widget.post.getContentPreview(maxLength: 60),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Comment count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.post.commentsCount}',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(List<PostCommentModel> comments, ModernThemeExtension theme) {
    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment on this post',
              style: TextStyle(
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment, theme);
      },
    );
  }

  Widget _buildCommentItem(PostCommentModel comment, ModernThemeExtension theme) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnComment = currentUser != null && comment.authorUID == currentUser.uid;
    final hasReacted = currentUser != null && comment.hasUserReacted(currentUser.uid);

    return Container(
      margin: EdgeInsets.only(left: comment.isReply() ? 32 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.primaryColor!.withOpacity(0.2),
            backgroundImage: comment.authorImage.isNotEmpty
                ? NetworkImage(comment.authorImage)
                : null,
            child: comment.authorImage.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty 
                        ? comment.authorName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name and reply indicator
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                            ),
                          ),
                          if (comment.isReply() && comment.repliedToAuthorName != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.reply,
                              size: 12,
                              color: theme.textTertiaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.repliedToAuthorName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTertiaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Comment text
                      Text(
                        comment.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action row
                Row(
                  children: [
                    Text(
                      comment.getFormattedTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTertiaryColor,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Like button
                    InkWell(
                      onTap: () => _handleCommentReaction(comment),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              hasReacted ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: hasReacted ? Colors.red : theme.textTertiaryColor,
                            ),
                            if (comment.reactionsCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                comment.reactionsCount.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTertiaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Reply button
                    InkWell(
                      onTap: () => _replyToComment(comment),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTertiaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // More options
                    if (isOwnComment || widget.publicGroup.canPost(currentUser?.uid ?? ''))
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: theme.textTertiaryColor,
                        ),
                        onSelected: (value) => _handleCommentAction(comment, value),
                        itemBuilder: (context) => [
                          if (isOwnComment)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.surfaceVariantColor,
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Replying to ${_replyingTo!.authorName}',
            style: TextStyle(
              fontSize: 14,
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _cancelReply,
            icon: Icon(
              Icons.close,
              size: 16,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ModernThemeExtension theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor!.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: _replyingTo != null 
                      ? 'Reply to ${_replyingTo!.authorName}...'
                      : 'Add a comment...',
                  hintStyle: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.borderColor!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.borderColor!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.primaryColor!),
                  ),
                  filled: true,
                  fillColor: theme.surfaceVariantColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _addComment,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return Center(
      child: CircularProgressIndicator(color: theme.primaryColor),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading comments',
            style: TextStyle(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: theme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleCommentReaction(PostCommentModel comment) {
    // TODO: Implement comment reaction
    showSnackBar(context, 'Comment reactions coming soon');
  }

  void _handleCommentAction(PostCommentModel comment, String action) {
    switch (action) {
      case 'delete':
        _showDeleteCommentDialog(comment);
        break;
      case 'report':
        showSnackBar(context, 'Comment reported');
        break;
    }
  }

  void _showDeleteCommentDialog(PostCommentModel comment) {
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
              // TODO: Implement delete comment
              showSnackBar(context, 'Comment deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}