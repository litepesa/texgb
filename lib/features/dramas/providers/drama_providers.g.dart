// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dramaRepositoryHash() => r'a987438ec4f04aad87ddabf29102ed25a3ac686a';

/// See also [dramaRepository].
@ProviderFor(dramaRepository)
final dramaRepositoryProvider = AutoDisposeProvider<DramaRepository>.internal(
  dramaRepository,
  name: r'dramaRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dramaRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DramaRepositoryRef = AutoDisposeProviderRef<DramaRepository>;
String _$episodeHash() => r'bcb09727e8153f5d487d6c0c7800944b69cb1798';

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

/// See also [episode].
@ProviderFor(episode)
const episodeProvider = EpisodeFamily();

/// See also [episode].
class EpisodeFamily extends Family<AsyncValue<EpisodeModel?>> {
  /// See also [episode].
  const EpisodeFamily();

  /// See also [episode].
  EpisodeProvider call(
    String episodeId,
  ) {
    return EpisodeProvider(
      episodeId,
    );
  }

  @override
  EpisodeProvider getProviderOverride(
    covariant EpisodeProvider provider,
  ) {
    return call(
      provider.episodeId,
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
  String? get name => r'episodeProvider';
}

/// See also [episode].
class EpisodeProvider extends AutoDisposeFutureProvider<EpisodeModel?> {
  /// See also [episode].
  EpisodeProvider(
    String episodeId,
  ) : this._internal(
          (ref) => episode(
            ref as EpisodeRef,
            episodeId,
          ),
          from: episodeProvider,
          name: r'episodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$episodeHash,
          dependencies: EpisodeFamily._dependencies,
          allTransitiveDependencies: EpisodeFamily._allTransitiveDependencies,
          episodeId: episodeId,
        );

  EpisodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.episodeId,
  }) : super.internal();

  final String episodeId;

  @override
  Override overrideWith(
    FutureOr<EpisodeModel?> Function(EpisodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EpisodeProvider._internal(
        (ref) => create(ref as EpisodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        episodeId: episodeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<EpisodeModel?> createElement() {
    return _EpisodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeProvider && other.episodeId == episodeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, episodeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EpisodeRef on AutoDisposeFutureProviderRef<EpisodeModel?> {
  /// The parameter `episodeId` of this provider.
  String get episodeId;
}

class _EpisodeProviderElement
    extends AutoDisposeFutureProviderElement<EpisodeModel?> with EpisodeRef {
  _EpisodeProviderElement(super.provider);

  @override
  String get episodeId => (origin as EpisodeProvider).episodeId;
}

String _$userFavoriteDramasHash() =>
    r'929e17bf48df3b00d8d3192f5054f97228ddc15f';

/// See also [userFavoriteDramas].
@ProviderFor(userFavoriteDramas)
final userFavoriteDramasProvider =
    AutoDisposeFutureProvider<List<DramaModel>>.internal(
  userFavoriteDramas,
  name: r'userFavoriteDramasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userFavoriteDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserFavoriteDramasRef = AutoDisposeFutureProviderRef<List<DramaModel>>;
String _$continueWatchingDramasHash() =>
    r'70036f6daff37b6e231728665c7b4b3c57cb8fb2';

/// See also [continueWatchingDramas].
@ProviderFor(continueWatchingDramas)
final continueWatchingDramasProvider =
    AutoDisposeFutureProvider<List<DramaModel>>.internal(
  continueWatchingDramas,
  name: r'continueWatchingDramasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$continueWatchingDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ContinueWatchingDramasRef
    = AutoDisposeFutureProviderRef<List<DramaModel>>;
String _$isDramaFavoritedHash() => r'04047cfb8f5ac801b2bc45ae15f4669cc8de1829';

/// See also [isDramaFavorited].
@ProviderFor(isDramaFavorited)
const isDramaFavoritedProvider = IsDramaFavoritedFamily();

/// See also [isDramaFavorited].
class IsDramaFavoritedFamily extends Family<bool> {
  /// See also [isDramaFavorited].
  const IsDramaFavoritedFamily();

  /// See also [isDramaFavorited].
  IsDramaFavoritedProvider call(
    String dramaId,
  ) {
    return IsDramaFavoritedProvider(
      dramaId,
    );
  }

  @override
  IsDramaFavoritedProvider getProviderOverride(
    covariant IsDramaFavoritedProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'isDramaFavoritedProvider';
}

/// See also [isDramaFavorited].
class IsDramaFavoritedProvider extends AutoDisposeProvider<bool> {
  /// See also [isDramaFavorited].
  IsDramaFavoritedProvider(
    String dramaId,
  ) : this._internal(
          (ref) => isDramaFavorited(
            ref as IsDramaFavoritedRef,
            dramaId,
          ),
          from: isDramaFavoritedProvider,
          name: r'isDramaFavoritedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isDramaFavoritedHash,
          dependencies: IsDramaFavoritedFamily._dependencies,
          allTransitiveDependencies:
              IsDramaFavoritedFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  IsDramaFavoritedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    bool Function(IsDramaFavoritedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsDramaFavoritedProvider._internal(
        (ref) => create(ref as IsDramaFavoritedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsDramaFavoritedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsDramaFavoritedProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsDramaFavoritedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _IsDramaFavoritedProviderElement extends AutoDisposeProviderElement<bool>
    with IsDramaFavoritedRef {
  _IsDramaFavoritedProviderElement(super.provider);

  @override
  String get dramaId => (origin as IsDramaFavoritedProvider).dramaId;
}

String _$isDramaUnlockedHash() => r'aaee204a53c77d31ed54796944bd04d7e796b1b1';

/// See also [isDramaUnlocked].
@ProviderFor(isDramaUnlocked)
const isDramaUnlockedProvider = IsDramaUnlockedFamily();

/// See also [isDramaUnlocked].
class IsDramaUnlockedFamily extends Family<bool> {
  /// See also [isDramaUnlocked].
  const IsDramaUnlockedFamily();

  /// See also [isDramaUnlocked].
  IsDramaUnlockedProvider call(
    String dramaId,
  ) {
    return IsDramaUnlockedProvider(
      dramaId,
    );
  }

  @override
  IsDramaUnlockedProvider getProviderOverride(
    covariant IsDramaUnlockedProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'isDramaUnlockedProvider';
}

/// See also [isDramaUnlocked].
class IsDramaUnlockedProvider extends AutoDisposeProvider<bool> {
  /// See also [isDramaUnlocked].
  IsDramaUnlockedProvider(
    String dramaId,
  ) : this._internal(
          (ref) => isDramaUnlocked(
            ref as IsDramaUnlockedRef,
            dramaId,
          ),
          from: isDramaUnlockedProvider,
          name: r'isDramaUnlockedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isDramaUnlockedHash,
          dependencies: IsDramaUnlockedFamily._dependencies,
          allTransitiveDependencies:
              IsDramaUnlockedFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  IsDramaUnlockedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    bool Function(IsDramaUnlockedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsDramaUnlockedProvider._internal(
        (ref) => create(ref as IsDramaUnlockedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsDramaUnlockedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsDramaUnlockedProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsDramaUnlockedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _IsDramaUnlockedProviderElement extends AutoDisposeProviderElement<bool>
    with IsDramaUnlockedRef {
  _IsDramaUnlockedProviderElement(super.provider);

  @override
  String get dramaId => (origin as IsDramaUnlockedProvider).dramaId;
}

String _$dramaUserProgressHash() => r'e6f273666e092bc2416ed89f0fff8e8b8dd81248';

/// See also [dramaUserProgress].
@ProviderFor(dramaUserProgress)
const dramaUserProgressProvider = DramaUserProgressFamily();

/// See also [dramaUserProgress].
class DramaUserProgressFamily extends Family<int> {
  /// See also [dramaUserProgress].
  const DramaUserProgressFamily();

  /// See also [dramaUserProgress].
  DramaUserProgressProvider call(
    String dramaId,
  ) {
    return DramaUserProgressProvider(
      dramaId,
    );
  }

  @override
  DramaUserProgressProvider getProviderOverride(
    covariant DramaUserProgressProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'dramaUserProgressProvider';
}

/// See also [dramaUserProgress].
class DramaUserProgressProvider extends AutoDisposeProvider<int> {
  /// See also [dramaUserProgress].
  DramaUserProgressProvider(
    String dramaId,
  ) : this._internal(
          (ref) => dramaUserProgress(
            ref as DramaUserProgressRef,
            dramaId,
          ),
          from: dramaUserProgressProvider,
          name: r'dramaUserProgressProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaUserProgressHash,
          dependencies: DramaUserProgressFamily._dependencies,
          allTransitiveDependencies:
              DramaUserProgressFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaUserProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    int Function(DramaUserProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaUserProgressProvider._internal(
        (ref) => create(ref as DramaUserProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _DramaUserProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaUserProgressProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaUserProgressRef on AutoDisposeProviderRef<int> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaUserProgressProviderElement extends AutoDisposeProviderElement<int>
    with DramaUserProgressRef {
  _DramaUserProgressProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaUserProgressProvider).dramaId;
}

String _$canWatchEpisodeHash() => r'8fc76cac3068998c88f43fd823795b292017d11f';

/// See also [canWatchEpisode].
@ProviderFor(canWatchEpisode)
const canWatchEpisodeProvider = CanWatchEpisodeFamily();

/// See also [canWatchEpisode].
class CanWatchEpisodeFamily extends Family<bool> {
  /// See also [canWatchEpisode].
  const CanWatchEpisodeFamily();

  /// See also [canWatchEpisode].
  CanWatchEpisodeProvider call(
    String dramaId,
    int episodeNumber,
  ) {
    return CanWatchEpisodeProvider(
      dramaId,
      episodeNumber,
    );
  }

  @override
  CanWatchEpisodeProvider getProviderOverride(
    covariant CanWatchEpisodeProvider provider,
  ) {
    return call(
      provider.dramaId,
      provider.episodeNumber,
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
  String? get name => r'canWatchEpisodeProvider';
}

/// See also [canWatchEpisode].
class CanWatchEpisodeProvider extends AutoDisposeProvider<bool> {
  /// See also [canWatchEpisode].
  CanWatchEpisodeProvider(
    String dramaId,
    int episodeNumber,
  ) : this._internal(
          (ref) => canWatchEpisode(
            ref as CanWatchEpisodeRef,
            dramaId,
            episodeNumber,
          ),
          from: canWatchEpisodeProvider,
          name: r'canWatchEpisodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canWatchEpisodeHash,
          dependencies: CanWatchEpisodeFamily._dependencies,
          allTransitiveDependencies:
              CanWatchEpisodeFamily._allTransitiveDependencies,
          dramaId: dramaId,
          episodeNumber: episodeNumber,
        );

  CanWatchEpisodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
    required this.episodeNumber,
  }) : super.internal();

  final String dramaId;
  final int episodeNumber;

  @override
  Override overrideWith(
    bool Function(CanWatchEpisodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanWatchEpisodeProvider._internal(
        (ref) => create(ref as CanWatchEpisodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
        episodeNumber: episodeNumber,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanWatchEpisodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanWatchEpisodeProvider &&
        other.dramaId == dramaId &&
        other.episodeNumber == episodeNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);
    hash = _SystemHash.combine(hash, episodeNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanWatchEpisodeRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;

  /// The parameter `episodeNumber` of this provider.
  int get episodeNumber;
}

class _CanWatchEpisodeProviderElement extends AutoDisposeProviderElement<bool>
    with CanWatchEpisodeRef {
  _CanWatchEpisodeProviderElement(super.provider);

  @override
  String get dramaId => (origin as CanWatchEpisodeProvider).dramaId;
  @override
  int get episodeNumber => (origin as CanWatchEpisodeProvider).episodeNumber;
}

String _$featuredDramasStreamHash() =>
    r'3e8705c2acd345e29c265977c5435a607f2423e3';

/// See also [featuredDramasStream].
@ProviderFor(featuredDramasStream)
final featuredDramasStreamProvider =
    AutoDisposeStreamProvider<List<DramaModel>>.internal(
  featuredDramasStream,
  name: r'featuredDramasStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredDramasStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedDramasStreamRef
    = AutoDisposeStreamProviderRef<List<DramaModel>>;
String _$trendingDramasStreamHash() =>
    r'acd2be7182839f8d9b20dd6b062dbdf6ce74774c';

/// See also [trendingDramasStream].
@ProviderFor(trendingDramasStream)
final trendingDramasStreamProvider =
    AutoDisposeStreamProvider<List<DramaModel>>.internal(
  trendingDramasStream,
  name: r'trendingDramasStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingDramasStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrendingDramasStreamRef
    = AutoDisposeStreamProviderRef<List<DramaModel>>;
String _$dramaStreamHash() => r'8a830241d1c0e9736ebdc093e8252ed66c6243d7';

/// See also [dramaStream].
@ProviderFor(dramaStream)
const dramaStreamProvider = DramaStreamFamily();

/// See also [dramaStream].
class DramaStreamFamily extends Family<AsyncValue<DramaModel>> {
  /// See also [dramaStream].
  const DramaStreamFamily();

  /// See also [dramaStream].
  DramaStreamProvider call(
    String dramaId,
  ) {
    return DramaStreamProvider(
      dramaId,
    );
  }

  @override
  DramaStreamProvider getProviderOverride(
    covariant DramaStreamProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'dramaStreamProvider';
}

/// See also [dramaStream].
class DramaStreamProvider extends AutoDisposeStreamProvider<DramaModel> {
  /// See also [dramaStream].
  DramaStreamProvider(
    String dramaId,
  ) : this._internal(
          (ref) => dramaStream(
            ref as DramaStreamRef,
            dramaId,
          ),
          from: dramaStreamProvider,
          name: r'dramaStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaStreamHash,
          dependencies: DramaStreamFamily._dependencies,
          allTransitiveDependencies:
              DramaStreamFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    Stream<DramaModel> Function(DramaStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaStreamProvider._internal(
        (ref) => create(ref as DramaStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<DramaModel> createElement() {
    return _DramaStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaStreamProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaStreamRef on AutoDisposeStreamProviderRef<DramaModel> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaStreamProviderElement
    extends AutoDisposeStreamProviderElement<DramaModel> with DramaStreamRef {
  _DramaStreamProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaStreamProvider).dramaId;
}

String _$dramaEpisodesStreamHash() =>
    r'1e8e972f7cf5caa5e0c3c4e7e435b59796b6acfe';

/// See also [dramaEpisodesStream].
@ProviderFor(dramaEpisodesStream)
const dramaEpisodesStreamProvider = DramaEpisodesStreamFamily();

/// See also [dramaEpisodesStream].
class DramaEpisodesStreamFamily extends Family<AsyncValue<List<EpisodeModel>>> {
  /// See also [dramaEpisodesStream].
  const DramaEpisodesStreamFamily();

  /// See also [dramaEpisodesStream].
  DramaEpisodesStreamProvider call(
    String dramaId,
  ) {
    return DramaEpisodesStreamProvider(
      dramaId,
    );
  }

  @override
  DramaEpisodesStreamProvider getProviderOverride(
    covariant DramaEpisodesStreamProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'dramaEpisodesStreamProvider';
}

/// See also [dramaEpisodesStream].
class DramaEpisodesStreamProvider
    extends AutoDisposeStreamProvider<List<EpisodeModel>> {
  /// See also [dramaEpisodesStream].
  DramaEpisodesStreamProvider(
    String dramaId,
  ) : this._internal(
          (ref) => dramaEpisodesStream(
            ref as DramaEpisodesStreamRef,
            dramaId,
          ),
          from: dramaEpisodesStreamProvider,
          name: r'dramaEpisodesStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaEpisodesStreamHash,
          dependencies: DramaEpisodesStreamFamily._dependencies,
          allTransitiveDependencies:
              DramaEpisodesStreamFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaEpisodesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  Override overrideWith(
    Stream<List<EpisodeModel>> Function(DramaEpisodesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaEpisodesStreamProvider._internal(
        (ref) => create(ref as DramaEpisodesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<EpisodeModel>> createElement() {
    return _DramaEpisodesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaEpisodesStreamProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaEpisodesStreamRef
    on AutoDisposeStreamProviderRef<List<EpisodeModel>> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaEpisodesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<EpisodeModel>>
    with DramaEpisodesStreamRef {
  _DramaEpisodesStreamProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaEpisodesStreamProvider).dramaId;
}

String _$featuredDramasHash() => r'471162570e9f7d0fa8ec6a5488f1e844c8f5ba18';

/// See also [FeaturedDramas].
@ProviderFor(FeaturedDramas)
final featuredDramasProvider =
    AutoDisposeAsyncNotifierProvider<FeaturedDramas, List<DramaModel>>.internal(
  FeaturedDramas.new,
  name: r'featuredDramasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeaturedDramas = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$trendingDramasHash() => r'6da945bc5f7b86bbb7b2330fa395b5bcb8854e2e';

/// See also [TrendingDramas].
@ProviderFor(TrendingDramas)
final trendingDramasProvider =
    AutoDisposeAsyncNotifierProvider<TrendingDramas, List<DramaModel>>.internal(
  TrendingDramas.new,
  name: r'trendingDramasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrendingDramas = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$allDramasHash() => r'bd9e4caa8f69ee0ffc9ae6ca06d614f3b02b7a8a';

/// See also [AllDramas].
@ProviderFor(AllDramas)
final allDramasProvider =
    AutoDisposeAsyncNotifierProvider<AllDramas, DramaListState>.internal(
  AllDramas.new,
  name: r'allDramasProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AllDramas = AutoDisposeAsyncNotifier<DramaListState>;
String _$freeDramasHash() => r'267b1215643c24e9c54a12c0b4e8ebbde79f6a84';

/// See also [FreeDramas].
@ProviderFor(FreeDramas)
final freeDramasProvider =
    AutoDisposeAsyncNotifierProvider<FreeDramas, List<DramaModel>>.internal(
  FreeDramas.new,
  name: r'freeDramasProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$freeDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FreeDramas = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$premiumDramasHash() => r'635eb8ced04f327064faeeff794321e2ffeafcd3';

/// See also [PremiumDramas].
@ProviderFor(PremiumDramas)
final premiumDramasProvider =
    AutoDisposeAsyncNotifierProvider<PremiumDramas, List<DramaModel>>.internal(
  PremiumDramas.new,
  name: r'premiumDramasProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$premiumDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PremiumDramas = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$dramaHash() => r'3a063dbd368dccbacc9030f6fc7e652dea304d1d';

abstract class _$Drama extends BuildlessAutoDisposeAsyncNotifier<DramaModel?> {
  late final String dramaId;

  FutureOr<DramaModel?> build(
    String dramaId,
  );
}

/// See also [Drama].
@ProviderFor(Drama)
const dramaProvider = DramaFamily();

/// See also [Drama].
class DramaFamily extends Family<AsyncValue<DramaModel?>> {
  /// See also [Drama].
  const DramaFamily();

  /// See also [Drama].
  DramaProvider call(
    String dramaId,
  ) {
    return DramaProvider(
      dramaId,
    );
  }

  @override
  DramaProvider getProviderOverride(
    covariant DramaProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'dramaProvider';
}

/// See also [Drama].
class DramaProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Drama, DramaModel?> {
  /// See also [Drama].
  DramaProvider(
    String dramaId,
  ) : this._internal(
          () => Drama()..dramaId = dramaId,
          from: dramaProvider,
          name: r'dramaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaHash,
          dependencies: DramaFamily._dependencies,
          allTransitiveDependencies: DramaFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  FutureOr<DramaModel?> runNotifierBuild(
    covariant Drama notifier,
  ) {
    return notifier.build(
      dramaId,
    );
  }

  @override
  Override overrideWith(Drama Function() create) {
    return ProviderOverride(
      origin: this,
      override: DramaProvider._internal(
        () => create()..dramaId = dramaId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Drama, DramaModel?> createElement() {
    return _DramaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaRef on AutoDisposeAsyncNotifierProviderRef<DramaModel?> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Drama, DramaModel?>
    with DramaRef {
  _DramaProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaProvider).dramaId;
}

String _$dramaEpisodesHash() => r'55baf80e0b1642ecfba170cc1193ee8e157f713c';

abstract class _$DramaEpisodes
    extends BuildlessAutoDisposeAsyncNotifier<List<EpisodeModel>> {
  late final String dramaId;

  FutureOr<List<EpisodeModel>> build(
    String dramaId,
  );
}

/// See also [DramaEpisodes].
@ProviderFor(DramaEpisodes)
const dramaEpisodesProvider = DramaEpisodesFamily();

/// See also [DramaEpisodes].
class DramaEpisodesFamily extends Family<AsyncValue<List<EpisodeModel>>> {
  /// See also [DramaEpisodes].
  const DramaEpisodesFamily();

  /// See also [DramaEpisodes].
  DramaEpisodesProvider call(
    String dramaId,
  ) {
    return DramaEpisodesProvider(
      dramaId,
    );
  }

  @override
  DramaEpisodesProvider getProviderOverride(
    covariant DramaEpisodesProvider provider,
  ) {
    return call(
      provider.dramaId,
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
  String? get name => r'dramaEpisodesProvider';
}

/// See also [DramaEpisodes].
class DramaEpisodesProvider extends AutoDisposeAsyncNotifierProviderImpl<
    DramaEpisodes, List<EpisodeModel>> {
  /// See also [DramaEpisodes].
  DramaEpisodesProvider(
    String dramaId,
  ) : this._internal(
          () => DramaEpisodes()..dramaId = dramaId,
          from: dramaEpisodesProvider,
          name: r'dramaEpisodesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaEpisodesHash,
          dependencies: DramaEpisodesFamily._dependencies,
          allTransitiveDependencies:
              DramaEpisodesFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaEpisodesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.dramaId,
  }) : super.internal();

  final String dramaId;

  @override
  FutureOr<List<EpisodeModel>> runNotifierBuild(
    covariant DramaEpisodes notifier,
  ) {
    return notifier.build(
      dramaId,
    );
  }

  @override
  Override overrideWith(DramaEpisodes Function() create) {
    return ProviderOverride(
      origin: this,
      override: DramaEpisodesProvider._internal(
        () => create()..dramaId = dramaId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        dramaId: dramaId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<DramaEpisodes, List<EpisodeModel>>
      createElement() {
    return _DramaEpisodesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaEpisodesProvider && other.dramaId == dramaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, dramaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaEpisodesRef
    on AutoDisposeAsyncNotifierProviderRef<List<EpisodeModel>> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaEpisodesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DramaEpisodes,
        List<EpisodeModel>> with DramaEpisodesRef {
  _DramaEpisodesProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaEpisodesProvider).dramaId;
}

String _$searchDramasHash() => r'7d229881527675981ff86af67fa75c32fe16bb81';

abstract class _$SearchDramas
    extends BuildlessAutoDisposeAsyncNotifier<List<DramaModel>> {
  late final String query;

  FutureOr<List<DramaModel>> build(
    String query,
  );
}

/// See also [SearchDramas].
@ProviderFor(SearchDramas)
const searchDramasProvider = SearchDramasFamily();

/// See also [SearchDramas].
class SearchDramasFamily extends Family<AsyncValue<List<DramaModel>>> {
  /// See also [SearchDramas].
  const SearchDramasFamily();

  /// See also [SearchDramas].
  SearchDramasProvider call(
    String query,
  ) {
    return SearchDramasProvider(
      query,
    );
  }

  @override
  SearchDramasProvider getProviderOverride(
    covariant SearchDramasProvider provider,
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
  String? get name => r'searchDramasProvider';
}

/// See also [SearchDramas].
class SearchDramasProvider extends AutoDisposeAsyncNotifierProviderImpl<
    SearchDramas, List<DramaModel>> {
  /// See also [SearchDramas].
  SearchDramasProvider(
    String query,
  ) : this._internal(
          () => SearchDramas()..query = query,
          from: searchDramasProvider,
          name: r'searchDramasProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchDramasHash,
          dependencies: SearchDramasFamily._dependencies,
          allTransitiveDependencies:
              SearchDramasFamily._allTransitiveDependencies,
          query: query,
        );

  SearchDramasProvider._internal(
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
  FutureOr<List<DramaModel>> runNotifierBuild(
    covariant SearchDramas notifier,
  ) {
    return notifier.build(
      query,
    );
  }

  @override
  Override overrideWith(SearchDramas Function() create) {
    return ProviderOverride(
      origin: this,
      override: SearchDramasProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<SearchDramas, List<DramaModel>>
      createElement() {
    return _SearchDramasProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchDramasProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchDramasRef on AutoDisposeAsyncNotifierProviderRef<List<DramaModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchDramasProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<SearchDramas,
        List<DramaModel>> with SearchDramasRef {
  _SearchDramasProviderElement(super.provider);

  @override
  String get query => (origin as SearchDramasProvider).query;
}

String _$adminDramasHash() => r'73490374ef84bed899f834a0aef482c537349c2e';

/// See also [AdminDramas].
@ProviderFor(AdminDramas)
final adminDramasProvider =
    AutoDisposeAsyncNotifierProvider<AdminDramas, List<DramaModel>>.internal(
  AdminDramas.new,
  name: r'adminDramasProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminDramasHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminDramas = AutoDisposeAsyncNotifier<List<DramaModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package