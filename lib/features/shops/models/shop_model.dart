// ===============================
// lib/features/shops/models/shop_model.dart
// Complete Shop Model for Social Commerce Marketplace
// ===============================

import 'dart:convert';

class ShopModel {
  // ===============================
  // CORE FIELDS
  // ===============================
  final String id;              // Shop unique identifier
  final String ownerId;         // User ID who owns this shop (one-to-one relationship)
  final String shopName;        // Shop display name
  final String about;           // Shop description/bio
  final String shopBanner;      // Banner image URL
  
  // ===============================
  // STATUS FIELDS
  // ===============================
  final bool isActive;          // Is shop currently active/published?
  final bool isFeatured;        // Is shop featured on platform?
  final bool isVerified;        // Is shop verified (blue checkmark)?
  final bool isSuspended;       // Is shop temporarily suspended?
  
  // ===============================
  // STATISTICS FIELDS
  // ===============================
  final int productsCount;      // Total products/videos in shop
  final int followersCount;     // Total followers
  final int viewsCount;         // Total shop profile views
  final int likesCount;         // Total likes across all products
  
  // ===============================
  // SOCIAL FIELDS
  // ===============================
  final List<String> followerUIDs;    // List of user IDs following this shop
  final List<String> tags;             // Shop tags/categories
  
  // ===============================
  // CONTACT/INFO FIELDS (Simple Discovery)
  // ===============================
  final String location;        // Shop location (e.g., "Nairobi, Kenya")
  final String phoneNumber;     // Shop contact phone number
  
