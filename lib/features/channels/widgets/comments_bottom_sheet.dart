// lib/features/channels/widgets/comments_bottom_sheet.dart
// Enhanced comments experience with threaded replies and better UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/constants.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String videoId;
  
  const CommentsBottomSheet({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet>
    with TickerProviderStateMixin {
  
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late AnimationController _sheetController;
  late AnimationController _keyboardController;
  late Animation<double> _sheetAnimation;
  late Animation<double> _keyboardAnimation;
  
  bool _isLoading = false;
  bool _isKeyboardVisible = false;
  String? _replyingToCommentId;
  String? _replyingToUserName;
  Map<String, bool> _expandedReplies = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
  }

  void _initializeAnimations() {
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _keyboardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutCubic,
    );
    
    _keyboardAnimation = CurvedAnimation(
      parent: _keyboardController,
      curve: Curves.easeOutQuart,
    );
    
    _sheetController.forward();
  }

  void _setupKeyboardListener() {
    _commentFocusNode.addListener(() {
      if (_commentFocusNode.hasFocus) {
        _showKeyboard();
      } else {
        _hideKeyboard();
      }
    });
  }

  void _showKeyboard() {
    setState(() {
      _isKeyboardVisible = true;
    });
    _keyboardController.forward();
  }

  void _hideKeyboard() {
    setState(() {
      _isKeyboardVisible = false;
    });
    _keyboardController.reverse();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _sheetController.dispose();
    _keyboardController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_auth.currentUser == null) {
      _showSnackBar('You must be logged in to comment');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = _auth.currentUser!.uid;
      
      // Get user data
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      final userName = userData[Constants.name] ?? '';
      final userImage = userData[Constants.image] ?? '';
      
      // Add comment to Firestore
      final commentData = {
        'videoId': widget.videoId,
        'userId': uid,
        'userName': userName,
        'userImage': userImage,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'replyCount': 0,
      };
      
      // Only add parentCommentId if we're replying
      if (_replyingToCommentId != null) {
        commentData['parentCommentId'] = _replyingToCommentId;
      }
      
      await _firestore.collection(Constants.channelComments).add(commentData);
      
      // If replying to a comment, increment reply count
      if (_replyingToCommentId != null) {
        await _firestore.collection(Constants.channelComments).doc(_replyingToCommentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }
      
      // Increment comment count on video
      await _firestore.collection(Constants.channelVideos).doc(widget.videoId).update({
        'comments': FieldValue.increment(1),
      });
      
      // Clear input and reset reply state
      _commentController.clear();
      _commentFocusNode.unfocus();
      _cancelReply();
      
      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      
    } catch (e) {
      _showSnackBar('Error adding comment: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    _commentController.text = '@$userName ';
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _toggleReplies(String commentId) {
    setState(() {
      _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? false);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.7,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final mediaQuery = MediaQuery.of(context);
    
    return AnimatedBuilder(
      animation: _sheetAnimation,
      builder: (context, child) {
        return Container(
          height: mediaQuery.size.height * 0.75 * _sheetAnimation.value,
          decoration: BoxDecoration(
            color: modernTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(modernTheme),
              if (_replyingToCommentId != null)
                _buildReplyIndicator(modernTheme),
              Expanded(
                child: _buildCommentsList(modernTheme),
              ),
              AnimatedBuilder(
                animation: _keyboardAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_keyboardAnimation.value * 20),
                    child: _buildCommentInput(modernTheme),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Comments',
            style: TextStyle(
              color: modernTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            color: modernTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Replying to @$_replyingToUserName',
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelReply,
            child: Icon(
              Icons.close,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(ModernThemeExtension modernTheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(Constants.channelComments)
          .where('videoId', isEqualTo: widget.videoId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: modernTheme.primaryColor,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: modernTheme.textSecondaryColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading comments',
                  style: TextStyle(color: modernTheme.textColor),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: modernTheme.textSecondaryColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No comments yet',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to comment!',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        final comments = snapshot.data!.docs;
        
        // Filter main comments (those without parentCommentId or with null parentCommentId)
        final mainComments = comments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['parentCommentId'] == null || !data.containsKey('parentCommentId');
        }).toList();
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: mainComments.length,
          itemBuilder: (context, index) {
            final commentDoc = mainComments[index];
            final comment = commentDoc.data() as Map<String, dynamic>;
            return _buildCommentThread(commentDoc.id, comment, modernTheme);
          },
        );
      },
    );
  }

  Widget _buildCommentThread(String commentId, Map<String, dynamic> comment, ModernThemeExtension modernTheme) {
    final replyCount = comment['replyCount'] ?? 0;
    final isExpanded = _expandedReplies[commentId] ?? false;

    return Column(
      children: [
        _buildCommentItem(commentId, comment, modernTheme, isMainComment: true),
        
        // Show replies indicator
        if (replyCount > 0)
          _buildRepliesIndicator(commentId, replyCount, isExpanded, modernTheme),
        
        // Show replies if expanded
        if (isExpanded)
          _buildRepliesList(commentId, modernTheme),
      ],
    );
  }

  Widget _buildRepliesIndicator(String commentId, int replyCount, bool isExpanded, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _toggleReplies(commentId),
      child: Container(
        margin: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 1,
              color: modernTheme.dividerColor!.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: modernTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isExpanded ? 'Hide replies' : 'View $replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepliesList(String parentCommentId, ModernThemeExtension modernTheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(Constants.channelComments)
          .where('videoId', isEqualTo: widget.videoId)
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(left: 48),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          debugPrint('Error loading replies: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final replies = snapshot.data!.docs;
        
        return Container(
          margin: const EdgeInsets.only(left: 48),
          child: Column(
            children: replies.map((replyDoc) {
              final reply = replyDoc.data() as Map<String, dynamic>;
              return _buildCommentItem(replyDoc.id, reply, modernTheme, isMainComment: false);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(String commentId, Map<String, dynamic> comment, ModernThemeExtension modernTheme, {required bool isMainComment}) {
    final userName = comment['userName'] ?? '';
    final userImage = comment['userImage'] ?? '';
    final commentText = comment['comment'] ?? '';
    final likes = comment['likes'] ?? 0;
    
    // Format timestamp
    String timeAgo = 'Just now';
    if (comment['createdAt'] != null) {
      final timestamp = comment['createdAt'] as Timestamp;
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());
      
      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h';
      } else {
        timeAgo = '${difference.inDays}d';
      }
    }
    
    return Container(
      padding: EdgeInsets.only(
        left: isMainComment ? 16 : 8,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection line for replies
          if (!isMainComment)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 18),
              child: Column(
                children: [
                  Container(
                    width: 16,
                    height: 1,
                    color: modernTheme.dividerColor!.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          
          // User avatar
          CircleAvatar(
            radius: isMainComment ? 18 : 14,
            backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
            backgroundImage: userImage.isNotEmpty
                ? NetworkImage(userImage)
                : null,
            child: userImage.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isMainComment ? 14 : 10,
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
                // User name and timestamp
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMainComment ? 14 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: isMainComment ? 12 : 10,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  commentText,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: isMainComment ? 14 : 12,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action buttons
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: () {
                        // Like comment functionality
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            color: modernTheme.textSecondaryColor,
                            size: isMainComment ? 16 : 14,
                          ),
                          if (likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              likes.toString(),
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: isMainComment ? 12 : 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Reply button (only for main comments)
                    if (isMainComment)
                      GestureDetector(
                        onTap: () => _startReply(commentId, userName),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildCommentInput(ModernThemeExtension modernTheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor!.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
              backgroundImage: _auth.currentUser?.photoURL != null
                  ? NetworkImage(_auth.currentUser!.photoURL!)
                  : null,
              child: _auth.currentUser?.photoURL == null
                  ? Icon(
                      Icons.person,
                      color: modernTheme.primaryColor,
                      size: 16,
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Comment input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: modernTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _replyingToCommentId != null 
                        ? modernTheme.primaryColor!.withOpacity(0.5)
                        : modernTheme.dividerColor!.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null 
                        ? 'Reply to @$_replyingToUserName...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(
                      color: modernTheme.textSecondaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  style: TextStyle(
                    color: modernTheme.textColor,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isLoading ? null : _addComment,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show comments bottom sheet
void showCommentsBottomSheet(BuildContext context, String videoId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => CommentsBottomSheet(videoId: videoId),
  );
}