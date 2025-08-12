// lib/features/mini_series/screens/mini_series_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/mini_series_provider.dart';
import '../models/mini_series_model.dart';
import '../widgets/series_card.dart';
import '../widgets/search_bar.dart';
import 'series_detail_screen.dart';
import 'create_series_screen.dart';

class MiniSeriesFeedScreen extends ConsumerStatefulWidget {
  const MiniSeriesFeedScreen({super.key});

  @override
  ConsumerState<MiniSeriesFeedScreen> createState() => _MiniSeriesFeedScreenState();
}

class _MiniSeriesFeedScreenState extends ConsumerState<MiniSeriesFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load featured series on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadPublishedSeries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Series'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Popular'),
            Tab(text: 'New'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            _buildSearchResults(),
          if (_searchQuery.isEmpty)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeaturedTab(),
                  _buildPopularTab(),
                  _buildNewTab(),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSeriesScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return Consumer(
      builder: (context, ref, child) {
        final featuredSeries = ref.watch(featuredSeriesProvider);
        
        return featuredSeries.when(
          data: (series) => _buildSeriesGrid(series),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildPopularTab() {
    return Consumer(
      builder: (context, ref, child) {
        final miniSeriesState = ref.watch(miniSeriesProvider);
        
        return miniSeriesState.when(
          data: (state) {
            // Sort by total views for popular
            final popularSeries = List<MiniSeriesModel>.from(state.series)
              ..sort((a, b) => b.totalViews.compareTo(a.totalViews));
            return _buildSeriesGrid(popularSeries);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildNewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final miniSeriesState = ref.watch(miniSeriesProvider);
        
        return miniSeriesState.when(
          data: (state) {
            // Sort by creation date for new
            final newSeries = List<MiniSeriesModel>.from(state.series)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return _buildSeriesGrid(newSeries);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(seriesSearchProvider(_searchQuery));
        
        return Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search results for "$_searchQuery"',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _searchQuery = ''),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: searchResults.when(
                  data: (series) => _buildSeriesGrid(series),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeriesGrid(List<MiniSeriesModel> series) {
    if (series.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No series found'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: series.length,
      itemBuilder: (context, index) {
        final seriesItem = series[index];
        return SeriesCard(
          series: seriesItem,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(seriesId: seriesItem.seriesId),
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Series'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter series title, description, or tags...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop();
            setState(() => _searchQuery = value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// lib/features/mini_series/screens/creator_dashboard_screen.dart
class CreatorDashboardScreen extends ConsumerStatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  ConsumerState<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends ConsumerState<CreatorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load user's series
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadUserSeries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Series'),
            Tab(text: 'Analytics'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMySeriesTab(),
          _buildAnalyticsTab(),
          _buildDraftsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSeriesScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Series'),
      ),
    );
  }

  Widget _buildMySeriesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final userSeries = ref.watch(userSeriesProvider);
        final publishedSeries = userSeries.where((s) => s.isPublished).toList();
        
        if (publishedSeries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No published series yet'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateSeriesScreen()),
                  ),
                  child: const Text('Create Your First Series'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: publishedSeries.length,
          itemBuilder: (context, index) {
            final series = publishedSeries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: series.coverImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                title: Text(series.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${series.totalEpisodes} episodes'),
                    Text('${series.totalViews} views • ${series.totalLikes} likes'),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: const Text('View'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'analytics',
                      child: const Text('Analytics'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('Delete'),
                    ),
                  ],
                  onSelected: (value) => _handleSeriesAction(value, series),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailScreen(seriesId: series.seriesId),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final userSeries = ref.watch(userSeriesProvider);
        
        // Calculate total stats
        int totalViews = userSeries.fold(0, (sum, series) => sum + series.totalViews);
        int totalLikes = userSeries.fold(0, (sum, series) => sum + series.totalLikes);
        int totalEpisodes = userSeries.fold(0, (sum, series) => sum + series.totalEpisodes);
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Views', totalViews.toString(), Icons.visibility),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Total Likes', totalLikes.toString(), Icons.favorite),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Series', userSeries.length.toString(), Icons.video_library),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Episodes', totalEpisodes.toString(), Icons.play_circle),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Top Performing Series',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: userSeries.length,
                  itemBuilder: (context, index) {
                    final series = userSeries[index];
                    return Card(
                      child: ListTile(
                        title: Text(series.title),
                        subtitle: Text('${series.totalViews} views • ${series.totalLikes} likes'),
                        trailing: IconButton(
                          icon: const Icon(Icons.analytics),
                          onPressed: () => _viewDetailedAnalytics(series),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraftsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final userSeries = ref.watch(userSeriesProvider);
        final draftSeries = userSeries.where((s) => !s.isPublished).toList();
        
        if (draftSeries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.drafts_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No drafts'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: draftSeries.length,
          itemBuilder: (context, index) {
            final series = draftSeries[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.drafts_rounded),
                title: Text(series.title),
                subtitle: Text('Created: ${_formatDate(series.createdAt)}'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'publish',
                      child: const Text('Publish'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Text('Delete'),
                    ),
                  ],
                  onSelected: (value) => _handleSeriesAction(value, series),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  void _handleSeriesAction(String action, MiniSeriesModel series) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeriesDetailScreen(seriesId: series.seriesId),
          ),
        );
        break;
      case 'edit':
        // Navigate to edit screen
        break;
      case 'analytics':
        _viewDetailedAnalytics(series);
        break;
      case 'publish':
        _publishSeries(series);
        break;
      case 'delete':
        _confirmDeleteSeries(series);
        break;
    }
  }

  void _viewDetailedAnalytics(MiniSeriesModel series) {
    // Navigate to detailed analytics screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesAnalyticsScreen(series: series)));
  }

  void _publishSeries(MiniSeriesModel series) {
    ref.read(miniSeriesProvider.notifier).updateSeries(
      series.copyWith(isPublished: true),
    );
  }

  void _confirmDeleteSeries(MiniSeriesModel series) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Series'),
        content: Text('Are you sure you want to delete "${series.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(miniSeriesProvider.notifier).deleteSeries(series.seriesId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}