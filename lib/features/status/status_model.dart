import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String statusId;
  final String uid;
  final String userName;
  final String userImage;
  final List<StatusItemModel> items;
  final DateTime createdAt;
  final DateTime expiresAt;

  StatusModel({
    required this.statusId,
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.items,
    required this.createdAt,
    required this.expiresAt,
  });

  // Create from map (Firestore document)
  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      uid: map['uid'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      items: List<StatusItemModel>.from(
        (map['items'] as List? ?? []).map(
          (item) => StatusItemModel.fromMap(item),
        ),
      ),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      expiresAt: (map['expiresAt'] is Timestamp)
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] ?? DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch),
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'uid': uid,
      'userName': userName,
      'userImage': userImage,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }
  
  // Check if status is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  // Check if user has viewed all status items
  bool hasUserViewedAll(String viewerId) {
    return items.every((item) => item.viewedBy.contains(viewerId));
  }
}

class StatusItemModel {
  final String itemId;
  final String mediaUrl;
  final String? caption;
  final DateTime timestamp;
  final StatusType type;
  final List<String> viewedBy;
  final Map<String, String>? reactions;

  StatusItemModel({
    required this.itemId,
    required this.mediaUrl,
    this.caption,
    required this.timestamp,
    required this.type,
    required this.viewedBy,
    this.reactions,
  });

  factory StatusItemModel.fromMap(Map<String, dynamic> map) {
    return StatusItemModel(
      itemId: map['itemId'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      caption: map['caption'],
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      type: _getStatusTypeFromString(map['type'] ?? 'text'),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      reactions: map['reactions'] != null 
          ? Map<String, String>.from(map['reactions']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.name,
      'viewedBy': viewedBy,
      'reactions': reactions,
    };
  }
  
  // Helper method to convert string to StatusType
  static StatusType _getStatusTypeFromString(String typeStr) {
    return StatusTypeExtension.fromString(typeStr);
  }
}