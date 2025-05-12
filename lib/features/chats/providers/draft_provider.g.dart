// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$draftNotifierHash() => r'e87e9aaff91eb14ec965a11667dce380bc2d1d5e';

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

abstract class _$DraftNotifier
    extends BuildlessAutoDisposeAsyncNotifier<DraftState> {
  late final String contactUID;

  FutureOr<DraftState> build(
    String contactUID,
  );
}

/// Provider for managing message drafts.
/// Handles saving, retrieving, and updating draft messages.
///
/// Copied from [DraftNotifier].
@ProviderFor(DraftNotifier)
const draftNotifierProvider = DraftNotifierFamily();

/// Provider for managing message drafts.
/// Handles saving, retrieving, and updating draft messages.
///
/// Copied from [DraftNotifier].
class DraftNotifierFamily extends Family<AsyncValue<DraftState>> {
  /// Provider for managing message drafts.
  /// Handles saving, retrieving, and updating draft messages.
  ///
  /// Copied from [DraftNotifier].
  const DraftNotifierFamily();

  /// Provider for managing message drafts.
  /// Handles saving, retrieving, and updating draft messages.
  ///
  /// Copied from [DraftNotifier].
  DraftNotifierProvider call(
    String contactUID,
  ) {
    return DraftNotifierProvider(
      contactUID,
    );
  }

  @override
  DraftNotifierProvider getProviderOverride(
    covariant DraftNotifierProvider provider,
  ) {
    return call(
      provider.contactUID,
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
  String? get name => r'draftNotifierProvider';
}

/// Provider for managing message drafts.
/// Handles saving, retrieving, and updating draft messages.
///
/// Copied from [DraftNotifier].
class DraftNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<DraftNotifier, DraftState> {
  /// Provider for managing message drafts.
  /// Handles saving, retrieving, and updating draft messages.
  ///
  /// Copied from [DraftNotifier].
  DraftNotifierProvider(
    String contactUID,
  ) : this._internal(
          () => DraftNotifier()..contactUID = contactUID,
          from: draftNotifierProvider,
          name: r'draftNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$draftNotifierHash,
          dependencies: DraftNotifierFamily._dependencies,
          allTransitiveDependencies:
              DraftNotifierFamily._allTransitiveDependencies,
          contactUID: contactUID,
        );

  DraftNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contactUID,
  }) : super.internal();

  final String contactUID;

  @override
  FutureOr<DraftState> runNotifierBuild(
    covariant DraftNotifier notifier,
  ) {
    return notifier.build(
      contactUID,
    );
  }

  @override
  Override overrideWith(DraftNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: DraftNotifierProvider._internal(
        () => create()..contactUID = contactUID,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contactUID: contactUID,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<DraftNotifier, DraftState>
      createElement() {
    return _DraftNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DraftNotifierProvider && other.contactUID == contactUID;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contactUID.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DraftNotifierRef on AutoDisposeAsyncNotifierProviderRef<DraftState> {
  /// The parameter `contactUID` of this provider.
  String get contactUID;
}

class _DraftNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DraftNotifier, DraftState>
    with DraftNotifierRef {
  _DraftNotifierProviderElement(super.provider);

  @override
  String get contactUID => (origin as DraftNotifierProvider).contactUID;
}

String _$allDraftsNotifierHash() => r'e036deed8dd2eae2e5218d5216a10a4338bc8e8e';

/// Provider for accessing all drafts
///
/// Copied from [AllDraftsNotifier].
@ProviderFor(AllDraftsNotifier)
final allDraftsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AllDraftsNotifier, List<DraftMessageModel>>.internal(
  AllDraftsNotifier.new,
  name: r'allDraftsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allDraftsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AllDraftsNotifier = AutoDisposeAsyncNotifier<List<DraftMessageModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
