import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/status/widgets/comment_item.dart';
import 'package:textgb/features/status/widgets/media_grid_view.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusDetailScreen extends StatefulWidget {
  final StatusModel status;
  final String currentUserId;
  final bool focusComment;
  
  const StatusDetailScreen({
    Key? key,
    required this.status,
    required this.currentUserId,
    this.focusComment = false,
  }) : super(key: key);

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isCommenting = false;
  
  @override
  void initState() {
    super.initState();
    
    // If focusComment is true, focus the comment field after build
    if (widget.focusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocus.requestFocus();
      });
    }
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }
  
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    setState(() {
      _isCommenting = true;
    });
    
    final statusProvider = context.read<StatusProvider>();
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    
    await statusProvider.addComment(
      statusId: widget.status.statusId,
      currentUser: currentUser,
      commentText: _commentController.text.trim(),
      onSuccess: () {
        _commentController.clear();
        setState(() {
          _isCommenting = false;
        });
        FocusScope.of(context).unfocus();
      },
      onError: (error) {
        setState(() {
          _isCommenting = false;
        });
        showSnackBar(context, 'Error posting comment: $error');
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    final isMyStatus = widget.status.uid == widget.currentUserId;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Status'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with user info and time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User avatar
                        userImageWidget(
                          imageUrl: widget.status.userImage,
                          radius: 20,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        
                        // Username and time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.status.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                timeago.format(widget.status.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Caption content
                    if (widget.status.caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          widget.status.caption,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    
                    // Media content
                    if (widget.status.statusType == StatusType.image)
                      _buildSingleImage(widget.status.statusUrl)
                    else if (widget.status.statusType == StatusType.video)
                      _buildVideoThumbnail(widget.status.statusUrl)
                    else if (widget.status.statusType == StatusType.multiImage && widget.status.mediaUrls != null)
                      MediaGridView(
                        mediaUrls: widget.status.mediaUrls!,
                        caption: widget.status.caption,
                      ),
                    
                    // Location if available
                    if (widget.status.location != null && widget.status.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.status.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats row (only visible to post owner)
                    if (isMyStatus)
                      Row(
                        children: [
                          // Views count
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.status.viewedBy.length} views',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          // Likes count
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.status.likedBy.length} likes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    
                    const Divider(height: 32),
                    
                    // Interaction section (for non-owners)
                    if (!isMyStatus)
                      Row(
                        children: [
                          // Like button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                context.read<StatusProvider>().toggleLike(
                                  statusId: widget.status.statusId,
                                  userId: widget.currentUserId,
                                  statusOwnerUid: widget.status.uid,
                                  onSuccess: () {},
                                  onError: (error) {
                                    showSnackBar(context, 'Error: $error');
                                  },
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.status.likedBy.contains(widget.currentUserId)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: widget.status.likedBy.contains(widget.currentUserId)
                                        ? Colors.red
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.status.likedBy.contains(widget.currentUserId)
                                        ? 'Liked'
                                        : 'Like',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Comment button
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _commentFocus.requestFocus();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.comment),
                                  const SizedBox(width: 8),
                                  const Text('Comment'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    
                    if (!isMyStatus)
                      const Divider(height: 32),
                    
                    // Comments section
                    if (widget.status.comments.isNotEmpty) ...[
                      Text(
                        'Comments (${widget.status.comments.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Comment list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.status.comments.length,
                        itemBuilder: (context, index) {
                          final comment = widget.status.comments[index];
                          return CommentItem(
                            comment: comment,
                            isMyComment: comment.uid == widget.currentUserId,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Comment input field at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocus,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send button
                SizedBox(
                  height: 40,
                  width: 40,
                  child: _isCommenting
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            color: accentColor,
                          ),
                          onPressed: _addComment,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSingleImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
  
  Widget _buildVideoThumbnail(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // For a real implementation, you would use a thumbnail extraction or video frame
                // Here we just use a placeholder
                'https://via.placeholder.com/800x450',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}