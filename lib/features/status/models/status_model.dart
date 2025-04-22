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
    // Get createdAt timestamp
    final createdAtDateTime = _parseDateTime(map[Constants.createdAt]);
    
    // Calculate expiresAt - always exactly 24 hours after creation
    final expiresAtDateTime = createdAtDateTime.add(const Duration(hours: 24));
    
    return StatusModel(
      statusId: map[Constants.statusId] ?? '',
      uid: map[Constants.uid] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      text: map[Constants.message] ?? '',
      mediaUrl: map[Constants.statusUrl] != null && (map[Constants.statusUrl] as List).isNotEmpty 
          ? map[Constants.statusUrl][0] 
          : '',
      type: _getStatusTypeFromString(map[Constants.statusType] ?? 'text'),
      createdAt: createdAtDateTime,
      expiresAt: expiresAtDateTime,
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
      Constants.statusUrl: mediaUrl.isNotEmpty ? [mediaUrl] : [],
      Constants.statusType: type.toString().split('.').last,
      Constants.createdAt: Timestamp.fromDate(createdAt), // Store as Firestore Timestamp
      'expiresAt': Timestamp.fromDate(expiresAt), // Store expiry as Timestamp too
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
  static DateTime _parseDateTime(dynamic timestamp) {
    DateTime dateTime;
    
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      dateTime = DateTime.now();
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
  
  // Calculate remaining time in hours and minutes
  String get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return 'Expired';
    }
    
    final difference = expiresAt.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    
    if (hours > 0) {
      return 'Expires in ${hours}h ${minutes}m';
    } else {
      return 'Expires in ${minutes}m';
    }
  }
  
  // Get remaining time as percentage (for progress indicators)
  double get remainingTimePercentage {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return 0.0;
    }
    
    final totalDuration = const Duration(hours: 24).inMilliseconds;
    final elapsed = now.difference(createdAt).inMilliseconds;
    final remaining = totalDuration - elapsed;
    
    return remaining / totalDuration;
  }
  
  // Get view count
  int get viewCount => viewedBy.length;
  
  // Get like count
  int get likeCount => likedBy.length;
  
  // Check if user has viewed this status
  bool isViewedBy(String userId) => viewedBy.contains(userId);
  
  // Check if user has liked this status
  bool isLikedBy(String userId) => likedBy.contains(userId);
}