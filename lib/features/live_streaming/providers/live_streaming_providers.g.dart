// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_streaming_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liveStreamRepositoryHash() =>
    r'682ee2eaed714ef52539f8c62991c9d8c02be839';

/// See also [liveStreamRepository].
@ProviderFor(liveStreamRepository)
final liveStreamRepositoryProvider =
    AutoDisposeProvider<LiveStreamRepository>.internal(
  liveStreamRepository,
  name: r'liveStreamRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$liveStreamRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LiveStreamRepositoryRef = AutoDisposeProviderRef<LiveStreamRepository>;
String _$liveStreamHash() => r'ddf1161f2b96caa07238921fc92ceb5225d0513c';

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

/// Get specific live stream
///
/// Copied from [liveStream].
@ProviderFor(liveStream)
const liveStreamProvider = LiveStreamFamily();

/// Get specific live stream
///
/// Copied from [liveStream].
class LiveStreamFamily extends Family<AsyncValue<RefinedLiveStreamModel>> {
  /// Get specific live stream
  ///
  /// Copied from [liveStream].
  const LiveStreamFamily();

  /// Get specific live stream
  ///
  /// Copied from [liveStream].
  LiveStreamProvider call(
    String streamId,
  ) {
    return LiveStreamProvider(
      streamId,
    );
  }

  @override
  LiveStreamProvider getProviderOverride(
    covariant LiveStreamProvider provider,
  ) {
    return call(
      provider.streamId,
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
  String? get name => r'liveStreamProvider';
}

/// Get specific live stream
///
/// Copied from [liveStream].
class LiveStreamProvider
    extends AutoDisposeFutureProvider<RefinedLiveStreamModel> {
  /// Get specific live stream
  ///
  /// Copied from [liveStream].
  LiveStreamProvider(
    String streamId,
  ) : this._internal(
          (ref) => liveStream(
            ref as LiveStreamRef,
            streamId,
          ),
          from: liveStreamProvider,
          name: r'liveStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$liveStreamHash,
          dependencies: LiveStreamFamily._dependencies,
          allTransitiveDependencies:
              LiveStreamFamily._allTransitiveDependencies,
          streamId: streamId,
        );

  LiveStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.streamId,
  }) : super.internal();

  final String streamId;

  @override
  Override overrideWith(
    FutureOr<RefinedLiveStreamModel> Function(LiveStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LiveStreamProvider._internal(
        (ref) => create(ref as LiveStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        streamId: streamId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<RefinedLiveStreamModel> createElement() {
    return _LiveStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveStreamProvider && other.streamId == streamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, streamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LiveStreamRef on AutoDisposeFutureProviderRef<RefinedLiveStreamModel> {
  /// The parameter `streamId` of this provider.
  String get streamId;
}

class _LiveStreamProviderElement
    extends AutoDisposeFutureProviderElement<RefinedLiveStreamModel>
    with LiveStreamRef {
  _LiveStreamProviderElement(super.provider);

  @override
  String get streamId => (origin as LiveStreamProvider).streamId;
}

String _$liveStreamsHash() => r'1f1834bea6dbcba5dcf9b989de3917042933413c';

/// Get all live streams
///
/// Copied from [liveStreams].
@ProviderFor(liveStreams)
const liveStreamsProvider = LiveStreamsFamily();

/// Get all live streams
///
/// Copied from [liveStreams].
class LiveStreamsFamily
    extends Family<AsyncValue<List<RefinedLiveStreamModel>>> {
  /// Get all live streams
  ///
  /// Copied from [liveStreams].
  const LiveStreamsFamily();

  /// Get all live streams
  ///
  /// Copied from [liveStreams].
  LiveStreamsProvider call({
    int limit = 20,
    int offset = 0,
    LiveStreamType? type,
    LiveStreamCategory? category,
  }) {
    return LiveStreamsProvider(
      limit: limit,
      offset: offset,
      type: type,
      category: category,
    );
  }

  @override
  LiveStreamsProvider getProviderOverride(
    covariant LiveStreamsProvider provider,
  ) {
    return call(
      limit: provider.limit,
      offset: provider.offset,
      type: provider.type,
      category: provider.category,
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
  String? get name => r'liveStreamsProvider';
}

/// Get all live streams
///
/// Copied from [liveStreams].
class LiveStreamsProvider
    extends AutoDisposeFutureProvider<List<RefinedLiveStreamModel>> {
  /// Get all live streams
  ///
  /// Copied from [liveStreams].
  LiveStreamsProvider({
    int limit = 20,
    int offset = 0,
    LiveStreamType? type,
    LiveStreamCategory? category,
  }) : this._internal(
          (ref) => liveStreams(
            ref as LiveStreamsRef,
            limit: limit,
            offset: offset,
            type: type,
            category: category,
          ),
          from: liveStreamsProvider,
          name: r'liveStreamsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$liveStreamsHash,
          dependencies: LiveStreamsFamily._dependencies,
          allTransitiveDependencies:
              LiveStreamsFamily._allTransitiveDependencies,
          limit: limit,
          offset: offset,
          type: type,
          category: category,
        );

  LiveStreamsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
    required this.offset,
    required this.type,
    required this.category,
  }) : super.internal();

  final int limit;
  final int offset;
  final LiveStreamType? type;
  final LiveStreamCategory? category;

  @override
  Override overrideWith(
    FutureOr<List<RefinedLiveStreamModel>> Function(LiveStreamsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LiveStreamsProvider._internal(
        (ref) => create(ref as LiveStreamsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
        offset: offset,
        type: type,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
      createElement() {
    return _LiveStreamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveStreamsProvider &&
        other.limit == limit &&
        other.offset == offset &&
        other.type == type &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LiveStreamsRef
    on AutoDisposeFutureProviderRef<List<RefinedLiveStreamModel>> {
  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `type` of this provider.
  LiveStreamType? get type;

  /// The parameter `category` of this provider.
  LiveStreamCategory? get category;
}

class _LiveStreamsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
    with LiveStreamsRef {
  _LiveStreamsProviderElement(super.provider);

  @override
  int get limit => (origin as LiveStreamsProvider).limit;
  @override
  int get offset => (origin as LiveStreamsProvider).offset;
  @override
  LiveStreamType? get type => (origin as LiveStreamsProvider).type;
  @override
  LiveStreamCategory? get category => (origin as LiveStreamsProvider).category;
}

String _$giftLiveStreamsHash() => r'bb533cc03c103ca07c6fc21217a5c9fdee3e465e';

/// Get gift live streams
///
/// Copied from [giftLiveStreams].
@ProviderFor(giftLiveStreams)
const giftLiveStreamsProvider = GiftLiveStreamsFamily();

/// Get gift live streams
///
/// Copied from [giftLiveStreams].
class GiftLiveStreamsFamily
    extends Family<AsyncValue<List<RefinedLiveStreamModel>>> {
  /// Get gift live streams
  ///
  /// Copied from [giftLiveStreams].
  const GiftLiveStreamsFamily();

  /// Get gift live streams
  ///
  /// Copied from [giftLiveStreams].
  GiftLiveStreamsProvider call({
    int limit = 20,
  }) {
    return GiftLiveStreamsProvider(
      limit: limit,
    );
  }

  @override
  GiftLiveStreamsProvider getProviderOverride(
    covariant GiftLiveStreamsProvider provider,
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
  String? get name => r'giftLiveStreamsProvider';
}

/// Get gift live streams
///
/// Copied from [giftLiveStreams].
class GiftLiveStreamsProvider
    extends AutoDisposeFutureProvider<List<RefinedLiveStreamModel>> {
  /// Get gift live streams
  ///
  /// Copied from [giftLiveStreams].
  GiftLiveStreamsProvider({
    int limit = 20,
  }) : this._internal(
          (ref) => giftLiveStreams(
            ref as GiftLiveStreamsRef,
            limit: limit,
          ),
          from: giftLiveStreamsProvider,
          name: r'giftLiveStreamsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$giftLiveStreamsHash,
          dependencies: GiftLiveStreamsFamily._dependencies,
          allTransitiveDependencies:
              GiftLiveStreamsFamily._allTransitiveDependencies,
          limit: limit,
        );

  GiftLiveStreamsProvider._internal(
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
    FutureOr<List<RefinedLiveStreamModel>> Function(GiftLiveStreamsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GiftLiveStreamsProvider._internal(
        (ref) => create(ref as GiftLiveStreamsRef),
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
  AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
      createElement() {
    return _GiftLiveStreamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GiftLiveStreamsProvider && other.limit == limit;
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
mixin GiftLiveStreamsRef
    on AutoDisposeFutureProviderRef<List<RefinedLiveStreamModel>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _GiftLiveStreamsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
    with GiftLiveStreamsRef {
  _GiftLiveStreamsProviderElement(super.provider);

  @override
  int get limit => (origin as GiftLiveStreamsProvider).limit;
}

String _$shopLiveStreamsHash() => r'ba5178480a0921c3f5616be0cf422dcaaf7360ad';

/// Get shop live streams
///
/// Copied from [shopLiveStreams].
@ProviderFor(shopLiveStreams)
const shopLiveStreamsProvider = ShopLiveStreamsFamily();

/// Get shop live streams
///
/// Copied from [shopLiveStreams].
class ShopLiveStreamsFamily
    extends Family<AsyncValue<List<RefinedLiveStreamModel>>> {
  /// Get shop live streams
  ///
  /// Copied from [shopLiveStreams].
  const ShopLiveStreamsFamily();

  /// Get shop live streams
  ///
  /// Copied from [shopLiveStreams].
  ShopLiveStreamsProvider call({
    int limit = 20,
  }) {
    return ShopLiveStreamsProvider(
      limit: limit,
    );
  }

  @override
  ShopLiveStreamsProvider getProviderOverride(
    covariant ShopLiveStreamsProvider provider,
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
  String? get name => r'shopLiveStreamsProvider';
}

/// Get shop live streams
///
/// Copied from [shopLiveStreams].
class ShopLiveStreamsProvider
    extends AutoDisposeFutureProvider<List<RefinedLiveStreamModel>> {
  /// Get shop live streams
  ///
  /// Copied from [shopLiveStreams].
  ShopLiveStreamsProvider({
    int limit = 20,
  }) : this._internal(
          (ref) => shopLiveStreams(
            ref as ShopLiveStreamsRef,
            limit: limit,
          ),
          from: shopLiveStreamsProvider,
          name: r'shopLiveStreamsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopLiveStreamsHash,
          dependencies: ShopLiveStreamsFamily._dependencies,
          allTransitiveDependencies:
              ShopLiveStreamsFamily._allTransitiveDependencies,
          limit: limit,
        );

  ShopLiveStreamsProvider._internal(
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
    FutureOr<List<RefinedLiveStreamModel>> Function(ShopLiveStreamsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopLiveStreamsProvider._internal(
        (ref) => create(ref as ShopLiveStreamsRef),
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
  AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
      createElement() {
    return _ShopLiveStreamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopLiveStreamsProvider && other.limit == limit;
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
mixin ShopLiveStreamsRef
    on AutoDisposeFutureProviderRef<List<RefinedLiveStreamModel>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _ShopLiveStreamsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
    with ShopLiveStreamsRef {
  _ShopLiveStreamsProviderElement(super.provider);

  @override
  int get limit => (origin as ShopLiveStreamsProvider).limit;
}

String _$userLiveStreamsHash() => r'408d39f9c56fbda55c805538900a951c4bb7ae52';

/// Get user's live stream history (as host)
///
/// Copied from [userLiveStreams].
@ProviderFor(userLiveStreams)
const userLiveStreamsProvider = UserLiveStreamsFamily();

/// Get user's live stream history (as host)
///
/// Copied from [userLiveStreams].
class UserLiveStreamsFamily
    extends Family<AsyncValue<List<RefinedLiveStreamModel>>> {
  /// Get user's live stream history (as host)
  ///
  /// Copied from [userLiveStreams].
  const UserLiveStreamsFamily();

  /// Get user's live stream history (as host)
  ///
  /// Copied from [userLiveStreams].
  UserLiveStreamsProvider call(
    String userId,
  ) {
    return UserLiveStreamsProvider(
      userId,
    );
  }

  @override
  UserLiveStreamsProvider getProviderOverride(
    covariant UserLiveStreamsProvider provider,
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
  String? get name => r'userLiveStreamsProvider';
}

/// Get user's live stream history (as host)
///
/// Copied from [userLiveStreams].
class UserLiveStreamsProvider
    extends AutoDisposeFutureProvider<List<RefinedLiveStreamModel>> {
  /// Get user's live stream history (as host)
  ///
  /// Copied from [userLiveStreams].
  UserLiveStreamsProvider(
    String userId,
  ) : this._internal(
          (ref) => userLiveStreams(
            ref as UserLiveStreamsRef,
            userId,
          ),
          from: userLiveStreamsProvider,
          name: r'userLiveStreamsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userLiveStreamsHash,
          dependencies: UserLiveStreamsFamily._dependencies,
          allTransitiveDependencies:
              UserLiveStreamsFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserLiveStreamsProvider._internal(
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
    FutureOr<List<RefinedLiveStreamModel>> Function(UserLiveStreamsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserLiveStreamsProvider._internal(
        (ref) => create(ref as UserLiveStreamsRef),
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
  AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
      createElement() {
    return _UserLiveStreamsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserLiveStreamsProvider && other.userId == userId;
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
mixin UserLiveStreamsRef
    on AutoDisposeFutureProviderRef<List<RefinedLiveStreamModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserLiveStreamsProviderElement
    extends AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
    with UserLiveStreamsRef {
  _UserLiveStreamsProviderElement(super.provider);

  @override
  String get userId => (origin as UserLiveStreamsProvider).userId;
}

String _$shopLiveStreamHistoryHash() =>
    r'9361675e54f5e5330d4ff8ebe24a010a818bbbaa';

/// Get shop's live stream history
///
/// Copied from [shopLiveStreamHistory].
@ProviderFor(shopLiveStreamHistory)
const shopLiveStreamHistoryProvider = ShopLiveStreamHistoryFamily();

/// Get shop's live stream history
///
/// Copied from [shopLiveStreamHistory].
class ShopLiveStreamHistoryFamily
    extends Family<AsyncValue<List<RefinedLiveStreamModel>>> {
  /// Get shop's live stream history
  ///
  /// Copied from [shopLiveStreamHistory].
  const ShopLiveStreamHistoryFamily();

  /// Get shop's live stream history
  ///
  /// Copied from [shopLiveStreamHistory].
  ShopLiveStreamHistoryProvider call(
    String shopId,
  ) {
    return ShopLiveStreamHistoryProvider(
      shopId,
    );
  }

  @override
  ShopLiveStreamHistoryProvider getProviderOverride(
    covariant ShopLiveStreamHistoryProvider provider,
  ) {
    return call(
      provider.shopId,
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
  String? get name => r'shopLiveStreamHistoryProvider';
}

/// Get shop's live stream history
///
/// Copied from [shopLiveStreamHistory].
class ShopLiveStreamHistoryProvider
    extends AutoDisposeFutureProvider<List<RefinedLiveStreamModel>> {
  /// Get shop's live stream history
  ///
  /// Copied from [shopLiveStreamHistory].
  ShopLiveStreamHistoryProvider(
    String shopId,
  ) : this._internal(
          (ref) => shopLiveStreamHistory(
            ref as ShopLiveStreamHistoryRef,
            shopId,
          ),
          from: shopLiveStreamHistoryProvider,
          name: r'shopLiveStreamHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopLiveStreamHistoryHash,
          dependencies: ShopLiveStreamHistoryFamily._dependencies,
          allTransitiveDependencies:
              ShopLiveStreamHistoryFamily._allTransitiveDependencies,
          shopId: shopId,
        );

  ShopLiveStreamHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shopId,
  }) : super.internal();

  final String shopId;

  @override
  Override overrideWith(
    FutureOr<List<RefinedLiveStreamModel>> Function(
            ShopLiveStreamHistoryRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopLiveStreamHistoryProvider._internal(
        (ref) => create(ref as ShopLiveStreamHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shopId: shopId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
      createElement() {
    return _ShopLiveStreamHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopLiveStreamHistoryProvider && other.shopId == shopId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shopId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopLiveStreamHistoryRef
    on AutoDisposeFutureProviderRef<List<RefinedLiveStreamModel>> {
  /// The parameter `shopId` of this provider.
  String get shopId;
}

class _ShopLiveStreamHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<RefinedLiveStreamModel>>
    with ShopLiveStreamHistoryRef {
  _ShopLiveStreamHistoryProviderElement(super.provider);

  @override
  String get shopId => (origin as ShopLiveStreamHistoryProvider).shopId;
}

String _$streamGiftsHash() => r'7c30e65ce1f5acb19f6ecfba55b6abebec03ae49';

/// Get gift transactions for a stream
///
/// Copied from [streamGifts].
@ProviderFor(streamGifts)
const streamGiftsProvider = StreamGiftsFamily();

/// Get gift transactions for a stream
///
/// Copied from [streamGifts].
class StreamGiftsFamily extends Family<AsyncValue<List<GiftTransactionModel>>> {
  /// Get gift transactions for a stream
  ///
  /// Copied from [streamGifts].
  const StreamGiftsFamily();

  /// Get gift transactions for a stream
  ///
  /// Copied from [streamGifts].
  StreamGiftsProvider call(
    String streamId, {
    int limit = 50,
  }) {
    return StreamGiftsProvider(
      streamId,
      limit: limit,
    );
  }

  @override
  StreamGiftsProvider getProviderOverride(
    covariant StreamGiftsProvider provider,
  ) {
    return call(
      provider.streamId,
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
  String? get name => r'streamGiftsProvider';
}

/// Get gift transactions for a stream
///
/// Copied from [streamGifts].
class StreamGiftsProvider
    extends AutoDisposeFutureProvider<List<GiftTransactionModel>> {
  /// Get gift transactions for a stream
  ///
  /// Copied from [streamGifts].
  StreamGiftsProvider(
    String streamId, {
    int limit = 50,
  }) : this._internal(
          (ref) => streamGifts(
            ref as StreamGiftsRef,
            streamId,
            limit: limit,
          ),
          from: streamGiftsProvider,
          name: r'streamGiftsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$streamGiftsHash,
          dependencies: StreamGiftsFamily._dependencies,
          allTransitiveDependencies:
              StreamGiftsFamily._allTransitiveDependencies,
          streamId: streamId,
          limit: limit,
        );

  StreamGiftsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.streamId,
    required this.limit,
  }) : super.internal();

  final String streamId;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<GiftTransactionModel>> Function(StreamGiftsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StreamGiftsProvider._internal(
        (ref) => create(ref as StreamGiftsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        streamId: streamId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GiftTransactionModel>> createElement() {
    return _StreamGiftsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreamGiftsProvider &&
        other.streamId == streamId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, streamId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StreamGiftsRef
    on AutoDisposeFutureProviderRef<List<GiftTransactionModel>> {
  /// The parameter `streamId` of this provider.
  String get streamId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _StreamGiftsProviderElement
    extends AutoDisposeFutureProviderElement<List<GiftTransactionModel>>
    with StreamGiftsRef {
  _StreamGiftsProviderElement(super.provider);

  @override
  String get streamId => (origin as StreamGiftsProvider).streamId;
  @override
  int get limit => (origin as StreamGiftsProvider).limit;
}

String _$giftLeaderboardHash() => r'cb395c02d933c98acf3bf7badd6578529469842f';

/// Get gift leaderboard
///
/// Copied from [giftLeaderboard].
@ProviderFor(giftLeaderboard)
const giftLeaderboardProvider = GiftLeaderboardFamily();

/// Get gift leaderboard
///
/// Copied from [giftLeaderboard].
class GiftLeaderboardFamily
    extends Family<AsyncValue<List<GiftLeaderboardEntry>>> {
  /// Get gift leaderboard
  ///
  /// Copied from [giftLeaderboard].
  const GiftLeaderboardFamily();

  /// Get gift leaderboard
  ///
  /// Copied from [giftLeaderboard].
  GiftLeaderboardProvider call(
    String streamId, {
    int limit = 10,
  }) {
    return GiftLeaderboardProvider(
      streamId,
      limit: limit,
    );
  }

  @override
  GiftLeaderboardProvider getProviderOverride(
    covariant GiftLeaderboardProvider provider,
  ) {
    return call(
      provider.streamId,
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
  String? get name => r'giftLeaderboardProvider';
}

/// Get gift leaderboard
///
/// Copied from [giftLeaderboard].
class GiftLeaderboardProvider
    extends AutoDisposeFutureProvider<List<GiftLeaderboardEntry>> {
  /// Get gift leaderboard
  ///
  /// Copied from [giftLeaderboard].
  GiftLeaderboardProvider(
    String streamId, {
    int limit = 10,
  }) : this._internal(
          (ref) => giftLeaderboard(
            ref as GiftLeaderboardRef,
            streamId,
            limit: limit,
          ),
          from: giftLeaderboardProvider,
          name: r'giftLeaderboardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$giftLeaderboardHash,
          dependencies: GiftLeaderboardFamily._dependencies,
          allTransitiveDependencies:
              GiftLeaderboardFamily._allTransitiveDependencies,
          streamId: streamId,
          limit: limit,
        );

  GiftLeaderboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.streamId,
    required this.limit,
  }) : super.internal();

  final String streamId;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<GiftLeaderboardEntry>> Function(GiftLeaderboardRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GiftLeaderboardProvider._internal(
        (ref) => create(ref as GiftLeaderboardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        streamId: streamId,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<GiftLeaderboardEntry>> createElement() {
    return _GiftLeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GiftLeaderboardProvider &&
        other.streamId == streamId &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, streamId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GiftLeaderboardRef
    on AutoDisposeFutureProviderRef<List<GiftLeaderboardEntry>> {
  /// The parameter `streamId` of this provider.
  String get streamId;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _GiftLeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<List<GiftLeaderboardEntry>>
    with GiftLeaderboardRef {
  _GiftLeaderboardProviderElement(super.provider);

  @override
  String get streamId => (origin as GiftLeaderboardProvider).streamId;
  @override
  int get limit => (origin as GiftLeaderboardProvider).limit;
}

String _$agoraServiceProviderHash() =>
    r'c47ea951a510b301999170fcbfb432c9194a9048';

/// See also [AgoraServiceProvider].
@ProviderFor(AgoraServiceProvider)
final agoraServiceProviderProvider =
    AutoDisposeNotifierProvider<AgoraServiceProvider, AgoraService>.internal(
  AgoraServiceProvider.new,
  name: r'agoraServiceProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$agoraServiceProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AgoraServiceProvider = AutoDisposeNotifier<AgoraService>;
String _$currentLiveStreamHash() => r'c0eb205c49886ea7018f402f4a9158cfc05ea155';

/// Current live stream state (for hosts)
///
/// Copied from [CurrentLiveStream].
@ProviderFor(CurrentLiveStream)
final currentLiveStreamProvider = AutoDisposeNotifierProvider<CurrentLiveStream,
    RefinedLiveStreamModel?>.internal(
  CurrentLiveStream.new,
  name: r'currentLiveStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLiveStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentLiveStream = AutoDisposeNotifier<RefinedLiveStreamModel?>;
String _$joinedLiveStreamHash() => r'661ec454018ee60ee4ac5daa474ec64cdea75027';

/// Joined live stream state (for viewers)
///
/// Copied from [JoinedLiveStream].
@ProviderFor(JoinedLiveStream)
final joinedLiveStreamProvider = AutoDisposeNotifierProvider<JoinedLiveStream,
    RefinedLiveStreamModel?>.internal(
  JoinedLiveStream.new,
  name: r'joinedLiveStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$joinedLiveStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$JoinedLiveStream = AutoDisposeNotifier<RefinedLiveStreamModel?>;
String _$streamViewerCountHash() => r'cb8bfd4f3b8c41adc9883c78cd92be12177a6ce3';

abstract class _$StreamViewerCount extends BuildlessAutoDisposeNotifier<int> {
  late final String streamId;

  int build(
    String streamId,
  );
}

/// Stream viewer count (real-time)
///
/// Copied from [StreamViewerCount].
@ProviderFor(StreamViewerCount)
const streamViewerCountProvider = StreamViewerCountFamily();

/// Stream viewer count (real-time)
///
/// Copied from [StreamViewerCount].
class StreamViewerCountFamily extends Family<int> {
  /// Stream viewer count (real-time)
  ///
  /// Copied from [StreamViewerCount].
  const StreamViewerCountFamily();

  /// Stream viewer count (real-time)
  ///
  /// Copied from [StreamViewerCount].
  StreamViewerCountProvider call(
    String streamId,
  ) {
    return StreamViewerCountProvider(
      streamId,
    );
  }

  @override
  StreamViewerCountProvider getProviderOverride(
    covariant StreamViewerCountProvider provider,
  ) {
    return call(
      provider.streamId,
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
  String? get name => r'streamViewerCountProvider';
}

/// Stream viewer count (real-time)
///
/// Copied from [StreamViewerCount].
class StreamViewerCountProvider
    extends AutoDisposeNotifierProviderImpl<StreamViewerCount, int> {
  /// Stream viewer count (real-time)
  ///
  /// Copied from [StreamViewerCount].
  StreamViewerCountProvider(
    String streamId,
  ) : this._internal(
          () => StreamViewerCount()..streamId = streamId,
          from: streamViewerCountProvider,
          name: r'streamViewerCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$streamViewerCountHash,
          dependencies: StreamViewerCountFamily._dependencies,
          allTransitiveDependencies:
              StreamViewerCountFamily._allTransitiveDependencies,
          streamId: streamId,
        );

  StreamViewerCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.streamId,
  }) : super.internal();

  final String streamId;

  @override
  int runNotifierBuild(
    covariant StreamViewerCount notifier,
  ) {
    return notifier.build(
      streamId,
    );
  }

  @override
  Override overrideWith(StreamViewerCount Function() create) {
    return ProviderOverride(
      origin: this,
      override: StreamViewerCountProvider._internal(
        () => create()..streamId = streamId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        streamId: streamId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<StreamViewerCount, int> createElement() {
    return _StreamViewerCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StreamViewerCountProvider && other.streamId == streamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, streamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StreamViewerCountRef on AutoDisposeNotifierProviderRef<int> {
  /// The parameter `streamId` of this provider.
  String get streamId;
}

class _StreamViewerCountProviderElement
    extends AutoDisposeNotifierProviderElement<StreamViewerCount, int>
    with StreamViewerCountRef {
  _StreamViewerCountProviderElement(super.provider);

  @override
  String get streamId => (origin as StreamViewerCountProvider).streamId;
}

String _$liveStreamSettingsHash() =>
    r'117b3608996b369c00bc0d8f5740ee28f65192fd';

/// Live streaming settings (video quality, etc.)
///
/// Copied from [LiveStreamSettings].
@ProviderFor(LiveStreamSettings)
final liveStreamSettingsProvider = AutoDisposeNotifierProvider<
    LiveStreamSettings, LiveStreamSettingsState>.internal(
  LiveStreamSettings.new,
  name: r'liveStreamSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$liveStreamSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LiveStreamSettings = AutoDisposeNotifier<LiveStreamSettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
