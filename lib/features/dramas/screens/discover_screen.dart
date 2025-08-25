// lib/features/dramas/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/dramas/widgets/drama_card.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _filterTabs = ['All', 'Free', 'Premium', 'Featured'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
      _isSearching = _searchQuery.isNotEmpty;
    });
    
    if (_isSearching) {
      ref.read(searchDramasProvider(_searchQuery).notifier).search(_searchQuery);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _buildHeader(modernTheme),
            
            // Show search results or filtered content
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildFilteredContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
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
          // Title
          Text(
            'Discover Dramas',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: modernTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearching 
                    ? const Color(0xFFFE2C55) 
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search dramas...',
                hintStyle: TextStyle(
                  color: modernTheme.textSecondaryColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: _isSearching 
                      ? const Color(0xFFFE2C55)
                      : modernTheme.textSecondaryColor,
                ),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        color: modernTheme.textSecondaryColor,
                        onPressed: _clearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Filter tabs (hidden when searching)
          if (!_isSearching) ...[
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFFFE2C55),
              unselectedLabelColor: modernTheme.textSecondaryColor,
              indicatorColor: const Color(0xFFFE2C55),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: _filterTabs.map((filter) => Tab(text: filter)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(searchDramasProvider(_searchQuery));
    
    return searchResults.when(
      data: (dramas) {
        if (dramas.isEmpty) {
          return _buildEmptyState('No dramas found for "$_searchQuery"', Icons.search_off);
        }
        
        return _buildDramaGrid(dramas);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Search failed', error.toString()),
    );
  }

  Widget _buildFilteredContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllDramas(),
        _buildFreeDramas(),
        _buildPremiumDramas(),
        _buildFeaturedDramas(),
      ],
    );
  }

  Widget _buildAllDramas() {
    final allDramas = ref.watch(allDramasProvider);
    
    return allDramas.when(
      data: (dramaState) {
        if (dramaState.dramas.isEmpty) {
          return _buildEmptyState('No dramas available yet', Icons.tv_off);
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(allDramasProvider.notifier).refresh(),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(dramaState.dramas, hasMore: dramaState.hasMore),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Failed to load dramas', error.toString()),
    );
  }

  Widget _buildFreeDramas() {
    final freeDramas = ref.watch(freeDramasProvider);
    
    return freeDramas.when(
      data: (dramas) {
        if (dramas.isEmpty) {
          return _buildEmptyState('No free dramas available', Icons.money_off);
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(freeDramasProvider.notifier).refresh(),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(dramas),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Failed to load free dramas', error.toString()),
    );
  }

  Widget _buildPremiumDramas() {
    final premiumDramas = ref.watch(premiumDramasProvider);
    
    return premiumDramas.when(
      data: (dramas) {
        if (dramas.isEmpty) {
          return _buildEmptyState('No premium dramas available', Icons.lock);
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(premiumDramasProvider.notifier).refresh(),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(dramas),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Failed to load premium dramas', error.toString()),
    );
  }

  Widget _buildFeaturedDramas() {
    final featuredDramas = ref.watch(featuredDramasProvider);
    
    return featuredDramas.when(
      data: (dramas) {
        if (dramas.isEmpty) {
          return _buildEmptyState('No featured dramas available', Icons.star_border);
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(featuredDramasProvider.notifier).refresh(),
          color: const Color(0xFFFE2C55),
          child: _buildDramaGrid(dramas),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Failed to load featured dramas', error.toString()),
    );
  }

  Widget _buildDramaGrid(List<DramaModel> dramas, {bool hasMore = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: dramas.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMore && index == dramas.length) {
          // Load more button
          return _buildLoadMoreButton();
        }
        
        return DramaCard(
          drama: dramas[index],
          onTap: () => _navigateToDramaDetails(dramas[index].dramaId),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () => ref.read(allDramasProvider.notifier).loadMore(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55).withOpacity(0.1),
          foregroundColor: const Color(0xFFFE2C55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add),
            SizedBox(height: 4),
            Text('Load More'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              title,
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
            ElevatedButton(
              onPressed: () {
                // Retry based on current tab
                switch (_tabController.index) {
                  case 0:
                    ref.read(allDramasProvider.notifier).refresh();
                    break;
                  case 1:
                    ref.read(freeDramasProvider.notifier).refresh();
                    break;
                  case 2:
                    ref.read(premiumDramasProvider.notifier).refresh();
                    break;
                  case 3:
                    ref.read(featuredDramasProvider.notifier).refresh();
                    break;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE2C55),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDramaDetails(String dramaId) {
    Navigator.pushNamed(
      context,
      Constants.dramaDetailsScreen,
      arguments: {'dramaId': dramaId},
    );
  }
}