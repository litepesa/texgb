// ===============================
// Channel Model
// One user can create ONE channel (WeChat Channels style)
// Backend-ready with complete JSON serialization
// ===============================

class ChannelModel {
  final String id;
  final String userId;              // Owner of this channel
  final String channelName;         // Channel's display name (NOT user's personal name)
  final String channelAvatar;       // Channel's avatar/logo (NOT user's personal avatar)
  final String bio;                 // Channel description
  final bool isVerified;            // Channel verification status
  final int followersCount;         // Number of followers
  final int videosCount;            // Number of videos posted
  final int totalViews;             // Total views across all videos
  final int totalLikes;             // Total likes across all videos
  final String category;            // Channel category (e.g., "Tech", "Fashion", "Food")
  final List<String> tags;          // Channel tags
  final String? websiteUrl;         // Optional website link
  final String? contactEmail;       // Optional contact email
  final bool isActive;              // Is channel active
  final bool isFeatured;            // Featured channel status
  final DateTime createdAt;
  final DateTime updatedAt;

  // Runtime fields (not from backend)
  final bool isFollowing;           // Is current user following this channel

  const ChannelModel({
    required this.id,
    required this.userId,
    required this.channelName,
    required this.channelAvatar,
    required this.bio,
    required this.isVerified,
    required this.followersCount,
    required this.videosCount,
    required this.totalViews,
    required this.totalLikes,
    required this.category,
    required this.tags,
    this.websiteUrl,
    this.contactEmail,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.isFollowing = false,
  });

  // From JSON (backend response)
  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      channelName: json['channelName'] as String? ?? json['channel_name'] as String? ?? '',
      channelAvatar: json['channelAvatar'] as String? ?? json['channel_avatar'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      followersCount: _parseInt(json['followersCount'] ?? json['followers_count'] ?? 0),
      videosCount: _parseInt(json['videosCount'] ?? json['videos_count'] ?? 0),
      totalViews: _parseInt(json['totalViews'] ?? json['total_views'] ?? 0),
      totalLikes: _parseInt(json['totalLikes'] ?? json['total_likes'] ?? 0),
      category: json['category'] as String? ?? 'General',
      tags: _parseStringList(json['tags']),
      websiteUrl: json['websiteUrl'] as String? ?? json['website_url'] as String?,
      contactEmail: json['contactEmail'] as String? ?? json['contact_email'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? json['is_featured'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      isFollowing: json['isFollowing'] as bool? ?? json['is_following'] as bool? ?? false,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'bio': bio,
      'isVerified': isVerified,
      'followersCount': followersCount,
      'videosCount': videosCount,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'category': category,
      'tags': tags,
      'websiteUrl': websiteUrl,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFollowing': isFollowing,
    };
  }

  // CopyWith for state updates
  ChannelModel copyWith({
    String? id,
    String? userId,
    String? channelName,
    String? channelAvatar,
    String? bio,
    bool? isVerified,
    int? followersCount,
    int? videosCount,
    int? totalViews,
    int? totalLikes,
    String? category,
    List<String>? tags,
    String? websiteUrl,
    String? contactEmail,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFollowing,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      channelName: channelName ?? this.channelName,
      channelAvatar: channelAvatar ?? this.channelAvatar,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      videosCount: videosCount ?? this.videosCount,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  // Helper: Parse int safely
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper: Parse string list
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  // Helper: Parse DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Display helpers
  String get formattedFollowers => _formatCount(followersCount);
  String get formattedVideos => _formatCount(videosCount);
  String get formattedViews => _formatCount(totalViews);
  String get formattedLikes => _formatCount(totalLikes);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Engagement rate
  double get engagementRate {
    if (totalViews == 0) return 0.0;
    return (totalLikes / totalViews) * 100;
  }

  String get formattedEngagementRate => '${engagementRate.toStringAsFixed(1)}%';

  // Validation
  bool get isValid {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        channelName.isNotEmpty &&
        channelAvatar.isNotEmpty;
  }

  @override
  String toString() {
    return 'ChannelModel(id: $id, channelName: $channelName, followers: $followersCount, videos: $videosCount, verified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChannelModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// Create Channel Request
// ===============================

class CreateChannelRequest {
  final String channelName;
  final String channelAvatar;
  final String bio;
  final String category;
  final List<String> tags;
  final String? websiteUrl;
  final String? contactEmail;

  const CreateChannelRequest({
    required this.channelName,
    required this.channelAvatar,
    required this.bio,
    required this.category,
    required this.tags,
    this.websiteUrl,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'bio': bio,
      'category': category,
      'tags': tags,
      'websiteUrl': websiteUrl,
      'contactEmail': contactEmail,
    };
  }
}

// ===============================
// Update Channel Request
// ===============================

class UpdateChannelRequest {
  final String? channelName;
  final String? channelAvatar;
  final String? bio;
  final String? category;
  final List<String>? tags;
  final String? websiteUrl;
  final String? contactEmail;

  const UpdateChannelRequest({
    this.channelName,
    this.channelAvatar,
    this.bio,
    this.category,
    this.tags,
    this.websiteUrl,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (channelName != null) map['channelName'] = channelName;
    if (channelAvatar != null) map['channelAvatar'] = channelAvatar;
    if (bio != null) map['bio'] = bio;
    if (category != null) map['category'] = category;
    if (tags != null) map['tags'] = tags;
    if (websiteUrl != null) map['websiteUrl'] = websiteUrl;
    if (contactEmail != null) map['contactEmail'] = contactEmail;
    return map;
  }
}
