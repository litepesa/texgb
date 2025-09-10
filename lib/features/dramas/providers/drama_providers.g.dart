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

String _$dramaEpisodeHash() => r'85b9da9b139a0b762c21f8e6cef1453fbf335658';

/// See also [dramaEpisode].
@ProviderFor(dramaEpisode)
const dramaEpisodeProvider = DramaEpisodeFamily();

/// See also [dramaEpisode].
class DramaEpisodeFamily extends Family<Episode?> {
  /// See also [dramaEpisode].
  const DramaEpisodeFamily();

  /// See also [dramaEpisode].
  DramaEpisodeProvider call(
    String dramaId,
    int episodeNumber,
  ) {
    return DramaEpisodeProvider(
      dramaId,
      episodeNumber,
    );
  }

  @override
  DramaEpisodeProvider getProviderOverride(
    covariant DramaEpisodeProvider provider,
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
  String? get name => r'dramaEpisodeProvider';
}

/// See also [dramaEpisode].
class DramaEpisodeProvider extends AutoDisposeProvider<Episode?> {
  /// See also [dramaEpisode].
  DramaEpisodeProvider(
    String dramaId,
    int episodeNumber,
  ) : this._internal(
          (ref) => dramaEpisode(
            ref as DramaEpisodeRef,
            dramaId,
            episodeNumber,
          ),
          from: dramaEpisodeProvider,
          name: r'dramaEpisodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaEpisodeHash,
          dependencies: DramaEpisodeFamily._dependencies,
          allTransitiveDependencies:
              DramaEpisodeFamily._allTransitiveDependencies,
          dramaId: dramaId,
          episodeNumber: episodeNumber,
        );

