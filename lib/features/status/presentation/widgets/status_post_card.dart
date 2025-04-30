import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_reaction.dart';
import '../widgets/status_media_viewer.dart';
import '../widgets/status_reaction_button.dart';
import '../../application/providers/status_providers.dart';
import '../../application/providers/app_providers.dart';
import '../../../../constants.dart';

class StatusPostCard extends ConsumerStatefulWidget {
  final StatusPost post;
  final VoidCallback onTap;
  final Function(StatusPost post, BuildContext context) onLongPress;
  
  const StatusPostCard({
    Key? key,
    required this.post,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);
  
  @override
  ConsumerState<StatusPostCard> createState() => _StatusPostCardState();
}

class _StatusPostCardState extends ConsumerState<StatusPostCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _isVisible = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize video if the first media item is a video
    if (widget.post.media.isNotEmpty && widget.post.media.first.isVideo) {
      _initializeVideoController();
    }
  }
  
  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(StatusPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if post media changed
    if (widget.post.id != oldWidget.post.id ||
        widget.post.media.toString() != oldWidget.post.media.toString()) {
      _disposeVideoController();
      
      if (widget.post.media.isNotEmpty && widget.post.media.first.isVideo) {
        _initializeVideoController();
      }
    }
  }
  
  Future<void> _initializeVideoController() async {
    if (widget.post.media.isEmpty || !widget.post.media.first.isVideo) return;
    
    try {
      final videoUrl = widget.post.media.first.url;
      _videoController = VideoPlayerController.network(videoUrl);
      
      await _videoController!.initialize();
      
      // Use aspectRatio from video if height and width are not available
      _videoController!.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }
  
  void _disposeVideoController() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _isPlaying = false;
    }
  }
  
  void _playPauseVideo() {
    if (_videoController == null || !_isVideoInitialized) return;
    
    if (_isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }
  
  void _handleVisibilityChanged(VisibilityInfo info) {
    // Auto-play/pause video based on visibility
    if (_videoController != null && _isVideoInitialized) {
      final isVisible = info.visibleFraction > 0.7;
      
      setState(() {
        _isVisible = isVisible;
      });
      
      if (isVisible && !_isPlaying) {
        _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
      } else if (!isVisible && _isPlaying) {
        _videoController!.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return VisibilityDetector(
      key: Key('post-${widget.post.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: theme.cardColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: () => widget.onLongPress(widget.post, context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.post.authorImage.isNotEmpty
                          ? CachedNetworkImageProvider(widget.post.authorImage)
                          : null,
                      child: widget.post.authorImage.isEmpty
                          ? Icon(Icons.person, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.post.formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => widget.onLongPress(widget.post, context),
                    ),
                  ],
                ),
              ),
              
              // Content
              if (widget.post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    widget.post.content,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              
              // Media
              if (widget.post.media.isNotEmpty)
                _buildMediaContent(),
              
              // Link preview
              if (widget.post.linkUrl != null)
                _buildLinkPreview(),
              
              // Reactions and comments count
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
                child: Row(
                  children: [
                    if (widget.post.reactionCount > 0) ...[
                      Icon(
                        Icons.thumb_up_alt,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.reactionCount}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    
                    if (widget.post.commentCount > 0)
                      Text(
                        '${widget.post.commentCount} comments',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatusReactionButton(
                      post: widget.post,
                      onReact: _addReaction,
                    ),
                    TextButton.icon(
                      onPressed: widget.onTap,
                      icon: const Icon(Icons.comment_outlined, size: 20),
                      label: const Text('Comment'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _sharePost,
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMediaContent() {
    final media = widget.post.media;
    
    // For single media item
    if (media.length == 1) {
      return _buildSingleMedia(media.first);
    }
    
    // For multiple media items
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: media.length,
        itemBuilder: (context, index) {
          return _buildSingleMedia(media[index]);
        },
      ),
    );
  }
  
  Widget _buildSingleMedia(media) {
    if (media.isVideo) {
      // Video content
      return SizedBox(
        height: 400,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoController != null)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: media.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: media.thumbnailUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            
            // Play/pause button
            if (_isVideoInitialized && _videoController != null)
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 50,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: _playPauseVideo,
              ),
            
            // Video duration
            if (media.duration != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    media.formattedDuration ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Image content - use aspect ratio if available
      final aspectRatio = media.aspectRatio;
      
      return SizedBox(
        height: 400,
        child: CachedNetworkImage(
          imageUrl: media.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.error)),
          ),
        ),
      );
    }
  }
  
  Widget _buildLinkPreview() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.linkPreviewImage != null)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.post.linkPreviewImage!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.link, size: 40, color: Colors.grey),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.linkPreviewTitle != null)
                  Text(
                    widget.post.linkPreviewTitle!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                if (widget.post.linkPreviewDescription != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.post.linkPreviewDescription!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 4),
                Text(
                  widget.post.linkUrl!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addReaction(ReactionType reactionType) async {
    // Get current user
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;
    
    // Get current post detail provider
    final postDetailProvider = statusDetailProvider(widget.post.id);
    
    // Check if user already reacted
    final existingReaction = widget.post.getReactionByUser(currentUser.uid);
    
    if (existingReaction != null) {
      // Remove existing reaction if it's the same type
      if (existingReaction.type == reactionType) {
        await ref.read(postDetailProvider.notifier).removeReaction(
          reactionId: existingReaction.id,
          userId: currentUser.uid,
        );
        return;
      }
      
      // Otherwise, remove the old reaction and add the new one
      await ref.read(postDetailProvider.notifier).removeReaction(
        reactionId: existingReaction.id,
        userId: currentUser.uid,
      );
    }
    
    // Add new reaction
    await ref.read(postDetailProvider.notifier).addReaction(
      userId: currentUser.uid,
      userName: currentUser.name,
      userImage: currentUser.image,
      reactionType: reactionType,
    );
  }
  
  void _sharePost() {
    // Implementation for sharing
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('Share with contact'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context, 
                Constants.contactsScreen,
                arguments: {'sharePostId': widget.post.id}
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy link'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}