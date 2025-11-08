// lib/features/shops/constants/shop_constants.dart

class ShopConstants {
  ShopConstants._();

  // ==================== DEFAULT VALUES ====================

  static const int defaultPageLimit = 20;
  static const int defaultOffset = 0;
  static const int maxProductsPerPage = 50;
  static const int minStockThreshold = 5;
  static const int defaultLowStockThreshold = 10;
  static const int maxProductImages = 10;

  // ==================== COMMISSION RATES ====================

  static const double defaultCommissionRate = 10.0; // 10%
  static const double platformFeeRate = 5.0; // 5%
  static const double minCommissionRate = 5.0;
  static const double maxCommissionRate = 30.0;
  static const double liveStreamCommissionBonus = 2.0; // Extra 2% for live stream sales
  static const double flashSaleCommissionBonus = 1.5; // Extra 1.5% for flash sales

  // ==================== PRICING ====================

  static const double minProductPrice = 1.0; // KES 1
  static const double maxProductPrice = 1000000.0; // KES 1M
  static const double minOrderAmount = 10.0; // KES 10
  static const double defaultShippingCost = 0.0;
  static const double freeShippingThreshold = 1000.0; // Free shipping above KES 1000

  // ==================== INVENTORY ====================

  static const int maxStockQuantity = 999999;
  static const int defaultMaxStock = 1000;
  static const int outOfStockThreshold = 0;
  static const int cartMaxQuantityPerItem = 99;

  // ==================== SHOP SETTINGS ====================

  static const int minShopNameLength = 3;
  static const int maxShopNameLength = 50;
  static const int minShopDescriptionLength = 10;
  static const int maxShopDescriptionLength = 500;
  static const int maxShopTags = 10;
  static const int maxFeaturedProducts = 20;

  // ==================== PRODUCT SETTINGS ====================

  static const int minProductNameLength = 3;
  static const int maxProductNameLength = 100;
  static const int minProductDescriptionLength = 10;
  static const int maxProductDescriptionLength = 1000;
  static const int maxProductKeywords = 15;
  static const int maxProductVariants = 50;

  // ==================== ORDER SETTINGS ====================

  static const int orderExpiryMinutes = 30; // Order expires after 30 minutes if not paid
  static const int orderCancellationGracePeriodHours = 1; // Can cancel within 1 hour
  static const int refundProcessingDays = 7; // Refund takes up to 7 days
  static const int deliveryEstimateDays = 3; // Estimated delivery time
  static const int autoDeliveryConfirmationDays = 14; // Auto-confirm delivery after 14 days

  // ==================== PAYOUT SETTINGS ====================

  static const double minPayoutAmount = 100.0; // KES 100 minimum payout
  static const double maxPayoutAmount = 500000.0; // KES 500K max per payout
  static const int payoutProcessingDays = 5; // Payout processed within 5 days
  static const int minDaysBetweenPayouts = 7; // Can request payout every 7 days

  // ==================== FLASH SALE SETTINGS ====================

  static const int minFlashSaleDuration = 5; // 5 minutes minimum
  static const int maxFlashSaleDuration = 240; // 4 hours maximum
  static const int defaultFlashSaleDuration = 30; // 30 minutes default
  static const double minFlashSaleDiscount = 5.0; // 5% minimum discount
  static const double maxFlashSaleDiscount = 70.0; // 70% maximum discount

  // ==================== CART SETTINGS ====================

  static const int cartExpiryDays = 30; // Cart items expire after 30 days
  static const int maxCartItems = 100;
  static const int maxItemsPerShop = 50;
  static const int cartValidationIntervalMinutes = 5; // Validate cart every 5 minutes

  // ==================== SEARCH & FILTER ====================

  static const int minSearchQueryLength = 2;
  static const int maxSearchQueryLength = 100;
  static const int searchResultsLimit = 50;
  static const List<String> sortOptions = [
    'popularity',
    'price_low_high',
    'price_high_low',
    'newest',
    'rating',
    'sales'
  ];

  // ==================== SHOP CATEGORIES ====================

  static const List<String> shopCategories = [
    'Fashion & Clothing',
    'Electronics',
    'Home & Living',
    'Beauty & Personal Care',
    'Sports & Outdoors',
    'Books & Stationery',
    'Toys & Games',
    'Food & Beverages',
    'Health & Wellness',
    'Automotive',
    'Jewelry & Accessories',
    'Arts & Crafts',
    'Pet Supplies',
    'Baby & Kids',
    'Other'
  ];

  // ==================== PRODUCT CATEGORIES ====================

  static const List<String> productCategories = [
    'Clothing',
    'Shoes',
    'Accessories',
    'Electronics',
    'Phones & Tablets',
    'Computers',
    'Home Appliances',
    'Furniture',
    'Decor',
    'Beauty',
    'Skincare',
    'Makeup',
    'Sports Equipment',
    'Fitness',
    'Books',
    'Toys',
    'Games',
    'Food',
    'Beverages',
    'Health',
    'Other'
  ];

  // ==================== ORDER STATUS ====================

  static const List<String> orderStatusSequence = [
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered'
  ];

  // ==================== PAYOUT METHODS ====================

  static const List<String> payoutMethods = [
    'M-Pesa',
    'Bank Transfer',
    'Wallet'
  ];

  // ==================== VALIDATION MESSAGES ====================

  static const String invalidPriceMessage = 'Price must be between KES 1 and KES 1,000,000';
  static const String invalidStockMessage = 'Stock must be between 0 and 999,999';
  static const String invalidCommissionMessage = 'Commission rate must be between 5% and 30%';
  static const String invalidPayoutMessage = 'Payout amount must be between KES 100 and KES 500,000';
  static const String insufficientStockMessage = 'Insufficient stock available';
  static const String cartEmptyMessage = 'Your cart is empty';
  static const String orderExpiredMessage = 'Order has expired';
  static const String invalidShopNameMessage = 'Shop name must be between 3 and 50 characters';

  // ==================== SUCCESS MESSAGES ====================

  static const String shopCreatedMessage = 'Shop created successfully';
  static const String productAddedMessage = 'Product added successfully';
  static const String orderPlacedMessage = 'Order placed successfully';
  static const String payoutRequestedMessage = 'Payout requested successfully';
  static const String cartUpdatedMessage = 'Cart updated';
  static const String stockUpdatedMessage = 'Stock updated successfully';

  // ==================== ERROR MESSAGES ====================

  static const String shopNotFoundMessage = 'Shop not found';
  static const String productNotFoundMessage = 'Product not found';
  static const String orderNotFoundMessage = 'Order not found';
  static const String insufficientBalanceMessage = 'Insufficient balance';
  static const String payoutFailedMessage = 'Payout request failed';
  static const String networkErrorMessage = 'Network error. Please try again';
}
