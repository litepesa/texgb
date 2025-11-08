// lib/features/shops/providers/shop_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/shops/repositories/shop_repository.dart';
import 'package:textgb/features/shops/repositories/order_repository.dart';
import 'package:textgb/features/shops/repositories/inventory_repository.dart';
import 'package:textgb/features/shops/repositories/commission_repository.dart';
import 'package:textgb/features/shops/services/cart_service.dart';
import 'package:textgb/features/shops/models/shop_model.dart';
import 'package:textgb/features/shops/models/product_model.dart';
import 'package:textgb/features/shops/models/order_model.dart';
import 'package:textgb/features/shops/models/cart_model.dart';
import 'package:textgb/features/shops/models/commission_model.dart';

part 'shop_providers.g.dart';

// ==================== REPOSITORY PROVIDERS ====================

@riverpod
ShopRepository shopRepository(ShopRepositoryRef ref) {
  return ShopRepository();
}

@riverpod
OrderRepository orderRepository(OrderRepositoryRef ref) {
  return OrderRepository();
}

@riverpod
InventoryRepository inventoryRepository(InventoryRepositoryRef ref) {
  return InventoryRepository();
}

@riverpod
CommissionRepository commissionRepository(CommissionRepositoryRef ref) {
  return CommissionRepository();
}

// ==================== CART SERVICE PROVIDER ====================

@riverpod
Future<CartService> cartService(CartServiceRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CartService(prefs);
}

// ==================== SHOP PROVIDERS ====================

/// Get shop by ID
@riverpod
Future<ShopModel> shop(ShopRef ref, String shopId) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShop(shopId);
}

/// Get shop by owner ID
@riverpod
Future<ShopModel?> shopByOwner(ShopByOwnerRef ref, String ownerId) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShopByOwner(ownerId);
}

/// Get all shops with filters
@riverpod
Future<List<ShopModel>> shops(
  ShopsRef ref, {
  int limit = 20,
  int offset = 0,
  String? searchQuery,
  String? tag,
  bool? isVerified,
  bool? isFeatured,
  String? sortBy,
}) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShops(
    limit: limit,
    offset: offset,
    searchQuery: searchQuery,
    tag: tag,
    isVerified: isVerified,
    isFeatured: isFeatured,
    sortBy: sortBy,
  );
}

/// Get featured shops
@riverpod
Future<List<ShopModel>> featuredShops(FeaturedShopsRef ref) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getFeaturedShops();
}

/// Get verified shops
@riverpod
Future<List<ShopModel>> verifiedShops(VerifiedShopsRef ref) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getVerifiedShops();
}

/// Get shops followed by user
@riverpod
Future<List<ShopModel>> followedShops(FollowedShopsRef ref, String userId) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getFollowedShops(userId);
}

// ==================== PRODUCT PROVIDERS ====================

/// Get products for a shop
@riverpod
Future<List<ProductModel>> shopProducts(
  ShopProductsRef ref,
  String shopId, {
  int limit = 20,
  int offset = 0,
  bool? isActive,
  bool? isFeatured,
  bool? flashSale,
}) async {
  final repository = ref.watch(shopRepositoryProvider);
  return repository.getShopProducts(
    shopId: shopId,
    limit: limit,
    offset: offset,
    isActive: isActive,
    isFeatured: isFeatured,
    flashSale: flashSale,
  );
}

// ==================== CART PROVIDERS ====================

/// Get current cart (auto-refresh)
@riverpod
class Cart extends _$Cart {
  @override
  Future<CartModel> build() async {
    final service = await ref.watch(cartServiceProvider.future);
    return service.getCart();
  }

  /// Add item to cart
  Future<void> addItem({
    required String productId,
    required String shopId,
    required String shopName,
    required String productName,
    required String thumbnailUrl,
    required double price,
    required int quantity,
    int? availableStock,
    bool? flashSale,
    double? flashSalePrice,
    String? flashSaleEndsAt,
  }) async {
    final service = await ref.read(cartServiceProvider.future);
    final updatedCart = await service.addItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      thumbnailUrl: thumbnailUrl,
      price: price,
      quantity: quantity,
      availableStock: availableStock,
      flashSale: flashSale,
      flashSalePrice: flashSalePrice,
      flashSaleEndsAt: flashSaleEndsAt,
    );
    state = AsyncValue.data(updatedCart);
  }

  /// Remove item from cart
  Future<void> removeItem(String productId) async {
    final service = await ref.read(cartServiceProvider.future);
    final updatedCart = await service.removeItem(productId);
    state = AsyncValue.data(updatedCart);
  }

  /// Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    final service = await ref.read(cartServiceProvider.future);
    final updatedCart = await service.updateQuantity(productId, quantity);
    state = AsyncValue.data(updatedCart);
  }

  /// Clear cart
  Future<void> clearCart() async {
    final service = await ref.read(cartServiceProvider.future);
    await service.clearCart();
    state = AsyncValue.data(CartModel.empty());
  }

  /// Clear shop cart
  Future<void> clearShopCart(String shopId) async {
    final service = await ref.read(cartServiceProvider.future);
    final updatedCart = await service.clearShopCart(shopId);
    state = AsyncValue.data(updatedCart);
  }

  /// Refresh cart
  Future<void> refresh() async {
    final service = await ref.read(cartServiceProvider.future);
    final cart = await service.getCart();
    state = AsyncValue.data(cart);
  }
}

