// lib/features/live_streaming/models/live_stream_type_model.dart
// Live stream type definitions and configurations

/// Type of live stream
enum LiveStreamType {
  gift,     // Entertainment stream powered by virtual gifts
  shop;     // Shopping stream powered by product sales/commissions

  String get displayName {
    switch (this) {
      case LiveStreamType.gift:
        return 'Gift Live';
      case LiveStreamType.shop:
        return 'Shop Live';
    }
  }

  String get description {
    switch (this) {
      case LiveStreamType.gift:
        return 'Earn from virtual gifts sent by viewers';
      case LiveStreamType.shop:
        return 'Sell products and earn commissions';
    }
  }

  String get emoji {
    switch (this) {
      case LiveStreamType.gift:
        return '🎁';
      case LiveStreamType.shop:
        return '🛍️';
    }
  }

  static LiveStreamType fromString(String? value) {
    if (value == null) return LiveStreamType.gift;
    return LiveStreamType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LiveStreamType.gift,
    );
  }
}

/// Configuration for Gift Live streams
class GiftLiveConfig {
  final bool enabled;
  final double giftConversionRate;   // Coins to KES (e.g., 1 coin = 1 KES)
  final int minGiftValue;            // Minimum gift value in coins
  final int maxGiftValue;            // Maximum gift value in coins
  final bool allowCustomGiftAmounts; // Allow viewers to send custom amounts
  final List<String> featuredGiftIds; // Featured gifts to highlight

  // Engagement settings
  final bool showTopGifters;         // Show leaderboard of top gifters
  final bool enableGiftGoals;        // Enable gift goals/milestones
  final int? giftGoalAmount;         // Target amount for this stream

  // Revenue tracking
  final double totalGiftsReceived;   // Total coins received
  final double totalGiftRevenue;     // Total KES earned
  final int uniqueGifters;           // Number of unique users who gifted

  const GiftLiveConfig({
    this.enabled = true,
    this.giftConversionRate = 1.0,
    this.minGiftValue = 1,
    this.maxGiftValue = 10000,
    this.allowCustomGiftAmounts = true,
    this.featuredGiftIds = const [],
    this.showTopGifters = true,
    this.enableGiftGoals = false,
    this.giftGoalAmount,
    this.totalGiftsReceived = 0.0,
    this.totalGiftRevenue = 0.0,
    this.uniqueGifters = 0,
  });

