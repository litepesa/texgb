// lib/features/status/providers/status_provider.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusStreamHash() => r'8a9b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b';

/// See also [statusStream].
@ProviderFor(statusStream)
final statusStreamProvider = AutoDisposeStreamProvider<List<UserStatusGroup>>.internal(
  statusStream,
  name: r'statusStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatusStreamRef = AutoDisposeStreamProviderRef<List<UserStatusGroup>>;
String _$userStatusesHash() => r'9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c';

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

/// See also [userStatuses].
@ProviderFor(userStatuses)
const userStatusesProvider = UserStatusesFamily();

/// See also [userStatuses].
class UserStatusesFamily extends Family<AsyncValue<List<StatusModel>>> {
  /// See also [userStatuses].
  const UserStatusesFamily();

  /// See also [userStatuses].
  UserStatusesProvider call(
    String userId,
  ) {
    return UserStatusesProvider(
      userId,
    );
  }

  @override
  UserStatusesProvider getProviderOverride(
    covariant UserStatusesProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'userStatusesProvider';
}

/// See also [userStatuses].
class UserStatusesProvider extends AutoDisposeFutureProvider<List<StatusModel>> {
  /// See also [userStatuses].
  UserStatusesProvider(
    String userId,
  ) : this._internal(
          (ref) => userStatuses(
            ref as UserStatusesRef,
            userId,
          ),
          from: userStatusesProvider,
          name: r'userStatusesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userStatusesHash,
          dependencies: UserStatusesFamily._dependencies,
          allTransitiveDependencies:
              UserStatusesFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserStatusesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<StatusModel>> Function(UserStatusesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserStatusesProvider._internal(
        (ref) => create(ref as UserStatusesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StatusModel>> createElement() {
    return _UserStatusesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserStatusesProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserStatusesRef on AutoDisposeFutureProviderRef<List<StatusModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserStatusesProviderElement
    extends AutoDisposeFutureProviderElement<List<StatusModel>>
    with UserStatusesRef {
  _UserStatusesProviderElement(super.provider);

  @override
  String get userId => (origin as UserStatusesProvider).userId;
}

String _$statusPrivacySettingsHash() =>
    r'1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d';

/// See also [statusPrivacySettings].
@ProviderFor(statusPrivacySettings)
final statusPrivacySettingsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  statusPrivacySettings,
  name: r'statusPrivacySettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusPrivacySettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StatusPrivacySettingsRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$statusNotifierHash() => r'2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e';

/// See also [StatusNotifier].
@ProviderFor(StatusNotifier)
final statusNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StatusNotifier, StatusState>.internal(
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