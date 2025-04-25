// lib/features/status/status_post_model.dart

import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

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

  factory StatusPostModel.fromMap(Map<String, dynamic> map) {
    final mediaUrls = List<String>.from(map['mediaUrls'] ?? []);
    final rawType = map[Constants.statusType] ?? 'text';
    
    // Auto-detect type based on media URLs if not explicitly specified
    final detectedType = mediaUrls.isNotEmpty 
        ? (_isVideoUrl(mediaUrls.first) 
            ? StatusType.video 
            : StatusType.image)
        : StatusType.text;

    return StatusPostModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      mediaUrls: mediaUrls,
      caption: map['caption'] ?? '',
      type: rawType != 'text' 
          ? StatusTypeExtension.fromString(rawType)
          : detectedType,
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

  // Helper method to check if URL points to a video
  static bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.mp4') || 
           lowerUrl.endsWith('.mov') || 
           lowerUrl.contains('video') ||
           lowerUrl.contains('stream');
  }

  /// Validates all media URLs in the post
  bool get hasValidMediaUrls {
    if (mediaUrls.isEmpty) return type == StatusType.text;
    
    try {
      for (final url in mediaUrls) {
        final uri = Uri.parse(url);
        if (!uri.isAbsolute) return false;
        
        // Additional validation based on type
        if (type == StatusType.video && !_isVideoUrl(url)) {
          return false;
        }
        if (type == StatusType.image && _isVideoUrl(url)) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the first media URL if valid, otherwise empty string
  String get firstValidMediaUrl {
    if (mediaUrls.isEmpty) return '';
    return hasValidMediaUrls ? mediaUrls.first : '';
  }

  int get likeCount => likeUIDs.length;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool isLikedBy(String userId) => likeUIDs.contains(userId);
  bool isViewedBy(String userId) => viewerUIDs.contains(userId);

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

class StatusCommentModel {
  final String commentId;
  final String statusId;
  final String uid;
  final String username;
  final String userImage;
  final String text;
  final DateTime createdAt;
  final String? parentCommentId;
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

  int get likeCount => likeUIDs.length;
  bool isLikedBy(String userId) => likeUIDs.contains(userId);
  bool get isReply => parentCommentId != null;
}