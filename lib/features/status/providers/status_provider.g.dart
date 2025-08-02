// lib/features/status/providers/status_provider.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$contactsStatusesStreamHash() => r'8f3b2a1c9d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a';

/// See also [contactsStatusesStream].
@ProviderFor(contactsStatusesStream)
final contactsStatusesStreamProvider = AutoDisposeStreamProvider<List<UserStatusGroup>>.internal(
  contactsStatusesStream,
  name: r'contactsStatusesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$contactsStatusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ContactsStatusesStreamRef = AutoDisposeStreamProviderRef<List<UserStatusGroup>>;

String _$myStatusesStreamHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

/// See also [myStatusesStream].
@ProviderFor(myStatusesStream)
final myStatusesStreamProvider = AutoDisposeStreamProvider<List<StatusModel>>.internal(
  myStatusesStream,
  name: r'myStatusesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myStatusesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyStatusesStreamRef = AutoDisposeStreamProviderRef<List<StatusModel>>;

String _$singleStatusHash() => r'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2';

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

/// See also [singleStatus].
@ProviderFor(singleStatus)
const singleStatusProvider = SingleStatusFamily();

/// See also [singleStatus].
class SingleStatusFamily extends Family<AsyncValue<StatusModel?>> {
  /// See also [singleStatus].
  const SingleStatusFamily();

  /// See also [singleStatus].
  SingleStatusProvider call(
    String statusId,
  ) {
    return SingleStatusProvider(
      statusId,
    );
  }

  @override
  SingleStatusProvider getProviderOverride(
    covariant SingleStatusProvider provider,
  ) {
    return call(
      provider.statusId,
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
  String? get name => r'singleStatusProvider';
}

/// See also [singleStatus].
class SingleStatusProvider extends AutoDisposeFutureProvider<StatusModel?> {
  /// See also [singleStatus].
  SingleStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => singleStatus(
            ref as SingleStatusRef,
            statusId,
          ),
          from: singleStatusProvider,
          name: r'singleStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$singleStatusHash,
          dependencies: SingleStatusFamily._dependencies,
          allTransitiveDependencies:
              SingleStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  SingleStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.statusId,
  }) : super.internal();

  final String statusId;

  @override
  Override overrideWith(
    FutureOr<StatusModel?> Function(SingleStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SingleStatusProvider._internal(
        (ref) => create(ref as SingleStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        statusId: statusId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StatusModel?> createElement() {
    return _SingleStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SingleStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SingleStatusRef on AutoDisposeFutureProviderRef<StatusModel?> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _SingleStatusProviderElement
    extends AutoDisposeFutureProviderElement<StatusModel?>
    with SingleStatusRef {
  _SingleStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as SingleStatusProvider).statusId;
}

String _$statusNotifierHash() => r'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3';

/// See also [StatusNotifier].
@ProviderFor(StatusNotifier)
final statusNotifierProvider = AutoDisposeAsyncNotifierProvider<StatusNotifier, StatusState>.internal(
  StatusNotifier.new,
  name: r'statusNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StatusNotifier = AutoDisposeAsyncNotifier<StatusState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package