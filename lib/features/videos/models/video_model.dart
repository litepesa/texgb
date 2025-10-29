// ===============================
// lib/features/videos/models/video_model.dart
// Complete Video Model for PostgreSQL Backend (100% Compatible)
// Enhanced with Verified Field + BOOST FIELDS
// ===============================

import 'dart:convert';

class VideoModel {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final double price; // Price field for business posts 
  
  // 🔧 CRITICAL FIX: Use correct field names that match backend database
  final int views;        // Backend: views_count -> Frontend: views
  final int likes;        // Backend: likes_count -> Frontend: likes  
  final int comments;     // Backend: comments_count -> Frontend: comments
  final int shares;       // Backend: shares_count -> Frontend: shares
  
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final bool isVerified;  // Verified status from database
  final bool isMultipleImages;
  final List<String> imageUrls;
  final String createdAt; // RFC3339 string format from PostgreSQL
  final String updatedAt; // RFC3339 string format from PostgreSQL

  // 🆕 BOOST FIELDS
  final bool isBoosted;           // Is video currently boosted?
  final String boostTier;         // 'none', 'basic', 'standard', 'advanced'
  final bool superBoost;          // For future custom boost features

  // Runtime fields (not stored in DB)
  final bool isLiked;
  final bool isFollowing;

