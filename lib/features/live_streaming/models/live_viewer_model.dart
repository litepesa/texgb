// lib/features/live_streaming/models/live_viewer_model.dart

// Viewer status enum
enum ViewerStatus {
  watching,      // Currently watching
  idle,          // Connected but inactive (backgrounded app)
  disconnected;  // Left the stream

  String get displayName {
    switch (this) {
      case ViewerStatus.watching:
        return 'Watching';
      case ViewerStatus.idle:
        return 'Idle';
      case ViewerStatus.disconnected:
        return 'Left';
    }
  }
}

// Viewer tier/badge enum (for special viewers)
enum ViewerTier {
  regular,       // Regular viewer
  follower,      // Follows the host
  subscriber,    // Paid subscriber (future feature)
  moderator,     // Appointed moderator
  topGifter,     // Top gift sender in this stream
  vip;           // VIP status (future feature)

  String get displayName {
    switch (this) {
      case ViewerTier.regular:
        return 'Viewer';
      case ViewerTier.follower:
        return 'Follower';
      case ViewerTier.subscriber:
        return 'Subscriber';
      case ViewerTier.moderator:
        return 'Moderator';
      case ViewerTier.topGifter:
        return 'Top Gifter';
      case ViewerTier.vip:
        return 'VIP';
    }
  }

  String get emoji {
    switch (this) {
      case ViewerTier.regular:
        return '👤';
      case ViewerTier.follower:
        return '❤️';
      case ViewerTier.subscriber:
        return '⭐';
      case ViewerTier.moderator:
        return '🛡️';
      case ViewerTier.topGifter:
        return '💎';
      case ViewerTier.vip:
        return '👑';
    }
  }

  // Priority for sorting (higher = more important)
  int get priority {
    switch (this) {
      case ViewerTier.moderator:
        return 100;
      case ViewerTier.vip:
        return 90;
      case ViewerTier.topGifter:
        return 80;
      case ViewerTier.subscriber:
        return 70;
      case ViewerTier.follower:
        return 60;
      case ViewerTier.regular:
        return 0;
    }
  }
}

// Main Live Viewer Model
class LiveViewerModel {
  final String id;                    // Unique viewer session ID
  final String liveStreamId;
  final String userId;
  final String userName;
  final String userImage;
  final bool userIsVerified;
  
  // Viewer status
  final ViewerStatus status;
  final ViewerTier tier;
  
  // Session tracking
  final String joinedAt;              // When they joined this stream
  final String? leftAt;               // When they left (if disconnected)
  final String lastActiveAt;          // Last activity timestamp
  final int watchDurationSeconds;     // Total watch time in seconds
  
  // Engagement metrics
  final int messagesCount;            // Messages sent in chat
  final int giftsCount;               // Gifts sent in this stream
  final double totalGiftSpent;        // Total KES spent on gifts
  final int likesGiven;               // Likes given to chat messages
  
  // Network/connection info
  final String? connectionQuality;    // 'excellent', 'good', 'poor'
  final String? deviceType;           // 'mobile', 'tablet', 'desktop'
  final String? platform;             // 'android', 'ios', 'web'
  
  // Special entrance effects (for top gifters)
  final bool hasEntranceEffect;       // Show special animation on join
  final String? entranceEffectType;   // 'gold', 'diamond', 'vip'

  const LiveViewerModel({
    required this.id,
    required this.liveStreamId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.userIsVerified,
    required this.status,
    this.tier = ViewerTier.regular,
    required this.joinedAt,
    this.leftAt,
    required this.lastActiveAt,
    this.watchDurationSeconds = 0,
    this.messagesCount = 0,
    this.giftsCount = 0,
    this.totalGiftSpent = 0.0,
    this.likesGiven = 0,
    this.connectionQuality,
    this.deviceType,
    this.platform,
    this.hasEntranceEffect = false,
    this.entranceEffectType,
  });

