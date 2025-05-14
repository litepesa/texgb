import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String statusId;
  final String uid;
  final String username;
  final String userImage;
  final String content;
  final StatusType type;
  final String timestamp;
  final List<String> seenBy;
  final StatusPrivacyType privacyType;
  final List<String> privacyUIDs; // UIDs for except/only privacy settings
  final Map<String, dynamic>? metadata; // For additional type-specific data
  final String? caption;

  StatusModel({
    required this.statusId,
    required this.uid,
    required this.username,
    required this.userImage,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.seenBy,
    required this.privacyType,
    required this.privacyUIDs,
    this.metadata,
    this.caption,
  });

  // Create from map (for Firestore)
  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      uid: map[Constants.uid] ?? '',
      username: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      content: map['content'] ?? '',
      type: StatusTypeExtension.fromString(map[Constants.statusType] ?? 'text'),
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      privacyType: StatusPrivacyTypeExtension.fromString(map['privacyType'] ?? 'all_contacts'),
      privacyUIDs: List<String>.from(map['privacyUIDs'] ?? []),
      metadata: map['metadata'],
      caption: map['caption'],
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      Constants.uid: uid,
      Constants.name: username,
      Constants.image: userImage,
      'content': content,
      Constants.statusType: type.name,
      'timestamp': timestamp,
      'seenBy': seenBy,
      'privacyType': privacyType.toString().split('.').last,
      'privacyUIDs': privacyUIDs,
      'metadata': metadata,
      'caption': caption,
    };
  }

  // Create a copy with some fields updated
  StatusModel copyWith({
    String? statusId,
    String? uid,
    String? username,
    String? userImage,
    String? content,
    StatusType? type,
    String? timestamp,
    List<String>? seenBy,
    StatusPrivacyType? privacyType,
    List<String>? privacyUIDs,
    Map<String, dynamic>? metadata,
    String? caption,
  }) {
    return StatusModel(
      statusId: statusId ?? this.statusId,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      seenBy: seenBy ?? List.from(this.seenBy),
      privacyType: privacyType ?? this.privacyType,
      privacyUIDs: privacyUIDs ?? List.from(this.privacyUIDs),
      metadata: metadata ?? this.metadata,
      caption: caption ?? this.caption,
    );
  }

  // Check if a user can view this status
  bool canViewStatus(String viewerUID, List<String> contactsUIDs) {
    // Status creator can always view their own status
    if (viewerUID == uid) return true;

    // Check if viewer is in user's contacts
    final isContact = contactsUIDs.contains(viewerUID);
    
    // Apply privacy rules
    switch (privacyType) {
      case StatusPrivacyType.all_contacts:
        return isContact;
      case StatusPrivacyType.except:
        return isContact && !privacyUIDs.contains(viewerUID);
      case StatusPrivacyType.only:
        return privacyUIDs.contains(viewerUID);
    }
  }

  // Get duration since posting for display
  String get timeAgo {
    final now = DateTime.now();
    final posted = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final difference = now.difference(posted);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      // Status older than 24 hours would typically be expired in WhatsApp
      return 'Expired';
    }
  }

  // Check if status is expired (older than 24 hours)
  bool get isExpired {
    final now = DateTime.now();
    final posted = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final difference = now.difference(posted);
    
    return difference.inHours >= 24;
  }
}