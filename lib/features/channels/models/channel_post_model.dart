// lib/features/channels/models/channel_post_model.dart

/// Post content type enum
enum PostContentType {
  text,
  image,
  video,
  textImage,
  textVideo,
}

/// Channel post model with premium features
class ChannelPost {
  final String id;
  final String channelId;
  final String? channelName;
  final String? channelAvatarUrl;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final PostContentType contentType;

  // Content
  final String? text;
  final String? mediaUrl; // Single video or multiple images (comma-separated)
  final List<String>? imageUrls; // Parsed from mediaUrl if multiple images
  final String? thumbnailUrl;

  // Premium features
  final bool isPremium;
  final int? priceCoins; // Cost to unlock (if premium)
  final int? previewDuration; // Seconds of free preview for videos
  final int? fullDuration; // Total video duration in seconds
  final int? fileSize; // File size in bytes (up to 2GB for premium)

  // Engagement
  final int views;
  final int likes;
  final int commentsCount;
  final int unlocksCount; // How many users paid (premium only)
  final int sharesCount;

  // Settings
  final bool commentsEnabled;
  final bool isPinned;

  // User interaction state
  final bool? hasLiked;
  final bool? hasUnlocked; // Has current user unlocked this premium content
  final bool? hasViewed;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChannelPost({
    required this.id,
    required this.channelId,
    this.channelName,
    this.channelAvatarUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.contentType,
    this.text,
    this.mediaUrl,
    this.imageUrls,
    this.thumbnailUrl,
    this.isPremium = false,
    this.priceCoins,
    this.previewDuration,
    this.fullDuration,
    this.fileSize,
    this.views = 0,
    this.likes = 0,
    this.commentsCount = 0,
    this.unlocksCount = 0,
    this.sharesCount = 0,
    this.commentsEnabled = true,
    this.isPinned = false,
    this.hasLiked,
    this.hasUnlocked,
    this.hasViewed,
    this.createdAt,
    this.updatedAt,
  });

