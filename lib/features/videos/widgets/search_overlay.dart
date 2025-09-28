// ===============================
// lib/features/videos/widgets/search_overlay.dart
// Search Overlay Widget - TikTok-style search interface
// Slides down from top with search results
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/features/videos/providers/video_search_provider.dart';
import 'package:textgb/features/videos/widgets/search_results_grid.dart';
import 'package:textgb/features/videos/widgets/search_suggestions.dart';
import 'package:textgb/constants.dart';

class SearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(String videoId)? onVideoTap;
  final bool showFilters;
  final String? initialQuery;

  const SearchOverlay({
    super.key,
    required this.onClose,
    this.onVideoTap,
    this.showFilters = true,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay>
    with TickerProviderStateMixin {
  // Controllers and focus
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  
  // Animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // State
  bool _isFiltersExpanded = false;
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    
    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      _fadeController.forward();
      
      // Focus search input after animation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
          
          // If there's an initial query, perform search
          if (widget.initialQuery?.isNotEmpty == true) {
            _performSearch(widget.initialQuery!);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(videoSearchProvider);
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _closeOverlay,
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  height: screenHeight,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search header with padding for system status bar
                      Container(
                        padding: EdgeInsets.only(
                          top: systemTopPadding + 8,
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: _buildSearchHeader(),
                      ),
                      
                      // Filters (if enabled and expanded)
                      if (widget.showFilters && _isFiltersExpanded)
                        _buildFiltersSection(),
                      
                      // Search content
                      Expanded(
                        child: _buildSearchContent(searchState),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // HEADER SECTION
  // ===============================

  Widget _buildSearchHeader() {
    return Column(
      children: [
        // Search bar row
        Row(
          children: [
            // Search input
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search videos or creators...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchSubmitted,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Cancel button
            GestureDetector(
              onTap: _closeOverlay,
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        // Filter toggle and quick stats
        if (widget.showFilters) ...[
          const SizedBox(height: 12),
          _buildQuickFiltersRow(),
        ],
      ],
    );
  }

  Widget _buildQuickFiltersRow() {
    final searchState = ref.watch(videoSearchProvider);
    
    return Row(
      children: [
        // Filter toggle button
        GestureDetector(
          onTap: () {
            setState(() {
              _isFiltersExpanded = !_isFiltersExpanded;
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isFiltersExpanded ? Colors.red.withOpacity(0.2) : Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFiltersExpanded ? Colors.red : Colors.grey[600]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: _isFiltersExpanded ? Colors.red : Colors.grey[300],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: TextStyle(
                    color: _isFiltersExpanded ? Colors.red : Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (searchState.filters.hasActiveFilters) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // Search results info
        if (searchState.hasResults) ...[
          Text(
            '${searchState.totalResults} results',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ref.watch(searchTimeTakenProvider),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  // ===============================
  // FILTERS SECTION
  // ===============================

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Media type filter
          _buildFilterRow(
            'Content Type',
            _buildMediaTypeFilter(),
          ),
          
          const SizedBox(height: 12),
          
          // Sort and verification filters
          Row(
            children: [
              Expanded(
                child: _buildFilterRow(
                  'Sort',
                  _buildSortFilter(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterRow(
                  'Quality',
                  _buildVerificationFilter(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Reset filters button
          if (ref.watch(videoSearchProvider).filters.hasActiveFilters)
            GestureDetector(
              onTap: () {
                ref.read(searchControllerProvider.notifier).resetFilters();
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reset Filters',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

  Widget _buildFilterRow(String label, Widget filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        filter,
      ],
    );
  }

  Widget _buildMediaTypeFilter() {
    final currentFilter = ref.watch(videoSearchProvider).filters.mediaType;
    
    return Row(
      children: [
        _buildFilterChip('All', 'all', currentFilter, (value) {
          _applyFilter(mediaType: value);
        }),
        const SizedBox(width: 8),
        _buildFilterChip('Videos', 'video', currentFilter, (value) {
          _applyFilter(mediaType: value);
        }),
        const SizedBox(width: 8),
        _buildFilterChip('Images', 'image', currentFilter, (value) {
          _applyFilter(mediaType: value);
        }),
      ],
    );
  }

  Widget _buildSortFilter() {
    final currentSort = ref.watch(videoSearchProvider).filters.sortBy;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Best Match', 'relevance', currentSort, (value) {
            _applyFilter(sortBy: value);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Latest', 'latest', currentSort, (value) {
            _applyFilter(sortBy: value);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Popular', 'popular', currentSort, (value) {
            _applyFilter(sortBy: value);
          }),
        ],
      ),
    );
  }

  Widget _buildVerificationFilter() {
    final currentFilter = ref.watch(videoSearchProvider).filters.isVerified;
    
    return Row(
      children: [
        _buildFilterChip('All', null, currentFilter, (value) {
          _applyFilter(isVerified: value);
        }),
        const SizedBox(width: 8),
        _buildFilterChip('Verified', true, currentFilter, (value) {
          _applyFilter(isVerified: value);
        }),
      ],
    );
  }

  Widget _buildFilterChip<T>(String label, T value, T currentValue, Function(T) onTap) {
    final isSelected = value == currentValue;
    
    return GestureDetector(
      onTap: () {
        onTap(value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===============================
  // CONTENT SECTION
  // ===============================

  Widget _buildSearchContent(VideoSearchState searchState) {
    if (searchState.isInitial || (_searchController.text.isEmpty && !searchState.hasQuery)) {
      return SearchSuggestions(
        onSuggestionTap: _onSuggestionTap,
        onTrendingTap: _onTrendingTap,
        onRecentTap: _onRecentTap,
      );
    }
    
    if (searchState.isLoading) {
      return _buildLoadingState();
    }
    
    if (searchState.isError) {
      return _buildErrorState(searchState.errorMessage ?? 'Search failed');
    }
    
    if (searchState.isEmpty) {
      return _buildEmptyState();
    }
    
    if (searchState.hasResults) {
      return SearchResultsGrid(
        results: searchState.results,
        onVideoTap: _onVideoTap,
        onLoadMore: _canLoadMore(searchState) ? _loadMore : null,
        isLoadingMore: searchState.isLoading && searchState.hasResults,
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.red,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Error',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(searchControllerProvider.notifier).retrySearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Suggestions from API response
            if (ref.watch(videoSearchProvider).suggestions.isNotEmpty) ...[
              Text(
                'Try these suggestions:',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ref.watch(videoSearchProvider).suggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => _onSuggestionTap(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===============================
  // EVENT HANDLERS
  // ===============================

  void _onSearchChanged(String query) {
    setState(() {}); // Update clear button visibility
    
    // Cancel previous timer
    _suggestionTimer?.cancel();
    
    // Get suggestions after short delay
    if (query.length >= 2) {
      _suggestionTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(videoSearchProvider.notifier).getSuggestions(query);
        }
      });
    }
    
    // Perform search with debouncing
    ref.read(videoSearchProvider.notifier).search(query);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    ref.read(videoSearchProvider.notifier).searchImmediate(query);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(videoSearchProvider.notifier).clearSearch();
    setState(() {});
  }

  void _closeOverlay() {
    _searchFocusNode.unfocus();
    
    // Animate out
    _slideController.reverse();
    _fadeController.reverse();
    
    // Close after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _onVideoTap(String videoId) {
    _closeOverlay();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (widget.onVideoTap != null) {
        widget.onVideoTap!(videoId);
      } else {
        // Default navigation to videos feed
        Navigator.pushNamed(
          context,
          Constants.videosFeedScreen,
          arguments: {
            Constants.startVideoId: videoId,
          },
        );
      }
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _onTrendingTap(String term) {
    _searchController.text = term;
    _performSearch(term);
  }

  void _onRecentTap(String recent) {
    _searchController.text = recent;
    _performSearch(recent);
  }

  void _applyFilter({
    String? mediaType,
    String? sortBy,
    bool? isVerified,
    bool? hasPrice,
  }) {
    final currentFilters = ref.read(videoSearchProvider).filters;
    final newFilters = currentFilters.copyWith(
      mediaType: mediaType,
      sortBy: sortBy,
      isVerified: isVerified,
      hasPrice: hasPrice,
    );
    
    ref.read(videoSearchProvider.notifier).applyFilters(newFilters);
  }

  void _loadMore() {
    ref.read(videoSearchProvider.notifier).loadMore();
  }

  bool _canLoadMore(VideoSearchState state) {
    return state.hasMore && !state.isLoading;
  }
}

// ===============================
// SEARCH OVERLAY CONTROLLER
// ===============================

class SearchOverlayController {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show(
    BuildContext context, {
    Function(String videoId)? onVideoTap,
    bool showFilters = true,
    String? initialQuery,
  }) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => SearchOverlay(
        onClose: () {
          hide();
        },
        onVideoTap: onVideoTap,
        showFilters: showFilters,
        initialQuery: initialQuery,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    if (!_isShowing || _overlayEntry == null) return;

    _overlayEntry!.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  static bool get isShowing => _isShowing;
}