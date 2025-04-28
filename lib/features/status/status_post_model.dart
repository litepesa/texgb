// lib/features/status/models/status_post_model.dart

import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:flutter/material.dart';

/// Represents a single status post
class StatusPostModel {
  final String statusId;         // Unique ID for the status
  final String uid;              // User ID of the creator
  final String username;         // Username of the creator
  final String userImage;        // Profile image URL of the creator
  final StatusType type;         // Type of status (image, video, text, link)
  
  // Content fields based on the type
  final List<String> mediaUrls;  // URLs for images or videos
  final String caption;          // Caption/text message
  final Color? backgroundColor;  // Background color for text status
  final String? fontName;        // Font for text status
  final String? linkUrl;         // URL for link status
  final String? linkPreviewImage; // Preview image for link
  final String? linkTitle;       // Title of the link
  
  // Time fields
  final DateTime createdAt;      // When the status was created
  final DateTime expiresAt;      // When the status will expire (createdAt + 24h)
  
  // Viewer info
  final List<String> viewerUIDs;  // List of UIDs who viewed the status
  final int viewCount;            // Number of views (cached for efficiency)
  
  // Privacy settings
  final StatusPrivacyType privacyType;          // Type of privacy setting
  final List<String> includedContactUIDs;       // Contacts who can see the status (for "only share with")
  final List<String> excludedContactUIDs;       // Contacts who can't see the status (for "except")

  StatusPostModel({
    required this.statusId,
    required this.uid,
    required this.username,
    required this.userImage,
    required this.type,
    this.mediaUrls = const [],
    this.caption = '',
    this.backgroundColor,
    this.fontName,
    this.linkUrl,
    this.linkPreviewImage,
    this.linkTitle,
    required this.createdAt,
    required this.expiresAt,
    this.viewerUIDs = const [],
    this.viewCount = 0,
    required this.privacyType,
    this.includedContactUIDs = const [],
    this.excludedContactUIDs = const [],
  });

  factory StatusPostModel.fromMap(Map<String, dynamic> map) {
    final mediaUrls = List<String>.from(map['mediaUrls'] ?? []);
    final rawType = map[Constants.statusType] ?? 'text';
    
    // Determine type based on provided data
    final StatusType statusType = StatusTypeExtension.fromString(rawType);
    
    // Parse colors from stored string value
    Color? backgroundColor;
    if (map['backgroundColor'] != null) {
      final colorValue = int.tryParse(map['backgroundColor']);
      if (colorValue != null) {
        backgroundColor = Color(colorValue);
      }
    }

    return StatusPostModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      type: statusType,
      mediaUrls: mediaUrls,
      caption: map['caption'] ?? '',
      backgroundColor: backgroundColor,
      fontName: map['fontName'],
      linkUrl: map['linkUrl'],
      linkPreviewImage: map['linkPreviewImage'],
      linkTitle: map['linkTitle'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt']) 
          : DateTime.now().add(const Duration(hours: 24)),
      viewerUIDs: List<String>.from(map['viewerUIDs'] ?? []),
      viewCount: map[Constants.statusViewCount] ?? 0,
      privacyType: StatusPrivacyTypeExtension.fromString(map['privacyType'] ?? 'all_contacts'),
      includedContactUIDs: List<String>.from(map['includedContactUIDs'] ?? []),
      excludedContactUIDs: List<String>.from(map['excludedContactUIDs'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.statusId: statusId,
      Constants.uid: uid,
      Constants.name: username,
      Constants.image: userImage,
      Constants.statusType: type.name,
      'mediaUrls': mediaUrls,
      'caption': caption,
      'backgroundColor': backgroundColor?.value.toString(),
      'fontName': fontName,
      'linkUrl': linkUrl,
      'linkPreviewImage': linkPreviewImage,
      'linkTitle': linkTitle,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'viewerUIDs': viewerUIDs,
      Constants.statusViewCount: viewCount,
      'privacyType': privacyType.name,
      'includedContactUIDs': includedContactUIDs,
      'excludedContactUIDs': excludedContactUIDs,
    };
  }

  // Check if the status is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  // Check if the user is allowed to view this status based on privacy settings
  bool canBeViewedBy(String viewerUid, List<String> viewerContacts) {
    // Creator can always view their own status
    if (viewerUid == uid) return true;
    
    switch (privacyType) {
      case StatusPrivacyType.all_contacts:
        // Can be viewed if viewer has creator as a contact
        return viewerContacts.contains(uid);
        
      case StatusPrivacyType.except:
        // Can be viewed if viewer has creator as a contact and is not excluded
        return viewerContacts.contains(uid) && !excludedContactUIDs.contains(viewerUid);
        
      case StatusPrivacyType.only:
        // Can be viewed if viewer is explicitly included
        return includedContactUIDs.contains(viewerUid);
    }
  }

  // Check if the user has viewed this status
  bool isViewedBy(String userId) => viewerUIDs.contains(userId);

  StatusPostModel copyWith({
    String? statusId,
    String? uid,
    String? username,
    String? userImage,
    StatusType? type,
    List<String>? mediaUrls,
    String? caption,
    Color? backgroundColor,
    String? fontName,
    String? linkUrl,
    String? linkPreviewImage,
    String? linkTitle,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewerUIDs,
    int? viewCount,
    StatusPrivacyType? privacyType,
    List<String>? includedContactUIDs,
    List<String>? excludedContactUIDs,
  }) {
    return StatusPostModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      type: type ?? this.type,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      caption: caption ?? this.caption,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontName: fontName ?? this.fontName,
      linkUrl: linkUrl ?? this.linkUrl,
      linkPreviewImage: linkPreviewImage ?? this.linkPreviewImage,
      linkTitle: linkTitle ?? this.linkTitle,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerUIDs: viewerUIDs ?? this.viewerUIDs,
      viewCount: viewCount ?? this.viewCount,
      privacyType: privacyType ?? this.privacyType,
      includedContactUIDs: includedContactUIDs ?? this.includedContactUIDs,
      excludedContactUIDs: excludedContactUIDs ?? this.excludedContactUIDs,
    );
  }
}

/// Represents a reply to a status post
class StatusReplyModel {
  final String replyId;         // Unique ID for the reply
  final String statusId;        // ID of the status being replied to
  final String senderUid;       // User ID of sender
  final String senderName;      // Username of sender
  final String senderImage;     // Profile image URL of sender
  final String recipientUid;    // User ID of recipient (status creator)
  final String message;         // Reply message
  final DateTime timestamp;     // When the reply was sent
  final bool isRead;            // Whether the reply has been read

  StatusReplyModel({
    required this.replyId,
    required this.statusId,
    required this.senderUid,
    required this.senderName,
    required this.senderImage,
    required this.recipientUid,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory StatusReplyModel.fromMap(Map<String, dynamic> map) {
    return StatusReplyModel(
      replyId: map['replyId'] ?? '',
      statusId: map[Constants.statusId] ?? '',
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] ?? '',
      recipientUid: map['recipientUid'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'replyId': replyId,
      Constants.statusId: statusId,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderImage': senderImage,
      'recipientUid': recipientUid,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  StatusReplyModel copyWith({
    String? replyId,
    String? statusId,
    String? senderUid,
    String? senderName,
    String? senderImage,
    String? recipientUid,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return StatusReplyModel(
      replyId: replyId ?? this.replyId,
      statusId: statusId ?? this.statusId,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      recipientUid: recipientUid ?? this.recipientUid,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}