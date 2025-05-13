import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';

class MarketplaceCommentsScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const MarketplaceCommentsScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<MarketplaceCommentsScreen> createState() => _MarketplaceCommentsScreenState();
}

class _MarketplaceCommentsScreenState extends ConsumerState<MarketplaceCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
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
      await _firestore.collection(Constants.marketplaceComments).add({
        'videoId': widget.videoId,
        'userId': uid,
        'userName': userName,
        'userImage': userImage,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });
      
      // Increment comment count on video
      await _firestore.collection(Constants.marketplaceVideos).doc(widget.videoId).update({
        'comments': FieldValue.increment(1),
      });
      
      // Clear input
      _commentController.clear();
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Comments',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // Comments list
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(Constants.marketplaceComments)
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
                    child: Text(
                      'Error loading comments',
                      style: TextStyle(color: modernTheme.textColor),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment,
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
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;
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
                        timeAgo = '${difference.inMinutes}m ago';
                      } else if (difference.inHours < 24) {
                        timeAgo = '${difference.inHours}h ago';
                      } else {
                        timeAgo = '${difference.inDays}d ago';
                      }
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User avatar
                          CircleAvatar(
                            radius: 20,
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
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        color: modernTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        color: modernTheme.textSecondaryColor,
                                        fontSize: 12,
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
                                    fontSize: 14,
                                  ),
                                ),
                                
                                const SizedBox(height: 6),
                                
                                // Like and reply buttons
                                Row(
                                  children: [
                                    Text(
                                      'Like',
                                      style: TextStyle(
                                        color: modernTheme.textSecondaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: modernTheme.textSecondaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (likes > 0) ...[
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.favorite,
                                        color: modernTheme.primaryColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        likes.toString(),
                                        style: TextStyle(
                                          color: modernTheme.textSecondaryColor,
                                          fontSize: 12,
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
                  },
                );
              },
            ),
          ),
          
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                  child: Text(
                    'Me',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Comment input field
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: modernTheme.textSecondaryColor,
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: modernTheme.textColor,
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send button
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: modernTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: modernTheme.primaryColor,
                        ),
                  onPressed: _isLoading ? null : _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}