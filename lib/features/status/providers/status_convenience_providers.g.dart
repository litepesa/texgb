// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_convenience_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allStatusesHash() => r'868aff47bf3ec967cf76abb8663ca585a8d27a66';

/// Get all statuses
///
/// Copied from [allStatuses].
@ProviderFor(allStatuses)
final allStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  allStatuses,
  name: r'allStatusesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$myStatusesHash() => r'a85498e1f356c3b4ec258dbfd3f8e86562820781';

/// Get my statuses (current user's statuses)
///
/// Copied from [myStatuses].
@ProviderFor(myStatuses)
final myStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  myStatuses,
  name: r'myStatusesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$unviewedStatusesHash() => r'364600743f03eb2062df1861677fb9a91fec4e4a';

/// Get unviewed statuses
///
/// Copied from [unviewedStatuses].
@ProviderFor(unviewedStatuses)
final unviewedStatusesProvider =
    AutoDisposeProvider<List<StatusModel>>.internal(
  unviewedStatuses,
  name: r'unviewedStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unviewedStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnviewedStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$activeStatusesHash() => r'2f3b9e08c99788c7373d1a800e8b44dda12b2134';

/// Get active statuses (not expired)
///
/// Copied from [activeStatuses].
@ProviderFor(activeStatuses)
final activeStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  activeStatuses,
  name: r'activeStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$expiredStatusesHash() => r'54e370213a0ef618b977de98131db8421d231d6d';

/// Get expired statuses
///
/// Copied from [expiredStatuses].
@ProviderFor(expiredStatuses)
final expiredStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  expiredStatuses,
  name: r'expiredStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$expiredStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpiredStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$imageStatusesHash() => r'e07b74f2b691ea8c951e343e1259eeb8025397a1';

/// Get image statuses
///
/// Copied from [imageStatuses].
@ProviderFor(imageStatuses)
final imageStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  imageStatuses,
  name: r'imageStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$imageStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImageStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$videoStatusesHash() => r'a120a08372cdac8a6fc12552c4ca6c3f00ec606f';

/// Get video statuses
///
/// Copied from [videoStatuses].
@ProviderFor(videoStatuses)
final videoStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  videoStatuses,
  name: r'videoStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$textStatusesHash() => r'f6a2ad578debd2114ddc8f5b22756782ff3692ef';

/// Get text statuses
///
/// Copied from [textStatuses].
@ProviderFor(textStatuses)
final textStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  textStatuses,
  name: r'textStatusesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$textStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TextStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$mediaStatusesHash() => r'004a1a7c398fd4d354e544a227787cc39bc180cb';

/// Get media statuses (image + video)
///
/// Copied from [mediaStatuses].
@ProviderFor(mediaStatuses)
final mediaStatusesProvider = AutoDisposeProvider<List<StatusModel>>.internal(
  mediaStatuses,
  name: r'mediaStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mediaStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MediaStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$userStatusesHash() => r'c9e9886508895518c29a2a2af462007939671075';

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

/// Get statuses from specific user
///
/// Copied from [userStatuses].
@ProviderFor(userStatuses)
const userStatusesProvider = UserStatusesFamily();

/// Get statuses from specific user
///
/// Copied from [userStatuses].
class UserStatusesFamily extends Family<AsyncValue<List<StatusModel>>> {
  /// Get statuses from specific user
  ///
  /// Copied from [userStatuses].
  const UserStatusesFamily();

  /// Get statuses from specific user
  ///
  /// Copied from [userStatuses].
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

/// Get statuses from specific user
///
/// Copied from [userStatuses].
class UserStatusesProvider
    extends AutoDisposeFutureProvider<List<StatusModel>> {
  /// Get statuses from specific user
  ///
  /// Copied from [userStatuses].
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

String _$filteredStatusesHash() => r'7c9dc494d70d6e092055ab8594a5ea86ff9f8977';

/// Get filtered statuses (search by user name)
///
/// Copied from [filteredStatuses].
@ProviderFor(filteredStatuses)
const filteredStatusesProvider = FilteredStatusesFamily();

/// Get filtered statuses (search by user name)
///
/// Copied from [filteredStatuses].
class FilteredStatusesFamily extends Family<List<StatusModel>> {
  /// Get filtered statuses (search by user name)
  ///
  /// Copied from [filteredStatuses].
  const FilteredStatusesFamily();

  /// Get filtered statuses (search by user name)
  ///
  /// Copied from [filteredStatuses].
  FilteredStatusesProvider call(
    String query,
  ) {
    return FilteredStatusesProvider(
      query,
    );
  }

  @override
  FilteredStatusesProvider getProviderOverride(
    covariant FilteredStatusesProvider provider,
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
  String? get name => r'filteredStatusesProvider';
}

/// Get filtered statuses (search by user name)
///
/// Copied from [filteredStatuses].
class FilteredStatusesProvider extends AutoDisposeProvider<List<StatusModel>> {
  /// Get filtered statuses (search by user name)
  ///
  /// Copied from [filteredStatuses].
  FilteredStatusesProvider(
    String query,
  ) : this._internal(
          (ref) => filteredStatuses(
            ref as FilteredStatusesRef,
            query,
          ),
          from: filteredStatusesProvider,
          name: r'filteredStatusesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filteredStatusesHash,
          dependencies: FilteredStatusesFamily._dependencies,
          allTransitiveDependencies:
              FilteredStatusesFamily._allTransitiveDependencies,
          query: query,
        );

  FilteredStatusesProvider._internal(
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
  Override overrideWith(
    List<StatusModel> Function(FilteredStatusesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredStatusesProvider._internal(
        (ref) => create(ref as FilteredStatusesRef),
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
  AutoDisposeProviderElement<List<StatusModel>> createElement() {
    return _FilteredStatusesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredStatusesProvider && other.query == query;
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
mixin FilteredStatusesRef on AutoDisposeProviderRef<List<StatusModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _FilteredStatusesProviderElement
    extends AutoDisposeProviderElement<List<StatusModel>>
    with FilteredStatusesRef {
  _FilteredStatusesProviderElement(super.provider);

  @override
  String get query => (origin as FilteredStatusesProvider).query;
}

String _$statusByIdHash() => r'b93864be39b9a7f1325e339c803cc58dae890233';

/// Get specific status by ID
///
/// Copied from [statusById].
@ProviderFor(statusById)
const statusByIdProvider = StatusByIdFamily();

/// Get specific status by ID
///
/// Copied from [statusById].
class StatusByIdFamily extends Family<AsyncValue<StatusModel?>> {
  /// Get specific status by ID
  ///
  /// Copied from [statusById].
  const StatusByIdFamily();

  /// Get specific status by ID
  ///
  /// Copied from [statusById].
  StatusByIdProvider call(
    String statusId,
  ) {
    return StatusByIdProvider(
      statusId,
    );
  }

  @override
  StatusByIdProvider getProviderOverride(
    covariant StatusByIdProvider provider,
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
  String? get name => r'statusByIdProvider';
}

/// Get specific status by ID
///
/// Copied from [statusById].
class StatusByIdProvider extends AutoDisposeFutureProvider<StatusModel?> {
  /// Get specific status by ID
  ///
  /// Copied from [statusById].
  StatusByIdProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusById(
            ref as StatusByIdRef,
            statusId,
          ),
          from: statusByIdProvider,
          name: r'statusByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusByIdHash,
          dependencies: StatusByIdFamily._dependencies,
          allTransitiveDependencies:
              StatusByIdFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusByIdProvider._internal(
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
    FutureOr<StatusModel?> Function(StatusByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusByIdProvider._internal(
        (ref) => create(ref as StatusByIdRef),
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
    return _StatusByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusByIdProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusByIdRef on AutoDisposeFutureProviderRef<StatusModel?> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusByIdProviderElement
    extends AutoDisposeFutureProviderElement<StatusModel?> with StatusByIdRef {
  _StatusByIdProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusByIdProvider).statusId;
}

String _$hasViewedStatusHash() => r'51744cb158766631260040941d493254be0dc2e0';

/// Check if status has been viewed
///
/// Copied from [hasViewedStatus].
@ProviderFor(hasViewedStatus)
const hasViewedStatusProvider = HasViewedStatusFamily();

/// Check if status has been viewed
///
/// Copied from [hasViewedStatus].
class HasViewedStatusFamily extends Family<AsyncValue<bool>> {
  /// Check if status has been viewed
  ///
  /// Copied from [hasViewedStatus].
  const HasViewedStatusFamily();

  /// Check if status has been viewed
  ///
  /// Copied from [hasViewedStatus].
  HasViewedStatusProvider call(
    String statusId,
  ) {
    return HasViewedStatusProvider(
      statusId,
    );
  }

  @override
  HasViewedStatusProvider getProviderOverride(
    covariant HasViewedStatusProvider provider,
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
  String? get name => r'hasViewedStatusProvider';
}

/// Check if status has been viewed
///
/// Copied from [hasViewedStatus].
class HasViewedStatusProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if status has been viewed
  ///
  /// Copied from [hasViewedStatus].
  HasViewedStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => hasViewedStatus(
            ref as HasViewedStatusRef,
            statusId,
          ),
          from: hasViewedStatusProvider,
          name: r'hasViewedStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasViewedStatusHash,
          dependencies: HasViewedStatusFamily._dependencies,
          allTransitiveDependencies:
              HasViewedStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  HasViewedStatusProvider._internal(
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
    FutureOr<bool> Function(HasViewedStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasViewedStatusProvider._internal(
        (ref) => create(ref as HasViewedStatusRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasViewedStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasViewedStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HasViewedStatusRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _HasViewedStatusProviderElement
    extends AutoDisposeFutureProviderElement<bool> with HasViewedStatusRef {
  _HasViewedStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as HasViewedStatusProvider).statusId;
}

String _$canViewStatusHash() => r'bd8931c63cfdbdff31e199657cc4de2d65ff3d94';

/// Check if current user can view a status
///
/// Copied from [canViewStatus].
@ProviderFor(canViewStatus)
const canViewStatusProvider = CanViewStatusFamily();

/// Check if current user can view a status
///
/// Copied from [canViewStatus].
class CanViewStatusFamily extends Family<AsyncValue<bool>> {
  /// Check if current user can view a status
  ///
  /// Copied from [canViewStatus].
  const CanViewStatusFamily();

  /// Check if current user can view a status
  ///
  /// Copied from [canViewStatus].
  CanViewStatusProvider call(
    String statusId,
  ) {
    return CanViewStatusProvider(
      statusId,
    );
  }

  @override
  CanViewStatusProvider getProviderOverride(
    covariant CanViewStatusProvider provider,
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
  String? get name => r'canViewStatusProvider';
}

/// Check if current user can view a status
///
/// Copied from [canViewStatus].
class CanViewStatusProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if current user can view a status
  ///
  /// Copied from [canViewStatus].
  CanViewStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => canViewStatus(
            ref as CanViewStatusRef,
            statusId,
          ),
          from: canViewStatusProvider,
          name: r'canViewStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canViewStatusHash,
          dependencies: CanViewStatusFamily._dependencies,
          allTransitiveDependencies:
              CanViewStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  CanViewStatusProvider._internal(
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
    FutureOr<bool> Function(CanViewStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanViewStatusProvider._internal(
        (ref) => create(ref as CanViewStatusRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _CanViewStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanViewStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CanViewStatusRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _CanViewStatusProviderElement
    extends AutoDisposeFutureProviderElement<bool> with CanViewStatusRef {
  _CanViewStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as CanViewStatusProvider).statusId;
}

String _$mutedUsersHash() => r'cff7653d3c4adaf3b17212c5bca2d7df23126ca8';

/// Get list of muted users
///
/// Copied from [mutedUsers].
@ProviderFor(mutedUsers)
final mutedUsersProvider = AutoDisposeProvider<List<String>>.internal(
  mutedUsers,
  name: r'mutedUsersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$mutedUsersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MutedUsersRef = AutoDisposeProviderRef<List<String>>;
String _$isUserMutedHash() => r'f31ddc2c4646fd12ecb75bda14875e40c04f3e87';

/// Check if user is muted
///
/// Copied from [isUserMuted].
@ProviderFor(isUserMuted)
const isUserMutedProvider = IsUserMutedFamily();

/// Check if user is muted
///
/// Copied from [isUserMuted].
class IsUserMutedFamily extends Family<AsyncValue<bool>> {
  /// Check if user is muted
  ///
  /// Copied from [isUserMuted].
  const IsUserMutedFamily();

  /// Check if user is muted
  ///
  /// Copied from [isUserMuted].
  IsUserMutedProvider call(
    String userId,
  ) {
    return IsUserMutedProvider(
      userId,
    );
  }

  @override
  IsUserMutedProvider getProviderOverride(
    covariant IsUserMutedProvider provider,
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
  String? get name => r'isUserMutedProvider';
}

/// Check if user is muted
///
/// Copied from [isUserMuted].
class IsUserMutedProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if user is muted
  ///
  /// Copied from [isUserMuted].
  IsUserMutedProvider(
    String userId,
  ) : this._internal(
          (ref) => isUserMuted(
            ref as IsUserMutedRef,
            userId,
          ),
          from: isUserMutedProvider,
          name: r'isUserMutedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isUserMutedHash,
          dependencies: IsUserMutedFamily._dependencies,
          allTransitiveDependencies:
              IsUserMutedFamily._allTransitiveDependencies,
          userId: userId,
        );

  IsUserMutedProvider._internal(
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
    FutureOr<bool> Function(IsUserMutedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsUserMutedProvider._internal(
        (ref) => create(ref as IsUserMutedRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsUserMutedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserMutedProvider && other.userId == userId;
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
mixin IsUserMutedRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _IsUserMutedProviderElement extends AutoDisposeFutureProviderElement<bool>
    with IsUserMutedRef {
  _IsUserMutedProviderElement(super.provider);

  @override
  String get userId => (origin as IsUserMutedProvider).userId;
}

String _$isUserInMutedListHash() => r'06780f5ede8ab6c54c0e3a5cda7f4a5dab2227f4';

/// Check if user is in muted list (synchronous)
///
/// Copied from [isUserInMutedList].
@ProviderFor(isUserInMutedList)
const isUserInMutedListProvider = IsUserInMutedListFamily();

/// Check if user is in muted list (synchronous)
///
/// Copied from [isUserInMutedList].
class IsUserInMutedListFamily extends Family<bool> {
  /// Check if user is in muted list (synchronous)
  ///
  /// Copied from [isUserInMutedList].
  const IsUserInMutedListFamily();

  /// Check if user is in muted list (synchronous)
  ///
  /// Copied from [isUserInMutedList].
  IsUserInMutedListProvider call(
    String userId,
  ) {
    return IsUserInMutedListProvider(
      userId,
    );
  }

  @override
  IsUserInMutedListProvider getProviderOverride(
    covariant IsUserInMutedListProvider provider,
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
  String? get name => r'isUserInMutedListProvider';
}

/// Check if user is in muted list (synchronous)
///
/// Copied from [isUserInMutedList].
class IsUserInMutedListProvider extends AutoDisposeProvider<bool> {
  /// Check if user is in muted list (synchronous)
  ///
  /// Copied from [isUserInMutedList].
  IsUserInMutedListProvider(
    String userId,
  ) : this._internal(
          (ref) => isUserInMutedList(
            ref as IsUserInMutedListRef,
            userId,
          ),
          from: isUserInMutedListProvider,
          name: r'isUserInMutedListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isUserInMutedListHash,
          dependencies: IsUserInMutedListFamily._dependencies,
          allTransitiveDependencies:
              IsUserInMutedListFamily._allTransitiveDependencies,
          userId: userId,
        );

  IsUserInMutedListProvider._internal(
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
    bool Function(IsUserInMutedListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsUserInMutedListProvider._internal(
        (ref) => create(ref as IsUserInMutedListRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsUserInMutedListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserInMutedListProvider && other.userId == userId;
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
mixin IsUserInMutedListRef on AutoDisposeProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _IsUserInMutedListProviderElement extends AutoDisposeProviderElement<bool>
    with IsUserInMutedListRef {
  _IsUserInMutedListProviderElement(super.provider);

  @override
  String get userId => (origin as IsUserInMutedListProvider).userId;
}

String _$myTotalViewCountHash() => r'0469fe863121edf709db6fd050add0cdf18173b2';

/// Get total view count for current user's statuses
///
/// Copied from [myTotalViewCount].
@ProviderFor(myTotalViewCount)
final myTotalViewCountProvider = AutoDisposeFutureProvider<int>.internal(
  myTotalViewCount,
  name: r'myTotalViewCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myTotalViewCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyTotalViewCountRef = AutoDisposeFutureProviderRef<int>;
String _$userTotalViewCountHash() =>
    r'24ab01c104463f68a195d12c707be8fce432d70a';

/// Get total view count for specific user
///
/// Copied from [userTotalViewCount].
@ProviderFor(userTotalViewCount)
const userTotalViewCountProvider = UserTotalViewCountFamily();

/// Get total view count for specific user
///
/// Copied from [userTotalViewCount].
class UserTotalViewCountFamily extends Family<AsyncValue<int>> {
  /// Get total view count for specific user
  ///
  /// Copied from [userTotalViewCount].
  const UserTotalViewCountFamily();

  /// Get total view count for specific user
  ///
  /// Copied from [userTotalViewCount].
  UserTotalViewCountProvider call(
    String userId,
  ) {
    return UserTotalViewCountProvider(
      userId,
    );
  }

  @override
  UserTotalViewCountProvider getProviderOverride(
    covariant UserTotalViewCountProvider provider,
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
  String? get name => r'userTotalViewCountProvider';
}

/// Get total view count for specific user
///
/// Copied from [userTotalViewCount].
class UserTotalViewCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get total view count for specific user
  ///
  /// Copied from [userTotalViewCount].
  UserTotalViewCountProvider(
    String userId,
  ) : this._internal(
          (ref) => userTotalViewCount(
            ref as UserTotalViewCountRef,
            userId,
          ),
          from: userTotalViewCountProvider,
          name: r'userTotalViewCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userTotalViewCountHash,
          dependencies: UserTotalViewCountFamily._dependencies,
          allTransitiveDependencies:
              UserTotalViewCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserTotalViewCountProvider._internal(
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
    FutureOr<int> Function(UserTotalViewCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserTotalViewCountProvider._internal(
        (ref) => create(ref as UserTotalViewCountRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _UserTotalViewCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserTotalViewCountProvider && other.userId == userId;
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
mixin UserTotalViewCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserTotalViewCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with UserTotalViewCountRef {
  _UserTotalViewCountProviderElement(super.provider);

  @override
  String get userId => (origin as UserTotalViewCountProvider).userId;
}

String _$statusViewCountHash() => r'f026cf03e9b58a0fe78df7cc8087fea2d3d46f53';

/// Get view count for specific status
///
/// Copied from [statusViewCount].
@ProviderFor(statusViewCount)
const statusViewCountProvider = StatusViewCountFamily();

/// Get view count for specific status
///
/// Copied from [statusViewCount].
class StatusViewCountFamily extends Family<AsyncValue<int>> {
  /// Get view count for specific status
  ///
  /// Copied from [statusViewCount].
  const StatusViewCountFamily();

  /// Get view count for specific status
  ///
  /// Copied from [statusViewCount].
  StatusViewCountProvider call(
    String statusId,
  ) {
    return StatusViewCountProvider(
      statusId,
    );
  }

  @override
  StatusViewCountProvider getProviderOverride(
    covariant StatusViewCountProvider provider,
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
  String? get name => r'statusViewCountProvider';
}

/// Get view count for specific status
///
/// Copied from [statusViewCount].
class StatusViewCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get view count for specific status
  ///
  /// Copied from [statusViewCount].
  StatusViewCountProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusViewCount(
            ref as StatusViewCountRef,
            statusId,
          ),
          from: statusViewCountProvider,
          name: r'statusViewCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusViewCountHash,
          dependencies: StatusViewCountFamily._dependencies,
          allTransitiveDependencies:
              StatusViewCountFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusViewCountProvider._internal(
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
    FutureOr<int> Function(StatusViewCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusViewCountProvider._internal(
        (ref) => create(ref as StatusViewCountRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _StatusViewCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusViewCountProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusViewCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusViewCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with StatusViewCountRef {
  _StatusViewCountProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusViewCountProvider).statusId;
}

String _$myMostViewedStatusHash() =>
    r'8831d4427330b2c222390ef2f02542f10fa1f75d';

/// Get most viewed status for current user
///
/// Copied from [myMostViewedStatus].
@ProviderFor(myMostViewedStatus)
final myMostViewedStatusProvider =
    AutoDisposeFutureProvider<StatusModel?>.internal(
  myMostViewedStatus,
  name: r'myMostViewedStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myMostViewedStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyMostViewedStatusRef = AutoDisposeFutureProviderRef<StatusModel?>;
String _$userMostViewedStatusHash() =>
    r'b4b8477537951bd7a4d1e5d89abc84540d221a24';

/// Get most viewed status for specific user
///
/// Copied from [userMostViewedStatus].
@ProviderFor(userMostViewedStatus)
const userMostViewedStatusProvider = UserMostViewedStatusFamily();

/// Get most viewed status for specific user
///
/// Copied from [userMostViewedStatus].
class UserMostViewedStatusFamily extends Family<AsyncValue<StatusModel?>> {
  /// Get most viewed status for specific user
  ///
  /// Copied from [userMostViewedStatus].
  const UserMostViewedStatusFamily();

  /// Get most viewed status for specific user
  ///
  /// Copied from [userMostViewedStatus].
  UserMostViewedStatusProvider call(
    String userId,
  ) {
    return UserMostViewedStatusProvider(
      userId,
    );
  }

  @override
  UserMostViewedStatusProvider getProviderOverride(
    covariant UserMostViewedStatusProvider provider,
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
  String? get name => r'userMostViewedStatusProvider';
}

/// Get most viewed status for specific user
///
/// Copied from [userMostViewedStatus].
class UserMostViewedStatusProvider
    extends AutoDisposeFutureProvider<StatusModel?> {
  /// Get most viewed status for specific user
  ///
  /// Copied from [userMostViewedStatus].
  UserMostViewedStatusProvider(
    String userId,
  ) : this._internal(
          (ref) => userMostViewedStatus(
            ref as UserMostViewedStatusRef,
            userId,
          ),
          from: userMostViewedStatusProvider,
          name: r'userMostViewedStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userMostViewedStatusHash,
          dependencies: UserMostViewedStatusFamily._dependencies,
          allTransitiveDependencies:
              UserMostViewedStatusFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserMostViewedStatusProvider._internal(
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
    FutureOr<StatusModel?> Function(UserMostViewedStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserMostViewedStatusProvider._internal(
        (ref) => create(ref as UserMostViewedStatusRef),
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
  AutoDisposeFutureProviderElement<StatusModel?> createElement() {
    return _UserMostViewedStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMostViewedStatusProvider && other.userId == userId;
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
mixin UserMostViewedStatusRef on AutoDisposeFutureProviderRef<StatusModel?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserMostViewedStatusProviderElement
    extends AutoDisposeFutureProviderElement<StatusModel?>
    with UserMostViewedStatusRef {
  _UserMostViewedStatusProviderElement(super.provider);

  @override
  String get userId => (origin as UserMostViewedStatusProvider).userId;
}

String _$hasActiveStatusesHash() => r'711105884a264c2320f98c906fd7950e8a514352';

/// Check if user has active statuses
///
/// Copied from [hasActiveStatuses].
@ProviderFor(hasActiveStatuses)
const hasActiveStatusesProvider = HasActiveStatusesFamily();

/// Check if user has active statuses
///
/// Copied from [hasActiveStatuses].
class HasActiveStatusesFamily extends Family<AsyncValue<bool>> {
  /// Check if user has active statuses
  ///
  /// Copied from [hasActiveStatuses].
  const HasActiveStatusesFamily();

  /// Check if user has active statuses
  ///
  /// Copied from [hasActiveStatuses].
  HasActiveStatusesProvider call(
    String userId,
  ) {
    return HasActiveStatusesProvider(
      userId,
    );
  }

  @override
  HasActiveStatusesProvider getProviderOverride(
    covariant HasActiveStatusesProvider provider,
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
  String? get name => r'hasActiveStatusesProvider';
}

/// Check if user has active statuses
///
/// Copied from [hasActiveStatuses].
class HasActiveStatusesProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if user has active statuses
  ///
  /// Copied from [hasActiveStatuses].
  HasActiveStatusesProvider(
    String userId,
  ) : this._internal(
          (ref) => hasActiveStatuses(
            ref as HasActiveStatusesRef,
            userId,
          ),
          from: hasActiveStatusesProvider,
          name: r'hasActiveStatusesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasActiveStatusesHash,
          dependencies: HasActiveStatusesFamily._dependencies,
          allTransitiveDependencies:
              HasActiveStatusesFamily._allTransitiveDependencies,
          userId: userId,
        );

  HasActiveStatusesProvider._internal(
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
    FutureOr<bool> Function(HasActiveStatusesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasActiveStatusesProvider._internal(
        (ref) => create(ref as HasActiveStatusesRef),
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
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasActiveStatusesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasActiveStatusesProvider && other.userId == userId;
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
mixin HasActiveStatusesRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _HasActiveStatusesProviderElement
    extends AutoDisposeFutureProviderElement<bool> with HasActiveStatusesRef {
  _HasActiveStatusesProviderElement(super.provider);

  @override
  String get userId => (origin as HasActiveStatusesProvider).userId;
}

String _$activeStatusCountHash() => r'd4c4b7eef5b0f4bd9dd48e3255d7b3bb23870a04';

/// Get active status count for user
///
/// Copied from [activeStatusCount].
@ProviderFor(activeStatusCount)
const activeStatusCountProvider = ActiveStatusCountFamily();

/// Get active status count for user
///
/// Copied from [activeStatusCount].
class ActiveStatusCountFamily extends Family<AsyncValue<int>> {
  /// Get active status count for user
  ///
  /// Copied from [activeStatusCount].
  const ActiveStatusCountFamily();

  /// Get active status count for user
  ///
  /// Copied from [activeStatusCount].
  ActiveStatusCountProvider call(
    String userId,
  ) {
    return ActiveStatusCountProvider(
      userId,
    );
  }

  @override
  ActiveStatusCountProvider getProviderOverride(
    covariant ActiveStatusCountProvider provider,
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
  String? get name => r'activeStatusCountProvider';
}

/// Get active status count for user
///
/// Copied from [activeStatusCount].
class ActiveStatusCountProvider extends AutoDisposeFutureProvider<int> {
  /// Get active status count for user
  ///
  /// Copied from [activeStatusCount].
  ActiveStatusCountProvider(
    String userId,
  ) : this._internal(
          (ref) => activeStatusCount(
            ref as ActiveStatusCountRef,
            userId,
          ),
          from: activeStatusCountProvider,
          name: r'activeStatusCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeStatusCountHash,
          dependencies: ActiveStatusCountFamily._dependencies,
          allTransitiveDependencies:
              ActiveStatusCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  ActiveStatusCountProvider._internal(
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
    FutureOr<int> Function(ActiveStatusCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveStatusCountProvider._internal(
        (ref) => create(ref as ActiveStatusCountRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _ActiveStatusCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveStatusCountProvider && other.userId == userId;
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
mixin ActiveStatusCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ActiveStatusCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with ActiveStatusCountRef {
  _ActiveStatusCountProviderElement(super.provider);

  @override
  String get userId => (origin as ActiveStatusCountProvider).userId;
}

String _$usersWithActiveStatusesHash() =>
    r'35efe15afd0bf588014096e541854c007bcc2129';

/// Get users with active statuses
///
/// Copied from [usersWithActiveStatuses].
@ProviderFor(usersWithActiveStatuses)
final usersWithActiveStatusesProvider =
    AutoDisposeFutureProvider<List<String>>.internal(
  usersWithActiveStatuses,
  name: r'usersWithActiveStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usersWithActiveStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersWithActiveStatusesRef = AutoDisposeFutureProviderRef<List<String>>;
String _$isStatusLoadingHash() => r'5b31f1ebcbd5f120d5f4dd6ad2b5c47b7de0d8a4';

/// Check if statuses are loading
///
/// Copied from [isStatusLoading].
@ProviderFor(isStatusLoading)
final isStatusLoadingProvider = AutoDisposeProvider<bool>.internal(
  isStatusLoading,
  name: r'isStatusLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isStatusLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsStatusLoadingRef = AutoDisposeProviderRef<bool>;
String _$isStatusUploadingHash() => r'48d7018623ba0deae798a6c14460576a19b1db72';

/// Check if status is uploading
///
/// Copied from [isStatusUploading].
@ProviderFor(isStatusUploading)
final isStatusUploadingProvider = AutoDisposeProvider<bool>.internal(
  isStatusUploading,
  name: r'isStatusUploadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isStatusUploadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsStatusUploadingRef = AutoDisposeProviderRef<bool>;
String _$statusUploadProgressHash() =>
    r'49eec1213af388cffe3e5ec97b9056b2a04021a6';

/// Get upload progress
///
/// Copied from [statusUploadProgress].
@ProviderFor(statusUploadProgress)
final statusUploadProgressProvider = AutoDisposeProvider<double>.internal(
  statusUploadProgress,
  name: r'statusUploadProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusUploadProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusUploadProgressRef = AutoDisposeProviderRef<double>;
String _$statusErrorHash() => r'730ad6ae361a30a0b7f326ec8506c5a3f896a265';

/// Get status error if any
///
/// Copied from [statusError].
@ProviderFor(statusError)
final statusErrorProvider = AutoDisposeProvider<String?>.internal(
  statusError,
  name: r'statusErrorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$statusErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusErrorRef = AutoDisposeProviderRef<String?>;
String _$lastStatusSyncHash() => r'5c816d2c81f5e4e6c2ea77b2dcf82a8f376b412f';

/// Get last sync time
///
/// Copied from [lastStatusSync].
@ProviderFor(lastStatusSync)
final lastStatusSyncProvider = AutoDisposeProvider<DateTime?>.internal(
  lastStatusSync,
  name: r'lastStatusSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastStatusSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LastStatusSyncRef = AutoDisposeProviderRef<DateTime?>;
String _$totalStatusCountHash() => r'0459f9e61eed4346f030c92aca8e1126b110c54d';

/// Get total status count
///
/// Copied from [totalStatusCount].
@ProviderFor(totalStatusCount)
final totalStatusCountProvider = AutoDisposeProvider<int>.internal(
  totalStatusCount,
  name: r'totalStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalStatusCountRef = AutoDisposeProviderRef<int>;
String _$totalActiveStatusCountHash() =>
    r'f53762ef2be45971b888476952b429dca30cb478';

/// Get active status count (all users)
///
/// Copied from [totalActiveStatusCount].
@ProviderFor(totalActiveStatusCount)
final totalActiveStatusCountProvider = AutoDisposeProvider<int>.internal(
  totalActiveStatusCount,
  name: r'totalActiveStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalActiveStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalActiveStatusCountRef = AutoDisposeProviderRef<int>;
String _$myStatusCountHash() => r'86586aa2e295724e4d7d8faa5d1a9df4a4bc2ca1';

/// Get my status count
///
/// Copied from [myStatusCount].
@ProviderFor(myStatusCount)
final myStatusCountProvider = AutoDisposeProvider<int>.internal(
  myStatusCount,
  name: r'myStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyStatusCountRef = AutoDisposeProviderRef<int>;
String _$unviewedStatusCountHash() =>
    r'eda394cc797579721cbb7272a8a8398c75df0f5e';

/// Get unviewed status count
///
/// Copied from [unviewedStatusCount].
@ProviderFor(unviewedStatusCount)
final unviewedStatusCountProvider = AutoDisposeProvider<int>.internal(
  unviewedStatusCount,
  name: r'unviewedStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unviewedStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnviewedStatusCountRef = AutoDisposeProviderRef<int>;
String _$imageStatusCountHash() => r'90a6f491581c3cbb3d1e9b8e3d44788bd3289136';

/// Get image status count
///
/// Copied from [imageStatusCount].
@ProviderFor(imageStatusCount)
final imageStatusCountProvider = AutoDisposeProvider<int>.internal(
  imageStatusCount,
  name: r'imageStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$imageStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImageStatusCountRef = AutoDisposeProviderRef<int>;
String _$videoStatusCountHash() => r'ae1a129de4b605bfb80343732769e3025b1c6881';

/// Get video status count
///
/// Copied from [videoStatusCount].
@ProviderFor(videoStatusCount)
final videoStatusCountProvider = AutoDisposeProvider<int>.internal(
  videoStatusCount,
  name: r'videoStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoStatusCountRef = AutoDisposeProviderRef<int>;
String _$textStatusCountHash() => r'2194606450416ee6b923fda6e1607a730062f619';

/// Get text status count
///
/// Copied from [textStatusCount].
@ProviderFor(textStatusCount)
final textStatusCountProvider = AutoDisposeProvider<int>.internal(
  textStatusCount,
  name: r'textStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$textStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TextStatusCountRef = AutoDisposeProviderRef<int>;
String _$mutedUsersCountHash() => r'c28f7ab1152878f103ff066d52445a65d8c18c6c';

/// Get muted users count
///
/// Copied from [mutedUsersCount].
@ProviderFor(mutedUsersCount)
final mutedUsersCountProvider = AutoDisposeProvider<int>.internal(
  mutedUsersCount,
  name: r'mutedUsersCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mutedUsersCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MutedUsersCountRef = AutoDisposeProviderRef<int>;
String _$isImageStatusHash() => r'11f3a87a337c2a668b16c27a556ef849dd141cd6';

/// Check if status is image
///
/// Copied from [isImageStatus].
@ProviderFor(isImageStatus)
const isImageStatusProvider = IsImageStatusFamily();

/// Check if status is image
///
/// Copied from [isImageStatus].
class IsImageStatusFamily extends Family<bool> {
  /// Check if status is image
  ///
  /// Copied from [isImageStatus].
  const IsImageStatusFamily();

  /// Check if status is image
  ///
  /// Copied from [isImageStatus].
  IsImageStatusProvider call(
    String statusId,
  ) {
    return IsImageStatusProvider(
      statusId,
    );
  }

  @override
  IsImageStatusProvider getProviderOverride(
    covariant IsImageStatusProvider provider,
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
  String? get name => r'isImageStatusProvider';
}

/// Check if status is image
///
/// Copied from [isImageStatus].
class IsImageStatusProvider extends AutoDisposeProvider<bool> {
  /// Check if status is image
  ///
  /// Copied from [isImageStatus].
  IsImageStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => isImageStatus(
            ref as IsImageStatusRef,
            statusId,
          ),
          from: isImageStatusProvider,
          name: r'isImageStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isImageStatusHash,
          dependencies: IsImageStatusFamily._dependencies,
          allTransitiveDependencies:
              IsImageStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsImageStatusProvider._internal(
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
    bool Function(IsImageStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsImageStatusProvider._internal(
        (ref) => create(ref as IsImageStatusRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsImageStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsImageStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsImageStatusRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsImageStatusProviderElement extends AutoDisposeProviderElement<bool>
    with IsImageStatusRef {
  _IsImageStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as IsImageStatusProvider).statusId;
}

String _$isVideoStatusHash() => r'ac9e7d0753aaf34c83771b75b1ab0ceb66db5dbf';

/// Check if status is video
///
/// Copied from [isVideoStatus].
@ProviderFor(isVideoStatus)
const isVideoStatusProvider = IsVideoStatusFamily();

/// Check if status is video
///
/// Copied from [isVideoStatus].
class IsVideoStatusFamily extends Family<bool> {
  /// Check if status is video
  ///
  /// Copied from [isVideoStatus].
  const IsVideoStatusFamily();

  /// Check if status is video
  ///
  /// Copied from [isVideoStatus].
  IsVideoStatusProvider call(
    String statusId,
  ) {
    return IsVideoStatusProvider(
      statusId,
    );
  }

  @override
  IsVideoStatusProvider getProviderOverride(
    covariant IsVideoStatusProvider provider,
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
  String? get name => r'isVideoStatusProvider';
}

/// Check if status is video
///
/// Copied from [isVideoStatus].
class IsVideoStatusProvider extends AutoDisposeProvider<bool> {
  /// Check if status is video
  ///
  /// Copied from [isVideoStatus].
  IsVideoStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => isVideoStatus(
            ref as IsVideoStatusRef,
            statusId,
          ),
          from: isVideoStatusProvider,
          name: r'isVideoStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isVideoStatusHash,
          dependencies: IsVideoStatusFamily._dependencies,
          allTransitiveDependencies:
              IsVideoStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsVideoStatusProvider._internal(
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
    bool Function(IsVideoStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsVideoStatusProvider._internal(
        (ref) => create(ref as IsVideoStatusRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsVideoStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsVideoStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsVideoStatusRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsVideoStatusProviderElement extends AutoDisposeProviderElement<bool>
    with IsVideoStatusRef {
  _IsVideoStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as IsVideoStatusProvider).statusId;
}

String _$isTextStatusHash() => r'ecc50e80b35dfcd7f74e02735695b658a287882b';

/// Check if status is text
///
/// Copied from [isTextStatus].
@ProviderFor(isTextStatus)
const isTextStatusProvider = IsTextStatusFamily();

/// Check if status is text
///
/// Copied from [isTextStatus].
class IsTextStatusFamily extends Family<bool> {
  /// Check if status is text
  ///
  /// Copied from [isTextStatus].
  const IsTextStatusFamily();

  /// Check if status is text
  ///
  /// Copied from [isTextStatus].
  IsTextStatusProvider call(
    String statusId,
  ) {
    return IsTextStatusProvider(
      statusId,
    );
  }

  @override
  IsTextStatusProvider getProviderOverride(
    covariant IsTextStatusProvider provider,
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
  String? get name => r'isTextStatusProvider';
}

/// Check if status is text
///
/// Copied from [isTextStatus].
class IsTextStatusProvider extends AutoDisposeProvider<bool> {
  /// Check if status is text
  ///
  /// Copied from [isTextStatus].
  IsTextStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => isTextStatus(
            ref as IsTextStatusRef,
            statusId,
          ),
          from: isTextStatusProvider,
          name: r'isTextStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isTextStatusHash,
          dependencies: IsTextStatusFamily._dependencies,
          allTransitiveDependencies:
              IsTextStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsTextStatusProvider._internal(
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
    bool Function(IsTextStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsTextStatusProvider._internal(
        (ref) => create(ref as IsTextStatusRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsTextStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsTextStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsTextStatusRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsTextStatusProviderElement extends AutoDisposeProviderElement<bool>
    with IsTextStatusRef {
  _IsTextStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as IsTextStatusProvider).statusId;
}

String _$isStatusExpiredHash() => r'a1e9b3443bdbad4b7e3375a1a73e45091a2ff031';

/// Check if status is expired
///
/// Copied from [isStatusExpired].
@ProviderFor(isStatusExpired)
const isStatusExpiredProvider = IsStatusExpiredFamily();

/// Check if status is expired
///
/// Copied from [isStatusExpired].
class IsStatusExpiredFamily extends Family<bool> {
  /// Check if status is expired
  ///
  /// Copied from [isStatusExpired].
  const IsStatusExpiredFamily();

  /// Check if status is expired
  ///
  /// Copied from [isStatusExpired].
  IsStatusExpiredProvider call(
    String statusId,
  ) {
    return IsStatusExpiredProvider(
      statusId,
    );
  }

  @override
  IsStatusExpiredProvider getProviderOverride(
    covariant IsStatusExpiredProvider provider,
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
  String? get name => r'isStatusExpiredProvider';
}

/// Check if status is expired
///
/// Copied from [isStatusExpired].
class IsStatusExpiredProvider extends AutoDisposeProvider<bool> {
  /// Check if status is expired
  ///
  /// Copied from [isStatusExpired].
  IsStatusExpiredProvider(
    String statusId,
  ) : this._internal(
          (ref) => isStatusExpired(
            ref as IsStatusExpiredRef,
            statusId,
          ),
          from: isStatusExpiredProvider,
          name: r'isStatusExpiredProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isStatusExpiredHash,
          dependencies: IsStatusExpiredFamily._dependencies,
          allTransitiveDependencies:
              IsStatusExpiredFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsStatusExpiredProvider._internal(
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
    bool Function(IsStatusExpiredRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsStatusExpiredProvider._internal(
        (ref) => create(ref as IsStatusExpiredRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsStatusExpiredProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsStatusExpiredProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsStatusExpiredRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsStatusExpiredProviderElement extends AutoDisposeProviderElement<bool>
    with IsStatusExpiredRef {
  _IsStatusExpiredProviderElement(super.provider);

  @override
  String get statusId => (origin as IsStatusExpiredProvider).statusId;
}

String _$isStatusActiveHash() => r'4858f658ee5ab2b984fb7fe669198b8b1df12e9d';

/// Check if status is active
///
/// Copied from [isStatusActive].
@ProviderFor(isStatusActive)
const isStatusActiveProvider = IsStatusActiveFamily();

/// Check if status is active
///
/// Copied from [isStatusActive].
class IsStatusActiveFamily extends Family<bool> {
  /// Check if status is active
  ///
  /// Copied from [isStatusActive].
  const IsStatusActiveFamily();

  /// Check if status is active
  ///
  /// Copied from [isStatusActive].
  IsStatusActiveProvider call(
    String statusId,
  ) {
    return IsStatusActiveProvider(
      statusId,
    );
  }

  @override
  IsStatusActiveProvider getProviderOverride(
    covariant IsStatusActiveProvider provider,
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
  String? get name => r'isStatusActiveProvider';
}

/// Check if status is active
///
/// Copied from [isStatusActive].
class IsStatusActiveProvider extends AutoDisposeProvider<bool> {
  /// Check if status is active
  ///
  /// Copied from [isStatusActive].
  IsStatusActiveProvider(
    String statusId,
  ) : this._internal(
          (ref) => isStatusActive(
            ref as IsStatusActiveRef,
            statusId,
          ),
          from: isStatusActiveProvider,
          name: r'isStatusActiveProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isStatusActiveHash,
          dependencies: IsStatusActiveFamily._dependencies,
          allTransitiveDependencies:
              IsStatusActiveFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsStatusActiveProvider._internal(
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
    bool Function(IsStatusActiveRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsStatusActiveProvider._internal(
        (ref) => create(ref as IsStatusActiveRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsStatusActiveProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsStatusActiveProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsStatusActiveRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsStatusActiveProviderElement extends AutoDisposeProviderElement<bool>
    with IsStatusActiveRef {
  _IsStatusActiveProviderElement(super.provider);

  @override
  String get statusId => (origin as IsStatusActiveProvider).statusId;
}

String _$isStatusPublicHash() => r'7ad6c7858ab4c95a071c16c36d00abb76d90eba6';

/// Check if status is public
///
/// Copied from [isStatusPublic].
@ProviderFor(isStatusPublic)
const isStatusPublicProvider = IsStatusPublicFamily();

/// Check if status is public
///
/// Copied from [isStatusPublic].
class IsStatusPublicFamily extends Family<bool> {
  /// Check if status is public
  ///
  /// Copied from [isStatusPublic].
  const IsStatusPublicFamily();

  /// Check if status is public
  ///
  /// Copied from [isStatusPublic].
  IsStatusPublicProvider call(
    String statusId,
  ) {
    return IsStatusPublicProvider(
      statusId,
    );
  }

  @override
  IsStatusPublicProvider getProviderOverride(
    covariant IsStatusPublicProvider provider,
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
  String? get name => r'isStatusPublicProvider';
}

/// Check if status is public
///
/// Copied from [isStatusPublic].
class IsStatusPublicProvider extends AutoDisposeProvider<bool> {
  /// Check if status is public
  ///
  /// Copied from [isStatusPublic].
  IsStatusPublicProvider(
    String statusId,
  ) : this._internal(
          (ref) => isStatusPublic(
            ref as IsStatusPublicRef,
            statusId,
          ),
          from: isStatusPublicProvider,
          name: r'isStatusPublicProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isStatusPublicHash,
          dependencies: IsStatusPublicFamily._dependencies,
          allTransitiveDependencies:
              IsStatusPublicFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsStatusPublicProvider._internal(
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
    bool Function(IsStatusPublicRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsStatusPublicProvider._internal(
        (ref) => create(ref as IsStatusPublicRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsStatusPublicProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsStatusPublicProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsStatusPublicRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsStatusPublicProviderElement extends AutoDisposeProviderElement<bool>
    with IsStatusPublicRef {
  _IsStatusPublicProviderElement(super.provider);

  @override
  String get statusId => (origin as IsStatusPublicProvider).statusId;
}

String _$isStatusContactsOnlyHash() =>
    r'335b62759ee7e9e072dd4d73ce16b50b2d0a79e3';

/// Check if status is contacts only
///
/// Copied from [isStatusContactsOnly].
@ProviderFor(isStatusContactsOnly)
const isStatusContactsOnlyProvider = IsStatusContactsOnlyFamily();

/// Check if status is contacts only
///
/// Copied from [isStatusContactsOnly].
class IsStatusContactsOnlyFamily extends Family<bool> {
  /// Check if status is contacts only
  ///
  /// Copied from [isStatusContactsOnly].
  const IsStatusContactsOnlyFamily();

  /// Check if status is contacts only
  ///
  /// Copied from [isStatusContactsOnly].
  IsStatusContactsOnlyProvider call(
    String statusId,
  ) {
    return IsStatusContactsOnlyProvider(
      statusId,
    );
  }

  @override
  IsStatusContactsOnlyProvider getProviderOverride(
    covariant IsStatusContactsOnlyProvider provider,
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
  String? get name => r'isStatusContactsOnlyProvider';
}

/// Check if status is contacts only
///
/// Copied from [isStatusContactsOnly].
class IsStatusContactsOnlyProvider extends AutoDisposeProvider<bool> {
  /// Check if status is contacts only
  ///
  /// Copied from [isStatusContactsOnly].
  IsStatusContactsOnlyProvider(
    String statusId,
  ) : this._internal(
          (ref) => isStatusContactsOnly(
            ref as IsStatusContactsOnlyRef,
            statusId,
          ),
          from: isStatusContactsOnlyProvider,
          name: r'isStatusContactsOnlyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isStatusContactsOnlyHash,
          dependencies: IsStatusContactsOnlyFamily._dependencies,
          allTransitiveDependencies:
              IsStatusContactsOnlyFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsStatusContactsOnlyProvider._internal(
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
    bool Function(IsStatusContactsOnlyRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsStatusContactsOnlyProvider._internal(
        (ref) => create(ref as IsStatusContactsOnlyRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsStatusContactsOnlyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsStatusContactsOnlyProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsStatusContactsOnlyRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsStatusContactsOnlyProviderElement
    extends AutoDisposeProviderElement<bool> with IsStatusContactsOnlyRef {
  _IsStatusContactsOnlyProviderElement(super.provider);

  @override
  String get statusId => (origin as IsStatusContactsOnlyProvider).statusId;
}

String _$hasStatusPrivacyRestrictionsHash() =>
    r'fd4f8225c94ccef83ed598f20894976b24fc7c70';

/// Check if status has privacy restrictions
///
/// Copied from [hasStatusPrivacyRestrictions].
@ProviderFor(hasStatusPrivacyRestrictions)
const hasStatusPrivacyRestrictionsProvider =
    HasStatusPrivacyRestrictionsFamily();

/// Check if status has privacy restrictions
///
/// Copied from [hasStatusPrivacyRestrictions].
class HasStatusPrivacyRestrictionsFamily extends Family<bool> {
  /// Check if status has privacy restrictions
  ///
  /// Copied from [hasStatusPrivacyRestrictions].
  const HasStatusPrivacyRestrictionsFamily();

  /// Check if status has privacy restrictions
  ///
  /// Copied from [hasStatusPrivacyRestrictions].
  HasStatusPrivacyRestrictionsProvider call(
    String statusId,
  ) {
    return HasStatusPrivacyRestrictionsProvider(
      statusId,
    );
  }

  @override
  HasStatusPrivacyRestrictionsProvider getProviderOverride(
    covariant HasStatusPrivacyRestrictionsProvider provider,
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
  String? get name => r'hasStatusPrivacyRestrictionsProvider';
}

/// Check if status has privacy restrictions
///
/// Copied from [hasStatusPrivacyRestrictions].
class HasStatusPrivacyRestrictionsProvider extends AutoDisposeProvider<bool> {
  /// Check if status has privacy restrictions
  ///
  /// Copied from [hasStatusPrivacyRestrictions].
  HasStatusPrivacyRestrictionsProvider(
    String statusId,
  ) : this._internal(
          (ref) => hasStatusPrivacyRestrictions(
            ref as HasStatusPrivacyRestrictionsRef,
            statusId,
          ),
          from: hasStatusPrivacyRestrictionsProvider,
          name: r'hasStatusPrivacyRestrictionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasStatusPrivacyRestrictionsHash,
          dependencies: HasStatusPrivacyRestrictionsFamily._dependencies,
          allTransitiveDependencies:
              HasStatusPrivacyRestrictionsFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  HasStatusPrivacyRestrictionsProvider._internal(
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
    bool Function(HasStatusPrivacyRestrictionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasStatusPrivacyRestrictionsProvider._internal(
        (ref) => create(ref as HasStatusPrivacyRestrictionsRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _HasStatusPrivacyRestrictionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasStatusPrivacyRestrictionsProvider &&
        other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HasStatusPrivacyRestrictionsRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _HasStatusPrivacyRestrictionsProviderElement
    extends AutoDisposeProviderElement<bool>
    with HasStatusPrivacyRestrictionsRef {
  _HasStatusPrivacyRestrictionsProviderElement(super.provider);

  @override
  String get statusId =>
      (origin as HasStatusPrivacyRestrictionsProvider).statusId;
}

String _$timeUntilExpirationHash() =>
    r'dbaf44dd3ea30bd4d0757c9ac5008f9a77c93047';

/// Get time until expiration for status
///
/// Copied from [timeUntilExpiration].
@ProviderFor(timeUntilExpiration)
const timeUntilExpirationProvider = TimeUntilExpirationFamily();

/// Get time until expiration for status
///
/// Copied from [timeUntilExpiration].
class TimeUntilExpirationFamily extends Family<Duration> {
  /// Get time until expiration for status
  ///
  /// Copied from [timeUntilExpiration].
  const TimeUntilExpirationFamily();

  /// Get time until expiration for status
  ///
  /// Copied from [timeUntilExpiration].
  TimeUntilExpirationProvider call(
    String statusId,
  ) {
    return TimeUntilExpirationProvider(
      statusId,
    );
  }

  @override
  TimeUntilExpirationProvider getProviderOverride(
    covariant TimeUntilExpirationProvider provider,
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
  String? get name => r'timeUntilExpirationProvider';
}

/// Get time until expiration for status
///
/// Copied from [timeUntilExpiration].
class TimeUntilExpirationProvider extends AutoDisposeProvider<Duration> {
  /// Get time until expiration for status
  ///
  /// Copied from [timeUntilExpiration].
  TimeUntilExpirationProvider(
    String statusId,
  ) : this._internal(
          (ref) => timeUntilExpiration(
            ref as TimeUntilExpirationRef,
            statusId,
          ),
          from: timeUntilExpirationProvider,
          name: r'timeUntilExpirationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timeUntilExpirationHash,
          dependencies: TimeUntilExpirationFamily._dependencies,
          allTransitiveDependencies:
              TimeUntilExpirationFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  TimeUntilExpirationProvider._internal(
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
    Duration Function(TimeUntilExpirationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TimeUntilExpirationProvider._internal(
        (ref) => create(ref as TimeUntilExpirationRef),
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
  AutoDisposeProviderElement<Duration> createElement() {
    return _TimeUntilExpirationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimeUntilExpirationProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TimeUntilExpirationRef on AutoDisposeProviderRef<Duration> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _TimeUntilExpirationProviderElement
    extends AutoDisposeProviderElement<Duration> with TimeUntilExpirationRef {
  _TimeUntilExpirationProviderElement(super.provider);

  @override
  String get statusId => (origin as TimeUntilExpirationProvider).statusId;
}

String _$timeRemainingTextHash() => r'0d2d4bb48c3a63bf833438ecaf294e90acd2b397';

/// Get time remaining text for status
///
/// Copied from [timeRemainingText].
@ProviderFor(timeRemainingText)
const timeRemainingTextProvider = TimeRemainingTextFamily();

/// Get time remaining text for status
///
/// Copied from [timeRemainingText].
class TimeRemainingTextFamily extends Family<String> {
  /// Get time remaining text for status
  ///
  /// Copied from [timeRemainingText].
  const TimeRemainingTextFamily();

  /// Get time remaining text for status
  ///
  /// Copied from [timeRemainingText].
  TimeRemainingTextProvider call(
    String statusId,
  ) {
    return TimeRemainingTextProvider(
      statusId,
    );
  }

  @override
  TimeRemainingTextProvider getProviderOverride(
    covariant TimeRemainingTextProvider provider,
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
  String? get name => r'timeRemainingTextProvider';
}

/// Get time remaining text for status
///
/// Copied from [timeRemainingText].
class TimeRemainingTextProvider extends AutoDisposeProvider<String> {
  /// Get time remaining text for status
  ///
  /// Copied from [timeRemainingText].
  TimeRemainingTextProvider(
    String statusId,
  ) : this._internal(
          (ref) => timeRemainingText(
            ref as TimeRemainingTextRef,
            statusId,
          ),
          from: timeRemainingTextProvider,
          name: r'timeRemainingTextProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timeRemainingTextHash,
          dependencies: TimeRemainingTextFamily._dependencies,
          allTransitiveDependencies:
              TimeRemainingTextFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  TimeRemainingTextProvider._internal(
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
    String Function(TimeRemainingTextRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TimeRemainingTextProvider._internal(
        (ref) => create(ref as TimeRemainingTextRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _TimeRemainingTextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimeRemainingTextProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TimeRemainingTextRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _TimeRemainingTextProviderElement
    extends AutoDisposeProviderElement<String> with TimeRemainingTextRef {
  _TimeRemainingTextProviderElement(super.provider);

  @override
  String get statusId => (origin as TimeRemainingTextProvider).statusId;
}

String _$statusTimeAgoHash() => r'6bf20dc348e242ab7a3a19397e85bc2586c4aeb9';

/// Get time ago text for status
///
/// Copied from [statusTimeAgo].
@ProviderFor(statusTimeAgo)
const statusTimeAgoProvider = StatusTimeAgoFamily();

/// Get time ago text for status
///
/// Copied from [statusTimeAgo].
class StatusTimeAgoFamily extends Family<String> {
  /// Get time ago text for status
  ///
  /// Copied from [statusTimeAgo].
  const StatusTimeAgoFamily();

  /// Get time ago text for status
  ///
  /// Copied from [statusTimeAgo].
  StatusTimeAgoProvider call(
    String statusId,
  ) {
    return StatusTimeAgoProvider(
      statusId,
    );
  }

  @override
  StatusTimeAgoProvider getProviderOverride(
    covariant StatusTimeAgoProvider provider,
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
  String? get name => r'statusTimeAgoProvider';
}

/// Get time ago text for status
///
/// Copied from [statusTimeAgo].
class StatusTimeAgoProvider extends AutoDisposeProvider<String> {
  /// Get time ago text for status
  ///
  /// Copied from [statusTimeAgo].
  StatusTimeAgoProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusTimeAgo(
            ref as StatusTimeAgoRef,
            statusId,
          ),
          from: statusTimeAgoProvider,
          name: r'statusTimeAgoProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusTimeAgoHash,
          dependencies: StatusTimeAgoFamily._dependencies,
          allTransitiveDependencies:
              StatusTimeAgoFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusTimeAgoProvider._internal(
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
    String Function(StatusTimeAgoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusTimeAgoProvider._internal(
        (ref) => create(ref as StatusTimeAgoRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _StatusTimeAgoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusTimeAgoProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusTimeAgoRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusTimeAgoProviderElement extends AutoDisposeProviderElement<String>
    with StatusTimeAgoRef {
  _StatusTimeAgoProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusTimeAgoProvider).statusId;
}

String _$statusesGroupedByUserHash() =>
    r'071ba2cbd94501e32b2be53d4562b1cbe9f31024';

/// Get statuses grouped by user
///
/// Copied from [statusesGroupedByUser].
@ProviderFor(statusesGroupedByUser)
final statusesGroupedByUserProvider =
    AutoDisposeProvider<Map<String, List<StatusModel>>>.internal(
  statusesGroupedByUser,
  name: r'statusesGroupedByUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusesGroupedByUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusesGroupedByUserRef
    = AutoDisposeProviderRef<Map<String, List<StatusModel>>>;
String _$usersWithUnviewedStatusesHash() =>
    r'5269990db06ad39d050f5e0c595ef29ea09f6bbf';

/// Get users with unviewed statuses
///
/// Copied from [usersWithUnviewedStatuses].
@ProviderFor(usersWithUnviewedStatuses)
final usersWithUnviewedStatusesProvider =
    AutoDisposeProvider<List<String>>.internal(
  usersWithUnviewedStatuses,
  name: r'usersWithUnviewedStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usersWithUnviewedStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersWithUnviewedStatusesRef = AutoDisposeProviderRef<List<String>>;
String _$unviewedStatusCountPerUserHash() =>
    r'd1fd52815e5f9e58cbae94527bb9e3101e941dc8';

/// Get count of unviewed statuses per user
///
/// Copied from [unviewedStatusCountPerUser].
@ProviderFor(unviewedStatusCountPerUser)
final unviewedStatusCountPerUserProvider =
    AutoDisposeProvider<Map<String, int>>.internal(
  unviewedStatusCountPerUser,
  name: r'unviewedStatusCountPerUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unviewedStatusCountPerUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnviewedStatusCountPerUserRef
    = AutoDisposeProviderRef<Map<String, int>>;
String _$unviewedCountForUserHash() =>
    r'9487d1a22376c741d067dc7491caed9e925eddb3';

/// Get unviewed count for specific user
///
/// Copied from [unviewedCountForUser].
@ProviderFor(unviewedCountForUser)
const unviewedCountForUserProvider = UnviewedCountForUserFamily();

/// Get unviewed count for specific user
///
/// Copied from [unviewedCountForUser].
class UnviewedCountForUserFamily extends Family<int> {
  /// Get unviewed count for specific user
  ///
  /// Copied from [unviewedCountForUser].
  const UnviewedCountForUserFamily();

  /// Get unviewed count for specific user
  ///
  /// Copied from [unviewedCountForUser].
  UnviewedCountForUserProvider call(
    String userId,
  ) {
    return UnviewedCountForUserProvider(
      userId,
    );
  }

  @override
  UnviewedCountForUserProvider getProviderOverride(
    covariant UnviewedCountForUserProvider provider,
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
  String? get name => r'unviewedCountForUserProvider';
}

/// Get unviewed count for specific user
///
/// Copied from [unviewedCountForUser].
class UnviewedCountForUserProvider extends AutoDisposeProvider<int> {
  /// Get unviewed count for specific user
  ///
  /// Copied from [unviewedCountForUser].
  UnviewedCountForUserProvider(
    String userId,
  ) : this._internal(
          (ref) => unviewedCountForUser(
            ref as UnviewedCountForUserRef,
            userId,
          ),
          from: unviewedCountForUserProvider,
          name: r'unviewedCountForUserProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unviewedCountForUserHash,
          dependencies: UnviewedCountForUserFamily._dependencies,
          allTransitiveDependencies:
              UnviewedCountForUserFamily._allTransitiveDependencies,
          userId: userId,
        );

  UnviewedCountForUserProvider._internal(
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
    int Function(UnviewedCountForUserRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnviewedCountForUserProvider._internal(
        (ref) => create(ref as UnviewedCountForUserRef),
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
  AutoDisposeProviderElement<int> createElement() {
    return _UnviewedCountForUserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnviewedCountForUserProvider && other.userId == userId;
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
mixin UnviewedCountForUserRef on AutoDisposeProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UnviewedCountForUserProviderElement
    extends AutoDisposeProviderElement<int> with UnviewedCountForUserRef {
  _UnviewedCountForUserProviderElement(super.provider);

  @override
  String get userId => (origin as UnviewedCountForUserProvider).userId;
}

String _$recentlyPostedStatusesHash() =>
    r'0115e7fa631df237159c24b2e456ae8d457893f3';

/// Get recently posted statuses (last 1 hour)
///
/// Copied from [recentlyPostedStatuses].
@ProviderFor(recentlyPostedStatuses)
final recentlyPostedStatusesProvider =
    AutoDisposeProvider<List<StatusModel>>.internal(
  recentlyPostedStatuses,
  name: r'recentlyPostedStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentlyPostedStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentlyPostedStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$soonExpiringStatusesHash() =>
    r'9aa262eaf926bb0e897bb11da49c8dc06c25a00d';

/// Get soon expiring statuses (expires in less than 1 hour)
///
/// Copied from [soonExpiringStatuses].
@ProviderFor(soonExpiringStatuses)
final soonExpiringStatusesProvider =
    AutoDisposeProvider<List<StatusModel>>.internal(
  soonExpiringStatuses,
  name: r'soonExpiringStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$soonExpiringStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SoonExpiringStatusesRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$mostViewedStatusesHash() =>
    r'e622e6219d70b158f7d35be804f5274f995a4614';

/// Get most viewed statuses (sorted by views)
///
/// Copied from [mostViewedStatuses].
@ProviderFor(mostViewedStatuses)
const mostViewedStatusesProvider = MostViewedStatusesFamily();

/// Get most viewed statuses (sorted by views)
///
/// Copied from [mostViewedStatuses].
class MostViewedStatusesFamily extends Family<List<StatusModel>> {
  /// Get most viewed statuses (sorted by views)
  ///
  /// Copied from [mostViewedStatuses].
  const MostViewedStatusesFamily();

  /// Get most viewed statuses (sorted by views)
  ///
  /// Copied from [mostViewedStatuses].
  MostViewedStatusesProvider call({
    int limit = 10,
  }) {
    return MostViewedStatusesProvider(
      limit: limit,
    );
  }

  @override
  MostViewedStatusesProvider getProviderOverride(
    covariant MostViewedStatusesProvider provider,
  ) {
    return call(
      limit: provider.limit,
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
  String? get name => r'mostViewedStatusesProvider';
}

/// Get most viewed statuses (sorted by views)
///
/// Copied from [mostViewedStatuses].
class MostViewedStatusesProvider
    extends AutoDisposeProvider<List<StatusModel>> {
  /// Get most viewed statuses (sorted by views)
  ///
  /// Copied from [mostViewedStatuses].
  MostViewedStatusesProvider({
    int limit = 10,
  }) : this._internal(
          (ref) => mostViewedStatuses(
            ref as MostViewedStatusesRef,
            limit: limit,
          ),
          from: mostViewedStatusesProvider,
          name: r'mostViewedStatusesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$mostViewedStatusesHash,
          dependencies: MostViewedStatusesFamily._dependencies,
          allTransitiveDependencies:
              MostViewedStatusesFamily._allTransitiveDependencies,
          limit: limit,
        );

  MostViewedStatusesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    List<StatusModel> Function(MostViewedStatusesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MostViewedStatusesProvider._internal(
        (ref) => create(ref as MostViewedStatusesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<StatusModel>> createElement() {
    return _MostViewedStatusesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MostViewedStatusesProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MostViewedStatusesRef on AutoDisposeProviderRef<List<StatusModel>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _MostViewedStatusesProviderElement
    extends AutoDisposeProviderElement<List<StatusModel>>
    with MostViewedStatusesRef {
  _MostViewedStatusesProviderElement(super.provider);

  @override
  int get limit => (origin as MostViewedStatusesProvider).limit;
}

String _$statusesWithViewsHash() => r'c6eb61421ad69019bbec28ef2430329d9d8b8ef8';

/// Get statuses with views
///
/// Copied from [statusesWithViews].
@ProviderFor(statusesWithViews)
final statusesWithViewsProvider =
    AutoDisposeProvider<List<StatusModel>>.internal(
  statusesWithViews,
  name: r'statusesWithViewsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$statusesWithViewsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StatusesWithViewsRef = AutoDisposeProviderRef<List<StatusModel>>;
String _$currentUserHasActiveStatusesHash() =>
    r'a3f0eedc816666ad11227890c495f9d795503fee';

/// Check if current user has active statuses
///
/// Copied from [currentUserHasActiveStatuses].
@ProviderFor(currentUserHasActiveStatuses)
final currentUserHasActiveStatusesProvider =
    AutoDisposeFutureProvider<bool>.internal(
  currentUserHasActiveStatuses,
  name: r'currentUserHasActiveStatusesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHasActiveStatusesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserHasActiveStatusesRef = AutoDisposeFutureProviderRef<bool>;
String _$currentUserActiveStatusCountHash() =>
    r'3f0b1764661caa35a14fdf66626df69168db3f8c';

/// Get current user's active status count
///
/// Copied from [currentUserActiveStatusCount].
@ProviderFor(currentUserActiveStatusCount)
final currentUserActiveStatusCountProvider =
    AutoDisposeFutureProvider<int>.internal(
  currentUserActiveStatusCount,
  name: r'currentUserActiveStatusCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserActiveStatusCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserActiveStatusCountRef = AutoDisposeFutureProviderRef<int>;
String _$isMyStatusHash() => r'eb5034c7282e4da3d015df69ebe2293a21dd81bd';

/// Check if current user owns a status
///
/// Copied from [isMyStatus].
@ProviderFor(isMyStatus)
const isMyStatusProvider = IsMyStatusFamily();

/// Check if current user owns a status
///
/// Copied from [isMyStatus].
class IsMyStatusFamily extends Family<bool> {
  /// Check if current user owns a status
  ///
  /// Copied from [isMyStatus].
  const IsMyStatusFamily();

  /// Check if current user owns a status
  ///
  /// Copied from [isMyStatus].
  IsMyStatusProvider call(
    String statusId,
  ) {
    return IsMyStatusProvider(
      statusId,
    );
  }

  @override
  IsMyStatusProvider getProviderOverride(
    covariant IsMyStatusProvider provider,
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
  String? get name => r'isMyStatusProvider';
}

/// Check if current user owns a status
///
/// Copied from [isMyStatus].
class IsMyStatusProvider extends AutoDisposeProvider<bool> {
  /// Check if current user owns a status
  ///
  /// Copied from [isMyStatus].
  IsMyStatusProvider(
    String statusId,
  ) : this._internal(
          (ref) => isMyStatus(
            ref as IsMyStatusRef,
            statusId,
          ),
          from: isMyStatusProvider,
          name: r'isMyStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isMyStatusHash,
          dependencies: IsMyStatusFamily._dependencies,
          allTransitiveDependencies:
              IsMyStatusFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  IsMyStatusProvider._internal(
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
    bool Function(IsMyStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsMyStatusProvider._internal(
        (ref) => create(ref as IsMyStatusRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _IsMyStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsMyStatusProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsMyStatusRef on AutoDisposeProviderRef<bool> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _IsMyStatusProviderElement extends AutoDisposeProviderElement<bool>
    with IsMyStatusRef {
  _IsMyStatusProviderElement(super.provider);

  @override
  String get statusId => (origin as IsMyStatusProvider).statusId;
}

String _$statusUserNameHash() => r'afe986c64cfc5b316534a67d7e9088f5addac2c6';

/// Get status user name
///
/// Copied from [statusUserName].
@ProviderFor(statusUserName)
const statusUserNameProvider = StatusUserNameFamily();

/// Get status user name
///
/// Copied from [statusUserName].
class StatusUserNameFamily extends Family<String> {
  /// Get status user name
  ///
  /// Copied from [statusUserName].
  const StatusUserNameFamily();

  /// Get status user name
  ///
  /// Copied from [statusUserName].
  StatusUserNameProvider call(
    String statusId,
  ) {
    return StatusUserNameProvider(
      statusId,
    );
  }

  @override
  StatusUserNameProvider getProviderOverride(
    covariant StatusUserNameProvider provider,
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
  String? get name => r'statusUserNameProvider';
}

/// Get status user name
///
/// Copied from [statusUserName].
class StatusUserNameProvider extends AutoDisposeProvider<String> {
  /// Get status user name
  ///
  /// Copied from [statusUserName].
  StatusUserNameProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusUserName(
            ref as StatusUserNameRef,
            statusId,
          ),
          from: statusUserNameProvider,
          name: r'statusUserNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusUserNameHash,
          dependencies: StatusUserNameFamily._dependencies,
          allTransitiveDependencies:
              StatusUserNameFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusUserNameProvider._internal(
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
    String Function(StatusUserNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusUserNameProvider._internal(
        (ref) => create(ref as StatusUserNameRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _StatusUserNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusUserNameProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusUserNameRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusUserNameProviderElement extends AutoDisposeProviderElement<String>
    with StatusUserNameRef {
  _StatusUserNameProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusUserNameProvider).statusId;
}

String _$statusUserImageHash() => r'3e7bde2d63cc7ee07fd344b8030c9c97aba5aecc';

/// Get status user image
///
/// Copied from [statusUserImage].
@ProviderFor(statusUserImage)
const statusUserImageProvider = StatusUserImageFamily();

/// Get status user image
///
/// Copied from [statusUserImage].
class StatusUserImageFamily extends Family<String> {
  /// Get status user image
  ///
  /// Copied from [statusUserImage].
  const StatusUserImageFamily();

  /// Get status user image
  ///
  /// Copied from [statusUserImage].
  StatusUserImageProvider call(
    String statusId,
  ) {
    return StatusUserImageProvider(
      statusId,
    );
  }

  @override
  StatusUserImageProvider getProviderOverride(
    covariant StatusUserImageProvider provider,
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
  String? get name => r'statusUserImageProvider';
}

/// Get status user image
///
/// Copied from [statusUserImage].
class StatusUserImageProvider extends AutoDisposeProvider<String> {
  /// Get status user image
  ///
  /// Copied from [statusUserImage].
  StatusUserImageProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusUserImage(
            ref as StatusUserImageRef,
            statusId,
          ),
          from: statusUserImageProvider,
          name: r'statusUserImageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusUserImageHash,
          dependencies: StatusUserImageFamily._dependencies,
          allTransitiveDependencies:
              StatusUserImageFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusUserImageProvider._internal(
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
    String Function(StatusUserImageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusUserImageProvider._internal(
        (ref) => create(ref as StatusUserImageRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _StatusUserImageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusUserImageProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusUserImageRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusUserImageProviderElement extends AutoDisposeProviderElement<String>
    with StatusUserImageRef {
  _StatusUserImageProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusUserImageProvider).statusId;
}

String _$statusCaptionHash() => r'cdbe8a997beb9bd33fe3b3ff96fc3ffb32ba8f13';

/// Get status caption
///
/// Copied from [statusCaption].
@ProviderFor(statusCaption)
const statusCaptionProvider = StatusCaptionFamily();

/// Get status caption
///
/// Copied from [statusCaption].
class StatusCaptionFamily extends Family<String?> {
  /// Get status caption
  ///
  /// Copied from [statusCaption].
  const StatusCaptionFamily();

  /// Get status caption
  ///
  /// Copied from [statusCaption].
  StatusCaptionProvider call(
    String statusId,
  ) {
    return StatusCaptionProvider(
      statusId,
    );
  }

  @override
  StatusCaptionProvider getProviderOverride(
    covariant StatusCaptionProvider provider,
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
  String? get name => r'statusCaptionProvider';
}

/// Get status caption
///
/// Copied from [statusCaption].
class StatusCaptionProvider extends AutoDisposeProvider<String?> {
  /// Get status caption
  ///
  /// Copied from [statusCaption].
  StatusCaptionProvider(
    String statusId,
  ) : this._internal(
          (ref) => statusCaption(
            ref as StatusCaptionRef,
            statusId,
          ),
          from: statusCaptionProvider,
          name: r'statusCaptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$statusCaptionHash,
          dependencies: StatusCaptionFamily._dependencies,
          allTransitiveDependencies:
              StatusCaptionFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  StatusCaptionProvider._internal(
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
    String? Function(StatusCaptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StatusCaptionProvider._internal(
        (ref) => create(ref as StatusCaptionRef),
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
  AutoDisposeProviderElement<String?> createElement() {
    return _StatusCaptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StatusCaptionProvider && other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StatusCaptionRef on AutoDisposeProviderRef<String?> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _StatusCaptionProviderElement extends AutoDisposeProviderElement<String?>
    with StatusCaptionRef {
  _StatusCaptionProviderElement(super.provider);

  @override
  String get statusId => (origin as StatusCaptionProvider).statusId;
}

String _$formattedStatusDurationHash() =>
    r'3209c7be6d55e7008bc57779dbe2138119c081ce';

/// Get formatted duration for video status
///
/// Copied from [formattedStatusDuration].
@ProviderFor(formattedStatusDuration)
const formattedStatusDurationProvider = FormattedStatusDurationFamily();

/// Get formatted duration for video status
///
/// Copied from [formattedStatusDuration].
class FormattedStatusDurationFamily extends Family<String> {
  /// Get formatted duration for video status
  ///
  /// Copied from [formattedStatusDuration].
  const FormattedStatusDurationFamily();

  /// Get formatted duration for video status
  ///
  /// Copied from [formattedStatusDuration].
  FormattedStatusDurationProvider call(
    String statusId,
  ) {
    return FormattedStatusDurationProvider(
      statusId,
    );
  }

  @override
  FormattedStatusDurationProvider getProviderOverride(
    covariant FormattedStatusDurationProvider provider,
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
  String? get name => r'formattedStatusDurationProvider';
}

/// Get formatted duration for video status
///
/// Copied from [formattedStatusDuration].
class FormattedStatusDurationProvider extends AutoDisposeProvider<String> {
  /// Get formatted duration for video status
  ///
  /// Copied from [formattedStatusDuration].
  FormattedStatusDurationProvider(
    String statusId,
  ) : this._internal(
          (ref) => formattedStatusDuration(
            ref as FormattedStatusDurationRef,
            statusId,
          ),
          from: formattedStatusDurationProvider,
          name: r'formattedStatusDurationProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formattedStatusDurationHash,
          dependencies: FormattedStatusDurationFamily._dependencies,
          allTransitiveDependencies:
              FormattedStatusDurationFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  FormattedStatusDurationProvider._internal(
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
    String Function(FormattedStatusDurationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FormattedStatusDurationProvider._internal(
        (ref) => create(ref as FormattedStatusDurationRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _FormattedStatusDurationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormattedStatusDurationProvider &&
        other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FormattedStatusDurationRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _FormattedStatusDurationProviderElement
    extends AutoDisposeProviderElement<String> with FormattedStatusDurationRef {
  _FormattedStatusDurationProviderElement(super.provider);

  @override
  String get statusId => (origin as FormattedStatusDurationProvider).statusId;
}

String _$formattedStatusFileSizeHash() =>
    r'856fb0a4d37b58df73e4747d3aaaadf71274957b';

/// Get formatted file size
///
/// Copied from [formattedStatusFileSize].
@ProviderFor(formattedStatusFileSize)
const formattedStatusFileSizeProvider = FormattedStatusFileSizeFamily();

/// Get formatted file size
///
/// Copied from [formattedStatusFileSize].
class FormattedStatusFileSizeFamily extends Family<String> {
  /// Get formatted file size
  ///
  /// Copied from [formattedStatusFileSize].
  const FormattedStatusFileSizeFamily();

  /// Get formatted file size
  ///
  /// Copied from [formattedStatusFileSize].
  FormattedStatusFileSizeProvider call(
    String statusId,
  ) {
    return FormattedStatusFileSizeProvider(
      statusId,
    );
  }

  @override
  FormattedStatusFileSizeProvider getProviderOverride(
    covariant FormattedStatusFileSizeProvider provider,
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
  String? get name => r'formattedStatusFileSizeProvider';
}

/// Get formatted file size
///
/// Copied from [formattedStatusFileSize].
class FormattedStatusFileSizeProvider extends AutoDisposeProvider<String> {
  /// Get formatted file size
  ///
  /// Copied from [formattedStatusFileSize].
  FormattedStatusFileSizeProvider(
    String statusId,
  ) : this._internal(
          (ref) => formattedStatusFileSize(
            ref as FormattedStatusFileSizeRef,
            statusId,
          ),
          from: formattedStatusFileSizeProvider,
          name: r'formattedStatusFileSizeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formattedStatusFileSizeHash,
          dependencies: FormattedStatusFileSizeFamily._dependencies,
          allTransitiveDependencies:
              FormattedStatusFileSizeFamily._allTransitiveDependencies,
          statusId: statusId,
        );

  FormattedStatusFileSizeProvider._internal(
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
    String Function(FormattedStatusFileSizeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FormattedStatusFileSizeProvider._internal(
        (ref) => create(ref as FormattedStatusFileSizeRef),
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
  AutoDisposeProviderElement<String> createElement() {
    return _FormattedStatusFileSizeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormattedStatusFileSizeProvider &&
        other.statusId == statusId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, statusId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FormattedStatusFileSizeRef on AutoDisposeProviderRef<String> {
  /// The parameter `statusId` of this provider.
  String get statusId;
}

class _FormattedStatusFileSizeProviderElement
    extends AutoDisposeProviderElement<String> with FormattedStatusFileSizeRef {
  _FormattedStatusFileSizeProviderElement(super.provider);

  @override
  String get statusId => (origin as FormattedStatusFileSizeProvider).statusId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
