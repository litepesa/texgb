// ===============================
// lib/features/videos/providers/video_search_provider.dart
// SIMPLIFIED Search Provider - No Suggestions, Just Search
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/videos/repositories/video_search_repository.dart';

part 'video_search_provider.g.dart';

// ===============================
// SIMPLE SEARCH STATE
// ===============================

enum SearchStatus { idle, loading, success, error, empty }

class SimpleSearchState {
  final SearchStatus status;
  final String query;
  final List<VideoModel> videos;
  final int totalResults;
  final bool hasMore;
  final String? errorMessage;
  final bool usernameOnly;

  const SimpleSearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.videos = const [],
    this.totalResults = 0,
    this.hasMore = false,
    this.errorMessage,
    this.usernameOnly = false,
  });

  SimpleSearchState copyWith({
    SearchStatus? status,
    String? query,
    List<VideoModel>? videos,
    int? totalResults,
    bool? hasMore,
    String? errorMessage,
    bool? usernameOnly,
  }) {
    return SimpleSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      videos: videos ?? this.videos,
      totalResults: totalResults ?? this.totalResults,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      usernameOnly: usernameOnly ?? this.usernameOnly,
    );
  }

  bool get isLoading => status == SearchStatus.loading;
  bool get isSuccess => status == SearchStatus.success;
  bool get isEmpty => status == SearchStatus.empty;
  bool get isError => status == SearchStatus.error;
  bool get hasResults => videos.isNotEmpty;

  @override
  String toString() {
    return 'SimpleSearchState(status: $status, query: "$query", videos: ${videos.length}, total: $totalResults, usernameOnly: $usernameOnly)';
  }
}

// ===============================
// REPOSITORY PROVIDER
// ===============================

@riverpod
VideoSearchRepository searchRepository(SearchRepositoryRef ref) {
  return VideoSearchRepository();
}

// ===============================
// MAIN SEARCH PROVIDER
// ===============================

@riverpod
class VideoSearch extends _$VideoSearch {
  Timer? _debounceTimer;

  @override
  SimpleSearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      debugPrint('🔍 VideoSearch disposed');
    });
    return const SimpleSearchState();
  }

  /// Perform search with debouncing (for real-time typing)
  void search(String query, {bool usernameOnly = false}) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();

    // Clear results if query is too short
    if (trimmed.length < 2) {
      state = const SimpleSearchState();
      return;
    }

    // Set loading state immediately
    state = state.copyWith(
      status: SearchStatus.loading,
      query: trimmed,
      usernameOnly: usernameOnly,
    );

    // Debounce the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch(trimmed, usernameOnly);
      }
    });
  }

  /// Search immediately without debouncing (for submit action)
  Future<void> searchNow(String query, {bool usernameOnly = false}) async {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.length < 2) {
      state = const SimpleSearchState();
      return;
    }

    await _performSearch(trimmed, usernameOnly);
  }

  /// Load more results (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    try {
      debugPrint('📄 Loading more results (offset: ${state.videos.length})');

      final repository = ref.read(searchRepositoryProvider);
      final response = await repository.searchVideos(
        query: state.query,
        usernameOnly: state.usernameOnly,
        limit: 20,
        offset: state.videos.length,
      );

      // Append new videos to existing list
      state = state.copyWith(
        videos: [...state.videos, ...response.videos],
        hasMore: response.hasMore,
        totalResults: response.total,
      );

      debugPrint(
          '✅ Loaded more: ${response.videos.length} videos (total: ${state.videos.length})');
    } catch (e) {
      debugPrint('❌ Load more error: $e');
      // Don't update state on pagination errors - just log it
    }
  }

  /// Clear search and reset to idle
  void clear() {
    _debounceTimer?.cancel();
    state = const SimpleSearchState();
    debugPrint('🧹 Search cleared');
  }

  /// Toggle username-only filter
  void toggleUsernameOnly() {
    if (state.query.isNotEmpty) {
      final newValue = !state.usernameOnly;
      debugPrint('🔄 Toggling usernameOnly: $newValue');
      searchNow(state.query, usernameOnly: newValue);
    }
  }

  /// Retry last search (for error recovery)
  Future<void> retry() async {
    if (state.query.isNotEmpty) {
      debugPrint('🔄 Retrying search: "${state.query}"');
      await searchNow(state.query, usernameOnly: state.usernameOnly);
    }
  }

  // ===============================
  // PRIVATE METHODS
  // ===============================

  Future<void> _performSearch(String query, bool usernameOnly) async {
    try {
      debugPrint('🔍 Searching: "$query" (usernameOnly: $usernameOnly)');

      state = state.copyWith(
        status: SearchStatus.loading,
        query: query,
        usernameOnly: usernameOnly,
      );

      final repository = ref.read(searchRepositoryProvider);
      final response = await repository.searchVideos(
        query: query,
        usernameOnly: usernameOnly,
        limit: 20,
        offset: 0,
      );

      if (response.isEmpty) {
        state = state.copyWith(
          status: SearchStatus.empty,
          videos: [],
          totalResults: 0,
          hasMore: false,
        );
        debugPrint('📭 No results found for: "$query"');
      } else {
        state = state.copyWith(
          status: SearchStatus.success,
          videos: response.videos,
          totalResults: response.total,
          hasMore: response.hasMore,
        );
        debugPrint(
            '✅ Search complete: ${response.videos.length} videos (total: ${response.total})');
      }
    } catch (e) {
      debugPrint('❌ Search failed: $e');
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: e.toString(),
        videos: [],
      );
    }
  }

  // Helper to check if provider is still mounted
  bool get mounted =>
      state.status != SearchStatus.idle || state.query.isNotEmpty;
}

// ===============================
// CONVENIENCE PROVIDERS
// ===============================

/// Current search state
@riverpod
SimpleSearchState searchState(SearchStateRef ref) {
  return ref.watch(videoSearchProvider);
}

/// Search results (list of videos)
@riverpod
List<VideoModel> searchResults(SearchResultsRef ref) {
  return ref.watch(videoSearchProvider).videos;
}

/// Is currently searching
@riverpod
bool isSearching(IsSearchingRef ref) {
  return ref.watch(videoSearchProvider).isLoading;
}

/// Search error message
@riverpod
String? searchError(SearchErrorRef ref) {
  return ref.watch(videoSearchProvider).errorMessage;
}

/// Has search results
@riverpod
bool hasSearchResults(HasSearchResultsRef ref) {
  return ref.watch(videoSearchProvider).hasResults;
}

/// Current search query
@riverpod
String searchQuery(SearchQueryRef ref) {
  return ref.watch(videoSearchProvider).query;
}

/// Username-only filter active
@riverpod
bool isUsernameOnlyActive(IsUsernameOnlyActiveRef ref) {
  return ref.watch(videoSearchProvider).usernameOnly;
}

/// Has more results to load
@riverpod
bool hasMoreResults(HasMoreResultsRef ref) {
  return ref.watch(videoSearchProvider).hasMore;
}

/// Total results count
@riverpod
int totalResultsCount(TotalResultsCountRef ref) {
  return ref.watch(videoSearchProvider).totalResults;
}

/// Results count display text
@riverpod
String resultsCountText(ResultsCountTextRef ref) {
  final state = ref.watch(videoSearchProvider);
  if (state.isEmpty) return 'No results';
  if (state.totalResults == 1) return '1 result';
  return '${state.totalResults} results';
}