/// Cart item count
@riverpod
Future<int> cartItemCount(CartItemCountRef ref) async {
  final cart = await ref.watch(cartProvider.future);
  return cart.totalItems;
}

/// Cart total
@riverpod
Future<double> cartTotal(CartTotalRef ref) async {
  final cart = await ref.watch(cartProvider.future);
  return cart.total;
}

/// Check if product is in cart
@riverpod
Future<bool> isProductInCart(IsProductInCartRef ref, String productId) async {
  final cart = await ref.watch(cartProvider.future);
  return cart.items.any((item) => item.productId == productId);
}

// ==================== ORDER PROVIDERS ====================

/// Get buyer's orders
@riverpod
Future<List<OrderModel>> buyerOrders(
  BuyerOrdersRef ref,
  String buyerId, {
  int limit = 20,
  int offset = 0,
  OrderStatus? status,
}) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getBuyerOrders(
    buyerId: buyerId,
    limit: limit,
    offset: offset,
    status: status,
  );
}

/// Get seller's orders
@riverpod
Future<List<OrderModel>> sellerOrders(
  SellerOrdersRef ref,
  String sellerId, {
  int limit = 20,
  int offset = 0,
  OrderStatus? status,
}) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getSellerOrders(
    sellerId: sellerId,
    limit: limit,
    offset: offset,
    status: status,
  );
}

/// Get shop's orders
@riverpod
Future<List<OrderModel>> shopOrders(
  ShopOrdersRef ref,
  String shopId, {
  int limit = 20,
  int offset = 0,
  OrderStatus? status,
}) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getShopOrders(
    shopId: shopId,
    limit: limit,
    offset: offset,
    status: status,
  );
}

/// Get specific order
@riverpod
Future<OrderModel> order(OrderRef ref, String orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrder(orderId);
}

/// Get live stream orders
@riverpod
Future<List<OrderModel>> liveStreamOrders(
  LiveStreamOrdersRef ref,
  String liveStreamId,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getLiveStreamOrders(liveStreamId);
}

// ==================== COMMISSION PROVIDERS ====================

/// Get seller commissions
@riverpod
Future<List<CommissionModel>> sellerCommissions(
  SellerCommissionsRef ref,
  String sellerId, {
  int limit = 20,
  int offset = 0,
  CommissionType? type,
  PayoutStatus? payoutStatus,
  String? startDate,
  String? endDate,
}) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getSellerCommissions(
    sellerId: sellerId,
    limit: limit,
    offset: offset,
    type: type,
    payoutStatus: payoutStatus,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Get seller earnings summary
@riverpod
Future<SellerEarningsSummary> sellerEarnings(
  SellerEarningsRef ref,
  String sellerId, {
  String? startDate,
  String? endDate,
}) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getSellerEarnings(
    sellerId: sellerId,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Get pending commissions (awaiting payout)
@riverpod
Future<List<CommissionModel>> pendingCommissions(
  PendingCommissionsRef ref,
  String sellerId,
) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getPendingCommissions(sellerId);
}

/// Get payout history
@riverpod
Future<List<PayoutRequest>> payoutHistory(
  PayoutHistoryRef ref,
  String sellerId, {
  int limit = 20,
  int offset = 0,
  String? status,
}) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getPayoutHistory(
    sellerId: sellerId,
    limit: limit,
    offset: offset,
    status: status,
  );
}

/// Get shop commissions
@riverpod
Future<List<CommissionModel>> shopCommissions(
  ShopCommissionsRef ref,
  String shopId, {
  int limit = 20,
  int offset = 0,
  String? startDate,
  String? endDate,
}) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getShopCommissions(
    shopId: shopId,
    limit: limit,
    offset: offset,
    startDate: startDate,
    endDate: endDate,
  );
}

/// Get commission analytics
@riverpod
Future<CommissionAnalytics> commissionAnalytics(
  CommissionAnalyticsRef ref,
  String sellerId,
  String startDate,
  String endDate,
) async {
  final repository = ref.watch(commissionRepositoryProvider);
  return repository.getCommissionAnalytics(
    sellerId: sellerId,
    startDate: startDate,
    endDate: endDate,
  );
}
