// lib/features/moments/widgets/moment_comments_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_comment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MomentCommentsBottomSheet extends ConsumerStatefulWidget {
  final MomentModel moment;
  final Widget videoWidget;
  final VoidCallback? onClose;

  const MomentCommentsBottomSheet({
    super.key,
    required this.moment,
    required this.videoWidget,
    this.onClose,
  });

  @override
  ConsumerState<MomentCommentsBottomSheet> createState() => _MomentCommentsBottomSheetState();
}

class _MomentCommentsBottomSheetState extends ConsumerState<MomentCommentsBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _videoSizeController;
  late Animation<double> _videoScaleAnimation;
  late Animation<Offset> _videoPositionAnimation;
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _isExpanded = false;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupTextControllerListener();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _videoSizeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _videoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.35,
    ).animate(CurvedAnimation(
      parent: _videoSizeController,
      curve: Curves.easeOutCubic,
    ));
    
    _videoPositionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.6, -0.7),
    ).animate(CurvedAnimation(
      parent: _videoSizeController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _slideController.forward();
    _videoSizeController.forward();
  }

  void _setupKeyboardListener() {
    _commentFocusNode.addListener(() {
      if (_commentFocusNode.hasFocus) {
        _expandSheet();
      }
    });
  }

  void _setupTextControllerListener() {
    _commentController.addListener(() {
      setState(() {}); // Update UI when text changes for send button state
    });
  }

  void _expandSheet() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _videoSizeController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _closeSheet() async {
    // Animate out
    await Future.wait([
      _slideController.reverse(),
      _videoSizeController.reverse(),
    ]);
    
    if (mounted) {
      widget.onClose?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = _isExpanded ? screenHeight * 0.9 : screenHeight * 0.6;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _closeSheet();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Dimmed background with video
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSheet,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Stack(
                    children: [
                      // Small video player in top-right corner
                      AnimatedBuilder(
                        animation: Listenable.merge([_videoScaleAnimation, _videoPositionAnimation]),
                        builder: (context, child) {
                          return Positioned(
                            top: MediaQuery.of(context).padding.top + 20,
                            right: 20,
                            child: Transform.scale(
                              scale: _videoScaleAnimation.value,
                              child: Transform.translate(
                                offset: Offset(
                                  _videoPositionAnimation.value.dx * MediaQuery.of(context).size.width,
                                  _videoPositionAnimation.value.dy * MediaQuery.of(context).size.height,
                                ),
                                child: Container(
                                  width: 120,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: widget.videoWidget,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Comments bottom sheet with custom white theme
            SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: sheetHeight + bottomInset + systemBottomPadding,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSheetHeader(),
                      _buildMomentInfo(),
                      Expanded(child: _buildCommentsList()),
                      _buildCommentInput(bottomInset, systemBottomPadding),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Header with title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closeSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
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
            backgroundColor: Colors.grey[200],
            child: widget.moment.authorImage.isEmpty
                ? Text(
                    widget.moment.authorName.isNotEmpty 
                        ? widget.moment.authorName[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      color: Colors.black54,
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
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.moment.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.moment.content,
                    style: TextStyle(
                      color: Colors.grey[600],
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
                    color: Colors.grey[500],
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

  Widget _buildCommentsList() {
    final commentsStream = ref.watch(momentCommentsStreamProvider(widget.moment.id));

    return commentsStream.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (comments) {
        if (comments.isEmpty) {
          return _buildEmptyCommentsState();
        }

        // Group comments by replies
        final groupedComments = _groupCommentsByReplies(comments);

        return Container(
          color: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedComments.length,
            itemBuilder: (context, index) {
              final commentGroup = groupedComments[index];
              return _buildCommentGroup(commentGroup);
            },
          ),
        );
      },
    );
  }

  List<CommentGroup> _groupCommentsByReplies(List<MomentCommentModel> comments) {
    final Map<String, CommentGroup> groups = {};
    final List<CommentGroup> result = [];

    // First pass: create groups for main comments
    for (final comment in comments) {
      if (!comment.isReply) {
        final group = CommentGroup(mainComment: comment, replies: []);
        groups[comment.id] = group;
        result.add(group);
      }
    }

    // Second pass: add replies to their groups
    for (final comment in comments) {
      if (comment.isReply && comment.repliedToCommentId != null) {
        final group = groups[comment.repliedToCommentId!];
        if (group != null) {
          group.replies.add(comment);
        }
      }
    }

    // Sort replies by creation time (oldest first)
    for (final group in result) {
      group.replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return result;
  }

  Widget _buildCommentGroup(CommentGroup group) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _buildCommentThread(group),
    );
  }

  Widget _buildCommentThread(CommentGroup group) {
    return Column(
      children: [
        _buildCommentItem(group.mainComment),
        if (group.replies.isNotEmpty) ...[
          // Show first 2 replies directly
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: group.replies.take(2).map((reply) => 
                _buildCommentItem(reply, isReply: true)
              ).toList(),
            ),
          ),
          
          // Show "view more replies" if there are more than 2
          if (group.replies.length > 2) ...[
            _buildViewMoreReplies(group),
          ],
        ],
      ],
    );
  }

  Widget _buildViewMoreReplies(CommentGroup group) {
    return Container(
      padding: const EdgeInsets.only(left: 64, right: 16, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => _showAllReplies(group),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(width: 8),
            Text(
              'View ${group.replies.length - 2} more replies',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.blue,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReplies(CommentGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFullRepliesSheet(group),
    );
  }

  Widget _buildFullRepliesSheet(CommentGroup group) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replies to ${group.mainComment.authorName}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          
          // Original comment (condensed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: group.mainComment.authorImage.isNotEmpty
                      ? NetworkImage(group.mainComment.authorImage)
                      : null,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.mainComment.authorName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        group.mainComment.content,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // All replies
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: group.replies.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(group.replies[index], isReply: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(MomentCommentModel comment, {bool isReply = false}) {
    final currentUser = ref.watch(currentUserProvider);
    final isLiked = currentUser != null && comment.likedBy.contains(currentUser.uid);
    final isOwn = currentUser?.uid == comment.authorId;

    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 32 : 16,
        right: 16,
        top: 12,
        bottom: isReply ? 8 : 12,
      ),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundImage: comment.authorImage.isNotEmpty
                ? NetworkImage(comment.authorImage)
                : null,
            backgroundColor: Colors.grey[200],
            child: comment.authorImage.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty 
                        ? comment.authorName[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: isReply ? 10 : 12,
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
                // Comment bubble with enhanced styling
                Container(
                  padding: EdgeInsets.all(isReply ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isReply ? Colors.grey[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(isReply ? 14 : 16),
                    border: comment.isReply && comment.repliedToAuthorName != null 
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isReply ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      // Reply indicator with better styling
                      if (comment.isReply && comment.repliedToAuthorName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              color: Colors.blue,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to ${comment.repliedToAuthorName}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      // Comment content with better formatting
                      Text(
                        comment.content,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: isReply ? 13 : 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Enhanced comment actions with animations
                Row(
                  children: [
                    // Time with more precise formatting
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Enhanced like button with count
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(isLiked),
                                color: isLiked ? Colors.red : Colors.grey[500],
                                size: 14,
                              ),
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  comment.likesCount.toString(),
                                  key: ValueKey(comment.likesCount),
                                  style: TextStyle(
                                    color: isLiked ? Colors.red : Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Reply button (only for main comments)
                    if (!isReply) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _replyToComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Delete button with better styling
                    if (isOwn) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _deleteComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyCommentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No comments yet',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
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
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load comments',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(momentCommentsStreamProvider(widget.moment.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(double bottomInset, double systemBottomPadding) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + bottomInset + systemBottomPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null) _buildReplyingIndicator(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                child: ref.watch(currentUserProvider)?.image.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          ref.watch(currentUserProvider)!.image,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 18,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Comment input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _commentFocusNode.hasFocus 
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null 
                          ? 'Reply to $_replyingToAuthorName...'
                          : 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    maxLines: null,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return null; // Hide default counter, we'll show our own
                    },
                    textCapitalization: TextCapitalization.sentences,
                    onTap: _expandSheet,
                    onChanged: (text) {
                      // Add typing indicator or other real-time features here
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send button with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _commentController.text.trim().isNotEmpty ? _sendComment : null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _commentController.text.trim().isNotEmpty
                          ? Colors.blue
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: _commentController.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Character count and typing indicators (optional)
          if (_commentController.text.length > 200) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_commentController.text.length}/500',
                style: TextStyle(
                  color: _commentController.text.length > 450 
                      ? Colors.red 
                      : Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyingIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: Colors.blue,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToAuthorName',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.blue,
                size: 12,
              ),
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
        
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _replyToComment(MomentCommentModel comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToAuthorName = comment.authorName;
    });
    _commentFocusNode.requestFocus();
    _expandSheet();
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Comment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
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

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();

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
      
      // Scroll to bottom to show new comment
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      showSnackBar(context, 'Failed to send comment');
    }
  }
}

class CommentGroup {
  final MomentCommentModel mainComment;
  final List<MomentCommentModel> replies;

  CommentGroup({
    required this.mainComment,
    required this.replies,
  });
}