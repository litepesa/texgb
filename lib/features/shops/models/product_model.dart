// ===============================
// lib/features/products/models/product_model.dart
// Complete Product Model for Social Commerce Marketplace
// ===============================
// CHANGES:
// 1. Boost removed (now at Shop level)
// 2. Added flashSale field
// 3. Renamed caption → description
// 4. Renamed tags → keywords (short product identifiers like "adidas terrex", "toyota prado")
// ===============================

import 'dart:convert';

class ProductModel {
  final String id;
  
  // Shop references (products belong to shops)
  final String shopId;          
  final String shopName;        
  final String shopImage;       // Shop banner
  
  final String videoUrl;
  final String thumbnailUrl;
  final String description;     // Product description (formerly caption)
  final double price;           // Price field for products 
  
  // Engagement counts
  final int views;        
  final int likes;          
  final int comments;     
  final int shares;       
  
  final List<String> keywords;  // Short product identifiers (formerly tags)
  final bool isActive;
  final bool isFeatured;
  final bool isVerified;        // Verified status from database
  final bool isMultipleImages;
  final List<String> imageUrls;
  
  // NEW: Flash sale field
  final bool flashSale;         // Is this product on flash sale?
  final String? flashSaleEndsAt; // When flash sale ends (RFC3339 timestamp)
  final double? flashSalePrice;  // Special flash sale price
  
  final String createdAt;       // RFC3339 string format from PostgreSQL
  final String updatedAt;       // RFC3339 string format from PostgreSQL

  // Runtime fields (not stored in DB)
  final bool isLiked;
  final bool isFollowing;

