// lib/features/shops/models/inventory_model.dart
// Inventory Management for Products

enum StockStatus {
  inStock,      // Available for purchase
  lowStock,     // Running low (below threshold)
  outOfStock,   // Sold out
  discontinued; // No longer available

  String get displayName {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.discontinued:
        return 'Discontinued';
    }
  }

  String get emoji {
    switch (this) {
      case StockStatus.inStock:
        return '✅';
      case StockStatus.lowStock:
        return '⚠️';
      case StockStatus.outOfStock:
        return '❌';
      case StockStatus.discontinued:
        return '🚫';
    }
  }

  static StockStatus fromString(String? value) {
    if (value == null) return StockStatus.inStock;
    return StockStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StockStatus.inStock,
    );
  }
}

class InventoryModel {
  final String id;
  final String productId;
  final String shopId;

  // Stock levels
  final int currentStock;
  final int reservedStock;          // Reserved for pending orders
  final int availableStock;         // currentStock - reservedStock
  final int lowStockThreshold;      // Alert when stock falls below this
  final int? maxStock;              // Maximum stock level (optional)

  // Stock status
  final StockStatus status;
  final bool trackInventory;        // Whether to track inventory for this product
  final bool allowBackorder;        // Allow orders when out of stock

  // Pricing for inventory
  final double costPrice;           // How much it costs you
  final double sellingPrice;        // How much you sell it for
  final double? salePrice;          // Special sale price

  // Location (for physical inventory)
  final String? warehouseLocation;
  final String? binLocation;

  // Timestamps
  final String createdAt;
  final String updatedAt;
  final String? lastRestockedAt;
  final String? lastSoldAt;

  const InventoryModel({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.currentStock,
    required this.reservedStock,
    required this.availableStock,
    required this.lowStockThreshold,
    this.maxStock,
    required this.status,
    required this.trackInventory,
    required this.allowBackorder,
    required this.costPrice,
    required this.sellingPrice,
    this.salePrice,
    this.warehouseLocation,
    this.binLocation,
    required this.createdAt,
    required this.updatedAt,
    this.lastRestockedAt,
    this.lastSoldAt,
  });

