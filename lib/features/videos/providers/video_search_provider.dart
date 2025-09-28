// ===============================
// lib/features/videos/providers/video_search_provider.dart
// Riverpod State Management for Video Search
// Handles search state, caching, debouncing, and history
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/features/videos/repositories/video_search_repository.dart';
import 'package:textgb/shared/services/http_client.dart';

part 'video_search_provider.g.dart';

// ===============================
// REPOSITORY PROVIDER
// ===============================

@riverpod
VideoSearchRepository videoSearchRepository(VideoSearchRepositoryRef ref) {
  return VideoSearchRepositoryImpl();
}

// ===============================
// MAIN SEARCH STATE PROVIDER
// ===============================

@riverpod
class VideoSearch extends _$VideoSearch {
  Timer? _debounceTimer;
  VideoSearchRepository get _repository => ref.read(videoSearchRepositoryProvider);

  @override
  VideoSearchState build() {
    // Initialize with empty state and load initial data
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    // Load initial data (trending terms, search history)
    _loadInitialData();
    
    return VideoSearchState.initial();
  }

  // ===============================
  // PUBLIC SEARCH METHODS
  // ===============================

  /// Perform search with debouncing for real-time search
  Future<void> search(String query, {SearchFilters? filters, String? mode}) async {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Validate and sanitize query
    final sanitizedQuery = _sanitizeSearchQuery(query);
    
    if (!_isValidSearchQuery(sanitizedQuery)) {
      if (sanitizedQuery.isEmpty) {
        // Clear results for empty query
        state = VideoSearchState.initial().copyWith(
          suggestions: state.suggestions,
          recentSearches: state.recentSearches,
          trendingTerms: state.trendingTerms,
        );
        return;
      } else {
        // Invalid query
        state = VideoSearchState.error(
          errorMessage: 'Search query must be between ${SearchConstants.minSearchQueryLength} and ${SearchConstants.maxSearchQueryLength} characters',
          query: sanitizedQuery,
        );
        return;
      }
    }

    // Set loading state immediately
    state = VideoSearchState.loading(query: sanitizedQuery);

    // Debounce the actual search
    _debounceTimer = Timer(const Duration(milliseconds: SearchConstants.searchDebounceMs), () {
      _performSearch(sanitizedQuery, filters: filters, mode: mode);
    });
  }

  /// Perform immediate search without debouncing
  Future<void> searchImmediate(String query, {SearchFilters? filters, String? mode}) async {
    _debounceTimer?.cancel();
    
    final sanitizedQuery = _sanitizeSearchQuery(query);
    
    if (!_isValidSearchQuery(sanitizedQuery)) {
      state = VideoSearchState.error(
        errorMessage: 'Invalid search query',
        query: sanitizedQuery,
      );
      return;
    }

    await _performSearch(sanitizedQuery, filters: filters, mode: mode);
  }

