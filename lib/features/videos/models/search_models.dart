// ===============================
// lib/features/videos/models/search_models.dart
// Search Models for Video Search Functionality
// Compatible with Backend Search API
// ===============================

import 'package:textgb/features/videos/models/video_model.dart';

// ===============================
// SEARCH STATE MANAGEMENT
// ===============================

enum SearchStatus {
  initial,
  loading,
  success,
  error,
  empty,
}

class VideoSearchState {
  final SearchStatus status;
  final String query;
  final List<VideoSearchResult> results;
  final List<String> suggestions;
  final List<String> recentSearches;
  final List<String> trendingTerms;
  final SearchFilters filters;
  final String? errorMessage;
  final bool hasMore;
  final int totalResults;
  final int currentPage;
  final String searchMode;
  final int timeTaken; // milliseconds
  
  const VideoSearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.suggestions = const [],
    this.recentSearches = const [],
    this.trendingTerms = const [],
    this.filters = const SearchFilters(),
    this.errorMessage,
    this.hasMore = false,
    this.totalResults = 0,
    this.currentPage = 0,
    this.searchMode = 'combined',
    this.timeTaken = 0,
  });

  VideoSearchState copyWith({
    SearchStatus? status,
    String? query,
    List<VideoSearchResult>? results,
    List<String>? suggestions,
    List<String>? recentSearches,
    List<String>? trendingTerms,
    SearchFilters? filters,
    String? errorMessage,
    bool? hasMore,
    int? totalResults,
    int? currentPage,
    String? searchMode,
    int? timeTaken,
  }) {
    return VideoSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      recentSearches: recentSearches ?? this.recentSearches,
      trendingTerms: trendingTerms ?? this.trendingTerms,
      filters: filters ?? this.filters,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      totalResults: totalResults ?? this.totalResults,
      currentPage: currentPage ?? this.currentPage,
      searchMode: searchMode ?? this.searchMode,
      timeTaken: timeTaken ?? this.timeTaken,
    );
  }

  // Factory constructors for common states
  factory VideoSearchState.initial() {
    return const VideoSearchState(status: SearchStatus.initial);
  }

  factory VideoSearchState.loading({String query = ''}) {
    return VideoSearchState(
      status: SearchStatus.loading,
      query: query,
    );
  }

  factory VideoSearchState.success({
    required String query,
    required List<VideoSearchResult> results,
    required int totalResults,
    bool hasMore = false,
    int currentPage = 1,
    String searchMode = 'combined',
    int timeTaken = 0,
    SearchFilters? filters,
  }) {
    return VideoSearchState(
      status: SearchStatus.success,
      query: query,
      results: results,
      totalResults: totalResults,
      hasMore: hasMore,
      currentPage: currentPage,
      searchMode: searchMode,
      timeTaken: timeTaken,
      filters: filters ?? const SearchFilters(),
    );
  }

  factory VideoSearchState.error({
    required String errorMessage,
    String query = '',
  }) {
    return VideoSearchState(
      status: SearchStatus.error,
      query: query,
      errorMessage: errorMessage,
    );
  }

  factory VideoSearchState.empty({
    required String query,
    List<String>? suggestions,
  }) {
    return VideoSearchState(
      status: SearchStatus.empty,
      query: query,
      suggestions: suggestions ?? [],
    );
  }

  // Helper getters
  bool get isLoading => status == SearchStatus.loading;
  bool get isSuccess => status == SearchStatus.success;
  bool get isError => status == SearchStatus.error;
  bool get isEmpty => status == SearchStatus.empty;
  bool get isInitial => status == SearchStatus.initial;
  bool get hasResults => results.isNotEmpty;
  bool get hasQuery => query.isNotEmpty;
  bool get canLoadMore => hasMore && !isLoading;

  @override
  String toString() {
    return 'VideoSearchState(status: $status, query: "$query", results: ${results.length}, totalResults: $totalResults)';
  }
}

// ===============================
// SEARCH FILTERS
// ===============================

class SearchFilters {
  final String mediaType; // "video", "image", "all"
  final String timeRange; // "day", "week", "month", "all"
  final String sortBy; // "relevance", "latest", "popular"
  final int minLikes;
  final bool? hasPrice; // Filter by paid/free content
  final bool? isVerified; // Filter by verified content
  final List<String> tags;
  final String? userId; // Search within specific user's content

  const SearchFilters({
    this.mediaType = 'all',
    this.timeRange = 'all',
    this.sortBy = 'relevance',
    this.minLikes = 0,
    this.hasPrice,
    this.isVerified,
    this.tags = const [],
    this.userId,
  });

