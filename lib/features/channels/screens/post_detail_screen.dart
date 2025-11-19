// lib/features/channels/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_comment_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/features/channels/providers/channel_comments_provider.dart';
import 'package:textgb/features/channels/widgets/post_card.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Post detail screen with multi-threaded comments
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  final String channelId;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.channelId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(channelPostProvider(widget.postId));
    final commentsAsync = ref.watch(sortedCommentsProvider(widget.postId));
    final sortType = ref.watch(commentSortProvider);

    return Scaffold(
      backgroundColor: ChannelsTheme.screenBackground,
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          // Sort menu
          PopupMenuButton<CommentSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (sortType) {
              ref.read(commentSortProvider.notifier).setSortType(sortType);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: CommentSortType.top,
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 18,
                      color: sortType == CommentSortType.top
                          ? ChannelsTheme.facebookBlue
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Top Comments'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CommentSortType.new_,
                child: Row(
                  children: [
                    Icon(
                      Icons.new_releases,
                      size: 18,
                      color: sortType == CommentSortType.new_
                          ? ChannelsTheme.facebookBlue
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Newest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CommentSortType.old,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: sortType == CommentSortType.old
                          ? ChannelsTheme.facebookBlue
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Oldest First'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Post Content
          Expanded(
            child: postAsync.when(
              data: (post) {
                if (post == null) {
                  return _buildNotFoundState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(channelPostProvider(widget.postId));
                    ref.invalidate(postCommentsProvider(widget.postId));
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Card
                        PostCard(
                          post: post,
                          channelId: widget.channelId,
                          showChannelInfo: true,
                        ),

                        const Divider(thickness: 8, height: 8),

                        // Comments Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.comment_outlined,
                                size: 20,
                                color: ChannelsTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${post.commentsCount} Comments',
                                style: ChannelsTheme.headingSmall,
                              ),
                            ],
                          ),
                        ),

                        // Comments List
                        commentsAsync.when(
                          data: (comments) {
                            if (comments.isEmpty) {
                              return _buildNoCommentsState();
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                return _buildCommentItem(comments[index], 0);
                              },
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => _buildErrorState(error.toString()),
                        ),

                        const SizedBox(height: 100), // Comment input clearance
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),

          // Comment Input Bar
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ChannelComment comment, int depth) {
    final isDeleted = comment.isDeleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 24.0),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: comment.isPinned ? ChannelsTheme.warning.withOpacity(0.1) : ChannelsTheme.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment Header
                  Row(
                    children: [
                      // User Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: comment.userAvatarUrl != null
                            ? NetworkImage(comment.userAvatarUrl!)
                            : null,
                        child: comment.userAvatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),

                      // Username
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.username,
                              style: ChannelsTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              comment.timeAgo,
                              style: ChannelsTheme.caption,
                            ),
                          ],
                        ),
                      ),

                      // Pinned Badge
                      if (comment.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ChannelsTheme.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PINNED',
                            style: ChannelsTheme.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ChannelsTheme.black,
                            ),
                          ),
                        ),

                      // More Options
                      if (!isDeleted)
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onPressed: () => _showCommentOptions(comment),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Comment Text
                  Text(
                    comment.text,
                    style: ChannelsTheme.bodyMedium.copyWith(
                      color: isDeleted ? ChannelsTheme.textTertiary : null,
                      fontStyle: isDeleted ? FontStyle.italic : null,
                    ),
                  ),

                  // Media Attachment
                  if (comment.mediaUrl != null && !isDeleted) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        comment.mediaUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  if (!isDeleted) ...[
                    const SizedBox(height: 8),

                    // Engagement Row
                    Row(
                      children: [
                        // Like Button
                        InkWell(
                          onTap: () => _likeComment(comment),
                          child: Row(
                            children: [
                              Icon(
                                comment.hasLiked == true
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                size: 16,
                                color: comment.hasLiked == true
                                    ? ChannelsTheme.facebookBlue
                                    : ChannelsTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likes}',
                                style: ChannelsTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Reply Button
                        InkWell(
                          onTap: () => _startReply(comment),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 16,
                                color: ChannelsTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: ChannelsTheme.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Replies Count
                        if (comment.repliesCount > 0) ...[
                          const SizedBox(width: 16),
                          Text(
                            '${comment.repliesCount} ${comment.repliesCount == 1 ? 'reply' : 'replies'}',
                            style: ChannelsTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Nested Replies
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildCommentItem(reply, depth + 1)),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: ChannelsTheme.hoverColor,
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 16, color: ChannelsTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to $_replyingToUsername',
                        style: ChannelsTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _cancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Input field
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: ChannelsTheme.hoverColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        hintStyle: ChannelsTheme.bodyMedium.copyWith(
                          color: ChannelsTheme.textTertiary,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submitComment,
                    icon: const Icon(
                      Icons.send,
                      color: ChannelsTheme.facebookBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCommentsState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: ChannelsTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: ChannelsTheme.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment',
            style: ChannelsTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: ChannelsTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Post not found',
              style: ChannelsTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This post may have been deleted',
              style: ChannelsTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ChannelsTheme.primaryButtonStyle,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: ChannelsTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: ChannelsTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(channelPostProvider(widget.postId));
                ref.invalidate(postCommentsProvider(widget.postId));
              },
              style: ChannelsTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final actionsNotifier = ref.read(commentActionsProvider.notifier);
    final comment = await actionsNotifier.createComment(
      postId: widget.postId,
      text: text,
      parentCommentId: _replyingToCommentId,
    );

    if (comment != null) {
      _commentController.clear();
      _cancelReply();
      _commentFocusNode.unfocus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
  }

  void _startReply(ChannelComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToUsername = comment.username;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  Future<void> _likeComment(ChannelComment comment) async {
    final actionsNotifier = ref.read(commentActionsProvider.notifier);
    await actionsNotifier.likeComment(comment.id, widget.postId);
  }

  void _showCommentOptions(ChannelComment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _startReply(comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report
              },
            ),
            // TODO: Show delete option if user owns comment
            // TODO: Show pin option if user is admin/moderator
          ],
        ),
      ),
    );
  }
}
