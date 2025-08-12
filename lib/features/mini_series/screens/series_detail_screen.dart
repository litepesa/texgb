// lib/features/mini_series/screens/series_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import '../providers/mini_series_provider.dart';
import '../widgets/episode_card.dart';
import '../widgets/comment_widget.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/tag_input_widget.dart';
import '../models/mini_series_model.dart';
import '../models/episode_model.dart';
import '../models/comment_model.dart';
import 'create_episode_screen.dart';
import 'episode_player_screen.dart';
import 'series_analytics_screen.dart';
import '../../authentication/providers/auth_providers.dart';


class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({
    super.key,
    required this.seriesId,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isAppBarExpanded = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    
    // Listen to scroll to manage app bar
    _scrollController.addListener(_onScroll);
    
    // Load series and episodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadSeries(widget.seriesId);
      ref.read(miniSeriesProvider.notifier).loadEpisodes(widget.seriesId);
      ref.read(miniSeriesProvider.notifier).loadAnalytics(widget.seriesId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const expandedHeight = 300.0;
    const threshold = expandedHeight - kToolbarHeight - 50;
    
    final isExpanded = _scrollController.hasClients &&
        _scrollController.offset < threshold;
    
    if (isExpanded != _isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    
    return Consumer(
      builder: (context, ref, child) {
        final currentSeries = ref.watch(currentSeriesProvider);
        final episodes = ref.watch(seriesEpisodesProvider);
        final analytics = ref.watch(seriesAnalyticsProvider);
        final miniSeriesState = ref.watch(miniSeriesProvider);
        
        if (currentSeries == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Series Details'),
            ),
            body: miniSeriesState.when(
              data: (_) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Series not found'),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isCreator = currentUser?.uid == currentSeries.creatorUID;
        final publishedEpisodes = episodes.where((e) => e.isPublished || isCreator).toList();

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(currentSeries, isCreator, theme),
            ],
            body: Column(
              children: [
                // Series info and stats
                _buildSeriesInfo(currentSeries, analytics, theme),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  tabs: const [
                    Tab(text: 'Episodes'),
                    Tab(text: 'About'),
                    Tab(text: 'Comments'),
                    Tab(text: 'Related'),
                  ],
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEpisodesTab(publishedEpisodes, isCreator, currentSeries),
                      _buildAboutTab(currentSeries, theme),
                      _buildCommentsTab(currentSeries),
                      _buildRelatedTab(currentSeries),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(currentSeries, isCreator),
        );
      },
    );
  }

  Widget _buildSliverAppBar(MiniSeriesModel series, bool isCreator, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            CachedNetworkImage(
              imageUrl: series.coverImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Series info overlay
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    series.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Creator info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: series.creatorImage.isNotEmpty
                            ? CachedNetworkImageProvider(series.creatorImage)
                            : null,
                        child: series.creatorImage.isEmpty
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          series.creatorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Status badges
                      if (!series.isPublished && isCreator) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'DRAFT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      if (series.isPublished)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Play button for featured episode
            if (series.totalEpisodes > 0)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _playFirstEpisode(),
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Share button
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareSeries(series),
        ),
        
        // Creator menu or follow button
        if (isCreator)
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_episode',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Episode'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit_series',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Series'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Analytics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!series.isPublished)
                const PopupMenuItem(
                  value: 'publish',
                  child: ListTile(
                    leading: Icon(Icons.publish),
                    title: Text('Publish Series'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Series', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) => _handleCreatorAction(value, series),
          )
        else
          IconButton(
            icon: Icon(_isFollowing ? Icons.favorite : Icons.favorite_border),
            color: _isFollowing ? Colors.red : null,
            onPressed: _toggleFollow,
          ),
      ],
    );
  }

  Widget _buildSeriesInfo(MiniSeriesModel series, analytics, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats row
          Row(
            children: [
              _buildStatItem('Episodes', series.totalEpisodes.toString(), theme),
              const SizedBox(width: 24),
              _buildStatItem('Views', _formatCount(series.totalViews), theme),
              const SizedBox(width: 24),
              _buildStatItem('Likes', _formatCount(series.totalLikes), theme),
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  // Like button
                  IconButton(
                    icon: const Icon(Icons.thumb_up_outlined),
                    onPressed: _likeSeries,
                  ),
                  
                  // Add to playlist
                  IconButton(
                    icon: const Icon(Icons.playlist_add),
                    onPressed: _addToPlaylist,
                  ),
                  
                  // Download for offline
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    onPressed: _downloadSeries,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Category and tags
          if (series.category.isNotEmpty || series.tags.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    series.category,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (series.tags.isNotEmpty)
                  Expanded(
                    child: TagDisplayWidget(
                      tags: series.tags,
                      maxTags: 3,
                      onMoreTapped: () => _showAllTags(series.tags),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Description preview
          if (series.description.isNotEmpty) ...[
            Text(
              series.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (series.description.length > 150)
              TextButton(
                onPressed: () => _showFullDescription(series.description),
                child: const Text('Read more'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesTab(List<EpisodeModel> episodes, bool isCreator, MiniSeriesModel series) {
    if (episodes.isEmpty) {
      return _buildEmptyEpisodesState(isCreator, series);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(miniSeriesProvider.notifier).loadEpisodes(widget.seriesId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: episodes.length + (isCreator ? 1 : 0),
        itemBuilder: (context, index) {
          // Add episode button for creators
          if (isCreator && index == episodes.length) {
            return _buildAddEpisodeCard(series);
          }
          
          final episode = episodes[index];
          final currentUser = ref.read(currentUserProvider);
          final isLiked = currentUser != null && episode.isLikedBy(currentUser.uid);
          
          return EpisodeCard(
            episode: episode,
            onTap: () => _playEpisode(episode),
            onLike: () => _toggleEpisodeLike(episode, isLiked),
            onComment: () => _showEpisodeComments(episode),
            isLiked: isLiked,
          );
        },
      ),
    );
  }

  Widget _buildEmptyEpisodesState(bool isCreator, MiniSeriesModel series) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isCreator ? 'No episodes yet' : 'No episodes available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isCreator 
                  ? 'Add your first episode to get started'
                  : 'Check back later for new episodes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (isCreator) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _addNewEpisode(series),
                icon: const Icon(Icons.add),
                label: const Text('Add First Episode'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddEpisodeCard(MiniSeriesModel series) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _addNewEpisode(series),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Episode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create episode ${series.totalEpisodes + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab(MiniSeriesModel series, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full description
          if (series.description.isNotEmpty) ...[
            Text(
              'Description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              series.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          
          // Creator information
          Text(
            'Creator',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: series.creatorImage.isNotEmpty
                  ? CachedNetworkImageProvider(series.creatorImage)
                  : null,
              child: series.creatorImage.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(series.creatorName),
            subtitle: const Text('Series Creator'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _viewCreatorProfile(series.creatorUID),
          ),
          
          const SizedBox(height: 24),
          
          // Series stats
          Text(
            'Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Views', series.totalViews.toString(), Icons.visibility, theme),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Total Likes', series.totalLikes.toString(), Icons.favorite, theme),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Episodes', series.totalEpisodes.toString(), Icons.play_circle, theme),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Comments', series.totalComments.toString(), Icons.comment, theme),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tags section
          if (series.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TagDisplayWidget(tags: series.tags),
            const SizedBox(height: 24),
          ],
          
          // Creation date
          Text(
            'Series Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildInfoRow('Category', series.category, theme),
          _buildInfoRow('Language', series.language, theme),
          _buildInfoRow('Created', _formatDate(series.createdAt), theme),
          _buildInfoRow('Last Updated', _formatDate(series.updatedAt), theme),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(MiniSeriesModel series) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Series comments coming soon'),
          SizedBox(height: 8),
          Text(
            'For now, you can comment on individual episodes',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedTab(MiniSeriesModel series) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recommend_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Related series coming soon'),
          SizedBox(height: 8),
          Text(
            'We\'ll show similar series based on your interests',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(MiniSeriesModel series, bool isCreator) {
    if (!isCreator) return null;
    
    return FloatingActionButton.extended(
      onPressed: () => _addNewEpisode(series),
      icon: const Icon(Icons.add),
      label: const Text('Add Episode'),
    );
  }

  // Action handlers
  void _handleCreatorAction(String action, MiniSeriesModel series) {
    switch (action) {
      case 'add_episode':
        _addNewEpisode(series);
        break;
      case 'edit_series':
        _editSeries(series);
        break;
      case 'analytics':
        _viewAnalytics(series);
        break;
      case 'publish':
        _publishSeries(series);
        break;
      case 'delete':
        _confirmDeleteSeries(series);
        break;
    }
  }

  void _addNewEpisode(MiniSeriesModel series) {
    final episodes = ref.read(seriesEpisodesProvider);
    final nextEpisodeNumber = episodes.length + 1;
    
    if (nextEpisodeNumber > 100) {
      showSnackBar(context, 'Maximum 100 episodes per series allowed');
      return;
    }
    
    Navigator.pushNamed(
      context,
      '/createEpisodeScreen',
      arguments: {
        'seriesId': series.seriesId,
        'seriesTitle': series.title,
        'episodeNumber': nextEpisodeNumber,
      },
    ).then((_) {
      // Refresh episodes after returning
      ref.read(miniSeriesProvider.notifier).loadEpisodes(widget.seriesId);
    });
  }

  void _editSeries(MiniSeriesModel series) {
    // Navigate to edit series screen
    showSnackBar(context, 'Edit series feature coming soon');
  }

  void _viewAnalytics(MiniSeriesModel series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesAnalyticsScreen(series: series),
      ),
    );
  }

  void _publishSeries(MiniSeriesModel series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Series'),
        content: const Text(
          'Are you sure you want to publish this series? '
          'Once published, it will be visible to all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(miniSeriesProvider.notifier).updateSeries(
                series.copyWith(isPublished: true),
              );
              showSnackBar(context, 'Series published successfully!');
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSeries(MiniSeriesModel series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Series'),
        content: Text(
          'Are you sure you want to delete "${series.title}"? '
          'This action cannot be undone and will delete all episodes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              ref.read(miniSeriesProvider.notifier).deleteSeries(series.seriesId);
              showSnackBar(context, 'Series deleted successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _playFirstEpisode() {
    final episodes = ref.read(seriesEpisodesProvider);
    if (episodes.isNotEmpty) {
      _playEpisode(episodes.first);
    }
  }

  void _playEpisode(EpisodeModel episode) {
    Navigator.pushNamed(
      context,
      '/episodePlayerScreen',
      arguments: {
        'episodeId': episode.episodeId,
        'seriesId': episode.seriesId,
      },
    );
  }

  void _toggleEpisodeLike(EpisodeModel episode, bool isLiked) {
    if (isLiked) {
      ref.read(miniSeriesProvider.notifier).unlikeEpisode(episode.episodeId);
    } else {
      ref.read(miniSeriesProvider.notifier).likeEpisode(episode.episodeId);
    }
  }

  void _showEpisodeComments(EpisodeModel episode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EpisodeCommentsSheet(
            episode: episode,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  void _shareSeries(MiniSeriesModel series) {
    final shareText = '${series.title}\n'
        'by ${series.creatorName}\n'
        '${series.totalEpisodes} episodes • ${_formatCount(series.totalViews)} views\n'
        'Watch on Mini Series App';
    
    Share.share(
      shareText,
      subject: 'Check out this mini series: ${series.title}',
    );
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    showSnackBar(
      context,
      _isFollowing ? 'Following series' : 'Unfollowed series',
    );
  }

  void _likeSeries() {
    // Implement series like functionality
    showSnackBar(context, 'Series liked!');
  }

  void _addToPlaylist() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add to Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Playlist'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Creating new playlist...');
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Watch Later'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Added to Watch Later');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.of(context).pop();
                showSnackBar(context, 'Added to Favorites');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadSeries() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Series'),
        content: const Text(
          'Download all episodes for offline viewing? '
          'This may use significant storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showSnackBar(context, 'Download started...');
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showAllTags(List<String> tags) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Tags'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => Chip(label: Text(tag))).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFullDescription(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Description'),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewCreatorProfile(String creatorUID) {
    // Navigate to creator profile
    showSnackBar(context, 'Creator profile feature coming soon');
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}

// Episode Comments Bottom Sheet Widget
class EpisodeCommentsSheet extends ConsumerStatefulWidget {
  final EpisodeModel episode;
  final ScrollController scrollController;

  const EpisodeCommentsSheet({
    super.key,
    required this.episode,
    required this.scrollController,
  });

  @override
  ConsumerState<EpisodeCommentsSheet> createState() => _EpisodeCommentsSheetState();
}

class _EpisodeCommentsSheetState extends ConsumerState<EpisodeCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load comments for this episode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadComments(widget.episode.episodeId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = ref.watch(episodeCommentsProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Comments (${comments.length})',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Comments list
        Expanded(
          child: comments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No comments yet'),
                      Text(
                        'Be the first to comment!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isLiked = currentUser != null && 
                        comment.isLikedBy(currentUser.uid);
                    
                    return CommentWidget(
                      comment: comment,
                      isLiked: isLiked,
                      onLike: () => _toggleCommentLike(comment, isLiked),
                      canDelete: currentUser?.uid == comment.authorUID,
                      onDelete: () => _deleteComment(comment),
                      onReply: () => _replyToComment(comment),
                    );
                  },
                ),
        ),
        
        // Add comment input
        if (currentUser != null) _buildCommentInput(theme, currentUser),
      ],
    );
  }

  Widget _buildCommentInput(ThemeData theme, currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: currentUser.image.isNotEmpty
                  ? CachedNetworkImageProvider(currentUser.image)
                  : null,
              child: currentUser.image.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addComment,
              icon: Icon(
                Icons.send,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addComment() {
    final content = _commentController.text.trim();
    if (content.isNotEmpty) {
      ref.read(miniSeriesProvider.notifier).addComment(
        episodeId: widget.episode.episodeId,
        seriesId: widget.episode.seriesId,
        content: content,
      );
      _commentController.clear();
    }
  }

  void _toggleCommentLike(EpisodeCommentModel comment, bool isLiked) {
    if (isLiked) {
      ref.read(miniSeriesProvider.notifier).unlikeComment(comment.commentId);
    } else {
      ref.read(miniSeriesProvider.notifier).likeComment(comment.commentId);
    }
  }

  void _deleteComment(EpisodeCommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(miniSeriesProvider.notifier).deleteComment(comment.commentId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _replyToComment(EpisodeCommentModel comment) {
    _commentController.text = '@${comment.authorName} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
  }
}