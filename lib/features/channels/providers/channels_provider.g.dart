// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channels_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelRepositoryHash() => r'93575ad28ba52ab738529bfa168b79b867ec5084';

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
String _$trendingChannelsHash() => r'd541b0ba2c250a70397af3da4f3448a4ecd5657e';

/// Get trending channels
///
/// Copied from [trendingChannels].
@ProviderFor(trendingChannels)
final trendingChannelsProvider =
    AutoDisposeFutureProvider<List<ChannelModel>>.internal(
  trendingChannels,
  name: r'trendingChannelsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trendingChannelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TrendingChannelsRef = AutoDisposeFutureProviderRef<List<ChannelModel>>;
String _$popularChannelsHash() => r'03e324d85b64875739cddf2e30d849c826376123';

/// Get popular channels
///
/// Copied from [popularChannels].
@ProviderFor(popularChannels)
final popularChannelsProvider =
    AutoDisposeFutureProvider<List<ChannelModel>>.internal(
  popularChannels,
  name: r'popularChannelsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$popularChannelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PopularChannelsRef = AutoDisposeFutureProviderRef<List<ChannelModel>>;
String _$subscribedChannelsHash() =>
    r'eaecd18bfc59db3a374e65da2696ed549ae392dc';

/// Get user's subscribed channels
///
/// Copied from [subscribedChannels].
@ProviderFor(subscribedChannels)
final subscribedChannelsProvider =
    AutoDisposeFutureProvider<List<ChannelModel>>.internal(
  subscribedChannels,
  name: r'subscribedChannelsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$subscribedChannelsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscribedChannelsRef
    = AutoDisposeFutureProviderRef<List<ChannelModel>>;
String _$channelHash() => r'a2215245fadb0cbfd1dfbf6d855c20e4e6446454';

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

/// Get channel by ID
///
/// Copied from [channel].
@ProviderFor(channel)
const channelProvider = ChannelFamily();

/// Get channel by ID
///
/// Copied from [channel].
class ChannelFamily extends Family<AsyncValue<ChannelModel?>> {
  /// Get channel by ID
  ///
  /// Copied from [channel].
  const ChannelFamily();

  /// Get channel by ID
  ///
  /// Copied from [channel].
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

/// Get channel by ID
///
/// Copied from [channel].
class ChannelProvider extends AutoDisposeFutureProvider<ChannelModel?> {
  /// Get channel by ID
  ///
  /// Copied from [channel].
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
    FutureOr<ChannelModel?> Function(ChannelRef provider) create,
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
  AutoDisposeFutureProviderElement<ChannelModel?> createElement() {
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
mixin ChannelRef on AutoDisposeFutureProviderRef<ChannelModel?> {
  /// The parameter `channelId` of this provider.
  String get channelId;
}

class _ChannelProviderElement
    extends AutoDisposeFutureProviderElement<ChannelModel?> with ChannelRef {
  _ChannelProviderElement(super.provider);

  @override
  String get channelId => (origin as ChannelProvider).channelId;
}

String _$channelMembersHash() => r'1b4290e005a080be6406e7c2332f741b591add16';

/// Get channel members (admins/moderators)
///
/// Copied from [channelMembers].
@ProviderFor(channelMembers)
const channelMembersProvider = ChannelMembersFamily();

/// Get channel members (admins/moderators)
///
/// Copied from [channelMembers].
class ChannelMembersFamily extends Family<AsyncValue<List<ChannelMember>>> {
  /// Get channel members (admins/moderators)
  ///
  /// Copied from [channelMembers].
  const ChannelMembersFamily();

  /// Get channel members (admins/moderators)
  ///
  /// Copied from [channelMembers].
  ChannelMembersProvider call(
    String channelId,
  ) {
    return ChannelMembersProvider(
      channelId,
    );
  }

  @override
  ChannelMembersProvider getProviderOverride(
    covariant ChannelMembersProvider provider,
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
  String? get name => r'channelMembersProvider';
}

/// Get channel members (admins/moderators)
///
/// Copied from [channelMembers].
class ChannelMembersProvider
    extends AutoDisposeFutureProvider<List<ChannelMember>> {
  /// Get channel members (admins/moderators)
  ///
  /// Copied from [channelMembers].
  ChannelMembersProvider(
    String channelId,
  ) : this._internal(
          (ref) => channelMembers(
            ref as ChannelMembersRef,
            channelId,
          ),
          from: channelMembersProvider,
          name: r'channelMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelMembersHash,
          dependencies: ChannelMembersFamily._dependencies,
          allTransitiveDependencies:
              ChannelMembersFamily._allTransitiveDependencies,
          channelId: channelId,
        );

  ChannelMembersProvider._internal(
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
    FutureOr<List<ChannelMember>> Function(ChannelMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChannelMembersProvider._internal(
        (ref) => create(ref as ChannelMembersRef),
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
  AutoDisposeFutureProviderElement<List<ChannelMember>> createElement() {
    return _ChannelMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelMembersProvider && other.channelId == channelId;
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
mixin ChannelMembersRef on AutoDisposeFutureProviderRef<List<ChannelMember>> {
  /// The parameter `channelId` of this provider.
  String get channelId;
}

class _ChannelMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<ChannelMember>>
    with ChannelMembersRef {
  _ChannelMembersProviderElement(super.provider);

  @override
  String get channelId => (origin as ChannelMembersProvider).channelId;
}

String _$channelsListHash() => r'7fa6a2e9237ad8e162160494f277b4530c425e42';

abstract class _$ChannelsList
    extends BuildlessAutoDisposeAsyncNotifier<List<ChannelModel>> {
  late final int page;
  late final String? type;
  late final String? search;

  FutureOr<List<ChannelModel>> build({
    int page = 1,
    String? type,
    String? search,
  });
}

/// Get all channels (discovery/browse)
///
/// Copied from [ChannelsList].
@ProviderFor(ChannelsList)
const channelsListProvider = ChannelsListFamily();

/// Get all channels (discovery/browse)
///
/// Copied from [ChannelsList].
class ChannelsListFamily extends Family<AsyncValue<List<ChannelModel>>> {
  /// Get all channels (discovery/browse)
  ///
  /// Copied from [ChannelsList].
  const ChannelsListFamily();

  /// Get all channels (discovery/browse)
  ///
  /// Copied from [ChannelsList].
  ChannelsListProvider call({
    int page = 1,
    String? type,
    String? search,
  }) {
    return ChannelsListProvider(
      page: page,
      type: type,
      search: search,
    );
  }

  @override
  ChannelsListProvider getProviderOverride(
    covariant ChannelsListProvider provider,
  ) {
    return call(
      page: provider.page,
      type: provider.type,
      search: provider.search,
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
  String? get name => r'channelsListProvider';
}

/// Get all channels (discovery/browse)
///
/// Copied from [ChannelsList].
class ChannelsListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChannelsList, List<ChannelModel>> {
  /// Get all channels (discovery/browse)
  ///
  /// Copied from [ChannelsList].
  ChannelsListProvider({
    int page = 1,
    String? type,
    String? search,
  }) : this._internal(
          () => ChannelsList()
            ..page = page
            ..type = type
            ..search = search,
          from: channelsListProvider,
          name: r'channelsListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$channelsListHash,
          dependencies: ChannelsListFamily._dependencies,
          allTransitiveDependencies:
              ChannelsListFamily._allTransitiveDependencies,
          page: page,
          type: type,
          search: search,
        );

  ChannelsListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.page,
    required this.type,
    required this.search,
  }) : super.internal();

  final int page;
  final String? type;
  final String? search;

  @override
  FutureOr<List<ChannelModel>> runNotifierBuild(
    covariant ChannelsList notifier,
  ) {
    return notifier.build(
      page: page,
      type: type,
      search: search,
    );
  }

  @override
  Override overrideWith(ChannelsList Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChannelsListProvider._internal(
        () => create()
          ..page = page
          ..type = type
          ..search = search,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
        type: type,
        search: search,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChannelsList, List<ChannelModel>>
      createElement() {
    return _ChannelsListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelsListProvider &&
        other.page == page &&
        other.type == type &&
        other.search == search;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChannelsListRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChannelModel>> {
  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `type` of this provider.
  String? get type;

  /// The parameter `search` of this provider.
  String? get search;
}

class _ChannelsListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChannelsList,
        List<ChannelModel>> with ChannelsListRef {
  _ChannelsListProviderElement(super.provider);

  @override
  int get page => (origin as ChannelsListProvider).page;
  @override
  String? get type => (origin as ChannelsListProvider).type;
  @override
  String? get search => (origin as ChannelsListProvider).search;
}

String _$channelActionsHash() => r'c9ef31086d91e392cac4d05e425eb59e5a9e4ff1';

/// Channel actions notifier (create, update, delete, subscribe)
///
/// Copied from [ChannelActions].
@ProviderFor(ChannelActions)
final channelActionsProvider =
    AutoDisposeAsyncNotifierProvider<ChannelActions, void>.internal(
  ChannelActions.new,
  name: r'channelActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$channelActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChannelActions = AutoDisposeAsyncNotifier<void>;
String _$channelMemberActionsHash() =>
    r'87ce2202c3282c54718f14fd36ba8d8e3e9944f8';

/// Channel member actions (add/remove admins/mods)
///
/// Copied from [ChannelMemberActions].
@ProviderFor(ChannelMemberActions)
final channelMemberActionsProvider =
    AutoDisposeAsyncNotifierProvider<ChannelMemberActions, void>.internal(
  ChannelMemberActions.new,
  name: r'channelMemberActionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$channelMemberActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChannelMemberActions = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
