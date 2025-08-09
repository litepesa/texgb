// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$statusStreamHash() => r'2cbc0f6f885d793890d898d4992ba2d84ccf8c56';

/// See also [statusStream].
@ProviderFor(statusStream)
final statusStreamProvider =
    AutoDisposeStreamProvider<List<UserStatusGroup>>.internal(
  statusStream,
  name: r'statusStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusStreamRef = AutoDisposeStreamProviderRef<List<UserStatusGroup>>;
String _$userStatusesHash() => r'12b1e6e127909671dfbe0f7f01dc42a41969a1b0';

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
class UserStatusesProvider
    extends AutoDisposeFutureProvider<List<StatusModel>> {
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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
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
    r'70f9fa18ff9e645f818d9a33f033491f93916966';

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

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusPrivacySettingsRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$statusNotifierHash() => r'f1f62173c6336d2c32ba8664b350c0a954a88952';

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
