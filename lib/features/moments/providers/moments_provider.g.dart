// lib/features/moments/providers/moments_provider.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$momentsFeedStreamHash() => r'b5f2e1a8c9d4f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2';

/// See also [momentsFeedStream].
@ProviderFor(momentsFeedStream)
final momentsFeedStreamProvider = AutoDisposeStreamProvider<List<MomentModel>>.internal(
  momentsFeedStream,
  name: r'momentsFeedStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$momentsFeedStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MomentsFeedStreamRef = AutoDisposeStreamProviderRef<List<MomentModel>>;
String _$userMomentsStreamHash() => r'c6d7e8f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9a0b1c2d3e4f5g6h7i8';

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

String _$momentCommentsStreamHash() => r'd7e8f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9a0b1c2d3e4f5g6h7i8j9';

/// See also [momentCommentsStream].
@ProviderFor(momentCommentsStream)
const momentCommentsStreamProvider = MomentCommentsStreamFamily();

/// See also [momentCommentsStream].
class MomentCommentsStreamFamily extends Family<AsyncValue<List<MomentCommentModel>>> {
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
    Stream<List<MomentCommentModel>> Function(MomentCommentsStreamRef provider) create,
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

mixin MomentCommentsStreamRef on AutoDisposeStreamProviderRef<List<MomentCommentModel>> {
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

String _$momentsHash() => r'e8f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9a0b1c2d3e4f5g6h7i8j9k0';

/// See also [Moments].
@ProviderFor(Moments)
final momentsProvider = AutoDisposeNotifierProvider<Moments, MomentsState>.internal(
  Moments.new,
  name: r'momentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$momentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Moments = AutoDisposeNotifier<MomentsState>;

String _$momentCommentsHash() => r'f9g0h1i2j3k4l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9a0b1c2d3e4f5g6h7i8j9k0l1';

/// See also [MomentComments].
@ProviderFor(MomentComments)
const momentCommentsProvider = MomentCommentsFamily();

/// See also [MomentComments].
class MomentCommentsFamily extends Family<List<MomentCommentModel>> {
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
class MomentCommentsProvider
    extends AutoDisposeNotifierProvider<MomentComments, List<MomentCommentModel>> {
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
  MomentComments create() => MomentComments()..momentId = momentId;

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

typedef _$MomentComments = AutoDisposeNotifier<List<MomentCommentModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package