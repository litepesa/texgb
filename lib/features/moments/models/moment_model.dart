// ===============================
// Moment Models (Plain Dart Classes)
// Matching existing codebase pattern
// ===============================

import 'moment_enums.dart';

// ===============================
// MOMENT MODEL
// ===============================

class MomentModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String? content;
  final List<String> mediaUrls;
  final MomentMediaType mediaType;
  final String? location;

  // Privacy settings
  final MomentVisibility visibility;
  final List<String> visibleTo;
  final List<String> hiddenFrom;

  // Engagement metrics
  final int likesCount;
  final int commentsCount;

  // User interaction state
  final bool isLikedByMe;
  final bool isMutualContact;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  // Cover photo
  final String? coverPhotoUrl;

  // Previews
  final List<MomentCommentModel> commentsPreview;
  final List<MomentLikerModel> likesPreview;

  const MomentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.content,
    this.mediaUrls = const [],
    required this.mediaType,
    this.location,
    required this.visibility,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByMe = false,
    this.isMutualContact = false,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.coverPhotoUrl,
    this.commentsPreview = const [],
    this.likesPreview = const [],
  });

  factory MomentModel.fromJson(Map<String, dynamic> json) {
    return MomentModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar: json['userAvatar'] as String? ?? json['user_avatar'] as String,
      content: json['content'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          (json['media_urls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      mediaType: MomentMediaTypeExtension.fromJson(
        json['mediaType'] as String? ?? json['media_type'] as String? ?? 'text',
      ),
      location: json['location'] as String?,
      visibility: MomentVisibilityExtension.fromJson(
        json['visibility'] as String? ?? 'all',
      ),
      visibleTo: (json['visibleTo'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          (json['visible_to'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      hiddenFrom: (json['hiddenFrom'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          (json['hidden_from'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      likesCount: json['likesCount'] as int? ?? json['likes_count'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? json['comments_count'] as int? ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? json['is_liked_by_me'] as bool? ?? false,
      isMutualContact: json['isMutualContact'] as bool? ?? json['is_mutual_contact'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
      isDeleted: json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
      coverPhotoUrl: json['coverPhotoUrl'] as String? ?? json['cover_photo_url'] as String?,
      commentsPreview: (json['commentsPreview'] as List<dynamic>?)
              ?.map((e) => MomentCommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['comments_preview'] as List<dynamic>?)
              ?.map((e) => MomentCommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      likesPreview: (json['likesPreview'] as List<dynamic>?)
              ?.map((e) => MomentLikerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['likes_preview'] as List<dynamic>?)
              ?.map((e) => MomentLikerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.toJson(),
      'location': location,
      'visibility': visibility.toJson(),
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isLikedByMe': isLikedByMe,
      'isMutualContact': isMutualContact,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'coverPhotoUrl': coverPhotoUrl,
      'commentsPreview': commentsPreview.map((e) => e.toJson()).toList(),
      'likesPreview': likesPreview.map((e) => e.toJson()).toList(),
    };
  }

  MomentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    List<String>? mediaUrls,
    MomentMediaType? mediaType,
    String? location,
    MomentVisibility? visibility,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
    bool? isMutualContact,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? coverPhotoUrl,
    List<MomentCommentModel>? commentsPreview,
    List<MomentLikerModel>? likesPreview,
  }) {
    return MomentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      visibleTo: visibleTo ?? this.visibleTo,
      hiddenFrom: hiddenFrom ?? this.hiddenFrom,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isMutualContact: isMutualContact ?? this.isMutualContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      commentsPreview: commentsPreview ?? this.commentsPreview,
      likesPreview: likesPreview ?? this.likesPreview,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MomentModel(id: $id, userId: $userId, content: $content)';
}

// ===============================
// MOMENT LIKER MODEL
// ===============================

class MomentLikerModel {
  final String userId;
  final String userName;
  final String userAvatar;
  final DateTime likedAt;
  final bool isMutualContact;

  const MomentLikerModel({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.likedAt,
    this.isMutualContact = false,
  });

  factory MomentLikerModel.fromJson(Map<String, dynamic> json) {
    return MomentLikerModel(
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar: json['userAvatar'] as String? ?? json['user_avatar'] as String,
      likedAt: DateTime.parse(json['likedAt'] as String? ?? json['liked_at'] as String),
      isMutualContact: json['isMutualContact'] as bool? ?? json['is_mutual_contact'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'likedAt': likedAt.toIso8601String(),
      'isMutualContact': isMutualContact,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentLikerModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

// ===============================
// MOMENT COMMENT MODEL
// ===============================

class MomentCommentModel {
  final String id;
  final String momentId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String? replyToUserId;
  final String? replyToUserName;
  final DateTime createdAt;
  final bool isMutualContact;
  final bool isDeleted;

  const MomentCommentModel({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.replyToUserId,
    this.replyToUserName,
    required this.createdAt,
    this.isMutualContact = false,
    this.isDeleted = false,
  });

  factory MomentCommentModel.fromJson(Map<String, dynamic> json) {
    return MomentCommentModel(
      id: json['id'] as String,
      momentId: json['momentId'] as String? ?? json['moment_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar: json['userAvatar'] as String? ?? json['user_avatar'] as String,
      content: json['content'] as String,
      replyToUserId: json['replyToUserId'] as String? ?? json['reply_to_user_id'] as String?,
      replyToUserName: json['replyToUserName'] as String? ?? json['reply_to_user_name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      isMutualContact: json['isMutualContact'] as bool? ?? json['is_mutual_contact'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'momentId': momentId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'replyToUserId': replyToUserId,
      'replyToUserName': replyToUserName,
      'createdAt': createdAt.toIso8601String(),
      'isMutualContact': isMutualContact,
      'isDeleted': isDeleted,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentCommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// MOMENT PRIVACY SETTINGS
// ===============================

class MomentPrivacySettings {
  final String userId;
  final TimelineVisibility timelineVisibility;
  final List<String> hiddenFrom;
  final bool allowStrangersPhotos;
  final String? coverPhotoUrl;
  final DateTime updatedAt;

  const MomentPrivacySettings({
    required this.userId,
    this.timelineVisibility = TimelineVisibility.all,
    this.hiddenFrom = const [],
    this.allowStrangersPhotos = false,
    this.coverPhotoUrl,
    required this.updatedAt,
  });

  factory MomentPrivacySettings.fromJson(Map<String, dynamic> json) {
    return MomentPrivacySettings(
      userId: json['userId'] as String? ?? json['user_id'] as String,
      timelineVisibility: TimelineVisibilityExtension.fromJson(
        json['timelineVisibility'] as String? ?? json['timeline_visibility'] as String? ?? 'all',
      ),
      hiddenFrom: (json['hiddenFrom'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          (json['hidden_from'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      allowStrangersPhotos: json['allowStrangersPhotos'] as bool? ?? json['allow_strangers_photos'] as bool? ?? false,
      coverPhotoUrl: json['coverPhotoUrl'] as String? ?? json['cover_photo_url'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'timelineVisibility': timelineVisibility.toJson(),
      'hiddenFrom': hiddenFrom,
      'allowStrangersPhotos': allowStrangersPhotos,
      'coverPhotoUrl': coverPhotoUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ===============================
// CREATE MOMENT REQUEST
// ===============================

class CreateMomentRequest {
  final String? content;
  final List<String> mediaUrls;
  final MomentMediaType mediaType;
  final String? location;
  final MomentVisibility visibility;
  final List<String> visibleTo;
  final List<String> hiddenFrom;
  final List<String> remindUsers;

  const CreateMomentRequest({
    this.content,
    this.mediaUrls = const [],
    required this.mediaType,
    this.location,
    this.visibility = MomentVisibility.all,
    this.visibleTo = const [],
    this.hiddenFrom = const [],
    this.remindUsers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.toJson(),
      'location': location,
      'visibility': visibility.toJson(),
      'visibleTo': visibleTo,
      'hiddenFrom': hiddenFrom,
      'remindUsers': remindUsers,
    };
  }

  factory CreateMomentRequest.fromJson(Map<String, dynamic> json) {
    return CreateMomentRequest(
      content: json['content'] as String?,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      mediaType: MomentMediaTypeExtension.fromJson(json['mediaType'] as String? ?? 'text'),
      location: json['location'] as String?,
      visibility: MomentVisibilityExtension.fromJson(json['visibility'] as String? ?? 'all'),
      visibleTo: (json['visibleTo'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      hiddenFrom: (json['hiddenFrom'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      remindUsers: (json['remindUsers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }
}

// ===============================
// UPDATE PRIVACY REQUEST
// ===============================

class UpdatePrivacyRequest {
  final TimelineVisibility? timelineVisibility;
  final List<String>? hiddenFrom;
  final bool? allowStrangersPhotos;
  final String? coverPhotoUrl;

  const UpdatePrivacyRequest({
    this.timelineVisibility,
    this.hiddenFrom,
    this.allowStrangersPhotos,
    this.coverPhotoUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (timelineVisibility != null) {
      map['timelineVisibility'] = timelineVisibility!.toJson();
    }
    if (hiddenFrom != null) {
      map['hiddenFrom'] = hiddenFrom;
    }
    if (allowStrangersPhotos != null) {
      map['allowStrangersPhotos'] = allowStrangersPhotos;
    }
    if (coverPhotoUrl != null) {
      map['coverPhotoUrl'] = coverPhotoUrl;
    }
    return map;
  }

  factory UpdatePrivacyRequest.fromJson(Map<String, dynamic> json) {
    return UpdatePrivacyRequest(
      timelineVisibility: json['timelineVisibility'] != null
          ? TimelineVisibilityExtension.fromJson(json['timelineVisibility'] as String)
          : null,
      hiddenFrom: json['hiddenFrom'] != null
          ? (json['hiddenFrom'] as List<dynamic>).map((e) => e as String).toList()
          : null,
      allowStrangersPhotos: json['allowStrangersPhotos'] as bool?,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
    );
  }
}
