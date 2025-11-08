// lib/features/shops/models/cart_model.dart
// Shopping cart for e-commerce system

class CartModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final String createdAt;
  final String updatedAt;

  const CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartModel.empty([String userId = '']) {
    final now = DateTime.now().toIso8601String();
    return CartModel(
      id: '',  // Will be set by backend
      userId: userId,
      items: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    String? createdAt,
    String? updatedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Cart operations
  CartModel addItem(CartItem item) {
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);

    if (existingIndex >= 0) {
      // Update quantity if item already exists
      final updatedItems = List<CartItem>.from(items);
      updatedItems[existingIndex] = updatedItems[existingIndex].increaseQuantity(item.quantity);
      return copyWith(
        items: updatedItems,
        updatedAt: DateTime.now().toIso8601String(),
      );
    } else {
      // Add new item
      return copyWith(
        items: [...items, item],
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  CartModel removeItem(String productId) {
    return copyWith(
      items: items.where((item) => item.productId != productId).toList(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  CartModel updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      return removeItem(productId);
    }

    final updatedItems = items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    return copyWith(
      items: updatedItems,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  CartModel clear() {
    return copyWith(
      items: [],
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Filter items by shop
  List<CartItem> itemsByShop(String shopId) {
    return items.where((item) => item.shopId == shopId).toList();
  }

  // Group items by shop
  Map<String, List<CartItem>> get itemsByShops {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.shopId)) {
        grouped[item.shopId] = [];
      }
      grouped[item.shopId]!.add(item);
    }
    return grouped;
  }

  // Calculations
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalItems => itemCount; // Alias for itemCount

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get total => subtotal; // Alias for subtotal

  double get totalSavings => items.fold(0.0, (sum, item) => sum + item.savings);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  bool hasProduct(String productId) => items.any((item) => item.productId == productId);

  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Formatted values
  String get formattedSubtotal => 'KES ${subtotal.toStringAsFixed(2)}';
  String get formattedTotalSavings => 'KES ${totalSavings.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Individual item in cart
class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final String shopId;
  final String shopName;

  final double unitPrice;
  final int quantity;
  final int maxQuantity;            // Maximum available stock

  final bool isFlashSale;
  final double? originalPrice;      // Price before flash sale
  final String? flashSaleEndsAt;    // When flash sale ends

  final bool isAvailable;           // Product still available?
  final String? unavailableReason;

  final String addedAt;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.shopId,
    required this.shopName,
    required this.unitPrice,
    required this.quantity,
    required this.maxQuantity,
    required this.isFlashSale,
    this.originalPrice,
    this.flashSaleEndsAt,
    required this.isAvailable,
    this.unavailableReason,
    required this.addedAt,
  });

  factory CartItem.fromProduct({
    required String productId,
    required String productName,
    required String productImage,
    required String shopId,
    required String shopName,
    required double price,
    int quantity = 1,
    int maxQuantity = 999,
    bool isFlashSale = false,
    double? originalPrice,
    String? flashSaleEndsAt,
  }) {
    return CartItem(
      productId: productId,
      productName: productName,
      productImage: productImage,
      shopId: shopId,
      shopName: shopName,
      unitPrice: price,
      quantity: quantity,
      maxQuantity: maxQuantity,
      isFlashSale: isFlashSale,
      originalPrice: originalPrice,
      flashSaleEndsAt: flashSaleEndsAt,
      isAvailable: true,
      unavailableReason: null,
      addedAt: DateTime.now().toIso8601String(),
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productImage: json['productImage'] ?? json['product_image'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      unitPrice: (json['unitPrice'] ?? json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      maxQuantity: json['maxQuantity'] ?? json['max_quantity'] ?? 999,
      isFlashSale: json['isFlashSale'] ?? json['is_flash_sale'] ?? false,
      originalPrice: json['originalPrice'] != null || json['original_price'] != null
          ? (json['originalPrice'] ?? json['original_price']).toDouble()
          : null,
      flashSaleEndsAt: json['flashSaleEndsAt'] ?? json['flash_sale_ends_at'],
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      unavailableReason: json['unavailableReason'] ?? json['unavailable_reason'],
      addedAt: json['addedAt'] ?? json['added_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'shopId': shopId,
      'shopName': shopName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'maxQuantity': maxQuantity,
      'isFlashSale': isFlashSale,
      'originalPrice': originalPrice,
      'flashSaleEndsAt': flashSaleEndsAt,
      'isAvailable': isAvailable,
      'unavailableReason': unavailableReason,
      'addedAt': addedAt,
    };
  }

  CartItem copyWith({
    String? productId,
    String? productName,
    String? productImage,
    String? shopId,
    String? shopName,
    double? unitPrice,
    int? quantity,
    int? maxQuantity,
    bool? isFlashSale,
    double? originalPrice,
    String? flashSaleEndsAt,
    bool? isAvailable,
    String? unavailableReason,
    String? addedAt,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      isFlashSale: isFlashSale ?? this.isFlashSale,
      originalPrice: originalPrice ?? this.originalPrice,
      flashSaleEndsAt: flashSaleEndsAt ?? this.flashSaleEndsAt,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReason: unavailableReason ?? this.unavailableReason,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  // Quantity operations
  CartItem increaseQuantity([int amount = 1]) {
    final newQuantity = (quantity + amount).clamp(1, maxQuantity);
    return copyWith(quantity: newQuantity);
  }

  CartItem decreaseQuantity([int amount = 1]) {
    final newQuantity = (quantity - amount).clamp(1, maxQuantity);
    return copyWith(quantity: newQuantity);
  }

  // Calculations
  double get total => unitPrice * quantity;

  double get savings => isFlashSale && originalPrice != null
      ? (originalPrice! - unitPrice) * quantity
      : 0.0;

  bool get hasDiscount => isFlashSale && originalPrice != null;

  double get discountPercentage => hasDiscount
      ? ((originalPrice! - unitPrice) / originalPrice!) * 100
      : 0.0;

  bool get isFlashSaleActive {
    if (!isFlashSale || flashSaleEndsAt == null) return false;
    try {
      final endsAt = DateTime.parse(flashSaleEndsAt!);
      return DateTime.now().isBefore(endsAt);
    } catch (e) {
      return false;
    }
  }

  bool get canIncreaseQuantity => quantity < maxQuantity;
  bool get canDecreaseQuantity => quantity > 1;

  // Formatted values
  String get formattedUnitPrice => 'KES ${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => 'KES ${total.toStringAsFixed(2)}';
  String get formattedSavings => 'KES ${savings.toStringAsFixed(2)}';
  String get formattedOriginalPrice => originalPrice != null
      ? 'KES ${originalPrice!.toStringAsFixed(2)}'
      : '';
  String get formattedDiscount => hasDiscount
      ? '${discountPercentage.toStringAsFixed(0)}% OFF'
      : '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
