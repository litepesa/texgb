// lib/features/comments/widgets/comments_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/constants.dart';

class ExpandableCommentText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final bool isMainComment;

  const ExpandableCommentText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 3,
    this.isMainComment = true,
  });

  @override
  State<ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<ExpandableCommentText>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _needsExpansion = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Check if text needs expansion after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsExpansion();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkIfNeedsExpansion() {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 120); // Account for avatar and padding
    
    if (textPainter.didExceedMaxLines) {
      setState(() {
        _needsExpansion = true;
      });
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  String _getTruncatedText() {
    if (!_needsExpansion || _isExpanded) return widget.text;
    
    final words = widget.text.split(' ');
    if (words.length <= 20) return widget.text; // Don't truncate very short texts
    
    // Find a good breaking point (roughly 2-3 lines worth)
    final targetLength = widget.isMainComment ? 120 : 100;
    int currentLength = 0;
    int wordIndex = 0;
    
    for (int i = 0; i < words.length; i++) {
      currentLength += words[i].length + 1; // +1 for space
      if (currentLength > targetLength) {
        wordIndex = i;
        break;
      }
    }
    
    if (wordIndex == 0) wordIndex = words.length ~/ 2; // Fallback
    
    return '${words.take(wordIndex).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _getTruncatedText();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            displayText,
            style: widget.style,
          ),
          secondChild: Text(
            widget.text,
            style: widget.style,
          ),
          crossFadeState: _isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        
        if (_needsExpansion) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _toggleExpansion,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Text(
                _isExpanded ? 'Show less' : 'Read more',
                style: const TextStyle(
                  color: Color(0xFF007AFF), // iOS blue
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final VideoModel video;
  final VoidCallback? onClose;

  const CommentsBottomSheet({
    super.key,
    required this.video,
    this.onClose,
  });

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _isExpanded = false;
  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;

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
    _loadComments();
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

  void _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final authProvider = ref.read(authenticationProvider.notifier);
      final comments = await authProvider.getVideoComments(widget.video.id);
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        showSnackBar(context, 'Failed to load comments: $e');
      }
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

  // Helper method to parse RFC3339 timestamp and format time ago
  String _formatTimeAgo(String timestampString) {
    try {
      // Parse RFC3339 timestamp
      final dateTime = DateTime.parse(timestampString);
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
    } catch (e) {
      // Fallback if parsing fails
      return 'Unknown';
    }
  }

  // Helper method to parse video creation time
  String _formatVideoTime(String timestampString) {
    try {
      final dateTime = DateTime.parse(timestampString);
      return timeago.format(dateTime);
    } catch (e) {
      return 'Unknown time';
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
                        _buildVideoInfo(),
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

  Widget _buildVideoInfo() {
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
            backgroundImage: widget.video.userImage.isNotEmpty
                ? NetworkImage(widget.video.userImage)
                : null,
            backgroundColor: _lightGray,
            child: widget.video.userImage.isEmpty
                ? Text(
                    widget.video.userName.isNotEmpty 
                        ? widget.video.userName[0].toUpperCase()
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
                  widget.video.userName,
                  style: const TextStyle(
                    color: _pureBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatVideoTime(widget.video.createdAt), // Use helper method
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
    if (_isLoadingComments) {
      return const Center(
        child: CircularProgressIndicator(
          color: _iosBlue,
        ),
      );
    }

    if (_comments.isEmpty) {
      return _buildEmptyCommentsState();
    }

    // Group comments by replies
    final groupedComments = _groupCommentsByReplies(_comments);

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
  }

  List<CommentGroup> _groupCommentsByReplies(List<CommentModel> comments) {
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
        _buildEnhancedCommentItem(group.mainComment),
        if (group.replies.isNotEmpty) ...[
          // Show first 2 replies directly
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: group.replies.take(2).map((reply) => 
                _buildEnhancedCommentItem(reply, isReply: true)
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
                  return _buildEnhancedCommentItem(group.replies[index], isReply: true);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCommentItem(CommentModel comment, {bool isReply = false}) {
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    
    // Check if this comment belongs to the current user and if it's liked
    final isLiked = currentUserId != null && comment.likedBy.contains(currentUserId);
    final isOwn = currentUserId != null && comment.authorId == currentUserId;

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
                // Enhanced comment bubble with expandable text
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
                      
                      // Enhanced expandable comment content
                      ExpandableCommentText(
                        text: comment.content,
                        style: TextStyle(
                          color: _pureBlack,
                          fontSize: isReply ? 13 : 14,
                          height: 1.3,
                        ),
                        maxLines: isReply ? 2 : 3,
                        isMainComment: !isReply,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Comment actions
                Row(
                  children: [
                    // Time - Updated to use RFC3339 parsing
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: _mediumGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Like button with enhanced animation
                    GestureDetector(
                      onTap: () => _likeComment(comment),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLiked ? _iosRed.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
              _loadComments();
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
    final currentUser = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    
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
          
          // Show login required message for guest users
          if (!isAuthenticated) ...[
            _buildGuestCommentPrompt(),
          ] else ...[
            // Regular comment input for authenticated users
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _lightGray,
                  child: currentUser?.profileImage.isNotEmpty == true
                      ? ClipOval(
                          child: Image.network(
                            currentUser!.profileImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: _mediumGray,
                                size: 18,
                              );
                            },
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
                      maxLength: Constants.maxCommentLength,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        return null; // Hide default counter
                      },
                      textCapitalization: TextCapitalization.sentences,
                      onTap: _expandSheet,
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
                  '${_commentController.text.length}/${Constants.maxCommentLength}',
                  style: TextStyle(
                    color: _commentController.text.length > (Constants.maxCommentLength * 0.9).round()
                        ? _iosRed
                        : _mediumGray,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGuestCommentPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _iosBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _iosBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _iosBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: _iosBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Constants.guestModeCommentPrompt,
                  style: TextStyle(
                    color: _pureBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(Constants.landingScreen);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _iosBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: _pureWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _likeComment(CommentModel comment) async {
    final currentUserId = ref.read(currentUserIdProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated || currentUserId == null) {
      await requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Like Comments',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }
    
    final isLiked = comment.likedBy.contains(currentUserId);
    
    try {
      final authProvider = ref.read(authenticationProvider.notifier);
      
      if (isLiked) {
        await authProvider.unlikeComment(comment.id);
      } else {
        await authProvider.likeComment(comment.id);
      }
      
      // Reload comments to get updated state
      _loadComments();
      
      // Add haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to update comment like');
      }
    }
  }

  void _replyToComment(CommentModel comment) {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated) {
      requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Reply',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }
    
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

  void _deleteComment(CommentModel comment) {
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
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await ref.read(authenticationProvider.notifier)
                      .deleteComment(comment.id, (error) {
                    if (mounted) {
                      showSnackBar(context, error);
                    }
                  });
                  
                  // Reload comments to reflect deletion
                  _loadComments();
                  
                  HapticFeedback.lightImpact();
                  
                  if (mounted) {
                    showSnackBar(context, Constants.commentDeleted);
                  }
                } catch (e) {
                  if (mounted) {
                    showSnackBar(context, 'Failed to delete comment');
                  }
                }
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

    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      await requireLogin(
        context,
        ref,
        customTitle: 'Sign In to Comment',
        customSubtitle: Constants.guestModeCommentPrompt,
        showContinueBrowsing: false,
      );
      return;
    }

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      await ref.read(authenticationProvider.notifier).addComment(
        videoId: widget.video.id,
        content: content,
        repliedToCommentId: _replyingToCommentId,
        repliedToAuthorName: _replyingToAuthorName,
        onSuccess: (message) async {
          if (mounted) {
            _commentController.clear();
            _cancelReply();
            
            // Reload comments to show the new comment
            _loadComments();
            
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
            
            showSnackBar(context, Constants.commentAdded);
          }
        },
        onError: (error) {
          if (mounted) {
            showSnackBar(context, error);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to send comment');
      }
    }
  }
}

class CommentGroup {
  final CommentModel mainComment;
  final List<CommentModel> replies;

  CommentGroup({
    required this.mainComment,
    required this.replies,
  });
}