  /// Load more results (pagination)
  Future<void> loadMore() async {
    if (!state.canLoadMore) return;

    try {
      final currentRequest = VideoSearchRequest(
        query: state.query,
        filters: state.filters,
        mode: state.searchMode,
        limit: SearchConstants.defaultResultsPerPage,
        offset: state.results.length, // Use current results count as offset
      );

      final response = await _repository.searchVideos(currentRequest);

      // Append new results to existing ones
      final allResults = [...state.results, ...response.results];

      state = VideoSearchState.success(
        query: response.query,
        results: allResults,
        totalResults: response.total,
        hasMore: response.hasMore,
        currentPage: state.currentPage + 1,
        searchMode: response.searchMode,
        timeTaken: response.timeTaken,
        filters: state.filters,
      );
    } catch (e) {
      debugPrint('❌ Error loading more results: $e');
      // Keep current state but show error message
      state = state.copyWith(
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Clear search results and return to initial state
  void clearSearch() {
    _debounceTimer?.cancel();
    state = VideoSearchState.initial().copyWith(
      suggestions: state.suggestions,
      recentSearches: state.recentSearches,
      trendingTerms: state.trendingTerms,
    );
  }

  /// Apply filters to current search
  Future<void> applyFilters(SearchFilters filters) async {
    if (state.query.isEmpty) return;

    state = state.copyWith(
      status: SearchStatus.loading,
      filters: filters,
    );

    await _performSearch(state.query, filters: filters, mode: state.searchMode);
  }

  /// Change search mode and re-search
  Future<void> changeSearchMode(String mode) async {
    if (state.query.isEmpty) return;

    state = state.copyWith(
      status: SearchStatus.loading,
      searchMode: mode,
    );

    await _performSearch(state.query, filters: state.filters, mode: mode);
  }

  // ===============================
  // SUGGESTIONS METHODS
  // ===============================

  /// Get real-time search suggestions as user types
  Future<void> getSuggestions(String query) async {
    if (query.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }

    try {
      final suggestions = await _repository.getSearchSuggestions(query, limit: 5);
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      debugPrint('❌ Error getting suggestions: $e');
      // Don't update state on suggestion errors
    }
  }

  /// Refresh trending search terms
  Future<void> refreshTrendingTerms() async {
    try {
      final trendingTerms = await _repository.getPopularSearchTerms(limit: 10);
      final termStrings = trendingTerms.map((term) => term.text).toList();
      state = state.copyWith(trendingTerms: termStrings);
    } catch (e) {
      debugPrint('❌ Error refreshing trending terms: $e');
    }
  }

  // ===============================
  // SEARCH HISTORY METHODS
  // ===============================

  /// Load search history from local storage
  Future<void> loadSearchHistory() async {
    try {
      final history = await _repository.getSearchHistory();
      final recentSearches = history.map((item) => item.query).toList();
      state = state.copyWith(recentSearches: recentSearches);
    } catch (e) {
      debugPrint('❌ Error loading search history: $e');
    }
  }

  /// Add search to history
  Future<void> addToHistory(String query, int resultsCount) async {
    try {
      final historyItem = SearchHistoryItem(
        query: query,
        timestamp: DateTime.now(),
        resultsCount: resultsCount,
      );
      
      await _repository.addSearchToHistory(historyItem);
      
      // Update state with new history
      final updatedHistory = [query, ...state.recentSearches];
      state = state.copyWith(
        recentSearches: updatedHistory.take(SearchConstants.maxSearchHistoryItems).toList(),
      );
    } catch (e) {
      debugPrint('❌ Error adding to search history: $e');
    }
  }

  /// Remove search from history
  Future<void> removeFromHistory(String query) async {
    try {
      await _repository.removeSearchFromHistory(query);
      
      final updatedHistory = state.recentSearches.where((item) => item != query).toList();
      state = state.copyWith(recentSearches: updatedHistory);
    } catch (e) {
      debugPrint('❌ Error removing from search history: $e');
    }
  }

  /// Clear all search history
  Future<void> clearSearchHistory() async {
    try {
      await _repository.clearSearchHistory();
      state = state.copyWith(recentSearches: []);
    } catch (e) {
      debugPrint('❌ Error clearing search history: $e');
    }
  }

  // ===============================
  // PRIVATE METHODS
  // ===============================

  /// Load initial data (trending terms and history)
  Future<void> _loadInitialData() async {
    try {
      // Load in parallel
      await Future.wait([
        refreshTrendingTerms(),
        loadSearchHistory(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading initial search data: $e');
    }
  }

  /// Perform the actual search operation
  Future<void> _performSearch(String query, {SearchFilters? filters, String? mode}) async {
    try {
      final request = VideoSearchRequest(
        query: query,
        filters: filters ?? state.filters,
        mode: mode ?? state.searchMode,
        limit: SearchConstants.defaultResultsPerPage,
        offset: 0,
      );

      final response = await _repository.searchVideos(request);

      if (response.results.isEmpty) {
        state = VideoSearchState.empty(
          query: response.query,
          suggestions: response.suggestions,
        );
      } else {
        state = VideoSearchState.success(
          query: response.query,
          results: response.results,
          totalResults: response.total,
          hasMore: response.hasMore,
          currentPage: 1,
          searchMode: response.searchMode,
          timeTaken: response.timeTaken,
          filters: request.filters,
        );

        // Add to search history
        addToHistory(query, response.total);
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      state = VideoSearchState.error(
        errorMessage: _getErrorMessage(e),
        query: query,
      );
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Validate search query
  bool _isValidSearchQuery(String query) {
    final trimmed = query.trim();
    return trimmed.isNotEmpty && 
           trimmed.length >= SearchConstants.minSearchQueryLength &&
           trimmed.length <= SearchConstants.maxSearchQueryLength;
  }

  /// Sanitize search query
  String _sanitizeSearchQuery(String query) {
    // Remove excessive whitespace
    String sanitized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove potentially problematic characters for search
    sanitized = sanitized.replaceAll(RegExp(r'[<>{}[\]\\|`~]'), '');
    
    // Limit length
    if (sanitized.length > SearchConstants.maxSearchQueryLength) {
      sanitized = sanitized.substring(0, SearchConstants.maxSearchQueryLength);
    }
    
    return sanitized;
  }

  /// Convert exceptions to user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is VideoSearchException) {
      return error.message;
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Search request timed out. Please try again.';
    }
    
    if (errorString.contains('format')) {
      return 'Invalid response from server. Please try again.';
    }
    
    return 'Search failed. Please try again.';
  }
}

// ===============================
// CONVENIENCE PROVIDERS
// ===============================

/// Current search state
@riverpod
VideoSearchState searchState(SearchStateRef ref) {
  return ref.watch(videoSearchProvider);
}

/// Whether search is currently loading
@riverpod
bool isSearchLoading(IsSearchLoadingRef ref) {
  return ref.watch(videoSearchProvider).isLoading;
}

/// Current search results
@riverpod
List<VideoSearchResult> searchResults(SearchResultsRef ref) {
  return ref.watch(videoSearchProvider).results;
}

/// Current search query
@riverpod
String searchQuery(SearchQueryRef ref) {
  return ref.watch(videoSearchProvider).query;
}

/// Search suggestions for autocomplete
@riverpod
List<String> searchSuggestions(SearchSuggestionsRef ref) {
  return ref.watch(videoSearchProvider).suggestions;
}

/// Recent search history
@riverpod
List<String> recentSearches(RecentSearchesRef ref) {
  return ref.watch(videoSearchProvider).recentSearches;
}

/// Trending search terms
@riverpod
List<String> trendingTerms(TrendingTermsRef ref) {
  return ref.watch(videoSearchProvider).trendingTerms;
}

/// Current search filters
@riverpod
SearchFilters searchFilters(SearchFiltersRef ref) {
  return ref.watch(videoSearchProvider).filters;
}

/// Whether there are more results to load
@riverpod
bool canLoadMoreResults(CanLoadMoreResultsRef ref) {
  return ref.watch(videoSearchProvider).canLoadMore;
}

/// Search error message
@riverpod
String? searchError(SearchErrorRef ref) {
  return ref.watch(videoSearchProvider).errorMessage;
}

/// Whether search has results
@riverpod
bool hasSearchResults(HasSearchResultsRef ref) {
  return ref.watch(videoSearchProvider).hasResults;
}

/// Search results count
@riverpod
int searchResultsCount(SearchResultsCountRef ref) {
  return ref.watch(videoSearchProvider).totalResults;
}

/// Search time taken
@riverpod
String searchTimeTaken(SearchTimeTakenRef ref) {
  final timeTaken = ref.watch(videoSearchProvider).timeTaken;
  if (timeTaken < 1000) {
    return '${timeTaken}ms';
  } else {
    return '${(timeTaken / 1000).toStringAsFixed(1)}s';
  }
}

// ===============================
// SEARCH CONTROLLER PROVIDER
// ===============================

/// Search controller for managing search operations
@riverpod
class SearchController extends _$SearchController {
  @override
  void build() {
    // No initial state needed
  }

  /// Quick search with default settings
  Future<void> quickSearch(String query) async {
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.searchImmediate(query);
  }

  /// Advanced search with filters
  Future<void> advancedSearch({
    required String query,
    SearchFilters? filters,
    String? mode,
  }) async {
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.searchImmediate(query, filters: filters, mode: mode);
  }

  /// Search from suggestion or history
  Future<void> searchFromSuggestion(String query) async {
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.searchImmediate(query);
  }

  /// Toggle between video and image search
  Future<void> toggleMediaType() async {
    final currentFilters = ref.read(searchFiltersProvider);
    final newMediaType = currentFilters.mediaType == 'video' ? 'image' : 'video';
    
    final newFilters = currentFilters.copyWith(mediaType: newMediaType);
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.applyFilters(newFilters);
  }

  /// Sort results by different criteria
  Future<void> sortResults(String sortBy) async {
    final currentFilters = ref.read(searchFiltersProvider);
    final newFilters = currentFilters.copyWith(sortBy: sortBy);
    
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.applyFilters(newFilters);
  }

  /// Filter by verification status
  Future<void> filterByVerification(bool? isVerified) async {
    final currentFilters = ref.read(searchFiltersProvider);
    final newFilters = currentFilters.copyWith(isVerified: isVerified);
    
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.applyFilters(newFilters);
  }

  /// Filter by price range
  Future<void> filterByPrice(bool? hasPrice) async {
    final currentFilters = ref.read(searchFiltersProvider);
    final newFilters = currentFilters.copyWith(hasPrice: hasPrice);
    
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.applyFilters(newFilters);
  }

  /// Reset all filters
  Future<void> resetFilters() async {
    final searchNotifier = ref.read(videoSearchProvider.notifier);
    await searchNotifier.applyFilters(const SearchFilters());
  }

  /// Retry last search
  Future<void> retrySearch() async {
    final currentState = ref.read(videoSearchProvider);
    if (currentState.query.isNotEmpty) {
      final searchNotifier = ref.read(videoSearchProvider.notifier);
      await searchNotifier.searchImmediate(
        currentState.query,
        filters: currentState.filters,
        mode: currentState.searchMode,
      );
    }
  }
}

// ===============================
// SEARCH ANALYTICS PROVIDER
// ===============================

/// Track search analytics for optimization
@riverpod
class SearchAnalytics extends _$SearchAnalytics {
  @override
  Map<String, dynamic> build() {
    return {
      'totalSearches': 0,
      'successfulSearches': 0,
      'averageResponseTime': 0.0,
      'popularQueries': <String, int>{},
      'lastSearchTime': null,
    };
  }

  void trackSearch({
    required String query,
    required bool successful,
    required int timeTaken,
    int? resultsCount,
  }) {
    final currentStats = state;
    final totalSearches = (currentStats['totalSearches'] as int) + 1;
    final successfulSearches = (currentStats['successfulSearches'] as int) + (successful ? 1 : 0);
    final popularQueries = Map<String, int>.from(currentStats['popularQueries'] as Map);
    
    // Update popular queries
    popularQueries[query.toLowerCase()] = (popularQueries[query.toLowerCase()] ?? 0) + 1;
    
    // Calculate average response time
    final currentAverage = currentStats['averageResponseTime'] as double;
    final newAverage = ((currentAverage * (totalSearches - 1)) + timeTaken) / totalSearches;

    state = {
      'totalSearches': totalSearches,
      'successfulSearches': successfulSearches,
      'averageResponseTime': newAverage,
      'popularQueries': popularQueries,
      'lastSearchTime': DateTime.now().toIso8601String(),
    };
  }

  double get successRate {
    final total = state['totalSearches'] as int;
    final successful = state['successfulSearches'] as int;
    return total > 0 ? (successful / total) * 100 : 0.0;
  }

  List<String> get topQueries {
    final popularQueries = state['popularQueries'] as Map<String, int>;
    final sorted = popularQueries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList();
  }
}

// ===============================
// SEARCH CACHE PROVIDER
// ===============================

/// Simple in-memory cache for search results
@riverpod
class SearchCache extends _$SearchCache {
  @override
  Map<String, VideoSearchResponse> build() {
    return {};
  }

  void cacheResults(String key, VideoSearchResponse response) {
    // Limit cache size to prevent memory issues
    if (state.length >= 50) {
      // Remove oldest entries
      final keys = state.keys.toList();
      for (int i = 0; i < 10; i++) {
        state.remove(keys[i]);
      }
    }
    
    state = {...state, key: response};
  }

  VideoSearchResponse? getResults(String key) {
    return state[key];
  }

  void clearCache() {
    state = {};
  }

  bool hasResults(String key) {
    return state.containsKey(key);
  }

  String generateCacheKey(VideoSearchRequest request) {
    return '${request.query}_${request.mode}_${request.filters.hashCode}_${request.offset}';
  }
}