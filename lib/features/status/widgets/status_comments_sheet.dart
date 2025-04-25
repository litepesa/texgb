import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';

class StatusCommentsSheet extends StatefulWidget {
  final String statusId;
  final String currentUserId;
  
  const StatusCommentsSheet({
    Key? key,
    required this.statusId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<StatusCommentsSheet> createState() => _StatusCommentsSheetState();
}

class _StatusCommentsSheetState extends State<StatusCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  List<StatusCommentModel> _comments = [];
  bool _isLoading = false;
  String? _replyToCommentId;
  String _replyToUsername = '';
  
  @override
  void initState() {
    super.initState();
    _fetchComments();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _fetchComments() async {
    setState(() {
      _isLoading = true;
    });
    
    final comments = await Provider.of<StatusProvider>(context, listen: false)
        .fetchComments(statusId: widget.statusId);
    
    // Organize comments by parent-child relationships
    // Root comments first, then replies grouped under them
    final rootComments = comments.where((c) => c.parentCommentId == null).toList();
    final Map<String, List<StatusCommentModel>> replyMap = {};
    
    for (var comment in comments.where((c) => c.parentCommentId != null)) {
      if (!replyMap.containsKey(comment.parentCommentId)) {
        replyMap[comment.parentCommentId!] = [];
      }
      replyMap[comment.parentCommentId!]!.add(comment);
    }
    
    // Sort root comments by creation time (newest first)
    rootComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Create ordered list with replies inserted after their parent comments
    List<StatusCommentModel> orderedComments = [];
    for (var rootComment in rootComments) {
      orderedComments.add(rootComment);
      
      if (replyMap.containsKey(rootComment.commentId)) {
        // Sort replies by creation time (oldest first for conversation flow)
        final replies = replyMap[rootComment.commentId]!;
        replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        orderedComments.addAll(replies);
      }
    }
    
    setState(() {
      _comments = orderedComments;
      _isLoading = false;
    });
  }
  
  void _replyToComment(StatusCommentModel comment) {
    setState(() {
      _replyToCommentId = comment.commentId;
      _replyToUsername = comment.username;
    });
    
    _commentController.text = '@${comment.username} ';
    _commentFocusNode.requestFocus();
  }
  
  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = '';
      _commentController.clear();
    });
  }
  
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
    if (currentUser == null) return;
    
    // Check if this is a reply
    String commentText = _commentController.text.trim();
    String? parentId = _replyToCommentId;
    
    // If it's a reply, remove the @username prefix for cleaner storage
    if (parentId != null && commentText.startsWith('@$_replyToUsername ')) {
      commentText = commentText.substring('@$_replyToUsername '.length);
    }
    
    // Clear input field
    _commentController.clear();
    
    // Reset reply state
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = '';
    });
    
    try {
      await Provider.of<StatusProvider>(context, listen: false).addComment(
        statusId: widget.statusId,
        uid: currentUser.uid,
        username: currentUser.name,
        userImage: currentUser.image,
        text: commentText,
        parentCommentId: parentId,
      );
      
      // Refresh comments
      _fetchComments();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = isDarkMode 
        ? Colors.grey[900] 
        : Colors.grey[50];
    
    final currentUser = Provider.of<AuthenticationProvider>(context).userModel;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
                : _comments.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to comment',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isReply = comment.parentCommentId != null;
                          
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isReply ? 36 : 16,
                              vertical: 8,
                            ),
                            margin: EdgeInsets.only(
                              left: isReply ? 24 : 0,
                              bottom: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isReply
                                  ? (isDarkMode ? Colors.grey[850] : Colors.grey[100])
                                  : null,
                              border: isReply
                                  ? Border(
                                      left: BorderSide(
                                        color: modernTheme.primaryColor!.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User avatar
                                CircleAvatar(
                                  radius: isReply ? 14 : 18,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: comment.userImage.isNotEmpty
                                      ? CachedNetworkImageProvider(comment.userImage)
                                      : AssetImage(AssetsManager.userImage) as ImageProvider,
                                ),
                                
                                SizedBox(width: 10),
                                
                                // Comment content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Username and timestamp
                                      Row(
                                        children: [
                                          Text(
                                            comment.username,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isReply ? 13 : 14,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            _timeAgo(comment.createdAt),
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: isReply ? 11 : 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 4),
                                      
                                      // Comment text
                                      Text(
                                        comment.text,
                                        style: TextStyle(
                                          fontSize: isReply ? 13 : 14,
                                        ),
                                      ),
                                      
                                      SizedBox(height: 6),
                                      
                                      // Like and reply actions
                                      Row(
                                        children: [
                                          // Like button
                                          GestureDetector(
                                            onTap: () {
                                              // Implement like functionality
                                            },
                                            child: Row(
                                              children: [
                                                Icon(
                                                  comment.isLikedBy(widget.currentUserId)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 16,
                                                  color: comment.isLikedBy(widget.currentUserId)
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  comment.likeCount.toString(),
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          SizedBox(width: 16),
                                          
                                          // Reply button
                                          if (!isReply) // Only show reply for parent comments
                                            GestureDetector(
                                              onTap: () => _replyToComment(comment),
                                              child: Text(
                                                'Reply',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
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
                        },
                      ),
          ),
          
          // Reply indicator
          if (_replyToCommentId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    'Replying to $_replyToUsername',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: modernTheme.primaryColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 16),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          
          // Comment input
          if (currentUser != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: currentUser.image.isNotEmpty
                          ? CachedNetworkImageProvider(currentUser.image)
                          : AssetImage(AssetsManager.userImage) as ImageProvider,
                    ),
                    
                    SizedBox(width: 8),
                    
                    // Comment input field
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        style: TextStyle(fontSize: 14),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    
                    SizedBox(width: 8),
                    
                    // Post button
                    IconButton(
                      icon: Icon(Icons.send, color: modernTheme.primaryColor),
                      onPressed: _postComment,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}