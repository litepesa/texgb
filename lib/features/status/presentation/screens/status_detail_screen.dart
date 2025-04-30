import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_reaction.dart';
import '../../application/providers/status_providers.dart';
import '../widgets/status_post_card.dart';
import '../widgets/status_comment_section.dart';
import '../widgets/status_media_viewer.dart';
import '../widgets/status_reaction_button.dart';
import '../../../../shared/theme/theme_extensions.dart';

class StatusDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  
  const StatusDetailScreen({
    Key? key,
    required this.postId,
  }) : super(key: key);
  
  @override
  ConsumerState<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends ConsumerState<StatusDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // Load post when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPost();
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadPost() async {
    final detailNotifier = ref.read(statusDetailProvider(widget.postId).notifier);
    await detailNotifier.loadPost();
    
    // Mark as viewed
    final currentUser = await ref.read(userProvider.future);
    if (currentUser != null) {
      detailNotifier.viewPost(currentUser.uid);
    }
  }
  
  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    // Add comment
    await ref.read(statusDetailProvider(widget.postId).notifier).addComment(
      userId: currentUser.uid,
      userName: currentUser.name,
      userImage: currentUser.image,
      content: text,
    );
    
    // Clear input
    _commentController.clear();
  }
  
  void _showMediaFullscreen(List<StatusMedia> media, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusMediaViewer(
          mediaItems: media,
          initialIndex: initialIndex,
          autoPlayVideos: true,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(statusDetailProvider(widget.postId));
    
    // Loading state
    if (detailState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    // Error state
    if (detailState.failure != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading status: ${detailState.failure.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPost,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Post not found
    if (detailState.post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status')),
        body: const Center(
          child: Text('Status not found or has been deleted'),
        ),
      );
    }
    
    // Show post
    final post = detailState.post!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(post.authorName),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostOptions(post),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: post.authorImage.isNotEmpty
                              ? CachedNetworkImageProvider(post.authorImage)
                              : null,
                          child: post.authorImage.isEmpty
                              ? Text(post.authorName[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                post.formattedDate,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  
                  // Media
                  if (post.media.isNotEmpty)
                    _buildMediaCarousel(post.media),
                  
                  // Link preview
                  if (post.linkUrl != null)
                    _buildLinkPreview(post),
                  
                  // Stats (views, reactions)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Views
                        _buildStatBadge(
                          icon: Icons.visibility,
                          count: post.viewCount,
                          label: 'views',
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Reactions
                        if (post.reactionCount > 0)
                          _buildStatBadge(
                            icon: Icons.thumb_up,
                            count: post.reactionCount,
                            label: 'reactions',
                          ),
                          
                        const Spacer(),
                        
                        // Privacy
                        _buildPrivacyBadge(post),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Reaction buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatusReactionButton(
                          post: post,
                          onReact: _addReaction,
                        ),
                        
                        TextButton.icon(
                          onPressed: () => _commentFocusNode.requestFocus(),
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
                  
                  const Divider(height: 1),
                  
                  // Comments section
                  StatusCommentSection(
                    comments: detailState.comments,
                    onDeleteComment: _deleteComment,
                  ),
                ],
              ),
            ),
          ),
          
          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                FutureBuilder(
                  future: ref.read(userProvider.future),
                  builder: (context, snapshot) {
                    final currentUser = snapshot.data;
                    
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: currentUser != null && currentUser.image.isNotEmpty
                          ? CachedNetworkImageProvider(currentUser.image)
                          : null,
                      child: currentUser == null || currentUser.image.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaCarousel(List<StatusMedia> mediaItems) {
    if (mediaItems.isEmpty) return const SizedBox();
    
    // For single media item
    if (mediaItems.length == 1) {
      return GestureDetector(
        onTap: () => _showMediaFullscreen(mediaItems, 0),
        child: SizedBox(
          height: 300,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: mediaItems.first.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => 
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => 
                const Center(child: Icon(Icons.error)),
          ),
        ),
      );
    }
    
    // For multiple media items
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: mediaItems.length,
        itemBuilder: (context, index) {
          final media = mediaItems[index];
          return GestureDetector(
            onTap: () => _showMediaFullscreen(mediaItems, index),
            child: CachedNetworkImage(
              imageUrl: media.isVideo && media.thumbnailUrl != null
                  ? media.thumbnailUrl!
                  : media.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => 
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => 
                  const Center(child: Icon(Icons.error)),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLinkPreview(StatusPost post) {
    if (post.linkUrl == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.linkPreviewImage != null)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: post.linkPreviewImage!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => 
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.link, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.linkPreviewTitle != null)
                    Text(
                      post.linkPreviewTitle!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  
                  if (post.linkPreviewDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.linkPreviewDescription!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Text(
                    post.linkUrl!,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatBadge({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrivacyBadge(StatusPost post) {
    IconData icon;
    String label;
    
    switch (post.privacy.type) {
      case PrivacyType.allContacts:
        icon = Icons.people;
        label = 'All Contacts';
        break;
      case PrivacyType.except:
        icon = Icons.person_remove;
        label = 'Some Contacts';
        break;
      case PrivacyType.onlySpecific:
        icon = Icons.person;
        label = 'Selected Contacts';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addReaction(ReactionType reactionType) async {
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    final detailNotifier = ref.read(statusDetailProvider(widget.postId).notifier);
    
    // Check if user already reacted
    final post = ref.read(statusDetailProvider(widget.postId)).post;
    if (post == null) return;
    
    final existingReaction = post.getReactionByUser(currentUser.uid);
    
    if (existingReaction != null) {
      // Remove existing reaction if it's the same type
      if (existingReaction.type == reactionType) {
        await detailNotifier.removeReaction(
          reactionId: existingReaction.id,
          userId: currentUser.uid,
        );
        return;
      }
      
      // Otherwise, remove the old reaction and add the new one
      await detailNotifier.removeReaction(
        reactionId: existingReaction.id,
        userId: currentUser.uid,
      );
    }
    
    // Add new reaction
    await detailNotifier.addReaction(
      userId: currentUser.uid,
      userName: currentUser.name,
      userImage: currentUser.image,
      reactionType: reactionType,
    );
  }
  
  Future<void> _deleteComment(String commentId) async {
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Delete the comment
    await ref.read(statusDetailProvider(widget.postId).notifier).deleteComment(
      commentId: commentId,
      userId: currentUser.uid,
    );
  }
  
  void _sharePost() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
  
  void _showPostOptions(StatusPost post) async {
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    // Check if this is the user's own post
    final isCurrentUserPost = post.authorId == currentUser.uid;
    
    // Check if author is muted
    final mutedUsers = ref.read(mutedUsersProvider);
    final isAuthorMuted = mutedUsers.contains(post.authorId);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUserPost) ...[
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete post'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit post'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditPost(post);
                },
              ),
            ] else ...[
              // Mute/unmute user
              ListTile(
                leading: Icon(isAuthorMuted ? Icons.volume_up : Icons.volume_off),
                title: Text(isAuthorMuted ? 'Unmute ${post.authorName}' : 'Mute ${post.authorName}'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleMuteUser(post.authorId, isAuthorMuted, currentUser.uid);
                },
              ),
            ],
            // Report option for all users
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(post);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _confirmDeletePost(StatusPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePost(StatusPost post) async {
    final currentUser = await ref.read(userProvider.future);
    if (currentUser == null) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    // Delete the post
    final result = await ref.read(statusControllerProvider).deleteStatusPost(
      postId: post.id,
      authorId: currentUser.uid,
    );
    
    // Hide loading indicator
    if (mounted) Navigator.pop(context);
    
    // Handle result
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: ${failure.toString()}')),
          );
        }
      },
      (_) {
        // Update local state
        ref.read(statusFeedProvider.notifier).removePost(post.id);
        ref.read(myStatusPostsProvider.notifier).removePost(post.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted')),
          );
          Navigator.pop(context); // Return to previous screen
        }
      },
    );
  }
  
  void _navigateToEditPost(StatusPost post) {
    Navigator.pushNamed(
      context,
      Constants.editStatusScreen,
      arguments: post,
    ).then((_) => _loadPost());
  }
  
  void _toggleMuteUser(String authorId, bool isCurrentlyMuted, String currentUserId) {
    if (isCurrentlyMuted) {
      // Unmute
      ref.read(mutedUsersProvider.notifier).unmuteUser(currentUserId, authorId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unmuted')),
      );
    } else {
      // Mute
      ref.read(mutedUsersProvider.notifier).muteUser(currentUserId, authorId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User muted. Their posts will no longer appear in your feed.')),
      );
    }
  }
  
  void _reportPost(StatusPost post) {
    // Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for reporting this post. We will review it.')),
    );
  }
}