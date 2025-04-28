// lib/features/status/status_post_model.dart

import 'package:flutter/material.dart';
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
  
  // Privacy settings
  final StatusPrivacyType privacyType;
  final List<String> includedContactUIDs;
  final List<String> excludedContactUIDs;
  
  // Additional properties for specific status types
  final Color? backgroundColor; // For text status
  final String? fontName; // For text status
  final String? linkUrl; // For link status
  final String? linkPreviewImage; // For link status
  final String? linkPreviewTitle; // For link status
  final String? linkPreviewDescription; // For link status

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
    this.privacyType = StatusPrivacyType.all_contacts,
    this.includedContactUIDs = const [],
    this.excludedContactUIDs = const [],
    this.backgroundColor,
    this.fontName,
    this.linkUrl,
    this.linkPreviewImage,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
  });

  factory StatusPostModel.fromMap(Map<String, dynamic> map) {
    final mediaUrls = List<String>.from(map['mediaUrls'] ?? []);
    final rawType = map[Constants.statusType] ?? 'text';
    
    // Default privacy type
    StatusPrivacyType privacyType = StatusPrivacyType.all_contacts;
    
    // Try to detect privacy type from the map
    if (map.containsKey('privacyType')) {
      final privacyTypeStr = map['privacyType'];
      if (privacyTypeStr is String) {
        privacyType = StatusPrivacyTypeExtension.fromString(privacyTypeStr);
      }
    } else {
      // Backward compatibility: determine from isPrivate and isContactsOnly
      final isPrivate = map['isPrivate'] ?? false;
      final isContactsOnly = map['isContactsOnly'] ?? false;
      
      if (!isPrivate) {
        privacyType = StatusPrivacyType.all_contacts;
      } else if (isContactsOnly) {
        privacyType = StatusPrivacyType.except;
      } else {
        privacyType = StatusPrivacyType.only;
      }
    }
    
    // Handle included and excluded contacts
    final includedContactUIDs = List<String>.from(map['includedContactUIDs'] ?? []);
    final excludedContactUIDs = List<String>.from(map['excludedContactUIDs'] ?? []);
    
    // For backward compatibility, also check allowedContactUIDs
    if (includedContactUIDs.isEmpty && map.containsKey('allowedContactUIDs')) {
      includedContactUIDs.addAll(List<String>.from(map['allowedContactUIDs'] ?? []));
    }
    
    // Auto-detect type based on media URLs if not explicitly specified
    final detectedType = mediaUrls.isNotEmpty 
        ? (_isVideoUrl(mediaUrls.first) 
            ? StatusType.video 
            : StatusType.image)
        : (map.containsKey('linkUrl') && map['linkUrl'] != null) 
            ? StatusType.link 
            : StatusType.text;
    
    // Parse status type
    StatusType statusType;
    if (rawType != 'text') {
      statusType = StatusTypeExtension.fromString(rawType);
    } else {
      statusType = detectedType;
    }
    
    // Parse color for text status
    Color? backgroundColor;
    if (map.containsKey('backgroundColor') && map['backgroundColor'] != null) {
      final colorValue = map['backgroundColor'];
      if (colorValue is int) {
        backgroundColor = Color(colorValue);
      }
    }

    return StatusPostModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      mediaUrls: mediaUrls,
      caption: map['caption'] ?? '',
      type: statusType,
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
      privacyType: privacyType,
      includedContactUIDs: includedContactUIDs,
      excludedContactUIDs: excludedContactUIDs,
      backgroundColor: backgroundColor,
      fontName: map['fontName'],
      linkUrl: map['linkUrl'],
      linkPreviewImage: map['linkPreviewImage'],
      linkPreviewTitle: map['linkPreviewTitle'],
      linkPreviewDescription: map['linkPreviewDescription'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
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
      'privacyType': privacyType.name,
      'includedContactUIDs': includedContactUIDs,
      'excludedContactUIDs': excludedContactUIDs,
    };
    
    // Add type-specific properties
    if (backgroundColor != null) {
      map['backgroundColor'] = backgroundColor!.value;
    }
    
    if (fontName != null) {
      map['fontName'] = fontName;
    }
    
    if (linkUrl != null) {
      map['linkUrl'] = linkUrl;
    }
    
    if (linkPreviewImage != null) {
      map['linkPreviewImage'] = linkPreviewImage;
    }
    
    if (linkPreviewTitle != null) {
      map['linkPreviewTitle'] = linkPreviewTitle;
    }
    
    if (linkPreviewDescription != null) {
      map['linkPreviewDescription'] = linkPreviewDescription;
    }
    
    return map;
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
    if (mediaUrls.isEmpty) return type == StatusType.text || type == StatusType.link;
    
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
  
  /// Check if user can view the status based on privacy settings
  bool canBeViewedBy(String viewerUid, List<String> viewerContacts) {
    // Owner can always view their own status
    if (viewerUid == uid) return true;
    
    // Check privacy settings
    switch (privacyType) {
      case StatusPrivacyType.except:
        // "My contacts except..." - viewable by all contacts except those in the excluded list
        return viewerContacts.contains(uid) && !excludedContactUIDs.contains(viewerUid);
        
      case StatusPrivacyType.only:
        // "Only share with..." - viewable only by those in the included list
        return includedContactUIDs.contains(viewerUid);
        
      case StatusPrivacyType.all_contacts:
      default:
        // Viewable by all contacts
        return viewerContacts.contains(uid);
    }
  }
  
  /// Get a display string for the privacy setting
  String getPrivacyDisplayText() {
    switch (privacyType) {
      case StatusPrivacyType.except:
        final count = excludedContactUIDs.length;
        return 'My contacts except $count ${count == 1 ? 'person' : 'people'}';
        
      case StatusPrivacyType.only:
        final count = includedContactUIDs.length;
        return 'Only $count ${count == 1 ? 'person' : 'people'}';
        
      case StatusPrivacyType.all_contacts:
      default:
        return 'My contacts';
    }
  }

  /// Create a copy of this model with updated fields
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
    StatusPrivacyType? privacyType,
    List<String>? includedContactUIDs,
    List<String>? excludedContactUIDs,
    Color? backgroundColor,
    String? fontName,
    String? linkUrl,
    String? linkPreviewImage,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
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
      privacyType: privacyType ?? this.privacyType,
      includedContactUIDs: includedContactUIDs ?? this.includedContactUIDs,
      excludedContactUIDs: excludedContactUIDs ?? this.excludedContactUIDs,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontName: fontName ?? this.fontName,
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreviewImage: linkPreviewImage ?? this.linkPreviewImage,
      linkPreviewTitle: linkPreviewTitle ?? this.linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription ?? this.linkPreviewDescription,
    );
  }
}