  const VideoModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    this.price = 0.0, // Default price is 0
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.tags,
    required this.isActive,
    required this.isFeatured,
    this.isVerified = false, // Default verified status is false
    required this.isMultipleImages,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isBoosted = false,         // 🆕 Default not boosted
    this.boostTier = 'none',        // 🆕 Default no boost tier
    this.superBoost = false,        // 🆕 Default no super boost
    this.isLiked = false,
    this.isFollowing = false,
  });

  // 🔧 CRITICAL FIX: fromJson method with PostgreSQL-compatible field mapping + BOOST FIELDS
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    try {
      return VideoModel(
        id: _parseString(json['id']),
        userId: _parseString(json['userId'] ?? json['user_id']),
        userName: _parseString(json['userName'] ?? json['user_name']),
        userImage: _parseString(json['userImage'] ?? json['user_image']),
        videoUrl: _parseString(json['videoUrl'] ?? json['video_url']),
        thumbnailUrl: _parseString(json['thumbnailUrl'] ?? json['thumbnail_url']),
        caption: _parseString(json['caption']),
        price: _parsePrice(json['price']),
        
        // 🔧 CRITICAL FIX: Map backend field names to frontend names
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
        
        tags: _parseStringList(json['tags']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isFeatured: _parseBool(json['isFeatured'] ?? json['is_featured'] ?? false),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? false),
        isMultipleImages: _parseBool(json['isMultipleImages'] ?? json['is_multiple_images'] ?? false),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
        
        // 🆕 PARSE BOOST FIELDS
        isBoosted: _parseBool(json['isBoosted'] ?? json['is_boosted'] ?? false),
        boostTier: _parseBoostTier(json['boostTier'] ?? json['boost_tier']),
        superBoost: _parseBool(json['superBoost'] ?? json['super_boost'] ?? false),
        
        isLiked: _parseBool(json['isLiked'] ?? false),
        isFollowing: _parseBool(json['isFollowing'] ?? false),
      );
    } catch (e) {
      print('❌ Error parsing VideoModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return a default video model to prevent crashes
      return VideoModel(
        id: _parseString(json['id'] ?? ''),
        userId: _parseString(json['userId'] ?? json['user_id'] ?? ''),
        userName: _parseString(json['userName'] ?? json['user_name'] ?? 'Unknown'),
        userImage: '',
        videoUrl: _parseString(json['videoUrl'] ?? json['video_url'] ?? ''),
        thumbnailUrl: _parseString(json['thumbnailUrl'] ?? json['thumbnail_url'] ?? ''),
        caption: _parseString(json['caption'] ?? 'No caption'),
        price: 0.0,
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        tags: [],
        isActive: true,
        isFeatured: false,
        isVerified: false,
        isMultipleImages: false,
        imageUrls: [],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        isBoosted: false,
        boostTier: 'none',
        superBoost: false,
        isLiked: false,
        isFollowing: false,
      );
    }
  }

  // 🔧 HELPER: Safely parse string fields
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // 🔧 HELPER: Safely parse boolean fields
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  // 🔧 NEW HELPER: Safely parse price fields
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

  // 🆕 NEW HELPER: Safely parse boost tier
  static String _parseBoostTier(dynamic value) {
    if (value == null) return 'none';
    
    final tierStr = value.toString().toLowerCase().trim();
    
    // Validate boost tier
    const validTiers = ['none', 'basic', 'standard', 'advanced'];
    if (validTiers.contains(tierStr)) {
      return tierStr;
    }
    
    print('⚠️ Warning: Invalid boost tier: $value, defaulting to "none"');
    return 'none';
  }

  // 🔧 HELPER: Safely parse count fields with enhanced error handling
  static int _parseCount(dynamic value) {
    if (value == null) return 0;
    
    if (value is int) return value < 0 ? 0 : value;
    
    if (value is double) return value < 0 ? 0 : value.round();
    
    if (value is String) {
      // Handle empty strings
      if (value.trim().isEmpty) return 0;
      
      // Try parsing as integer
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0 : parsed;
      
      // Try parsing as double then convert to int
      final parsedDouble = double.tryParse(value.trim());
      if (parsedDouble != null) return parsedDouble < 0 ? 0 : parsedDouble.round();
    }
    
    print('⚠️ Warning: Could not parse count value: $value (type: ${value.runtimeType})');
    return 0;
  }

  // 🔧 HELPER: Safely parse string lists (PostgreSQL arrays and JSON arrays)
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    // Handle List<dynamic>
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    // Handle String (could be JSON array or PostgreSQL array format)
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // Handle PostgreSQL array format: {item1,item2,item3} or {"item1","item2","item3"}
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        // Split by comma and clean up each item
        return content
            .split(',')
            .map((item) {
              final cleaned = item.trim();
              // Remove surrounding quotes if present
              if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                return cleaned.substring(1, cleaned.length - 1);
              }
              return cleaned;
            })
            .where((s) => s.isNotEmpty)
            .map((s) {
              // Unescape PostgreSQL escapes
              return s
                  .replaceAll(r'\"', '"')
                  .replaceAll(r'\\', r'\');
            })
            .toList();
      }
      
      // Handle JSON array format: ["item1","item2","item3"]
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
      
      // Single item
      return [trimmed];
    }
    
    print('⚠️ Warning: Could not parse string list: $value (type: ${value.runtimeType})');
    return [];
  }

  // 🔧 HELPER: Parse timestamp (PostgreSQL RFC3339 strings and other formats)
  static String _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    
    // Handle String (RFC3339 from PostgreSQL)
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return DateTime.now().toIso8601String();
      
      try {
        // Validate and parse RFC3339/ISO8601 format
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse timestamp: $trimmed');
        return DateTime.now().toIso8601String();
      }
    }
    
    // Handle DateTime object
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    // Handle Unix timestamp (milliseconds)
    if (value is int) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse Unix timestamp: $value');
        return DateTime.now().toIso8601String();
      }
    }
    
    // Handle Unix timestamp (seconds)
    if (value is double) {
      try {
        final milliseconds = (value * 1000).round();
        final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        return dateTime.toIso8601String();
      } catch (e) {
        print('⚠️ Warning: Could not parse Unix timestamp: $value');
        return DateTime.now().toIso8601String();
      }
    }
    
    print('⚠️ Warning: Unknown timestamp format: $value (type: ${value.runtimeType})');
    return DateTime.now().toIso8601String();
  }

  // 🔧 NEW: Formatted price getter matching ChannelVideoModel
  /// Formats the price for display
  /// Rules: 
  /// - Up to 999,999: "KES 999,999"
  /// - 1,000,000+: "KES 1M", "KES 1.5M", etc.
  /// - Default (0): "KES 0"
  String get formattedPrice {
    if (price == 0) {
      return 'KES 0';
    }
    
    if (price < 1000000) {
      // Format with commas for thousands
      return 'KES ${price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      // Format in millions
      double millions = price / 1000000;
      if (millions == millions.toInt()) {
        // Whole number of millions
        return 'KES ${millions.toInt()}M';
      } else {
        // Decimal millions (e.g., 1.5M)
        return 'KES ${millions.toStringAsFixed(1)}M';
      }
    }
  }

  // 🆕 BOOST HELPER METHODS
  
  /// Returns true if video has any boost tier active
  bool get hasBoost => isBoosted && boostTier != 'none';
  
  /// Returns true if video has basic boost
  bool get hasBasicBoost => isBoosted && boostTier == 'basic';
  
  /// Returns true if video has standard boost
  bool get hasStandardBoost => isBoosted && boostTier == 'standard';
  
  /// Returns true if video has advanced boost
  bool get hasAdvancedBoost => isBoosted && boostTier == 'advanced';
  
  /// Returns boost tier display name
  String get boostTierDisplayName {
    switch (boostTier) {
      case 'basic':
        return 'Basic Boost';
      case 'standard':
        return 'Standard Boost';
      case 'advanced':
        return 'Advanced Boost';
      default:
        return 'No Boost';
    }
  }
  
  /// Returns boost tier view range
  String get boostViewRange {
    switch (boostTier) {
      case 'basic':
        return '1,713 - 10K views';
      case 'standard':
        return '17,138 - 100K views';
      case 'advanced':
        return '171,388 - 1M views';
      default:
        return 'No boost active';
    }
  }
  
  /// Returns boost tier price in KES
  int get boostPrice {
    switch (boostTier) {
      case 'basic':
        return 99;
      case 'standard':
        return 999;
      case 'advanced':
        return 9999;
      default:
        return 0;
    }
  }
  
  /// Returns formatted boost price
  String get formattedBoostPrice {
    if (boostPrice == 0) return 'KES 0';
    return 'KES ${boostPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
  
  /// Returns boost tier icon
  String get boostTierIcon {
    switch (boostTier) {
      case 'basic':
        return '⚡';
      case 'standard':
        return '🚀';
      case 'advanced':
        return '⭐';
      default:
        return '';
    }
  }
  
  /// Returns boost status text
  String get boostStatusText {
    if (!isBoosted || boostTier == 'none') {
      return 'Not Boosted';
    }
    
    String status = boostTierDisplayName;
    if (superBoost) {
      status += ' + Super Boost';
    }
    return status;
  }

  // 🔧 ENHANCED: Helper methods for display formatting
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

  // 🔧 NEW: Engagement calculation
  double get engagementRate {
    if (views == 0) return 0.0;
    final totalEngagement = likes + comments + shares;
    return (totalEngagement / views) * 100;
  }

  String get formattedEngagementRate {
    return '${engagementRate.toStringAsFixed(1)}%';
  }

  // 🆕 NEW: Verification status helpers
  /// Returns true if the video is verified
  bool get isVerifiedContent => isVerified;
  
  /// Returns verification status text for display
  String get verificationStatus => isVerified ? 'Verified' : 'Unverified';
  
  /// Returns verification badge emoji/symbol
  String get verificationBadge => isVerified ? '✓' : '';
  
  /// Returns verification badge with text
  String get verificationBadgeText => isVerified ? '✓ Verified' : '';

  // 🔧 NEW: Content type helpers
  bool get isVideoContent => !isMultipleImages && videoUrl.isNotEmpty;
  bool get isImageContent => isMultipleImages && imageUrls.isNotEmpty;
  bool get hasValidContent => isVideoContent || isImageContent;

  /// Returns true if this is premium content (verified and has a price)
  bool get isPremiumContent => isVerified && price > 0;
  
  /// Returns true if this is verified free content
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

  /// Returns content quality tier based on verification, featured status, boost, and engagement
  String get contentTier {
    if (isVerified && isFeatured && hasAdvancedBoost) return 'Premium++';
    if (isVerified && isFeatured) return 'Premium+';
    if (isVerified && hasBoost) return 'Premium Boosted';
    if (isVerified) return 'Premium';
    if (isFeatured) return 'Featured';
    if (hasBoost) return 'Boosted';
    if (engagementRate > 5.0) return 'Popular';
    return 'Standard';
  }

  // 🔧 NEW: Time helpers
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

  // 🔧 ENHANCED: toJson method with boost fields
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'price': price,
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isVerified': isVerified,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isBoosted': isBoosted,           // 🆕 Include boost fields
      'boostTier': boostTier,           // 🆕
      'superBoost': superBoost,         // 🆕
      'isLiked': isLiked,
      'isFollowing': isFollowing,
    };
  }

  // 🔧 NEW: copyWith method for state updates with boost fields
  VideoModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    double? price,
    int? views,
    int? likes,
    int? comments,
    int? shares,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    bool? isVerified,
    bool? isMultipleImages,
    List<String>? imageUrls,
    String? createdAt,
    String? updatedAt,
    bool? isBoosted,          // 🆕 Add boost fields to copyWith
    String? boostTier,        // 🆕
    bool? superBoost,         // 🆕
    bool? isLiked,
    bool? isFollowing,
  }) {
    return VideoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      price: price ?? this.price,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBoosted: isBoosted ?? this.isBoosted,         // 🆕
      boostTier: boostTier ?? this.boostTier,         // 🆕
      superBoost: superBoost ?? this.superBoost,      // 🆕
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  // 🔧 NEW: Update counts (for real-time updates)
  VideoModel updateCounts({
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

  // 🔧 NEW: Toggle like status
  VideoModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🆕 NEW: Toggle verification status
  VideoModel toggleVerification() {
    return copyWith(
      isVerified: !isVerified,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🆕 NEW: Set verification status
  VideoModel setVerified(bool verified) {
    return copyWith(
      isVerified: verified,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🆕 NEW: Set boost status
  VideoModel setBoost({
    required bool isBoosted,
    required String boostTier,
    bool? superBoost,
  }) {
    return copyWith(
      isBoosted: isBoosted,
      boostTier: boostTier,
      superBoost: superBoost ?? this.superBoost,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🆕 NEW: Activate boost
  VideoModel activateBoost(String tier) {
    return copyWith(
      isBoosted: true,
      boostTier: tier,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🆕 NEW: Deactivate boost
  VideoModel deactivateBoost() {
    return copyWith(
      isBoosted: false,
      boostTier: 'none',
      superBoost: false,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🔧 NEW: Increment view count
  VideoModel incrementViews() {
    return copyWith(
      views: views + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🔧 NEW: Increment share count
  VideoModel incrementShares() {
    return copyWith(
      shares: shares + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // 🔧 NEW: Validation methods
  bool get isValid {
    return id.isNotEmpty && 
           userId.isNotEmpty && 
           userName.isNotEmpty && 
           caption.isNotEmpty && 
           hasValidContent;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (userId.isEmpty) errors.add('User ID is required');
    if (userName.isEmpty) errors.add('User name is required');
    if (caption.isEmpty) errors.add('Caption is required');
    if (!hasValidContent) errors.add('Valid video or image content is required');
    
    if (isImageContent && imageUrls.isEmpty) {
      errors.add('Image URLs are required for image posts');
    }
    
    if (isVideoContent && videoUrl.isEmpty) {
      errors.add('Video URL is required for video posts');
    }
    
    return errors;
  }

  // 🔧 NEW: Search helpers
  bool containsQuery(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    
    return caption.toLowerCase().contains(searchQuery) ||
           userName.toLowerCase().contains(searchQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(searchQuery));
  }

  bool hasTag(String tag) {
    return tags.any((t) => t.toLowerCase() == tag.toLowerCase());
  }

  // 🔧 DEBUGGING: toString method
  @override
  String toString() {
    return 'VideoModel(id: $id, caption: "${caption.length > 30 ? "${caption.substring(0, 30)}..." : caption}", views: $views, likes: $likes, comments: $comments, shares: $shares, price: $formattedPrice, verified: $isVerified, boosted: $isBoosted, boostTier: $boostTier, user: $userName)';
  }

  // 🔧 DEBUGGING: Detailed debug string
  String toDebugString() {
    return '''
VideoModel {
  id: $id
  userId: $userId
  userName: $userName
  caption: $caption
  price: $formattedPrice
  views: $views
  likes: $likes
  comments: $comments
  shares: $shares
  tags: $tags
  isActive: $isActive
  isFeatured: $isFeatured
  isVerified: $isVerified ✓
  isMultipleImages: $isMultipleImages
  imageUrls: $imageUrls
  videoUrl: $videoUrl
  thumbnailUrl: $thumbnailUrl
  createdAt: $createdAt
  updatedAt: $updatedAt
  isBoosted: $isBoosted 🚀
  boostTier: $boostTier
  superBoost: $superBoost
  isLiked: $isLiked
  isFollowing: $isFollowing
  engagementRate: ${engagementRate.toStringAsFixed(2)}%
  contentTier: $contentTier
  verificationStatus: $verificationStatus
  boostStatus: $boostStatusText
  isValid: $isValid
}''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 🔧 NEW: Extensions for additional functionality
extension VideoModelList on List<VideoModel> {
  List<VideoModel> get activeVideos => where((video) => video.isActive).toList();
  List<VideoModel> get featuredVideos => where((video) => video.isFeatured).toList();
  List<VideoModel> get verifiedVideos => where((video) => video.isVerified).toList();
  List<VideoModel> get unverifiedVideos => where((video) => !video.isVerified).toList();
  List<VideoModel> get premiumVideos => where((video) => video.isPremiumContent).toList();
  List<VideoModel> get verifiedFreeVideos => where((video) => video.isVerifiedFreeContent).toList();
  List<VideoModel> get imageVideos => where((video) => video.isImageContent).toList();
  List<VideoModel> get videoContent => where((video) => video.isVideoContent).toList();
  
  // 🆕 NEW: Boost filtering
  List<VideoModel> get boostedVideos => where((video) => video.isBoosted).toList();
  List<VideoModel> get unboostedVideos => where((video) => !video.isBoosted).toList();
  List<VideoModel> get basicBoostedVideos => where((video) => video.hasBasicBoost).toList();
  List<VideoModel> get standardBoostedVideos => where((video) => video.hasStandardBoost).toList();
  List<VideoModel> get advancedBoostedVideos => where((video) => video.hasAdvancedBoost).toList();
  List<VideoModel> get superBoostedVideos => where((video) => video.superBoost).toList();
  
  List<VideoModel> sortByViews({bool descending = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) => descending ? b.views.compareTo(a.views) : a.views.compareTo(b.views));
    return sorted;
  }
  
  List<VideoModel> sortByLikes({bool descending = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) => descending ? b.likes.compareTo(a.likes) : a.likes.compareTo(b.likes));
    return sorted;
  }
  
  List<VideoModel> sortByPrice({bool descending = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) => descending ? b.price.compareTo(a.price) : a.price.compareTo(b.price));
    return sorted;
  }
  
  List<VideoModel> sortByEngagement({bool descending = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.engagementRate.compareTo(a.engagementRate) 
        : a.engagementRate.compareTo(b.engagementRate));
    return sorted;
  }
  
  List<VideoModel> sortByDate({bool descending = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
        : a.createdAtDateTime.compareTo(b.createdAtDateTime));
    return sorted;
  }

  List<VideoModel> sortByVerification({bool verifiedFirst = true}) {
    final sorted = List<VideoModel>.from(this);
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

  // 🆕 NEW: Sort by boost status
  List<VideoModel> sortByBoost({bool boostedFirst = true}) {
    final sorted = List<VideoModel>.from(this);
    sorted.sort((a, b) {
      if (boostedFirst) {
        if (a.isBoosted && !b.isBoosted) return -1;
        if (!a.isBoosted && b.isBoosted) return 1;
        // If both boosted, sort by tier
        if (a.isBoosted && b.isBoosted) {
          final tierOrder = {'advanced': 0, 'standard': 1, 'basic': 2, 'none': 3};
          final aTier = tierOrder[a.boostTier] ?? 4;
          final bTier = tierOrder[b.boostTier] ?? 4;
          return aTier.compareTo(bTier);
        }
        return 0;
      } else {
        if (!a.isBoosted && b.isBoosted) return -1;
        if (a.isBoosted && !b.isBoosted) return 1;
        return 0;
      }
    });
    return sorted;
  }

  List<VideoModel> sortByContentTier() {
    final sorted = List<VideoModel>.from(this);
    final tierOrder = {
      'Premium++': 0, 
      'Premium+': 1, 
      'Premium Boosted': 2,
      'Premium': 3, 
      'Featured': 4,
      'Boosted': 5,
      'Popular': 6, 
      'Standard': 7
    };
    
    sorted.sort((a, b) {
      final aTier = tierOrder[a.contentTier] ?? 8;
      final bTier = tierOrder[b.contentTier] ?? 8;
      return aTier.compareTo(bTier);
    });
    return sorted;
  }
  
  List<VideoModel> filterByUser(String userId) {
    return where((video) => video.userId == userId).toList();
  }
  
  List<VideoModel> filterByTag(String tag) {
    return where((video) => video.hasTag(tag)).toList();
  }
  
  List<VideoModel> filterByPriceRange(double minPrice, double maxPrice) {
    return where((video) => video.price >= minPrice && video.price <= maxPrice).toList();
  }

  List<VideoModel> filterByVerification(bool isVerified) {
    return where((video) => video.isVerified == isVerified).toList();
  }

  // 🆕 NEW: Filter by boost tier
  List<VideoModel> filterByBoostTier(String tier) {
    return where((video) => video.boostTier == tier).toList();
  }

  List<VideoModel> filterByContentTier(String tier) {
    return where((video) => video.contentTier == tier).toList();
  }

  List<VideoModel> get premiumContent => where((video) => video.isPremiumContent).toList();

  List<VideoModel> get freeVerifiedContent => where((video) => video.isVerifiedFreeContent).toList();
  
  List<VideoModel> search(String query) {
    return where((video) => video.containsQuery(query)).toList();
  }
  
  int get totalViews => fold<int>(0, (sum, video) => sum + video.views);
  int get totalLikes => fold<int>(0, (sum, video) => sum + video.likes);
  int get totalComments => fold<int>(0, (sum, video) => sum + video.comments);
  int get totalShares => fold<int>(0, (sum, video) => sum + video.shares);
  double get totalPrice => fold<double>(0.0, (sum, video) => sum + video.price);

  int get verifiedCount => where((video) => video.isVerified).length;
  int get unverifiedCount => where((video) => !video.isVerified).length;
  double get verificationPercentage {
    if (isEmpty) return 0.0;
    return (verifiedCount / length) * 100;
  }

  // 🆕 NEW: Boost statistics
  int get boostedCount => where((video) => video.isBoosted).length;
  int get unboostedCount => where((video) => !video.isBoosted).length;
  double get boostPercentage {
    if (isEmpty) return 0.0;
    return (boostedCount / length) * 100;
  }

  int get basicBoostCount => where((video) => video.hasBasicBoost).length;
  int get standardBoostCount => where((video) => video.hasStandardBoost).length;
  int get advancedBoostCount => where((video) => video.hasAdvancedBoost).length;
  int get superBoostCount => where((video) => video.superBoost).length;

  Map<String, int> get boostTierBreakdown {
    final breakdown = <String, int>{};
    for (final video in this) {
      final tier = video.boostTier;
      breakdown[tier] = (breakdown[tier] ?? 0) + 1;
    }
    return breakdown;
  }

  Map<String, int> get contentTierBreakdown {
    final breakdown = <String, int>{};
    for (final video in this) {
      final tier = video.contentTier;
      breakdown[tier] = (breakdown[tier] ?? 0) + 1;
    }
    return breakdown;
  }

  int get premiumContentCount => where((video) => video.isPremiumContent).length;
  double get premiumContentPercentage {
    if (isEmpty) return 0.0;
    return (premiumContentCount / length) * 100;
  }

  double get averageEngagementRate {
    if (isEmpty) return 0.0;
    final totalEngagement = fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / length;
  }
  
  double get averagePrice {
    if (isEmpty) return 0.0;
    return totalPrice / length;
  }

  double get verifiedAverageEngagement {
    final verified = verifiedVideos;
    if (verified.isEmpty) return 0.0;
    final totalEngagement = verified.fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / verified.length;
  }

  double get unverifiedAverageEngagement {
    final unverified = unverifiedVideos;
    if (unverified.isEmpty) return 0.0;
    final totalEngagement = unverified.fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / unverified.length;
  }

  // 🆕 NEW: Boost engagement comparison
  double get boostedAverageEngagement {
    final boosted = boostedVideos;
    if (boosted.isEmpty) return 0.0;
    final totalEngagement = boosted.fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / boosted.length;
  }

  double get unboostedAverageEngagement {
    final unboosted = unboostedVideos;
    if (unboosted.isEmpty) return 0.0;
    final totalEngagement = unboosted.fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / unboosted.length;
  }

  List<VideoModel> get topVerifiedVideos => verifiedVideos.sortByEngagement().take(10).toList();
  List<VideoModel> get topPremiumVideos => premiumVideos.sortByEngagement().take(10).toList();
  
  // 🆕 NEW: Top boosted videos
  List<VideoModel> get topBoostedVideos => boostedVideos.sortByEngagement().take(10).toList();
  
  double get overallQualityScore {
    if (isEmpty) return 0.0;
    
    double score = 0.0;
    for (final video in this) {
      double videoScore = 0.0;
      
      // Base engagement score (0-40 points)
      videoScore += (video.engagementRate * 4).clamp(0.0, 40.0);
      
      // Verification bonus (0-20 points)
      if (video.isVerified) videoScore += 20;
      
      // Featured bonus (0-15 points)
      if (video.isFeatured) videoScore += 15;
      
      // Boost bonus (0-15 points)
      if (video.hasAdvancedBoost) {
        videoScore += 15;
      } else if (video.hasStandardBoost) {
        videoScore += 10;
      } else if (video.hasBasicBoost) {
        videoScore += 5;
      }
      
      // Premium content bonus (0-10 points)
      if (video.isPremiumContent) videoScore += 10;
      
      // Activity bonus (0-5 points)
      if (video.isActive) videoScore += 5;
      
      score += videoScore;
    }
    
    return score / length; // Average quality score per video (0-100+)
  }
}