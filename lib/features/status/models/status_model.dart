// lib/features/status/models/status_model.dart
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String statusId;
  final String userId;
  final String userName;
  final String userImage;
  final StatusType type;
  final String content; // Text content or media URL
  final String? caption; // For media posts
  final String? backgroundColor; // For text status
  final String? fontColor; // For text status
  final String? fontFamily; // For text status
  final DateTime createdAt;
  final DateTime expiresAt; // 24 hours from creation
  final List<String> viewedBy;
  final StatusPrivacyType privacyType;
  final List<String> allowedViewers; // For "only" privacy
  final List<String> excludedViewers; // For "except" privacy
  final bool isActive; // Status is active if not expired and not deleted
  final String? musicUrl; // For status with music
  final String? musicTitle; // Song title
  final String? musicArtist; // Song artist
  final Duration? musicDuration; // Duration of music clip
  final Map<String, dynamic>? metadata; // Additional data (file size, dimensions, etc.)

  const StatusModel({
    required this.statusId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.type,
    required this.content,
    this.caption,
    this.backgroundColor,
    this.fontColor,
    this.fontFamily,
    required this.createdAt,
    required this.expiresAt,
    this.viewedBy = const [],
    this.privacyType = StatusPrivacyType.all_contacts,
    this.allowedViewers = const [],
    this.excludedViewers = const [],
    this.isActive = true,
    this.musicUrl,
    this.musicTitle,
    this.musicArtist,
    this.musicDuration,
    this.metadata,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      type: StatusTypeExtension.fromString(map['type'] ?? 'text'),
      content: map['content'] ?? '',
      caption: map['caption'],
      backgroundColor: map['backgroundColor'],
      fontColor: map['fontColor'],
      fontFamily: map['fontFamily'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] ?? 0),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      privacyType: StatusPrivacyTypeExtension.fromString(map['privacyType'] ?? 'all_contacts'),
      allowedViewers: List<String>.from(map['allowedViewers'] ?? []),
      excludedViewers: List<String>.from(map['excludedViewers'] ?? []),
      isActive: map['isActive'] ?? true,
      musicUrl: map['musicUrl'],
      musicTitle: map['musicTitle'],
      musicArtist: map['musicArtist'],
      musicDuration: map['musicDuration'] != null 
          ? Duration(milliseconds: map['musicDuration']) 
          : null,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'type': type.name,
      'content': content,
      'caption': caption,
      'backgroundColor': backgroundColor,
      'fontColor': fontColor,
      'fontFamily': fontFamily,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'viewedBy': viewedBy,
      'privacyType': privacyType.name,
      'allowedViewers': allowedViewers,
      'excludedViewers': excludedViewers,
      'isActive': isActive,
      'musicUrl': musicUrl,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicDuration': musicDuration?.inMilliseconds,
      'metadata': metadata,
    };
  }

  StatusModel copyWith({
    String? statusId,
    String? userId,
    String? userName,
    String? userImage,
    StatusType? type,
    String? content,
    String? caption,
    String? backgroundColor,
    String? fontColor,
    String? fontFamily,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewedBy,
    StatusPrivacyType? privacyType,
    List<String>? allowedViewers,
    List<String>? excludedViewers,
    bool? isActive,
    String? musicUrl,
    String? musicTitle,
    String? musicArtist,
    Duration? musicDuration,
    Map<String, dynamic>? metadata,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      type: type ?? this.type,
      content: content ?? this.content,
      caption: caption ?? this.caption,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontColor: fontColor ?? this.fontColor,
      fontFamily: fontFamily ?? this.fontFamily,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? this.viewedBy,
      privacyType: privacyType ?? this.privacyType,
      allowedViewers: allowedViewers ?? this.allowedViewers,
      excludedViewers: excludedViewers ?? this.excludedViewers,
      isActive: isActive ?? this.isActive,
      musicUrl: musicUrl ?? this.musicUrl,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      musicDuration: musicDuration ?? this.musicDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt) || !isActive;
  
  bool get hasBeenViewed => viewedBy.isNotEmpty;
  
  int get viewCount => viewedBy.length;
  
  bool hasUserViewed(String userId) => viewedBy.contains(userId);
  
  bool canUserView(String userId, List<String> userContacts) {
    if (this.userId == userId) return true; // Owner can always view
    
    switch (privacyType) {
      case StatusPrivacyType.all_contacts:
        return userContacts.contains(this.userId);
      case StatusPrivacyType.only:
        return allowedViewers.contains(userId);
      case StatusPrivacyType.except:
        return userContacts.contains(this.userId) && !excludedViewers.contains(userId);
    }
  }
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }
  
  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return '${remaining.inSeconds}s';
    }
  }
  
  bool get isTextStatus => type == StatusType.text;
  bool get isImageStatus => type == StatusType.image;
  bool get isVideoStatus => type == StatusType.video;
  bool get isLinkStatus => type == StatusType.link;
  
  bool get hasMusic => musicUrl != null && musicUrl!.isNotEmpty;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusModel && other.statusId == statusId;
  }

  @override
  int get hashCode => statusId.hashCode;

  @override
  String toString() {
    return 'StatusModel(statusId: $statusId, userId: $userId, type: $type, isActive: $isActive)';
  }
}

// Helper class for grouping statuses by user
class UserStatusGroup {
  final String userId;
  final String userName;
  final String userImage;
  final List<StatusModel> statuses;
  final bool isMyStatus;

  UserStatusGroup({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.statuses,
    this.isMyStatus = false,
  });

  // Get the latest status for preview
  StatusModel? get latestStatus {
    if (statuses.isEmpty) return null;
    return statuses.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  // Get total unviewed statuses for this user
  int getUnviewedCount(String currentUserId) {
    return statuses.where((status) => !status.hasUserViewed(currentUserId)).length;
  }

  // Check if there are any unviewed statuses
  bool hasUnviewedStatuses(String currentUserId) {
    return getUnviewedCount(currentUserId) > 0;
  }

  // Get time of latest status
  String get latestStatusTime {
    final latest = latestStatus;
    if (latest == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(latest.createdAt);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  UserStatusGroup copyWith({
    String? userId,
    String? userName,
    String? userImage,
    List<StatusModel>? statuses,
    bool? isMyStatus,
  }) {
    return UserStatusGroup(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      statuses: statuses ?? this.statuses,
      isMyStatus: isMyStatus ?? this.isMyStatus,
    );
  }
}