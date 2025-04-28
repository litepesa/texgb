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
          : DateTime.now().add(const Duration(hours: 24)),
      viewerUIDs: List<String>.from(map['viewerUIDs'] ?? []),
      viewCount: map[Constants.statusViewCount] ?? 0,
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

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool isViewedBy(String userId) => viewerUIDs.contains(userId);
  
  // Simple check if user can view the status (basic implementation)
  bool canBeViewedBy(String viewerUid, List<String> viewerContacts) {
    // Owner can always view
    if (viewerUid == uid) return true;
    
    // If not owner and status is private, check access
    if (isPrivate) {
      if (isContactsOnly) {
        return viewerContacts.contains(uid);
      } else {
        return allowedContactUIDs.contains(viewerUid);
      }
    }
    
    // Public status
    return true;
  }

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
      isPrivate: isPrivate ?? this.isPrivate,
      allowedContactUIDs: allowedContactUIDs ?? this.allowedContactUIDs,
      isContactsOnly: isContactsOnly ?? this.isContactsOnly,
    );
  }
}