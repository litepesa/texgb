import 'package:textgb/constants.dart';

class StatusPostModel {
  final String statusId;
  final String uid;
  final String username;
  final String userImage;
  final List<String> mediaUrls;
  final String caption;
  final StatusType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewerUIDs;
  final int viewCount;
  final List<String> likeUIDs;
  final bool isPrivate;
  final List<String> allowedContactUIDs;
  final bool isContactsOnly;

  StatusPostModel({
    required this.statusId,
    required this.uid,
    required this.username,
    required this.userImage,
    required this.mediaUrls,
    required this.caption,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    required this.viewerUIDs,
    required this.viewCount,
    required this.likeUIDs,
    required this.isPrivate,
    required this.allowedContactUIDs,
    required this.isContactsOnly,
  });

  // Factory constructor to create a StatusPostModel from a map
  factory StatusPostModel.fromMap(Map<String, dynamic> map) {
    return StatusPostModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      caption: map['caption'] ?? '',
      type: StatusType.fromString(map[Constants.statusType] ?? 'text'),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt']) 
          : DateTime.now().add(const Duration(hours: 72)),
      viewerUIDs: List<String>.from(map['viewerUIDs'] ?? []),
      viewCount: map[Constants.statusViewCount] ?? 0,
      likeUIDs: List<String>.from(map['likeUIDs'] ?? []),
      isPrivate: map['isPrivate'] ?? false,
      allowedContactUIDs: List<String>.from(map['allowedContactUIDs'] ?? []),
      isContactsOnly: map['isContactsOnly'] ?? false,
    );
  }

  // Method to convert StatusPostModel to a map
  Map<String, dynamic> toMap() {
    return {
      Constants.statusId: statusId,
      Constants.uid: uid,
      Constants.name: username,
      Constants.image: userImage,
      'mediaUrls': mediaUrls,
      'caption': caption,
      Constants.statusType: type.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewerUIDs': viewerUIDs,
      Constants.statusViewCount: viewCount,
      'likeUIDs': likeUIDs,
      'isPrivate': isPrivate,
      'allowedContactUIDs': allowedContactUIDs,
      'isContactsOnly': isContactsOnly,
    };
  }

  // Getter for like count
  int get likeCount => likeUIDs.length;

  // Check if status is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Check if a user has liked this status
  bool isLikedBy(String userId) => likeUIDs.contains(userId);

  // Check if a user has viewed this status
  bool isViewedBy(String userId) => viewerUIDs.contains(userId);

  // Clone with method for updating status data
  StatusPostModel copyWith({
    String? statusId,
    String? uid,
    String? username,
    String? userImage,
    List<String>? mediaUrls,
    String? caption,
    StatusType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewerUIDs,
    int? viewCount,
    List<String>? likeUIDs,
    bool? isPrivate,
    List<String>? allowedContactUIDs,
    bool? isContactsOnly,
  }) {
    return StatusPostModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      caption: caption ?? this.caption,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerUIDs: viewerUIDs ?? this.viewerUIDs,
      viewCount: viewCount ?? this.viewCount,
      likeUIDs: likeUIDs ?? this.likeUIDs,
      isPrivate: isPrivate ?? this.isPrivate,
      allowedContactUIDs: allowedContactUIDs ?? this.allowedContactUIDs,
      isContactsOnly: isContactsOnly ?? this.isContactsOnly,
    );
  }
}

// Status comment model for the robust comment system
class StatusCommentModel {
  final String commentId;
  final String statusId;
  final String uid;
  final String username;
  final String userImage;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId; // For replies to comments
  final List<String> likeUIDs;

  StatusCommentModel({
    required this.commentId,
    required this.statusId, 
    required this.uid,
    required this.username,
    required this.userImage,
    required this.text,
    required this.createdAt,
    this.parentCommentId,
    required this.likeUIDs,
  });

  // Factory constructor to create a StatusCommentModel from a map
  factory StatusCommentModel.fromMap(Map<String, dynamic> map) {
    return StatusCommentModel(
      commentId: map['commentId'] ?? '',
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      parentCommentId: map['parentCommentId'],
      likeUIDs: List<String>.from(map['likeUIDs'] ?? []),
    );
  }

  // Method to convert StatusCommentModel to a map
  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      Constants.statusId: statusId,
      Constants.uid: uid,
      Constants.name: username,
      Constants.image: userImage,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'parentCommentId': parentCommentId,
      'likeUIDs': likeUIDs,
    };
  }

  // Getter for like count
  int get likeCount => likeUIDs.length;

  // Check if a user has liked this comment
  bool isLikedBy(String userId) => likeUIDs.contains(userId);
  
  // Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;
}

// Enum for Status type (importing from enums.dart)
enum StatusType {
  text,
  image,
  video,
}

// Extension on StatusType
extension StatusTypeExtension on StatusType {
  String get name {
    switch (this) {
      case StatusType.text:
        return 'text';
      case StatusType.image:
        return 'image';
      case StatusType.video:
        return 'video';
      default:
        return 'text';
    }
  }
  
  static StatusType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return StatusType.image;
      case 'video':
        return StatusType.video;
      case 'text':
      default:
        return StatusType.text;
    }
  }
}