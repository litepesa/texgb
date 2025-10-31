// lib/features/live_streaming/models/refined_live_stream_model.dart
// REFINED Live Stream Model integrating Gift vs Shop types
// This supersedes parts of live_stream_model.dart with better architecture

import 'package:textgb/features/live_streaming/models/live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';

/// Enhanced Live Stream Model with type-specific configurations
class RefinedLiveStreamModel {
  // Core fields (same as original)
  final String id;
  final String hostId;
  final String hostName;
  final String hostImage;
  final bool hostIsVerified;

  // Stream details
  final String title;
  final String description;
  final String thumbnailUrl;
  final LiveStreamCategory category;
  final List<String> tags;
  final LiveStreamStatus status;

  // NEW: Stream type and configurations
  final LiveStreamType type;          // Gift or Shop
  final GiftLiveConfig? giftConfig;   // Only for gift streams
  final ShopLiveConfig? shopConfig;   // Only for shop streams

  // Agora details
  final String channelName;
  final String? agoraToken;
  final String? agoraUid;

  // Metrics
  final int currentViewers;
  final int totalViewers;
  final int peakViewers;
  final int likesCount;

  // Timestamps
  final String scheduledAt;
  final String? startedAt;
  final String? endedAt;
  final String createdAt;
  final String updatedAt;

  // Settings
  final bool isRecording;
  final bool allowComments;
  final bool isPrivate;

  // Moderation
  final List<String> blockedUserIds;
  final List<String> moderatorIds;
  final int reportCount;

