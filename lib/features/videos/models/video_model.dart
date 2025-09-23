// ===============================
// lib/features/videos/models/video_model.dart
// Complete Video Model for PostgreSQL Backend (100% Compatible)
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
  final double price; // NEW: Price field for business posts (matching ChannelVideoModel)
  
  // 🔧 CRITICAL FIX: Use correct field names that match backend database
  final int views;        // Backend: views_count -> Frontend: views
  final int likes;        // Backend: likes_count -> Frontend: likes  
  final int comments;     // Backend: comments_count -> Frontend: comments
  final int shares;       // Backend: shares_count -> Frontend: shares
  
  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final bool isMultipleImages;
  final List<String> imageUrls;
  final String createdAt; // RFC3339 string format from PostgreSQL
  final String updatedAt; // RFC3339 string format from PostgreSQL

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
    required this.isMultipleImages,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isLiked = false,
    this.isFollowing = false,
  });

  // 🔧 CRITICAL FIX: fromJson method with PostgreSQL-compatible field mapping
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
        price: _parsePrice(json['price']), // NEW: Parse price field
        
        // 🔧 CRITICAL FIX: Map backend field names to frontend names
        // Try multiple possible field name variations from your backend
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
        isMultipleImages: _parseBool(json['isMultipleImages'] ?? json['is_multiple_images'] ?? false),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
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
        price: 0.0, // Default price
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        tags: [],
        isActive: true,
        isFeatured: false,
        isMultipleImages: false,
        imageUrls: [],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
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

  // 🔧 NEW: Content type helpers
  bool get isVideoContent => !isMultipleImages && videoUrl.isNotEmpty;
  bool get isImageContent => isMultipleImages && imageUrls.isNotEmpty;
  bool get hasValidContent => isVideoContent || isImageContent;

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

  // 🔧 ENHANCED: toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'price': price, // Include price in JSON
      'views': views,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'tags': tags,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isLiked': isLiked,
      'isFollowing': isFollowing,
    };
  }

  // 🔧 NEW: copyWith method for state updates
  VideoModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    double? price, // Add price to copyWith
    int? views,
    int? likes,
    int? comments,
    int? shares,
    List<String>? tags,
    bool? isActive,
    bool? isFeatured,
    bool? isMultipleImages,
    List<String>? imageUrls,
    String? createdAt,
    String? updatedAt,
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
      price: price ?? this.price, // Include price in copyWith
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return 'VideoModel(id: $id, caption: "${caption.length > 30 ? "${caption.substring(0, 30)}..." : caption}", views: $views, likes: $likes, comments: $comments, shares: $shares, price: $formattedPrice, user: $userName)';
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
  isMultipleImages: $isMultipleImages
  imageUrls: $imageUrls
  videoUrl: $videoUrl
  thumbnailUrl: $thumbnailUrl
  createdAt: $createdAt
  updatedAt: $updatedAt
  isLiked: $isLiked
  isFollowing: $isFollowing
  engagementRate: ${engagementRate.toStringAsFixed(2)}%
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
  List<VideoModel> get imageVideos => where((video) => video.isImageContent).toList();
  List<VideoModel> get videoContent => where((video) => video.isVideoContent).toList();
  
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
  
  List<VideoModel> filterByUser(String userId) {
    return where((video) => video.userId == userId).toList();
  }
  
  List<VideoModel> filterByTag(String tag) {
    return where((video) => video.hasTag(tag)).toList();
  }
  
  List<VideoModel> filterByPriceRange(double minPrice, double maxPrice) {
    return where((video) => video.price >= minPrice && video.price <= maxPrice).toList();
  }
  
  List<VideoModel> search(String query) {
    return where((video) => video.containsQuery(query)).toList();
  }
  
  int get totalViews => fold<int>(0, (sum, video) => sum + video.views);
  int get totalLikes => fold<int>(0, (sum, video) => sum + video.likes);
  int get totalComments => fold<int>(0, (sum, video) => sum + video.comments);
  int get totalShares => fold<int>(0, (sum, video) => sum + video.shares);
  double get totalPrice => fold<double>(0.0, (sum, video) => sum + video.price);
  
  double get averageEngagementRate {
    if (isEmpty) return 0.0;
    final totalEngagement = fold<double>(0.0, (sum, video) => sum + video.engagementRate);
    return totalEngagement / length;
  }
  
  double get averagePrice {
    if (isEmpty) return 0.0;
    return totalPrice / length;
  }
}