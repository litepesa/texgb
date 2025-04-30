import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../application/providers/status_providers.dart';
import '../../application/providers/app_providers.dart';
import '../../domain/models/status_post.dart';
import '../widgets/status_post_card.dart';
import '../widgets/status_empty_state.dart';
import '../widgets/status_error_state.dart';
import '../../../../constants.dart';
import '../../../../features/authentication/authentication_provider.dart';

class StatusFeedScreen extends ConsumerStatefulWidget {
  const StatusFeedScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<StatusFeedScreen> createState() => _StatusFeedScreenState();
}

class _StatusFeedScreenState extends ConsumerState<StatusFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _initialLoadDone = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Load feed on first render with a short delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }
  
  Future<void> _refreshFeed() async {
    // Get current user from Provider
    final authProvider = AuthenticationProvider.of(context);
    final currentUser = authProvider.userModel;
    
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view status updates')),
        );
      }
      return;
    }
    
    // Update Riverpod user provider
    ref.read(userProvider.notifier).state = currentUser;
    
    // Get muted users
    await ref.read(mutedUsersProvider.notifier).loadMutedUsers(currentUser.uid);
    final mutedUsers = ref.read(mutedUsersProvider);
    
    // Load the feed
    ref.read(statusFeedProvider.notifier).loadStatusFeed(
      userId: currentUser.uid,
      contactIds: currentUser.contactsUIDs,
      mutedUserIds: mutedUsers,
    );
    
    // Mark initial load as complete
    if (mounted) {
      setState(() {
        _initialLoadDone = true;
      });
    }
  }
  
  void _loadMorePosts() async {
    // Get current user
    final currentUser = ref.read(userProvider);
    
    if (currentUser == null) return;
    
    // Get current feed state
    final feedState = ref.read(statusFeedProvider);
    
    // Don't load more if already loading or no more posts
    if (feedState.isLoading || !feedState.hasMore) return;
    
    // Get muted users
    final mutedUsers = ref.read(mutedUsersProvider);
    
    // Load more posts
    ref.read(statusFeedProvider.notifier).loadMorePosts(
      userId: currentUser.uid,
      contactIds: currentUser.contactsUIDs,
      mutedUserIds: mutedUsers,
    );
  }
  
  void _navigateToCreateStatus() {
    Navigator.pushNamed(context, Constants.createStatusScreen)
        .then((_) => _refreshFeed());
  }
  
  void _navigateToStatusDetail(StatusPost post) {
    Navigator.pushNamed(
      context,
      Constants.statusDetailScreen,
      arguments: post.id,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(statusFeedProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Constants.statusSettingsScreen),
          ),
        ],
      ),
      body: _buildBody(feedState),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateStatus,
        child: const Icon(Icons.add_photo_alternate),
        tooltip: 'Create new status',
      ),
    );
  }
  
  Widget _buildBody(feedState) {
    // Check if user is authenticated
    final currentUser = ref.watch(userProvider);
    
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please log in to view status updates'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Constants.loginScreen),
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }
    
    // Show loading state
    if (!_initialLoadDone || (feedState.isLoading && feedState.posts.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Show error state
    if (feedState.failure != null && feedState.posts.isEmpty) {
      return StatusErrorState(
        failure: feedState.failure!,
        onRetry: _refreshFeed,
      );
    }
    
    // Show empty state
    if (feedState.posts.isEmpty) {
      return StatusEmptyState(
        onCreateStatus: _navigateToCreateStatus,
      );
    }
    
    // Show feed with posts
    return RefreshIndicator(
      onRefresh: _refreshFeed,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: feedState.posts.length + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom while loading more
          if (index == feedState.posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Show post
          final post = feedState.posts[index];
          return StatusPostCard(
            post: post,
            onTap: () => _navigateToStatusDetail(post),
            onLongPress: _showPostOptions,
          );
        },
      ),
    );
  }
  
  void _showPostOptions(StatusPost post, BuildContext context) async {
    final currentUser = ref.read(userProvider);
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
    final currentUser = ref.read(userProvider);
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
        }
      },
    );
  }
  
  void _navigateToEditPost(StatusPost post) {
    // This functionality might not be fully implemented yet
    Navigator.pushNamed(
      context,
      Constants.editStatusScreen,
      arguments: post.id,
    ).then((_) => _refreshFeed());
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
      
      // Refresh feed to remove posts
      _refreshFeed();
    }
  }
  
  void _reportPost(StatusPost post) {
    // Implement report functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Inappropriate content'),
              leading: Radio<String>(
                value: 'inappropriate',
                groupValue: null,
                onChanged: (_) {},
              ),
            ),
            ListTile(
              title: const Text('Spam or misleading'),
              leading: Radio<String>(
                value: 'spam',
                groupValue: null,
                onChanged: (_) {},
              ),
            ),
            ListTile(
              title: const Text('Harassment or bullying'),
              leading: Radio<String>(
                value: 'harassment',
                groupValue: null,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for reporting this post. We will review it.'),
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}