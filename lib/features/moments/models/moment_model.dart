// lib/features/moments/models/moment_model.dart
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class MomentModel {
  final String momentId;
  final String userId;
  final String userName;
  final String userImage;
  final String content; // Text content
  final List<String> mediaUrls; // Image/video URLs
  final StatusType momentType; // text, image, video
  final DateTime createdAt;
  final List<String> likedBy; // UIDs of users who liked
  final List<MomentComment> comments;
  final int viewCount;
  final StatusPrivacyType privacyType;
  final List<String> excludedUsers; // For privacy type 'except'
  final List<String> onlyUsers; // For privacy type 'only'

  MomentModel({
    required this.momentId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content,
    required this.mediaUrls,
    required this.momentType,
    required this.createdAt,
    required this.likedBy,
    required this.comments,
    required this.viewCount,
    this.privacyType = StatusPrivacyType.all_contacts,
    this.excludedUsers = const [],
    this.onlyUsers = const [],
  });

  // Factory constructor from Firestore data
  factory MomentModel.fromMap(Map<String, dynamic> map) {
    return MomentModel(
      momentId: map['momentId'] ?? '',
      userId: map[Constants.userId] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      momentType: StatusTypeExtension.fromString(map['momentType'] ?? 'text'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[Constants.createdAt] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      likedBy: List<String>.from(map[Constants.likedBy] ?? []),
      comments: (map['comments'] as List<dynamic>? ?? [])
          .map((comment) => MomentComment.fromMap(comment))
          .toList(),
      viewCount: map[Constants.viewCount] ?? 0,
      privacyType: StatusPrivacyTypeExtension.fromString(
        map['privacyType'] ?? 'all_contacts',
      ),
      excludedUsers: List<String>.from(map['excludedUsers'] ?? []),
      onlyUsers: List<String>.from(map['onlyUsers'] ?? []),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      Constants.userId: userId,
      Constants.name: userName,
      Constants.image: userImage,
      'content': content,
      'mediaUrls': mediaUrls,
      'momentType': momentType.name,
      Constants.createdAt: createdAt.millisecondsSinceEpoch,
      Constants.likedBy: likedBy,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      Constants.viewCount: viewCount,
      'privacyType': privacyType.name,
      'excludedUsers': excludedUsers,
      'onlyUsers': onlyUsers,
    };
  }

  // CopyWith method for updates
  MomentModel copyWith({
    String? momentId,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    List<String>? mediaUrls,
    StatusType? momentType,
    DateTime? createdAt,
    List<String>? likedBy,
    List<MomentComment>? comments,
    int? viewCount,
    StatusPrivacyType? privacyType,
    List<String>? excludedUsers,
    List<String>? onlyUsers,
  }) {
    return MomentModel(
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? List<String>.from(this.mediaUrls),
      momentType: momentType ?? this.momentType,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? List<String>.from(this.likedBy),
      comments: comments ?? List<MomentComment>.from(this.comments),
      viewCount: viewCount ?? this.viewCount,
      privacyType: privacyType ?? this.privacyType,
      excludedUsers: excludedUsers ?? List<String>.from(this.excludedUsers),
      onlyUsers: onlyUsers ?? List<String>.from(this.onlyUsers),
    );
  }

  // Helper getters
  int get likesCount => likedBy.length;
  int get commentsCount => comments.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool get hasMedia => mediaUrls.isNotEmpty;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentModel && other.momentId == momentId;
  }

  @override
  int get hashCode => momentId.hashCode;
}

class MomentComment {
  final String commentId;
  final String userId;
  final String userName;
  final String userImage;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;

  MomentComment({
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content,
    required this.createdAt,
    required this.likedBy,
  });

  factory MomentComment.fromMap(Map<String, dynamic> map) {
    return MomentComment(
      commentId: map['commentId'] ?? '',
      userId: map[Constants.userId] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[Constants.createdAt] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      likedBy: List<String>.from(map[Constants.likedBy] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      Constants.userId: userId,
      Constants.name: userName,
      Constants.image: userImage,
      'content': content,
      Constants.createdAt: createdAt.millisecondsSinceEpoch,
      Constants.likedBy: likedBy,
    };
  }

  MomentComment copyWith({
    String? commentId,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    DateTime? createdAt,
    List<String>? likedBy,
  }) {
    return MomentComment(
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? List<String>.from(this.likedBy),
    );
  }

  int get likesCount => likedBy.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentComment && other.commentId == commentId;
  }

  @override
  int get hashCode => commentId.hashCode;
}