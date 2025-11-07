// ===============================
// Video Model - REFACTORED for Channels
// Videos belong to channels (NOT users directly)
// Backend-ready with complete JSON serialization
// ===============================

import 'dart:convert';

class VideoModel {
  final String id;

  // ✅ CHANNEL FIELDS (replaced userId/userName/userImage)
  final String channelId;           // Reference to channel (NOT userId!)
  final String channelName;         // Channel's name (NOT userName!)
  final String channelAvatar;       // Channel's avatar (NOT userImage!)
  final bool isChannelVerified;     // Channel verification status

  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final double price; // Price field for business posts

  // Engagement metrics
  final int views;
  final int likes;
  final int comments;
  final int shares;

  final List<String> tags;
  final bool isActive;
  final bool isFeatured;
  final bool isMultipleImages;
  final List<String> imageUrls;
  final String createdAt;
  final String updatedAt;

  // Boost fields
  final bool isBoosted;
  final String boostTier;
  final bool superBoost;

  // Runtime fields (not stored in DB)
  final bool isLiked;
  final bool isFollowing;          // Is following the CHANNEL (not user)

  const VideoModel({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelAvatar,
    this.isChannelVerified = false,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    this.price = 0.0,
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
    this.isBoosted = false,
    this.boostTier = 'none',
    this.superBoost = false,
    this.isLiked = false,
    this.isFollowing = false,
  });

  // From JSON (backend response)
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    try {
      return VideoModel(
        id: _parseString(json['id']),

        // ✅ Parse CHANNEL fields
        channelId: _parseString(json['channelId'] ?? json['channel_id']),
        channelName: _parseString(json['channelName'] ?? json['channel_name']),
        channelAvatar: _parseString(json['channelAvatar'] ?? json['channel_avatar']),
        isChannelVerified: _parseBool(json['isChannelVerified'] ?? json['is_channel_verified'] ?? false),

        videoUrl: _parseString(json['videoUrl'] ?? json['video_url']),
        thumbnailUrl: _parseString(json['thumbnailUrl'] ?? json['thumbnail_url']),
        caption: _parseString(json['caption']),
        price: _parsePrice(json['price']),

        views: _parseCount(json['views'] ?? json['viewsCount'] ?? json['views_count'] ?? 0),
        likes: _parseCount(json['likes'] ?? json['likesCount'] ?? json['likes_count'] ?? 0),
        comments: _parseCount(json['comments'] ?? json['commentsCount'] ?? json['comments_count'] ?? 0),
        shares: _parseCount(json['shares'] ?? json['sharesCount'] ?? json['shares_count'] ?? 0),

        tags: _parseStringList(json['tags']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isFeatured: _parseBool(json['isFeatured'] ?? json['is_featured'] ?? false),
        isMultipleImages: _parseBool(json['isMultipleImages'] ?? json['is_multiple_images'] ?? false),
        imageUrls: _parseStringList(json['imageUrls'] ?? json['image_urls']),
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),

        isBoosted: _parseBool(json['isBoosted'] ?? json['is_boosted'] ?? false),
        boostTier: _parseBoostTier(json['boostTier'] ?? json['boost_tier']),
        superBoost: _parseBool(json['superBoost'] ?? json['super_boost'] ?? false),

        isLiked: _parseBool(json['isLiked'] ?? false),
        isFollowing: _parseBool(json['isFollowing'] ?? false),
      );
    } catch (e) {
      print('❌ Error parsing VideoModel from JSON: $e');
      print('📄 JSON data: $json');

      return VideoModel(
        id: _parseString(json['id'] ?? ''),
        channelId: _parseString(json['channelId'] ?? json['channel_id'] ?? ''),
        channelName: _parseString(json['channelName'] ?? json['channel_name'] ?? 'Unknown'),
        channelAvatar: '',
        isChannelVerified: false,
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

  // Helper methods (same as before)
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

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value < 0 ? 0.0 : value;
    if (value is int) return value < 0 ? 0.0 : value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed < 0 ? 0.0 : parsed;
    }
    return 0.0;
  }

  static String _parseBoostTier(dynamic value) {
    if (value == null) return 'none';
    final tierStr = value.toString().toLowerCase().trim();
    const validTiers = ['none', 'basic', 'standard', 'advanced'];
    if (validTiers.contains(tierStr)) return tierStr;
    return 'none';
  }

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
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        return content.split(',').map((item) {
          final cleaned = item.trim();
          if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
            return cleaned.substring(1, cleaned.length - 1);
          }
          return cleaned;
        }).where((s) => s.isNotEmpty).toList();
      }
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
          }
        } catch (e) {
          // Ignore
        }
      }
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
    if (value is DateTime) return value.toIso8601String();
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

  // Formatted price getter
  String get formattedPrice {
    if (price == 0) return 'KES 0';
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

  // Boost helper methods
  bool get hasBoost => isBoosted && boostTier != 'none';
  bool get hasBasicBoost => isBoosted && boostTier == 'basic';
  bool get hasStandardBoost => isBoosted && boostTier == 'standard';
  bool get hasAdvancedBoost => isBoosted && boostTier == 'advanced';

  String get boostTierDisplayName {
    switch (boostTier) {
      case 'basic': return 'Basic Boost';
      case 'standard': return 'Standard Boost';
      case 'advanced': return 'Advanced Boost';
      default: return 'No Boost';
    }
  }

  // Display formatting
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

  String get formattedEngagementRate => '${engagementRate.toStringAsFixed(1)}%';

  // Content type helpers
  bool get isVideoContent => !isMultipleImages && videoUrl.isNotEmpty;
  bool get isImageContent => isMultipleImages && imageUrls.isNotEmpty;
  bool get hasValidContent => isVideoContent || isImageContent;
  bool get isPremiumContent => price > 0;

  String get displayUrl {
    if (isImageContent && imageUrls.isNotEmpty) return imageUrls.first;
    if (thumbnailUrl.isNotEmpty) return thumbnailUrl;
    return videoUrl;
  }

  // Time helpers
  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
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

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'isChannelVerified': isChannelVerified,
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
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isBoosted': isBoosted,
      'boostTier': boostTier,
      'superBoost': superBoost,
      'isLiked': isLiked,
      'isFollowing': isFollowing,
    };
  }

  // CopyWith method
  VideoModel copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelAvatar,
    bool? isChannelVerified,
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
    bool? isMultipleImages,
    List<String>? imageUrls,
    String? createdAt,
    String? updatedAt,
    bool? isBoosted,
    String? boostTier,
    bool? superBoost,
    bool? isLiked,
    bool? isFollowing,
  }) {
    return VideoModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelAvatar: channelAvatar ?? this.channelAvatar,
      isChannelVerified: isChannelVerified ?? this.isChannelVerified,
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
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isBoosted: isBoosted ?? this.isBoosted,
      boostTier: boostTier ?? this.boostTier,
      superBoost: superBoost ?? this.superBoost,
      isLiked: isLiked ?? this.isLiked,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  // Toggle like
  VideoModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
    );
  }

  // Increment views
  VideoModel incrementViews() {
    return copyWith(views: views + 1);
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, channel: $channelName, views: $views, likes: $likes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
