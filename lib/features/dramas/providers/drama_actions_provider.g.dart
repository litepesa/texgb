// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drama_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$canWatchDramaEpisodeHash() =>
    r'c7266abf3152890cd802c25745b82300576880c3';

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

/// See also [canWatchDramaEpisode].
@ProviderFor(canWatchDramaEpisode)
const canWatchDramaEpisodeProvider = CanWatchDramaEpisodeFamily();

/// See also [canWatchDramaEpisode].
class CanWatchDramaEpisodeFamily extends Family<bool> {
  /// See also [canWatchDramaEpisode].
  const CanWatchDramaEpisodeFamily();

  /// See also [canWatchDramaEpisode].
  CanWatchDramaEpisodeProvider call(
    String dramaId,
    int episodeNumber,
  ) {
    return CanWatchDramaEpisodeProvider(
      dramaId,
      episodeNumber,
    );
  }

  @override
  CanWatchDramaEpisodeProvider getProviderOverride(
    covariant CanWatchDramaEpisodeProvider provider,
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
  String? get name => r'canWatchDramaEpisodeProvider';
}

/// See also [canWatchDramaEpisode].
class CanWatchDramaEpisodeProvider extends AutoDisposeProvider<bool> {
  /// See also [canWatchDramaEpisode].
  CanWatchDramaEpisodeProvider(
    String dramaId,
    int episodeNumber,
  ) : this._internal(
          (ref) => canWatchDramaEpisode(
            ref as CanWatchDramaEpisodeRef,
            dramaId,
            episodeNumber,
          ),
          from: canWatchDramaEpisodeProvider,
          name: r'canWatchDramaEpisodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canWatchDramaEpisodeHash,
          dependencies: CanWatchDramaEpisodeFamily._dependencies,
          allTransitiveDependencies:
              CanWatchDramaEpisodeFamily._allTransitiveDependencies,
          dramaId: dramaId,
          episodeNumber: episodeNumber,
        );

