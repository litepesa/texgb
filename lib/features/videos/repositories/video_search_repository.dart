// ===============================
// lib/features/videos/repositories/video_search_repository.dart
// Video Search Repository for Backend API Integration
// Handles all search-related API calls to Go backend
// ===============================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:textgb/features/videos/models/search_models.dart';
import 'package:textgb/shared/services/http_client.dart';

// ===============================
// ABSTRACT REPOSITORY INTERFACE
// ===============================

abstract class VideoSearchRepository {
  // Core search operations
  Future<VideoSearchResponse> searchVideos(VideoSearchRequest request);
  Future<List<String>> getSearchSuggestions(String query, {int limit = 5});
  Future<List<SearchSuggestion>> getPopularSearchTerms({int limit = 10});
  
  // Search history (local storage)
  Future<List<SearchHistoryItem>> getSearchHistory();
  Future<void> addSearchToHistory(SearchHistoryItem item);
  Future<void> clearSearchHistory();
  Future<void> removeSearchFromHistory(String query);
}

// ===============================
// REPOSITORY IMPLEMENTATION
// ===============================

class VideoSearchRepositoryImpl implements VideoSearchRepository {
  final HttpClientService _httpClient;
  static const String _searchHistoryKey = 'video_search_history';

  VideoSearchRepositoryImpl({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // CORE SEARCH OPERATIONS
  // ===============================

  @override
  Future<VideoSearchResponse> searchVideos(VideoSearchRequest request) async {
    try {
      debugPrint('🔍 Searching videos: "${request.query}" with mode: ${request.mode}');
      
      // Validate query
      if (request.query.trim().isEmpty) {
        throw VideoSearchException('Search query cannot be empty');
      }

      if (request.query.length < SearchConstants.minSearchQueryLength) {
        throw VideoSearchException('Search query must be at least ${SearchConstants.minSearchQueryLength} characters');
      }

      if (request.query.length > SearchConstants.maxSearchQueryLength) {
        throw VideoSearchException('Search query cannot exceed ${SearchConstants.maxSearchQueryLength} characters');
      }

      // Build query parameters
      final queryParams = request.toQueryParams();
      
      // Create URL with query parameters
      final uri = Uri.parse('/videos/search').replace(queryParameters: queryParams);
      debugPrint('📤 Search API URL: ${uri.toString()}');

      // Make API request
      final response = await _httpClient.get(uri.toString());
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Search successful: ${responseData['total']} results in ${responseData['timeTaken']}ms');
        
        // Parse response
        final searchResponse = VideoSearchResponse.fromJson(responseData);
        
        // Add filters to response (since backend doesn't return them)
        final responseWithFilters = VideoSearchResponse(
          results: searchResponse.results,
          total: searchResponse.total,
          query: searchResponse.query,
          searchMode: searchResponse.searchMode,
          timeTaken: searchResponse.timeTaken,
          suggestions: searchResponse.suggestions,
          page: searchResponse.page,
          hasMore: searchResponse.hasMore,
          filters: request.filters,
        );

        // Add to search history (fire and forget)
        _addToHistoryAsync(request.query, searchResponse.total);

        return responseWithFilters;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] as String? ?? 'Invalid search request';
        throw VideoSearchException(errorMessage);
      } else if (response.statusCode == 429) {
        throw VideoSearchException('Too many search requests. Please wait a moment before searching again.');
      } else {
        throw VideoSearchException('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      
      if (e is VideoSearchException) {
        rethrow;
      }
      
      // Handle network errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException')) {
        throw VideoSearchException('Network error. Please check your internet connection.');
      }
      
      // Handle JSON parsing errors
      if (e.toString().contains('FormatException')) {
        throw VideoSearchException('Invalid response format from server.');
      }
      
      throw VideoSearchException('Search failed: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String query, {int limit = 5}) async {
    try {
      if (query.trim().isEmpty || query.length < 2) {
        return [];
      }

      debugPrint('💡 Getting search suggestions for: "$query"');

      final queryParams = {
        'q': query.trim(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('/videos/search/suggestions').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri.toString());
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final suggestions = responseData['suggestions'] as List<dynamic>? ?? [];
        
        final result = suggestions.map((s) => s.toString()).take(limit).toList();
        debugPrint('✅ Got ${result.length} suggestions');
        return result;
      } else {
        debugPrint('⚠️ Suggestions request failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting suggestions: $e');
      return []; // Don't throw errors for suggestions - just return empty list
    }
  }

  @override
  Future<List<SearchSuggestion>> getPopularSearchTerms({int limit = 10}) async {
    try {
      debugPrint('📈 Getting popular search terms');

      final queryParams = {
        'limit': limit.toString(),
      };

      final uri = Uri.parse('/videos/search/popular').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri.toString());
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final terms = responseData['terms'] as List<dynamic>? ?? [];
        
        final result = terms.map((term) {
          if (term is String) {
            return SearchSuggestion.trending(term, 0);
          } else if (term is Map<String, dynamic>) {
            return SearchSuggestion.trending(
              term['term'] as String? ?? '',
              term['frequency'] as int? ?? 0,
            );
          }
          return SearchSuggestion.trending(term.toString(), 0);
        }).take(limit).toList();

        debugPrint('✅ Got ${result.length} popular terms');
        return result;
      } else {
        debugPrint('⚠️ Popular terms request failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting popular terms: $e');
      return []; // Don't throw errors for popular terms - just return empty list
    }
  }

  // ===============================
  // SEARCH HISTORY MANAGEMENT (LOCAL STORAGE)
  // ===============================

  @override
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    try {
      // Use SharedPreferences through http client's storage capabilities
      // This is a simple implementation - in a real app you might use SharedPreferences directly
      final historyJson = await _getStoredData(_searchHistoryKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final historyData = jsonDecode(historyJson) as List<dynamic>;
      final history = historyData
          .map((item) => SearchHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by timestamp (most recent first) and limit to max items
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return history.take(SearchConstants.maxSearchHistoryItems).toList();
    } catch (e) {
      debugPrint('❌ Error loading search history: $e');
      return [];
    }
  }

  @override
  Future<void> addSearchToHistory(SearchHistoryItem item) async {
    try {
      final currentHistory = await getSearchHistory();
      
      // Remove existing entry with same query
      currentHistory.removeWhere((existing) => existing.query == item.query);
      
      // Add new item at the beginning
      currentHistory.insert(0, item);
      
      // Limit to max items
      final limitedHistory = currentHistory.take(SearchConstants.maxSearchHistoryItems).toList();
      
      // Save back to storage
      final historyJson = jsonEncode(limitedHistory.map((h) => h.toJson()).toList());
      await _storeData(_searchHistoryKey, historyJson);
      
      debugPrint('💾 Added search to history: "${item.query}"');
    } catch (e) {
      debugPrint('❌ Error adding to search history: $e');
      // Don't throw - history is not critical
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    try {
      await _removeStoredData(_searchHistoryKey);
      debugPrint('🗑️ Cleared search history');
    } catch (e) {
      debugPrint('❌ Error clearing search history: $e');
    }
  }

  @override
  Future<void> removeSearchFromHistory(String query) async {
    try {
      final currentHistory = await getSearchHistory();
      currentHistory.removeWhere((item) => item.query == query);
      
      final historyJson = jsonEncode(currentHistory.map((h) => h.toJson()).toList());
      await _storeData(_searchHistoryKey, historyJson);
      
      debugPrint('🗑️ Removed search from history: "$query"');
    } catch (e) {
      debugPrint('❌ Error removing from search history: $e');
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  // Add search to history asynchronously (fire and forget)
  void _addToHistoryAsync(String query, int resultsCount) {
    if (query.trim().isEmpty) return;
    
    final historyItem = SearchHistoryItem(
      query: query.trim(),
      timestamp: DateTime.now(),
      resultsCount: resultsCount,
    );
    
    // Don't await - this is fire and forget
    addSearchToHistory(historyItem).catchError((error) {
      debugPrint('Failed to add search to history: $error');
    });
  }

  // ===============================
  // STORAGE ABSTRACTION
  // ===============================
  // These methods abstract the storage mechanism
  // In a real implementation, you would use SharedPreferences or another storage solution

  Future<String?> _getStoredData(String key) async {
    // TODO: Implement using SharedPreferences
    // For now, return null (empty history)
    return null;
  }

  Future<void> _storeData(String key, String data) async {
    // TODO: Implement using SharedPreferences
    // For now, do nothing
  }

  Future<void> _removeStoredData(String key) async {
    // TODO: Implement using SharedPreferences
    // For now, do nothing
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  // Test backend connectivity for search endpoints
  Future<bool> testSearchEndpoints() async {
    try {
      // Test basic search endpoint
      final testRequest = VideoSearchRequest(
        query: 'test',
        limit: 1,
      );
      
      await searchVideos(testRequest);
      return true;
    } catch (e) {
      debugPrint('Search endpoints test failed: $e');
      return false;
    }
  }

  // Get search endpoint health
  Future<Map<String, dynamic>> getSearchHealth() async {
    try {
      // This would call a health endpoint if available
      // For now, just test basic functionality
      final isHealthy = await testSearchEndpoints();
      
      return {
        'healthy': isHealthy,
        'timestamp': DateTime.now().toIso8601String(),
        'endpoints': {
          'search': '/videos/search',
          'suggestions': '/videos/search/suggestions',
          'popular': '/videos/search/popular',
        },
      };
    } catch (e) {
      return {
        'healthy': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Build optimized search request for different use cases
  VideoSearchRequest buildQuickSearchRequest(String query) {
    return VideoSearchRequest(
      query: query,
      mode: SearchConstants.modeCombined,
      limit: SearchConstants.defaultResultsPerPage,
      filters: const SearchFilters(
        mediaType: SearchConstants.mediaTypeAll,
        sortBy: SearchConstants.sortByRelevance,
      ),
    );
  }

  VideoSearchRequest buildAdvancedSearchRequest({
    required String query,
    SearchFilters? filters,
    String? mode,
    int? limit,
  }) {
    return VideoSearchRequest(
      query: query,
      mode: mode ?? SearchConstants.modeCombined,
      limit: limit ?? SearchConstants.defaultResultsPerPage,
      filters: filters ?? const SearchFilters(),
    );
  }

  // Validate search query
  bool isValidSearchQuery(String query) {
    final trimmed = query.trim();
    return trimmed.isNotEmpty && 
           trimmed.length >= SearchConstants.minSearchQueryLength &&
           trimmed.length <= SearchConstants.maxSearchQueryLength;
  }

  // Sanitize search query
  String sanitizeSearchQuery(String query) {
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

  // Build search URL for sharing
  String buildSearchUrl(VideoSearchRequest request) {
    final queryParams = request.toQueryParams();
    final uri = Uri.parse('/videos/search').replace(queryParameters: queryParams);
    return uri.toString();
  }

  // Parse search mode from string
  String parseSearchMode(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'exact':
        return SearchConstants.modeExact;
      case 'fuzzy':
        return SearchConstants.modeFuzzy;
      case 'fulltext':
        return SearchConstants.modeFullText;
      case 'combined':
      default:
        return SearchConstants.modeCombined;
    }
  }

  // Get search mode display name
  String getSearchModeDisplayName(String mode) {
    switch (mode) {
      case SearchConstants.modeExact:
        return 'Exact Match';
      case SearchConstants.modeFuzzy:
        return 'Smart Search';
      case SearchConstants.modeFullText:
        return 'Full Text';
      case SearchConstants.modeCombined:
        return 'Best Match';
      default:
        return 'Unknown';
    }
  }

  // Format search results for display
  String formatSearchResultsInfo(VideoSearchResponse response) {
    final mode = getSearchModeDisplayName(response.searchMode);
    return '${response.resultsCountDisplay} found in ${response.timeTakenDisplay} using $mode';
  }

  // Check if search results are cached (placeholder for future caching implementation)
  bool isSearchCached(VideoSearchRequest request) {
    // TODO: Implement caching logic
    return false;
  }

  // Get cached search results (placeholder for future caching implementation)
  Future<VideoSearchResponse?> getCachedSearchResults(VideoSearchRequest request) async {
    // TODO: Implement caching logic
    return null;
  }

  // Cache search results (placeholder for future caching implementation)
  Future<void> cacheSearchResults(VideoSearchRequest request, VideoSearchResponse response) async {
    // TODO: Implement caching logic
  }

  // Clear search cache (placeholder for future caching implementation)
  Future<void> clearSearchCache() async {
    // TODO: Implement caching logic
  }
}

// ===============================
// SEARCH EXCEPTION
// ===============================

class VideoSearchException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const VideoSearchException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null) {
      return 'VideoSearchException($code): $message';
    }
    return 'VideoSearchException: $message';
  }

  // Factory constructors for common error types
  factory VideoSearchException.network() {
    return const VideoSearchException(
      'Network error. Please check your internet connection.',
      code: 'NETWORK_ERROR',
    );
  }

  factory VideoSearchException.timeout() {
    return const VideoSearchException(
      'Search request timed out. Please try again.',
      code: 'TIMEOUT_ERROR',
    );
  }

  factory VideoSearchException.invalidQuery() {
    return const VideoSearchException(
      'Invalid search query. Please check your input.',
      code: 'INVALID_QUERY',
    );
  }

  factory VideoSearchException.serverError() {
    return const VideoSearchException(
      'Server error. Please try again later.',
      code: 'SERVER_ERROR',
    );
  }

  factory VideoSearchException.rateLimited() {
    return const VideoSearchException(
      'Too many search requests. Please wait a moment before searching again.',
      code: 'RATE_LIMITED',
    );
  }

  factory VideoSearchException.noResults() {
    return const VideoSearchException(
      'No results found for your search.',
      code: 'NO_RESULTS',
    );
  }
}

// ===============================
// REPOSITORY PROVIDER SETUP
// ===============================

// This can be used with dependency injection frameworks or Riverpod
abstract class VideoSearchRepositoryProvider {
  static VideoSearchRepository create({HttpClientService? httpClient}) {
    return VideoSearchRepositoryImpl(httpClient: httpClient);
  }
}

// ===============================
// SEARCH METRICS (FOR ANALYTICS)
// ===============================

class SearchMetrics {
  final String query;
  final String mode;
  final int resultsCount;
  final int timeTaken;
  final DateTime timestamp;
  final SearchFilters filters;
  final String? errorCode;

  const SearchMetrics({
    required this.query,
    required this.mode,
    required this.resultsCount,
    required this.timeTaken,
    required this.timestamp,
    required this.filters,
    this.errorCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'mode': mode,
      'resultsCount': resultsCount,
      'timeTaken': timeTaken,
      'timestamp': timestamp.toIso8601String(),
      'filters': filters.toQueryParams(),
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  bool get isSuccessful => errorCode == null;
  bool get hasResults => resultsCount > 0;
}