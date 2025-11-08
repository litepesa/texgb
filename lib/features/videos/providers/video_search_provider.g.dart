// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchRepositoryHash() => r'81c46de47f05f6c8c271b0794accb5ee4c54c213';

/// See also [searchRepository].
@ProviderFor(searchRepository)
final searchRepositoryProvider =
    AutoDisposeProvider<VideoSearchRepository>.internal(
  searchRepository,
  name: r'searchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchRepositoryRef = AutoDisposeProviderRef<VideoSearchRepository>;
String _$searchStateHash() => r'66d975e4da769d105d47a9c8f5aee37d56230de9';

/// Current search state
///
/// Copied from [searchState].
@ProviderFor(searchState)
final searchStateProvider = AutoDisposeProvider<SimpleSearchState>.internal(
  searchState,
  name: r'searchStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$searchStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SearchStateRef = AutoDisposeProviderRef<SimpleSearchState>;
String _$searchResultsHash() => r'49317597ed3bf872f61290af90699db050183392';

/// Search results (list of videos)
///
/// Copied from [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider = AutoDisposeProvider<List<VideoModel>>.internal(
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
typedef SearchResultsRef = AutoDisposeProviderRef<List<VideoModel>>;
String _$isSearchingHash() => r'cb4b6baed3746602c0d80cc0082e2bdbb9ba21af';

/// Is currently searching
///
/// Copied from [isSearching].
@ProviderFor(isSearching)
final isSearchingProvider = AutoDisposeProvider<bool>.internal(
  isSearching,
  name: r'isSearchingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isSearchingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSearchingRef = AutoDisposeProviderRef<bool>;
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

/// Has search results
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
String _$isUsernameOnlyActiveHash() =>
    r'3fd0e66d41fbc0d98e645b753d9746852bd5a8c3';

/// Username-only filter active
///
/// Copied from [isUsernameOnlyActive].
@ProviderFor(isUsernameOnlyActive)
final isUsernameOnlyActiveProvider = AutoDisposeProvider<bool>.internal(
  isUsernameOnlyActive,
  name: r'isUsernameOnlyActiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isUsernameOnlyActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsUsernameOnlyActiveRef = AutoDisposeProviderRef<bool>;
String _$hasMoreResultsHash() => r'69deb511e3d441658e6305d513b432d421a09f69';

/// Has more results to load
///
/// Copied from [hasMoreResults].
@ProviderFor(hasMoreResults)
final hasMoreResultsProvider = AutoDisposeProvider<bool>.internal(
  hasMoreResults,
  name: r'hasMoreResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasMoreResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasMoreResultsRef = AutoDisposeProviderRef<bool>;
String _$totalResultsCountHash() => r'fc552d4018bd4372e0529725e4373661c10fd537';

/// Total results count
///
/// Copied from [totalResultsCount].
@ProviderFor(totalResultsCount)
final totalResultsCountProvider = AutoDisposeProvider<int>.internal(
  totalResultsCount,
  name: r'totalResultsCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalResultsCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalResultsCountRef = AutoDisposeProviderRef<int>;
String _$resultsCountTextHash() => r'ce7ccbaa73f3fa9bff74bcc69a24268431cf3e5a';

/// Results count display text
///
/// Copied from [resultsCountText].
@ProviderFor(resultsCountText)
final resultsCountTextProvider = AutoDisposeProvider<String>.internal(
  resultsCountText,
  name: r'resultsCountTextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resultsCountTextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResultsCountTextRef = AutoDisposeProviderRef<String>;
String _$videoSearchHash() => r'71743da8daa40094323f4cdae1976f8276dfc8e4';

/// See also [VideoSearch].
@ProviderFor(VideoSearch)
final videoSearchProvider =
    AutoDisposeNotifierProvider<VideoSearch, SimpleSearchState>.internal(
  VideoSearch.new,
  name: r'videoSearchProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoSearch = AutoDisposeNotifier<SimpleSearchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
