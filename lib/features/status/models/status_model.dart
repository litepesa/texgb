// lib/features/status/models/status_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';

class StatusModel {
  final String statusId;
  final String uid;
  final String userName;
  final String userImage;
  final String statusType;
  final String statusContent;
  final String? statusMediaUrl;
  final String? statusThumbnail;
  final String? statusBackgroundColor;
  final String? statusTextColor;
  final String? statusFont;
  final DateTime statusCreatedAt;
  final DateTime statusExpiresAt;
  final String statusPrivacyLevel;
  final List<String> statusAllowedViewers;
  final List<String> statusExcludedViewers;
  final int statusViewsCount;
  final List<String> statusViewers;
  final bool statusIsActive;
  final Map<String, dynamic>? statusMetadata;

  StatusModel({
    required this.statusId,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.statusType,
    required this.statusContent,
    this.statusMediaUrl,
    this.statusThumbnail,
    this.statusBackgroundColor,
    this.statusTextColor,
    this.statusFont,
    required this.statusCreatedAt,
    required this.statusExpiresAt,
    required this.statusPrivacyLevel,
    this.statusAllowedViewers = const [],
    this.statusExcludedViewers = const [],
    this.statusViewsCount = 0,
    this.statusViewers = const [],
    this.statusIsActive = true,
    this.statusMetadata,
  });

