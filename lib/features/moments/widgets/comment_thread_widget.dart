// lib/features/moments/widgets/comment_thread_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:textgb/features/moments/models/moment_comment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CommentThreadWidget extends ConsumerStatefulWidget {
  final MomentCommentModel comment;
  final List<MomentCommentModel> replies;
  final Function(MomentCommentModel) onReply;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const CommentThreadWidget({
    super.key,
    required this.comment,
    required this.replies,
    required this.onReply,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  ConsumerState<CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends ConsumerState<CommentThreadWidget>
    with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool _showLikeAnimation = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainComment(),
        if (widget.replies.isNotEmpty) ...[
          if (widget.replies.length > 2 && !widget.isExpanded)
            _buildViewMoreReplies()
          else
            _buildRepliesList(),
        ],
      ],
    );
  }

  Widget _buildMainComment() {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser != null && widget.comment.likedBy.contains(currentUser.uid);
    final isOwn = currentUser?.uid == widget.comment.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(widget.comment, 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentBubble(widget.comment, isMainComment: true),
                const SizedBox(height: 8),
                _buildCommentActions(widget.comment, isLiked, isOwn, isMainComment: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesList() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        children: widget.replies.map((reply) => _buildReplyComment(reply)).toList(),
      ),
    );
  }

  Widget _buildReplyComment(MomentCommentModel reply) {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser != null && reply.likedBy.contains(currentUser.uid);
    final isOwn = currentUser?.uid == reply.authorId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(reply, 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentBubble(reply, isMainComment: false),
                const SizedBox(height: 6),
                _buildCommentActions(reply, isLiked, isOwn, isMainComment: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(MomentCommentModel comment, double radius) {
    return CircleAvatar(
      radius: radius,
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
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildCommentBubble(MomentCommentModel comment, {required bool isMainComment}) {
    return Container(
      padding: EdgeInsets.all(isMainComment ? 12 : 10),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(isMainComment ? 16 : 14),
        border: comment.isReply && comment.repliedToAuthorName != null 
            ? Border.all(
                color: context.modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author name
          Text(
            comment.authorName,
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: isMainComment ? 14 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Reply indicator
          if (comment.isReply && comment.repliedToAuthorName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.reply,
                  color: context.modernTheme.primaryColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Replying to ${comment.repliedToAuthorName}',
                  style: TextStyle(
                    color: context.modernTheme.primaryColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 4),
          
          // Comment content
          Text(
            comment.content,
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: isMainComment ? 14 : 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentActions(
    MomentCommentModel comment, 
    bool isLiked, 
    bool isOwn, 
    {required bool isMainComment}
  ) {
    return Row(
      children: [
        // Time ago
        Text(
          timeago.format(comment.createdAt),
          style: TextStyle(
            color: context.modernTheme.textTertiaryColor,
            fontSize: 11,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Like button with animation
        GestureDetector(
          onTap: () => _likeComment(comment, isLiked),
          child: AnimatedBuilder(
            animation: _likeScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _showLikeAnimation && comment.id == widget.comment.id 
                    ? _likeScaleAnimation.value 
                    : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked 
                          ? Colors.red 
                          : context.modernTheme.textTertiaryColor,
                      size: 14,
                    ),
                    if (comment.likesCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(comment.likesCount),
                        style: TextStyle(
                          color: context.modernTheme.textTertiaryColor,
                          fontSize: 11,
                          fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        
        // Reply button (only for main comments)
        if (isMainComment) ...[
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => widget.onReply(comment),
            child: Text(
              'Reply',
              style: TextStyle(
                color: context.modernTheme.textTertiaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        
        // Delete button (for own comments)
        if (isOwn) ...[
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _deleteComment(comment),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildViewMoreReplies() {
    return Container(
      padding: const EdgeInsets.only(left: 48, right: 16, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: widget.onToggleExpanded,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 1,
              color: context.modernTheme.textTertiaryColor?.withOpacity(0.3),
            ),
            const SizedBox(width: 8),
            Text(
              'View ${widget.replies.length - 2} more replies',
              style: TextStyle(
                color: context.modernTheme.textTertiaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: context.modernTheme.textTertiaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _likeComment(MomentCommentModel comment, bool isCurrentlyLiked) {
    if (_isLiking) return;
    
    _isLiking = true;
    
    // Trigger animation for visual feedback
    if (!isCurrentlyLiked) {
      setState(() {
        _showLikeAnimation = true;
      });
      
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showLikeAnimation = false;
            });
          }
        });
      });
    }
    
    // Perform the like action
    ref.read(momentCommentActionsProvider)
        .toggleLikeComment(comment.id, isCurrentlyLiked)
        .then((_) {
      _isLiking = false;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _deleteComment(MomentCommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.modernTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Comment',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(
            color: context.modernTheme.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(momentCommentActionsProvider)
                  .deleteComment(comment.id);
              HapticFeedback.lightImpact();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}