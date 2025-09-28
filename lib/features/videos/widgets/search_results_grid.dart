// ===============================
// lib/features/videos/widgets/search_results_grid.dart
// Search Results Grid Widget - Instagram/TikTok style grid layout
// Displays video thumbnails with creator info and engagement stats
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/features/videos/widgets/search_result_card.dart';

class SearchResultsGrid extends ConsumerStatefulWidget {
  final List<VideoSearchResult> results;
  final Function(String videoId) onVideoTap;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final EdgeInsets? padding;
  final double? childAspectRatio;
  final int crossAxisCount;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.onVideoTap,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.padding,
    this.childAspectRatio,
    this.crossAxisCount = 2,
  });

  @override
  ConsumerState<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends ConsumerState<SearchResultsGrid> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Add scroll listener for pagination
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null || widget.isLoadingMore) return;
    
    // Load more when reaching 80% of scroll
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.8) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Results header with sorting/filtering info
        _buildResultsHeader(),
        
        // Main grid
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Results grid
              SliverPadding(
                padding: widget.padding ?? const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    childAspectRatio: widget.childAspectRatio ?? (9 / 14), // Portrait ratio for videos
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final result = widget.results[index];
                      
                      return SearchResultCard(
                        searchResult: result,
                        onTap: () => _onResultTap(result),
                        showRelevance: false, // Can be enabled for debugging
                        showMatchType: true,
                      );
                    },
                    childCount: widget.results.length,
                  ),
                ),
              ),
              
              // Loading more indicator
              if (widget.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              
              // Load more button (if not auto-loading)
              if (widget.onLoadMore != null && !widget.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildLoadMoreButton(),
                  ),
                ),
              
              // Bottom padding for system navigation
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Results count
          Text(
            '${widget.results.length} results',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(),
          
          // View options (could be expanded to list/grid toggle)
          GestureDetector(
            onTap: _showViewOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.square_grid_2x2,
                    color: Colors.grey[300],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[300],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return GestureDetector(
      onTap: widget.onLoadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.arrow_down_circle,
              color: Colors.grey[300],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Load More Results',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onResultTap(VideoSearchResult result) {
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
    
    // Call the tap handler
    widget.onVideoTap(result.video.id);
  }

  void _showViewOptions() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildViewOptionsSheet(),
    );
  }

  Widget _buildViewOptionsSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Display Options',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Options
          _buildViewOption(
            icon: CupertinoIcons.square_grid_2x2,
            title: 'Grid View (2 columns)',
            subtitle: 'Current view',
            isSelected: widget.crossAxisCount == 2,
            onTap: () {
              Navigator.pop(context);
              // Would trigger parent to change crossAxisCount to 2
            },
          ),
          
          _buildViewOption(
            icon: CupertinoIcons.square_grid_3x2,
            title: 'Compact Grid (3 columns)',
            subtitle: 'More videos per row',
            isSelected: widget.crossAxisCount == 3,
            onTap: () {
              Navigator.pop(context);
              // Would trigger parent to change crossAxisCount to 3
            },
          ),
          
          _buildViewOption(
            icon: CupertinoIcons.list_bullet,
            title: 'List View',
            subtitle: 'One video per row',
            isSelected: false,
            onTap: () {
              Navigator.pop(context);
              // Would trigger parent to switch to list view
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildViewOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.red : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.red : Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: Colors.red,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// SEARCH RESULTS LIST VIEW
// ===============================

class SearchResultsList extends ConsumerStatefulWidget {
  final List<VideoSearchResult> results;
  final Function(String videoId) onVideoTap;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onVideoTap,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends ConsumerState<SearchResultsList> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null || widget.isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll * 0.8) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: widget.results.length + (widget.isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == widget.results.length && widget.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 2,
              ),
            ),
          );
        }
        
        final result = widget.results[index];
        return CompactSearchResultCard(
          searchResult: result,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onVideoTap(result.video.id);
          },
        );
      },
    );
  }
}

// ===============================
// SEARCH RESULTS STAGGERED GRID
// ===============================

class SearchResultsStaggeredGrid extends ConsumerWidget {
  final List<VideoSearchResult> results;
  final Function(String videoId) onVideoTap;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const SearchResultsStaggeredGrid({
    super.key,
    required this.results,
    required this.onVideoTap,
    this.onLoadMore,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            
            return SearchResultCard(
              searchResult: result,
              onTap: () {
                HapticFeedback.lightImpact();
                onVideoTap(result.video.id);
              },
              showRelevance: false,
              showMatchType: true,
            );
          },
        ),
        
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Placeholder for SliverMasonryGrid (would need to be implemented or use package)
class SliverMasonryGrid {
  static Widget count({
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required int childCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    // This is a placeholder - in real implementation you would use
    // a package like flutter_staggered_grid_view
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: 0.7,
      ),
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: childCount,
      ),
    );
  }
}