// ===============================
// Channel Profile Screen
// Display channel info and videos
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/features/channels/providers/channel_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/core/router/app_router.dart';

class ChannelProfileScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelProfileScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends ConsumerState<ChannelProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleFollow(ChannelModel channel) async {
    try {
      await ref.read(followChannelProvider.notifier).toggle(
            widget.channelId,
            channel.isFollowing,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow: $e')),
        );
      }
    }
  }

  void _navigateToEdit() {
    context.goToEditChannel(channelId: widget.channelId);
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final videosAsync = ref.watch(channelVideosProvider(widget.channelId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: channelAsync.when(
        data: (channel) => _buildProfile(channel, videosAsync, currentUser?.id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load channel: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(
    ChannelModel channel,
    AsyncValue<List<VideoModel>> videosAsync,
    String? currentUserId,
  ) {
    final isOwnChannel = currentUserId != null && channel.userId == currentUserId;

    return CustomScrollView(
      slivers: [
        // App Bar with channel header
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(channel, isOwnChannel),
          ),
        ),

        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'About'),
              ],
            ),
          ),
        ),

        // Tab Bar View
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVideosTab(videosAsync),
              _buildAboutTab(channel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ChannelModel channel, bool isOwnChannel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade100,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: CachedNetworkImageProvider(channel.channelAvatar),
            ),

            const SizedBox(height: 16),

            // Channel Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  channel.channelName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (channel.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat('Videos', channel.formattedVideos),
                const SizedBox(width: 24),
                _buildStat('Followers', channel.formattedFollowers),
                const SizedBox(width: 24),
                _buildStat('Views', channel.formattedViews),
              ],
            ),

            const SizedBox(height: 16),

            // Follow/Edit Button
            if (isOwnChannel)
              OutlinedButton.icon(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Channel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _handleFollow(channel),
                icon: Icon(channel.isFollowing ? Icons.check : Icons.add),
                label: Text(channel.isFollowing ? 'Following' : 'Follow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: channel.isFollowing ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVideosTab(AsyncValue<List<VideoModel>> videosAsync) {
    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(
            child: Text('No videos yet'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 9 / 16,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _buildVideoThumbnail(video);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildVideoThumbnail(VideoModel video) {
    return GestureDetector(
      onTap: () => context.goToChannelVideo(video.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[400],
              child: const Icon(Icons.play_circle_outline, size: 48),
            ),
          ),
          // Views count
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    video.formattedViews,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildAboutTab(ChannelModel channel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            channel.bio,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 24),

          // Category
          _buildInfoRow(Icons.category, 'Category', channel.category),

          if (channel.websiteUrl != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.link, 'Website', channel.websiteUrl!),
          ],

          if (channel.contactEmail != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Contact', channel.contactEmail!),
          ],

          // Tags
          if (channel.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: channel.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // Stats
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.videocam, 'Total Videos', channel.videosCount.toString()),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.remove_red_eye, 'Total Views', channel.formattedViews),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.favorite, 'Total Likes', channel.formattedLikes),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.people, 'Followers', channel.formattedFollowers),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

// Custom Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
