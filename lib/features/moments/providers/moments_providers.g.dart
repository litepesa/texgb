// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$momentsRepositoryHash() => r'ba76cd86ab00e2dd23f66c3bf2e345ada8c23358';

/// See also [momentsRepository].
@ProviderFor(momentsRepository)
final momentsRepositoryProvider =
    AutoDisposeProvider<MomentsRepository>.internal(
  momentsRepository,
  name: r'momentsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MomentsRepositoryRef = AutoDisposeProviderRef<MomentsRepository>;
String _$momentHash() => r'dc556ba3707d18d73034ee0a945f51e4e4b35df4';

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

/// See also [moment].
@ProviderFor(moment)
const momentProvider = MomentFamily();

/// See also [moment].
class MomentFamily extends Family<AsyncValue<MomentModel?>> {
  /// See also [moment].
  const MomentFamily();

  /// See also [moment].
  MomentProvider call(
    String momentId,
  ) {
    return MomentProvider(
      momentId,
    );
  }

  @override
  MomentProvider getProviderOverride(
    covariant MomentProvider provider,
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
  String? get name => r'momentProvider';
}

/// See also [moment].
class MomentProvider extends AutoDisposeFutureProvider<MomentModel?> {
  /// See also [moment].
  MomentProvider(
    String momentId,
  ) : this._internal(
          (ref) => moment(
            ref as MomentRef,
            momentId,
          ),
          from: momentProvider,
          name: r'momentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$momentHash,
          dependencies: MomentFamily._dependencies,
          allTransitiveDependencies: MomentFamily._allTransitiveDependencies,
          momentId: momentId,
        );

  MomentProvider._internal(
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
    FutureOr<MomentModel?> Function(MomentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MomentProvider._internal(
        (ref) => create(ref as MomentRef),
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
  AutoDisposeFutureProviderElement<MomentModel?> createElement() {
    return _MomentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentProvider && other.momentId == momentId;
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
mixin MomentRef on AutoDisposeFutureProviderRef<MomentModel?> {
  /// The parameter `momentId` of this provider.
  String get momentId;
}

class _MomentProviderElement
    extends AutoDisposeFutureProviderElement<MomentModel?> with MomentRef {
  _MomentProviderElement(super.provider);

  @override
  String get momentId => (origin as MomentProvider).momentId;
}

String _$momentLikesHash() => r'4a9899abce16e5af86deb2d9ef2e988b869cbbda';

/// See also [momentLikes].
@ProviderFor(momentLikes)
const momentLikesProvider = MomentLikesFamily();

/// See also [momentLikes].
class MomentLikesFamily extends Family<AsyncValue<List<MomentLikerModel>>> {
  /// See also [momentLikes].
  const MomentLikesFamily();

  /// See also [momentLikes].
  MomentLikesProvider call(
    String momentId,
  ) {
    return MomentLikesProvider(
      momentId,
    );
  }

  @override
  MomentLikesProvider getProviderOverride(
    covariant MomentLikesProvider provider,
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
  String? get name => r'momentLikesProvider';
}

/// See also [momentLikes].
class MomentLikesProvider
    extends AutoDisposeFutureProvider<List<MomentLikerModel>> {
  /// See also [momentLikes].
  MomentLikesProvider(
    String momentId,
  ) : this._internal(
          (ref) => momentLikes(
            ref as MomentLikesRef,
            momentId,
          ),
          from: momentLikesProvider,
          name: r'momentLikesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$momentLikesHash,
          dependencies: MomentLikesFamily._dependencies,
          allTransitiveDependencies:
              MomentLikesFamily._allTransitiveDependencies,
          momentId: momentId,
        );

  MomentLikesProvider._internal(
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
    FutureOr<List<MomentLikerModel>> Function(MomentLikesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MomentLikesProvider._internal(
        (ref) => create(ref as MomentLikesRef),
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
  AutoDisposeFutureProviderElement<List<MomentLikerModel>> createElement() {
    return _MomentLikesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentLikesProvider && other.momentId == momentId;
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
mixin MomentLikesRef on AutoDisposeFutureProviderRef<List<MomentLikerModel>> {
  /// The parameter `momentId` of this provider.
  String get momentId;
}

class _MomentLikesProviderElement
    extends AutoDisposeFutureProviderElement<List<MomentLikerModel>>
    with MomentLikesRef {
  _MomentLikesProviderElement(super.provider);

  @override
  String get momentId => (origin as MomentLikesProvider).momentId;
}

String _$momentsFeedHash() => r'eab5312ffbcf8a9ab3f6a83c0c1437208e210816';

/// See also [MomentsFeed].
@ProviderFor(MomentsFeed)
final momentsFeedProvider =
    AutoDisposeAsyncNotifierProvider<MomentsFeed, MomentsFeedState>.internal(
  MomentsFeed.new,
  name: r'momentsFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$momentsFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MomentsFeed = AutoDisposeAsyncNotifier<MomentsFeedState>;
String _$userMomentsHash() => r'0b0266199b3676e6a3bc86835276173a8c8ad5d5';

abstract class _$UserMoments
    extends BuildlessAutoDisposeAsyncNotifier<List<MomentModel>> {
  late final String userId;

  FutureOr<List<MomentModel>> build(
    String userId,
  );
}

/// See also [UserMoments].
@ProviderFor(UserMoments)
const userMomentsProvider = UserMomentsFamily();

/// See also [UserMoments].
class UserMomentsFamily extends Family<AsyncValue<List<MomentModel>>> {
  /// See also [UserMoments].
  const UserMomentsFamily();

  /// See also [UserMoments].
  UserMomentsProvider call(
    String userId,
  ) {
    return UserMomentsProvider(
      userId,
    );
  }

  @override
  UserMomentsProvider getProviderOverride(
    covariant UserMomentsProvider provider,
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
  String? get name => r'userMomentsProvider';
}

/// See also [UserMoments].
class UserMomentsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    UserMoments, List<MomentModel>> {
  /// See also [UserMoments].
  UserMomentsProvider(
    String userId,
  ) : this._internal(
          () => UserMoments()..userId = userId,
          from: userMomentsProvider,
          name: r'userMomentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userMomentsHash,
          dependencies: UserMomentsFamily._dependencies,
          allTransitiveDependencies:
              UserMomentsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserMomentsProvider._internal(
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
  FutureOr<List<MomentModel>> runNotifierBuild(
    covariant UserMoments notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserMoments Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserMomentsProvider._internal(
        () => create()..userId = userId,
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
  AutoDisposeAsyncNotifierProviderElement<UserMoments, List<MomentModel>>
      createElement() {
    return _UserMomentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMomentsProvider && other.userId == userId;
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
mixin UserMomentsRef on AutoDisposeAsyncNotifierProviderRef<List<MomentModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserMomentsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UserMoments,
        List<MomentModel>> with UserMomentsRef {
  _UserMomentsProviderElement(super.provider);

  @override
  String get userId => (origin as UserMomentsProvider).userId;
}

String _$momentCommentsHash() => r'3aed108367b844af9829cfc09028ed3305ed2a69';

abstract class _$MomentComments
    extends BuildlessAutoDisposeAsyncNotifier<List<MomentCommentModel>> {
  late final String momentId;

  FutureOr<List<MomentCommentModel>> build(
    String momentId,
  );
}

/// See also [MomentComments].
@ProviderFor(MomentComments)
const momentCommentsProvider = MomentCommentsFamily();

/// See also [MomentComments].
class MomentCommentsFamily
    extends Family<AsyncValue<List<MomentCommentModel>>> {
  /// See also [MomentComments].
  const MomentCommentsFamily();

  /// See also [MomentComments].
  MomentCommentsProvider call(
    String momentId,
  ) {
    return MomentCommentsProvider(
      momentId,
    );
  }

  @override
  MomentCommentsProvider getProviderOverride(
    covariant MomentCommentsProvider provider,
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
  String? get name => r'momentCommentsProvider';
}

/// See also [MomentComments].
class MomentCommentsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MomentComments, List<MomentCommentModel>> {
  /// See also [MomentComments].
  MomentCommentsProvider(
    String momentId,
  ) : this._internal(
          () => MomentComments()..momentId = momentId,
          from: momentCommentsProvider,
          name: r'momentCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$momentCommentsHash,
          dependencies: MomentCommentsFamily._dependencies,
          allTransitiveDependencies:
              MomentCommentsFamily._allTransitiveDependencies,
          momentId: momentId,
        );

  MomentCommentsProvider._internal(
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
  FutureOr<List<MomentCommentModel>> runNotifierBuild(
    covariant MomentComments notifier,
  ) {
    return notifier.build(
      momentId,
    );
  }

  @override
  Override overrideWith(MomentComments Function() create) {
    return ProviderOverride(
      origin: this,
      override: MomentCommentsProvider._internal(
        () => create()..momentId = momentId,
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
  AutoDisposeAsyncNotifierProviderElement<MomentComments,
      List<MomentCommentModel>> createElement() {
    return _MomentCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentCommentsProvider && other.momentId == momentId;
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
mixin MomentCommentsRef
    on AutoDisposeAsyncNotifierProviderRef<List<MomentCommentModel>> {
  /// The parameter `momentId` of this provider.
  String get momentId;
}

class _MomentCommentsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MomentComments,
        List<MomentCommentModel>> with MomentCommentsRef {
  _MomentCommentsProviderElement(super.provider);

  @override
  String get momentId => (origin as MomentCommentsProvider).momentId;
}

String _$momentPrivacyHash() => r'afb33acb68ee38c3b62b2905380f012b842a4c29';

/// See also [MomentPrivacy].
@ProviderFor(MomentPrivacy)
final momentPrivacyProvider = AutoDisposeAsyncNotifierProvider<MomentPrivacy,
    MomentPrivacySettings?>.internal(
  MomentPrivacy.new,
  name: r'momentPrivacyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentPrivacyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MomentPrivacy = AutoDisposeAsyncNotifier<MomentPrivacySettings?>;
String _$createMomentHash() => r'f52180d3d06400fef7874a3cdcacd6d8b88e2acb';

/// See also [CreateMoment].
@ProviderFor(CreateMoment)
final createMomentProvider =
    AutoDisposeAsyncNotifierProvider<CreateMoment, MomentModel?>.internal(
  CreateMoment.new,
  name: r'createMomentProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$createMomentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateMoment = AutoDisposeAsyncNotifier<MomentModel?>;
String _$deleteMomentHash() => r'709cf7e0c12f2604f7d76a5259b5ea6cf58d54ad';

/// See also [DeleteMoment].
@ProviderFor(DeleteMoment)
final deleteMomentProvider =
    AutoDisposeAsyncNotifierProvider<DeleteMoment, bool>.internal(
  DeleteMoment.new,
  name: r'deleteMomentProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$deleteMomentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeleteMoment = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
