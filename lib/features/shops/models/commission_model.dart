// lib/features/shops/models/commission_model.dart
// Commission and earnings tracking for shop sales

enum CommissionType {
  shopSale,         // Regular shop purchase
  liveStreamSale,   // Purchase during live stream
  flashSale,        // Flash sale purchase
  affiliate,        // Affiliate/referral sale
  platformFee;      // Platform service fee

  String get displayName {
    switch (this) {
      case CommissionType.shopSale:
        return 'Shop Sale';
      case CommissionType.liveStreamSale:
        return 'Live Stream Sale';
      case CommissionType.flashSale:
        return 'Flash Sale';
      case CommissionType.affiliate:
        return 'Affiliate Sale';
      case CommissionType.platformFee:
        return 'Platform Fee';
    }
  }

  static CommissionType fromString(String? value) {
    if (value == null) return CommissionType.shopSale;
    return CommissionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CommissionType.shopSale,
    );
  }
}

enum PayoutStatus {
  pending,      // Commission earned, payout pending
  processing,   // Payout being processed
  completed,    // Payout completed
  failed,       // Payout failed
  onHold;       // On hold (dispute, verification, etc.)

  String get displayName {
    switch (this) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
      case PayoutStatus.onHold:
        return 'On Hold';
    }
  }

  String get emoji {
    switch (this) {
      case PayoutStatus.pending:
        return '⏳';
      case PayoutStatus.processing:
        return '⚙️';
      case PayoutStatus.completed:
        return '✅';
      case PayoutStatus.failed:
        return '❌';
      case PayoutStatus.onHold:
        return '⚠️';
    }
  }

  static PayoutStatus fromString(String? value) {
    if (value == null) return PayoutStatus.pending;
    return PayoutStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PayoutStatus.pending,
    );
  }
}

/// Commission record for individual transactions
class CommissionModel {
  final String id;
  final String orderId;               // Related order
  final String productId;
  final String shopId;
  final String sellerId;              // Shop owner

  // Sale details
  final CommissionType type;
  final double orderTotal;            // Total order amount
  final double commissionRate;        // Percentage (e.g., 10.0 = 10%)
  final double commissionAmount;      // Actual commission
  final double sellerEarnings;        // What seller gets

  // Platform earnings
  final double platformFee;           // What platform takes
  final double platformRate;          // Platform fee percentage

  // Live stream context (if applicable)
  final String? liveStreamId;
  final bool earnedDuringLive;

  // Payout info
  final PayoutStatus payoutStatus;
  final String? payoutId;             // Wallet transaction ID for payout
  final String? payoutDate;

  // Metadata
  final String? notes;
  final Map<String, dynamic>? metadata;

  // Timestamps
  final String createdAt;
  final String updatedAt;

