// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dramaRepositoryHash() => r'797c6581b95c90edd90bd8af19d001b19d2e7d8e';

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
    r'026077b94af1de7488d5d691f75e5dc63265c128';

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
    r'468707cc825ae22384fc6a19c722f1d3b6b797c3';

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
String _$isDramaFavoritedHash() => r'4f0a6d138f242368ab07bc1f17db67e07eb1a20a';

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

String _$isDramaUnlockedHash() => r'ba87a6b558b4cbc7c9038dc5e62fbcad2cfb09d0';

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

String _$dramaUserProgressHash() => r'27397d8d9e59cc04e73cd815a028c554f33658e4';

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

String _$canWatchEpisodeHash() => r'093029327ce7e69d2dc355c14c3219609a557181';

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
String _$allDramasHash() => r'e33514c865b8d2b115c9e91f3d3214a8b9903e32';

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
String _$dramaHash() => r'c0f0340e4c09cc5bfe05dc9bcb11ec428966ab8f';

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

String _$dramaEpisodesHash() => r'679b031a3b30aa56c573fe68165ba42fb568a502';

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

String _$adminDramasHash() => r'7b3c2cf913b3510713705ca548541851fec6ffe4';

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
String _$featuredDramasLiveHash() =>
    r'8e763b35881bc89f31121e0a4efa589337681241';

/// See also [FeaturedDramasLive].
@ProviderFor(FeaturedDramasLive)
final featuredDramasLiveProvider = AutoDisposeAsyncNotifierProvider<
    FeaturedDramasLive, List<DramaModel>>.internal(
  FeaturedDramasLive.new,
  name: r'featuredDramasLiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredDramasLiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeaturedDramasLive = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$trendingDramasLiveHash() =>
    r'bc6f463d58f212ac851fba0efad5003d4f8a1138';

/// See also [TrendingDramasLive].
@ProviderFor(TrendingDramasLive)
final trendingDramasLiveProvider = AutoDisposeAsyncNotifierProvider<
    TrendingDramasLive, List<DramaModel>>.internal(
  TrendingDramasLive.new,
  name: r'trendingDramasLiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingDramasLiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrendingDramasLive = AutoDisposeAsyncNotifier<List<DramaModel>>;
String _$dramaLiveHash() => r'c452b482d56861ce08bb1e5c62c715c6c479341a';

abstract class _$DramaLive
    extends BuildlessAutoDisposeAsyncNotifier<DramaModel?> {
  late final String dramaId;

  FutureOr<DramaModel?> build(
    String dramaId,
  );
}

/// See also [DramaLive].
@ProviderFor(DramaLive)
const dramaLiveProvider = DramaLiveFamily();

/// See also [DramaLive].
class DramaLiveFamily extends Family<AsyncValue<DramaModel?>> {
  /// See also [DramaLive].
  const DramaLiveFamily();

  /// See also [DramaLive].
  DramaLiveProvider call(
    String dramaId,
  ) {
    return DramaLiveProvider(
      dramaId,
    );
  }

  @override
  DramaLiveProvider getProviderOverride(
    covariant DramaLiveProvider provider,
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
  String? get name => r'dramaLiveProvider';
}

/// See also [DramaLive].
class DramaLiveProvider
    extends AutoDisposeAsyncNotifierProviderImpl<DramaLive, DramaModel?> {
  /// See also [DramaLive].
  DramaLiveProvider(
    String dramaId,
  ) : this._internal(
          () => DramaLive()..dramaId = dramaId,
          from: dramaLiveProvider,
          name: r'dramaLiveProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaLiveHash,
          dependencies: DramaLiveFamily._dependencies,
          allTransitiveDependencies: DramaLiveFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaLiveProvider._internal(
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
    covariant DramaLive notifier,
  ) {
    return notifier.build(
      dramaId,
    );
  }

  @override
  Override overrideWith(DramaLive Function() create) {
    return ProviderOverride(
      origin: this,
      override: DramaLiveProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<DramaLive, DramaModel?>
      createElement() {
    return _DramaLiveProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaLiveProvider && other.dramaId == dramaId;
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
mixin DramaLiveRef on AutoDisposeAsyncNotifierProviderRef<DramaModel?> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaLiveProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DramaLive, DramaModel?>
    with DramaLiveRef {
  _DramaLiveProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaLiveProvider).dramaId;
}

String _$dramaEpisodesLiveHash() => r'2f05cfb443a547dc0713bc4095c25e724b9fe935';

abstract class _$DramaEpisodesLive
    extends BuildlessAutoDisposeAsyncNotifier<List<EpisodeModel>> {
  late final String dramaId;

  FutureOr<List<EpisodeModel>> build(
    String dramaId,
  );
}

/// See also [DramaEpisodesLive].
@ProviderFor(DramaEpisodesLive)
const dramaEpisodesLiveProvider = DramaEpisodesLiveFamily();

/// See also [DramaEpisodesLive].
class DramaEpisodesLiveFamily extends Family<AsyncValue<List<EpisodeModel>>> {
  /// See also [DramaEpisodesLive].
  const DramaEpisodesLiveFamily();

  /// See also [DramaEpisodesLive].
  DramaEpisodesLiveProvider call(
    String dramaId,
  ) {
    return DramaEpisodesLiveProvider(
      dramaId,
    );
  }

  @override
  DramaEpisodesLiveProvider getProviderOverride(
    covariant DramaEpisodesLiveProvider provider,
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
  String? get name => r'dramaEpisodesLiveProvider';
}

/// See also [DramaEpisodesLive].
class DramaEpisodesLiveProvider extends AutoDisposeAsyncNotifierProviderImpl<
    DramaEpisodesLive, List<EpisodeModel>> {
  /// See also [DramaEpisodesLive].
  DramaEpisodesLiveProvider(
    String dramaId,
  ) : this._internal(
          () => DramaEpisodesLive()..dramaId = dramaId,
          from: dramaEpisodesLiveProvider,
          name: r'dramaEpisodesLiveProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaEpisodesLiveHash,
          dependencies: DramaEpisodesLiveFamily._dependencies,
          allTransitiveDependencies:
              DramaEpisodesLiveFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaEpisodesLiveProvider._internal(
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
    covariant DramaEpisodesLive notifier,
  ) {
    return notifier.build(
      dramaId,
    );
  }

  @override
  Override overrideWith(DramaEpisodesLive Function() create) {
    return ProviderOverride(
      origin: this,
      override: DramaEpisodesLiveProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<DramaEpisodesLive, List<EpisodeModel>>
      createElement() {
    return _DramaEpisodesLiveProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaEpisodesLiveProvider && other.dramaId == dramaId;
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
mixin DramaEpisodesLiveRef
    on AutoDisposeAsyncNotifierProviderRef<List<EpisodeModel>> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaEpisodesLiveProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DramaEpisodesLive,
        List<EpisodeModel>> with DramaEpisodesLiveRef {
  _DramaEpisodesLiveProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaEpisodesLiveProvider).dramaId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
