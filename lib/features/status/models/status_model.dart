// ===============================
// Status Models (Plain Dart Classes)
// Enhanced status feature with privacy and interactions
// ===============================

import 'status_enums.dart';

export 'status_enums.dart';

// ===============================
// STATUS MODEL
// ===============================

class StatusModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;

  // Content
  final String? content; // Text content for text status
  final String? mediaUrl; // Single media URL (image or video)
  final StatusMediaType mediaType;
  final String? thumbnailUrl; // Thumbnail for videos
  final TextStatusBackground? textBackground; // Background for text status

  // Metadata
  final DateTime createdAt;
  final DateTime expiresAt; // 24 hours from creation
  final bool isDeleted;

  // Privacy
  final StatusVisibility visibility;
  final List<String> visibleTo; // Custom list of user IDs
  final List<String> hiddenFrom; // User IDs to hide from

  // Engagement metrics (PRIVACY: Only counts, not viewer details)
  final int viewsCount; // Total view count
  final int likesCount;
  final int giftsCount;

  // User interaction state
  final bool isViewedByMe;
  final bool isLikedByMe;

  // Duration (for video/auto-advance)
  final int?
      durationSeconds; // null for text/image (uses default), specific for video

  const StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.content,
    this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.textBackground,
    required this.createdAt,
    required this.expiresAt,
    this.isDeleted = false,
    this.visibility = StatusVisibility.all,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.giftsCount = 0,
    this.isViewedByMe = false,
    this.isLikedByMe = false,
    this.durationSeconds,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar:
          json['userAvatar'] as String? ?? json['user_avatar'] as String,
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String? ?? json['media_url'] as String?,
      mediaType: StatusMediaTypeExtension.fromJson(
        json['mediaType'] as String? ?? json['media_type'] as String? ?? 'text',
      ),
      thumbnailUrl:
          json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      textBackground: json['textBackground'] != null
          ? TextStatusBackgroundExtension.fromJson(
              json['textBackground'] as String)
          : json['text_background'] != null
              ? TextStatusBackgroundExtension.fromJson(
                  json['text_background'] as String)
              : null,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? json['created_at'] as String),
      expiresAt: DateTime.parse(
          json['expiresAt'] as String? ?? json['expires_at'] as String),
      isDeleted:
          json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
      visibility: StatusVisibilityExtension.fromJson(
        json['visibility'] as String? ?? 'all',
      ),
      visibleTo: (json['visibleTo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['visible_to'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hiddenFrom: (json['hiddenFrom'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['hidden_from'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      viewsCount:
          json['viewsCount'] as int? ?? json['views_count'] as int? ?? 0,
      likesCount:
          json['likesCount'] as int? ?? json['likes_count'] as int? ?? 0,
      giftsCount:
          json['giftsCount'] as int? ?? json['gifts_count'] as int? ?? 0,
      isViewedByMe: json['isViewedByMe'] as bool? ??
          json['is_viewed_by_me'] as bool? ??
          false,
      isLikedByMe: json['isLikedByMe'] as bool? ??
          json['is_liked_by_me'] as bool? ??
          false,
      durationSeconds:
          json['durationSeconds'] as int? ?? json['duration_seconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'textBackground': textBackground?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isDeleted': isDeleted,
      'visibility': visibility.toJson(),
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'viewsCount': viewsCount,
      'likesCount': likesCount,
      'giftsCount': giftsCount,
      'isViewedByMe': isViewedByMe,
      'isLikedByMe': isLikedByMe,
      'durationSeconds': durationSeconds,
    };
  }

  StatusModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? mediaUrl,
    StatusMediaType? mediaType,
    String? thumbnailUrl,
    TextStatusBackground? textBackground,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isDeleted,
    StatusVisibility? visibility,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    int? viewsCount,
    int? likesCount,
    int? giftsCount,
    bool? isViewedByMe,
    bool? isLikedByMe,
    int? durationSeconds,
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      textBackground: textBackground ?? this.textBackground,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isDeleted: isDeleted ?? this.isDeleted,
      visibility: visibility ?? this.visibility,
      visibleTo: visibleTo ?? this.visibleTo,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      giftsCount: giftsCount ?? this.giftsCount,
      isViewedByMe: isViewedByMe ?? this.isViewedByMe,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  // Helper getters
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isDeleted && !isExpired;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  Duration get timeSinceCreation => DateTime.now().difference(createdAt);

  // Get display duration for viewer (in seconds)
  int get displayDuration {
    if (durationSeconds != null) return durationSeconds!;
    if (mediaType.isVideo) return 15; // Default video duration
    if (mediaType.isImage) return 5; // Image display time
    return 5; // Text status display time
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'StatusModel(id: $id, userId: $userId, mediaType: $mediaType)';
}

// ===============================
// STATUS GROUP (User's statuses grouped together)
// ===============================

class StatusGroup {
  final String userId;
  final String userName;
  final String userAvatar;
  final List<StatusModel> statuses;
  final bool isMyStatus; // Is this the current user's status group

  const StatusGroup({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.statuses,
    this.isMyStatus = false,
  });

  // Get active (non-expired, non-deleted) statuses
  List<StatusModel> get activeStatuses {
    return statuses.where((s) => s.isActive).toList();
  }

  // Get latest status
  StatusModel? get latestStatus {
    if (activeStatuses.isEmpty) return null;
    return activeStatuses
        .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  // Check if any status is unviewed
  bool get hasUnviewedStatus {
    return activeStatuses.any((s) => !s.isViewedByMe);
  }

  // Total view count across all statuses
  int get totalViews {
    return activeStatuses.fold(0, (sum, s) => sum + s.viewsCount);
  }

  // Time of latest status
  DateTime? get latestStatusTime {
    return latestStatus?.createdAt;
  }

  factory StatusGroup.fromJson(Map<String, dynamic> json) {
    return StatusGroup(
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar:
          json['userAvatar'] as String? ?? json['user_avatar'] as String,
      statuses: (json['statuses'] as List<dynamic>)
          .map((e) => StatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isMyStatus:
          json['isMyStatus'] as bool? ?? json['is_my_status'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'statuses': statuses.map((s) => s.toJson()).toList(),
      'isMyStatus': isMyStatus,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusGroup && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

// ===============================
// CREATE STATUS REQUEST
// ===============================

class CreateStatusRequest {
  final String? content;
  final String? mediaUrl;
  final StatusMediaType mediaType;
  final String? thumbnailUrl;
  final TextStatusBackground? textBackground;
  final StatusVisibility visibility;
  final List<String> visibleTo;
  final List<String> hiddenFrom;
  final int? durationSeconds;

  const CreateStatusRequest({
    this.content,
    this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.textBackground,
    this.visibility = StatusVisibility.all,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toJson(),
      'thumbnailUrl': thumbnailUrl,
      'textBackground': textBackground?.toJson(),
      'visibility': visibility.toJson(),
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'durationSeconds': durationSeconds,
    };
  }

  factory CreateStatusRequest.fromJson(Map<String, dynamic> json) {
    return CreateStatusRequest(
      content: json['content'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: StatusMediaTypeExtension.fromJson(
          json['mediaType'] as String? ?? 'text'),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      textBackground: json['textBackground'] != null
          ? TextStatusBackgroundExtension.fromJson(
              json['textBackground'] as String)
          : null,
      visibility: StatusVisibilityExtension.fromJson(
          json['visibility'] as String? ?? 'all'),
      visibleTo: (json['visibleTo'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hiddenFrom: (json['hiddenFrom'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      durationSeconds: json['durationSeconds'] as int?,
    );
  }
}
