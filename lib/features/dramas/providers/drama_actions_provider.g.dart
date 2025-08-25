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

String _$dramaActionsHash() => r'7d2ced59f14c5580f424224680554d68bfc91f4e';

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