  // ===============================
  // TIMESTAMPS
  // ===============================
  final String createdAt;       // RFC3339 timestamp
  final String updatedAt;       // RFC3339 timestamp
  final String? lastProductAt;  // Last time a product was added

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.about,
    required this.shopBanner,
    required this.isActive,
    required this.isFeatured,
    required this.isVerified,
    this.isSuspended = false,
    required this.productsCount,
    required this.followersCount,
    required this.viewsCount,
    required this.likesCount,
    required this.followerUIDs,
    required this.tags,
    required this.location,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.lastProductAt,
  });

  // ===============================
  // FACTORY CONSTRUCTORS
  // ===============================

  /// Create a new shop (initial state)
  factory ShopModel.create({
    required String id,
    required String ownerId,
    required String shopName,
    required String about,
    required String shopBanner,
    required String location,
    required String phoneNumber,
    List<String>? tags,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return ShopModel(
      id: id,
      ownerId: ownerId,
      shopName: shopName,
      about: about,
      shopBanner: shopBanner,
      isActive: true,
      isFeatured: false,
      isVerified: false,
      isSuspended: false,
      productsCount: 0,
      followersCount: 0,
      viewsCount: 0,
      likesCount: 0,
      followerUIDs: [],
      tags: tags ?? [],
      location: location,
      phoneNumber: phoneNumber,
      createdAt: now,
      updatedAt: now,
      lastProductAt: null,
    );
  }

  /// Parse shop from backend JSON
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    try {
      return ShopModel(
        id: _parseString(json['id']),
        ownerId: _parseString(json['ownerId'] ?? json['owner_id']),
        shopName: _parseString(json['shopName'] ?? json['shop_name']),
        about: _parseString(json['about'] ?? json['description']),
        shopBanner: _parseString(json['shopBanner'] ?? json['shop_banner'] ?? json['banner']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isFeatured: _parseBool(json['isFeatured'] ?? json['is_featured'] ?? false),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? false),
        isSuspended: _parseBool(json['isSuspended'] ?? json['is_suspended'] ?? false),
        productsCount: _parseInt(json['productsCount'] ?? json['products_count'] ?? 0),
        followersCount: _parseInt(json['followersCount'] ?? json['followers_count'] ?? 0),
        viewsCount: _parseInt(json['viewsCount'] ?? json['views_count'] ?? 0),
        likesCount: _parseInt(json['likesCount'] ?? json['likes_count'] ?? 0),
        followerUIDs: _parseStringList(json['followerUIDs'] ?? json['follower_uids'] ?? json['follower_UIDs']),
        tags: _parseStringList(json['tags']),
        location: _parseString(json['location']),
        phoneNumber: _parseString(json['phoneNumber'] ?? json['phone_number']),
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
        lastProductAt: _parseTimestamp(json['lastProductAt'] ?? json['last_product_at']),
      );
    } catch (e) {
      print('❌ Error parsing ShopModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return a default shop model to prevent crashes
      return ShopModel(
        id: _parseString(json['id'] ?? ''),
        ownerId: _parseString(json['ownerId'] ?? json['owner_id'] ?? ''),
        shopName: _parseString(json['shopName'] ?? json['shop_name'] ?? 'Unknown Shop'),
        about: '',
        shopBanner: '',
        isActive: true,
        isFeatured: false,
        isVerified: false,
        isSuspended: false,
        productsCount: 0,
        followersCount: 0,
        viewsCount: 0,
        likesCount: 0,
        followerUIDs: [],
        tags: [],
        location: '',
        phoneNumber: '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        lastProductAt: null,
      );
    }
  }

  // ===============================
  // HELPER PARSING METHODS
  // ===============================

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is double) return value < 0 ? 0 : value.round();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0 : parsed;
    }
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
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
            .map((s) => s.replaceAll(r'\"', '"').replaceAll(r'\\', r'\'))
            .toList();
      }
      
      // Handle JSON array format: ["item1","item2"]
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON array: $trimmed');
        }
      }
      
      // Handle comma-separated string
      if (trimmed.contains(',')) {
        return trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      
      return [trimmed];
    }
    
    return [];
  }

  static String _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return DateTime.now().toIso8601String();
      
      try {
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
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
        return DateTime.now().toIso8601String();
      }
    }
    
    return DateTime.now().toIso8601String();
  }

  // ===============================
  // SERIALIZATION
  // ===============================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'shopName': shopName,
      'about': about,
      'shopBanner': shopBanner,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isVerified': isVerified,
      'isSuspended': isSuspended,
      'productsCount': productsCount,
      'followersCount': followersCount,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'followerUIDs': followerUIDs,
      'tags': tags,
      'location': location,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastProductAt': lastProductAt,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  // ===============================
  // COPYWIDTH METHOD
  // ===============================

  ShopModel copyWith({
    String? id,
    String? ownerId,
    String? shopName,
    String? about,
    String? shopBanner,
    bool? isActive,
    bool? isFeatured,
    bool? isVerified,
    bool? isSuspended,
    int? productsCount,
    int? followersCount,
    int? viewsCount,
    int? likesCount,
    List<String>? followerUIDs,
    List<String>? tags,
    String? location,
    String? phoneNumber,
    String? createdAt,
    String? updatedAt,
    String? lastProductAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopName: shopName ?? this.shopName,
      about: about ?? this.about,
      shopBanner: shopBanner ?? this.shopBanner,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      productsCount: productsCount ?? this.productsCount,
      followersCount: followersCount ?? this.followersCount,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      followerUIDs: followerUIDs ?? this.followerUIDs,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastProductAt: lastProductAt ?? this.lastProductAt,
    );
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  /// Returns true if shop has location
  bool get hasLocation => location.isNotEmpty;

  /// Returns true if shop has phone
  bool get hasPhone => phoneNumber.isNotEmpty;

  /// Returns true if shop can accept new products
  bool get canAddProducts => isActive && !isSuspended;

  /// Returns true if shop is operational
  bool get isOperational => isActive && !isSuspended;

  /// Returns shop status text
  String get statusText {
    if (isSuspended) return 'Suspended';
    if (!isActive) return 'Inactive';
    if (isFeatured && isVerified) return 'Featured & Verified';
    if (isFeatured) return 'Featured';
    if (isVerified) return 'Verified';
    return 'Active';
  }

  /// Returns verification badge
  String get verificationBadge => isVerified ? '✓' : '';

  /// Returns verification status text
  String get verificationStatus => isVerified ? 'Verified Shop' : 'Unverified';

  /// Returns featured badge
  String get featuredBadge => isFeatured ? '⭐' : '';

  /// Returns shop tier based on status
  String get shopTier {
    if (isFeatured && isVerified) return 'Premium';
    if (isVerified) return 'Verified';
    if (isFeatured) return 'Featured';
    return 'Standard';
  }

  /// Returns formatted followers count
  String get formattedFollowers => _formatCount(followersCount);

  /// Returns formatted products count
  String get formattedProducts => _formatCount(productsCount);

  /// Returns formatted views count
  String get formattedViews => _formatCount(viewsCount);

  /// Returns formatted likes count
  String get formattedLikes => _formatCount(likesCount);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Returns average likes per product
  double get averageLikesPerProduct {
    if (productsCount == 0) return 0.0;
    return likesCount / productsCount;
  }

  /// Returns engagement rate
  double get engagementRate {
    if (viewsCount == 0) return 0.0;
    return ((followersCount + likesCount) / viewsCount) * 100;
  }

  /// Returns formatted engagement rate
  String get formattedEngagementRate => '${engagementRate.toStringAsFixed(1)}%';

  // Timestamp helpers
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

  DateTime? get lastProductAtDateTime {
    if (lastProductAt == null || lastProductAt!.isEmpty) return null;
    try {
      return DateTime.parse(lastProductAt!);
    } catch (e) {
      return null;
    }
  }

  /// Returns time since last product
  String get timeSinceLastProduct {
    final lastProduct = lastProductAtDateTime;
    if (lastProduct == null) return 'Never posted';
    
    final now = DateTime.now();
    final difference = now.difference(lastProduct);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Returns shop age
  String get shopAge {
    final created = createdAtDateTime;
    final now = DateTime.now();
    final difference = now.difference(created);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else {
      return 'New';
    }
  }

  // ===============================
  // VALIDATION
  // ===============================

  bool get isValid => validate().isEmpty;

  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Shop ID is required');
    if (ownerId.isEmpty) errors.add('Owner ID is required');
    if (shopName.isEmpty) errors.add('Shop name is required');
    if (shopName.length < 3) errors.add('Shop name must be at least 3 characters');
    if (shopName.length > 50) errors.add('Shop name cannot exceed 50 characters');
    if (about.isEmpty) errors.add('Shop description is required');
    if (about.length < 10) errors.add('Shop description must be at least 10 characters');
    if (about.length > 500) errors.add('Shop description cannot exceed 500 characters');
    if (location.isEmpty) errors.add('Location is required');
    if (phoneNumber.isEmpty) errors.add('Phone number is required');
    
    // Basic phone validation (can be adjusted based on requirements)
    if (phoneNumber.isNotEmpty && phoneNumber.length < 10) {
      errors.add('Phone number must be at least 10 digits');
    }
    
    return errors;
  }

  // ===============================
  // EQUALITY & HASH
  // ===============================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ===============================
  // STRING REPRESENTATION
  // ===============================

  @override
  String toString() {
    return 'ShopModel(id: $id, name: $shopName, owner: $ownerId, verified: $isVerified, featured: $isFeatured, products: $productsCount)';
  }

  String toDebugString() {
    return '''
ShopModel {
  id: $id
  ownerId: $ownerId
  shopName: $shopName
  about: $about
  shopBanner: $shopBanner
  isActive: $isActive
  isFeatured: $isFeatured
  isVerified: $isVerified
  isSuspended: $isSuspended
  productsCount: $productsCount
  followersCount: $followersCount
  viewsCount: $viewsCount
  likesCount: $likesCount
  tags: $tags
  location: $location
  phoneNumber: $phoneNumber
  createdAt: $createdAt
  updatedAt: $updatedAt
  lastProductAt: $lastProductAt
  shopTier: $shopTier
  shopAge: $shopAge
  engagementRate: $formattedEngagementRate
  isValid: $isValid
}''';
  }
}