  const CommissionModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.shopId,
    required this.sellerId,
    required this.type,
    required this.orderTotal,
    required this.commissionRate,
    required this.commissionAmount,
    required this.sellerEarnings,
    required this.platformFee,
    required this.platformRate,
    this.liveStreamId,
    required this.earnedDuringLive,
    required this.payoutStatus,
    this.payoutId,
    this.payoutDate,
    this.notes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionModel.calculate({
    required String orderId,
    required String productId,
    required String shopId,
    required String sellerId,
    required double orderTotal,
    required double commissionRate,
    required double platformRate,
    CommissionType type = CommissionType.shopSale,
    String? liveStreamId,
  }) {
    final now = DateTime.now().toIso8601String();

    // Calculate commission (what seller gives up)
    final commission = orderTotal * (commissionRate / 100);

    // Calculate platform fee (what platform takes)
    final platFee = orderTotal * (platformRate / 100);

    // Seller gets: orderTotal - commission - platform fee
    final sellerEarn = orderTotal - commission - platFee;

    return CommissionModel(
      id: '',  // Will be set by backend
      orderId: orderId,
      productId: productId,
      shopId: shopId,
      sellerId: sellerId,
      type: type,
      orderTotal: orderTotal,
      commissionRate: commissionRate,
      commissionAmount: commission,
      sellerEarnings: sellerEarn,
      platformFee: platFee,
      platformRate: platformRate,
      liveStreamId: liveStreamId,
      earnedDuringLive: liveStreamId != null,
      payoutStatus: PayoutStatus.pending,
      payoutId: null,
      payoutDate: null,
      notes: null,
      metadata: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      productId: json['productId'] ?? json['product_id'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      type: CommissionType.fromString(json['type']),
      orderTotal: (json['orderTotal'] ?? json['order_total'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? json['commission_rate'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? json['commission_amount'] ?? 0).toDouble(),
      sellerEarnings: (json['sellerEarnings'] ?? json['seller_earnings'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? json['platform_fee'] ?? 0).toDouble(),
      platformRate: (json['platformRate'] ?? json['platform_rate'] ?? 0).toDouble(),
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'],
      earnedDuringLive: json['earnedDuringLive'] ?? json['earned_during_live'] ?? false,
      payoutStatus: PayoutStatus.fromString(json['payoutStatus'] ?? json['payout_status']),
      payoutId: json['payoutId'] ?? json['payout_id'],
      payoutDate: json['payoutDate'] ?? json['payout_date'],
      notes: json['notes'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'shopId': shopId,
      'sellerId': sellerId,
      'type': type.name,
      'orderTotal': orderTotal,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'sellerEarnings': sellerEarnings,
      'platformFee': platformFee,
      'platformRate': platformRate,
      'liveStreamId': liveStreamId,
      'earnedDuringLive': earnedDuringLive,
      'payoutStatus': payoutStatus.name,
      'payoutId': payoutId,
      'payoutDate': payoutDate,
      'notes': notes,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  CommissionModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? shopId,
    String? sellerId,
    CommissionType? type,
    double? orderTotal,
    double? commissionRate,
    double? commissionAmount,
    double? sellerEarnings,
    double? platformFee,
    double? platformRate,
    String? liveStreamId,
    bool? earnedDuringLive,
    PayoutStatus? payoutStatus,
    String? payoutId,
    String? payoutDate,
    String? notes,
    Map<String, dynamic>? metadata,
    String? createdAt,
    String? updatedAt,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      orderTotal: orderTotal ?? this.orderTotal,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      sellerEarnings: sellerEarnings ?? this.sellerEarnings,
      platformFee: platformFee ?? this.platformFee,
      platformRate: platformRate ?? this.platformRate,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      earnedDuringLive: earnedDuringLive ?? this.earnedDuringLive,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      payoutId: payoutId ?? this.payoutId,
      payoutDate: payoutDate ?? this.payoutDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isPending => payoutStatus == PayoutStatus.pending;
  bool get isCompleted => payoutStatus == PayoutStatus.completed;
  bool get isFailed => payoutStatus == PayoutStatus.failed;
  bool get canPayout => isPending || isFailed;

  String get formattedOrderTotal => 'KES ${orderTotal.toStringAsFixed(2)}';
  String get formattedCommission => 'KES ${commissionAmount.toStringAsFixed(2)}';
  String get formattedSellerEarnings => 'KES ${sellerEarnings.toStringAsFixed(2)}';
  String get formattedPlatformFee => 'KES ${platformFee.toStringAsFixed(2)}';

  String get commissionRateText => '${commissionRate.toStringAsFixed(1)}%';
  String get platformRateText => '${platformRate.toStringAsFixed(1)}%';

  String get statusText => '${payoutStatus.emoji} ${payoutStatus.displayName}';

  double get totalDeductions => commissionAmount + platformFee;
  String get formattedTotalDeductions => 'KES ${totalDeductions.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommissionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Earnings summary for a seller
class EarningsSummary {
  final String sellerId;
  final String shopId;

  // Total earnings
  final double totalSales;            // All sales
  final double totalCommissions;      // Total commissions paid
  final double totalPlatformFees;     // Total platform fees
  final double totalEarnings;         // Net earnings
  final double availableBalance;      // Ready to withdraw
  final double pendingBalance;        // Pending payout

  // Breakdown by type
  final double shopSalesEarnings;
  final double liveStreamEarnings;
  final double flashSaleEarnings;

  // Statistics
  final int totalOrders;
  final int totalProducts;
  final double averageOrderValue;
  final double averageCommissionRate;

  // Period info
  final String periodStart;
  final String periodEnd;
  final String generatedAt;

  const EarningsSummary({
    required this.sellerId,
    required this.shopId,
    required this.totalSales,
    required this.totalCommissions,
    required this.totalPlatformFees,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.shopSalesEarnings,
    required this.liveStreamEarnings,
    required this.flashSaleEarnings,
    required this.totalOrders,
    required this.totalProducts,
    required this.averageOrderValue,
    required this.averageCommissionRate,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      totalSales: (json['totalSales'] ?? json['total_sales'] ?? 0).toDouble(),
      totalCommissions: (json['totalCommissions'] ?? json['total_commissions'] ?? 0).toDouble(),
      totalPlatformFees: (json['totalPlatformFees'] ?? json['total_platform_fees'] ?? 0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? json['available_balance'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? json['pending_balance'] ?? 0).toDouble(),
      shopSalesEarnings: (json['shopSalesEarnings'] ?? json['shop_sales_earnings'] ?? 0).toDouble(),
      liveStreamEarnings: (json['liveStreamEarnings'] ?? json['live_stream_earnings'] ?? 0).toDouble(),
      flashSaleEarnings: (json['flashSaleEarnings'] ?? json['flash_sale_earnings'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
      totalProducts: json['totalProducts'] ?? json['total_products'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? json['average_order_value'] ?? 0).toDouble(),
      averageCommissionRate: (json['averageCommissionRate'] ?? json['average_commission_rate'] ?? 0).toDouble(),
      periodStart: json['periodStart'] ?? json['period_start'] ?? '',
      periodEnd: json['periodEnd'] ?? json['period_end'] ?? '',
      generatedAt: json['generatedAt'] ?? json['generated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'shopId': shopId,
      'totalSales': totalSales,
      'totalCommissions': totalCommissions,
      'totalPlatformFees': totalPlatformFees,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'shopSalesEarnings': shopSalesEarnings,
      'liveStreamEarnings': liveStreamEarnings,
      'flashSaleEarnings': flashSaleEarnings,
      'totalOrders': totalOrders,
      'totalProducts': totalProducts,
      'averageOrderValue': averageOrderValue,
      'averageCommissionRate': averageCommissionRate,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'generatedAt': generatedAt,
    };
  }

  // Formatted values
  String get formattedTotalSales => 'KES ${totalSales.toStringAsFixed(2)}';
  String get formattedTotalCommissions => 'KES ${totalCommissions.toStringAsFixed(2)}';
  String get formattedTotalPlatformFees => 'KES ${totalPlatformFees.toStringAsFixed(2)}';
  String get formattedTotalEarnings => 'KES ${totalEarnings.toStringAsFixed(2)}';
  String get formattedAvailableBalance => 'KES ${availableBalance.toStringAsFixed(2)}';
  String get formattedPendingBalance => 'KES ${pendingBalance.toStringAsFixed(2)}';
  String get formattedAverageOrderValue => 'KES ${averageOrderValue.toStringAsFixed(2)}';
  String get formattedAverageCommissionRate => '${averageCommissionRate.toStringAsFixed(1)}%';

  // Percentages
  double get liveStreamPercentage => totalEarnings > 0
      ? (liveStreamEarnings / totalEarnings) * 100
      : 0.0;

  double get shopSalesPercentage => totalEarnings > 0
      ? (shopSalesEarnings / totalEarnings) * 100
      : 0.0;

  double get flashSalePercentage => totalEarnings > 0
      ? (flashSaleEarnings / totalEarnings) * 100
      : 0.0;

  double get commissionsPercentage => totalSales > 0
      ? (totalCommissions / totalSales) * 100
      : 0.0;

  double get platformFeesPercentage => totalSales > 0
      ? (totalPlatformFees / totalSales) * 100
      : 0.0;

  String get formattedLiveStreamPercentage => '${liveStreamPercentage.toStringAsFixed(1)}%';
  String get formattedShopSalesPercentage => '${shopSalesPercentage.toStringAsFixed(1)}%';
  String get formattedFlashSalePercentage => '${flashSalePercentage.toStringAsFixed(1)}%';
}

/// Seller earnings summary
class SellerEarningsSummary {
  final String sellerId;
  final double totalEarnings;
  final double availableBalance;
  final double pendingBalance;
  final double paidOut;
  final int totalCommissions;
  final String periodStart;
  final String periodEnd;

  const SellerEarningsSummary({
    required this.sellerId,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.paidOut,
    required this.totalCommissions,
    required this.periodStart,
    required this.periodEnd,
  });

  factory SellerEarningsSummary.fromJson(Map<String, dynamic> json) {
    return SellerEarningsSummary(
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? json['available_balance'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? json['pending_balance'] ?? 0).toDouble(),
      paidOut: (json['paidOut'] ?? json['paid_out'] ?? 0).toDouble(),
      totalCommissions: json['totalCommissions'] ?? json['total_commissions'] ?? 0,
      periodStart: json['periodStart'] ?? json['period_start'] ?? '',
      periodEnd: json['periodEnd'] ?? json['period_end'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'totalEarnings': totalEarnings,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'paidOut': paidOut,
      'totalCommissions': totalCommissions,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
    };
  }

  String get formattedTotalEarnings => 'KES ${totalEarnings.toStringAsFixed(2)}';
  String get formattedAvailableBalance => 'KES ${availableBalance.toStringAsFixed(2)}';
  String get formattedPendingBalance => 'KES ${pendingBalance.toStringAsFixed(2)}';
  String get formattedPaidOut => 'KES ${paidOut.toStringAsFixed(2)}';
}

/// Payout request model
class PayoutRequest {
  final String id;
  final String sellerId;
  final double amount;
  final String payoutMethod;
  final String? payoutDetails;
  final String status; // pending, processing, completed, failed, cancelled
  final String? failureReason;
  final String requestedAt;
  final String? processedAt;
  final String? completedAt;

  const PayoutRequest({
    required this.id,
    required this.sellerId,
    required this.amount,
    required this.payoutMethod,
    this.payoutDetails,
    required this.status,
    this.failureReason,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      payoutMethod: json['payoutMethod'] ?? json['payout_method'] ?? '',
      payoutDetails: json['payoutDetails'] ?? json['payout_details'],
      status: json['status'] ?? 'pending',
      failureReason: json['failureReason'] ?? json['failure_reason'],
      requestedAt: json['requestedAt'] ?? json['requested_at'] ?? DateTime.now().toIso8601String(),
      processedAt: json['processedAt'] ?? json['processed_at'],
      completedAt: json['completedAt'] ?? json['completed_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'amount': amount,
      'payoutMethod': payoutMethod,
      'payoutDetails': payoutDetails,
      'status': status,
      'failureReason': failureReason,
      'requestedAt': requestedAt,
      'processedAt': processedAt,
      'completedAt': completedAt,
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
}

/// Commission analytics model
class CommissionAnalytics {
  final String sellerId;
  final double totalEarnings;
  final double averageCommission;
  final int totalOrders;
  final Map<String, double> earningsByType;
  final Map<String, int> ordersByType;
  final List<DailyEarnings> dailyEarnings;
  final String periodStart;
  final String periodEnd;

  const CommissionAnalytics({
    required this.sellerId,
    required this.totalEarnings,
    required this.averageCommission,
    required this.totalOrders,
    required this.earningsByType,
    required this.ordersByType,
    required this.dailyEarnings,
    required this.periodStart,
    required this.periodEnd,
  });

  factory CommissionAnalytics.fromJson(Map<String, dynamic> json) {
    return CommissionAnalytics(
      sellerId: json['sellerId'] ?? json['seller_id'] ?? '',
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? 0).toDouble(),
      averageCommission: (json['averageCommission'] ?? json['average_commission'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
      earningsByType: Map<String, double>.from(json['earningsByType'] ?? json['earnings_by_type'] ?? {}),
      ordersByType: Map<String, int>.from(json['ordersByType'] ?? json['orders_by_type'] ?? {}),
      dailyEarnings: (json['dailyEarnings'] ?? json['daily_earnings'] ?? [])
          .map<DailyEarnings>((e) => DailyEarnings.fromJson(e))
          .toList(),
      periodStart: json['periodStart'] ?? json['period_start'] ?? '',
      periodEnd: json['periodEnd'] ?? json['period_end'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'totalEarnings': totalEarnings,
      'averageCommission': averageCommission,
      'totalOrders': totalOrders,
      'earningsByType': earningsByType,
      'ordersByType': ordersByType,
      'dailyEarnings': dailyEarnings.map((e) => e.toJson()).toList(),
      'periodStart': periodStart,
      'periodEnd': periodEnd,
    };
  }

  String get formattedTotalEarnings => 'KES ${totalEarnings.toStringAsFixed(2)}';
  String get formattedAverageCommission => 'KES ${averageCommission.toStringAsFixed(2)}';
}

/// Daily earnings data point
class DailyEarnings {
  final String date;
  final double earnings;
  final int orders;

  const DailyEarnings({
    required this.date,
    required this.earnings,
    required this.orders,
  });

  factory DailyEarnings.fromJson(Map<String, dynamic> json) {
    return DailyEarnings(
      date: json['date'] ?? '',
      earnings: (json['earnings'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'earnings': earnings,
      'orders': orders,
    };
  }

  String get formattedEarnings => 'KES ${earnings.toStringAsFixed(2)}';
}

/// Product commission statistics
class ProductCommissionStats {
  final String productId;
  final String productName;
  final String productImage;
  final double totalEarnings;
  final double averageCommission;
  final int totalSales;
  final int totalQuantitySold;

  const ProductCommissionStats({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.totalEarnings,
    required this.averageCommission,
    required this.totalSales,
    required this.totalQuantitySold,
  });

  factory ProductCommissionStats.fromJson(Map<String, dynamic> json) {
    return ProductCommissionStats(
      productId: json['productId'] ?? json['product_id'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? '',
      productImage: json['productImage'] ?? json['product_image'] ?? '',
      totalEarnings: (json['totalEarnings'] ?? json['total_earnings'] ?? 0).toDouble(),
      averageCommission: (json['averageCommission'] ?? json['average_commission'] ?? 0).toDouble(),
      totalSales: json['totalSales'] ?? json['total_sales'] ?? 0,
      totalQuantitySold: json['totalQuantitySold'] ?? json['total_quantity_sold'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'totalEarnings': totalEarnings,
      'averageCommission': averageCommission,
      'totalSales': totalSales,
      'totalQuantitySold': totalQuantitySold,
    };
  }

  String get formattedTotalEarnings => 'KES ${totalEarnings.toStringAsFixed(2)}';
  String get formattedAverageCommission => 'KES ${averageCommission.toStringAsFixed(2)}';
}
