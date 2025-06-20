// lib/features/public_groups/screens/public_group_post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/models/post_comment_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/features/public_groups/widgets/public_group_post_item.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class PublicGroupPostDetailScreen extends ConsumerStatefulWidget {
  final PublicGroupPostModel post;
  final PublicGroupModel publicGroup;

  const PublicGroupPostDetailScreen({
    super.key,
    required this.post,
    required this.publicGroup,
  });

  @override
  ConsumerState<PublicGroupPostDetailScreen> createState() => _PublicGroupPostDetailScreenState();
}

class _PublicGroupPostDetailScreenState extends ConsumerState<PublicGroupPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAddingComment = false;
  PostCommentModel? _replyingTo;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final commentsStream = ref.watch(postCommentsStreamProvider(widget.post.postId));
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Post',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Main post
                  PublicGroupPostItem(
                    post: widget.post,
                    publicGroup: widget.publicGroup,
                    onReaction: (emoji) => _handlePostReaction(emoji),
                    onComment: () => _focusCommentInput(),
                    onShare: () => _handlePostShare(),
                    onMenuAction: (action) => _handlePostMenuAction(action),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Comments section
                  Container(
                    color: theme.surfaceVariantColor?.withOpacity(0.3),
                    child: Column(
                      children: [
                        // Comments header
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: theme.textSecondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Comments',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${widget.post.commentsCount}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Comments list
                        commentsStream.when(
                          data: (comments) => _buildCommentsList(comments, theme),
                          loading: () => _buildCommentsLoading(theme),
                          error: (error, stack) => _buildCommentsError(error.toString(), theme),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  Widget _buildCommentsList(List<PostCommentModel> comments, ModernThemeExtension theme) {
    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 16,
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => Container(
        height: 1,
        color: theme.dividerColor?.withOpacity(0.1),
      ),
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
      color: theme.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply indicator
          if (comment.isReply())
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Replying to ${comment.repliedToAuthorName}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondaryColor,
                ),
              ),
            ),
          
          // Comment header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.primaryColor!.withOpacity(0.2),
                backgroundImage: comment.authorImage.isNotEmpty
                    ? NetworkImage(comment.authorImage)
                    : null,
                child: comment.authorImage.isEmpty
                    ? Text(
                        comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.primaryColor,
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
                    Text(
                      comment.authorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    Text(
                      comment.getFormattedTime(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Comment menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: theme.textSecondaryColor,
                ),
                onSelected: (action) => _handleCommentAction(comment, action),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reply',
                    child: Row(
                      children: [
                        Icon(Icons.reply, size: 16),
                        SizedBox(width: 8),
                        Text('Reply'),
                      ],
                    ),
                  ),
                  if (isOwnComment)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Report', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Comment content
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Comment actions
          Row(
            children: [
              InkWell(
                onTap: () => _handleCommentReaction(comment),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        hasReacted ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: hasReacted ? Colors.red : theme.textSecondaryColor,
                      ),
                      if (comment.reactionsCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          comment.reactionsCount.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              InkWell(
                onTap: () => _replyToComment(comment),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsLoading(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      ),
    );
  }

  Widget _buildCommentsError(String error, ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: theme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.primaryColor!.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to ${_replyingTo!.authorName}',
              style: TextStyle(
                fontSize: 14,
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
            icon: Icon(
              Icons.close,
              size: 16,
              color: theme.primaryColor,
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
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor!.withOpacity(0.2),
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
                style: TextStyle(color: theme.textColor),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isAddingComment ? null : _addComment,
                icon: _isAddingComment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
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

  void _focusCommentInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      await ref.read(publicGroupProvider.notifier).addComment(
        postId: widget.post.postId,
        content: content,
        repliedToCommentId: _replyingTo?.commentId,
      );

      _commentController.clear();
      setState(() {
        _replyingTo = null;
      });

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
          _isAddingComment = false;
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

  Future<void> _handlePostReaction(String emoji) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      final hasReaction = widget.post.hasUserReacted(currentUser.uid);
      final hasSameReaction = hasReaction && widget.post.getUserReaction(currentUser.uid) == emoji;
      
      if (hasSameReaction) {
        await ref.read(publicGroupProvider.notifier).removePostReaction(widget.post.postId);
      } else {
        await ref.read(publicGroupProvider.notifier).addPostReaction(widget.post.postId, emoji);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error reacting to post: $e');
      }
    }
  }

  void _handlePostShare() {
    showSnackBar(context, 'Share functionality coming soon');
  }

  void _handlePostMenuAction(String action) {
    showSnackBar(context, 'Menu action: $action');
  }

  Future<void> _handleCommentReaction(PostCommentModel comment) async {
    try {
      // TODO: Implement comment reactions
      showSnackBar(context, 'Comment reactions coming soon');
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error: $e');
      }
    }
  }

  void _handleCommentAction(PostCommentModel comment, String action) {
    switch (action) {
      case 'reply':
        _replyToComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
      case 'report':
        _reportComment(comment);
        break;
    }
  }

  Future<void> _deleteComment(PostCommentModel comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // TODO: Implement delete comment
        showSnackBar(context, 'Delete comment functionality coming soon');
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error deleting comment: $e');
        }
      }
    }
  }

  void _reportComment(PostCommentModel comment) {
    showSnackBar(context, 'Report functionality coming soon');
  }
}