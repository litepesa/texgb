// lib/features/dramas/screens/my_drama_details_screen.dart - ADMIN DRAMA ANALYTICS
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MyDramaDetailsScreen extends ConsumerStatefulWidget {
  final String dramaId;

  const MyDramaDetailsScreen({
    super.key,
    required this.dramaId,
  });

  @override
  ConsumerState<MyDramaDetailsScreen> createState() => _MyDramaDetailsScreenState();
}

class _MyDramaDetailsScreenState extends ConsumerState<MyDramaDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = ref.read(isAdminProvider);
      if (!isAdmin) {
        showSnackBar(context, Constants.adminOnly);
        Navigator.of(context).pop();
      }
    });

    // Listen to admin action messages
    ref.listenManual(adminDramaActionsProvider, (previous, next) {
      if (next.error != null) {
        showSnackBar(context, next.error!);
        ref.read(adminDramaActionsProvider.notifier).clearMessages();
      } else if (next.successMessage != null) {
        showSnackBar(context, next.successMessage!);
        ref.read(adminDramaActionsProvider.notifier).clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final drama = ref.watch(dramaProvider(widget.dramaId));
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null || !currentUser.isAdmin) {
      return _buildAccessDenied(modernTheme);
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(),
        backgroundColor: modernTheme.surfaceColor,
        color: modernTheme.textColor,
        child: drama.when(
          data: (dramaModel) {
            if (dramaModel == null) {
              return _buildNotFound(modernTheme);
            }

            // Check if current user owns this drama
            if (dramaModel.createdBy != currentUser.uid) {
              return _buildNotOwned(modernTheme);
            }

            return _buildDramaAnalytics(dramaModel, modernTheme);
          },
          loading: () => _buildLoading(modernTheme),
          error: (error, stack) => _buildError(modernTheme, error.toString()),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(dramaProvider(widget.dramaId));
    ref.invalidate(adminDramasProvider);
  }

  Widget _buildDramaAnalytics(DramaModel drama, ModernThemeExtension modernTheme) {
    return CustomScrollView(
      slivers: [
        // Header with drama info
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: modernTheme.backgroundColor,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert, color: Colors.white),
              ),
              onSelected: (value) => _handleMenuAction(value, drama),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Drama'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'episodes',
                  child: Row(
                    children: [
                      Icon(Icons.video_library),
                      SizedBox(width: 8),
                      Text('Manage Episodes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_featured',
                  child: Row(
                    children: [
                      Icon(drama.isFeatured ? Icons.star : Icons.star_border),
                      const SizedBox(width: 8),
                      Text(drama.isFeatured ? 'Unfeature' : 'Feature'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Row(
                    children: [
                      Icon(drama.isActive ? Icons.pause_circle : Icons.play_circle),
                      const SizedBox(width: 8),
                      Text(drama.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share_stats',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share Stats'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Banner image
                drama.bannerImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: drama.bannerImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: modernTheme.surfaceVariantColor,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: modernTheme.surfaceVariantColor,
                          child: Icon(
                            Icons.tv,
                            size: 64,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      )
                    : Container(
                        color: modernTheme.surfaceVariantColor,
                        child: Icon(
                          Icons.tv,
                          size: 64,
                          color: modernTheme.textSecondaryColor,
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
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Title and performance level
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drama.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPerformanceBadge(drama.performanceLevel),
                          const SizedBox(width: 8),
                          if (drama.isProfitable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Profitable',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab bar
        SliverToBoxAdapter(
          child: Container(
            color: modernTheme.surfaceColor,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFE2C55),
              unselectedLabelColor: modernTheme.textSecondaryColor,
              indicatorColor: const Color(0xFFFE2C55),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Analytics'),
                Tab(text: 'Episodes'),
              ],
            ),
          ),
        ),

        // Tab content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(drama, modernTheme),
              _buildAnalyticsTab(drama, modernTheme),
              _buildEpisodesTab(drama, modernTheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(DramaModel drama, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          _buildKeyMetricsRow(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Revenue section (for premium dramas)
          if (drama.isPremium) ...[
            _buildRevenueSection(drama, modernTheme),
            const SizedBox(height: 24),
          ],
          
          // Performance summary
          _buildPerformanceSummary(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Quick stats
          _buildQuickStats(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Drama details
          _buildDramaDetails(drama, modernTheme),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(DramaModel drama, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Engagement metrics
          _buildEngagementMetrics(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Conversion funnel
          _buildConversionFunnel(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Performance insights
          _buildPerformanceInsights(drama, modernTheme),
          
          const SizedBox(height: 24),
          
          // Recommendations
          _buildRecommendations(drama, modernTheme),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab(DramaModel drama, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episodes header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes (${drama.totalEpisodes})',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Constants.addEpisodeScreen,
                  arguments: {'dramaId': drama.dramaId},
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Episode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE2C55),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Episodes list
          if (drama.hasEpisodes) ...[
            ...List.generate(drama.totalEpisodes, (index) {
              final episodeNumber = index + 1;
              final isLocked = drama.isPremium && episodeNumber > drama.freeEpisodesCount;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: modernTheme.surfaceVariantColor!,
                  ),
                ),
                child: Row(
                  children: [
                    // Episode thumbnail
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: modernTheme.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$episodeNumber',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Episode info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drama.getEpisodeTitle(episodeNumber),
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLocked ? 'Premium Episode' : 'Free Episode',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Episode status
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Free',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ] else ...[
            _buildEmptyEpisodes(modernTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyMetricsRow(DramaModel drama, ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 85, // Fixed width to prevent overflow
            child: _buildMetricCard(
              modernTheme,
              title: 'Views',
              value: _formatCount(drama.viewCount),
              icon: Icons.visibility,
              color: Colors.blue.shade400,
              subtitle: 'Total views',
            ),
          ),
          const SizedBox(width: 8), // Reduced spacing
          SizedBox(
            width: 85,
            child: _buildMetricCard(
              modernTheme,
              title: 'Favorites',
              value: _formatCount(drama.favoriteCount),
              icon: Icons.favorite,
              color: Colors.red.shade400,
              subtitle: 'Total favorites',
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: _buildMetricCard(
              modernTheme,
              title: 'Unlocks',
              value: _formatCount(drama.unlockCount),
              icon: Icons.lock_open,
              color: Colors.green.shade400,
              subtitle: drama.isPremium ? 'Paid unlocks' : 'N/A (Free)',
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: _buildMetricCard(
              modernTheme,
              title: 'Episodes',
              value: drama.totalEpisodes.toString(),
              icon: Icons.play_circle,
              color: Colors.purple.shade400,
              subtitle: 'Total episodes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(DramaModel drama, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFE2C55).withOpacity(0.1),
            const Color(0xFFFE2C55).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFE2C55).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Revenue Analytics',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${drama.totalRevenue} Coins',
                      style: TextStyle(
                        color: const Color(0xFFFE2C55),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
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
                      '${drama.conversionRate.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Conversion Rate',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${drama.revenuePerView.toStringAsFixed(2)} coins per view',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary(DramaModel drama, ModernThemeExtension modernTheme) {
    final stats = drama.performanceStats;
    final engagement = drama.engagementMetrics;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Summary',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceIndicator(
                  modernTheme,
                  label: 'Performance Level',
                  value: drama.performanceLevel,
                  color: _getPerformanceColor(drama.performanceLevel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceIndicator(
                  modernTheme,
                  label: 'Engagement Score',
                  value: '${engagement['totalEngagementScore'].toStringAsFixed(1)}%',
                  color: _getEngagementColor(engagement['totalEngagementScore']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DramaModel drama, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(modernTheme, 'Content Type', drama.isPremium ? 'Premium' : 'Free'),
          _buildStatRow(modernTheme, 'Status', drama.isActive ? 'Active' : 'Inactive'),
          _buildStatRow(modernTheme, 'Featured', drama.isFeatured ? 'Yes' : 'No'),
          if (drama.isPremium) ...[
            _buildStatRow(modernTheme, 'Free Episodes', '${drama.freeEpisodesCount}/${drama.totalEpisodes}'),
            _buildStatRow(modernTheme, 'Unlock Cost', '${Constants.dramaUnlockCost} coins'),
          ],
          _buildStatRow(modernTheme, 'Created', _formatDate(drama.createdAt)),
        ],
      ),
    );
  }

  Widget _buildDramaDetails(DramaModel drama, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            drama.description,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics(DramaModel drama, ModernThemeExtension modernTheme) {
    final metrics = drama.engagementMetrics;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Metrics',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            modernTheme,
            'View to Favorite Rate',
            '${metrics['viewToFavoriteRate'].toStringAsFixed(2)}%',
            'Percentage of viewers who favorited',
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            modernTheme,
            'Favorite to Unlock Rate',
            '${metrics['favoriteToUnlockRate'].toStringAsFixed(2)}%',
            'Percentage of favoriters who unlocked',
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            modernTheme,
            'Overall Engagement',
            '${metrics['totalEngagementScore'].toStringAsFixed(1)}%',
            'Combined engagement score',
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel(DramaModel drama, ModernThemeExtension modernTheme) {
    final viewToFavorite = drama.favoriteCount / (drama.viewCount > 0 ? drama.viewCount : 1);
    final favoriteToUnlock = drama.unlockCount / (drama.favoriteCount > 0 ? drama.favoriteCount : 1);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFunnelStep(
            modernTheme,
            'Views',
            drama.viewCount.toString(),
            1.0,
            Colors.blue.shade400,
          ),
          const SizedBox(height: 8),
          _buildFunnelStep(
            modernTheme,
            'Favorites',
            drama.favoriteCount.toString(),
            viewToFavorite,
            Colors.red.shade400,
          ),
          if (drama.isPremium) ...[
            const SizedBox(height: 8),
            _buildFunnelStep(
              modernTheme,
              'Unlocks',
              drama.unlockCount.toString(),
              favoriteToUnlock * viewToFavorite,
              Colors.green.shade400,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights(DramaModel drama, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Insights',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            modernTheme,
            icon: drama.isPopular ? Icons.trending_up : Icons.visibility,
            title: drama.isPopular ? 'Popular Content' : 'Building Audience',
            description: drama.isPopular 
                ? 'Your drama has over 1,000 views! Keep promoting it.'
                : 'Focus on marketing to increase visibility.',
            color: drama.isPopular ? Colors.green.shade400 : Colors.blue.shade400,
          ),
          const SizedBox(height: 12),
          if (drama.isPremium) ...[
            _buildInsightCard(
              modernTheme,
              icon: drama.isHighConverting ? Icons.star : Icons.trending_flat,
              title: drama.isHighConverting ? 'High Converting' : 'Conversion Opportunity',
              description: drama.isHighConverting 
                  ? 'Excellent conversion rate! Your content is monetizing well.'
                  : 'Consider improving content quality or adjusting pricing strategy.',
              color: drama.isHighConverting ? Colors.amber.shade600 : Colors.orange.shade400,
            ),
            const SizedBox(height: 12),
          ],
          _buildInsightCard(
            modernTheme,
            icon: drama.favoriteCount > drama.viewCount * 0.1 ? Icons.favorite : Icons.favorite_border,
            title: drama.favoriteCount > drama.viewCount * 0.1 ? 'High Engagement' : 'Engagement Growth',
            description: drama.favoriteCount > drama.viewCount * 0.1
                ? 'Great favorite-to-view ratio! Your audience loves your content.'
                : 'Focus on creating more engaging content to boost favorites.',
            color: drama.favoriteCount > drama.viewCount * 0.1 ? Colors.red.shade400 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(DramaModel drama, ModernThemeExtension modernTheme) {
    final recommendations = _getRecommendations(drama);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecommendationItem(modernTheme, rec['icon'], rec['title'], rec['description']),
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ModernThemeExtension modernTheme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16), // Smaller icon
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 10, // Smaller font
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18, // Reduced from 24
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 8, // Smaller subtitle
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(
    ModernThemeExtension modernTheme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(ModernThemeExtension modernTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    ModernThemeExtension modernTheme,
    String title,
    String value,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFFFE2C55),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelStep(
    ModernThemeExtension modernTheme,
    String label,
    String count,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            count,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    ModernThemeExtension modernTheme, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    ModernThemeExtension modernTheme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFE2C55).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFE2C55),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBadge(String performanceLevel) {
    Color badgeColor;
    switch (performanceLevel) {
      case 'Excellent':
        badgeColor = Colors.green.shade600;
        break;
      case 'Good':
        badgeColor = Colors.blue.shade600;
        break;
      case 'Average':
        badgeColor = Colors.orange.shade600;
        break;
      case 'Needs Improvement':
        badgeColor = Colors.red.shade600;
        break;
      default:
        badgeColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        performanceLevel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyEpisodes(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No episodes yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first episode to get started',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              Constants.addEpisodeScreen,
              arguments: {'dramaId': widget.dramaId},
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Episode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(ModernThemeExtension modernTheme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Access Required',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(ModernThemeExtension modernTheme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_off,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Drama Not Found',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotOwned(ModernThemeExtension modernTheme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Not Your Drama',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can only view analytics for dramas you created',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ModernThemeExtension modernTheme) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFE2C55)),
      ),
    );
  }

  Widget _buildError(ModernThemeExtension modernTheme, String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Drama',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.surfaceVariantColor,
                    foregroundColor: modernTheme.textColor,
                  ),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(dramaProvider(widget.dramaId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _handleMenuAction(String action, DramaModel drama) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(
          context,
          Constants.editDramaScreen,
          arguments: {'dramaId': drama.dramaId},
        );
        break;
      case 'episodes':
        Navigator.pushNamed(
          context,
          Constants.addEpisodeScreen,
          arguments: {'dramaId': drama.dramaId},
        );
        break;
      case 'toggle_featured':
        ref.read(adminDramaActionsProvider.notifier)
            .toggleFeatured(drama.dramaId, !drama.isFeatured);
        break;
      case 'toggle_active':
        ref.read(adminDramaActionsProvider.notifier)
            .toggleActive(drama.dramaId, !drama.isActive);
        break;
      case 'share_stats':
        _shareStats(drama);
        break;
    }
  }

  void _shareStats(DramaModel drama) {
    final stats = '''
${drama.title} - Performance Stats

📊 Views: ${_formatCount(drama.viewCount)}
❤️ Favorites: ${_formatCount(drama.favoriteCount)}
${drama.isPremium ? '🔓 Unlocks: ${_formatCount(drama.unlockCount)}' : ''}
${drama.isPremium ? '💰 Revenue: ${drama.totalRevenue} coins' : ''}
📺 Episodes: ${drama.totalEpisodes}
⭐ Performance: ${drama.performanceLevel}
${drama.isPremium ? '📈 Conversion: ${drama.conversionRate.toStringAsFixed(2)}%' : ''}

Created with WeiBao Drama Platform
    '''.trim();

    Clipboard.setData(ClipboardData(text: stats));
    showSnackBar(context, 'Stats copied to clipboard!');
  }

  Color _getPerformanceColor(String level) {
    switch (level) {
      case 'Excellent':
        return Colors.green.shade600;
      case 'Good':
        return Colors.blue.shade600;
      case 'Average':
        return Colors.orange.shade600;
      case 'Needs Improvement':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getEngagementColor(double score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.blue.shade600;
    if (score >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  List<Map<String, dynamic>> _getRecommendations(DramaModel drama) {
    final recommendations = <Map<String, dynamic>>[];

    if (drama.viewCount < 100) {
      recommendations.add({
        'icon': Icons.visibility,
        'title': 'Boost Visibility',
        'description': 'Consider promoting your drama on social media or featuring it to increase views.',
      });
    }

    if (drama.isPremium && drama.conversionRate < 2.0) {
      recommendations.add({
        'icon': Icons.trending_up,
        'title': 'Improve Conversion',
        'description': 'Try offering more free episodes or improving content quality to boost unlock rates.',
      });
    }

    if (drama.favoriteCount < drama.viewCount * 0.05) {
      recommendations.add({
        'icon': Icons.favorite,
        'title': 'Increase Engagement',
        'description': 'Focus on creating more compelling content to encourage viewers to favorite your drama.',
      });
    }

    if (!drama.isFeatured && drama.isPopular) {
      recommendations.add({
        'icon': Icons.star,
        'title': 'Consider Featuring',
        'description': 'Your drama is popular! Consider featuring it to boost visibility even more.',
      });
    }

    if (drama.totalEpisodes < 5) {
      recommendations.add({
        'icon': Icons.add_circle,
        'title': 'Add More Episodes',
        'description': 'More episodes can help retain viewers and increase overall engagement.',
      });
    }

    // If no specific recommendations, add general ones
    if (recommendations.isEmpty) {
      recommendations.add({
        'icon': Icons.trending_up,
        'title': 'Keep Growing',
        'description': 'Continue creating quality content and engaging with your audience.',
      });
    }

    return recommendations;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateStr;
    }
  }
}