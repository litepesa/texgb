// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentRepliesHash() => r'3f3163987a3b07f4837243f2eee793ba8f109d8c';

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

/// Get replies for a specific comment (load more replies)
///
/// Copied from [commentReplies].
@ProviderFor(commentReplies)
const commentRepliesProvider = CommentRepliesFamily();

/// Get replies for a specific comment (load more replies)
///
/// Copied from [commentReplies].
class CommentRepliesFamily extends Family<AsyncValue<List<ChannelComment>>> {
  /// Get replies for a specific comment (load more replies)
  ///
  /// Copied from [commentReplies].
  const CommentRepliesFamily();

  /// Get replies for a specific comment (load more replies)
  ///
  /// Copied from [commentReplies].
  CommentRepliesProvider call(
    String postId,
    String parentCommentId,
  ) {
    return CommentRepliesProvider(
      postId,
      parentCommentId,
    );
  }

  @override
  CommentRepliesProvider getProviderOverride(
    covariant CommentRepliesProvider provider,
  ) {
    return call(
      provider.postId,
      provider.parentCommentId,
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
  String? get name => r'commentRepliesProvider';
}

/// Get replies for a specific comment (load more replies)
///
/// Copied from [commentReplies].
class CommentRepliesProvider
    extends AutoDisposeFutureProvider<List<ChannelComment>> {
  /// Get replies for a specific comment (load more replies)
  ///
  /// Copied from [commentReplies].
  CommentRepliesProvider(
    String postId,
    String parentCommentId,
  ) : this._internal(
          (ref) => commentReplies(
            ref as CommentRepliesRef,
            postId,
            parentCommentId,
          ),
          from: commentRepliesProvider,
          name: r'commentRepliesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentRepliesHash,
          dependencies: CommentRepliesFamily._dependencies,
          allTransitiveDependencies:
              CommentRepliesFamily._allTransitiveDependencies,
          postId: postId,
          parentCommentId: parentCommentId,
        );

  CommentRepliesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
    required this.parentCommentId,
  }) : super.internal();

  final String postId;
  final String parentCommentId;

