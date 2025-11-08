// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$shopRepositoryHash() => r'9f5379d716fcb45a949d95e8613c7e1bc3dd2548';

/// See also [shopRepository].
@ProviderFor(shopRepository)
final shopRepositoryProvider = AutoDisposeProvider<ShopRepository>.internal(
  shopRepository,
  name: r'shopRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$shopRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ShopRepositoryRef = AutoDisposeProviderRef<ShopRepository>;
String _$orderRepositoryHash() => r'9253d73f04ce8fb2e624da9bd81ad25a644540cd';

/// See also [orderRepository].
@ProviderFor(orderRepository)
final orderRepositoryProvider = AutoDisposeProvider<OrderRepository>.internal(
  orderRepository,
  name: r'orderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderRepositoryRef = AutoDisposeProviderRef<OrderRepository>;
String _$inventoryRepositoryHash() =>
    r'8fa5838e9d220a811ee0ba9bfac5d955da522c62';

/// See also [inventoryRepository].
@ProviderFor(inventoryRepository)
final inventoryRepositoryProvider =
    AutoDisposeProvider<InventoryRepository>.internal(
  inventoryRepository,
  name: r'inventoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InventoryRepositoryRef = AutoDisposeProviderRef<InventoryRepository>;
String _$commissionRepositoryHash() =>
    r'e83836e695fd5261daa9b10e24dfe5e315ae3876';

/// See also [commissionRepository].
@ProviderFor(commissionRepository)
final commissionRepositoryProvider =
    AutoDisposeProvider<CommissionRepository>.internal(
  commissionRepository,
  name: r'commissionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commissionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommissionRepositoryRef = AutoDisposeProviderRef<CommissionRepository>;
String _$cartServiceHash() => r'e657a90351ac40738cfa33a1a3b730bc54edce49';

/// See also [cartService].
@ProviderFor(cartService)
final cartServiceProvider = AutoDisposeFutureProvider<CartService>.internal(
  cartService,
  name: r'cartServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartServiceRef = AutoDisposeFutureProviderRef<CartService>;
String _$shopHash() => r'0e4dc0a11d30fafdd25560022b95e18617098706';

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

/// Get shop by ID
///
/// Copied from [shop].
@ProviderFor(shop)
const shopProvider = ShopFamily();

/// Get shop by ID
///
/// Copied from [shop].
class ShopFamily extends Family<AsyncValue<ShopModel>> {
  /// Get shop by ID
  ///
  /// Copied from [shop].
  const ShopFamily();

  /// Get shop by ID
  ///
  /// Copied from [shop].
  ShopProvider call(
    String shopId,
  ) {
    return ShopProvider(
      shopId,
    );
  }

  @override
  ShopProvider getProviderOverride(
    covariant ShopProvider provider,
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
  String? get name => r'shopProvider';
}

/// Get shop by ID
///
/// Copied from [shop].
class ShopProvider extends AutoDisposeFutureProvider<ShopModel> {
  /// Get shop by ID
  ///
  /// Copied from [shop].
  ShopProvider(
    String shopId,
  ) : this._internal(
          (ref) => shop(
            ref as ShopRef,
            shopId,
          ),
          from: shopProvider,
          name: r'shopProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product') ? null : _$shopHash,
          dependencies: ShopFamily._dependencies,
          allTransitiveDependencies: ShopFamily._allTransitiveDependencies,
          shopId: shopId,
        );

  ShopProvider._internal(
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
    FutureOr<ShopModel> Function(ShopRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopProvider._internal(
        (ref) => create(ref as ShopRef),
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
  AutoDisposeFutureProviderElement<ShopModel> createElement() {
    return _ShopProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopProvider && other.shopId == shopId;
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
mixin ShopRef on AutoDisposeFutureProviderRef<ShopModel> {
  /// The parameter `shopId` of this provider.
  String get shopId;
}

class _ShopProviderElement extends AutoDisposeFutureProviderElement<ShopModel>
    with ShopRef {
  _ShopProviderElement(super.provider);

  @override
  String get shopId => (origin as ShopProvider).shopId;
}

String _$shopByOwnerHash() => r'4dd26fa2e1a2eee5c2ee0ec47ae7b955207ce0f8';

/// Get shop by owner ID
///
/// Copied from [shopByOwner].
@ProviderFor(shopByOwner)
const shopByOwnerProvider = ShopByOwnerFamily();

/// Get shop by owner ID
///
/// Copied from [shopByOwner].
class ShopByOwnerFamily extends Family<AsyncValue<ShopModel?>> {
  /// Get shop by owner ID
  ///
  /// Copied from [shopByOwner].
  const ShopByOwnerFamily();

  /// Get shop by owner ID
  ///
  /// Copied from [shopByOwner].
  ShopByOwnerProvider call(
    String ownerId,
  ) {
    return ShopByOwnerProvider(
      ownerId,
    );
  }

  @override
  ShopByOwnerProvider getProviderOverride(
    covariant ShopByOwnerProvider provider,
  ) {
    return call(
      provider.ownerId,
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
  String? get name => r'shopByOwnerProvider';
}

/// Get shop by owner ID
///
/// Copied from [shopByOwner].
class ShopByOwnerProvider extends AutoDisposeFutureProvider<ShopModel?> {
  /// Get shop by owner ID
  ///
  /// Copied from [shopByOwner].
  ShopByOwnerProvider(
    String ownerId,
  ) : this._internal(
          (ref) => shopByOwner(
            ref as ShopByOwnerRef,
            ownerId,
          ),
          from: shopByOwnerProvider,
          name: r'shopByOwnerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopByOwnerHash,
          dependencies: ShopByOwnerFamily._dependencies,
          allTransitiveDependencies:
              ShopByOwnerFamily._allTransitiveDependencies,
          ownerId: ownerId,
        );

  ShopByOwnerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ownerId,
  }) : super.internal();

  final String ownerId;

  @override
  Override overrideWith(
    FutureOr<ShopModel?> Function(ShopByOwnerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopByOwnerProvider._internal(
        (ref) => create(ref as ShopByOwnerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ownerId: ownerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ShopModel?> createElement() {
    return _ShopByOwnerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopByOwnerProvider && other.ownerId == ownerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ownerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopByOwnerRef on AutoDisposeFutureProviderRef<ShopModel?> {
  /// The parameter `ownerId` of this provider.
  String get ownerId;
}

class _ShopByOwnerProviderElement
    extends AutoDisposeFutureProviderElement<ShopModel?> with ShopByOwnerRef {
  _ShopByOwnerProviderElement(super.provider);

  @override
  String get ownerId => (origin as ShopByOwnerProvider).ownerId;
}

String _$shopsHash() => r'1e415776b09ec6caf2126b9e4feb3e58998bb4cd';

/// Get all shops with filters
///
/// Copied from [shops].
@ProviderFor(shops)
const shopsProvider = ShopsFamily();

/// Get all shops with filters
///
/// Copied from [shops].
class ShopsFamily extends Family<AsyncValue<List<ShopModel>>> {
  /// Get all shops with filters
  ///
  /// Copied from [shops].
  const ShopsFamily();

  /// Get all shops with filters
  ///
  /// Copied from [shops].
  ShopsProvider call({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? tag,
    bool? isVerified,
    bool? isFeatured,
    String? sortBy,
  }) {
    return ShopsProvider(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
      tag: tag,
      isVerified: isVerified,
      isFeatured: isFeatured,
      sortBy: sortBy,
    );
  }

  @override
  ShopsProvider getProviderOverride(
    covariant ShopsProvider provider,
  ) {
    return call(
      limit: provider.limit,
      offset: provider.offset,
      searchQuery: provider.searchQuery,
      tag: provider.tag,
      isVerified: provider.isVerified,
      isFeatured: provider.isFeatured,
      sortBy: provider.sortBy,
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
  String? get name => r'shopsProvider';
}

/// Get all shops with filters
///
/// Copied from [shops].
class ShopsProvider extends AutoDisposeFutureProvider<List<ShopModel>> {
  /// Get all shops with filters
  ///
  /// Copied from [shops].
  ShopsProvider({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? tag,
    bool? isVerified,
    bool? isFeatured,
    String? sortBy,
  }) : this._internal(
          (ref) => shops(
            ref as ShopsRef,
            limit: limit,
            offset: offset,
            searchQuery: searchQuery,
            tag: tag,
            isVerified: isVerified,
            isFeatured: isFeatured,
            sortBy: sortBy,
          ),
          from: shopsProvider,
          name: r'shopsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopsHash,
          dependencies: ShopsFamily._dependencies,
          allTransitiveDependencies: ShopsFamily._allTransitiveDependencies,
          limit: limit,
          offset: offset,
          searchQuery: searchQuery,
          tag: tag,
          isVerified: isVerified,
          isFeatured: isFeatured,
          sortBy: sortBy,
        );

  ShopsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
    required this.offset,
    required this.searchQuery,
    required this.tag,
    required this.isVerified,
    required this.isFeatured,
    required this.sortBy,
  }) : super.internal();

  final int limit;
  final int offset;
  final String? searchQuery;
  final String? tag;
  final bool? isVerified;
  final bool? isFeatured;
  final String? sortBy;

  @override
  Override overrideWith(
    FutureOr<List<ShopModel>> Function(ShopsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopsProvider._internal(
        (ref) => create(ref as ShopsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        tag: tag,
        isVerified: isVerified,
        isFeatured: isFeatured,
        sortBy: sortBy,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ShopModel>> createElement() {
    return _ShopsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopsProvider &&
        other.limit == limit &&
        other.offset == offset &&
        other.searchQuery == searchQuery &&
        other.tag == tag &&
        other.isVerified == isVerified &&
        other.isFeatured == isFeatured &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, searchQuery.hashCode);
    hash = _SystemHash.combine(hash, tag.hashCode);
    hash = _SystemHash.combine(hash, isVerified.hashCode);
    hash = _SystemHash.combine(hash, isFeatured.hashCode);
    hash = _SystemHash.combine(hash, sortBy.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopsRef on AutoDisposeFutureProviderRef<List<ShopModel>> {
  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `searchQuery` of this provider.
  String? get searchQuery;

  /// The parameter `tag` of this provider.
  String? get tag;

  /// The parameter `isVerified` of this provider.
  bool? get isVerified;

  /// The parameter `isFeatured` of this provider.
  bool? get isFeatured;

  /// The parameter `sortBy` of this provider.
  String? get sortBy;
}

class _ShopsProviderElement
    extends AutoDisposeFutureProviderElement<List<ShopModel>> with ShopsRef {
  _ShopsProviderElement(super.provider);

  @override
  int get limit => (origin as ShopsProvider).limit;
  @override
  int get offset => (origin as ShopsProvider).offset;
  @override
  String? get searchQuery => (origin as ShopsProvider).searchQuery;
  @override
  String? get tag => (origin as ShopsProvider).tag;
  @override
  bool? get isVerified => (origin as ShopsProvider).isVerified;
  @override
  bool? get isFeatured => (origin as ShopsProvider).isFeatured;
  @override
  String? get sortBy => (origin as ShopsProvider).sortBy;
}

String _$featuredShopsHash() => r'c9330f84c12a0b9efb912370495f6fe2c4dc78cb';

/// Get featured shops
///
/// Copied from [featuredShops].
@ProviderFor(featuredShops)
final featuredShopsProvider =
    AutoDisposeFutureProvider<List<ShopModel>>.internal(
  featuredShops,
  name: r'featuredShopsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$featuredShopsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeaturedShopsRef = AutoDisposeFutureProviderRef<List<ShopModel>>;
String _$verifiedShopsHash() => r'205401c28c082a1b0c79140ac89a241fef053577';

/// Get verified shops
///
/// Copied from [verifiedShops].
@ProviderFor(verifiedShops)
final verifiedShopsProvider =
    AutoDisposeFutureProvider<List<ShopModel>>.internal(
  verifiedShops,
  name: r'verifiedShopsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$verifiedShopsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VerifiedShopsRef = AutoDisposeFutureProviderRef<List<ShopModel>>;
String _$followedShopsHash() => r'8805a693100a237077982a4236675ede35f65d4b';

/// Get shops followed by user
///
/// Copied from [followedShops].
@ProviderFor(followedShops)
const followedShopsProvider = FollowedShopsFamily();

/// Get shops followed by user
///
/// Copied from [followedShops].
class FollowedShopsFamily extends Family<AsyncValue<List<ShopModel>>> {
  /// Get shops followed by user
  ///
  /// Copied from [followedShops].
  const FollowedShopsFamily();

  /// Get shops followed by user
  ///
  /// Copied from [followedShops].
  FollowedShopsProvider call(
    String userId,
  ) {
    return FollowedShopsProvider(
      userId,
    );
  }

  @override
  FollowedShopsProvider getProviderOverride(
    covariant FollowedShopsProvider provider,
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
  String? get name => r'followedShopsProvider';
}

/// Get shops followed by user
///
/// Copied from [followedShops].
class FollowedShopsProvider extends AutoDisposeFutureProvider<List<ShopModel>> {
  /// Get shops followed by user
  ///
  /// Copied from [followedShops].
  FollowedShopsProvider(
    String userId,
  ) : this._internal(
          (ref) => followedShops(
            ref as FollowedShopsRef,
            userId,
          ),
          from: followedShopsProvider,
          name: r'followedShopsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$followedShopsHash,
          dependencies: FollowedShopsFamily._dependencies,
          allTransitiveDependencies:
              FollowedShopsFamily._allTransitiveDependencies,
          userId: userId,
        );

  FollowedShopsProvider._internal(
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
    FutureOr<List<ShopModel>> Function(FollowedShopsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FollowedShopsProvider._internal(
        (ref) => create(ref as FollowedShopsRef),
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
  AutoDisposeFutureProviderElement<List<ShopModel>> createElement() {
    return _FollowedShopsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowedShopsProvider && other.userId == userId;
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
mixin FollowedShopsRef on AutoDisposeFutureProviderRef<List<ShopModel>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FollowedShopsProviderElement
    extends AutoDisposeFutureProviderElement<List<ShopModel>>
    with FollowedShopsRef {
  _FollowedShopsProviderElement(super.provider);

  @override
  String get userId => (origin as FollowedShopsProvider).userId;
}

String _$shopProductsHash() => r'ff3cdb3e38b202deb7caa99e00f8035d79f714ed';

/// Get products for a shop
///
/// Copied from [shopProducts].
@ProviderFor(shopProducts)
const shopProductsProvider = ShopProductsFamily();

/// Get products for a shop
///
/// Copied from [shopProducts].
class ShopProductsFamily extends Family<AsyncValue<List<ProductModel>>> {
  /// Get products for a shop
  ///
  /// Copied from [shopProducts].
  const ShopProductsFamily();

  /// Get products for a shop
  ///
  /// Copied from [shopProducts].
  ShopProductsProvider call(
    String shopId, {
    int limit = 20,
    int offset = 0,
    bool? isActive,
    bool? isFeatured,
    bool? flashSale,
  }) {
    return ShopProductsProvider(
      shopId,
      limit: limit,
      offset: offset,
      isActive: isActive,
      isFeatured: isFeatured,
      flashSale: flashSale,
    );
  }

  @override
  ShopProductsProvider getProviderOverride(
    covariant ShopProductsProvider provider,
  ) {
    return call(
      provider.shopId,
      limit: provider.limit,
      offset: provider.offset,
      isActive: provider.isActive,
      isFeatured: provider.isFeatured,
      flashSale: provider.flashSale,
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
  String? get name => r'shopProductsProvider';
}

/// Get products for a shop
///
/// Copied from [shopProducts].
class ShopProductsProvider
    extends AutoDisposeFutureProvider<List<ProductModel>> {
  /// Get products for a shop
  ///
  /// Copied from [shopProducts].
  ShopProductsProvider(
    String shopId, {
    int limit = 20,
    int offset = 0,
    bool? isActive,
    bool? isFeatured,
    bool? flashSale,
  }) : this._internal(
          (ref) => shopProducts(
            ref as ShopProductsRef,
            shopId,
            limit: limit,
            offset: offset,
            isActive: isActive,
            isFeatured: isFeatured,
            flashSale: flashSale,
          ),
          from: shopProductsProvider,
          name: r'shopProductsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopProductsHash,
          dependencies: ShopProductsFamily._dependencies,
          allTransitiveDependencies:
              ShopProductsFamily._allTransitiveDependencies,
          shopId: shopId,
          limit: limit,
          offset: offset,
          isActive: isActive,
          isFeatured: isFeatured,
          flashSale: flashSale,
        );

  ShopProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shopId,
    required this.limit,
    required this.offset,
    required this.isActive,
    required this.isFeatured,
    required this.flashSale,
  }) : super.internal();

  final String shopId;
  final int limit;
  final int offset;
  final bool? isActive;
  final bool? isFeatured;
  final bool? flashSale;

  @override
  Override overrideWith(
    FutureOr<List<ProductModel>> Function(ShopProductsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopProductsProvider._internal(
        (ref) => create(ref as ShopProductsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shopId: shopId,
        limit: limit,
        offset: offset,
        isActive: isActive,
        isFeatured: isFeatured,
        flashSale: flashSale,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ProductModel>> createElement() {
    return _ShopProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopProductsProvider &&
        other.shopId == shopId &&
        other.limit == limit &&
        other.offset == offset &&
        other.isActive == isActive &&
        other.isFeatured == isFeatured &&
        other.flashSale == flashSale;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shopId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, isActive.hashCode);
    hash = _SystemHash.combine(hash, isFeatured.hashCode);
    hash = _SystemHash.combine(hash, flashSale.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopProductsRef on AutoDisposeFutureProviderRef<List<ProductModel>> {
  /// The parameter `shopId` of this provider.
  String get shopId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `isActive` of this provider.
  bool? get isActive;

  /// The parameter `isFeatured` of this provider.
  bool? get isFeatured;

  /// The parameter `flashSale` of this provider.
  bool? get flashSale;
}

class _ShopProductsProviderElement
    extends AutoDisposeFutureProviderElement<List<ProductModel>>
    with ShopProductsRef {
  _ShopProductsProviderElement(super.provider);

  @override
  String get shopId => (origin as ShopProductsProvider).shopId;
  @override
  int get limit => (origin as ShopProductsProvider).limit;
  @override
  int get offset => (origin as ShopProductsProvider).offset;
  @override
  bool? get isActive => (origin as ShopProductsProvider).isActive;
  @override
  bool? get isFeatured => (origin as ShopProductsProvider).isFeatured;
  @override
  bool? get flashSale => (origin as ShopProductsProvider).flashSale;
}

String _$cartItemCountHash() => r'aafb2b7c085ce59c6e316a569bc72075e580a1a7';

/// Cart item count
///
/// Copied from [cartItemCount].
@ProviderFor(cartItemCount)
final cartItemCountProvider = AutoDisposeFutureProvider<int>.internal(
  cartItemCount,
  name: r'cartItemCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartItemCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartItemCountRef = AutoDisposeFutureProviderRef<int>;
String _$cartTotalHash() => r'e346a216d0f2b8a725b6a982e246bb46c7d8f594';

/// Cart total
///
/// Copied from [cartTotal].
@ProviderFor(cartTotal)
final cartTotalProvider = AutoDisposeFutureProvider<double>.internal(
  cartTotal,
  name: r'cartTotalProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartTotalRef = AutoDisposeFutureProviderRef<double>;
String _$isProductInCartHash() => r'fc013095196d2ff0ab9fb609d6a9dd9eafb4c7a4';

/// Check if product is in cart
///
/// Copied from [isProductInCart].
@ProviderFor(isProductInCart)
const isProductInCartProvider = IsProductInCartFamily();

/// Check if product is in cart
///
/// Copied from [isProductInCart].
class IsProductInCartFamily extends Family<AsyncValue<bool>> {
  /// Check if product is in cart
  ///
  /// Copied from [isProductInCart].
  const IsProductInCartFamily();

  /// Check if product is in cart
  ///
  /// Copied from [isProductInCart].
  IsProductInCartProvider call(
    String productId,
  ) {
    return IsProductInCartProvider(
      productId,
    );
  }

  @override
  IsProductInCartProvider getProviderOverride(
    covariant IsProductInCartProvider provider,
  ) {
    return call(
      provider.productId,
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
  String? get name => r'isProductInCartProvider';
}

/// Check if product is in cart
///
/// Copied from [isProductInCart].
class IsProductInCartProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if product is in cart
  ///
  /// Copied from [isProductInCart].
  IsProductInCartProvider(
    String productId,
  ) : this._internal(
          (ref) => isProductInCart(
            ref as IsProductInCartRef,
            productId,
          ),
          from: isProductInCartProvider,
          name: r'isProductInCartProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isProductInCartHash,
          dependencies: IsProductInCartFamily._dependencies,
          allTransitiveDependencies:
              IsProductInCartFamily._allTransitiveDependencies,
          productId: productId,
        );

  IsProductInCartProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsProductInCartRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsProductInCartProvider._internal(
        (ref) => create(ref as IsProductInCartRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsProductInCartProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsProductInCartProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsProductInCartRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _IsProductInCartProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsProductInCartRef {
  _IsProductInCartProviderElement(super.provider);

  @override
  String get productId => (origin as IsProductInCartProvider).productId;
}

String _$buyerOrdersHash() => r'f189ceff4a3767deab9fdc1f4586f911e96dac91';

/// Get buyer's orders
///
/// Copied from [buyerOrders].
@ProviderFor(buyerOrders)
const buyerOrdersProvider = BuyerOrdersFamily();

/// Get buyer's orders
///
/// Copied from [buyerOrders].
class BuyerOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Get buyer's orders
  ///
  /// Copied from [buyerOrders].
  const BuyerOrdersFamily();

  /// Get buyer's orders
  ///
  /// Copied from [buyerOrders].
  BuyerOrdersProvider call(
    String buyerId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) {
    return BuyerOrdersProvider(
      buyerId,
      limit: limit,
      offset: offset,
      status: status,
    );
  }

  @override
  BuyerOrdersProvider getProviderOverride(
    covariant BuyerOrdersProvider provider,
  ) {
    return call(
      provider.buyerId,
      limit: provider.limit,
      offset: provider.offset,
      status: provider.status,
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
  String? get name => r'buyerOrdersProvider';
}

/// Get buyer's orders
///
/// Copied from [buyerOrders].
class BuyerOrdersProvider extends AutoDisposeFutureProvider<List<OrderModel>> {
  /// Get buyer's orders
  ///
  /// Copied from [buyerOrders].
  BuyerOrdersProvider(
    String buyerId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) : this._internal(
          (ref) => buyerOrders(
            ref as BuyerOrdersRef,
            buyerId,
            limit: limit,
            offset: offset,
            status: status,
          ),
          from: buyerOrdersProvider,
          name: r'buyerOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$buyerOrdersHash,
          dependencies: BuyerOrdersFamily._dependencies,
          allTransitiveDependencies:
              BuyerOrdersFamily._allTransitiveDependencies,
          buyerId: buyerId,
          limit: limit,
          offset: offset,
          status: status,
        );

  BuyerOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.buyerId,
    required this.limit,
    required this.offset,
    required this.status,
  }) : super.internal();

  final String buyerId;
  final int limit;
  final int offset;
  final OrderStatus? status;

  @override
  Override overrideWith(
    FutureOr<List<OrderModel>> Function(BuyerOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BuyerOrdersProvider._internal(
        (ref) => create(ref as BuyerOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        buyerId: buyerId,
        limit: limit,
        offset: offset,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OrderModel>> createElement() {
    return _BuyerOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BuyerOrdersProvider &&
        other.buyerId == buyerId &&
        other.limit == limit &&
        other.offset == offset &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, buyerId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BuyerOrdersRef on AutoDisposeFutureProviderRef<List<OrderModel>> {
  /// The parameter `buyerId` of this provider.
  String get buyerId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `status` of this provider.
  OrderStatus? get status;
}

class _BuyerOrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<OrderModel>>
    with BuyerOrdersRef {
  _BuyerOrdersProviderElement(super.provider);

  @override
  String get buyerId => (origin as BuyerOrdersProvider).buyerId;
  @override
  int get limit => (origin as BuyerOrdersProvider).limit;
  @override
  int get offset => (origin as BuyerOrdersProvider).offset;
  @override
  OrderStatus? get status => (origin as BuyerOrdersProvider).status;
}

String _$sellerOrdersHash() => r'9031efeb11893b6efefb5e35f321782df4d9fa40';

/// Get seller's orders
///
/// Copied from [sellerOrders].
@ProviderFor(sellerOrders)
const sellerOrdersProvider = SellerOrdersFamily();

/// Get seller's orders
///
/// Copied from [sellerOrders].
class SellerOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Get seller's orders
  ///
  /// Copied from [sellerOrders].
  const SellerOrdersFamily();

  /// Get seller's orders
  ///
  /// Copied from [sellerOrders].
  SellerOrdersProvider call(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) {
    return SellerOrdersProvider(
      sellerId,
      limit: limit,
      offset: offset,
      status: status,
    );
  }

  @override
  SellerOrdersProvider getProviderOverride(
    covariant SellerOrdersProvider provider,
  ) {
    return call(
      provider.sellerId,
      limit: provider.limit,
      offset: provider.offset,
      status: provider.status,
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
  String? get name => r'sellerOrdersProvider';
}

/// Get seller's orders
///
/// Copied from [sellerOrders].
class SellerOrdersProvider extends AutoDisposeFutureProvider<List<OrderModel>> {
  /// Get seller's orders
  ///
  /// Copied from [sellerOrders].
  SellerOrdersProvider(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) : this._internal(
          (ref) => sellerOrders(
            ref as SellerOrdersRef,
            sellerId,
            limit: limit,
            offset: offset,
            status: status,
          ),
          from: sellerOrdersProvider,
          name: r'sellerOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sellerOrdersHash,
          dependencies: SellerOrdersFamily._dependencies,
          allTransitiveDependencies:
              SellerOrdersFamily._allTransitiveDependencies,
          sellerId: sellerId,
          limit: limit,
          offset: offset,
          status: status,
        );

  SellerOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.limit,
    required this.offset,
    required this.status,
  }) : super.internal();

  final String sellerId;
  final int limit;
  final int offset;
  final OrderStatus? status;

  @override
  Override overrideWith(
    FutureOr<List<OrderModel>> Function(SellerOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerOrdersProvider._internal(
        (ref) => create(ref as SellerOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        limit: limit,
        offset: offset,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OrderModel>> createElement() {
    return _SellerOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerOrdersProvider &&
        other.sellerId == sellerId &&
        other.limit == limit &&
        other.offset == offset &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerOrdersRef on AutoDisposeFutureProviderRef<List<OrderModel>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `status` of this provider.
  OrderStatus? get status;
}

class _SellerOrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<OrderModel>>
    with SellerOrdersRef {
  _SellerOrdersProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerOrdersProvider).sellerId;
  @override
  int get limit => (origin as SellerOrdersProvider).limit;
  @override
  int get offset => (origin as SellerOrdersProvider).offset;
  @override
  OrderStatus? get status => (origin as SellerOrdersProvider).status;
}

String _$shopOrdersHash() => r'a519bbe1330f33eb833408286b0a4c80dd6fc03c';

/// Get shop's orders
///
/// Copied from [shopOrders].
@ProviderFor(shopOrders)
const shopOrdersProvider = ShopOrdersFamily();

/// Get shop's orders
///
/// Copied from [shopOrders].
class ShopOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Get shop's orders
  ///
  /// Copied from [shopOrders].
  const ShopOrdersFamily();

  /// Get shop's orders
  ///
  /// Copied from [shopOrders].
  ShopOrdersProvider call(
    String shopId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) {
    return ShopOrdersProvider(
      shopId,
      limit: limit,
      offset: offset,
      status: status,
    );
  }

  @override
  ShopOrdersProvider getProviderOverride(
    covariant ShopOrdersProvider provider,
  ) {
    return call(
      provider.shopId,
      limit: provider.limit,
      offset: provider.offset,
      status: provider.status,
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
  String? get name => r'shopOrdersProvider';
}

/// Get shop's orders
///
/// Copied from [shopOrders].
class ShopOrdersProvider extends AutoDisposeFutureProvider<List<OrderModel>> {
  /// Get shop's orders
  ///
  /// Copied from [shopOrders].
  ShopOrdersProvider(
    String shopId, {
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) : this._internal(
          (ref) => shopOrders(
            ref as ShopOrdersRef,
            shopId,
            limit: limit,
            offset: offset,
            status: status,
          ),
          from: shopOrdersProvider,
          name: r'shopOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopOrdersHash,
          dependencies: ShopOrdersFamily._dependencies,
          allTransitiveDependencies:
              ShopOrdersFamily._allTransitiveDependencies,
          shopId: shopId,
          limit: limit,
          offset: offset,
          status: status,
        );

  ShopOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shopId,
    required this.limit,
    required this.offset,
    required this.status,
  }) : super.internal();

  final String shopId;
  final int limit;
  final int offset;
  final OrderStatus? status;

  @override
  Override overrideWith(
    FutureOr<List<OrderModel>> Function(ShopOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopOrdersProvider._internal(
        (ref) => create(ref as ShopOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shopId: shopId,
        limit: limit,
        offset: offset,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OrderModel>> createElement() {
    return _ShopOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopOrdersProvider &&
        other.shopId == shopId &&
        other.limit == limit &&
        other.offset == offset &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shopId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopOrdersRef on AutoDisposeFutureProviderRef<List<OrderModel>> {
  /// The parameter `shopId` of this provider.
  String get shopId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `status` of this provider.
  OrderStatus? get status;
}

class _ShopOrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<OrderModel>>
    with ShopOrdersRef {
  _ShopOrdersProviderElement(super.provider);

  @override
  String get shopId => (origin as ShopOrdersProvider).shopId;
  @override
  int get limit => (origin as ShopOrdersProvider).limit;
  @override
  int get offset => (origin as ShopOrdersProvider).offset;
  @override
  OrderStatus? get status => (origin as ShopOrdersProvider).status;
}

String _$orderHash() => r'fdb75ce7b9b458c818604ed85fdcb8fcc7e10056';

/// Get specific order
///
/// Copied from [order].
@ProviderFor(order)
const orderProvider = OrderFamily();

/// Get specific order
///
/// Copied from [order].
class OrderFamily extends Family<AsyncValue<OrderModel>> {
  /// Get specific order
  ///
  /// Copied from [order].
  const OrderFamily();

  /// Get specific order
  ///
  /// Copied from [order].
  OrderProvider call(
    String orderId,
  ) {
    return OrderProvider(
      orderId,
    );
  }

  @override
  OrderProvider getProviderOverride(
    covariant OrderProvider provider,
  ) {
    return call(
      provider.orderId,
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
  String? get name => r'orderProvider';
}

/// Get specific order
///
/// Copied from [order].
class OrderProvider extends AutoDisposeFutureProvider<OrderModel> {
  /// Get specific order
  ///
  /// Copied from [order].
  OrderProvider(
    String orderId,
  ) : this._internal(
          (ref) => order(
            ref as OrderRef,
            orderId,
          ),
          from: orderProvider,
          name: r'orderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$orderHash,
          dependencies: OrderFamily._dependencies,
          allTransitiveDependencies: OrderFamily._allTransitiveDependencies,
          orderId: orderId,
        );

  OrderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(
    FutureOr<OrderModel> Function(OrderRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OrderProvider._internal(
        (ref) => create(ref as OrderRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<OrderModel> createElement() {
    return _OrderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OrderRef on AutoDisposeFutureProviderRef<OrderModel> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _OrderProviderElement extends AutoDisposeFutureProviderElement<OrderModel>
    with OrderRef {
  _OrderProviderElement(super.provider);

  @override
  String get orderId => (origin as OrderProvider).orderId;
}

String _$liveStreamOrdersHash() => r'5af524d17467877c53598cdb19acf73d425456e4';

/// Get live stream orders
///
/// Copied from [liveStreamOrders].
@ProviderFor(liveStreamOrders)
const liveStreamOrdersProvider = LiveStreamOrdersFamily();

/// Get live stream orders
///
/// Copied from [liveStreamOrders].
class LiveStreamOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Get live stream orders
  ///
  /// Copied from [liveStreamOrders].
  const LiveStreamOrdersFamily();

  /// Get live stream orders
  ///
  /// Copied from [liveStreamOrders].
  LiveStreamOrdersProvider call(
    String liveStreamId,
  ) {
    return LiveStreamOrdersProvider(
      liveStreamId,
    );
  }

  @override
  LiveStreamOrdersProvider getProviderOverride(
    covariant LiveStreamOrdersProvider provider,
  ) {
    return call(
      provider.liveStreamId,
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
  String? get name => r'liveStreamOrdersProvider';
}

/// Get live stream orders
///
/// Copied from [liveStreamOrders].
class LiveStreamOrdersProvider
    extends AutoDisposeFutureProvider<List<OrderModel>> {
  /// Get live stream orders
  ///
  /// Copied from [liveStreamOrders].
  LiveStreamOrdersProvider(
    String liveStreamId,
  ) : this._internal(
          (ref) => liveStreamOrders(
            ref as LiveStreamOrdersRef,
            liveStreamId,
          ),
          from: liveStreamOrdersProvider,
          name: r'liveStreamOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$liveStreamOrdersHash,
          dependencies: LiveStreamOrdersFamily._dependencies,
          allTransitiveDependencies:
              LiveStreamOrdersFamily._allTransitiveDependencies,
          liveStreamId: liveStreamId,
        );

  LiveStreamOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.liveStreamId,
  }) : super.internal();

  final String liveStreamId;

  @override
  Override overrideWith(
    FutureOr<List<OrderModel>> Function(LiveStreamOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LiveStreamOrdersProvider._internal(
        (ref) => create(ref as LiveStreamOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        liveStreamId: liveStreamId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<OrderModel>> createElement() {
    return _LiveStreamOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveStreamOrdersProvider &&
        other.liveStreamId == liveStreamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, liveStreamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LiveStreamOrdersRef on AutoDisposeFutureProviderRef<List<OrderModel>> {
  /// The parameter `liveStreamId` of this provider.
  String get liveStreamId;
}

class _LiveStreamOrdersProviderElement
    extends AutoDisposeFutureProviderElement<List<OrderModel>>
    with LiveStreamOrdersRef {
  _LiveStreamOrdersProviderElement(super.provider);

  @override
  String get liveStreamId => (origin as LiveStreamOrdersProvider).liveStreamId;
}

String _$sellerCommissionsHash() => r'a1708d319bbe79e37a429cc042a78c5bb209080c';

/// Get seller commissions
///
/// Copied from [sellerCommissions].
@ProviderFor(sellerCommissions)
const sellerCommissionsProvider = SellerCommissionsFamily();

/// Get seller commissions
///
/// Copied from [sellerCommissions].
class SellerCommissionsFamily
    extends Family<AsyncValue<List<CommissionModel>>> {
  /// Get seller commissions
  ///
  /// Copied from [sellerCommissions].
  const SellerCommissionsFamily();

  /// Get seller commissions
  ///
  /// Copied from [sellerCommissions].
  SellerCommissionsProvider call(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    CommissionType? type,
    PayoutStatus? payoutStatus,
    String? startDate,
    String? endDate,
  }) {
    return SellerCommissionsProvider(
      sellerId,
      limit: limit,
      offset: offset,
      type: type,
      payoutStatus: payoutStatus,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  SellerCommissionsProvider getProviderOverride(
    covariant SellerCommissionsProvider provider,
  ) {
    return call(
      provider.sellerId,
      limit: provider.limit,
      offset: provider.offset,
      type: provider.type,
      payoutStatus: provider.payoutStatus,
      startDate: provider.startDate,
      endDate: provider.endDate,
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
  String? get name => r'sellerCommissionsProvider';
}

/// Get seller commissions
///
/// Copied from [sellerCommissions].
class SellerCommissionsProvider
    extends AutoDisposeFutureProvider<List<CommissionModel>> {
  /// Get seller commissions
  ///
  /// Copied from [sellerCommissions].
  SellerCommissionsProvider(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    CommissionType? type,
    PayoutStatus? payoutStatus,
    String? startDate,
    String? endDate,
  }) : this._internal(
          (ref) => sellerCommissions(
            ref as SellerCommissionsRef,
            sellerId,
            limit: limit,
            offset: offset,
            type: type,
            payoutStatus: payoutStatus,
            startDate: startDate,
            endDate: endDate,
          ),
          from: sellerCommissionsProvider,
          name: r'sellerCommissionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sellerCommissionsHash,
          dependencies: SellerCommissionsFamily._dependencies,
          allTransitiveDependencies:
              SellerCommissionsFamily._allTransitiveDependencies,
          sellerId: sellerId,
          limit: limit,
          offset: offset,
          type: type,
          payoutStatus: payoutStatus,
          startDate: startDate,
          endDate: endDate,
        );

  SellerCommissionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.limit,
    required this.offset,
    required this.type,
    required this.payoutStatus,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String sellerId;
  final int limit;
  final int offset;
  final CommissionType? type;
  final PayoutStatus? payoutStatus;
  final String? startDate;
  final String? endDate;

  @override
  Override overrideWith(
    FutureOr<List<CommissionModel>> Function(SellerCommissionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerCommissionsProvider._internal(
        (ref) => create(ref as SellerCommissionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        limit: limit,
        offset: offset,
        type: type,
        payoutStatus: payoutStatus,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CommissionModel>> createElement() {
    return _SellerCommissionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerCommissionsProvider &&
        other.sellerId == sellerId &&
        other.limit == limit &&
        other.offset == offset &&
        other.type == type &&
        other.payoutStatus == payoutStatus &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, payoutStatus.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerCommissionsRef
    on AutoDisposeFutureProviderRef<List<CommissionModel>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `type` of this provider.
  CommissionType? get type;

  /// The parameter `payoutStatus` of this provider.
  PayoutStatus? get payoutStatus;

  /// The parameter `startDate` of this provider.
  String? get startDate;

  /// The parameter `endDate` of this provider.
  String? get endDate;
}

class _SellerCommissionsProviderElement
    extends AutoDisposeFutureProviderElement<List<CommissionModel>>
    with SellerCommissionsRef {
  _SellerCommissionsProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerCommissionsProvider).sellerId;
  @override
  int get limit => (origin as SellerCommissionsProvider).limit;
  @override
  int get offset => (origin as SellerCommissionsProvider).offset;
  @override
  CommissionType? get type => (origin as SellerCommissionsProvider).type;
  @override
  PayoutStatus? get payoutStatus =>
      (origin as SellerCommissionsProvider).payoutStatus;
  @override
  String? get startDate => (origin as SellerCommissionsProvider).startDate;
  @override
  String? get endDate => (origin as SellerCommissionsProvider).endDate;
}

String _$sellerEarningsHash() => r'86bf97b53c951eed59f4e4874d6f8bd0a6f1ad74';

/// Get seller earnings summary
///
/// Copied from [sellerEarnings].
@ProviderFor(sellerEarnings)
const sellerEarningsProvider = SellerEarningsFamily();

/// Get seller earnings summary
///
/// Copied from [sellerEarnings].
class SellerEarningsFamily extends Family<AsyncValue<SellerEarningsSummary>> {
  /// Get seller earnings summary
  ///
  /// Copied from [sellerEarnings].
  const SellerEarningsFamily();

  /// Get seller earnings summary
  ///
  /// Copied from [sellerEarnings].
  SellerEarningsProvider call(
    String sellerId, {
    String? startDate,
    String? endDate,
  }) {
    return SellerEarningsProvider(
      sellerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  SellerEarningsProvider getProviderOverride(
    covariant SellerEarningsProvider provider,
  ) {
    return call(
      provider.sellerId,
      startDate: provider.startDate,
      endDate: provider.endDate,
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
  String? get name => r'sellerEarningsProvider';
}

/// Get seller earnings summary
///
/// Copied from [sellerEarnings].
class SellerEarningsProvider
    extends AutoDisposeFutureProvider<SellerEarningsSummary> {
  /// Get seller earnings summary
  ///
  /// Copied from [sellerEarnings].
  SellerEarningsProvider(
    String sellerId, {
    String? startDate,
    String? endDate,
  }) : this._internal(
          (ref) => sellerEarnings(
            ref as SellerEarningsRef,
            sellerId,
            startDate: startDate,
            endDate: endDate,
          ),
          from: sellerEarningsProvider,
          name: r'sellerEarningsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sellerEarningsHash,
          dependencies: SellerEarningsFamily._dependencies,
          allTransitiveDependencies:
              SellerEarningsFamily._allTransitiveDependencies,
          sellerId: sellerId,
          startDate: startDate,
          endDate: endDate,
        );

  SellerEarningsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String sellerId;
  final String? startDate;
  final String? endDate;

  @override
  Override overrideWith(
    FutureOr<SellerEarningsSummary> Function(SellerEarningsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SellerEarningsProvider._internal(
        (ref) => create(ref as SellerEarningsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SellerEarningsSummary> createElement() {
    return _SellerEarningsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerEarningsProvider &&
        other.sellerId == sellerId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SellerEarningsRef on AutoDisposeFutureProviderRef<SellerEarningsSummary> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `startDate` of this provider.
  String? get startDate;

  /// The parameter `endDate` of this provider.
  String? get endDate;
}

class _SellerEarningsProviderElement
    extends AutoDisposeFutureProviderElement<SellerEarningsSummary>
    with SellerEarningsRef {
  _SellerEarningsProviderElement(super.provider);

  @override
  String get sellerId => (origin as SellerEarningsProvider).sellerId;
  @override
  String? get startDate => (origin as SellerEarningsProvider).startDate;
  @override
  String? get endDate => (origin as SellerEarningsProvider).endDate;
}

String _$pendingCommissionsHash() =>
    r'68cff8e8f68706aae95377619188a8f78416e774';

/// Get pending commissions (awaiting payout)
///
/// Copied from [pendingCommissions].
@ProviderFor(pendingCommissions)
const pendingCommissionsProvider = PendingCommissionsFamily();

/// Get pending commissions (awaiting payout)
///
/// Copied from [pendingCommissions].
class PendingCommissionsFamily
    extends Family<AsyncValue<List<CommissionModel>>> {
  /// Get pending commissions (awaiting payout)
  ///
  /// Copied from [pendingCommissions].
  const PendingCommissionsFamily();

  /// Get pending commissions (awaiting payout)
  ///
  /// Copied from [pendingCommissions].
  PendingCommissionsProvider call(
    String sellerId,
  ) {
    return PendingCommissionsProvider(
      sellerId,
    );
  }

  @override
  PendingCommissionsProvider getProviderOverride(
    covariant PendingCommissionsProvider provider,
  ) {
    return call(
      provider.sellerId,
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
  String? get name => r'pendingCommissionsProvider';
}

/// Get pending commissions (awaiting payout)
///
/// Copied from [pendingCommissions].
class PendingCommissionsProvider
    extends AutoDisposeFutureProvider<List<CommissionModel>> {
  /// Get pending commissions (awaiting payout)
  ///
  /// Copied from [pendingCommissions].
  PendingCommissionsProvider(
    String sellerId,
  ) : this._internal(
          (ref) => pendingCommissions(
            ref as PendingCommissionsRef,
            sellerId,
          ),
          from: pendingCommissionsProvider,
          name: r'pendingCommissionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingCommissionsHash,
          dependencies: PendingCommissionsFamily._dependencies,
          allTransitiveDependencies:
              PendingCommissionsFamily._allTransitiveDependencies,
          sellerId: sellerId,
        );

  PendingCommissionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
  }) : super.internal();

  final String sellerId;

  @override
  Override overrideWith(
    FutureOr<List<CommissionModel>> Function(PendingCommissionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingCommissionsProvider._internal(
        (ref) => create(ref as PendingCommissionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CommissionModel>> createElement() {
    return _PendingCommissionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingCommissionsProvider && other.sellerId == sellerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PendingCommissionsRef
    on AutoDisposeFutureProviderRef<List<CommissionModel>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;
}

class _PendingCommissionsProviderElement
    extends AutoDisposeFutureProviderElement<List<CommissionModel>>
    with PendingCommissionsRef {
  _PendingCommissionsProviderElement(super.provider);

  @override
  String get sellerId => (origin as PendingCommissionsProvider).sellerId;
}

String _$payoutHistoryHash() => r'74815f5c5241169db68424d8a9b090df006f377d';

/// Get payout history
///
/// Copied from [payoutHistory].
@ProviderFor(payoutHistory)
const payoutHistoryProvider = PayoutHistoryFamily();

/// Get payout history
///
/// Copied from [payoutHistory].
class PayoutHistoryFamily extends Family<AsyncValue<List<PayoutRequest>>> {
  /// Get payout history
  ///
  /// Copied from [payoutHistory].
  const PayoutHistoryFamily();

  /// Get payout history
  ///
  /// Copied from [payoutHistory].
  PayoutHistoryProvider call(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    String? status,
  }) {
    return PayoutHistoryProvider(
      sellerId,
      limit: limit,
      offset: offset,
      status: status,
    );
  }

  @override
  PayoutHistoryProvider getProviderOverride(
    covariant PayoutHistoryProvider provider,
  ) {
    return call(
      provider.sellerId,
      limit: provider.limit,
      offset: provider.offset,
      status: provider.status,
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
  String? get name => r'payoutHistoryProvider';
}

/// Get payout history
///
/// Copied from [payoutHistory].
class PayoutHistoryProvider
    extends AutoDisposeFutureProvider<List<PayoutRequest>> {
  /// Get payout history
  ///
  /// Copied from [payoutHistory].
  PayoutHistoryProvider(
    String sellerId, {
    int limit = 20,
    int offset = 0,
    String? status,
  }) : this._internal(
          (ref) => payoutHistory(
            ref as PayoutHistoryRef,
            sellerId,
            limit: limit,
            offset: offset,
            status: status,
          ),
          from: payoutHistoryProvider,
          name: r'payoutHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$payoutHistoryHash,
          dependencies: PayoutHistoryFamily._dependencies,
          allTransitiveDependencies:
              PayoutHistoryFamily._allTransitiveDependencies,
          sellerId: sellerId,
          limit: limit,
          offset: offset,
          status: status,
        );

  PayoutHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.limit,
    required this.offset,
    required this.status,
  }) : super.internal();

  final String sellerId;
  final int limit;
  final int offset;
  final String? status;

  @override
  Override overrideWith(
    FutureOr<List<PayoutRequest>> Function(PayoutHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PayoutHistoryProvider._internal(
        (ref) => create(ref as PayoutHistoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        limit: limit,
        offset: offset,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PayoutRequest>> createElement() {
    return _PayoutHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutHistoryProvider &&
        other.sellerId == sellerId &&
        other.limit == limit &&
        other.offset == offset &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PayoutHistoryRef on AutoDisposeFutureProviderRef<List<PayoutRequest>> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `status` of this provider.
  String? get status;
}

class _PayoutHistoryProviderElement
    extends AutoDisposeFutureProviderElement<List<PayoutRequest>>
    with PayoutHistoryRef {
  _PayoutHistoryProviderElement(super.provider);

  @override
  String get sellerId => (origin as PayoutHistoryProvider).sellerId;
  @override
  int get limit => (origin as PayoutHistoryProvider).limit;
  @override
  int get offset => (origin as PayoutHistoryProvider).offset;
  @override
  String? get status => (origin as PayoutHistoryProvider).status;
}

String _$shopCommissionsHash() => r'1dbad5c9f1d0867534b6c996e0ee3eda5111a0f3';

/// Get shop commissions
///
/// Copied from [shopCommissions].
@ProviderFor(shopCommissions)
const shopCommissionsProvider = ShopCommissionsFamily();

/// Get shop commissions
///
/// Copied from [shopCommissions].
class ShopCommissionsFamily extends Family<AsyncValue<List<CommissionModel>>> {
  /// Get shop commissions
  ///
  /// Copied from [shopCommissions].
  const ShopCommissionsFamily();

  /// Get shop commissions
  ///
  /// Copied from [shopCommissions].
  ShopCommissionsProvider call(
    String shopId, {
    int limit = 20,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) {
    return ShopCommissionsProvider(
      shopId,
      limit: limit,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  ShopCommissionsProvider getProviderOverride(
    covariant ShopCommissionsProvider provider,
  ) {
    return call(
      provider.shopId,
      limit: provider.limit,
      offset: provider.offset,
      startDate: provider.startDate,
      endDate: provider.endDate,
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
  String? get name => r'shopCommissionsProvider';
}

/// Get shop commissions
///
/// Copied from [shopCommissions].
class ShopCommissionsProvider
    extends AutoDisposeFutureProvider<List<CommissionModel>> {
  /// Get shop commissions
  ///
  /// Copied from [shopCommissions].
  ShopCommissionsProvider(
    String shopId, {
    int limit = 20,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) : this._internal(
          (ref) => shopCommissions(
            ref as ShopCommissionsRef,
            shopId,
            limit: limit,
            offset: offset,
            startDate: startDate,
            endDate: endDate,
          ),
          from: shopCommissionsProvider,
          name: r'shopCommissionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$shopCommissionsHash,
          dependencies: ShopCommissionsFamily._dependencies,
          allTransitiveDependencies:
              ShopCommissionsFamily._allTransitiveDependencies,
          shopId: shopId,
          limit: limit,
          offset: offset,
          startDate: startDate,
          endDate: endDate,
        );

  ShopCommissionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.shopId,
    required this.limit,
    required this.offset,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String shopId;
  final int limit;
  final int offset;
  final String? startDate;
  final String? endDate;

  @override
  Override overrideWith(
    FutureOr<List<CommissionModel>> Function(ShopCommissionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ShopCommissionsProvider._internal(
        (ref) => create(ref as ShopCommissionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        shopId: shopId,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CommissionModel>> createElement() {
    return _ShopCommissionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ShopCommissionsProvider &&
        other.shopId == shopId &&
        other.limit == limit &&
        other.offset == offset &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, shopId.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);
    hash = _SystemHash.combine(hash, offset.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ShopCommissionsRef
    on AutoDisposeFutureProviderRef<List<CommissionModel>> {
  /// The parameter `shopId` of this provider.
  String get shopId;

  /// The parameter `limit` of this provider.
  int get limit;

  /// The parameter `offset` of this provider.
  int get offset;

  /// The parameter `startDate` of this provider.
  String? get startDate;

  /// The parameter `endDate` of this provider.
  String? get endDate;
}

class _ShopCommissionsProviderElement
    extends AutoDisposeFutureProviderElement<List<CommissionModel>>
    with ShopCommissionsRef {
  _ShopCommissionsProviderElement(super.provider);

  @override
  String get shopId => (origin as ShopCommissionsProvider).shopId;
  @override
  int get limit => (origin as ShopCommissionsProvider).limit;
  @override
  int get offset => (origin as ShopCommissionsProvider).offset;
  @override
  String? get startDate => (origin as ShopCommissionsProvider).startDate;
  @override
  String? get endDate => (origin as ShopCommissionsProvider).endDate;
}

String _$commissionAnalyticsHash() =>
    r'dd91a6aeb72ac8f655f6efb5f54b253788568f2b';

/// Get commission analytics
///
/// Copied from [commissionAnalytics].
@ProviderFor(commissionAnalytics)
const commissionAnalyticsProvider = CommissionAnalyticsFamily();

/// Get commission analytics
///
/// Copied from [commissionAnalytics].
class CommissionAnalyticsFamily
    extends Family<AsyncValue<CommissionAnalytics>> {
  /// Get commission analytics
  ///
  /// Copied from [commissionAnalytics].
  const CommissionAnalyticsFamily();

  /// Get commission analytics
  ///
  /// Copied from [commissionAnalytics].
  CommissionAnalyticsProvider call(
    String sellerId,
    String startDate,
    String endDate,
  ) {
    return CommissionAnalyticsProvider(
      sellerId,
      startDate,
      endDate,
    );
  }

  @override
  CommissionAnalyticsProvider getProviderOverride(
    covariant CommissionAnalyticsProvider provider,
  ) {
    return call(
      provider.sellerId,
      provider.startDate,
      provider.endDate,
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
  String? get name => r'commissionAnalyticsProvider';
}

/// Get commission analytics
///
/// Copied from [commissionAnalytics].
class CommissionAnalyticsProvider
    extends AutoDisposeFutureProvider<CommissionAnalytics> {
  /// Get commission analytics
  ///
  /// Copied from [commissionAnalytics].
  CommissionAnalyticsProvider(
    String sellerId,
    String startDate,
    String endDate,
  ) : this._internal(
          (ref) => commissionAnalytics(
            ref as CommissionAnalyticsRef,
            sellerId,
            startDate,
            endDate,
          ),
          from: commissionAnalyticsProvider,
          name: r'commissionAnalyticsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commissionAnalyticsHash,
          dependencies: CommissionAnalyticsFamily._dependencies,
          allTransitiveDependencies:
              CommissionAnalyticsFamily._allTransitiveDependencies,
          sellerId: sellerId,
          startDate: startDate,
          endDate: endDate,
        );

  CommissionAnalyticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sellerId,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final String sellerId;
  final String startDate;
  final String endDate;

  @override
  Override overrideWith(
    FutureOr<CommissionAnalytics> Function(CommissionAnalyticsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CommissionAnalyticsProvider._internal(
        (ref) => create(ref as CommissionAnalyticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sellerId: sellerId,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CommissionAnalytics> createElement() {
    return _CommissionAnalyticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommissionAnalyticsProvider &&
        other.sellerId == sellerId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sellerId.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommissionAnalyticsRef
    on AutoDisposeFutureProviderRef<CommissionAnalytics> {
  /// The parameter `sellerId` of this provider.
  String get sellerId;

  /// The parameter `startDate` of this provider.
  String get startDate;

  /// The parameter `endDate` of this provider.
  String get endDate;
}

class _CommissionAnalyticsProviderElement
    extends AutoDisposeFutureProviderElement<CommissionAnalytics>
    with CommissionAnalyticsRef {
  _CommissionAnalyticsProviderElement(super.provider);

  @override
  String get sellerId => (origin as CommissionAnalyticsProvider).sellerId;
  @override
  String get startDate => (origin as CommissionAnalyticsProvider).startDate;
  @override
  String get endDate => (origin as CommissionAnalyticsProvider).endDate;
}

String _$cartHash() => r'9b05f93f76c14b8635b9efbd3027bdd7f86b2b4e';

/// Get current cart (auto-refresh)
///
/// Copied from [Cart].
@ProviderFor(Cart)
final cartProvider = AutoDisposeAsyncNotifierProvider<Cart, CartModel>.internal(
  Cart.new,
  name: r'cartProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Cart = AutoDisposeAsyncNotifier<CartModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
