// lib/features/shops/models/order_model.dart
// Complete Order Model for E-commerce System

enum OrderStatus {
  pending,      // Order placed, awaiting payment
  paid,         // Payment received
  processing,   // Being prepared/packed
  shipped,      // In transit
  delivered,    // Successfully delivered
  cancelled,    // Cancelled by buyer/seller
  refunded,     // Refund issued
  disputed;     // Under dispute/review

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending Payment';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.disputed:
        return 'Disputed';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.paid:
        return '💰';
      case OrderStatus.processing:
        return '📦';
      case OrderStatus.shipped:
        return '🚚';
      case OrderStatus.delivered:
        return '✅';
      case OrderStatus.cancelled:
        return '❌';
      case OrderStatus.refunded:
        return '💸';
      case OrderStatus.disputed:
        return '⚠️';
    }
  }

  static OrderStatus fromString(String? value) {
    if (value == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMethod {
  wallet,       // Internal wallet (coins)
  mpesa,        // M-Pesa (for top-up only)
  card,         // Credit/Debit card
  other;        // Other payment methods

  String get displayName {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Wallet (Coins)';
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static PaymentMethod fromString(String? value) {
    if (value == null) return PaymentMethod.wallet;
    return PaymentMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMethod.wallet,
    );
  }
}

class OrderModel {
  // Core fields
  final String id;
  final String orderNumber;           // Human-readable order number (e.g., "ORD-20250130-001")

  // Parties involved
  final String buyerId;               // User who placed the order
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;

  final String sellerId;              // Shop owner
  final String sellerName;
  final String shopId;
  final String shopName;

  // Order items
  final List<OrderItem> items;

  // Pricing
  final double subtotal;              // Sum of all items
  final double shippingCost;          // Delivery fee
  final double tax;                   // Tax amount
  final double discount;              // Discount applied
  final double total;                 // Final amount paid

  // Payment
  final PaymentMethod paymentMethod;
  final String? transactionId;        // Wallet transaction ID
  final String? paymentReference;     // External payment reference

  // Delivery info
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryPhone;
  final String? deliveryNotes;

  // Status
  final OrderStatus status;
  final String? cancelReason;
  final String? disputeReason;

  // Commission (for platform/seller)
  final double commissionRate;        // Percentage (e.g., 10.0 = 10%)
  final double commissionAmount;      // Actual commission earned
  final double sellerPayout;          // Amount seller receives

  // Live stream context (if purchased during live)
  final String? liveStreamId;
  final bool purchasedDuringLive;

  // Timestamps
  final String createdAt;
  final String? paidAt;
  final String? shippedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  final String updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.sellerId,
    required this.sellerName,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.transactionId,
    this.paymentReference,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryPhone,
    this.deliveryNotes,
    required this.status,
    this.cancelReason,
    this.disputeReason,
    required this.commissionRate,
    required this.commissionAmount,
    required this.sellerPayout,
    this.liveStreamId,
    required this.purchasedDuringLive,
    required this.createdAt,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? '',
      buyerId: json['buyerId'] ?? json['buyer_id'] ?? '',
      buyerName: json['buyerName'] ?? json['buyer_name'] ?? '',
      buyerPhone: json['buyerPhone'] ?? json['buyer_phone'] ?? '',
      buyerEmail: json['buyerEmail'] ?? json['buyer_email'] ?? '',
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      sellerName: json['sellerName'] ?? json['seller_name'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingCost: (json['shippingCost'] ?? json['shipping_cost'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.fromString(json['paymentMethod'] ?? json['payment_method']),
      transactionId: json['transactionId'] ?? json['transaction_id'],
      paymentReference: json['paymentReference'] ?? json['payment_reference'],
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      deliveryCity: json['deliveryCity'] ?? json['delivery_city'] ?? '',
      deliveryPhone: json['deliveryPhone'] ?? json['delivery_phone'] ?? '',
      deliveryNotes: json['deliveryNotes'] ?? json['delivery_notes'],
      status: OrderStatus.fromString(json['status']),
      cancelReason: json['cancelReason'] ?? json['cancel_reason'],
      disputeReason: json['disputeReason'] ?? json['dispute_reason'],
      commissionRate: (json['commissionRate'] ?? json['commission_rate'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? json['commission_amount'] ?? 0).toDouble(),
      sellerPayout: (json['sellerPayout'] ?? json['seller_payout'] ?? 0).toDouble(),
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'],
      purchasedDuringLive: json['purchasedDuringLive'] ?? json['purchased_during_live'] ?? false,
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      paidAt: json['paidAt'] ?? json['paid_at'],
      shippedAt: json['shippedAt'] ?? json['shipped_at'],
      deliveredAt: json['deliveredAt'] ?? json['delivered_at'],
      cancelledAt: json['cancelledAt'] ?? json['cancelled_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerEmail': buyerEmail,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'transactionId': transactionId,
      'paymentReference': paymentReference,
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryPhone': deliveryPhone,
      'deliveryNotes': deliveryNotes,
      'status': status.name,
      'cancelReason': cancelReason,
      'disputeReason': disputeReason,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'sellerPayout': sellerPayout,
      'liveStreamId': liveStreamId,
      'purchasedDuringLive': purchasedDuringLive,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'shippedAt': shippedAt,
      'deliveredAt': deliveredAt,
      'cancelledAt': cancelledAt,
      'updatedAt': updatedAt,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
    String? sellerId,
    String? sellerName,
    String? shopId,
    String? shopName,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingCost,
    double? tax,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    String? transactionId,
    String? paymentReference,
    String? deliveryAddress,
    String? deliveryCity,
    String? deliveryPhone,
    String? deliveryNotes,
    OrderStatus? status,
    String? cancelReason,
    String? disputeReason,
    double? commissionRate,
    double? commissionAmount,
    double? sellerPayout,
    String? liveStreamId,
    bool? purchasedDuringLive,
    String? createdAt,
    String? paidAt,
    String? shippedAt,
    String? deliveredAt,
    String? cancelledAt,
    String? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerEmail: buyerEmail ?? this.buyerEmail,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingCost: shippingCost ?? this.shippingCost,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentReference: paymentReference ?? this.paymentReference,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryPhone: deliveryPhone ?? this.deliveryPhone,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      disputeReason: disputeReason ?? this.disputeReason,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      sellerPayout: sellerPayout ?? this.sellerPayout,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      purchasedDuringLive: purchasedDuringLive ?? this.purchasedDuringLive,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isPaid => status != OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled || status == OrderStatus.refunded;
  bool get canBeCancelled => status == OrderStatus.pending || status == OrderStatus.paid;
  bool get canBeShipped => status == OrderStatus.paid || status == OrderStatus.processing;
  bool get canBeRefunded => isPaid && !isCancelled && status != OrderStatus.delivered;

  String get formattedTotal => 'KES ${total.toStringAsFixed(2)}';
  String get formattedSubtotal => 'KES ${subtotal.toStringAsFixed(2)}';
  String get formattedShipping => 'KES ${shippingCost.toStringAsFixed(2)}';
  String get formattedCommission => 'KES ${commissionAmount.toStringAsFixed(2)}';
  String get formattedSellerPayout => 'KES ${sellerPayout.toStringAsFixed(2)}';

  String get statusText => '${status.emoji} ${status.displayName}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Individual order item
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;
  final double total;
  final bool wasFlashSale;           // Was this purchased during flash sale?
  final double? originalPrice;        // Original price before flash sale

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.total,
    required this.wasFlashSale,
    this.originalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productImage: json['productImage'] ?? json['product_image'] ?? '',
      unitPrice: (json['unitPrice'] ?? json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] ?? 0).toDouble(),
      wasFlashSale: json['wasFlashSale'] ?? json['was_flash_sale'] ?? false,
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] ?? json['original_price']).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'total': total,
      'wasFlashSale': wasFlashSale,
      'originalPrice': originalPrice,
    };
  }

  String get formattedUnitPrice => 'KES ${unitPrice.toStringAsFixed(2)}';
  String get formattedTotal => 'KES ${total.toStringAsFixed(2)}';
  String get formattedOriginalPrice => originalPrice != null
      ? 'KES ${originalPrice!.toStringAsFixed(2)}'
      : '';

  double get savings => wasFlashSale && originalPrice != null
      ? (originalPrice! - unitPrice) * quantity
      : 0.0;

  String get formattedSavings => 'KES ${savings.toStringAsFixed(2)}';
}
