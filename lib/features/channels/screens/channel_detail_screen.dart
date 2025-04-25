import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/channel_model.dart';
import 'package:textgb/features/channels/channel_post_model.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';
import 'package:textgb/features/channels/widgets/channel_post_item.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ChannelDetailScreen extends StatefulWidget {
  final String channelId;

  const ChannelDetailScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  bool _isLoading = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadChannelDetails();
  }

  Future<void> _loadChannelDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final channelProvider = context.read<ChannelProvider>();
        final userId = context.read<AuthenticationProvider>().userModel!.uid;
        
        // If selected channel is not set or different from the one we want
        if (channelProvider.selectedChannel == null || 
            channelProvider.selectedChannel!.id != widget.channelId) {
          // Fetch channel by ID
          final channel = await channelProvider.getChannelById(widget.channelId);
          if (channel != null) {
            channelProvider.setSelectedChannel(channel);
          }
        }
        
        // Check if user is subscribed
        if (channelProvider.selectedChannel != null) {
          setState(() {
            _isSubscribed = channelProvider.selectedChannel!.subscribersUIDs.contains(userId);
          });
        }
        
        // Fetch channel posts
        await channelProvider.fetchChannelPosts(channelId: widget.channelId);
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error loading channel: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _toggleSubscription() async {
    final channelProvider = context.read<ChannelProvider>();
    final userId = context.read<AuthenticationProvider>().userModel!.uid;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isSubscribed) {
        // Unsubscribe
        await channelProvider.unsubscribeFromChannel(
          channelId: widget.channelId,
          userId: userId,
          onSuccess: () {
            setState(() {
              _isSubscribed = false;
            });
            showSnackBar(context, 'Unsubscribed from channel');
          },
          onFail: (error) {
            showSnackBar(context, 'Error unsubscribing: $error');
          },
        );
      } else {
        // Subscribe
        await channelProvider.subscribeToChannel(
          channelId: widget.channelId,
          userId: userId,
          onSuccess: () {
            setState(() {
              _isSubscribed = true;
            });
            showSnackBar(context, 'Subscribed to channel');
          },
          onFail: (error) {
            showSnackBar(context, 'Error subscribing: $error');
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    return Consumer<ChannelProvider>(
      builder: (context, channelProvider, _) {
        final channel = channelProvider.selectedChannel;
        final posts = channelProvider.channelPosts;
        final userId = context.read<AuthenticationProvider>().userModel!.uid;
        final isAdmin = channel != null ? channelProvider.isUserAdmin(userId, channel.id) : false;
        
        if (channel == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Channel'),
            ),
            body: Center(
              child: _isLoading 
                ? CircularProgressIndicator(color: accentColor)
                : const Text('Channel not found'),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              channel.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Navigate to channel settings
                    Navigator.pushNamed(
                      context,
                      Constants.channelSettingsScreen,
                      arguments: channel,
                    ).then((_) => _loadChannelDetails());
                  },
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share channel functionality
                  showSnackBar(context, 'Share functionality coming soon');
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadChannelDetails,
            color: accentColor,
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : CustomScrollView(
                    slivers: [
                      // Channel header
                      SliverToBoxAdapter(
                        child: _buildChannelHeader(channel),
                      ),
                      
                      // Channel posts
                      posts.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No posts yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: modernTheme.textSecondaryColor,
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = posts[index];
                                  return ChannelPostItem(
                                    post: post,
                                    isAdmin: isAdmin,
                                    onReactionAdded: (reaction) {
                                      channelProvider.reactToPost(
                                        channelId: channel.id,
                                        postId: post.id,
                                        userId: userId,
                                        reaction: reaction,
                                        onSuccess: () {},
                                        onFail: (error) {
                                          showSnackBar(context, error);
                                        },
                                      );
                                    },
                                    onReactionRemoved: () {
                                      channelProvider.removeReaction(
                                        channelId: channel.id,
                                        postId: post.id,
                                        userId: userId,
                                        onSuccess: () {},
                                        onFail: (error) {
                                          showSnackBar(context, error);
                                        },
                                      );
                                    },
                                    onPostViewed: () {
                                      channelProvider.incrementPostViewCount(
                                        channelId: channel.id,
                                        postId: post.id,
                                      );
                                    },
                                    onPostDeleted: isAdmin ? () {
                                      _confirmDeletePost(context, post);
                                    } : null,
                                  );
                                },
                                childCount: posts.length,
                              ),
                            ),
                    ],
                  ),
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  backgroundColor: accentColor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateChannelPostScreen(
                          channelId: channel.id,
                        ),
                      ),
                    ).then((_) => _loadChannelDetails());
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildChannelHeader(ChannelModel channel) {
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: modernTheme.dividerColor!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel image
              CircleAvatar(
                radius: 40,
                backgroundColor: modernTheme.dividerColor,
                backgroundImage: channel.image.isNotEmpty
                    ? CachedNetworkImageProvider(channel.image) as ImageProvider
                    : const AssetImage(AssetsManager.userImage),
              ),
              const SizedBox(width: 16),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel name with verified badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            channel.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: modernTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (channel.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Subscriber count
                    if (channel.settings['showSubscriberCount'] == true)
                      Text(
                        '${channel.subscribersUIDs.length} subscribers',
                        style: TextStyle(
                          fontSize: 14,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Subscribe button
                    SizedBox(
                      width: 140,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _toggleSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubscribed
                              ? modernTheme.surfaceColor
                              : accentColor,
                          foregroundColor: _isSubscribed
                              ? accentColor
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSubscribed ? 'Subscribed' : 'Subscribe',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Channel description
          Text(
            channel.description,
            style: TextStyle(
              fontSize: 15,
              color: modernTheme.textColor!.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Divider(
            color: modernTheme.dividerColor,
            thickness: 0.5,
          ),
          const SizedBox(height: 8),
          // Posts heading
          Text(
            'Posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: modernTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, ChannelPostModel post) {
    showMyAnimatedDialog(
      context: context,
      title: 'Delete Post',
      content: 'Are you sure you want to delete this post? This action cannot be undone.',
      textAction: 'Delete',
      onActionTap: (confirmed) {
        if (confirmed) {
          final channelProvider = context.read<ChannelProvider>();
          channelProvider.deleteChannelPost(
            channelId: post.channelId,
            postId: post.id,
            onSuccess: () {
              showSnackBar(context, 'Post deleted successfully');
            },
            onFail: (error) {
              showSnackBar(context, 'Error deleting post: $error');
            },
          );
        }
      },
    );
  }
}