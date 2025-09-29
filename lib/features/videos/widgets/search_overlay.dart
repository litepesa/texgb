// ===============================
// lib/features/videos/widgets/search_overlay.dart
// Clean TikTok-Style Search Overlay - Minimalist Design
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/features/videos/providers/video_search_provider.dart';
import 'package:textgb/features/videos/widgets/search_results_grid.dart';

class SearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final Function(String videoId)? onVideoTap;
  final String? initialQuery;

  const SearchOverlay({
    super.key,
    required this.onClose,
    this.onVideoTap,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFocusNode = FocusNode();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _searchFocusNode.requestFocus();
          
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
    _debounceTimer?.cancel();
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
        onTap: () {
          // Only close if tapping outside when no results
          if (!searchState.hasResults) {
            _closeOverlay();
          }
        },
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                height: screenHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    // Search header
                    Container(
                      padding: EdgeInsets.only(
                        top: systemTopPadding + 8,
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildSearchHeader(),
                    ),
                    
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
    );
  }

  // ===============================
  // SEARCH HEADER
  // ===============================

  Widget _buildSearchHeader() {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: _closeOverlay,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.black87,
              size: 24,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Search input
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: Colors.grey[500],
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _clearSearch,
                        child: Icon(
                          Icons.cancel,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
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
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ===============================
  // SEARCH CONTENT
  // ===============================

  Widget _buildSearchContent(VideoSearchState searchState) {
    // Show suggestions when typing or no query
    if (_searchController.text.isEmpty || searchState.suggestions.isNotEmpty) {
      return _buildSuggestions(searchState);
    }
    
    if (searchState.isLoading && !searchState.hasResults) {
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
        padding: const EdgeInsets.all(12),
        crossAxisCount: 3,
        childAspectRatio: 0.65,
      );
    }
    
    return const SizedBox.shrink();
  }

  // ===============================
  // SUGGESTIONS (CLEAN & SIMPLE)
  // ===============================

  Widget _buildSuggestions(VideoSearchState searchState) {
    final suggestions = searchState.suggestions;
    final recentSearches = ref.watch(recentSearchesProvider);
    final trendingTerms = ref.watch(trendingTermsProvider);

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Search suggestions (real-time)
          if (suggestions.isNotEmpty) ...[
            ...suggestions.take(10).map((suggestion) {
              return _buildSuggestionItem(
                text: suggestion,
                icon: CupertinoIcons.search,
                onTap: () => _onSuggestionTap(suggestion),
              );
            }).toList(),
          ]
          // Recent searches (when no suggestions)
          else if (recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Recent',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(videoSearchProvider.notifier).clearSearchHistory();
                      HapticFeedback.lightImpact();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...recentSearches.take(8).map((search) {
              return _buildSuggestionItem(
                text: search,
                icon: CupertinoIcons.time,
                onTap: () => _onSuggestionTap(search),
                trailing: GestureDetector(
                  onTap: () {
                    ref.read(videoSearchProvider.notifier).removeFromHistory(search);
                    HapticFeedback.lightImpact();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),
                ),
              );
            }).toList(),
          ]
          // Trending (when no recent searches)
          else if (trendingTerms.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Trending',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...trendingTerms.take(10).map((term) {
              return _buildSuggestionItem(
                text: term,
                icon: CupertinoIcons.flame,
                iconColor: Colors.red[400],
                onTap: () => _onSuggestionTap(term),
              );
            }).toList(),
          ]
          // Empty state
          else ...[
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: Colors.grey[300],
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for videos',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({
    required String text,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ===============================
  // LOADING STATE
  // ===============================

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.black87,
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ===============================
  // ERROR STATE
  // ===============================

  Widget _buildErrorState(String errorMessage) {
    return Container(
      color: Colors.white,
      child: Center(
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
                'Something went wrong',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  ref.read(searchControllerProvider.notifier).retrySearch();
                },
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // EMPTY STATE
  // ===============================

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.search,
                color: Colors.grey[300],
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // EVENT HANDLERS
  // ===============================

  void _onSearchChanged(String query) {
    setState(() {}); // Update clear button
    
    _debounceTimer?.cancel();
    
    if (query.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(videoSearchProvider.notifier).getSuggestions(query);
        }
      });
    }
    
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
    _searchFocusNode.requestFocus();
  }

  void _closeOverlay() {
    _searchFocusNode.unfocus();
    _slideController.reverse();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _onVideoTap(String videoId) {
    _closeOverlay();
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onVideoTap?.call(videoId);
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
    HapticFeedback.selectionClick();
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