  CanWatchDramaEpisodeProvider._internal(
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
    bool Function(CanWatchDramaEpisodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanWatchDramaEpisodeProvider._internal(
        (ref) => create(ref as CanWatchDramaEpisodeRef),
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
    return _CanWatchDramaEpisodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanWatchDramaEpisodeProvider &&
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
mixin CanWatchDramaEpisodeRef on AutoDisposeProviderRef<bool> {
  /// The parameter `dramaId` of this provider.
  String get dramaId;

  /// The parameter `episodeNumber` of this provider.
  int get episodeNumber;
}

class _CanWatchDramaEpisodeProviderElement
    extends AutoDisposeProviderElement<bool> with CanWatchDramaEpisodeRef {
  _CanWatchDramaEpisodeProviderElement(super.provider);

  @override
  String get dramaId => (origin as CanWatchDramaEpisodeProvider).dramaId;
  @override
  int get episodeNumber =>
      (origin as CanWatchDramaEpisodeProvider).episodeNumber;
}

String _$canAffordDramaUnlockHash() =>
    r'9e86b152ee5b53c11240c02a34118669cc703d09';

/// See also [canAffordDramaUnlock].
@ProviderFor(canAffordDramaUnlock)
const canAffordDramaUnlockProvider = CanAffordDramaUnlockFamily();

/// See also [canAffordDramaUnlock].
class CanAffordDramaUnlockFamily extends Family<bool> {
  /// See also [canAffordDramaUnlock].
  const CanAffordDramaUnlockFamily();

  /// See also [canAffordDramaUnlock].
  CanAffordDramaUnlockProvider call({
    int? customCost,
  }) {
    return CanAffordDramaUnlockProvider(
      customCost: customCost,
    );
  }

  @override
  CanAffordDramaUnlockProvider getProviderOverride(
    covariant CanAffordDramaUnlockProvider provider,
  ) {
    return call(
      customCost: provider.customCost,
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
  String? get name => r'canAffordDramaUnlockProvider';
}

/// See also [canAffordDramaUnlock].
class CanAffordDramaUnlockProvider extends AutoDisposeProvider<bool> {
  /// See also [canAffordDramaUnlock].
  CanAffordDramaUnlockProvider({
    int? customCost,
  }) : this._internal(
          (ref) => canAffordDramaUnlock(
            ref as CanAffordDramaUnlockRef,
            customCost: customCost,
          ),
          from: canAffordDramaUnlockProvider,
          name: r'canAffordDramaUnlockProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canAffordDramaUnlockHash,
          dependencies: CanAffordDramaUnlockFamily._dependencies,
          allTransitiveDependencies:
              CanAffordDramaUnlockFamily._allTransitiveDependencies,
          customCost: customCost,
        );

  CanAffordDramaUnlockProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.customCost,
  }) : super.internal();

  final int? customCost;

  @override
  Override overrideWith(
    bool Function(CanAffordDramaUnlockRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanAffordDramaUnlockProvider._internal(
        (ref) => create(ref as CanAffordDramaUnlockRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        customCost: customCost,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _CanAffordDramaUnlockProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanAffordDramaUnlockProvider &&
        other.customCost == customCost;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, customCost.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanAffordDramaUnlockRef on AutoDisposeProviderRef<bool> {
  /// The parameter `customCost` of this provider.
  int? get customCost;
}

class _CanAffordDramaUnlockProviderElement
    extends AutoDisposeProviderElement<bool> with CanAffordDramaUnlockRef {
  _CanAffordDramaUnlockProviderElement(super.provider);

  @override
  int? get customCost => (origin as CanAffordDramaUnlockProvider).customCost;
}

String _$dramaUnlockCostHash() => r'6c6ca0ac2988b276bbeedbc03ac315b37c80ad26';

/// See also [dramaUnlockCost].
@ProviderFor(dramaUnlockCost)
const dramaUnlockCostProvider = DramaUnlockCostFamily();

/// See also [dramaUnlockCost].
class DramaUnlockCostFamily extends Family<int> {
  /// See also [dramaUnlockCost].
  const DramaUnlockCostFamily();

  /// See also [dramaUnlockCost].
  DramaUnlockCostProvider call({
    int? customCost,
  }) {
    return DramaUnlockCostProvider(
      customCost: customCost,
    );
  }

  @override
  DramaUnlockCostProvider getProviderOverride(
    covariant DramaUnlockCostProvider provider,
  ) {
    return call(
      customCost: provider.customCost,
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
  String? get name => r'dramaUnlockCostProvider';
}

/// See also [dramaUnlockCost].
class DramaUnlockCostProvider extends AutoDisposeProvider<int> {
  /// See also [dramaUnlockCost].
  DramaUnlockCostProvider({
    int? customCost,
  }) : this._internal(
          (ref) => dramaUnlockCost(
            ref as DramaUnlockCostRef,
            customCost: customCost,
          ),
          from: dramaUnlockCostProvider,
          name: r'dramaUnlockCostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dramaUnlockCostHash,
          dependencies: DramaUnlockCostFamily._dependencies,
          allTransitiveDependencies:
              DramaUnlockCostFamily._allTransitiveDependencies,
          customCost: customCost,
        );

  DramaUnlockCostProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.customCost,
  }) : super.internal();

  final int? customCost;

  @override
  Override overrideWith(
    int Function(DramaUnlockCostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DramaUnlockCostProvider._internal(
        (ref) => create(ref as DramaUnlockCostRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        customCost: customCost,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int> createElement() {
    return _DramaUnlockCostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DramaUnlockCostProvider && other.customCost == customCost;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, customCost.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DramaUnlockCostRef on AutoDisposeProviderRef<int> {
  /// The parameter `customCost` of this provider.
  int? get customCost;
}

class _DramaUnlockCostProviderElement extends AutoDisposeProviderElement<int>
    with DramaUnlockCostRef {
  _DramaUnlockCostProviderElement(super.provider);

  @override
  int? get customCost => (origin as DramaUnlockCostProvider).customCost;
}

String _$nextEpisodeToWatchHash() =>
    r'2f779ea7a1eb9deff99a0687b76379ef305f8133';

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
    r'de447b78519ccf75830e1456aacbaf08babdc890';

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

String _$coinsAfterUnlockHash() => r'f5567cfe2cca23658c1319d6b56a6a5851a48202';

/// See also [coinsAfterUnlock].
@ProviderFor(coinsAfterUnlock)
const coinsAfterUnlockProvider = CoinsAfterUnlockFamily();

/// See also [coinsAfterUnlock].
class CoinsAfterUnlockFamily extends Family<int?> {
  /// See also [coinsAfterUnlock].
  const CoinsAfterUnlockFamily();

  /// See also [coinsAfterUnlock].
  CoinsAfterUnlockProvider call(
    int unlockCost,
  ) {
    return CoinsAfterUnlockProvider(
      unlockCost,
    );
  }

  @override
  CoinsAfterUnlockProvider getProviderOverride(
    covariant CoinsAfterUnlockProvider provider,
  ) {
    return call(
      provider.unlockCost,
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
  String? get name => r'coinsAfterUnlockProvider';
}

/// See also [coinsAfterUnlock].
class CoinsAfterUnlockProvider extends AutoDisposeProvider<int?> {
  /// See also [coinsAfterUnlock].
  CoinsAfterUnlockProvider(
    int unlockCost,
  ) : this._internal(
          (ref) => coinsAfterUnlock(
            ref as CoinsAfterUnlockRef,
            unlockCost,
          ),
          from: coinsAfterUnlockProvider,
          name: r'coinsAfterUnlockProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$coinsAfterUnlockHash,
          dependencies: CoinsAfterUnlockFamily._dependencies,
          allTransitiveDependencies:
              CoinsAfterUnlockFamily._allTransitiveDependencies,
          unlockCost: unlockCost,
        );

  CoinsAfterUnlockProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.unlockCost,
  }) : super.internal();

  final int unlockCost;

  @override
  Override overrideWith(
    int? Function(CoinsAfterUnlockRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CoinsAfterUnlockProvider._internal(
        (ref) => create(ref as CoinsAfterUnlockRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        unlockCost: unlockCost,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<int?> createElement() {
    return _CoinsAfterUnlockProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CoinsAfterUnlockProvider && other.unlockCost == unlockCost;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, unlockCost.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CoinsAfterUnlockRef on AutoDisposeProviderRef<int?> {
  /// The parameter `unlockCost` of this provider.
  int get unlockCost;
}

class _CoinsAfterUnlockProviderElement extends AutoDisposeProviderElement<int?>
    with CoinsAfterUnlockRef {
  _CoinsAfterUnlockProviderElement(super.provider);

  @override
  int get unlockCost => (origin as CoinsAfterUnlockProvider).unlockCost;
}

String _$dramaActionsHash() => r'cc6c6b991b01f69bd1118e55bb20bba5a335e9b6';

/// See also [DramaActions].
@ProviderFor(DramaActions)
final dramaActionsProvider =
    AutoDisposeNotifierProvider<DramaActions, DramaActionState>.internal(
  DramaActions.new,
  name: r'dramaActionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dramaActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DramaActions = AutoDisposeNotifier<DramaActionState>;
String _$adminDramaActionsHash() => r'f396508797c7562a5f1546a713892f9394e2ba38';

/// See also [AdminDramaActions].
@ProviderFor(AdminDramaActions)
final adminDramaActionsProvider =
    AutoDisposeNotifierProvider<AdminDramaActions, DramaActionState>.internal(
  AdminDramaActions.new,
  name: r'adminDramaActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminDramaActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminDramaActions = AutoDisposeNotifier<DramaActionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package