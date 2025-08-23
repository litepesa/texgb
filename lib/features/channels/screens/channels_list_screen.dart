// lib/features/channels/screens/channels_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/my_channel_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChannelsListScreen extends ConsumerStatefulWidget {
  const ChannelsListScreen({super.key});

  @override
  ConsumerState<ChannelsListScreen> createState() => _ChannelsListScreenState();
}

class _ChannelsListScreenState extends ConsumerState<ChannelsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  
  final List<String> categories = ['All', 'Following', 'Verified'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadChannels();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ChannelModel> get filteredChannels {
    final channelsState = ref.watch(channelsProvider);
    final followedChannels = channelsState.followedChannels;
    final userChannel = channelsState.userChannel;
    List<ChannelModel> channels;
    
    switch (_selectedCategory) {
      case 'Following':
        channels = channelsState.channels
            .where((channel) => followedChannels.contains(channel.id))
            .toList();
        break;
      case 'Verified':
        channels = channelsState.channels
            .where((channel) => channel.isVerified)
            .toList();
        break;
      default: // 'All'
        channels = channelsState.channels;
        break;
    }

    // Always filter out user's own channel
    if (userChannel != null) {
      channels.removeWhere((channel) => channel.id == userChannel.id);
    }
    
    // Sort by latest activity - most recent first
    channels.sort((a, b) {
      // Verified channels always come first (matching users list logic)
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      
      // Then sort by last activity
      final aLastPost = a.lastPostAt?.toDate();
      final bLastPost = b.lastPostAt?.toDate();
      
      // Channels with recent posts come first
      if (aLastPost != null && bLastPost != null) {
        return bLastPost.compareTo(aLastPost); // Most recent first
      }
      
      // Channels with any posts come before channels with no posts
      if (aLastPost != null && bLastPost == null) return -1;
      if (aLastPost == null && bLastPost != null) return 1;
      
      // For channels with no posts, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return channels;
  }

  Future<void> _navigateToChannelFeed(ChannelModel channel) async {
    try {
      HapticFeedback.lightImpact();
      
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(channel.id);
      
      if (videos.isNotEmpty) {
        Navigator.pushNamed(
          context,
          Constants.channelFeedScreen,
          arguments: videos.first.id,
        );
      } else {
        _showSnackBar('This channel has no videos yet');
        Navigator.pushNamed(
          context,
          Constants.channelProfileScreen,
          arguments: channel.id,
        );
      }
    } catch (e) {
      Navigator.pushNamed(
        context,
        Constants.channelProfileScreen,
        arguments: channel.id,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channelsState = ref.watch(channelsProvider);
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor, // Use surfaceColor as primary background
      body: SafeArea(
        child: Column(
          children: [

            
            // Category Filter Tabs - Enhanced Design
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor!.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                children: categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border(
                            bottom: BorderSide(
                              color: theme.primaryColor!,
                              width: 3,
                            ),
                          ) : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? theme.primaryColor!.withOpacity(0.15)
                                  : theme.primaryColor!.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: isSelected 
                                  ? theme.primaryColor 
                                  : theme.textSecondaryColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected 
                                    ? theme.primaryColor 
                                    : theme.textSecondaryColor,
                                  fontWeight: isSelected 
                                    ? FontWeight.w700 
                                    : FontWeight.w500,
                                  fontSize: 13,
                                  letterSpacing: 0.1,
                                ),
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Channels List
            Expanded(
              child: Container(
                color: theme.surfaceColor, // Consistent background
                child: _buildChannelsList(channelsState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Following':
        return Icons.favorite;
      case 'Verified':
        return Icons.verified;
      default:
        return Icons.grid_view;
    }
  }

  Widget _buildChannelsList(ChannelsState channelsState) {
    final theme = context.modernTheme;
    
    if (channelsState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading channels...',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (channelsState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.textTertiaryColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load channels',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                channelsState.error!,
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final channels = filteredChannels;

    if (channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getEmptyStateIcon(),
                color: theme.textTertiaryColor,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                _getEmptyStateTitle(),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyStateSubtitle(),
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedCategory == 'All') ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, Constants.createChannelScreen);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your Channel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
      },
      color: theme.primaryColor,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final channel = channels[index];
          return _buildChannelItem(channel);
        },
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedCategory) {
      case 'Following':
        return Icons.favorite_outline;
      case 'Verified':
        return Icons.verified_outlined;
      default:
        return Icons.business_outlined;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'No Followed Channels';
      case 'Verified':
        return 'No Verified Channels';
      default:
        return 'No Channels Available';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'Start following business channels to see them here';
      case 'Verified':
        return 'Verified business channels will appear here when available';
      default:
        return 'Business channels will appear here when available';
    }
  }

  Widget _buildChannelItem(ChannelModel channel) {
    final followedChannels = ref.watch(channelsProvider).followedChannels;
    final isFollowing = followedChannels.contains(channel.id);
    final theme = context.modernTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: channel.isVerified 
            ? Colors.blue.withOpacity(0.3)
            : theme.dividerColor!.withOpacity(0.15),
          width: channel.isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: channel.isVerified 
              ? Colors.blue.withOpacity(0.12)
              : theme.primaryColor!.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToChannelFeed(channel),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: channel.isVerified ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ) : null,
            child: Row(
              children: [
                // Enhanced Channel Avatar - matching users list exactly
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: channel.isVerified ? LinearGradient(
                          colors: [Colors.blue.shade300, Colors.indigo.shade400],
                        ) : null,
                        border: !channel.isVerified ? Border.all(
                          color: theme.dividerColor!.withOpacity(0.2),
                          width: 1,
                        ) : null,
                        boxShadow: [
                          BoxShadow(
                            color: (channel.isVerified ? Colors.blue : theme.primaryColor!)
                                .withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: channel.profileImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: channel.profileImage,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor!.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.business_rounded,
                                      color: theme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor!.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'B',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor!.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'B',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    // Verified indicator on avatar - exactly like users list
                    if (channel.isVerified)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.surfaceColor!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced Channel Info with proper flex control - matching users list
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Channel name with prominent verified badge - exactly like users list
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              channel.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Enhanced stats with proper wrapping - matching users list
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatChip(
                              icon: Icons.video_library_outlined,
                              text: '${channel.videosCount} posts',
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.people_outline_rounded,
                              text: _formatCount(channel.followers),
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Last activity with enhanced styling - matching users list
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor!.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                channel.lastPostAt != null 
                                  ? 'Active ${_getTimeAgo(channel.lastPostAt!.toDate())}'
                                  : 'New channel',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Enhanced Follow Button with better constraints - matching users list
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(channelsProvider.notifier).toggleFollowChannel(channel.id);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        maxWidth: 100,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFollowing ? theme.surfaceVariantColor : theme.primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFollowing 
                            ? theme.dividerColor!.withOpacity(0.3)
                            : theme.primaryColor!,
                          width: 1,
                        ),
                        boxShadow: !isFollowing ? [
                          BoxShadow(
                            color: theme.primaryColor!.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isFollowing 
                                ? theme.primaryColor!.withOpacity(0.15)
                                : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              isFollowing ? Icons.check_rounded : Icons.add_rounded,
                              color: isFollowing ? theme.primaryColor : Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? theme.primaryColor : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    required theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: theme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

// Search Delegate for Channel Search
class ChannelSearchDelegate extends SearchDelegate<ChannelModel?> {
  final List<ChannelModel> channels;
  final Function(ChannelModel) onChannelSelected;

  ChannelSearchDelegate({
    required this.channels,
    required this.onChannelSelected,
  });

  @override
  String get searchFieldLabel => 'Search channels...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>()!;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: theme.textSecondaryColor),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final theme = context.modernTheme;
    
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find business channels and creators',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    final filteredChannels = channels.where((channel) {
      return channel.name.toLowerCase().contains(query.toLowerCase()) ||
             channel.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: theme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No channels found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredChannels.length,
        itemBuilder: (context, index) {
          final channel = filteredChannels[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor!.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                close(context, channel);
                onChannelSelected(channel);
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // Channel Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.dividerColor!.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: channel.profileImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: channel.profileImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.primaryColor!.withOpacity(0.1),
                                child: Icon(
                                  Icons.business_rounded,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.primaryColor!.withOpacity(0.15),
                                child: Center(
                                  child: Text(
                                    channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'B',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: theme.primaryColor!.withOpacity(0.15),
                              child: Center(
                                child: Text(
                                  channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'B',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Channel Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                channel.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (channel.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${channel.videosCount} posts • ${_formatCount(channel.followers)} followers',
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        if (channel.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            channel.description,
                            style: TextStyle(
                              color: theme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}