  factory GiftLiveConfig.fromJson(Map<String, dynamic> json) {
    return GiftLiveConfig(
      enabled: json['enabled'] ?? true,
      giftConversionRate: (json['giftConversionRate'] ?? json['gift_conversion_rate'] ?? 1.0).toDouble(),
      minGiftValue: json['minGiftValue'] ?? json['min_gift_value'] ?? 1,
      maxGiftValue: json['maxGiftValue'] ?? json['max_gift_value'] ?? 10000,
      allowCustomGiftAmounts: json['allowCustomGiftAmounts'] ?? json['allow_custom_gift_amounts'] ?? true,
      featuredGiftIds: List<String>.from(json['featuredGiftIds'] ?? json['featured_gift_ids'] ?? []),
      showTopGifters: json['showTopGifters'] ?? json['show_top_gifters'] ?? true,
      enableGiftGoals: json['enableGiftGoals'] ?? json['enable_gift_goals'] ?? false,
      giftGoalAmount: json['giftGoalAmount'] ?? json['gift_goal_amount'],
      totalGiftsReceived: (json['totalGiftsReceived'] ?? json['total_gifts_received'] ?? 0).toDouble(),
      totalGiftRevenue: (json['totalGiftRevenue'] ?? json['total_gift_revenue'] ?? 0).toDouble(),
      uniqueGifters: json['uniqueGifters'] ?? json['unique_gifters'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'giftConversionRate': giftConversionRate,
      'minGiftValue': minGiftValue,
      'maxGiftValue': maxGiftValue,
      'allowCustomGiftAmounts': allowCustomGiftAmounts,
      'featuredGiftIds': featuredGiftIds,
      'showTopGifters': showTopGifters,
      'enableGiftGoals': enableGiftGoals,
      'giftGoalAmount': giftGoalAmount,
      'totalGiftsReceived': totalGiftsReceived,
      'totalGiftRevenue': totalGiftRevenue,
      'uniqueGifters': uniqueGifters,
    };
  }

  GiftLiveConfig copyWith({
    bool? enabled,
    double? giftConversionRate,
    int? minGiftValue,
    int? maxGiftValue,
    bool? allowCustomGiftAmounts,
    List<String>? featuredGiftIds,
    bool? showTopGifters,
    bool? enableGiftGoals,
    int? giftGoalAmount,
    double? totalGiftsReceived,
    double? totalGiftRevenue,
    int? uniqueGifters,
  }) {
    return GiftLiveConfig(
      enabled: enabled ?? this.enabled,
      giftConversionRate: giftConversionRate ?? this.giftConversionRate,
      minGiftValue: minGiftValue ?? this.minGiftValue,
      maxGiftValue: maxGiftValue ?? this.maxGiftValue,
      allowCustomGiftAmounts: allowCustomGiftAmounts ?? this.allowCustomGiftAmounts,
      featuredGiftIds: featuredGiftIds ?? this.featuredGiftIds,
      showTopGifters: showTopGifters ?? this.showTopGifters,
      enableGiftGoals: enableGiftGoals ?? this.enableGiftGoals,
      giftGoalAmount: giftGoalAmount ?? this.giftGoalAmount,
      totalGiftsReceived: totalGiftsReceived ?? this.totalGiftsReceived,
      totalGiftRevenue: totalGiftRevenue ?? this.totalGiftRevenue,
      uniqueGifters: uniqueGifters ?? this.uniqueGifters,
    );
  }

  // Helper getters
  bool get hasGiftGoal => enableGiftGoals && giftGoalAmount != null && giftGoalAmount! > 0;
  double get goalProgress => hasGiftGoal ? (totalGiftsReceived / giftGoalAmount!) * 100 : 0.0;
  bool get goalReached => hasGiftGoal && totalGiftsReceived >= giftGoalAmount!;

  String get formattedTotalRevenue => 'KES ${totalGiftRevenue.toStringAsFixed(2)}';
  String get formattedGoalProgress => '${goalProgress.toStringAsFixed(1)}%';
}

/// Configuration for Shop Live streams
class ShopLiveConfig {
  final bool enabled;
  final String shopId;               // Linked shop
  final String shopName;

  // Product showcase
  final List<String> featuredProductIds; // Products to highlight
  final String? pinnedProductId;         // Currently pinned/active product
  final bool allowProductBrowsing;       // Allow viewers to browse full catalog

  // Sales settings
  final double commissionRate;       // Commission percentage
  final bool enableFlashDeals;       // Enable flash deals during live
  final bool showInventoryCount;     // Show remaining stock

  // Revenue tracking
  final double totalSales;           // Total sales amount
  final double totalCommissions;     // Total commissions earned
  final int totalOrders;             // Number of orders
  final int uniqueBuyers;            // Number of unique buyers
  final Map<String, int> productsSold; // productId -> quantity sold

  // Engagement
  final bool showTopBuyers;          // Show leaderboard of top buyers
  final bool enableSalesGoals;       // Enable sales goals/milestones
  final double? salesGoalAmount;     // Target sales for this stream

  const ShopLiveConfig({
    this.enabled = true,
    required this.shopId,
    required this.shopName,
    this.featuredProductIds = const [],
    this.pinnedProductId,
    this.allowProductBrowsing = true,
    this.commissionRate = 10.0,
    this.enableFlashDeals = true,
    this.showInventoryCount = true,
    this.totalSales = 0.0,
    this.totalCommissions = 0.0,
    this.totalOrders = 0,
    this.uniqueBuyers = 0,
    this.productsSold = const {},
    this.showTopBuyers = true,
    this.enableSalesGoals = false,
    this.salesGoalAmount,
  });