  DramaEpisodeProvider._internal(
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
    Episode? Function(DramaEpisodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaEpisodeProvider._internal(
        (ref) => create(ref as DramaEpisodeRef),
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
  AutoDisposeProviderElement<Episode?> createElement() {
    return _DramaEpisodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaEpisodeProvider &&
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
mixin DramaEpisodeRef on AutoDisposeProviderRef<Episode?> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;

  /// The parameter `episodeNumber` of this provider.
  int get episodeNumber;
}

class _DramaEpisodeProviderElement extends AutoDisposeProviderElement<Episode?>
    with DramaEpisodeRef {
  _DramaEpisodeProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaEpisodeProvider).dramaId;
  @override
  int get episodeNumber => (origin as DramaEpisodeProvider).episodeNumber;
}

String _$dramaEpisodeListHash() => r'045472b05cf0d410be966e3315d25e912825be5f';

/// See also [dramaEpisodeList].
@ProviderFor(dramaEpisodeList)
const dramaEpisodeListProvider = DramaEpisodeListFamily();

/// See also [dramaEpisodeList].
class DramaEpisodeListFamily extends Family<List<Episode>> {
  /// See also [dramaEpisodeList].
  const DramaEpisodeListFamily();

  /// See also [dramaEpisodeList].
  DramaEpisodeListProvider call(
    String dramaId,
  ) {
    return DramaEpisodeListProvider(
      dramaId,
    );
  }

  @override
  DramaEpisodeListProvider getProviderOverride(
    covariant DramaEpisodeListProvider provider,
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
  String? get name => r'dramaEpisodeListProvider';
}

/// See also [dramaEpisodeList].
class DramaEpisodeListProvider extends AutoDisposeProvider<List<Episode>> {
  /// See also [dramaEpisodeList].
  DramaEpisodeListProvider(
    String dramaId,
  ) : this._internal(
          (ref) => dramaEpisodeList(
            ref as DramaEpisodeListRef,
            dramaId,
          ),
          from: dramaEpisodeListProvider,
          name: r'dramaEpisodeListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaEpisodeListHash,
          dependencies: DramaEpisodeListFamily._dependencies,
          allTransitiveDependencies:
              DramaEpisodeListFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  DramaEpisodeListProvider._internal(
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
    List<Episode> Function(DramaEpisodeListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaEpisodeListProvider._internal(
        (ref) => create(ref as DramaEpisodeListRef),
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
  AutoDisposeProviderElement<List<Episode>> createElement() {
    return _DramaEpisodeListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaEpisodeListProvider && other.dramaId == dramaId;
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
mixin DramaEpisodeListRef on AutoDisposeProviderRef<List<Episode>> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _DramaEpisodeListProviderElement
    extends AutoDisposeProviderElement<List<Episode>> with DramaEpisodeListRef {
  _DramaEpisodeListProviderElement(super.provider);

  @override
  String get dramaId => (origin as DramaEpisodeListProvider).dramaId;
}

String _$nextEpisodeToWatchHash() =>
    r'4dc37b113fa0e6f744c661a11616b1b1bee9af38';

/// See also [nextEpisodeToWatch].
@ProviderFor(nextEpisodeToWatch)
const nextEpisodeToWatchProvider = NextEpisodeToWatchFamily();

/// See also [nextEpisodeToWatch].
class NextEpisodeToWatchFamily extends Family<int> {
  /// See also [nextEpisodeToWatch].
  const NextEpisodeToWatchFamily();

  /// See also [nextEpisodeToWatch].
  NextEpisodeToWatchProvider call(
    String dramaId,
  ) {
    return NextEpisodeToWatchProvider(
      dramaId,
    );
  }

  @override
  NextEpisodeToWatchProvider getProviderOverride(
    covariant NextEpisodeToWatchProvider provider,
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
  String? get name => r'nextEpisodeToWatchProvider';
}

/// See also [nextEpisodeToWatch].
class NextEpisodeToWatchProvider extends AutoDisposeProvider<int> {
  /// See also [nextEpisodeToWatch].
  NextEpisodeToWatchProvider(
    String dramaId,
  ) : this._internal(
          (ref) => nextEpisodeToWatch(
            ref as NextEpisodeToWatchRef,
            dramaId,
          ),
          from: nextEpisodeToWatchProvider,
          name: r'nextEpisodeToWatchProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$nextEpisodeToWatchHash,
          dependencies: NextEpisodeToWatchFamily._dependencies,
          allTransitiveDependencies:
              NextEpisodeToWatchFamily._allTransitiveDependencies,
          dramaId: dramaId,
        );

  NextEpisodeToWatchProvider._internal(
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
    int Function(NextEpisodeToWatchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: NextEpisodeToWatchProvider._internal(
        (ref) => create(ref as NextEpisodeToWatchRef),
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
    return _NextEpisodeToWatchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NextEpisodeToWatchProvider && other.dramaId == dramaId;
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
mixin NextEpisodeToWatchRef on AutoDisposeProviderRef<int> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;
}

class _NextEpisodeToWatchProviderElement extends AutoDisposeProviderElement<int>
    with NextEpisodeToWatchRef {
  _NextEpisodeToWatchProviderElement(super.provider);

  @override
  String get dramaId => (origin as NextEpisodeToWatchProvider).dramaId;
}

String _$episodeRequiresUnlockHash() =>
    r'7b548fbb4cadd397d1f393fbfb0bbb057f1caab1';

/// See also [episodeRequiresUnlock].
@ProviderFor(episodeRequiresUnlock)
const episodeRequiresUnlockProvider = EpisodeRequiresUnlockFamily();

/// See also [episodeRequiresUnlock].
class EpisodeRequiresUnlockFamily extends Family<bool> {
  /// See also [episodeRequiresUnlock].
  const EpisodeRequiresUnlockFamily();

  /// See also [episodeRequiresUnlock].
  EpisodeRequiresUnlockProvider call(
    String dramaId,
    int episodeNumber,
  ) {
    return EpisodeRequiresUnlockProvider(
      dramaId,
      episodeNumber,
    );
  }

  @override
  EpisodeRequiresUnlockProvider getProviderOverride(
    covariant EpisodeRequiresUnlockProvider provider,
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
  String? get name => r'episodeRequiresUnlockProvider';
}

/// See also [episodeRequiresUnlock].
class EpisodeRequiresUnlockProvider extends AutoDisposeProvider<bool> {
  /// See also [episodeRequiresUnlock].
  EpisodeRequiresUnlockProvider(
    String dramaId,
    int episodeNumber,
  ) : this._internal(
          (ref) => episodeRequiresUnlock(
            ref as EpisodeRequiresUnlockRef,
            dramaId,
            episodeNumber,
          ),
          from: episodeRequiresUnlockProvider,
          name: r'episodeRequiresUnlockProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$episodeRequiresUnlockHash,
          dependencies: EpisodeRequiresUnlockFamily._dependencies,
          allTransitiveDependencies:
              EpisodeRequiresUnlockFamily._allTransitiveDependencies,
          dramaId: dramaId,
          episodeNumber: episodeNumber,
        );

  EpisodeRequiresUnlockProvider._internal(
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
    bool Function(EpisodeRequiresUnlockRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EpisodeRequiresUnlockProvider._internal(
        (ref) => create(ref as EpisodeRequiresUnlockRef),
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
    return _EpisodeRequiresUnlockProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeRequiresUnlockProvider &&
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
mixin EpisodeRequiresUnlockRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;

  /// The parameter `episodeNumber` of this provider.
  int get episodeNumber;
}

class _EpisodeRequiresUnlockProviderElement
    extends AutoDisposeProviderElement<bool> with EpisodeRequiresUnlockRef {
  _EpisodeRequiresUnlockProviderElement(super.provider);

  @override
  String get dramaId => (origin as EpisodeRequiresUnlockProvider).dramaId;
  @override
  int get episodeNumber =>
      (origin as EpisodeRequiresUnlockProvider).episodeNumber;
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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