  @override
  Override overrideWith(
    FutureOr<List<ChannelComment>> Function(CommentRepliesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommentRepliesProvider._internal(
        (ref) => create(ref as CommentRepliesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
        parentCommentId: parentCommentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChannelComment>> createElement() {
    return _CommentRepliesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentRepliesProvider &&
        other.postId == postId &&
        other.parentCommentId == parentCommentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);
    hash = _SystemHash.combine(hash, parentCommentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentRepliesRef on AutoDisposeFutureProviderRef<List<ChannelComment>> {
  /// The parameter `postId` of this provider.
  String get postId;

  /// The parameter `parentCommentId` of this provider.
  String get parentCommentId;
}

class _CommentRepliesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChannelComment>>
    with CommentRepliesRef {
  _CommentRepliesProviderElement(super.provider);

  @override
  String get postId => (origin as CommentRepliesProvider).postId;
  @override
  String get parentCommentId =>
      (origin as CommentRepliesProvider).parentCommentId;
}

String _$sortedCommentsHash() => r'46d2323b40e8bcd8ab32d0457998aa464ef53886';

/// Sorted comments based on current sort type
///
/// Copied from [sortedComments].
@ProviderFor(sortedComments)
const sortedCommentsProvider = SortedCommentsFamily();

/// Sorted comments based on current sort type
///
/// Copied from [sortedComments].
class SortedCommentsFamily extends Family<AsyncValue<List<ChannelComment>>> {
  /// Sorted comments based on current sort type
  ///
  /// Copied from [sortedComments].
  const SortedCommentsFamily();

  /// Sorted comments based on current sort type
  ///
  /// Copied from [sortedComments].
  SortedCommentsProvider call(
    String postId,
  ) {
    return SortedCommentsProvider(
      postId,
    );
  }

  @override
  SortedCommentsProvider getProviderOverride(
    covariant SortedCommentsProvider provider,
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
  String? get name => r'sortedCommentsProvider';
}

/// Sorted comments based on current sort type
///
/// Copied from [sortedComments].
class SortedCommentsProvider
    extends AutoDisposeFutureProvider<List<ChannelComment>> {
  /// Sorted comments based on current sort type
  ///
  /// Copied from [sortedComments].
  SortedCommentsProvider(
    String postId,
  ) : this._internal(
          (ref) => sortedComments(
            ref as SortedCommentsRef,
            postId,
          ),
          from: sortedCommentsProvider,
          name: r'sortedCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sortedCommentsHash,
          dependencies: SortedCommentsFamily._dependencies,
          allTransitiveDependencies:
              SortedCommentsFamily._allTransitiveDependencies,
          postId: postId,
        );

  SortedCommentsProvider._internal(
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
    FutureOr<List<ChannelComment>> Function(SortedCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SortedCommentsProvider._internal(
        (ref) => create(ref as SortedCommentsRef),
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
  AutoDisposeFutureProviderElement<List<ChannelComment>> createElement() {
    return _SortedCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SortedCommentsProvider && other.postId == postId;
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
mixin SortedCommentsRef on AutoDisposeFutureProviderRef<List<ChannelComment>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _SortedCommentsProviderElement
    extends AutoDisposeFutureProviderElement<List<ChannelComment>>
    with SortedCommentsRef {
  _SortedCommentsProviderElement(super.provider);

  @override
  String get postId => (origin as SortedCommentsProvider).postId;
}

String _$postCommentsHash() => r'09ae034d8abfac93511c852ab174e75d649baac1';

abstract class _$PostComments
    extends BuildlessAutoDisposeAsyncNotifier<List<ChannelComment>> {
  late final String postId;

  FutureOr<List<ChannelComment>> build(
    String postId,
  );
}

/// Get comments for a post (top-level comments only initially)
///
/// Copied from [PostComments].
@ProviderFor(PostComments)
const postCommentsProvider = PostCommentsFamily();

/// Get comments for a post (top-level comments only initially)
///
/// Copied from [PostComments].
class PostCommentsFamily extends Family<AsyncValue<List<ChannelComment>>> {
  /// Get comments for a post (top-level comments only initially)
  ///
  /// Copied from [PostComments].
  const PostCommentsFamily();

  /// Get comments for a post (top-level comments only initially)
  ///
  /// Copied from [PostComments].
  PostCommentsProvider call(
    String postId,
  ) {
    return PostCommentsProvider(
      postId,
    );
  }

  @override
  PostCommentsProvider getProviderOverride(
    covariant PostCommentsProvider provider,
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
  String? get name => r'postCommentsProvider';
}

/// Get comments for a post (top-level comments only initially)
///
/// Copied from [PostComments].
class PostCommentsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    PostComments, List<ChannelComment>> {
  /// Get comments for a post (top-level comments only initially)
  ///
  /// Copied from [PostComments].
  PostCommentsProvider(
    String postId,
  ) : this._internal(
          () => PostComments()..postId = postId,
          from: postCommentsProvider,
          name: r'postCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postCommentsHash,
          dependencies: PostCommentsFamily._dependencies,
          allTransitiveDependencies:
              PostCommentsFamily._allTransitiveDependencies,
          postId: postId,
        );

  PostCommentsProvider._internal(
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
  FutureOr<List<ChannelComment>> runNotifierBuild(
    covariant PostComments notifier,
  ) {
    return notifier.build(
      postId,
    );
  }

  @override
  Override overrideWith(PostComments Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostCommentsProvider._internal(
        () => create()..postId = postId,
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
  AutoDisposeAsyncNotifierProviderElement<PostComments, List<ChannelComment>>
      createElement() {
    return _PostCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentsProvider && other.postId == postId;
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
mixin PostCommentsRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChannelComment>> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _PostCommentsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PostComments,
        List<ChannelComment>> with PostCommentsRef {
  _PostCommentsProviderElement(super.provider);

  @override
  String get postId => (origin as PostCommentsProvider).postId;
}

String _$commentActionsHash() => r'2ca94ee4a217cd077d5a1fa7526052ad9631fa22';

/// Comment actions (create, delete, like, pin)
///
/// Copied from [CommentActions].
@ProviderFor(CommentActions)
final commentActionsProvider =
    AutoDisposeAsyncNotifierProvider<CommentActions, void>.internal(
  CommentActions.new,
  name: r'commentActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommentActions = AutoDisposeAsyncNotifier<void>;
String _$commentSortHash() => r'fa841233e26e6ded0aa2c00e5a40d40a4fc13a92';

/// Comment sort type state
///
/// Copied from [CommentSort].
@ProviderFor(CommentSort)
final commentSortProvider =
    AutoDisposeNotifierProvider<CommentSort, CommentSortType>.internal(
  CommentSort.new,
  name: r'commentSortProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$commentSortHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CommentSort = AutoDisposeNotifier<CommentSortType>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