  factory ShopLiveConfig.fromJson(Map<String, dynamic> json) {
    return ShopLiveConfig(
      enabled: json['enabled'] ?? true,
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      featuredProductIds: List<String>.from(json['featuredProductIds'] ?? json['featured_product_ids'] ?? []),
      pinnedProductId: json['pinnedProductId'] ?? json['pinned_product_id'],
      allowProductBrowsing: json['allowProductBrowsing'] ?? json['allow_product_browsing'] ?? true,
      commissionRate: (json['commissionRate'] ?? json['commission_rate'] ?? 10.0).toDouble(),
      enableFlashDeals: json['enableFlashDeals'] ?? json['enable_flash_deals'] ?? true,
      showInventoryCount: json['showInventoryCount'] ?? json['show_inventory_count'] ?? true,
      totalSales: (json['totalSales'] ?? json['total_sales'] ?? 0).toDouble(),
      totalCommissions: (json['totalCommissions'] ?? json['total_commissions'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
      uniqueBuyers: json['uniqueBuyers'] ?? json['unique_buyers'] ?? 0,
      productsSold: Map<String, int>.from(json['productsSold'] ?? json['products_sold'] ?? {}),
      showTopBuyers: json['showTopBuyers'] ?? json['show_top_buyers'] ?? true,
      enableSalesGoals: json['enableSalesGoals'] ?? json['enable_sales_goals'] ?? false,
      salesGoalAmount: json['salesGoalAmount'] != null || json['sales_goal_amount'] != null
          ? (json['salesGoalAmount'] ?? json['sales_goal_amount']).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'shopId': shopId,
      'shopName': shopName,
      'featuredProductIds': featuredProductIds,
      'pinnedProductId': pinnedProductId,
      'allowProductBrowsing': allowProductBrowsing,
      'commissionRate': commissionRate,
      'enableFlashDeals': enableFlashDeals,
      'showInventoryCount': showInventoryCount,
      'totalSales': totalSales,
      'totalCommissions': totalCommissions,
      'totalOrders': totalOrders,
      'uniqueBuyers': uniqueBuyers,
      'productsSold': productsSold,
      'showTopBuyers': showTopBuyers,
      'enableSalesGoals': enableSalesGoals,
      'salesGoalAmount': salesGoalAmount,
    };
  }

  ShopLiveConfig copyWith({
    bool? enabled,
    String? shopId,
    String? shopName,
    List<String>? featuredProductIds,
    String? pinnedProductId,
    bool? allowProductBrowsing,
    double? commissionRate,
    bool? enableFlashDeals,
    bool? showInventoryCount,
    double? totalSales,
    double? totalCommissions,
    int? totalOrders,
    int? uniqueBuyers,
    Map<String, int>? productsSold,
    bool? showTopBuyers,
    bool? enableSalesGoals,
    double? salesGoalAmount,
  }) {
    return ShopLiveConfig(
      enabled: enabled ?? this.enabled,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      featuredProductIds: featuredProductIds ?? this.featuredProductIds,
      pinnedProductId: pinnedProductId ?? this.pinnedProductId,
      allowProductBrowsing: allowProductBrowsing ?? this.allowProductBrowsing,
      commissionRate: commissionRate ?? this.commissionRate,
      enableFlashDeals: enableFlashDeals ?? this.enableFlashDeals,
      showInventoryCount: showInventoryCount ?? this.showInventoryCount,
      totalSales: totalSales ?? this.totalSales,
      totalCommissions: totalCommissions ?? this.totalCommissions,
      totalOrders: totalOrders ?? this.totalOrders,
      uniqueBuyers: uniqueBuyers ?? this.uniqueBuyers,
      productsSold: productsSold ?? this.productsSold,
      showTopBuyers: showTopBuyers ?? this.showTopBuyers,
      enableSalesGoals: enableSalesGoals ?? this.enableSalesGoals,
      salesGoalAmount: salesGoalAmount ?? this.salesGoalAmount,
    );
  }

  // Helper getters
  bool get hasFeaturedProducts => featuredProductIds.isNotEmpty;
  bool get hasPinnedProduct => pinnedProductId != null;
  bool get hasSalesGoal => enableSalesGoals && salesGoalAmount != null && salesGoalAmount! > 0;

  double get goalProgress => hasSalesGoal ? (totalSales / salesGoalAmount!) * 100 : 0.0;
  bool get goalReached => hasSalesGoal && totalSales >= salesGoalAmount!;

  double get averageOrderValue => totalOrders > 0 ? totalSales / totalOrders : 0.0;

  int get totalProductsSoldCount => productsSold.values.fold(0, (sum, qty) => sum + qty);

  String get formattedTotalSales => 'KES ${totalSales.toStringAsFixed(2)}';
  String get formattedTotalCommissions => 'KES ${totalCommissions.toStringAsFixed(2)}';
  String get formattedAverageOrder => 'KES ${averageOrderValue.toStringAsFixed(2)}';
  String get formattedCommissionRate => '${commissionRate.toStringAsFixed(1)}%';
  String get formattedGoalProgress => '${goalProgress.toStringAsFixed(1)}%';
}
