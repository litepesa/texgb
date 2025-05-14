import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String statusId;
  final String userId;
  final String userName;
  final String userImage;
  final String content;
  final StatusType type;
  final String caption;
  final String createdAt;
  final String expiresAt; // Status expires after 24 hours
  final List<String> viewedBy;
  final StatusPrivacyType privacyType;
  final List<String> visibleTo; // Used when privacyType is 'only'
  final List<String> hiddenFrom; // Used when privacyType is 'except'
  final int viewCount;
  final bool isActive;

  StatusModel({
    required this.statusId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content, // URL for media or text content
    required this.type,
    this.caption = '',
    required this.createdAt,
    required this.expiresAt,
    required this.viewedBy,
    this.privacyType = StatusPrivacyType.all_contacts,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
    this.viewCount = 0,
    this.isActive = true,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map[Constants.statusId] ?? '',
      userId: map[Constants.userId] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      content: map['content'] ?? '',
      type: StatusTypeExtension.fromString(map[Constants.statusType] ?? 'text'),
      caption: map['caption'] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      expiresAt: map['expiresAt'] ?? '',
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      privacyType: StatusPrivacyTypeExtension.fromString(map['privacyType'] ?? 'all_contacts'),
      visibleTo: List<String>.from(map['visibleTo'] ?? []),
      hiddenFrom: List<String>.from(map['hiddenFrom'] ?? []),
      viewCount: map[Constants.statusViewCount] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.statusId: statusId,
      Constants.userId: userId,
      Constants.name: userName,
      Constants.image: userImage,
      'content': content,
      Constants.statusType: type.name,
      'caption': caption,
      Constants.createdAt: createdAt,
      'expiresAt': expiresAt,
      'viewedBy': viewedBy,
      'privacyType': privacyType.toString().split('.').last,
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      Constants.statusViewCount: viewCount,
      'isActive': isActive,
    };
  }

  StatusModel copyWith({
    String? statusId,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    StatusType? type,
    String? caption,
    String? createdAt,
    String? expiresAt,
    List<String>? viewedBy,
    StatusPrivacyType? privacyType,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    int? viewCount,
    bool? isActive,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewedBy: viewedBy ?? List.from(this.viewedBy),
      privacyType: privacyType ?? this.privacyType,
      visibleTo: visibleTo ?? List.from(this.visibleTo),
      hiddenFrom: hiddenFrom ?? List.from(this.hiddenFrom),
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Additional model for user status summary
class UserStatusSummary {
  final String userId;
  final String userName;
  final String userImage;
  final List<StatusModel> statuses;
  final bool hasUnviewed;
  final DateTime latestStatusTime;

  UserStatusSummary({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.statuses,
    required this.hasUnviewed,
    required this.latestStatusTime,
  });

  UserStatusSummary copyWith({
    String? userId,
    String? userName,
    String? userImage,
    List<StatusModel>? statuses,
    bool? hasUnviewed,
    DateTime? latestStatusTime,
  }) {
    return UserStatusSummary(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      statuses: statuses ?? this.statuses,
      hasUnviewed: hasUnviewed ?? this.hasUnviewed,
      latestStatusTime: latestStatusTime ?? this.latestStatusTime,
    );
  }
}