// ===============================
// EXTENSIONS
// ===============================

extension ShopModelList on List<ShopModel> {
  List<ShopModel> get activeShops => where((shop) => shop.isActive).toList();
  List<ShopModel> get inactiveShops => where((shop) => !shop.isActive).toList();
  List<ShopModel> get featuredShops => where((shop) => shop.isFeatured).toList();
  List<ShopModel> get verifiedShops => where((shop) => shop.isVerified).toList();
  List<ShopModel> get suspendedShops => where((shop) => shop.isSuspended).toList();
  List<ShopModel> get operationalShops => where((shop) => shop.isOperational).toList();
  
  List<ShopModel> sortByFollowers({bool descending = true}) {
    final sorted = List<ShopModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.followersCount.compareTo(a.followersCount) 
        : a.followersCount.compareTo(b.followersCount));
    return sorted;
  }
  
  List<ShopModel> sortByProducts({bool descending = true}) {
    final sorted = List<ShopModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.productsCount.compareTo(a.productsCount) 
        : a.productsCount.compareTo(b.productsCount));
    return sorted;
  }
  
  List<ShopModel> sortByEngagement({bool descending = true}) {
    final sorted = List<ShopModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.engagementRate.compareTo(a.engagementRate) 
        : a.engagementRate.compareTo(b.engagementRate));
    return sorted;
  }
  
  List<ShopModel> filterByOwner(String ownerId) {
    return where((shop) => shop.ownerId == ownerId).toList();
  }
  
  List<ShopModel> filterByTag(String tag) {
    return where((shop) => shop.tags.contains(tag)).toList();
  }
  
  List<ShopModel> search(String query) {
    final searchQuery = query.toLowerCase();
    return where((shop) => 
      shop.shopName.toLowerCase().contains(searchQuery) ||
      shop.about.toLowerCase().contains(searchQuery) ||
      shop.tags.any((tag) => tag.toLowerCase().contains(searchQuery))
    ).toList();
  }
  
  int get totalProducts => fold<int>(0, (sum, shop) => sum + shop.productsCount);
  int get totalFollowers => fold<int>(0, (sum, shop) => sum + shop.followersCount);
  
  double get averageProducts {
    if (isEmpty) return 0.0;
    return totalProducts / length;
  }
  
  double get averageFollowers {
    if (isEmpty) return 0.0;
    return totalFollowers / length;
  }
}