  SearchFilters copyWith({
    String? mediaType,
    String? timeRange,
    String? sortBy,
    int? minLikes,
    bool? hasPrice,
    bool? isVerified,
    List<String>? tags,
    String? userId,
  }) {
    return SearchFilters(
      mediaType: mediaType ?? this.mediaType,
      timeRange: timeRange ?? this.timeRange,
      sortBy: sortBy ?? this.sortBy,
      minLikes: minLikes ?? this.minLikes,
      hasPrice: hasPrice ?? this.hasPrice,
      isVerified: isVerified ?? this.isVerified,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
    );
  }

  // Convert to API query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'mediaType': mediaType,
      'timeRange': timeRange,
      'sortBy': sortBy,
    };

    if (minLikes > 0) {
      params['minLikes'] = minLikes.toString();
    }

    if (hasPrice != null) {
      params['hasPrice'] = hasPrice.toString();
    }

    if (isVerified != null) {
      params['isVerified'] = isVerified.toString();
    }

    if (tags.isNotEmpty) {
      params['tags'] = tags.join(',');
    }

    if (userId != null && userId!.isNotEmpty) {
      params['userId'] = userId;
    }

    return params;
  }

  // Check if any filters are active (not default)
  bool get hasActiveFilters {
    return mediaType != 'all' ||
           timeRange != 'all' ||
           sortBy != 'relevance' ||
           minLikes > 0 ||
           hasPrice != null ||
           isVerified != null ||
           tags.isNotEmpty ||
           (userId != null && userId!.isNotEmpty);
  }

  // Reset to default filters
  SearchFilters reset() {
    return const SearchFilters();
  }

  @override
  String toString() {
    return 'SearchFilters(mediaType: $mediaType, timeRange: $timeRange, sortBy: $sortBy, hasActiveFilters: $hasActiveFilters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
           other.mediaType == mediaType &&
           other.timeRange == timeRange &&
           other.sortBy == sortBy &&
           other.minLikes == minLikes &&
           other.hasPrice == hasPrice &&
           other.isVerified == isVerified &&
           other.tags.length == tags.length &&
           other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      mediaType,
      timeRange,
      sortBy,
      minLikes,
      hasPrice,
      isVerified,
      tags.length,
      userId,
    );
  }
}

// ===============================
// SEARCH RESULT
// ===============================

class VideoSearchResult {
  final VideoModel video;
  final double relevance; // 0.0 to 1.0
  final String matchType; // "caption", "username", "tag", "fulltext"
  final String? highlightedCaption; // Caption with search terms highlighted
  final String? highlightedUsername; // Username with search terms highlighted

  const VideoSearchResult({
    required this.video,
    required this.relevance,
    required this.matchType,
    this.highlightedCaption,
    this.highlightedUsername,
  });

  factory VideoSearchResult.fromJson(Map<String, dynamic> json) {
    return VideoSearchResult(
      video: VideoModel.fromJson(json['video'] as Map<String, dynamic>),
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
      matchType: json['matchType'] as String? ?? 'unknown',
      highlightedCaption: json['highlightedCaption'] as String?,
      highlightedUsername: json['highlightedUsername'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video': video.toJson(),
      'relevance': relevance,
      'matchType': matchType,
      if (highlightedCaption != null) 'highlightedCaption': highlightedCaption,
      if (highlightedUsername != null) 'highlightedUsername': highlightedUsername,
    };
  }

  // Helper getters
  String get displayCaption => highlightedCaption ?? video.caption;
  String get displayUsername => highlightedUsername ?? video.userName;
  
  bool get isHighRelevance => relevance >= 0.8;
  bool get isMediumRelevance => relevance >= 0.5 && relevance < 0.8;
  bool get isLowRelevance => relevance < 0.5;

  String get relevanceLabel {
    if (isHighRelevance) return 'High match';
    if (isMediumRelevance) return 'Good match';
    return 'Low match';
  }

  // Get match type display text
  String get matchTypeDisplay {
    switch (matchType.toLowerCase()) {
      case 'caption':
        return 'Found in caption';
      case 'username':
        return 'Found in creator name';
      case 'tag':
        return 'Found in tags';
      case 'fulltext':
        return 'Text match';
      default:
        return 'Match found';
    }
  }

  @override
  String toString() {
    return 'VideoSearchResult(videoId: ${video.id}, relevance: ${relevance.toStringAsFixed(2)}, matchType: $matchType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoSearchResult && other.video.id == video.id;
  }

  @override
  int get hashCode => video.id.hashCode;
}

// ===============================
// SEARCH SUGGESTION
// ===============================

class SearchSuggestion {
  final String text;
  final String type; // "recent", "trending", "suggestion", "completion"
  final int? frequency; // For trending terms
  final String? matchType; // For completions: "caption", "username"

