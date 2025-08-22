// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userGroupedMomentsStreamHash() =>
    r'8a3b2f1c9d7e5a4b6c8d9e0f1a2b3c4d5e6f7a8b';

/// See also [userGroupedMomentsStream].
@ProviderFor(userGroupedMomentsStream)
final userGroupedMomentsStreamProvider =
    AutoDisposeStreamProvider<List<UserMomentGroup>>.internal(
  userGroupedMomentsStream,
  name: r'userGroupedMomentsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userGroupedMomentsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserGroupedMomentsStreamRef
    = AutoDisposeStreamProviderRef<List<UserMomentGroup>>;
String _$momentsFeedStreamHash() => r'701d73e3a8db93044bfa17879bc4e0393bd86f54';

/// See also [momentsFeedStream].
@ProviderFor(momentsFeedStream)
final momentsFeedStreamProvider =
    AutoDisposeStreamProvider<List<MomentModel>>.internal(
  momentsFeedStream,
  name: r'momentsFeedStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsFeedStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MomentsFeedStreamRef = AutoDisposeStreamProviderRef<List<MomentModel>>;
String _$userMomentsStreamHash() => r'7932fde95299508073c9c3ce9f56c838bc846182';

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

/// See also [userMomentsStream].
@ProviderFor(userMomentsStream)
const userMomentsStreamProvider = UserMomentsStreamFamily();

/// See also [userMomentsStream].
class UserMomentsStreamFamily extends Family<AsyncValue<List<MomentModel>>> {
  /// See also [userMomentsStream].
  const UserMomentsStreamFamily();

  /// See also [userMomentsStream].
  UserMomentsStreamProvider call(
    String userId,
  ) {
    return UserMomentsStreamProvider(
      userId,
    );
  }

  @override
  UserMomentsStreamProvider getProviderOverride(
    covariant UserMomentsStreamProvider provider,
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
  String? get name => r'userMomentsStreamProvider';
}

/// See also [userMomentsStream].
class UserMomentsStreamProvider
    extends AutoDisposeStreamProvider<List<MomentModel>> {
  /// See also [userMomentsStream].
  UserMomentsStreamProvider(
    String userId,
  ) : this._internal(
          (ref) => userMomentsStream(
            ref as UserMomentsStreamRef,
            userId,
          ),
          from: userMomentsStreamProvider,
          name: r'userMomentsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userMomentsStreamHash,
          dependencies: UserMomentsStreamFamily._dependencies,
          allTransitiveDependencies:
              UserMomentsStreamFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserMomentsStreamProvider._internal(
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
    Stream<List<MomentModel>> Function(UserMomentsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserMomentsStreamProvider._internal(
        (ref) => create(ref as UserMomentsStreamRef),
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
  AutoDisposeStreamProviderElement<List<MomentModel>> createElement() {
    return _UserMomentsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMomentsStreamProvider && other.userId == userId;
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
mixin UserMomentsStreamRef on AutoDisposeStreamProviderRef<List<MomentModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserMomentsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MomentModel>>
    with UserMomentsStreamRef {
  _UserMomentsStreamProviderElement(super.provider);

  @override
  String get userId => (origin as UserMomentsStreamProvider).userId;
}

String _$momentCommentsStreamHash() =>
    r'7a6e0dd3717468887874639840d2aa53aaf75a20';

/// See also [momentCommentsStream].
@ProviderFor(momentCommentsStream)
const momentCommentsStreamProvider = MomentCommentsStreamFamily();

/// See also [momentCommentsStream].
class MomentCommentsStreamFamily
    extends Family<AsyncValue<List<MomentCommentModel>>> {
  /// See also [momentCommentsStream].
  const MomentCommentsStreamFamily();

  /// See also [momentCommentsStream].
  MomentCommentsStreamProvider call(
    String momentId,
  ) {
    return MomentCommentsStreamProvider(
      momentId,
    );
  }

  @override
  MomentCommentsStreamProvider getProviderOverride(
    covariant MomentCommentsStreamProvider provider,
  ) {
    return call(
      provider.momentId,
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
  String? get name => r'momentCommentsStreamProvider';
}

/// See also [momentCommentsStream].
class MomentCommentsStreamProvider
    extends AutoDisposeStreamProvider<List<MomentCommentModel>> {
  /// See also [momentCommentsStream].
  MomentCommentsStreamProvider(
    String momentId,
  ) : this._internal(
          (ref) => momentCommentsStream(
            ref as MomentCommentsStreamRef,
            momentId,
          ),
          from: momentCommentsStreamProvider,
          name: r'momentCommentsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$momentCommentsStreamHash,
          dependencies: MomentCommentsStreamFamily._dependencies,
          allTransitiveDependencies:
              MomentCommentsStreamFamily._allTransitiveDependencies,
          momentId: momentId,
        );

  MomentCommentsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.momentId,
  }) : super.internal();

  final String momentId;

  @override
  Override overrideWith(
    Stream<List<MomentCommentModel>> Function(MomentCommentsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MomentCommentsStreamProvider._internal(
        (ref) => create(ref as MomentCommentsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        momentId: momentId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MomentCommentModel>> createElement() {
    return _MomentCommentsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentCommentsStreamProvider && other.momentId == momentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, momentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MomentCommentsStreamRef
    on AutoDisposeStreamProviderRef<List<MomentCommentModel>> {
  /// The parameter `momentId` of this provider.
  String get momentId;
}

class _MomentCommentsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MomentCommentModel>>
    with MomentCommentsStreamRef {
  _MomentCommentsStreamProviderElement(super.provider);

  @override
  String get momentId => (origin as MomentCommentsStreamProvider).momentId;
}

String _$momentsHash() => r'b35c1c70ac62cd533876b7d0b3c4e58d88576ae4';

/// See also [Moments].
@ProviderFor(Moments)
final momentsProvider =
    AutoDisposeNotifierProvider<Moments, MomentsState>.internal(
  Moments.new,
  name: r'momentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$momentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Moments = AutoDisposeNotifier<MomentsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package