// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userPublicGroupsStreamHash() =>
    r'6ca7acf386f584629a3c1caa0558245825c4eaf1';

/// See also [userPublicGroupsStream].
@ProviderFor(userPublicGroupsStream)
final userPublicGroupsStreamProvider =
    AutoDisposeStreamProvider<List<PublicGroupModel>>.internal(
  userPublicGroupsStream,
  name: r'userPublicGroupsStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userPublicGroupsStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPublicGroupsStreamRef
    = AutoDisposeStreamProviderRef<List<PublicGroupModel>>;
String _$publicGroupPostsStreamHash() =>
    r'e224e6839441099fc39e1764b78fbb0998064a38';

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

/// See also [publicGroupPostsStream].
@ProviderFor(publicGroupPostsStream)
const publicGroupPostsStreamProvider = PublicGroupPostsStreamFamily();

/// See also [publicGroupPostsStream].
class PublicGroupPostsStreamFamily
    extends Family<AsyncValue<List<PublicGroupPostModel>>> {
  /// See also [publicGroupPostsStream].
  const PublicGroupPostsStreamFamily();

  /// See also [publicGroupPostsStream].
  PublicGroupPostsStreamProvider call(
    String groupId,
  ) {
    return PublicGroupPostsStreamProvider(
      groupId,
    );
  }

  @override
  PublicGroupPostsStreamProvider getProviderOverride(
    covariant PublicGroupPostsStreamProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'publicGroupPostsStreamProvider';
}

/// See also [publicGroupPostsStream].
class PublicGroupPostsStreamProvider
    extends AutoDisposeStreamProvider<List<PublicGroupPostModel>> {
  /// See also [publicGroupPostsStream].
  PublicGroupPostsStreamProvider(
    String groupId,
  ) : this._internal(
          (ref) => publicGroupPostsStream(
            ref as PublicGroupPostsStreamRef,
            groupId,
          ),
          from: publicGroupPostsStreamProvider,
          name: r'publicGroupPostsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$publicGroupPostsStreamHash,
          dependencies: PublicGroupPostsStreamFamily._dependencies,
          allTransitiveDependencies:
              PublicGroupPostsStreamFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  PublicGroupPostsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  Override overrideWith(
    Stream<List<PublicGroupPostModel>> Function(
            PublicGroupPostsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PublicGroupPostsStreamProvider._internal(
        (ref) => create(ref as PublicGroupPostsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PublicGroupPostModel>> createElement() {
    return _PublicGroupPostsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PublicGroupPostsStreamProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PublicGroupPostsStreamRef
    on AutoDisposeStreamProviderRef<List<PublicGroupPostModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _PublicGroupPostsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<PublicGroupPostModel>>
    with PublicGroupPostsStreamRef {
  _PublicGroupPostsStreamProviderElement(super.provider);

  @override
  String get groupId => (origin as PublicGroupPostsStreamProvider).groupId;
}

String _$postCommentsStreamHash() =>
    r'48e2cbcd8c75f6ec452f6f856abcddc92bd9ff71';

/// See also [postCommentsStream].
@ProviderFor(postCommentsStream)
const postCommentsStreamProvider = PostCommentsStreamFamily();

/// See also [postCommentsStream].
class PostCommentsStreamFamily
    extends Family<AsyncValue<List<PostCommentModel>>> {
  /// See also [postCommentsStream].
  const PostCommentsStreamFamily();

  /// See also [postCommentsStream].
  PostCommentsStreamProvider call(
    String postId,
  ) {
    return PostCommentsStreamProvider(
      postId,
    );
  }

  @override
  PostCommentsStreamProvider getProviderOverride(
    covariant PostCommentsStreamProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'postCommentsStreamProvider';
}

/// See also [postCommentsStream].
class PostCommentsStreamProvider
    extends AutoDisposeStreamProvider<List<PostCommentModel>> {
  /// See also [postCommentsStream].
  PostCommentsStreamProvider(
    String postId,
  ) : this._internal(
          (ref) => postCommentsStream(
            ref as PostCommentsStreamRef,
            postId,
          ),
          from: postCommentsStreamProvider,
          name: r'postCommentsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postCommentsStreamHash,
          dependencies: PostCommentsStreamFamily._dependencies,
          allTransitiveDependencies:
              PostCommentsStreamFamily._allTransitiveDependencies,
          postId: postId,
        );

  PostCommentsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final String postId;

  @override
  Override overrideWith(
    Stream<List<PostCommentModel>> Function(PostCommentsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostCommentsStreamProvider._internal(
        (ref) => create(ref as PostCommentsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PostCommentModel>> createElement() {
    return _PostCommentsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentsStreamProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostCommentsStreamRef
    on AutoDisposeStreamProviderRef<List<PostCommentModel>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostCommentsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<PostCommentModel>>
    with PostCommentsStreamRef {
  _PostCommentsStreamProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentsStreamProvider).postId;
}

String _$publicGroupNotifierHash() =>
    r'49410a1f5daacc8fb1f414245aef28ab8d613f46';

/// See also [PublicGroupNotifier].
@ProviderFor(PublicGroupNotifier)
final publicGroupNotifierProvider = AutoDisposeAsyncNotifierProvider<
    PublicGroupNotifier, PublicGroupState>.internal(
  PublicGroupNotifier.new,
  name: r'publicGroupNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$publicGroupNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PublicGroupNotifier = AutoDisposeAsyncNotifier<PublicGroupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