  const ProductModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.shopImage,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    this.price = 0.0,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.keywords,
    required this.isActive,
    required this.isFeatured,
    this.isVerified = false,
    required this.isMultipleImages,
    required this.imageUrls,
    this.flashSale = false,
    this.flashSaleEndsAt,
    this.flashSalePrice,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.isFollowing = false,
  });

  // fromJson method with PostgreSQL-compatible field mapping
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProductModel(
        id: _parseString(json['id']),
        shopId: _parseString(json['shopId'] ?? json['shop_id'] ?? json['userId'] ?? json['user_id']),
        shopName: _parseString(json['shopName'] ?? json['shop_name'] ?? json['userName'] ?? json['user_name']),
        shopImage: _parseString(json['shopImage'] ?? json['shop_image'] ?? json['userImage'] ?? json['user_image']),
        videoUrl: _parseString(json['videoUrl'] ?? json['video_url']),
        thumbnailUrl: _parseString(json['thumbnailUrl'] ?? json['thumbnail_url']),
        description: _parseString(json['description'] ?? json['caption']),
        price: _parsePrice(json['price']),
        
        // Map backend field names to frontend names
        views: _parseCount(
          json['views'] ?? 
          json['viewsCount'] ?? 
          json['views_count'] ?? 
          json['ViewsCount'] ?? 
          0
        ),
        likes: _parseCount(
          json['likes'] ?? 
          json['likesCount'] ?? 
          json['likes_count'] ?? 
          json['LikesCount'] ?? 
          0
        ),
        comments: _parseCount(
          json['comments'] ?? 
          json['commentsCount'] ?? 
          json['comments_count'] ?? 
          json['CommentsCount'] ?? 
          0
        ),
        shares: _parseCount(
          json['shares'] ?? 
          json['sharesCount'] ?? 
          json['shares_count'] ?? 
          json['SharesCount'] ?? 
          0
        ),
        
        keywords: _parseStringList(json['keywords'] ?? json['tags']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isFeatured: _parseBool(json['isFeatured'] ?? json['is_featured'] ?? false),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? false),
        isMultipleImages: _parseBool(json['isMultipleImages'] ?? json['is_multiple_images'] ?? false),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        
        // Parse flash sale fields
        flashSale: _parseBool(json['flashSale'] ?? json['flash_sale'] ?? false),
        flashSaleEndsAt: _parseTimestamp(json['flashSaleEndsAt'] ?? json['flash_sale_ends_at']),
        flashSalePrice: _parsePrice(json['flashSalePrice'] ?? json['flash_sale_price']),
        
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']) ?? DateTime.now().toIso8601String(),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']) ?? DateTime.now().toIso8601String(),
        
        isLiked: _parseBool(json['isLiked'] ?? false),
        isFollowing: _parseBool(json['isFollowing'] ?? false),
      );
    } catch (e) {
      print('❌ Error parsing ProductModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return a default product model to prevent crashes
      return ProductModel(
        id: _parseString(json['id'] ?? ''),
        shopId: _parseString(json['shopId'] ?? json['shop_id'] ?? json['userId'] ?? json['user_id'] ?? ''),
        shopName: _parseString(json['shopName'] ?? json['shop_name'] ?? json['userName'] ?? json['user_name'] ?? 'Unknown Shop'),
        shopImage: '',
        videoUrl: _parseString(json['videoUrl'] ?? json['video_url'] ?? ''),
        thumbnailUrl: _parseString(json['thumbnailUrl'] ?? json['thumbnail_url'] ?? ''),
        description: _parseString(json['description'] ?? json['caption'] ?? 'No description'),
        price: 0.0,
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        keywords: [],
        isActive: true,
        isFeatured: false,
        isVerified: false,
        isMultipleImages: false,
        imageUrls: [],
        flashSale: false,
        flashSaleEndsAt: null,
        flashSalePrice: null,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        isLiked: false,
        isFollowing: false,
      );
    }
  }

  // HELPER: Safely parse string fields
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // HELPER: Safely parse boolean fields
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  // HELPER: Safely parse price fields
  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value < 0 ? 0.0 : value;
    if (value is int) return value < 0 ? 0.0 : value.toDouble();
    
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0.0 : parsed;
    }
    
    print('⚠️ Warning: Could not parse price value: $value (type: ${value.runtimeType})');
    return 0.0;
  }

  // HELPER: Safely parse count fields with enhanced error handling
  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) return value < 0 ? 0 : value;
    
    if (value is double) return value < 0 ? 0 : value.round();
    
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0 : parsed;
      
      final parsedDouble = double.tryParse(value.trim());
      if (parsedDouble != null) return parsedDouble < 0 ? 0 : parsedDouble.round();
    }
    
    print('⚠️ Warning: Could not parse count value: $value (type: ${value.runtimeType})');
    return 0;
  }

  // HELPER: Safely parse string lists (PostgreSQL arrays and JSON arrays)
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // Handle PostgreSQL array format: {item1,item2,item3}
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        return content
            .split(',')
            .map((item) {
              final cleaned = item.trim();
              if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                return cleaned.substring(1, cleaned.length - 1);
              }
              return cleaned;
            })
            .where((s) => s.isNotEmpty)
            .map((s) {
              return s
                  .replaceAll(r'\"', '"')
                  .replaceAll(r'\\', r'\');
            })
            .toList();
      }
      
      // Handle JSON array format: ["item1","item2"]
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON array: $trimmed');
        }
      }
      
      // Handle comma-separated string: "item1,item2,item3"
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      return [trimmed];
    }
    
    print('⚠️ Warning: Could not parse string list: $value (type: ${value.runtimeType})');
    return [];
  }

  // HELPER: Parse timestamp (PostgreSQL RFC3339 strings and other formats)
  static String? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      
      try {
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse timestamp: $trimmed');
        return null;
      }
    }
    
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    if (value is int) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse Unix timestamp: $value');
        return null;
      }
    }
    
    if (value is double) {
      try {
        final milliseconds = (value * 1000).round();
        final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse Unix timestamp: $value');
        return null;
      }
    }
    
    print('⚠️ Warning: Unknown timestamp format: $value (type: ${value.runtimeType})');
    return null;
  }

  // Formatted price getter
  String get formattedPrice {
    if (price == 0) {
      return 'KES 0';
    }
    
    if (price < 1000000) {
      return 'KES ${price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      double millions = price / 1000000;
      if (millions == millions.toInt()) {
        return 'KES ${millions.toInt()}M';
      } else {
        return 'KES ${millions.toStringAsFixed(1)}M';
      }
    }
  }

  // FLASH SALE HELPER METHODS
  
  /// Returns true if flash sale is active (not expired)
  bool get isFlashSaleActive {
    if (!flashSale || flashSaleEndsAt == null) return false;
    
    try {
      final endsAt = DateTime.parse(flashSaleEndsAt!);
      return DateTime.now().isBefore(endsAt);
    } catch (e) {
      return false;
    }
  }

  /// Returns true if flash sale has expired
  bool get isFlashSaleExpired {
    if (!flashSale || flashSaleEndsAt == null) return false;
    
    try {
      final endsAt = DateTime.parse(flashSaleEndsAt!);
      return DateTime.now().isAfter(endsAt);
    } catch (e) {
      return false;
    }
  }

  /// Returns time remaining for flash sale
  String get flashSaleTimeRemaining {
    if (!flashSale || flashSaleEndsAt == null) return '';
    
    try {
      final endsAt = DateTime.parse(flashSaleEndsAt!);
      final now = DateTime.now();
      
      if (now.isAfter(endsAt)) return 'Ended';
      
      final difference = endsAt.difference(now);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ${difference.inHours % 24}h';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m';
      } else {
        return '${difference.inMinutes}m';
      }
    } catch (e) {
      return '';
    }
  }

  /// Returns the effective price (flash sale price if active, regular price otherwise)
  double get effectivePrice {
    if (isFlashSaleActive && flashSalePrice != null) {
      return flashSalePrice!;
    }
    return price;
  }

  /// Returns formatted effective price
  String get formattedEffectivePrice {
    final effectiveP = effectivePrice;
    
    if (effectiveP == 0) {
      return 'KES 0';
    }
    
    if (effectiveP < 1000000) {
      return 'KES ${effectiveP.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      double millions = effectiveP / 1000000;
      if (millions == millions.toInt()) {
        return 'KES ${millions.toInt()}M';
      } else {
        return 'KES ${millions.toStringAsFixed(1)}M';
      }
    }
  }

  /// Returns discount percentage for flash sale
  double get flashSaleDiscountPercentage {
    if (!isFlashSaleActive || flashSalePrice == null || price == 0) {
      return 0.0;
    }
    
    return ((price - flashSalePrice!) / price) * 100;
  }

  /// Returns formatted discount percentage
  String get formattedFlashSaleDiscount {
    final discount = flashSaleDiscountPercentage;
    if (discount == 0) return '';
    return '${discount.toStringAsFixed(0)}% OFF';
  }

  /// Returns formatted flash sale price
  String? get formattedFlashSalePrice {
    if (flashSalePrice == null) return null;
    
    if (flashSalePrice! < 1000000) {
      return 'KES ${flashSalePrice!.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      double millions = flashSalePrice! / 1000000;
      if (millions == millions.toInt()) {
        return 'KES ${millions.toInt()}M';
      } else {
        return 'KES ${millions.toStringAsFixed(1)}M';
      }
    }
  }

  // Helper methods for display formatting
  String get formattedViews => _formatCount(views);
  String get formattedLikes => _formatCount(likes);
  String get formattedComments => _formatCount(comments);
  String get formattedShares => _formatCount(shares);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Engagement calculation
  double get engagementRate {
    if (views == 0) return 0.0;
    final totalEngagement = likes + comments + shares;
    return (totalEngagement / views) * 100;
  }

  String get formattedEngagementRate {
    return '${engagementRate.toStringAsFixed(1)}%';
  }

  // Verification status helpers
  bool get isVerifiedContent => isVerified;
  String get verificationStatus => isVerified ? 'Verified' : 'Unverified';
  String get verificationBadge => isVerified ? '✓' : '';
  String get verificationBadgeText => isVerified ? '✓ Verified' : '';

  // Content type helpers
  bool get isVideoContent => !isMultipleImages && videoUrl.isNotEmpty;
  bool get isImageContent => isMultipleImages && imageUrls.isNotEmpty;
  bool get hasValidContent => isVideoContent || isImageContent;

  bool get isPremiumContent => isVerified && price > 0;
  bool get isVerifiedFreeContent => isVerified && price == 0;

  String get displayUrl {
    if (isImageContent && imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    if (thumbnailUrl.isNotEmpty) {
      return thumbnailUrl;
    }
    return videoUrl;
  }

  int get mediaCount {
    if (isImageContent) return imageUrls.length;
    return 1; // Single video
  }

  /// Returns content quality tier based on verification, featured status, and engagement
  String get contentTier {
    if (isVerified && isFeatured) return 'Premium+';
    if (isVerified) return 'Premium';
    if (isFeatured) return 'Featured';
    if (engagementRate > 5.0) return 'Popular';
    return 'Standard';
  }

  // Time helpers
  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get updatedAtDateTime {
    try {
      return DateTime.parse(updatedAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = createdAtDateTime;
    final difference = now.difference(created);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'shopImage': shopImage,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'price': price,
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'keywords': keywords,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isVerified': isVerified,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
      'flashSale': flashSale,
      'flashSaleEndsAt': flashSaleEndsAt,
      'flashSalePrice': flashSalePrice,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLiked': isLiked,
      'isFollowing': isFollowing,
    };
  }

  // copyWith method for state updates
  ProductModel copyWith({
    String? id,
    String? shopId,
    String? shopName,
    String? shopImage,
    String? videoUrl,
    String? thumbnailUrl,
    String? description,
    double? price,
    int? views,
    int? likes,
    int? comments,
    int? shares,
    List<String>? keywords,
    bool? isActive,
    bool? isFeatured,
    bool? isVerified,
    bool? isMultipleImages,
    List<String>? imageUrls,
    bool? flashSale,
    String? flashSaleEndsAt,
    double? flashSalePrice,
    String? createdAt,
    String? updatedAt,
    bool? isLiked,
    bool? isFollowing,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopImage: shopImage ?? this.shopImage,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      keywords: keywords ?? this.keywords,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
      flashSale: flashSale ?? this.flashSale,
      flashSaleEndsAt: flashSaleEndsAt ?? this.flashSaleEndsAt,
      flashSalePrice: flashSalePrice ?? this.flashSalePrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  // Update counts (for real-time updates)
  ProductModel updateCounts({
    int? views,
    int? likes,
    int? comments,
    int? shares,
  }) {
    return copyWith(
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Toggle like status
  ProductModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Toggle verification status
  ProductModel toggleVerification() {
    return copyWith(
      isVerified: !isVerified,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Set verification status
  ProductModel setVerified(bool verified) {
    return copyWith(
      isVerified: verified,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Start flash sale
  ProductModel startFlashSale({
    required double salePrice,
    required Duration duration,
  }) {
    final endsAt = DateTime.now().add(duration).toIso8601String();
    return copyWith(
      flashSale: true,
      flashSalePrice: salePrice,
      flashSaleEndsAt: endsAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // End flash sale
  ProductModel endFlashSale() {
    return copyWith(
      flashSale: false,
      flashSalePrice: null,
      flashSaleEndsAt: null,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Increment view count
  ProductModel incrementViews() {
    return copyWith(
      views: views + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Increment share count
  ProductModel incrementShares() {
    return copyWith(
      shares: shares + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Validation methods
  bool get isValid {
    return id.isNotEmpty && 
           shopId.isNotEmpty && 
           shopName.isNotEmpty && 
           description.isNotEmpty && 
           hasValidContent;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (shopId.isEmpty) errors.add('Shop ID is required');
    if (shopName.isEmpty) errors.add('Shop name is required');
    if (description.isEmpty) errors.add('Description is required');
    if (!hasValidContent) errors.add('Valid video or image content is required');
    
    if (isImageContent && imageUrls.isEmpty) {
      errors.add('Image URLs are required for image posts');
    }
    
    if (isVideoContent && videoUrl.isEmpty) {
      errors.add('Video URL is required for video posts');
    }
    
    return errors;
  }

  // Search helpers
  bool containsQuery(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    
    return description.toLowerCase().contains(searchQuery) ||
           shopName.toLowerCase().contains(searchQuery) ||
           keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery));
  }

  bool hasKeyword(String keyword) {
    return keywords.any((k) => k.toLowerCase() == keyword.toLowerCase());
  }

  // toString method
  @override
  String toString() {
    return 'ProductModel(id: $id, description: "${description.length > 30 ? "${description.substring(0, 30)}..." : description}", views: $views, likes: $likes, price: $formattedPrice, flashSale: $flashSale, verified: $isVerified, shop: $shopName)';
  }

  // Detailed debug string
  String toDebugString() {
    return '''
ProductModel {
  id: $id
  shopId: $shopId
  shopName: $shopName
  shopImage: $shopImage
  description: $description
  price: $formattedPrice
  views: $views
  likes: $likes
  comments: $comments
  shares: $shares
  keywords: $keywords
  isActive: $isActive
  isFeatured: $isFeatured
  isVerified: $isVerified ✓
  isMultipleImages: $isMultipleImages
  imageUrls: $imageUrls
  videoUrl: $videoUrl
  thumbnailUrl: $thumbnailUrl
  flashSale: $flashSale 🔥
  flashSaleEndsAt: $flashSaleEndsAt
  flashSalePrice: $formattedFlashSalePrice
  flashSaleActive: $isFlashSaleActive
  flashSaleTimeRemaining: $flashSaleTimeRemaining
  effectivePrice: $formattedEffectivePrice
  createdAt: $createdAt
  updatedAt: $updatedAt
  isLiked: $isLiked
  isFollowing: $isFollowing
  engagementRate: ${engagementRate.toStringAsFixed(2)}%
  contentTier: $contentTier
  verificationStatus: $verificationStatus
  isValid: $isValid
}''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensions for additional functionality
extension ProductModelList on List<ProductModel> {
  List<ProductModel> get activeProducts => where((product) => product.isActive).toList();
  List<ProductModel> get featuredProducts => where((product) => product.isFeatured).toList();
  List<ProductModel> get verifiedProducts => where((product) => product.isVerified).toList();
  List<ProductModel> get unverifiedProducts => where((product) => !product.isVerified).toList();
  List<ProductModel> get premiumProducts => where((product) => product.isPremiumContent).toList();
  List<ProductModel> get verifiedFreeProducts => where((product) => product.isVerifiedFreeContent).toList();
  List<ProductModel> get imageProducts => where((product) => product.isImageContent).toList();
  List<ProductModel> get videoContent => where((product) => product.isVideoContent).toList();
  
  // Flash sale filtering
  List<ProductModel> get flashSaleProducts => where((product) => product.flashSale).toList();
  List<ProductModel> get activeFlashSaleProducts => where((product) => product.isFlashSaleActive).toList();
  
  List<ProductModel> sortByViews({bool descending = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) => descending ? b.views.compareTo(a.views) : a.views.compareTo(b.views));
    return sorted;
  }
  
  List<ProductModel> sortByLikes({bool descending = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) => descending ? b.likes.compareTo(a.likes) : a.likes.compareTo(b.likes));
    return sorted;
  }
  
  List<ProductModel> sortByPrice({bool descending = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) => descending ? b.price.compareTo(a.price) : a.price.compareTo(b.price));
    return sorted;
  }
  
  List<ProductModel> sortByEngagement({bool descending = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.engagementRate.compareTo(a.engagementRate) 
        : a.engagementRate.compareTo(b.engagementRate));
    return sorted;
  }
  
  List<ProductModel> sortByDate({bool descending = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
        : a.createdAtDateTime.compareTo(b.createdAtDateTime));
    return sorted;
  }

  List<ProductModel> sortByVerification({bool verifiedFirst = true}) {
    final sorted = List<ProductModel>.from(this);
    sorted.sort((a, b) {
      if (verifiedFirst) {
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;
        return 0;
      } else {
        if (!a.isVerified && b.isVerified) return -1;
        if (a.isVerified && !b.isVerified) return 1;
        return 0;
      }
    });
    return sorted;
  }

  List<ProductModel> sortByContentTier() {
    final sorted = List<ProductModel>.from(this);
    final tierOrder = {
      'Premium+': 0, 
      'Premium': 1, 
      'Featured': 2,
      'Popular': 3, 
      'Standard': 4
    };
    
    sorted.sort((a, b) {
      final aTier = tierOrder[a.contentTier] ?? 5;
      final bTier = tierOrder[b.contentTier] ?? 5;
      return aTier.compareTo(bTier);
    });
    return sorted;
  }
  
  List<ProductModel> filterByShop(String shopId) {
    return where((product) => product.shopId == shopId).toList();
  }
  
  List<ProductModel> filterByKeyword(String keyword) {
    return where((product) => product.hasKeyword(keyword)).toList();
  }
  
  List<ProductModel> filterByPriceRange(double minPrice, double maxPrice) {
    return where((product) => product.price >= minPrice && product.price <= maxPrice).toList();
  }

  List<ProductModel> filterByVerification(bool isVerified) {
    return where((product) => product.isVerified == isVerified).toList();
  }

  List<ProductModel> filterByContentTier(String tier) {
    return where((product) => product.contentTier == tier).toList();
  }

  List<ProductModel> get premiumContent => where((product) => product.isPremiumContent).toList();

  List<ProductModel> get freeVerifiedContent => where((product) => product.isVerifiedFreeContent).toList();
  
  List<ProductModel> search(String query) {
    return where((product) => product.containsQuery(query)).toList();
  }
  
  int get totalViews => fold<int>(0, (sum, product) => sum + product.views);
  int get totalLikes => fold<int>(0, (sum, product) => sum + product.likes);
  int get totalComments => fold<int>(0, (sum, product) => sum + product.comments);
  int get totalShares => fold<int>(0, (sum, product) => sum + product.shares);
  double get totalPrice => fold<double>(0.0, (sum, product) => sum + product.price);

  int get verifiedCount => where((product) => product.isVerified).length;
  int get unverifiedCount => where((product) => !product.isVerified).length;
  double get verificationPercentage {
    if (isEmpty) return 0.0;
    return (verifiedCount / length) * 100;
  }

  int get flashSaleCount => where((product) => product.flashSale).length;
  int get activeFlashSaleCount => where((product) => product.isFlashSaleActive).length;
  double get flashSalePercentage {
    if (isEmpty) return 0.0;
    return (flashSaleCount / length) * 100;
  }

  int get premiumContentCount => where((product) => product.isPremiumContent).length;
  double get premiumContentPercentage {
    if (isEmpty) return 0.0;
    return (premiumContentCount / length) * 100;
  }

  double get averageEngagementRate {
    if (isEmpty) return 0.0;
    final totalEngagement = fold<double>(0.0, (sum, product) => sum + product.engagementRate);
    return totalEngagement / length;
  }
  
  double get averagePrice {
    if (isEmpty) return 0.0;
    return totalPrice / length;
  }

  double get verifiedAverageEngagement {
    final verified = verifiedProducts;
    if (verified.isEmpty) return 0.0;
    final totalEngagement = verified.fold<double>(0.0, (sum, product) => sum + product.engagementRate);
    return totalEngagement / verified.length;
  }

  double get unverifiedAverageEngagement {
    final unverified = unverifiedProducts;
    if (unverified.isEmpty) return 0.0;
    final totalEngagement = unverified.fold<double>(0.0, (sum, product) => sum + product.engagementRate);
    return totalEngagement / unverified.length;
  }

  List<ProductModel> get topVerifiedProducts => verifiedProducts.sortByEngagement().take(10).toList();
  List<ProductModel> get topPremiumProducts => premiumProducts.sortByEngagement().take(10).toList();
  List<ProductModel> get topFlashSaleProducts => activeFlashSaleProducts.sortByEngagement().take(10).toList();
}