  const SearchSuggestion({
    required this.text,
    required this.type,
    this.frequency,
    this.matchType,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'suggestion',
      frequency: json['frequency'] as int?,
      matchType: json['matchType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type,
      if (frequency != null) 'frequency': frequency,
      if (matchType != null) 'matchType': matchType,
    };
  }

  // Factory constructors for different types
  factory SearchSuggestion.recent(String text) {
    return SearchSuggestion(text: text, type: 'recent');
  }

  factory SearchSuggestion.trending(String text, int frequency) {
    return SearchSuggestion(
      text: text,
      type: 'trending',
      frequency: frequency,
    );
  }

  factory SearchSuggestion.completion(String text, String matchType) {
    return SearchSuggestion(
      text: text,
      type: 'completion',
      matchType: matchType,
    );
  }

  // Helper getters
  bool get isRecent => type == 'recent';
  bool get isTrending => type == 'trending';
  bool get isCompletion => type == 'completion';
  bool get isSuggestion => type == 'suggestion';

  String get displayFrequency {
    if (frequency == null) return '';
    if (frequency! >= 1000000) {
      return '${(frequency! / 1000000).toStringAsFixed(1)}M searches';
    } else if (frequency! >= 1000) {
      return '${(frequency! / 1000).toStringAsFixed(1)}K searches';
    }
    return '$frequency searches';
  }

  String get typeDisplay {
    switch (type) {
      case 'recent':
        return 'Recent search';
      case 'trending':
        return 'Trending';
      case 'completion':
        return 'Suggestion';
      case 'suggestion':
        return 'Popular';
      default:
        return '';
    }
  }

  @override
  String toString() {
    return 'SearchSuggestion(text: "$text", type: $type${frequency != null ? ', frequency: $frequency' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSuggestion && 
           other.text == text && 
           other.type == type;
  }

  @override
  int get hashCode => Object.hash(text, type);
}

// ===============================
// SEARCH REQUEST
// ===============================

class VideoSearchRequest {
  final String query;
  final SearchFilters filters;
  final String mode; // "exact", "fuzzy", "fulltext", "combined"
  final int limit;
  final int offset;
  final bool includeRelevance;

  const VideoSearchRequest({
    required this.query,
    this.filters = const SearchFilters(),
    this.mode = 'combined',
    this.limit = 20,
    this.offset = 0,
    this.includeRelevance = true,
  });

  VideoSearchRequest copyWith({
    String? query,
    SearchFilters? filters,
    String? mode,
    int? limit,
    int? offset,
    bool? includeRelevance,
  }) {
    return VideoSearchRequest(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      mode: mode ?? this.mode,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      includeRelevance: includeRelevance ?? this.includeRelevance,
    );
  }

  // Convert to API query parameters
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'q': query,
      'mode': mode,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (includeRelevance) {
      params['includeRelevance'] = 'true';
    }

    // Add filter parameters
    params.addAll(filters.toQueryParams());

    return params;
  }

  // For pagination
  VideoSearchRequest nextPage() {
    return copyWith(offset: offset + limit);
  }

  VideoSearchRequest firstPage() {
    return copyWith(offset: 0);
  }

  @override
  String toString() {
    return 'VideoSearchRequest(query: "$query", mode: $mode, limit: $limit, offset: $offset)';
  }
}

// ===============================
// SEARCH RESPONSE
// ===============================

class VideoSearchResponse {
  final List<VideoSearchResult> results;
  final int total;
  final String query;
  final String searchMode;
  final int timeTaken; // milliseconds
  final List<String> suggestions;
  final int page;
  final bool hasMore;
  final SearchFilters filters;

  const VideoSearchResponse({
    required this.results,
    required this.total,
    required this.query,
    required this.searchMode,
    required this.timeTaken,
    this.suggestions = const [],
    required this.page,
    required this.hasMore,
    required this.filters,
  });

  factory VideoSearchResponse.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    final results = resultsJson
        .map((result) => VideoSearchResult.fromJson(result as Map<String, dynamic>))
        .toList();

