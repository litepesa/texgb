// lib/features/mini_series/screens/series_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/mini_series_provider.dart';
import '../models/mini_series_model.dart';
import '../models/analytics_model.dart';
import '../widgets/analytics_chart.dart';
import '../../authentication/providers/auth_providers.dart';

class SeriesAnalyticsScreen extends ConsumerStatefulWidget {
  final MiniSeriesModel series;

  const SeriesAnalyticsScreen({
    super.key,
    required this.series,
  });

  @override
  ConsumerState<SeriesAnalyticsScreen> createState() => _SeriesAnalyticsScreenState();
}

class _SeriesAnalyticsScreenState extends ConsumerState<SeriesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';
  
  final List<String> _periods = ['7d', '30d', '90d', '1y', 'all'];
  final Map<String, String> _periodLabels = {
    '7d': 'Last 7 days',
    '30d': 'Last 30 days',
    '90d': 'Last 3 months',
    '1y': 'Last year',
    'all': 'All time',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miniSeriesProvider.notifier).loadAnalytics(widget.series.seriesId);
      ref.read(miniSeriesProvider.notifier).loadEpisodes(widget.series.seriesId);
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
    final currentUser = ref.watch(currentUserProvider);
    
    // Verify user is the creator
    if (currentUser?.uid != widget.series.creatorUID) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('You can only view analytics for your own series'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Series Analytics'),
        elevation: 0,
        actions: [
          // Period selector
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            itemBuilder: (context) => _periods.map((period) => PopupMenuItem(
              value: period,
              child: Text(_periodLabels[period]!),
            )).toList(),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _periodLabels[_selectedPeriod]!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          
          // Export/Share button
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportAnalytics,
            tooltip: 'Export Analytics',
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final analytics = ref.watch(seriesAnalyticsProvider);
          final episodes = ref.watch(seriesEpisodesProvider);
          
          if (analytics == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Series header
              _buildSeriesHeader(theme),
              
              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: false,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Episodes'),
                  Tab(text: 'Audience'),
                  Tab(text: 'Growth'),
                ],
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(analytics, episodes, theme),
                    _buildEpisodesTab(analytics, episodes, theme),
                    _buildAudienceTab(analytics, theme),
                    _buildGrowthTab(analytics, theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeriesHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Series thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.series.coverImageUrl,
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
          
          const SizedBox(width: 16),
          
          // Series info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.series.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.series.totalEpisodes} episodes • ${widget.series.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.series.isPublished 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.series.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color: widget.series.isPublished ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

  Widget _buildOverviewTab(SeriesAnalyticsModel analytics, episodes, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(miniSeriesProvider.notifier).loadAnalytics(widget.series.seriesId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Key metrics cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Views',
                  analytics.totalViews.toString(),
                  Icons.visibility,
                  _getViewsGrowth(analytics),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Likes',
                  analytics.totalLikes.toString(),
                  Icons.favorite,
                  _getLikesGrowth(analytics),
                  theme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Comments',
                  analytics.totalComments.toString(),
                  Icons.comment,
                  _getCommentsGrowth(analytics),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Shares',
                  analytics.totalShares.toString(),
                  Icons.share,
                  _getSharesGrowth(analytics),
                  theme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Views over time chart
          AnalyticsChart(
            title: 'Views Over Time',
            data: _getFilteredViewsByDate(analytics),
            color: Colors.blue,
          ),
          
          const SizedBox(height: 24),
          
          // Performance summary
          _buildPerformanceSummary(analytics, theme),
          
          const SizedBox(height: 24),
          
          // Top performing episodes
          _buildTopPerformingEpisodes(analytics, episodes, theme),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, String growth, ThemeData theme) {
    final isPositive = growth.startsWith('+');
    final isNeutral = growth == '0%' || growth == '--';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isNeutral 
                        ? Colors.grey.withOpacity(0.1)
                        : isPositive 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(
                      color: isNeutral 
                          ? Colors.grey
                          : isPositive 
                              ? Colors.green
                              : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildPerformanceSummary(SeriesAnalyticsModel analytics, ThemeData theme) {
    final avgWatchTime = analytics.averageWatchTime;
    final retentionRate = analytics.retentionRate;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avg. Watch Time',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${avgWatchTime.toStringAsFixed(1)}s',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retention Rate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${(retentionRate * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Engagement rate
            Text(
              'Engagement Rate',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _calculateEngagementRate(analytics),
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getEngagementColor(_calculateEngagementRate(analytics)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_calculateEngagementRate(analytics) * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformingEpisodes(SeriesAnalyticsModel analytics, episodes, ThemeData theme) {
    // Sort episodes by views
    final sortedEpisodes = List.from(episodes)
      ..sort((a, b) => b.views.compareTo(a.views));
    
    final topEpisodes = sortedEpisodes.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Episodes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...topEpisodes.asMap().entries.map((entry) {
              final index = entry.key;
              final episode = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Episode info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Episode ${episode.episodeNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatCount(episode.views)} views',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_formatCount(episode.likes)} likes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesTab(SeriesAnalyticsModel analytics, episodes, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Episodes performance chart
        AnalyticsChart(
          title: 'Views by Episode',
          data: analytics.viewsByEpisode,
          color: Colors.green,
        ),
        
        const SizedBox(height: 24),
        
        // Episode details list
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Episode Performance Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Episode',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Views',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Likes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Comments',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Episode rows
                ...episodes.map((episode) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              episode.title,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Ep. ${episode.episodeNumber}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCount(episode.views),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCount(episode.likes),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatCount(episode.comments),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudienceTab(SeriesAnalyticsModel analytics, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Demographics charts
        if (analytics.viewsByCountry.isNotEmpty) ...[
          AnalyticsChart(
            title: 'Views by Country',
            data: analytics.viewsByCountry,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
        ],
        
        if (analytics.viewsByAge.isNotEmpty) ...[
          AnalyticsChart(
            title: 'Views by Age Group',
            data: analytics.viewsByAge,
            color: Colors.purple,
          ),
          const SizedBox(height: 24),
        ],
        
        if (analytics.viewsByGender.isNotEmpty) ...[
          AnalyticsChart(
            title: 'Views by Gender',
            data: analytics.viewsByGender,
            color: Colors.teal,
          ),
          const SizedBox(height: 24),
        ],
        
        // Audience insights
        _buildAudienceInsights(analytics, theme),
      ],
    );
  }

  Widget _buildAudienceInsights(SeriesAnalyticsModel analytics, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audience Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Key insights
            _buildInsightItem(
              'Peak Viewing Time',
              '7:00 PM - 9:00 PM',
              Icons.schedule,
              theme,
            ),
            
            _buildInsightItem(
              'Most Active Day',
              'Sunday',
              Icons.calendar_today,
              theme,
            ),
            
            _buildInsightItem(
              'Avg. Session Duration',
              '${analytics.averageWatchTime.toStringAsFixed(1)} seconds',
              Icons.timer,
              theme,
            ),
            
            _buildInsightItem(
              'Return Viewer Rate',
              '${(analytics.retentionRate * 100).toStringAsFixed(1)}%',
              Icons.refresh,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTab(SeriesAnalyticsModel analytics, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Growth metrics
        Row(
          children: [
            Expanded(
              child: _buildGrowthCard(
                'Views Growth',
                '+15.2%',
                'vs last period',
                Icons.trending_up,
                Colors.green,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGrowthCard(
                'Subscriber Growth',
                '+8.7%',
                'vs last period',
                Icons.person_add,
                Colors.blue,
                theme,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildGrowthCard(
                'Engagement Growth',
                '+12.4%',
                'vs last period',
                Icons.favorite,
                Colors.red,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGrowthCard(
                'Watch Time Growth',
                '+9.8%',
                'vs last period',
                Icons.play_circle,
                Colors.orange,
                theme,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Growth chart
        AnalyticsChart(
          title: 'Growth Trend',
          data: _getGrowthTrendData(analytics),
          color: Colors.indigo,
        ),
        
        const SizedBox(height: 24),
        
        // Growth tips
        _buildGrowthTips(theme),
      ],
    );
  }

  Widget _buildGrowthCard(String title, String value, String subtitle, IconData icon, Color color, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthTips(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Growth Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildTipItem(
              'Consistency is key',
              'Upload episodes regularly to keep your audience engaged',
              theme,
            ),
            
            _buildTipItem(
              'Engage with comments',
              'Respond to viewer comments to build a community',
              theme,
            ),
            
            _buildTipItem(
              'Use trending tags',
              'Add relevant tags to help new viewers discover your content',
              theme,
            ),
            
            _buildTipItem(
              'Create compelling thumbnails',
              'Eye-catching cover images increase click-through rates',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for data processing
  String _getViewsGrowth(SeriesAnalyticsModel analytics) {
    // This would calculate actual growth based on period
    // For demo purposes, returning mock data
    switch (_selectedPeriod) {
      case '7d': return '+12.5%';
      case '30d': return '+8.2%';
      case '90d': return '+15.7%';
      case '1y': return '+45.3%';
      default: return '+23.1%';
    }
  }

  String _getLikesGrowth(SeriesAnalyticsModel analytics) {
    switch (_selectedPeriod) {
      case '7d': return '+9.3%';
      case '30d': return '+6.8%';
      case '90d': return '+12.4%';
      case '1y': return '+38.9%';
      default: return '+19.7%';
    }
  }

  String _getCommentsGrowth(SeriesAnalyticsModel analytics) {
    switch (_selectedPeriod) {
      case '7d': return '+15.2%';
      case '30d': return '+11.5%';
      case '90d': return '+18.3%';
      case '1y': return '+52.1%';
      default: return '+28.4%';
    }
  }

  String _getSharesGrowth(SeriesAnalyticsModel analytics) {
    switch (_selectedPeriod) {
      case '7d': return '+7.8%';
      case '30d': return '+4.2%';
      case '90d': return '+9.6%';
      case '1y': return '+31.4%';
      default: return '+16.3%';
    }
  }

  Map<String, int> _getFilteredViewsByDate(SeriesAnalyticsModel analytics) {
    // Filter analytics data based on selected period
    final allData = analytics.viewsByDate;
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case '7d':
        return Map.fromEntries(
          allData.entries.where((entry) {
            final date = DateTime.tryParse(entry.key);
            return date != null && now.difference(date).inDays <= 7;
          }).take(7),
        );
      case '30d':
        return Map.fromEntries(
          allData.entries.where((entry) {
            final date = DateTime.tryParse(entry.key);
            return date != null && now.difference(date).inDays <= 30;
          }).take(30),
        );
      case '90d':
        return Map.fromEntries(
          allData.entries.where((entry) {
            final date = DateTime.tryParse(entry.key);
            return date != null && now.difference(date).inDays <= 90;
          }).take(90),
        );
      case '1y':
        return Map.fromEntries(
          allData.entries.where((entry) {
            final date = DateTime.tryParse(entry.key);
            return date != null && now.difference(date).inDays <= 365;
          }).take(365),
        );
      default:
        return allData;
    }
  }

  Map<String, int> _getGrowthTrendData(SeriesAnalyticsModel analytics) {
    // Generate growth trend data based on period
    final Map<String, int> trendData = {};
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case '7d':
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = '${date.month}/${date.day}';
          trendData[key] = (100 + (i * 15 + (7 - i) * 5)).toInt();
        }
        break;
      case '30d':
        for (int i = 29; i >= 0; i -= 5) {
          final date = now.subtract(Duration(days: i));
          final key = '${date.month}/${date.day}';
          trendData[key] = (200 + (i * 8 + (30 - i) * 3)).toInt();
        }
        break;
      default:
        trendData['Week 1'] = 150;
        trendData['Week 2'] = 280;
        trendData['Week 3'] = 420;
        trendData['Week 4'] = 580;
    }
    
    return trendData;
  }

  double _calculateEngagementRate(SeriesAnalyticsModel analytics) {
    if (analytics.totalViews == 0) return 0.0;
    
    final totalEngagements = analytics.totalLikes + 
                           analytics.totalComments + 
                           analytics.totalShares;
    
    return (totalEngagements / analytics.totalViews).clamp(0.0, 1.0);
  }

  Color _getEngagementColor(double rate) {
    if (rate >= 0.1) return Colors.green;
    if (rate >= 0.05) return Colors.orange;
    return Colors.red;
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0: return Colors.amber; // Gold
      case 1: return Colors.grey; // Silver
      case 2: return Colors.brown; // Bronze
      default: return Colors.blue;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _exportAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Analytics'),
        content: const Text(
          'Choose the format you want to export your analytics data:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsPDF();
            },
            child: const Text('PDF Report'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAsCSV();
            },
            child: const Text('CSV Data'),
          ),
        ],
      ),
    );
  }

  void _exportAsPDF() {
    // Implement PDF export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF report generation started...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportAsCSV() {
    // Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data export started...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Additional helper widget for detailed metric cards
class DetailedMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;
  final VoidCallback? onTap;

  const DetailedMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = trend.startsWith('+');
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositive 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for showing analytics insights
class AnalyticsInsight extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String actionText;
  final VoidCallback? onActionTap;

  const AnalyticsInsight({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (onActionTap != null)
              TextButton(
                onPressed: onActionTap,
                child: Text(actionText),
              ),
          ],
        ),
      ),
    );
  }
}