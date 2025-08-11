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
  final VoidCallback? onClose;

  const MomentCommentsBottomSheet({
    super.key,
    required this.moment,
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
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _isExpanded = false;

  // Custom theme-independent colors
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _pureBlack = Color(0xFF000000);
  static const Color _darkGray = Color(0xFF3C3C43);
  static const Color _mediumGray = Color(0xFF8E8E93);
  static const Color _lightGray = Color(0xFFF2F2F7);
  static const Color _borderGray = Color(0xFFE5E5E7);
  static const Color _iosBlue = Color(0xFF007AFF);
  static const Color _iosRed = Color(0xFFFF3B30);

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

    // Start animation
    _slideController.forward();
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
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _closeSheet() async {
    // Animate out
    await _slideController.reverse();
    
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
      child: Theme(
        // Force light theme for the bottom sheet regardless of app theme
        data: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.light(
            surface: _pureWhite,
            onSurface: _pureBlack,
            primary: _iosBlue,
            onPrimary: _pureWhite,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Dimmed background
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSheet,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
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
                    decoration: const BoxDecoration(
                      color: _pureWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000), // 10% black shadow
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, -5),
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
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: _pureWhite,
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
              color: _borderGray,
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
                      color: _pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _closeSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _lightGray,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: _mediumGray,
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
      decoration: const BoxDecoration(
        color: _pureWhite,
        border: Border(
          bottom: BorderSide(
            color: _borderGray,
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
            backgroundColor: _lightGray,
            child: widget.moment.authorImage.isEmpty
                ? Text(
                    widget.moment.authorName.isNotEmpty 
                        ? widget.moment.authorName[0].toUpperCase()
                        : "U",
                    style: const TextStyle(
                      color: _mediumGray,
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
                    color: _pureBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.moment.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.moment.content,
                    style: const TextStyle(
                      color: _darkGray,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeago.format(widget.moment.createdAt),
                  style: const TextStyle(
                    color: _mediumGray,
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
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: _iosBlue,
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
      data: (comments) {
        if (comments.isEmpty) {
          return _buildEmptyCommentsState();
        }

        // Group comments by replies
        final groupedComments = _groupCommentsByReplies(comments);

        return Container(
          color: _pureWhite,
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
              color: _borderGray,
            ),
            const SizedBox(width: 8),
            Text(
              'View ${group.replies.length - 2} more replies',
              style: const TextStyle(
                color: _iosBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: _iosBlue,
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
        color: _pureWhite,
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
            decoration: const BoxDecoration(
              color: _pureWhite,
              border: Border(
                bottom: BorderSide(color: _borderGray),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replies to ${group.mainComment.authorName}',
                    style: const TextStyle(
                      color: _pureBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: _mediumGray,
                  ),
                ),
              ],
            ),
          ),
          
          // Original comment (condensed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: _lightGray,
              border: Border(
                bottom: BorderSide(color: _borderGray),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: group.mainComment.authorImage.isNotEmpty
                      ? NetworkImage(group.mainComment.authorImage)
                      : null,
                  backgroundColor: _borderGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.mainComment.authorName,
                        style: const TextStyle(
                          color: _pureBlack,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        group.mainComment.content,
                        style: const TextStyle(
                          color: _darkGray,
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
              color: _pureWhite,
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
      color: _pureWhite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundImage: comment.authorImage.isNotEmpty
                ? NetworkImage(comment.authorImage)
                : null,
            backgroundColor: _lightGray,
            child: comment.authorImage.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty 
                        ? comment.authorName[0].toUpperCase()
                        : "U",
                    style: TextStyle(
                      color: _mediumGray,
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
                // Comment bubble
                Container(
                  padding: EdgeInsets.all(isReply ? 10 : 12),
                  decoration: BoxDecoration(
                    color: isReply ? _lightGray : const Color(0xFFEBEBF0),
                    borderRadius: BorderRadius.circular(isReply ? 14 : 16),
                    border: comment.isReply && comment.repliedToAuthorName != null 
                        ? Border.all(
                            color: _iosBlue.withOpacity(0.3),
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
                          color: _pureBlack,
                          fontSize: isReply ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      // Reply indicator
                      if (comment.isReply && comment.repliedToAuthorName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              color: _iosBlue,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Replying to ${comment.repliedToAuthorName}',
                              style: const TextStyle(
                                color: _iosBlue,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
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
                          color: _pureBlack,
                          fontSize: isReply ? 13 : 14,
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
                    // Time
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: _mediumGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Like button
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
                                color: isLiked ? _iosRed : _mediumGray,
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
                                    color: isLiked ? _iosRed : _mediumGray,
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
                              color: _iosBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Delete button
                    if (isOwn) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _deleteComment(comment),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: _iosRed,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Color(0xFFAEAEB2),
          ),
          SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              color: _pureBlack,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: TextStyle(
              color: _darkGray,
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
            color: _iosRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load comments',
            style: TextStyle(
              color: _pureBlack,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: _darkGray,
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
              backgroundColor: _iosBlue,
              foregroundColor: _pureWhite,
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
      decoration: const BoxDecoration(
        color: _pureWhite,
        border: Border(
          top: BorderSide(
            color: _borderGray,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // 5% black shadow
            blurRadius: 10,
            offset: Offset(0, -2),
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
                backgroundColor: _lightGray,
                child: ref.watch(currentUserProvider)?.image.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          ref.watch(currentUserProvider)!.image,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: _mediumGray,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Comment input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: _lightGray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _commentFocusNode.hasFocus 
                          ? _iosBlue.withOpacity(0.5)
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
                      hintStyle: const TextStyle(
                        color: _mediumGray,
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
                      color: _pureBlack,
                      fontSize: 14,
                    ),
                    maxLines: null,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return null; // Hide default counter
                    },
                    textCapitalization: TextCapitalization.sentences,
                    onTap: _expandSheet,
                  ),
                ),
              ),const SizedBox(width: 8),
              
              // Send button with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _commentController.text.trim().isNotEmpty ? _sendComment : null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _commentController.text.trim().isNotEmpty
                          ? _iosBlue
                          : _borderGray,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: _commentController.text.trim().isNotEmpty
                          ? _pureWhite
                          : _mediumGray,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Character count
          if (_commentController.text.length > 200) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_commentController.text.length}/500',
                style: TextStyle(
                  color: _commentController.text.length > 450 
                      ? _iosRed
                      : _mediumGray,
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
        color: _iosBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _iosBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            color: _iosBlue,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Replying to $_replyingToAuthorName',
              style: const TextStyle(
                color: _iosBlue,
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
                color: _iosBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: _iosBlue,
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
      builder: (context) => Theme(
        data: ThemeData(
          brightness: Brightness.light,
          dialogBackgroundColor: _pureWhite,
        ),
        child: AlertDialog(
          backgroundColor: _pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Comment',
            style: TextStyle(
              color: _pureBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
            style: TextStyle(
              color: _darkGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _mediumGray,
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
                foregroundColor: _iosRed,
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
      if (mounted) {
        showSnackBar(context, 'Failed to send comment');
      }
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