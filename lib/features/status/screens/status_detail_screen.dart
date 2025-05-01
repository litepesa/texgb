// lib/features/status/presentation/screens/status_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/models/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/status/widgets/status_comment_item.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

class StatusDetailScreen extends StatefulWidget {
  final String postId;
  
  const StatusDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostDetails();
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadPostDetails() async {
    await Provider.of<StatusProvider>(context, listen: false).getPostDetails(widget.postId);
    _initializeVideoPlayer();
  }
  
  void _initializeVideoPlayer() {
    final post = Provider.of<StatusProvider>(context, listen: false).currentViewingPost;
    if (post != null && post.type == StatusType.video && post.mediaUrls.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(post.mediaUrls[0]))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }
  
  void _addComment(currentUser) {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;
    
    Provider.of<StatusProvider>(context, listen: false).addComment(
      postId: widget.postId,
      userId: currentUser.uid,
      userName: currentUser.name,
      userImage: currentUser.image,
      content: _commentController.text.trim(),
    ).then((success) {
      if (success) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }
  
  void _showOptionsMenu(BuildContext context, StatusPost post) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      backgroundColor: modernTheme.surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  CupertinoIcons.pencil,
                  color: modernTheme.textColor,
                ),
                title: Text(
                  'Edit Post',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit screen - implement later
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.trash,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(context);
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.eye_slash,
                  color: modernTheme.textColor,
                ),
                title: Text(
                  'Change Privacy',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show privacy options - implement later
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone. Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<StatusProvider>(context, listen: false).deletePost(widget.postId).then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post deleted')),
                  );
                  Navigator.pop(context); // Go back to feed
                }
              });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final statusProvider = Provider.of<StatusProvider>(context);
    final authProvider = Provider.of<AuthenticationProvider>(context);
    final post = statusProvider.currentViewingPost;
    final comments = statusProvider.currentComments;
    final bool isLoading = statusProvider.isLoading;
    final currentUser = authProvider.userModel;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Status Details'),
        backgroundColor: modernTheme.appBarColor,
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
              ? const Center(child: Text('Post not found'))
              : Column(
                  children: [
                    // Expanded list with post and comments
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Post content
                          SliverToBoxAdapter(
                            child: Card(
                              margin: const EdgeInsets.all(8.0),
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: modernTheme.surfaceColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User info
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // User avatar
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey[300],
                                          backgroundImage: post.userImage.isNotEmpty
                                              ? CachedNetworkImageProvider(post.userImage)
                                              : const AssetImage(AssetsManager.userImage) as ImageProvider,
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // User name and time
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.userName,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: modernTheme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timeago.format(DateTime.fromMillisecondsSinceEpoch(post.timestamp)),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: modernTheme.textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Options menu for own posts
                                        if (post.userId == currentUser?.uid)
                                          IconButton(
                                            icon: Icon(
                                              CupertinoIcons.ellipsis,
                                              color: modernTheme.textSecondaryColor,
                                            ),
                                            onPressed: () => _showOptionsMenu(context, post),
                                            splashRadius: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Post content
                                  if (post.content.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                      child: Text(
                                        post.content,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: modernTheme.textColor,
                                        ),
                                      ),
                                    ),
                                    
                                  const SizedBox(height: 8),
                                  
                                  // Media content
                                  if (post.mediaUrls.isNotEmpty)
                                    _buildMediaContent(post),
                                    
                                  // Post stats and actions
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Stats
                                        Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.heart_fill,
                                              size: 16,
                                              color: modernTheme.textSecondaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${post.likes.length}',
                                              style: TextStyle(
                                                color: modernTheme.textSecondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              CupertinoIcons.chat_bubble,
                                              size: 16,
                                              color: modernTheme.textSecondaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${post.commentCount}',
                                              style: TextStyle(
                                                color: modernTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Action buttons
                                        Row(
                                          children: [
                                            // Like button
                                            IconButton(
                                              icon: Icon(
                                                post.likes.contains(currentUser?.uid)
                                                    ? CupertinoIcons.heart_fill
                                                    : CupertinoIcons.heart,
                                                color: post.likes.contains(currentUser?.uid)
                                                    ? Colors.red
                                                    : modernTheme.textSecondaryColor,
                                              ),
                                              onPressed: () {
                                                if (currentUser != null) {
                                                  Provider.of<StatusProvider>(context, listen: false).toggleLike(
                                                    postId: post.id,
                                                    userId: currentUser.uid,
                                                  );
                                                }
                                              },
                                              splashRadius: 20,
                                            ),
                                            
                                            // Share button
                                            IconButton(
                                              icon: Icon(
                                                CupertinoIcons.share,
                                                color: modernTheme.textSecondaryColor,
                                              ),
                                              onPressed: () {
                                                // Implement share functionality
                                              },
                                              splashRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Comments header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Comments (${comments.length})',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: modernTheme.textColor,
                                ),
                              ),
                            ),
                          ),
                          
                          // Comments list
                          comments.isEmpty
                              ? SliverToBoxAdapter(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: Text(
                                        'No comments yet. Be the first to comment!',
                                        style: TextStyle(
                                          color: modernTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return StatusCommentItem(
                                        comment: comments[index],
                                        currentUserId: currentUser?.uid ?? '',
                                      );
                                    },
                                    childCount: comments.length,
                                  ),
                                ),
                                
                          // Bottom padding
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 80),
                          ),
                        ],
                      ),
                    ),
                    
                    // Comment input field
                    Container(
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            // User avatar
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: currentUser?.image != null && currentUser!.image.isNotEmpty
                                  ? CachedNetworkImageProvider(currentUser.image)
                                  : const AssetImage(AssetsManager.userImage) as ImageProvider,
                            ),
                            const SizedBox(width: 8),
                            
                            // Comment input
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Send button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _addComment(currentUser),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: modernTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildMediaContent(StatusPost post) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (post.type) {
      case StatusType.image:
        if (post.mediaUrls.length == 1) {
          // Single image
          return CachedNetworkImage(
            imageUrl: post.mediaUrls[0],
            width: screenWidth,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 300,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 300,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          );
        } else {
          // Multiple images
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: post.mediaUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls[index],
                  width: screenWidth,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              );
            },
          );
        }
        
      case StatusType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  if (!_isVideoPlaying)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isVideoPlaying = true;
                          _videoController!.play();
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
              // Video controls
              if (_isVideoPlaying)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Play/pause button
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      
                      // Video progress
                      Expanded(
                        child: VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      ),
                      
                      // Duration
                      Text(
                        '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          );
        } else {
          // Video loading
          return Container(
            height: 300,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
      case StatusType.link:
        // Link preview
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Link preview image
              if (post.mediaUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.mediaUrls[0],
                    width: screenWidth,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.link),
                    ),
                  ),
                ),
              
              // Link info
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Open link
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        
      case StatusType.text:
      default:
        return const SizedBox();
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}