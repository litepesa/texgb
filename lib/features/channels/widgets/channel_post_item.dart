import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/channels/channel_post_model.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/modern_colors.dart';

class ChannelPostItem extends StatefulWidget {
  final ChannelPostModel post;
  final bool isAdmin;
  final Function(String) onReactionAdded;
  final VoidCallback onReactionRemoved;
  final VoidCallback onPostViewed;
  final VoidCallback? onPostDeleted;

  const ChannelPostItem({
    Key? key,
    required this.post,
    required this.isAdmin,
    required this.onReactionAdded,
    required this.onReactionRemoved,
    required this.onPostViewed,
    this.onPostDeleted,
  }) : super(key: key);

  @override
  State<ChannelPostItem> createState() => _ChannelPostItemState();
}

class _ChannelPostItemState extends State<ChannelPostItem> {
  UserModel? _postCreator;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPostCreator();
    _initializeVideo();
    
    // Mark post as viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPostViewed();
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadPostCreator() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final creator = await context.read<ChannelProvider>().getUserForPost(
        widget.post.creatorUID,
      );
      
      if (mounted) {
        setState(() {
          _postCreator = creator;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.post.messageType == MessageEnum.video && widget.post.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.post.mediaUrl);
      
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
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

  void _showReactionOptions(BuildContext context) {
    final userId = context.read<AuthenticationProvider>().userModel!.uid;
    final modernTheme = context.modernTheme;
    
    // Check if user already reacted
    final hasReacted = widget.post.reactions.containsKey(userId);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: hasReacted ? 140 : 100,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _reactionButton('❤️', 'love'),
                  _reactionButton('👍', 'like'),
                  _reactionButton('😂', 'haha'),
                  _reactionButton('😮', 'wow'),
                  _reactionButton('😢', 'sad'),
                ],
              ),
              if (hasReacted)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: TextButton(
                    onPressed: () {
                      widget.onReactionRemoved();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Remove Reaction',
                      style: TextStyle(
                        color: ModernColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _reactionButton(String emoji, String reactionType) {
    return GestureDetector(
      onTap: () {
        widget.onReactionAdded(reactionType);
        Navigator.pop(context);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildPostMedia() {
    switch (widget.post.messageType) {
      case MessageEnum.image:
        return Container(
          constraints: const BoxConstraints(
            maxHeight: 400,
          ),
          child: CachedNetworkImage(
            imageUrl: widget.post.mediaUrl,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            fit: BoxFit.cover,
          ),
        );
      case MessageEnum.video:
        if (_isVideoInitialized && _videoController != null) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
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
            ],
          );
        } else {
          return Container(
            height: 200,
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final userId = context.read<AuthenticationProvider>().userModel!.uid;
    
    // Get user's reaction if any
    final userReaction = widget.post.reactions[userId];
    
    // Get total reactions count
    final reactionsCount = widget.post.reactions.length;
    
    // Check if post is pinned
    final isPinned = widget.post.isPinned;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Creator avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: modernTheme.dividerColor,
                  backgroundImage: _postCreator?.image != null && _postCreator!.image.isNotEmpty
                      ? CachedNetworkImageProvider(_postCreator!.image) as ImageProvider
                      : const AssetImage(AssetsManager.userImage),
                ),
                const SizedBox(width: 12),
                // Creator name and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _postCreator?.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: modernTheme.textColor,
                            ),
                          ),
                          if (isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: modernTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                fontSize: 12,
                                color: modernTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Post options
                if (widget.isAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: modernTheme.textSecondaryColor,
                    ),
                    onSelected: (value) {
                      if (value == 'delete' && widget.onPostDeleted != null) {
                        widget.onPostDeleted!();
                      } else if (value == 'pin') {
                        // Toggle pin status
                        context.read<ChannelProvider>().togglePinPost(
                          channelId: widget.post.channelId,
                          postId: widget.post.id,
                          isPinned: !widget.post.isPinned,
                          onSuccess: () {},
                          onFail: (error) {
                            showSnackBar(context, 'Error: $error');
                          },
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'pin',
                        child: Text(widget.post.isPinned ? 'Unpin Post' : 'Pin Post'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete Post'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Post message
          if (widget.post.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.post.message,
                style: TextStyle(
                  fontSize: 16,
                  color: modernTheme.textColor,
                ),
              ),
            ),
          // Post media
          if (widget.post.messageType != MessageEnum.text)
            _buildPostMedia(),
          // Post stats and actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reaction count
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 18,
                      color: reactionsCount > 0
                          ? Colors.red
                          : modernTheme.textSecondaryColor!.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      reactionsCount > 0 ? '$reactionsCount' : '',
                      style: TextStyle(
                        fontSize: 14,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                // View count
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 18,
                      color: modernTheme.textSecondaryColor!.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.viewCount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            color: modernTheme.dividerColor,
            height: 1,
          ),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Like/React button
              TextButton.icon(
                onPressed: () {
                  _showReactionOptions(context);
                },
                icon: Icon(
                  userReaction != null ? Icons.favorite : Icons.favorite_border,
                  color: userReaction != null ? Colors.red : modernTheme.textSecondaryColor,
                  size: 20,
                ),
                label: Text(
                  userReaction != null ? 'Reacted' : 'React',
                  style: TextStyle(
                    color: userReaction != null ? Colors.red : modernTheme.textSecondaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              // Share button
              TextButton.icon(
                onPressed: () {
                  // Share post functionality
                  showSnackBar(context, 'Share functionality coming soon');
                },
                icon: Icon(
                  Icons.share,
                  color: modernTheme.textSecondaryColor,
                  size: 20,
                ),
                label: Text(
                  'Share',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}