  factory ChannelPost.fromJson(Map<String, dynamic> json) {
    return ChannelPost(
      id: json['id'] as String,
      channelId: json['channelId'] as String? ?? json['channel_id'] as String,
      channelName: json['channelName'] as String? ?? json['channel_name'] as String?,
      channelAvatarUrl: json['channelAvatarUrl'] as String? ?? json['channel_avatar_url'] as String?,
      authorId: json['authorId'] as String? ?? json['author_id'] as String,
      authorName: json['authorName'] as String? ?? json['author_name'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? json['author_avatar_url'] as String?,
      contentType: _postContentTypeFromString(json['contentType'] as String? ?? json['content_type'] as String?),
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String? ?? json['media_url'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
                 (json['image_urls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      isPremium: json['isPremium'] as bool? ?? json['is_premium'] as bool? ?? false,
      priceCoins: json['priceCoins'] as int? ?? json['price_coins'] as int?,
      previewDuration: json['previewDuration'] as int? ?? json['preview_duration'] as int?,
      fullDuration: json['fullDuration'] as int? ?? json['full_duration'] as int?,
      fileSize: json['fileSize'] as int? ?? json['file_size'] as int?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? json['comments_count'] as int? ?? 0,
      unlocksCount: json['unlocksCount'] as int? ?? json['unlocks_count'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? json['shares_count'] as int? ?? 0,
      commentsEnabled: json['commentsEnabled'] as bool? ?? json['comments_enabled'] as bool? ?? true,
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      hasLiked: json['hasLiked'] as bool? ?? json['has_liked'] as bool?,
      hasUnlocked: json['hasUnlocked'] as bool? ?? json['has_unlocked'] as bool?,
      hasViewed: json['hasViewed'] as bool? ?? json['has_viewed'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) :
                 (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) :
                 (json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'channelName': channelName,
      'channelAvatarUrl': channelAvatarUrl,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'contentType': _postContentTypeToString(contentType),
      'text': text,
      'mediaUrl': mediaUrl,
      'imageUrls': imageUrls,
      'thumbnailUrl': thumbnailUrl,
      'isPremium': isPremium,
      'priceCoins': priceCoins,
      'previewDuration': previewDuration,
      'fullDuration': fullDuration,
      'fileSize': fileSize,
      'views': views,
      'likes': likes,
      'commentsCount': commentsCount,
      'unlocksCount': unlocksCount,
      'sharesCount': sharesCount,
      'commentsEnabled': commentsEnabled,
      'isPinned': isPinned,
      'hasLiked': hasLiked,
      'hasUnlocked': hasUnlocked,
      'hasViewed': hasViewed,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  ChannelPost copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelAvatarUrl,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    PostContentType? contentType,
    String? text,
    String? mediaUrl,
    List<String>? imageUrls,
    String? thumbnailUrl,
    bool? isPremium,
    int? priceCoins,
    int? previewDuration,
    int? fullDuration,
    int? fileSize,
    int? views,
    int? likes,
    int? commentsCount,
    int? unlocksCount,
    int? sharesCount,
    bool? commentsEnabled,
    bool? isPinned,
    bool? hasLiked,
    bool? hasUnlocked,
    bool? hasViewed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChannelPost(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      contentType: contentType ?? this.contentType,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPremium: isPremium ?? this.isPremium,
      priceCoins: priceCoins ?? this.priceCoins,
      previewDuration: previewDuration ?? this.previewDuration,
      fullDuration: fullDuration ?? this.fullDuration,
      fileSize: fileSize ?? this.fileSize,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      unlocksCount: unlocksCount ?? this.unlocksCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      isPinned: isPinned ?? this.isPinned,
      hasLiked: hasLiked ?? this.hasLiked,
      hasUnlocked: hasUnlocked ?? this.hasUnlocked,
      hasViewed: hasViewed ?? this.hasViewed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Extension for post helpers
extension ChannelPostExtension on ChannelPost {
  /// Alias for sharesCount (for compatibility)
  int get shares => sharesCount;

  /// Alias for formattedFileSize (for compatibility)
  String get fileSizeFormatted => formattedFileSize;

  /// Get time ago string
  String get timeAgo {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Check if post has media
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Check if post is video
  bool get isVideo =>
      contentType == PostContentType.video ||
      contentType == PostContentType.textVideo;

  /// Check if post has images
  bool get hasImages =>
      contentType == PostContentType.image ||
      contentType == PostContentType.textImage;

  /// Check if user needs to pay to access full content
  bool get requiresPayment => isPremium && hasUnlocked != true;

  /// Get formatted file size
  String get formattedFileSize {
    if (fileSize == null) return '';

    final sizeInMB = fileSize! / (1024 * 1024);
    if (sizeInMB < 1) {
      final sizeInKB = fileSize! / 1024;
      return '${sizeInKB.toStringAsFixed(1)} KB';
    } else if (sizeInMB < 1024) {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    } else {
      final sizeInGB = sizeInMB / 1024;
      return '${sizeInGB.toStringAsFixed(2)} GB';
    }
  }

  /// Get formatted duration
  String get formattedDuration {
    if (fullDuration == null) return '';
    return _formatDuration(fullDuration!);
  }

  /// Get formatted preview duration
  String get formattedPreviewDuration {
    if (previewDuration == null) return '';
    return _formatDuration(previewDuration!);
  }

  /// Format duration helper
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// Check if preview is available
  bool get hasPreview => isPremium && previewDuration != null && previewDuration! > 0;

  /// Get preview percentage
  double get previewPercentage {
    if (!hasPreview || fullDuration == null || fullDuration == 0) return 0;
    return (previewDuration! / fullDuration!) * 100;
  }
}

/// Post unlock record (who paid for premium content)
class ChannelUnlock {
  final String id;
  final String postId;
  final String userId;
  final int coinsPaid;
  final int creatorEarned; // 80% of coinsPaid
  final int platformFee; // 20% of coinsPaid
  final DateTime? unlockedAt;

  const ChannelUnlock({
    required this.id,
    required this.postId,
    required this.userId,
    required this.coinsPaid,
    required this.creatorEarned,
    required this.platformFee,
    this.unlockedAt,
  });

  factory ChannelUnlock.fromJson(Map<String, dynamic> json) {
    return ChannelUnlock(
      id: json['id'] as String,
      postId: json['postId'] as String? ?? json['post_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      coinsPaid: json['coinsPaid'] as int? ?? json['coins_paid'] as int,
      creatorEarned: json['creatorEarned'] as int? ?? json['creator_earned'] as int,
      platformFee: json['platformFee'] as int? ?? json['platform_fee'] as int,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt'] as String) :
                  (json['unlocked_at'] != null ? DateTime.parse(json['unlocked_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'coinsPaid': coinsPaid,
      'creatorEarned': creatorEarned,
      'platformFee': platformFee,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

// Helper functions for enum conversion
PostContentType _postContentTypeFromString(String? value) {
  switch (value) {
    case 'text':
      return PostContentType.text;
    case 'image':
      return PostContentType.image;
    case 'video':
      return PostContentType.video;
    case 'text_image':
    case 'textImage':
      return PostContentType.textImage;
    case 'text_video':
    case 'textVideo':
      return PostContentType.textVideo;
    default:
      return PostContentType.text;
  }
}

String _postContentTypeToString(PostContentType type) {
  switch (type) {
    case PostContentType.text:
      return 'text';
    case PostContentType.image:
      return 'image';
    case PostContentType.video:
      return 'video';
    case PostContentType.textImage:
      return 'text_image';
    case PostContentType.textVideo:
      return 'text_video';
  }
}
