// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$videoSearchRepositoryHash() =>
    r'ec96cea89a1315569c3dde03d6f3ceaf20e958c2';

/// See also [videoSearchRepository].
@ProviderFor(videoSearchRepository)
final videoSearchRepositoryProvider =
    AutoDisposeProvider<VideoSearchRepository>.internal(
  videoSearchRepository,
  name: r'videoSearchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoSearchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoSearchRepositoryRef
    = AutoDisposeProviderRef<VideoSearchRepository>;
String _$searchStateHash() => r'139371b649948747276c5c201103dd99be198217';

/// Current search state
///
/// Copied from [searchState].
@ProviderFor(searchState)
final searchStateProvider = AutoDisposeProvider<VideoSearchState>.internal(
  searchState,
  name: r'searchStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchStateRef = AutoDisposeProviderRef<VideoSearchState>;
String _$isSearchLoadingHash() => r'18ccf1674dc662b48121d9765f2cd6e3e947b869';

/// Whether search is currently loading
///
/// Copied from [isSearchLoading].
@ProviderFor(isSearchLoading)
final isSearchLoadingProvider = AutoDisposeProvider<bool>.internal(
  isSearchLoading,
  name: r'isSearchLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSearchLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSearchLoadingRef = AutoDisposeProviderRef<bool>;
String _$searchResultsHash() => r'348f6836843c9e9829764d50dbd43a26deb880a5';

/// Current search results
///
/// Copied from [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider =
    AutoDisposeProvider<List<VideoSearchResult>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsRef = AutoDisposeProviderRef<List<VideoSearchResult>>;
String _$searchQueryHash() => r'117c96b38854da6bb19d082aa5c3d15b6f0a55b8';

/// Current search query
///
/// Copied from [searchQuery].
@ProviderFor(searchQuery)
final searchQueryProvider = AutoDisposeProvider<String>.internal(
  searchQuery,
  name: r'searchQueryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchQueryRef = AutoDisposeProviderRef<String>;
String _$searchSuggestionsHash() => r'c3052dc6b5bb140888dd3613393d9f6b3c705079';

/// Search suggestions for autocomplete
///
/// Copied from [searchSuggestions].
@ProviderFor(searchSuggestions)
final searchSuggestionsProvider = AutoDisposeProvider<List<String>>.internal(
  searchSuggestions,
  name: r'searchSuggestionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchSuggestionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchSuggestionsRef = AutoDisposeProviderRef<List<String>>;
String _$recentSearchesHash() => r'14b3843713361913723e8e2777d0c0aff04aee09';

/// Recent search history
///
/// Copied from [recentSearches].
@ProviderFor(recentSearches)
final recentSearchesProvider = AutoDisposeProvider<List<String>>.internal(
  recentSearches,
  name: r'recentSearchesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentSearchesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentSearchesRef = AutoDisposeProviderRef<List<String>>;
String _$trendingTermsHash() => r'28ac1eb8f7c329554c69ea18b5ae08376b347abf';

/// Trending search terms
///
/// Copied from [trendingTerms].
@ProviderFor(trendingTerms)
final trendingTermsProvider = AutoDisposeProvider<List<String>>.internal(
  trendingTerms,
  name: r'trendingTermsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingTermsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrendingTermsRef = AutoDisposeProviderRef<List<String>>;
String _$searchFiltersHash() => r'b5a3e8a13d805f3a77022e2ed719700a47d6e74f';

/// Current search filters
///
/// Copied from [searchFilters].
@ProviderFor(searchFilters)
final searchFiltersProvider = AutoDisposeProvider<SearchFilters>.internal(
  searchFilters,
  name: r'searchFiltersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchFiltersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchFiltersRef = AutoDisposeProviderRef<SearchFilters>;
String _$canLoadMoreResultsHash() =>
    r'41f2b69a77e2c42b486d9f0dc4d7b0ace2000c26';

/// Whether there are more results to load
///
/// Copied from [canLoadMoreResults].
@ProviderFor(canLoadMoreResults)
final canLoadMoreResultsProvider = AutoDisposeProvider<bool>.internal(
  canLoadMoreResults,
  name: r'canLoadMoreResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canLoadMoreResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanLoadMoreResultsRef = AutoDisposeProviderRef<bool>;
String _$searchErrorHash() => r'eb988949ca8c3124b3bb5451513f15fc6478ac66';

/// Search error message
///
/// Copied from [searchError].
@ProviderFor(searchError)
final searchErrorProvider = AutoDisposeProvider<String?>.internal(
  searchError,
  name: r'searchErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchErrorRef = AutoDisposeProviderRef<String?>;
String _$hasSearchResultsHash() => r'4cbe45521ce9353e1e138b6d156c155d1c7b76f6';

/// Whether search has results
///
/// Copied from [hasSearchResults].
@ProviderFor(hasSearchResults)
final hasSearchResultsProvider = AutoDisposeProvider<bool>.internal(
  hasSearchResults,
  name: r'hasSearchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasSearchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasSearchResultsRef = AutoDisposeProviderRef<bool>;
String _$searchResultsCountHash() =>
    r'85495bb84019373834146fb49fcf68b9fce10fad';

/// Search results count
///
/// Copied from [searchResultsCount].
@ProviderFor(searchResultsCount)
final searchResultsCountProvider = AutoDisposeProvider<int>.internal(
  searchResultsCount,
  name: r'searchResultsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchResultsCountRef = AutoDisposeProviderRef<int>;
String _$searchTimeTakenHash() => r'3c08fc6b2a9bb46793d35fe601013b55d7f7fb2f';

/// Search time taken
///
/// Copied from [searchTimeTaken].
@ProviderFor(searchTimeTaken)
final searchTimeTakenProvider = AutoDisposeProvider<String>.internal(
  searchTimeTaken,
  name: r'searchTimeTakenProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchTimeTakenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchTimeTakenRef = AutoDisposeProviderRef<String>;
String _$videoSearchHash() => r'3ba5f4b5553d681ae367a84b826bd8f8a4a80e25';

/// See also [VideoSearch].
@ProviderFor(VideoSearch)
final videoSearchProvider =
    AutoDisposeNotifierProvider<VideoSearch, VideoSearchState>.internal(
  VideoSearch.new,
  name: r'videoSearchProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoSearch = AutoDisposeNotifier<VideoSearchState>;
String _$searchControllerHash() => r'5eb7999bf318d22389fc348b59d2172c40017dbc';

/// Search controller for managing search operations
///
/// Copied from [SearchController].
@ProviderFor(SearchController)
final searchControllerProvider =
    AutoDisposeNotifierProvider<SearchController, void>.internal(
  SearchController.new,
  name: r'searchControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchController = AutoDisposeNotifier<void>;
String _$searchAnalyticsHash() => r'320d945d0aed5ddfbb502c4935b1c63c5f88db35';

/// Track search analytics for optimization
///
/// Copied from [SearchAnalytics].
@ProviderFor(SearchAnalytics)
final searchAnalyticsProvider =
    AutoDisposeNotifierProvider<SearchAnalytics, Map<String, dynamic>>.internal(
  SearchAnalytics.new,
  name: r'searchAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchAnalytics = AutoDisposeNotifier<Map<String, dynamic>>;
String _$searchCacheHash() => r'31ed6dea869ed4a071eef89dd46ab6e3bbd2ef00';

/// Simple in-memory cache for search results
///
/// Copied from [SearchCache].
@ProviderFor(SearchCache)
final searchCacheProvider = AutoDisposeNotifierProvider<SearchCache,
    Map<String, VideoSearchResponse>>.internal(
  SearchCache.new,
  name: r'searchCacheProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchCache = AutoDisposeNotifier<Map<String, VideoSearchResponse>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
