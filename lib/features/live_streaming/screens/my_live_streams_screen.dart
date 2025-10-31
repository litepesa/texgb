// lib/features/live_streaming/screens/my_live_streams_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/live_streaming/models/refined_live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_model.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/live_streaming/routes/live_streaming_routes.dart';

class MyLiveStreamsScreen extends ConsumerStatefulWidget {
  const MyLiveStreamsScreen({super.key});

  @override
  ConsumerState<MyLiveStreamsScreen> createState() => _MyLiveStreamsScreenState();
}

class _MyLiveStreamsScreenState extends ConsumerState<MyLiveStreamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'My Live Streams',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.pushToCreateLiveStream();
            },
            icon: const Icon(Icons.add_circle, color: Colors.red),
            tooltip: 'Start new stream',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Live'),
            Tab(text: 'Ended'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamList(null),
          _buildStreamList(LiveStreamStatus.live),
          _buildStreamList(LiveStreamStatus.ended),
        ],
      ),
    );
  }

  Widget _buildStreamList(LiveStreamStatus? filter) {
    // TODO: Get from provider
    // final streamsAsync = ref.watch(myLiveStreamsProvider(filter: filter));

    // Mock data for now
    return _buildMockList();
  }

  Widget _buildMockList() {
    // Mock empty state for demonstration
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No streams yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start your first live stream\nand connect with your audience',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.pushToCreateLiveStream(),
            icon: const Icon(Icons.play_circle_fill),
            label: const Text(
              'Start Live Stream',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedList(List<RefinedLiveStreamModel> streams) {
    if (streams.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh streams
      },
      color: Colors.red,
      backgroundColor: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: streams.length,
        itemBuilder: (context, index) {
          final stream = streams[index];
          return _StreamCard(stream: stream);
        },
      ),
    );
  }
}

class _StreamCard extends StatelessWidget {
  final RefinedLiveStreamModel stream;

  const _StreamCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: stream.thumbnailUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                  ),
                ),
              ),

              // Status badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stream.isLive ? Colors.red : Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stream.isLive) ...[
                        const Icon(Icons.circle, color: Colors.white, size: 8),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        stream.isLive ? 'LIVE' : stream.status.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Type badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: stream.isGiftStream
                        ? Colors.purple.withOpacity(0.9)
                        : Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stream.isGiftStream ? '🎁 Gift' : '🛍️ Shop',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Duration overlay (for ended streams)
              if (stream.isEnded)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          stream.durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Stream info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  stream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Stats
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.remove_red_eye,
                      value: stream.viewersText,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      icon: Icons.favorite,
                      value: '${stream.likesCount}',
                      color: Colors.red,
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      icon: Icons.attach_money,
                      value: stream.formattedRevenue,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    if (stream.isLive)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.goToLiveStreamHost(stream.id);
                          },
                          icon: const Icon(Icons.play_circle_fill, size: 20),
                          label: const Text('Continue Streaming'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.goToLiveStreamAnalytics(stream.id);
                          },
                          icon: const Icon(Icons.bar_chart, size: 20),
                          label: const Text('View Analytics'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // TODO: Show more options (delete, share replay, etc.)
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