  // Helper getters
  bool get isExpired => DateTime.now().isAfter(statusExpiresAt);
  bool get isTextStatus => statusType == Constants.statusTypeText;
  bool get isImageStatus => statusType == Constants.statusTypeImage;
  bool get isVideoStatus => statusType == Constants.statusTypeVideo;
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(statusExpiresAt)) {
      return Duration.zero;
    }
    return statusExpiresAt.difference(now);
  }

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return 'Expired';
    }
  }

  // Check if user can view this status
  bool canUserView(String userId, List<String> userContacts) {
    if (!statusIsActive || isExpired) return false;
    if (uid == userId) return true; // Owner can always view

    switch (statusPrivacyLevel) {
      case Constants.statusPrivacyPublic:
        return !statusExcludedViewers.contains(userId);
      case Constants.statusPrivacyContacts:
        return userContacts.contains(uid) && !statusExcludedViewers.contains(userId);
      case Constants.statusPrivacyCustom:
        return statusAllowedViewers.contains(userId);
      case Constants.statusPrivacyClose:
        return statusAllowedViewers.contains(userId);
      default:
        return false;
    }
  }

  // Check if user has viewed this status
  bool hasUserViewed(String userId) {
    return statusViewers.contains(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.statusId: statusId,
      Constants.uid: uid,
      Constants.name: userName,
      Constants.image: userImage,
      Constants.statusType: statusType,
      Constants.statusContent: statusContent,
      Constants.statusMediaUrl: statusMediaUrl,
      Constants.statusThumbnail: statusThumbnail,
      Constants.statusBackgroundColor: statusBackgroundColor,
      Constants.statusTextColor: statusTextColor,
      Constants.statusFont: statusFont,
      Constants.statusCreatedAt: Timestamp.fromDate(statusCreatedAt),
      Constants.statusExpiresAt: Timestamp.fromDate(statusExpiresAt),
      Constants.statusPrivacyLevel: statusPrivacyLevel,
      Constants.statusAllowedViewers: statusAllowedViewers,
      Constants.statusExcludedViewers: statusExcludedViewers,
      Constants.statusViewsCount: statusViewsCount,
      Constants.statusViewers: statusViewers,
      Constants.statusIsActive: statusIsActive,
      Constants.statusMetadata: statusMetadata ?? {},
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      statusType: map[Constants.statusType] ?? Constants.statusTypeText,
      statusContent: map[Constants.statusContent] ?? '',
      statusMediaUrl: map[Constants.statusMediaUrl],
      statusThumbnail: map[Constants.statusThumbnail],
      statusBackgroundColor: map[Constants.statusBackgroundColor],
      statusTextColor: map[Constants.statusTextColor],
      statusFont: map[Constants.statusFont],
      statusCreatedAt: (map[Constants.statusCreatedAt] as Timestamp).toDate(),
      statusExpiresAt: (map[Constants.statusExpiresAt] as Timestamp).toDate(),
      statusPrivacyLevel: map[Constants.statusPrivacyLevel] ?? Constants.statusPrivacyContacts,
      statusAllowedViewers: List<String>.from(map[Constants.statusAllowedViewers] ?? []),
      statusExcludedViewers: List<String>.from(map[Constants.statusExcludedViewers] ?? []),
      statusViewsCount: map[Constants.statusViewsCount] ?? 0,
      statusViewers: List<String>.from(map[Constants.statusViewers] ?? []),
      statusIsActive: map[Constants.statusIsActive] ?? true,
      statusMetadata: map[Constants.statusMetadata],
    );
  }

  StatusModel copyWith({
    String? statusId,
    String? uid,
    String? userName,
    String? userImage,
    String? statusType,
    String? statusContent,
    String? statusMediaUrl,
    String? statusThumbnail,
    String? statusBackgroundColor,
    String? statusTextColor,
    String? statusFont,
    DateTime? statusCreatedAt,
    DateTime? statusExpiresAt,
    String? statusPrivacyLevel,
    List<String>? statusAllowedViewers,
    List<String>? statusExcludedViewers,
    int? statusViewsCount,
    List<String>? statusViewers,
    bool? statusIsActive,
    Map<String, dynamic>? statusMetadata,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      statusType: statusType ?? this.statusType,
      statusContent: statusContent ?? this.statusContent,
      statusMediaUrl: statusMediaUrl ?? this.statusMediaUrl,
      statusThumbnail: statusThumbnail ?? this.statusThumbnail,
      statusBackgroundColor: statusBackgroundColor ?? this.statusBackgroundColor,
      statusTextColor: statusTextColor ?? this.statusTextColor,
      statusFont: statusFont ?? this.statusFont,
      statusCreatedAt: statusCreatedAt ?? this.statusCreatedAt,
      statusExpiresAt: statusExpiresAt ?? this.statusExpiresAt,
      statusPrivacyLevel: statusPrivacyLevel ?? this.statusPrivacyLevel,
      statusAllowedViewers: statusAllowedViewers ?? this.statusAllowedViewers,
      statusExcludedViewers: statusExcludedViewers ?? this.statusExcludedViewers,
      statusViewsCount: statusViewsCount ?? this.statusViewsCount,
      statusViewers: statusViewers ?? this.statusViewers,
      statusIsActive: statusIsActive ?? this.statusIsActive,
      statusMetadata: statusMetadata ?? this.statusMetadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusModel && other.statusId == statusId;
  }

  @override
  int get hashCode => statusId.hashCode;
}

// Helper class for grouping statuses by user
class UserStatusGroup {
  final String uid;
  final String userName;
  final String userImage;
  final List<StatusModel> statuses;
  final DateTime lastStatusTime;
  final bool hasUnviewedStatus;
  final int unviewedCount;

  UserStatusGroup({
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.statuses,
    required this.lastStatusTime,
    required this.hasUnviewedStatus,
    required this.unviewedCount,
  });

  // Get the most recent status
  StatusModel? get latestStatus {
    if (statuses.isEmpty) return null;
    return statuses.reduce((a, b) => 
      a.statusCreatedAt.isAfter(b.statusCreatedAt) ? a : b);
  }

  // Get active (non-expired) statuses
  List<StatusModel> get activeStatuses {
    return statuses.where((status) => 
      status.statusIsActive && !status.isExpired).toList()
      ..sort((a, b) => a.statusCreatedAt.compareTo(b.statusCreatedAt));
  }

  // Check if user has any unviewed statuses
  bool hasUnviewedStatusForUser(String userId) {
    return activeStatuses.any((status) => !status.hasUserViewed(userId));
  }

  // Get unviewed status count for user
  int getUnviewedCountForUser(String userId) {
    return activeStatuses.where((status) => !status.hasUserViewed(userId)).length;
  }
}