    final suggestionsJson = json['suggestions'] as List<dynamic>? ?? [];
    final suggestions = suggestionsJson.map((s) => s.toString()).toList();

    return VideoSearchResponse(
      results: results,
      total: json['total'] as int? ?? 0,
      query: json['query'] as String? ?? '',
      searchMode: json['searchMode'] as String? ?? 'combined',
      timeTaken: json['timeTaken'] as int? ?? 0,
      suggestions: suggestions,
      page: json['page'] as int? ?? 1,
      hasMore: json['hasMore'] as bool? ?? false,
      filters: const SearchFilters(), // Will be set by the caller
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((r) => r.toJson()).toList(),
      'total': total,
      'query': query,
      'searchMode': searchMode,
      'timeTaken': timeTaken,
      'suggestions': suggestions,
      'page': page,
      'hasMore': hasMore,
    };
  }

  // Helper getters
  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get resultsCount => results.length;
  
  String get timeTakenDisplay {
    if (timeTaken < 1000) {
      return '${timeTaken}ms';
    } else {
      return '${(timeTaken / 1000).toStringAsFixed(1)}s';
    }
  }

  String get resultsCountDisplay {
    if (total == 0) return 'No results';
    if (total == 1) return '1 result';
    if (total < 1000) return '$total results';
    if (total < 1000000) {
      return '${(total / 1000).toStringAsFixed(1)}K results';
    }
    return '${(total / 1000000).toStringAsFixed(1)}M results';
  }

  // Get results grouped by relevance
  Map<String, List<VideoSearchResult>> get resultsByRelevance {
    final grouped = <String, List<VideoSearchResult>>{
      'high': [],
      'medium': [],
      'low': [],
    };

    for (final result in results) {
      if (result.isHighRelevance) {
        grouped['high']!.add(result);
      } else if (result.isMediumRelevance) {
        grouped['medium']!.add(result);
      } else {
        grouped['low']!.add(result);
      }
    }

    return grouped;
  }

  // Get results grouped by match type
  Map<String, List<VideoSearchResult>> get resultsByMatchType {
    final grouped = <String, List<VideoSearchResult>>{};

    for (final result in results) {
      final matchType = result.matchType;
      if (!grouped.containsKey(matchType)) {
        grouped[matchType] = [];
      }
      grouped[matchType]!.add(result);
    }

    return grouped;
  }

  @override
  String toString() {
    return 'VideoSearchResponse(query: "$query", results: ${results.length}, total: $total, timeTaken: ${timeTakenDisplay})';
  }
}

// ===============================
// SEARCH HISTORY ITEM
// ===============================

class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final int resultsCount;
  final SearchFilters? filters;

  const SearchHistoryItem({
    required this.query,
    required this.timestamp,
    this.resultsCount = 0,
    this.filters,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultsCount: json['resultsCount'] as int? ?? 0,
      filters: json['filters'] != null 
          ? SearchFilters() // Would need to implement SearchFilters.fromJson
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultsCount': resultsCount,
      if (filters != null) 'filters': filters!.toQueryParams(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'SearchHistoryItem(query: "$query", timestamp: $timestamp, resultsCount: $resultsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistoryItem && other.query == query;
  }

  @override
  int get hashCode => query.hashCode;
}

// ===============================
// SEARCH CONSTANTS
// ===============================

class SearchConstants {
  // Search modes
  static const String modeExact = 'exact';
  static const String modeFuzzy = 'fuzzy';
  static const String modeFullText = 'fulltext';
  static const String modeCombined = 'combined';

  // Media types
  static const String mediaTypeAll = 'all';
  static const String mediaTypeVideo = 'video';
  static const String mediaTypeImage = 'image';

  // Time ranges
  static const String timeRangeAll = 'all';
  static const String timeRangeDay = 'day';
  static const String timeRangeWeek = 'week';
  static const String timeRangeMonth = 'month';

  // Sort options
  static const String sortByRelevance = 'relevance';
  static const String sortByLatest = 'latest';
  static const String sortByPopular = 'popular';

  // Suggestion types
  static const String suggestionTypeRecent = 'recent';
  static const String suggestionTypeTrending = 'trending';
  static const String suggestionTypeCompletion = 'completion';

  // Search limits
  static const int maxSearchHistoryItems = 20;
  static const int maxSuggestions = 10;
  static const int maxResultsPerPage = 50;
  static const int defaultResultsPerPage = 20;
  static const int searchDebounceMs = 500;
  static const int minSearchQueryLength = 2;
  static const int maxSearchQueryLength = 100;
}