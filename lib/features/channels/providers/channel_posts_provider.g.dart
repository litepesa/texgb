// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_posts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelPostHash() => r'ac8a89cc17e3e067ce3f222cfcfbbe2e37da28e3';

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

/// Get single post by ID
///
/// Copied from [channelPost].
@ProviderFor(channelPost)
const channelPostProvider = ChannelPostFamily();

/// Get single post by ID
///
/// Copied from [channelPost].
class ChannelPostFamily extends Family<AsyncValue<ChannelPost?>> {
  /// Get single post by ID
  ///
  /// Copied from [channelPost].
  const ChannelPostFamily();

  /// Get single post by ID
  ///
  /// Copied from [channelPost].
  ChannelPostProvider call(
    String postId,
  ) {
    return ChannelPostProvider(
      postId,
    );
  }

  @override
  ChannelPostProvider getProviderOverride(
    covariant ChannelPostProvider provider,
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
  String? get name => r'channelPostProvider';
}

/// Get single post by ID
///
/// Copied from [channelPost].
class ChannelPostProvider extends AutoDisposeFutureProvider<ChannelPost?> {
  /// Get single post by ID
  ///
  /// Copied from [channelPost].
  ChannelPostProvider(
    String postId,
  ) : this._internal(
          (ref) => channelPost(
            ref as ChannelPostRef,
            postId,
          ),
          from: channelPostProvider,
          name: r'channelPostProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelPostHash,
          dependencies: ChannelPostFamily._dependencies,
          allTransitiveDependencies:
              ChannelPostFamily._allTransitiveDependencies,
          postId: postId,
        );

  ChannelPostProvider._internal(
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
    FutureOr<ChannelPost?> Function(ChannelPostRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChannelPostProvider._internal(
        (ref) => create(ref as ChannelPostRef),
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
  AutoDisposeFutureProviderElement<ChannelPost?> createElement() {
    return _ChannelPostProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelPostProvider && other.postId == postId;
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
mixin ChannelPostRef on AutoDisposeFutureProviderRef<ChannelPost?> {
  /// The parameter `postId` of this provider.
  String get postId;
}

class _ChannelPostProviderElement
    extends AutoDisposeFutureProviderElement<ChannelPost?> with ChannelPostRef {
  _ChannelPostProviderElement(super.provider);

  @override
  String get postId => (origin as ChannelPostProvider).postId;
}

String _$channelPostsHash() => r'a1131f3c1802f9fb7ff878f62cae7f41f90dd808';

abstract class _$ChannelPosts
    extends BuildlessAutoDisposeAsyncNotifier<List<ChannelPost>> {
  late final String channelId;

  FutureOr<List<ChannelPost>> build(
    String channelId,
  );
}

/// Get posts for a channel
///
/// Copied from [ChannelPosts].
@ProviderFor(ChannelPosts)
const channelPostsProvider = ChannelPostsFamily();

/// Get posts for a channel
///
/// Copied from [ChannelPosts].
class ChannelPostsFamily extends Family<AsyncValue<List<ChannelPost>>> {
  /// Get posts for a channel
  ///
  /// Copied from [ChannelPosts].
  const ChannelPostsFamily();

  /// Get posts for a channel
  ///
  /// Copied from [ChannelPosts].
  ChannelPostsProvider call(
    String channelId,
  ) {
    return ChannelPostsProvider(
      channelId,
    );
  }

  @override
  ChannelPostsProvider getProviderOverride(
    covariant ChannelPostsProvider provider,
  ) {
    return call(
      provider.channelId,
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
  String? get name => r'channelPostsProvider';
}

/// Get posts for a channel
///
/// Copied from [ChannelPosts].
class ChannelPostsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChannelPosts, List<ChannelPost>> {
  /// Get posts for a channel
  ///
  /// Copied from [ChannelPosts].
  ChannelPostsProvider(
    String channelId,
  ) : this._internal(
          () => ChannelPosts()..channelId = channelId,
          from: channelPostsProvider,
          name: r'channelPostsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelPostsHash,
          dependencies: ChannelPostsFamily._dependencies,
          allTransitiveDependencies:
              ChannelPostsFamily._allTransitiveDependencies,
          channelId: channelId,
        );

  ChannelPostsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.channelId,
  }) : super.internal();

  final String channelId;

  @override
  FutureOr<List<ChannelPost>> runNotifierBuild(
    covariant ChannelPosts notifier,
  ) {
    return notifier.build(
      channelId,
    );
  }

  @override
  Override overrideWith(ChannelPosts Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChannelPostsProvider._internal(
        () => create()..channelId = channelId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        channelId: channelId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChannelPosts, List<ChannelPost>>
      createElement() {
    return _ChannelPostsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelPostsProvider && other.channelId == channelId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, channelId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChannelPostsRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChannelPost>> {
  /// The parameter `channelId` of this provider.
  String get channelId;
}

class _ChannelPostsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChannelPosts,
        List<ChannelPost>> with ChannelPostsRef {
  _ChannelPostsProviderElement(super.provider);

  @override
  String get channelId => (origin as ChannelPostsProvider).channelId;
}

String _$channelPostActionsHash() =>
    r'a45e080fa30d8540400d1f43561577526ce0eaef';

/// Post actions (create, delete, like, unlock)
///
/// Copied from [ChannelPostActions].
@ProviderFor(ChannelPostActions)
final channelPostActionsProvider =
    AutoDisposeAsyncNotifierProvider<ChannelPostActions, void>.internal(
  ChannelPostActions.new,
  name: r'channelPostActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$channelPostActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChannelPostActions = AutoDisposeAsyncNotifier<void>;
String _$uploadProgressHash() => r'bc399d0a8a69e27e318d577f42674acc81af631a';

/// Track upload progress for chunked uploads
///
/// Copied from [UploadProgress].
@ProviderFor(UploadProgress)
final uploadProgressProvider =
    AutoDisposeNotifierProvider<UploadProgress, double>.internal(
  UploadProgress.new,
  name: r'uploadProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UploadProgress = AutoDisposeNotifier<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
