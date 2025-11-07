// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelRepositoryHash() => r'0d81e4ff592b3dca662da9f7985197fead7d8c44';

/// See also [channelRepository].
@ProviderFor(channelRepository)
final channelRepositoryProvider =
    AutoDisposeProvider<ChannelRepository>.internal(
  channelRepository,
  name: r'channelRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$channelRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChannelRepositoryRef = AutoDisposeProviderRef<ChannelRepository>;
String _$channelHash() => r'a6881182b0d34a828668943122df44966c497f1c';

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

/// See also [channel].
@ProviderFor(channel)
const channelProvider = ChannelFamily();

/// See also [channel].
class ChannelFamily extends Family<AsyncValue<ChannelModel>> {
  /// See also [channel].
  const ChannelFamily();

  /// See also [channel].
  ChannelProvider call(
    String channelId,
  ) {
    return ChannelProvider(
      channelId,
    );
  }

  @override
  ChannelProvider getProviderOverride(
    covariant ChannelProvider provider,
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
  String? get name => r'channelProvider';
}

/// See also [channel].
class ChannelProvider extends AutoDisposeFutureProvider<ChannelModel> {
  /// See also [channel].
  ChannelProvider(
    String channelId,
  ) : this._internal(
          (ref) => channel(
            ref as ChannelRef,
            channelId,
          ),
          from: channelProvider,
          name: r'channelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelHash,
          dependencies: ChannelFamily._dependencies,
          allTransitiveDependencies: ChannelFamily._allTransitiveDependencies,
          channelId: channelId,
        );

  ChannelProvider._internal(
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
  Override overrideWith(
    FutureOr<ChannelModel> Function(ChannelRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChannelProvider._internal(
        (ref) => create(ref as ChannelRef),
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
  AutoDisposeFutureProviderElement<ChannelModel> createElement() {
    return _ChannelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelProvider && other.channelId == channelId;
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
mixin ChannelRef on AutoDisposeFutureProviderRef<ChannelModel> {
  /// The parameter `channelId` of this provider.
  String get channelId;
}

class _ChannelProviderElement
    extends AutoDisposeFutureProviderElement<ChannelModel> with ChannelRef {
  _ChannelProviderElement(super.provider);

  @override
  String get channelId => (origin as ChannelProvider).channelId;
}

String _$videoFeedHash() => r'8713acd3b056c1d03ad369f0dc98f8d06c64a001';

/// See also [VideoFeed].
@ProviderFor(VideoFeed)
final videoFeedProvider =
    AutoDisposeAsyncNotifierProvider<VideoFeed, VideoFeedState>.internal(
  VideoFeed.new,
  name: r'videoFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoFeed = AutoDisposeAsyncNotifier<VideoFeedState>;
String _$discoverFeedHash() => r'c6749f2cf0a9019df7b58a7bc7fb5050498df350';

/// See also [DiscoverFeed].
@ProviderFor(DiscoverFeed)
final discoverFeedProvider =
    AutoDisposeAsyncNotifierProvider<DiscoverFeed, VideoFeedState>.internal(
  DiscoverFeed.new,
  name: r'discoverFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$discoverFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DiscoverFeed = AutoDisposeAsyncNotifier<VideoFeedState>;
String _$myChannelHash() => r'a0be007bc9f77f7ba1b35188989fdf737f29b6c0';

/// See also [MyChannel].
@ProviderFor(MyChannel)
final myChannelProvider =
    AutoDisposeAsyncNotifierProvider<MyChannel, ChannelModel?>.internal(
  MyChannel.new,
  name: r'myChannelProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myChannelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MyChannel = AutoDisposeAsyncNotifier<ChannelModel?>;
String _$channelVideosHash() => r'2fda79759132db96e7e4f70b80ce97492d0fa284';

abstract class _$ChannelVideos
    extends BuildlessAutoDisposeAsyncNotifier<List<VideoModel>> {
  late final String channelId;

  FutureOr<List<VideoModel>> build(
    String channelId,
  );
}

/// See also [ChannelVideos].
@ProviderFor(ChannelVideos)
const channelVideosProvider = ChannelVideosFamily();

/// See also [ChannelVideos].
class ChannelVideosFamily extends Family<AsyncValue<List<VideoModel>>> {
  /// See also [ChannelVideos].
  const ChannelVideosFamily();

  /// See also [ChannelVideos].
  ChannelVideosProvider call(
    String channelId,
  ) {
    return ChannelVideosProvider(
      channelId,
    );
  }

  @override
  ChannelVideosProvider getProviderOverride(
    covariant ChannelVideosProvider provider,
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
  String? get name => r'channelVideosProvider';
}

/// See also [ChannelVideos].
class ChannelVideosProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChannelVideos, List<VideoModel>> {
  /// See also [ChannelVideos].
  ChannelVideosProvider(
    String channelId,
  ) : this._internal(
          () => ChannelVideos()..channelId = channelId,
          from: channelVideosProvider,
          name: r'channelVideosProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelVideosHash,
          dependencies: ChannelVideosFamily._dependencies,
          allTransitiveDependencies:
              ChannelVideosFamily._allTransitiveDependencies,
          channelId: channelId,
        );

  ChannelVideosProvider._internal(
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
  FutureOr<List<VideoModel>> runNotifierBuild(
    covariant ChannelVideos notifier,
  ) {
    return notifier.build(
      channelId,
    );
  }

  @override
  Override overrideWith(ChannelVideos Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChannelVideosProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ChannelVideos, List<VideoModel>>
      createElement() {
    return _ChannelVideosProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelVideosProvider && other.channelId == channelId;
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
mixin ChannelVideosRef
    on AutoDisposeAsyncNotifierProviderRef<List<VideoModel>> {
  /// The parameter `channelId` of this provider.
  String get channelId;
}

class _ChannelVideosProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChannelVideos,
        List<VideoModel>> with ChannelVideosRef {
  _ChannelVideosProviderElement(super.provider);

  @override
  String get channelId => (origin as ChannelVideosProvider).channelId;
}

String _$createChannelHash() => r'c044d7d4fed5ac2bba462d90e59e45a6cfb82091';

/// See also [CreateChannel].
@ProviderFor(CreateChannel)
final createChannelProvider =
    AutoDisposeAsyncNotifierProvider<CreateChannel, ChannelModel?>.internal(
  CreateChannel.new,
  name: r'createChannelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createChannelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateChannel = AutoDisposeAsyncNotifier<ChannelModel?>;
String _$updateChannelHash() => r'bad6875d17419ea917d5e3b59d739dc57e5b763b';

/// See also [UpdateChannel].
@ProviderFor(UpdateChannel)
final updateChannelProvider =
    AutoDisposeAsyncNotifierProvider<UpdateChannel, ChannelModel?>.internal(
  UpdateChannel.new,
  name: r'updateChannelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateChannelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UpdateChannel = AutoDisposeAsyncNotifier<ChannelModel?>;
String _$followChannelHash() => r'cc8345968e867c7a503d9b25eb38157238136cde';

/// See also [FollowChannel].
@ProviderFor(FollowChannel)
final followChannelProvider =
    AutoDisposeAsyncNotifierProvider<FollowChannel, bool>.internal(
  FollowChannel.new,
  name: r'followChannelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followChannelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FollowChannel = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
