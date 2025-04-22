import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String statusId;
  final String uid;
  final String userName;
  final String userImage;
  final String text;
  final String mediaUrl;
  final StatusType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isPrivate;
  final List<String> viewedBy;
  final List<String> likedBy;
  final Map<String, String> backgroundInfo; // For text status - color, font, etc.

  StatusModel({
    required this.statusId,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.mediaUrl,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    required this.isPrivate,
    required this.viewedBy,
    required this.likedBy,
    required this.backgroundInfo,
  });

  // Create from map (Firestore document)
  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      text: map[Constants.message] ?? '',
      mediaUrl: map[Constants.mediaUrls] != null && map[Constants.mediaUrls].isNotEmpty 
          ? map[Constants.mediaUrls][0] 
          : '',
      type: _getStatusTypeFromString(map[Constants.statusType] ?? 'text'),
      createdAt: _parseDateTime(map[Constants.createdAt]),
      expiresAt: _parseDateTime(map[Constants.createdAt], addHours: 24), // Status expires in 24 hours
      isPrivate: map['isPrivate'] ?? true,
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      backgroundInfo: Map<String, String>.from(map['backgroundInfo'] ?? {}),
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      Constants.statusId: statusId,
      Constants.uid: uid,
      Constants.name: userName,
      Constants.image: userImage,
      Constants.message: text,
      Constants.mediaUrls: mediaUrl.isNotEmpty ? [mediaUrl] : [],
      Constants.statusType: type.toString().split('.').last,
      Constants.createdAt: createdAt.millisecondsSinceEpoch,
      'isPrivate': isPrivate,
      'viewedBy': viewedBy,
      'likedBy': likedBy,
      'backgroundInfo': backgroundInfo,
    };
  }

  // Create a copy with changes
  StatusModel copyWith({
    String? statusId,
    String? uid,
    String? userName,
    String? userImage,
    String? text,
    String? mediaUrl,
    StatusType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isPrivate,
    List<String>? viewedBy,
    List<String>? likedBy,
    Map<String, String>? backgroundInfo,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPrivate: isPrivate ?? this.isPrivate,
      viewedBy: viewedBy ?? this.viewedBy,
      likedBy: likedBy ?? this.likedBy,
      backgroundInfo: backgroundInfo ?? this.backgroundInfo,
    );
  }

  // Helper method to parse DateTime from Firestore
  static DateTime _parseDateTime(dynamic timestamp, {int addHours = 0}) {
    DateTime dateTime;
    
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      dateTime = DateTime.now();
    }
    
    if (addHours > 0) {
      dateTime = dateTime.add(Duration(hours: addHours));
    }
    
    return dateTime;
  }

  // Helper to convert string to StatusType enum
  static StatusType _getStatusTypeFromString(String typeString) {
    switch (typeString) {
      case 'image':
        return StatusType.image;
      case 'video':
        return StatusType.video;
      case 'text':
      default:
        return StatusType.text;
    }
  }

  // Check if status is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  // Get view count
  int get viewCount => viewedBy.length;
  
  // Get like count
  int get likeCount => likedBy.length;
  
  // Check if user has viewed this status
  bool isViewedBy(String userId) => viewedBy.contains(userId);
  
  // Check if user has liked this status
  bool isLikedBy(String userId) => likedBy.contains(userId);
}