  // Create new viewer session
  factory LiveViewerModel.create({
    required String liveStreamId,
    required String userId,
    required String userName,
    required String userImage,
    required bool userIsVerified,
    ViewerTier tier = ViewerTier.regular,
    String? deviceType,
    String? platform,
    bool hasEntranceEffect = false,
    String? entranceEffectType,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    
    return LiveViewerModel(
      id: '', // Will be set by backend
      liveStreamId: liveStreamId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      userIsVerified: userIsVerified,
      status: ViewerStatus.watching,
      tier: tier,
      joinedAt: now,
      lastActiveAt: now,
      deviceType: deviceType,
      platform: platform,
      hasEntranceEffect: hasEntranceEffect,
      entranceEffectType: entranceEffectType,
    );
  }

  // From JSON (backend response or WebSocket message)
  factory LiveViewerModel.fromJson(Map<String, dynamic> json) {
    return LiveViewerModel(
      id: json['id'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      userImage: json['userImage'] ?? json['user_image'] ?? '',
      userIsVerified: json['userIsVerified'] ?? json['user_is_verified'] ?? false,
      status: ViewerStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'watching'),
        orElse: () => ViewerStatus.watching,
      ),
      tier: ViewerTier.values.firstWhere(
        (e) => e.name == (json['tier'] ?? 'regular'),
        orElse: () => ViewerTier.regular,
      ),
      joinedAt: json['joinedAt'] ?? json['joined_at'] ?? '',
      leftAt: json['leftAt'] ?? json['left_at'],
      lastActiveAt: json['lastActiveAt'] ?? json['last_active_at'] ?? '',
      watchDurationSeconds: json['watchDurationSeconds'] ?? json['watch_duration_seconds'] ?? 0,
      messagesCount: json['messagesCount'] ?? json['messages_count'] ?? 0,
      giftsCount: json['giftsCount'] ?? json['gifts_count'] ?? 0,
      totalGiftSpent: (json['totalGiftSpent'] ?? json['total_gift_spent'] ?? 0).toDouble(),
      likesGiven: json['likesGiven'] ?? json['likes_given'] ?? 0,
      connectionQuality: json['connectionQuality'] ?? json['connection_quality'],
      deviceType: json['deviceType'] ?? json['device_type'],
      platform: json['platform'],
      hasEntranceEffect: json['hasEntranceEffect'] ?? json['has_entrance_effect'] ?? false,
      entranceEffectType: json['entranceEffectType'] ?? json['entrance_effect_type'],
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liveStreamId': liveStreamId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'userIsVerified': userIsVerified,
      'status': status.name,
      'tier': tier.name,
      'joinedAt': joinedAt,
      'leftAt': leftAt,
      'lastActiveAt': lastActiveAt,
      'watchDurationSeconds': watchDurationSeconds,
      'messagesCount': messagesCount,
      'giftsCount': giftsCount,
      'totalGiftSpent': totalGiftSpent,
      'likesGiven': likesGiven,
      'connectionQuality': connectionQuality,
      'deviceType': deviceType,
      'platform': platform,
      'hasEntranceEffect': hasEntranceEffect,
      'entranceEffectType': entranceEffectType,
    };
  }

  // CopyWith method
  LiveViewerModel copyWith({
    String? id,
    String? liveStreamId,
    String? userId,
    String? userName,
    String? userImage,
    bool? userIsVerified,
    ViewerStatus? status,
    ViewerTier? tier,
    String? joinedAt,
    String? leftAt,
    String? lastActiveAt,
    int? watchDurationSeconds,
    int? messagesCount,
    int? giftsCount,
    double? totalGiftSpent,
    int? likesGiven,
    String? connectionQuality,
    String? deviceType,
    String? platform,
    bool? hasEntranceEffect,
    String? entranceEffectType,
  }) {
    return LiveViewerModel(
      id: id ?? this.id,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      userIsVerified: userIsVerified ?? this.userIsVerified,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      watchDurationSeconds: watchDurationSeconds ?? this.watchDurationSeconds,
      messagesCount: messagesCount ?? this.messagesCount,
      giftsCount: giftsCount ?? this.giftsCount,
      totalGiftSpent: totalGiftSpent ?? this.totalGiftSpent,
      likesGiven: likesGiven ?? this.likesGiven,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      hasEntranceEffect: hasEntranceEffect ?? this.hasEntranceEffect,
      entranceEffectType: entranceEffectType ?? this.entranceEffectType,
    );
  }

  // Helper getters
  bool get isWatching => status == ViewerStatus.watching;
  bool get isIdle => status == ViewerStatus.idle;
  bool get isDisconnected => status == ViewerStatus.disconnected;
  
  bool get isModerator => tier == ViewerTier.moderator;
  bool get isTopGifter => tier == ViewerTier.topGifter;
  bool get isVip => tier == ViewerTier.vip;
  bool get isFollower => tier == ViewerTier.follower;
  
  bool get hasSpecialBadge => tier != ViewerTier.regular;
  bool get hasEngaged => messagesCount > 0 || giftsCount > 0;
  bool get hasSpentMoney => totalGiftSpent > 0;

  String get watchDurationText {
    if (watchDurationSeconds < 60) {
      return '${watchDurationSeconds}s';
    } else if (watchDurationSeconds < 3600) {
      return '${(watchDurationSeconds / 60).floor()}m';
    } else {
      final hours = (watchDurationSeconds / 3600).floor();
      final minutes = ((watchDurationSeconds % 3600) / 60).floor();
      return '${hours}h ${minutes}m';
    }
  }