  const RefinedLiveStreamModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostImage,
    required this.hostIsVerified,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.tags,
    required this.status,
    required this.type,
    this.giftConfig,
    this.shopConfig,
    required this.channelName,
    this.agoraToken,
    this.agoraUid,
    required this.currentViewers,
    required this.totalViewers,
    required this.peakViewers,
    required this.likesCount,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isRecording,
    required this.allowComments,
    required this.isPrivate,
    required this.blockedUserIds,
    required this.moderatorIds,
    required this.reportCount,
  }) : assert(
          (type == LiveStreamType.gift && giftConfig != null) ||
          (type == LiveStreamType.shop && shopConfig != null),
          'Gift streams must have giftConfig, Shop streams must have shopConfig',
        );

  /// Create a Gift Live stream
  factory RefinedLiveStreamModel.createGiftStream({
    required String hostId,
    required String hostName,
    required String hostImage,
    required bool hostIsVerified,
    required String title,
    String description = '',
    LiveStreamCategory category = LiveStreamCategory.entertainment,
    List<String> tags = const [],
    GiftLiveConfig? customGiftConfig,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final channelName = 'gift_${hostId}_${DateTime.now().millisecondsSinceEpoch}';

    return RefinedLiveStreamModel(
      id: '',
      hostId: hostId,
      hostName: hostName,
      hostImage: hostImage,
      hostIsVerified: hostIsVerified,
      title: title,
      description: description,
      thumbnailUrl: '',
      category: category,
      tags: tags,
      status: LiveStreamStatus.live,
      type: LiveStreamType.gift,
      giftConfig: customGiftConfig ?? GiftLiveConfig(),
      shopConfig: null,
      channelName: channelName,
      currentViewers: 0,
      totalViewers: 0,
      peakViewers: 0,
      likesCount: 0,
      scheduledAt: now,
      createdAt: now,
      updatedAt: now,
      isRecording: true,
      allowComments: true,
      isPrivate: false,
      blockedUserIds: [],
      moderatorIds: [],
      reportCount: 0,
    );
  }

  /// Create a Shop Live stream
  factory RefinedLiveStreamModel.createShopStream({
    required String hostId,
    required String hostName,
    required String hostImage,
    required bool hostIsVerified,
    required String title,
    required String shopId,
    required String shopName,
    String description = '',
    LiveStreamCategory category = LiveStreamCategory.shopping,
    List<String> tags = const [],
    List<String> featuredProductIds = const [],
    double commissionRate = 10.0,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final channelName = 'shop_${hostId}_${DateTime.now().millisecondsSinceEpoch}';

    return RefinedLiveStreamModel(
      id: '',
      hostId: hostId,
      hostName: hostName,
      hostImage: hostImage,
      hostIsVerified: hostIsVerified,
      title: title,
      description: description,
      thumbnailUrl: '',
      category: category,
      tags: tags,
      status: LiveStreamStatus.live,
      type: LiveStreamType.shop,
      giftConfig: null,
      shopConfig: ShopLiveConfig(
        shopId: shopId,
        shopName: shopName,
        featuredProductIds: featuredProductIds,
        commissionRate: commissionRate,
      ),
      channelName: channelName,
      currentViewers: 0,
      totalViewers: 0,
      peakViewers: 0,
      likesCount: 0,
      scheduledAt: now,
      createdAt: now,
      updatedAt: now,
      isRecording: true,
      allowComments: true,
      isPrivate: false,
      blockedUserIds: [],
      moderatorIds: [],
      reportCount: 0,
    );
  }

  factory RefinedLiveStreamModel.fromJson(Map<String, dynamic> json) {
    final type = LiveStreamType.fromString(json['type']);

    return RefinedLiveStreamModel(
      id: json['id'] ?? '',
      hostId: json['hostId'] ?? json['host_id'] ?? '',
      hostName: json['hostName'] ?? json['host_name'] ?? '',
      hostImage: json['hostImage'] ?? json['host_image'] ?? '',
      hostIsVerified: json['hostIsVerified'] ?? json['host_is_verified'] ?? false,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? '',
      category: LiveStreamCategory.fromString(json['category']),
      tags: List<String>.from(json['tags'] ?? []),
      status: LiveStreamStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'live'),
        orElse: () => LiveStreamStatus.live,
      ),
      type: type,
      giftConfig: type == LiveStreamType.gift && json['giftConfig'] != null
          ? GiftLiveConfig.fromJson(json['giftConfig'] ?? json['gift_config'])
          : null,
      shopConfig: type == LiveStreamType.shop && json['shopConfig'] != null
          ? ShopLiveConfig.fromJson(json['shopConfig'] ?? json['shop_config'])
          : null,
      channelName: json['channelName'] ?? json['channel_name'] ?? '',
      agoraToken: json['agoraToken'] ?? json['agora_token'],
      agoraUid: json['agoraUid'] ?? json['agora_uid'],
      currentViewers: json['currentViewers'] ?? json['current_viewers'] ?? 0,
      totalViewers: json['totalViewers'] ?? json['total_viewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? json['peak_viewers'] ?? 0,
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      scheduledAt: json['scheduledAt'] ?? json['scheduled_at'] ?? '',
      startedAt: json['startedAt'] ?? json['started_at'],
      endedAt: json['endedAt'] ?? json['ended_at'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? '',
      isRecording: json['isRecording'] ?? json['is_recording'] ?? true,
      allowComments: json['allowComments'] ?? json['allow_comments'] ?? true,
      isPrivate: json['isPrivate'] ?? json['is_private'] ?? false,
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? json['blocked_user_ids'] ?? []),
      moderatorIds: List<String>.from(json['moderatorIds'] ?? json['moderator_ids'] ?? []),
      reportCount: json['reportCount'] ?? json['report_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostImage': hostImage,
      'hostIsVerified': hostIsVerified,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category.name,
      'tags': tags,
      'status': status.name,
      'type': type.name,
      'giftConfig': giftConfig?.toJson(),
      'shopConfig': shopConfig?.toJson(),
      'channelName': channelName,
      'agoraToken': agoraToken,
      'agoraUid': agoraUid,
      'currentViewers': currentViewers,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'likesCount': likesCount,
      'scheduledAt': scheduledAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isRecording': isRecording,
      'allowComments': allowComments,
      'isPrivate': isPrivate,
      'blockedUserIds': blockedUserIds,
      'moderatorIds': moderatorIds,
      'reportCount': reportCount,
    };
  }

  RefinedLiveStreamModel copyWith({
    String? id,
    String? title,
    String? description,
    LiveStreamStatus? status,
    GiftLiveConfig? giftConfig,
    ShopLiveConfig? shopConfig,
    String? agoraToken,
    int? currentViewers,
    int? totalViewers,
    int? peakViewers,
    int? likesCount,
    String? startedAt,
    String? endedAt,
    String? updatedAt,
  }) {
    return RefinedLiveStreamModel(
      id: id ?? this.id,
      hostId: hostId,
      hostName: hostName,
      hostImage: hostImage,
      hostIsVerified: hostIsVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl,
      category: category,
      tags: tags,
      status: status ?? this.status,
      type: type,
      giftConfig: giftConfig ?? this.giftConfig,
      shopConfig: shopConfig ?? this.shopConfig,
      channelName: channelName,
      agoraToken: agoraToken ?? this.agoraToken,
      agoraUid: agoraUid,
      currentViewers: currentViewers ?? this.currentViewers,
      totalViewers: totalViewers ?? this.totalViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      likesCount: likesCount ?? this.likesCount,
      scheduledAt: scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecording: isRecording,
      allowComments: allowComments,
      isPrivate: isPrivate,
      blockedUserIds: blockedUserIds,
      moderatorIds: moderatorIds,
      reportCount: reportCount,
    );
  }

  // Helper getters
  bool get isLive => status == LiveStreamStatus.live;
  bool get isScheduled => status == LiveStreamStatus.scheduled;
  bool get isEnded => status == LiveStreamStatus.ended;

  bool get isGiftStream => type == LiveStreamType.gift;
  bool get isShopStream => type == LiveStreamType.shop;

  // Revenue getters
  double get totalRevenue {
    if (isGiftStream && giftConfig != null) {
      return giftConfig!.totalGiftRevenue;
    }
    if (isShopStream && shopConfig != null) {
      return shopConfig!.totalCommissions;
    }
    return 0.0;
  }

  String get formattedRevenue => 'KES ${totalRevenue.toStringAsFixed(2)}';

  String get viewersText {
    if (currentViewers < 1000) return '$currentViewers';
    if (currentViewers < 1000000) return '${(currentViewers / 1000).toStringAsFixed(1)}K';
    return '${(currentViewers / 1000000).toStringAsFixed(1)}M';
  }

  String get durationText {
    if (startedAt == null) return '0:00';
    final start = DateTime.parse(startedAt!);
    final end = endedAt != null ? DateTime.parse(endedAt!) : DateTime.now();
    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefinedLiveStreamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
