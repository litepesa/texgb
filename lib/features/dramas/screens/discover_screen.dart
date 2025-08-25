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

  // Page controllers for each tab
  final PageController _allPageController = PageController(viewportFraction: 0.85);
  final PageController _freePageController = PageController(viewportFraction: 0.85);
  final PageController _premiumPageController = PageController(viewportFraction: 0.85);
  final PageController _featuredPageController = PageController(viewportFraction: 0.85);
  final PageController _searchPageController = PageController(viewportFraction: 0.85);

  // Current indices for page indicators
  int _allCurrentIndex = 0;
  int _freeCurrentIndex = 0;
  int _premiumCurrentIndex = 0;
  int _featuredCurrentIndex = 0;
  int _searchCurrentIndex = 0;

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
    _allPageController.dispose();
    _freePageController.dispose();
    _premiumPageController.dispose();
    _featuredPageController.dispose();
    _searchPageController.dispose();
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Free':
        return Icons.money_off;
      case 'Premium':
        return Icons.lock;
      case 'Featured':
        return Icons.star;
      default:
        return Icons.grid_view;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
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
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: modernTheme.dividerColor!.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: modernTheme.primaryColor!.withOpacity(0.08),
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
                children: _filterTabs.map((category) {
                  final isSelected = _tabController.index == _filterTabs.indexOf(category);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _tabController.index = _filterTabs.indexOf(category);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border(
                            bottom: BorderSide(
                              color: modernTheme.primaryColor!,
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
                                  ? modernTheme.primaryColor!.withOpacity(0.15)
                                  : modernTheme.primaryColor!.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: isSelected 
                                  ? modernTheme.primaryColor 
                                  : modernTheme.textSecondaryColor,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected 
                                    ? modernTheme.primaryColor 
                                    : modernTheme.textSecondaryColor,
                                  fontWeight: isSelected 
                                    ? FontWeight.w700 
                                    : FontWeight.w500,
                                  fontSize: 12,
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
        
        return Column(
          children: [
            // Page indicator
            if (dramas.isNotEmpty) _buildPageIndicator(dramas.length, _searchCurrentIndex),
            
            // Carousel
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(searchDramasProvider(_searchQuery).notifier).search(_searchQuery),
                backgroundColor: context.modernTheme.surfaceColor,
                color: context.modernTheme.textColor,
                child: PageView.builder(
                  controller: _searchPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _searchCurrentIndex = index;
                    });
                  },
                  itemCount: dramas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: DramaCard(
                        drama: dramas[index],
                        onTap: () => _navigateToDramaDetails(dramas[index].dramaId),
                        showProgress: true,
                        index: index,
                        pageController: _searchPageController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
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
        
        return Column(
          children: [
            // Page indicator
            _buildPageIndicator(dramaState.dramas.length, _allCurrentIndex),
            
            // Main carousel
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(allDramasProvider.notifier).refresh(),
                backgroundColor: context.modernTheme.surfaceColor,
                color: context.modernTheme.textColor,
                child: PageView.builder(
                  controller: _allPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _allCurrentIndex = index;
                    });
                  },
                  itemCount: dramaState.dramas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: DramaCard(
                        drama: dramaState.dramas[index],
                        onTap: () => _navigateToDramaDetails(dramaState.dramas[index].dramaId),
                        showProgress: true,
                        index: index,
                        pageController: _allPageController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
        
        return Column(
          children: [
            // Page indicator
            _buildPageIndicator(dramas.length, _freeCurrentIndex),
            
            // Main carousel
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(freeDramasProvider.notifier).refresh(),
                backgroundColor: context.modernTheme.surfaceColor,
                color: context.modernTheme.textColor,
                child: PageView.builder(
                  controller: _freePageController,
                  onPageChanged: (index) {
                    setState(() {
                      _freeCurrentIndex = index;
                    });
                  },
                  itemCount: dramas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: DramaCard(
                        drama: dramas[index],
                        onTap: () => _navigateToDramaDetails(dramas[index].dramaId),
                        showProgress: true,
                        index: index,
                        pageController: _freePageController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
        
        return Column(
          children: [
            // Page indicator
            _buildPageIndicator(dramas.length, _premiumCurrentIndex),
            
            // Main carousel
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(premiumDramasProvider.notifier).refresh(),
                backgroundColor: context.modernTheme.surfaceColor,
                color: context.modernTheme.textColor,
                child: PageView.builder(
                  controller: _premiumPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _premiumCurrentIndex = index;
                    });
                  },
                  itemCount: dramas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: DramaCard(
                        drama: dramas[index],
                        onTap: () => _navigateToDramaDetails(dramas[index].dramaId),
                        showProgress: true,
                        index: index,
                        pageController: _premiumPageController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
        
        return Column(
          children: [
            // Page indicator
            _buildPageIndicator(dramas.length, _featuredCurrentIndex),
            
            // Main carousel
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(featuredDramasProvider.notifier).refresh(),
                backgroundColor: context.modernTheme.surfaceColor,
                color: context.modernTheme.textColor,
                child: PageView.builder(
                  controller: _featuredPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _featuredCurrentIndex = index;
                    });
                  },
                  itemCount: dramas.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                      child: DramaCard(
                        drama: dramas[index],
                        onTap: () => _navigateToDramaDetails(dramas[index].dramaId),
                        showProgress: true,
                        index: index,
                        pageController: _featuredPageController,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55))),
      error: (error, stack) => _buildErrorState('Failed to load featured dramas', error.toString()),
    );
  }

  Widget _buildPageIndicator(int totalItems, int currentIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalItems > 10 ? 10 : totalItems, // Limit dots to 10
          (index) {
            // For more than 10 items, show relative position
            int displayIndex = totalItems > 10 
                ? (currentIndex < 5 ? index : (currentIndex > totalItems - 6 ? index + totalItems - 10 : index + currentIndex - 4))
                : index;
            
            bool isActive = displayIndex == currentIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              height: 6.0,
              width: isActive ? 20.0 : 6.0,
              decoration: BoxDecoration(
                color: isActive 
                    ? context.modernTheme.textColor 
                    : context.modernTheme.textSecondaryColor,
                borderRadius: BorderRadius.circular(3.0),
              ),
            );
          },
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