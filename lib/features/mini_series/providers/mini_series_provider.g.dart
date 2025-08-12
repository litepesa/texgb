// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mini_series_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSeriesHash() => r'a8b9c7d4e5f6a1b2c3d4e5f6a7b8c9d0e1f2a3b4';

/// See also [userSeries].
@ProviderFor(userSeries)
final userSeriesProvider = AutoDisposeProvider<List<MiniSeriesModel>>.internal(
  userSeries,
  name: r'userSeriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userSeriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserSeriesRef = AutoDisposeProviderRef<List<MiniSeriesModel>>;
String _$currentSeriesHash() => r'b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0';

/// See also [currentSeries].
@ProviderFor(currentSeries)
final currentSeriesProvider = AutoDisposeProvider<MiniSeriesModel?>.internal(
  currentSeries,
  name: r'currentSeriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSeriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentSeriesRef = AutoDisposeProviderRef<MiniSeriesModel?>;
String _$seriesEpisodesHash() => r'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

/// See also [seriesEpisodes].
@ProviderFor(seriesEpisodes)
final seriesEpisodesProvider = AutoDisposeProvider<List<EpisodeModel>>.internal(
  seriesEpisodes,
  name: r'seriesEpisodesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seriesEpisodesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SeriesEpisodesRef = AutoDisposeProviderRef<List<EpisodeModel>>;
String _$currentEpisodeHash() => r'd2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1';

/// See also [currentEpisode].
@ProviderFor(currentEpisode)
final currentEpisodeProvider = AutoDisposeProvider<EpisodeModel?>.internal(
  currentEpisode,
  name: r'currentEpisodeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentEpisodeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentEpisodeRef = AutoDisposeProviderRef<EpisodeModel?>;
String _$episodeCommentsHash() => r'e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2';

/// See also [episodeComments].
@ProviderFor(episodeComments)
final episodeCommentsProvider = AutoDisposeProvider<List<EpisodeCommentModel>>.internal(
  episodeComments,
  name: r'episodeCommentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$episodeCommentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EpisodeCommentsRef = AutoDisposeProviderRef<List<EpisodeCommentModel>>;
String _$seriesAnalyticsHash() => r'f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3';

/// See also [seriesAnalytics].
@ProviderFor(seriesAnalytics)
final seriesAnalyticsProvider = AutoDisposeProvider<SeriesAnalyticsModel?>.internal(
  seriesAnalytics,
  name: r'seriesAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seriesAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SeriesAnalyticsRef = AutoDisposeProviderRef<SeriesAnalyticsModel?>;
String _$seriesCategoriesHash() => r'a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4';

/// See also [seriesCategories].
@ProviderFor(seriesCategories)
final seriesCategoriesProvider = AutoDisposeProvider<List<String>>.internal(
  seriesCategories,
  name: r'seriesCategoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$seriesCategoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SeriesCategoriesRef = AutoDisposeProviderRef<List<String>>;
String _$miniSeriesHash() => r'b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5';

/// See also [MiniSeries].
@ProviderFor(MiniSeries)
final miniSeriesProvider = AutoDisposeAsyncNotifierProvider<MiniSeries,
    MiniSeriesState>.internal(
  MiniSeries.new,
  name: r'miniSeriesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$miniSeriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MiniSeries = AutoDisposeAsyncNotifier<MiniSeriesState>;
String _$seriesSearchHash() => r'c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$SeriesSearch extends BuildlessAutoDisposeAsyncNotifier<List<MiniSeriesModel>> {
  late final String query;

  FutureOr<List<MiniSeriesModel>> build(
    String query,
  );
}

/// See also [SeriesSearch].
@ProviderFor(SeriesSearch)
const seriesSearchProvider = SeriesSearchFamily();

/// See also [SeriesSearch].
class SeriesSearchFamily extends Family<AsyncValue<List<MiniSeriesModel>>> {
  /// See also [SeriesSearch].
  const SeriesSearchFamily();

  /// See also [SeriesSearch].
  SeriesSearchProvider call(
    String query,
  ) {
    return SeriesSearchProvider(
      query,
    );
  }

  @override
  SeriesSearchProvider getProviderOverride(
    covariant SeriesSearchProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'seriesSearchProvider';
}

/// See also [SeriesSearch].
class SeriesSearchProvider extends AutoDisposeAsyncNotifierProviderImpl<
    SeriesSearch, List<MiniSeriesModel>> {
  /// See also [SeriesSearch].
  SeriesSearchProvider(
    String query,
  ) : this._internal(
          () => SeriesSearch()..query = query,
          from: seriesSearchProvider,
          name: r'seriesSearchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$seriesSearchHash,
          dependencies: SeriesSearchFamily._dependencies,
          allTransitiveDependencies:
              SeriesSearchFamily._allTransitiveDependencies,
          query: query,
        );

  SeriesSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  FutureOr<List<MiniSeriesModel>> runNotifierBuild(
    covariant SeriesSearch notifier,
  ) {
    return notifier.build(
      query,
    );
  }

  @override
  Override overrideWith(SeriesSearch Function() create) {
    return ProviderOverride(
      origin: this,
      override: SeriesSearchProvider._internal(
        () => create()..query = query,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<SeriesSearch, List<MiniSeriesModel>>
      createElement() {
    return _SeriesSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SeriesSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SeriesSearchRef on AutoDisposeAsyncNotifierProviderRef<List<MiniSeriesModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SeriesSearchProviderElement extends AutoDisposeAsyncNotifierProviderElement<
    SeriesSearch, List<MiniSeriesModel>> with SeriesSearchRef {
  _SeriesSearchProviderElement(super.provider);

  @override
  String get query => (origin as SeriesSearchProvider).query;
}

String _$featuredSeriesHash() => r'd8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7';

/// See also [FeaturedSeries].
@ProviderFor(FeaturedSeries)
final featuredSeriesProvider = AutoDisposeAsyncNotifierProvider<FeaturedSeries,
    List<MiniSeriesModel>>.internal(
  FeaturedSeries.new,
  name: r'featuredSeriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredSeriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeaturedSeries = AutoDisposeAsyncNotifier<List<MiniSeriesModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package