  String get totalSpentText {
    if (totalGiftSpent < 1000) {
      return '${totalGiftSpent.toStringAsFixed(0)} KES';
    }
    return '${(totalGiftSpent / 1000).toStringAsFixed(1)}K KES';
  }

  String get connectionQualityEmoji {
    switch (connectionQuality?.toLowerCase()) {
      case 'excellent':
        return '🟢';
      case 'good':
        return '🟡';
      case 'poor':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get timeInStream {
    final joined = DateTime.parse(joinedAt);
    final now = DateTime.now();
    final difference = now.difference(joined);

    if (difference.inMinutes < 1) {
      return 'just joined';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveViewerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveViewerModel(id: $id, user: $userName, tier: ${tier.name}, status: ${status.name})';
  }
}

// Viewer list summary (for UI display)
class ViewerListSummary {
  final int totalViewers;           // Current watching + idle
  final int activeViewers;          // Currently watching only
  final int peakViewers;            // Peak concurrent viewers
  final List<LiveViewerModel> topGifters;       // Top 3-5 gift senders
  final List<LiveViewerModel> moderators;       // All moderators
  final List<LiveViewerModel> recentJoiners;    // Last 10 viewers who joined

  const ViewerListSummary({
    required this.totalViewers,
    required this.activeViewers,
    required this.peakViewers,
    required this.topGifters,
    required this.moderators,
    required this.recentJoiners,
  });

  factory ViewerListSummary.fromJson(Map<String, dynamic> json) {
    return ViewerListSummary(
      totalViewers: json['totalViewers'] ?? json['total_viewers'] ?? 0,
      activeViewers: json['activeViewers'] ?? json['active_viewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? json['peak_viewers'] ?? 0,
      topGifters: (json['topGifters'] ?? json['top_gifters'] as List<dynamic>?)
          ?.map((v) => LiveViewerModel.fromJson(v))
          .toList() ?? [],
      moderators: (json['moderators'] as List<dynamic>?)
          ?.map((v) => LiveViewerModel.fromJson(v))
          .toList() ?? [],
      recentJoiners: (json['recentJoiners'] ?? json['recent_joiners'] as List<dynamic>?)
          ?.map((v) => LiveViewerModel.fromJson(v))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalViewers': totalViewers,
      'activeViewers': activeViewers,
      'peakViewers': peakViewers,
      'topGifters': topGifters.map((v) => v.toJson()).toList(),
      'moderators': moderators.map((v) => v.toJson()).toList(),
      'recentJoiners': recentJoiners.map((v) => v.toJson()).toList(),
    };
  }

  String get viewerCountText {
    if (totalViewers < 1000) return '$totalViewers';
    if (totalViewers < 1000000) return '${(totalViewers / 1000).toStringAsFixed(1)}K';
    return '${(totalViewers / 1000000).toStringAsFixed(1)}M';
  }
}

// Viewer action event (for analytics)
class ViewerActionEvent {
  final String viewerId;
  final String userId;
  final String userName;
  final ViewerActionType action;
  final String timestamp;
  final Map<String, dynamic>? metadata;  // Additional action data

  const ViewerActionEvent({
    required this.viewerId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
    this.metadata,
  });

  factory ViewerActionEvent.fromJson(Map<String, dynamic> json) {
    return ViewerActionEvent(
      viewerId: json['viewerId'] ?? json['viewer_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      action: ViewerActionType.values.firstWhere(
        (e) => e.name == (json['action'] ?? 'joined'),
        orElse: () => ViewerActionType.joined,
      ),
      timestamp: json['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewerId': viewerId,
      'userId': userId,
      'userName': userName,
      'action': action.name,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// Viewer action types
enum ViewerActionType {
  joined,           // Viewer joined stream
  left,             // Viewer left stream
  sentMessage,      // Sent chat message
  sentGift,         // Sent gift
  likedMessage,     // Liked a chat message
  reportedContent,  // Reported content
  blocked,          // Was blocked by host
  promoted,         // Promoted to moderator
  viewedProduct,    // Clicked on product
  purchasedProduct; // Made a purchase

  String get displayName {
    switch (this) {
      case ViewerActionType.joined:
        return 'Joined';
      case ViewerActionType.left:
        return 'Left';
      case ViewerActionType.sentMessage:
        return 'Sent Message';
      case ViewerActionType.sentGift:
        return 'Sent Gift';
      case ViewerActionType.likedMessage:
        return 'Liked Message';
      case ViewerActionType.reportedContent:
        return 'Reported Content';
      case ViewerActionType.blocked:
        return 'Blocked';
      case ViewerActionType.promoted:
        return 'Promoted';
      case ViewerActionType.viewedProduct:
        return 'Viewed Product';
      case ViewerActionType.purchasedProduct:
        return 'Purchased Product';
    }
  }
}