  factory InventoryModel.create({
    required String productId,
    required String shopId,
    required int initialStock,
    required double sellingPrice,
    double? costPrice,
    int lowStockThreshold = 10,
  }) {
    final now = DateTime.now().toIso8601String();
    return InventoryModel(
      id: '',  // Will be set by backend
      productId: productId,
      shopId: shopId,
      currentStock: initialStock,
      reservedStock: 0,
      availableStock: initialStock,
      lowStockThreshold: lowStockThreshold,
      maxStock: null,
      status: initialStock > lowStockThreshold
          ? StockStatus.inStock
          : initialStock > 0
              ? StockStatus.lowStock
              : StockStatus.outOfStock,
      trackInventory: true,
      allowBackorder: false,
      costPrice: costPrice ?? 0.0,
      sellingPrice: sellingPrice,
      salePrice: null,
      warehouseLocation: null,
      binLocation: null,
      createdAt: now,
      updatedAt: now,
      lastRestockedAt: initialStock > 0 ? now : null,
      lastSoldAt: null,
    );
  }

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? json['product_id'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      currentStock: json['currentStock'] ?? json['current_stock'] ?? 0,
      reservedStock: json['reservedStock'] ?? json['reserved_stock'] ?? 0,
      availableStock: json['availableStock'] ?? json['available_stock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? json['low_stock_threshold'] ?? 10,
      maxStock: json['maxStock'] ?? json['max_stock'],
      status: StockStatus.fromString(json['status']),
      trackInventory: json['trackInventory'] ?? json['track_inventory'] ?? true,
      allowBackorder: json['allowBackorder'] ?? json['allow_backorder'] ?? false,
      costPrice: (json['costPrice'] ?? json['cost_price'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? json['selling_price'] ?? 0).toDouble(),
      salePrice: json['salePrice'] != null || json['sale_price'] != null
          ? (json['salePrice'] ?? json['sale_price']).toDouble()
          : null,
      warehouseLocation: json['warehouseLocation'] ?? json['warehouse_location'],
      binLocation: json['binLocation'] ?? json['bin_location'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String(),
      lastRestockedAt: json['lastRestockedAt'] ?? json['last_restocked_at'],
      lastSoldAt: json['lastSoldAt'] ?? json['last_sold_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'shopId': shopId,
      'currentStock': currentStock,
      'reservedStock': reservedStock,
      'availableStock': availableStock,
      'lowStockThreshold': lowStockThreshold,
      'maxStock': maxStock,
      'status': status.name,
      'trackInventory': trackInventory,
      'allowBackorder': allowBackorder,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'salePrice': salePrice,
      'warehouseLocation': warehouseLocation,
      'binLocation': binLocation,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastRestockedAt': lastRestockedAt,
      'lastSoldAt': lastSoldAt,
    };
  }

  InventoryModel copyWith({
    String? id,
    String? productId,
    String? shopId,
    int? currentStock,
    int? reservedStock,
    int? availableStock,
    int? lowStockThreshold,
    int? maxStock,
    StockStatus? status,
    bool? trackInventory,
    bool? allowBackorder,
    double? costPrice,
    double? sellingPrice,
    double? salePrice,
    String? warehouseLocation,
    String? binLocation,
    String? createdAt,
    String? updatedAt,
    String? lastRestockedAt,
    String? lastSoldAt,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      currentStock: currentStock ?? this.currentStock,
      reservedStock: reservedStock ?? this.reservedStock,
      availableStock: availableStock ?? this.availableStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      maxStock: maxStock ?? this.maxStock,
      status: status ?? this.status,
      trackInventory: trackInventory ?? this.trackInventory,
      allowBackorder: allowBackorder ?? this.allowBackorder,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      salePrice: salePrice ?? this.salePrice,
      warehouseLocation: warehouseLocation ?? this.warehouseLocation,
      binLocation: binLocation ?? this.binLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      lastSoldAt: lastSoldAt ?? this.lastSoldAt,
    );
  }

  // Helper methods
  bool get isAvailable => availableStock > 0 || allowBackorder;
  bool get isInStock => status == StockStatus.inStock;
  bool get isLowStock => status == StockStatus.lowStock;
  bool get isOutOfStock => status == StockStatus.outOfStock;
  bool get isDiscontinued => status == StockStatus.discontinued;

  bool get needsRestock => currentStock <= lowStockThreshold;
  bool get canSell => (trackInventory && availableStock > 0) || !trackInventory || allowBackorder;

  double get profitMargin => sellingPrice > 0 ? ((sellingPrice - costPrice) / sellingPrice) * 100 : 0.0;
  double get profitPerUnit => sellingPrice - costPrice;

  double get effectivePrice => salePrice ?? sellingPrice;
  bool get isOnSale => salePrice != null && salePrice! < sellingPrice;
  double get saleDiscount => isOnSale ? ((sellingPrice - salePrice!) / sellingPrice) * 100 : 0.0;

  String get stockText {
    if (!trackInventory) return 'Available';
    if (isOutOfStock && !allowBackorder) return 'Out of Stock';
    if (isOutOfStock && allowBackorder) return 'Backorder Available';
    if (isLowStock) return '$availableStock left';
    return 'In Stock';
  }

  String get formattedSellingPrice => 'KES ${sellingPrice.toStringAsFixed(2)}';
  String get formattedCostPrice => 'KES ${costPrice.toStringAsFixed(2)}';
  String get formattedSalePrice => salePrice != null ? 'KES ${salePrice!.toStringAsFixed(2)}' : '';
  String get formattedProfitMargin => '${profitMargin.toStringAsFixed(1)}%';

  // Stock operations
  InventoryModel addStock(int quantity) {
    final newStock = currentStock + quantity;
    final newAvailable = newStock - reservedStock;
    return copyWith(
      currentStock: newStock,
      availableStock: newAvailable,
      status: _calculateStatus(newStock, reservedStock),
      lastRestockedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  InventoryModel removeStock(int quantity) {
    final newStock = (currentStock - quantity).clamp(0, currentStock);
    final newAvailable = (newStock - reservedStock).clamp(0, newStock);
    return copyWith(
      currentStock: newStock,
      availableStock: newAvailable,
      status: _calculateStatus(newStock, reservedStock),
      lastSoldAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  InventoryModel reserveStock(int quantity) {
    final newReserved = reservedStock + quantity;
    final newAvailable = (currentStock - newReserved).clamp(0, currentStock);
    return copyWith(
      reservedStock: newReserved,
      availableStock: newAvailable,
      status: _calculateStatus(currentStock, newReserved),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  InventoryModel releaseStock(int quantity) {
    final newReserved = (reservedStock - quantity).clamp(0, reservedStock);
    final newAvailable = currentStock - newReserved;
    return copyWith(
      reservedStock: newReserved,
      availableStock: newAvailable,
      status: _calculateStatus(currentStock, newReserved),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  StockStatus _calculateStatus(int stock, int reserved) {
    final available = stock - reserved;
    if (available <= 0) return StockStatus.outOfStock;
    if (available <= lowStockThreshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Stock movement/transaction record
class StockMovement {
  final String id;
  final String inventoryId;
  final String productId;
  final String shopId;

  final StockMovementType type;
  final int quantity;
  final int previousStock;
  final int newStock;

  final String? orderId;            // If related to an order
  final String? liveStreamId;       // If sold during live stream
  final String? notes;

  final String performedBy;         // User ID who made the change
  final String createdAt;

  const StockMovement({
    required this.id,
    required this.inventoryId,
    required this.productId,
    required this.shopId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.orderId,
    this.liveStreamId,
    this.notes,
    required this.performedBy,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: json['id'] ?? '',
      inventoryId: json['inventoryId'] ?? json['inventory_id'] ?? '',
      productId: json['productId'] ?? json['product_id'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      type: StockMovementType.fromString(json['type']),
      quantity: json['quantity'] ?? 0,
      previousStock: json['previousStock'] ?? json['previous_stock'] ?? 0,
      newStock: json['newStock'] ?? json['new_stock'] ?? 0,
      orderId: json['orderId'] ?? json['order_id'],
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'],
      notes: json['notes'],
      performedBy: json['performedBy'] ?? json['performed_by'] ?? '',
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'productId': productId,
      'shopId': shopId,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'orderId': orderId,
      'liveStreamId': liveStreamId,
      'notes': notes,
      'performedBy': performedBy,
      'createdAt': createdAt,
    };
  }

  String get typeText => type.displayName;
  String get quantityText => '${type.isIncrease ? '+' : '-'}$quantity';
}

enum StockMovementType {
  restock,          // Manual restock
  sale,             // Sold to customer
  return_,          // Customer return
  adjustment,       // Manual adjustment
  reservation,      // Reserved for order
  release,          // Released reservation
  damage,           // Damaged/lost
  transfer;         // Transfer between locations

  String get displayName {
    switch (this) {
      case StockMovementType.restock:
        return 'Restock';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.return_:
        return 'Return';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.reservation:
        return 'Reserved';
      case StockMovementType.release:
        return 'Released';
      case StockMovementType.damage:
        return 'Damage/Loss';
      case StockMovementType.transfer:
        return 'Transfer';
    }
  }

  bool get isIncrease => this == StockMovementType.restock ||
      this == StockMovementType.return_ ||
      this == StockMovementType.release;

  static StockMovementType fromString(String? value) {
    if (value == null) return StockMovementType.adjustment;
    // Handle 'return' specially since it's a keyword
    if (value.toLowerCase() == 'return') return StockMovementType.return_;
    return StockMovementType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => StockMovementType.adjustment,
    );
  }
}
