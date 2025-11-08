// lib/features/shops/services/cart_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/shops/models/cart_model.dart';

/// Local cart management service using SharedPreferences
/// Cart is stored client-side and not synced to backend
class CartService {
  static const String _cartKey = 'shopping_cart';
  static const String _cartTimestampKey = 'cart_last_updated';

  final SharedPreferences _prefs;

  CartService(this._prefs);

  // ==================== CART OPERATIONS ====================

  /// Get current cart
  Future<CartModel> getCart() async {
    try {
      final cartJson = _prefs.getString(_cartKey);
      if (cartJson == null || cartJson.isEmpty) {
        return CartModel.empty();
      }

      final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
      return CartModel.fromJson(cartData);
    } catch (e) {
      print('Error loading cart: $e');
      return CartModel.empty();
    }
  }

  /// Save cart to local storage
  Future<bool> saveCart(CartModel cart) async {
    try {
      final cartJson = jsonEncode(cart.toJson());
      final success = await _prefs.setString(_cartKey, cartJson);

      if (success) {
        await _prefs.setString(
          _cartTimestampKey,
          DateTime.now().toIso8601String(),
        );
      }

      return success;
    } catch (e) {
      print('Error saving cart: $e');
      return false;
    }
  }

  /// Add item to cart
  Future<CartModel> addItem({
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
    final cart = await getCart();

    final cartItem = CartItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      productImage: thumbnailUrl,
      unitPrice: price,
      quantity: quantity,
      maxQuantity: availableStock ?? 999,
      isFlashSale: flashSale ?? false,
      originalPrice: flashSalePrice != null ? price : null,
      flashSaleEndsAt: flashSaleEndsAt,
      isAvailable: true,
      unavailableReason: null,
      addedAt: DateTime.now().toIso8601String(),
    );

    final updatedCart = cart.addItem(cartItem);
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Remove item from cart
  Future<CartModel> removeItem(String productId) async {
    final cart = await getCart();
    final updatedCart = cart.removeItem(productId);
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Update item quantity
  Future<CartModel> updateQuantity(String productId, int quantity) async {
    final cart = await getCart();
    final updatedCart = cart.updateQuantity(productId, quantity);
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Clear entire cart
  Future<bool> clearCart() async {
    try {
      await _prefs.remove(_cartKey);
      await _prefs.remove(_cartTimestampKey);
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  /// Clear cart for specific shop
  Future<CartModel> clearShopCart(String shopId) async {
    final cart = await getCart();
    final updatedItems = cart.items.where((item) => item.shopId != shopId).toList();
    final updatedCart = cart.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveCart(updatedCart);
    return updatedCart;
  }

  // ==================== CART QUERIES ====================

  /// Check if product is in cart
  Future<bool> isInCart(String productId) async {
    final cart = await getCart();
    return cart.items.any((item) => item.productId == productId);
  }

  /// Get item quantity in cart
  Future<int> getItemQuantity(String productId) async {
    final cart = await getCart();
    final item = cart.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        shopId: '',
        shopName: '',
        productName: '',
        productImage: '',
        unitPrice: 0,
        quantity: 0,
        maxQuantity: 0,
        isFlashSale: false,
        isAvailable: false,
        addedAt: '',
      ),
    );
    return item.quantity;
  }

  /// Get total items count in cart
  Future<int> getItemCount() async {
    final cart = await getCart();
    return cart.totalItems;
  }

  /// Get cart total
  Future<double> getCartTotal() async {
    final cart = await getCart();
    return cart.total;
  }

  /// Get items grouped by shop
  Future<Map<String, List<CartItem>>> getItemsByShop() async {
    final cart = await getCart();
    return cart.itemsByShops;
  }

  /// Get cart last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    final timestamp = _prefs.getString(_cartTimestampKey);
    if (timestamp == null) return null;

    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }

  // ==================== CART VALIDATION ====================

  /// Validate cart items against current stock/prices
  /// Returns list of issues found (out of stock, price changed, etc.)
  Future<List<CartValidationIssue>> validateCart(
    Future<Map<String, dynamic>> Function(String productId) fetchProductDetails,
  ) async {
    final cart = await getCart();
    final issues = <CartValidationIssue>[];

    for (var item in cart.items) {
      try {
        final productDetails = await fetchProductDetails(item.productId);

        // Check if product is still available
        final isActive = productDetails['isActive'] as bool? ?? true;
        if (!isActive) {
          issues.add(CartValidationIssue(
            productId: item.productId,
            productName: item.productName,
            issueType: CartIssueType.productUnavailable,
            message: 'Product is no longer available',
          ));
          continue;
        }

        // Check stock availability
        final currentStock = productDetails['stock'] as int? ?? 0;
        if (currentStock < item.quantity) {
          issues.add(CartValidationIssue(
            productId: item.productId,
            productName: item.productName,
            issueType: CartIssueType.insufficientStock,
            message: 'Only $currentStock items available',
            currentValue: currentStock,
            cartValue: item.quantity,
          ));
        }

        // Check price changes
        final currentPrice = (productDetails['price'] as num?)?.toDouble() ?? 0.0;
        if (currentPrice != item.unitPrice) {
          issues.add(CartValidationIssue(
            productId: item.productId,
            productName: item.productName,
            issueType: CartIssueType.priceChanged,
            message: 'Price changed from KES ${item.unitPrice} to KES $currentPrice',
            currentValue: currentPrice,
            cartValue: item.unitPrice,
          ));
        }

        // Check flash sale expiry
        if (item.isFlashSale && item.flashSaleEndsAt != null) {
          final expiryDate = DateTime.parse(item.flashSaleEndsAt!);
          if (DateTime.now().isAfter(expiryDate)) {
            issues.add(CartValidationIssue(
              productId: item.productId,
              productName: item.productName,
              issueType: CartIssueType.flashSaleExpired,
              message: 'Flash sale has ended',
            ));
          }
        }
      } catch (e) {
        issues.add(CartValidationIssue(
          productId: item.productId,
          productName: item.productName,
          issueType: CartIssueType.validationError,
          message: 'Could not validate product: $e',
        ));
      }
    }

    return issues;
  }

  /// Remove invalid items from cart based on validation issues
  Future<CartModel> removeInvalidItems(List<CartValidationIssue> issues) async {
    final cart = await getCart();
    final invalidProductIds = issues
        .where((issue) =>
            issue.issueType == CartIssueType.productUnavailable ||
            issue.issueType == CartIssueType.validationError)
        .map((issue) => issue.productId)
        .toSet();

    final validItems = cart.items
        .where((item) => !invalidProductIds.contains(item.productId))
        .toList();

    final updatedCart = cart.copyWith(
      items: validItems,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Auto-fix cart issues (adjust quantities, update prices)
  Future<CartModel> autoFixCart(List<CartValidationIssue> issues) async {
    final cart = await getCart();
    final updatedItems = <CartItem>[];

    for (var item in cart.items) {
      var updatedItem = item;

      // Find issues for this item
      final itemIssues = issues.where((i) => i.productId == item.productId);

      for (var issue in itemIssues) {
        switch (issue.issueType) {
          case CartIssueType.insufficientStock:
            // Adjust quantity to available stock
            if (issue.currentValue != null) {
              updatedItem = updatedItem.copyWith(
                quantity: (issue.currentValue as num).toInt(),
              );
            }
            break;

          case CartIssueType.priceChanged:
            // Update to current price
            if (issue.currentValue != null) {
              updatedItem = updatedItem.copyWith(
                unitPrice: (issue.currentValue as num).toDouble(),
              );
            }
            break;

          case CartIssueType.flashSaleExpired:
            // Remove flash sale pricing
            updatedItem = updatedItem.copyWith(
              isFlashSale: false,
              originalPrice: null,
              flashSaleEndsAt: null,
            );
            break;

          case CartIssueType.productUnavailable:
          case CartIssueType.validationError:
            // Skip invalid items
            continue;
        }
      }

      // Only add if not marked as unavailable
      if (!itemIssues.any((i) =>
          i.issueType == CartIssueType.productUnavailable ||
          i.issueType == CartIssueType.validationError)) {
        updatedItems.add(updatedItem);
      }
    }

    final updatedCart = cart.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveCart(updatedCart);
    return updatedCart;
  }

  // ==================== CART MIGRATION ====================

  /// Migrate cart after successful order
  /// Removes ordered items from cart
  Future<CartModel> removeOrderedItems(List<String> productIds) async {
    final cart = await getCart();
    final remainingItems = cart.items
        .where((item) => !productIds.contains(item.productId))
        .toList();

    final updatedCart = cart.copyWith(
      items: remainingItems,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Get cart age (time since last update)
  Future<Duration?> getCartAge() async {
    final lastUpdated = await getLastUpdated();
    if (lastUpdated == null) return null;

    return DateTime.now().difference(lastUpdated);
  }

  /// Clear old cart if not updated for specified duration
  Future<bool> clearIfOlderThan(Duration duration) async {
    final age = await getCartAge();
    if (age != null && age > duration) {
      return await clearCart();
    }
    return false;
  }
}

// ==================== CART VALIDATION MODELS ====================

enum CartIssueType {
  productUnavailable,
  insufficientStock,
  priceChanged,
  flashSaleExpired,
  validationError,
}

class CartValidationIssue {
  final String productId;
  final String productName;
  final CartIssueType issueType;
  final String message;
  final dynamic currentValue;
  final dynamic cartValue;

  const CartValidationIssue({
    required this.productId,
    required this.productName,
    required this.issueType,
    required this.message,
    this.currentValue,
    this.cartValue,
  });

  bool get isCritical =>
      issueType == CartIssueType.productUnavailable ||
      issueType == CartIssueType.validationError;

  bool get isWarning =>
      issueType == CartIssueType.priceChanged ||
      issueType == CartIssueType.insufficientStock ||
      issueType == CartIssueType.flashSaleExpired;
}
