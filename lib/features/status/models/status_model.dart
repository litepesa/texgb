import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String uid;
  final String userName;
  final String userImage;
  final String statusId;
  final String statusUrl; // Keep for backward compatibility
  final List<String> mediaUrls; // New field for multiple media files
  final String caption;
  final StatusType statusType;
  final DateTime createdAt;
  final List<String> viewedBy;
  final String backgroundColor; // For text statuses
  final String textColor; // For text statuses
  final String fontStyle; // For text statuses
  final int currentMediaIndex; // Track current media when viewing multiple

  StatusModel({
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.statusId,
    required this.statusUrl,
    this.mediaUrls = const [], // Default to empty list
    required this.caption,
    required this.statusType,
    required this.createdAt,
    required this.viewedBy,
    this.backgroundColor = '#000000',
    this.textColor = '#FFFFFF',
    this.fontStyle = 'normal',
    this.currentMediaIndex = 0,
  });

  // Check if status is expired (72 hours)
  bool get isExpired {
    final now = DateTime.now();
    final expirationTime = createdAt.add(const Duration(hours: 72));
    return now.isAfter(expirationTime);
  }

  // Calculate time remaining
  String get timeRemaining {
    final now = DateTime.now();
    final expirationTime = createdAt.add(const Duration(hours: 72));
    final remaining = expirationTime.difference(now);
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return 'Expires soon';
    }
  }

  // Get all media URLs (including legacy statusUrl if not in mediaUrls)
  List<String> get allMediaUrls {
    if (mediaUrls.isEmpty && statusUrl.isNotEmpty) {
      return [statusUrl];
    }
    return mediaUrls;
  }

  // Check if status has multiple media
  bool get hasMultipleMedia {
    return mediaUrls.length > 1;
  }

  // Get current media URL
  String get currentMediaUrl {
    if (mediaUrls.isEmpty) {
      return statusUrl;
    }
    
    if (currentMediaIndex >= 0 && currentMediaIndex < mediaUrls.length) {
      return mediaUrls[currentMediaIndex];
    }
    
    return mediaUrls.first;
  }

  // Create a copy with a new current media index
  StatusModel copyWithIndex(int newIndex) {
    return StatusModel(
      uid: uid,
      userName: userName,
      userImage: userImage,
      statusId: statusId,
      statusUrl: statusUrl,
      mediaUrls: mediaUrls,
      caption: caption,
      statusType: statusType,
      createdAt: createdAt,
      viewedBy: viewedBy,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontStyle: fontStyle,
      currentMediaIndex: newIndex,
    );
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: userName,
      Constants.image: userImage,
      'statusId': statusId,
      'statusUrl': statusUrl,
      'mediaUrls': mediaUrls,
      'caption': caption,
      'statusType': statusType.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'viewedBy': viewedBy,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'fontStyle': fontStyle,
    };
  }

  // from map
  factory StatusModel.fromMap(Map<String, dynamic> map) {
    // Handle the mediaUrls field, which might not exist in older documents
    List<String> mediaUrls = [];
    if (map.containsKey('mediaUrls')) {
      mediaUrls = List<String>.from(map['mediaUrls'] ?? []);
    }
    
    // If mediaUrls is empty but statusUrl exists, initialize mediaUrls with statusUrl
    if (mediaUrls.isEmpty && map['statusUrl'] != null && map['statusUrl'] != '') {
      final String statusUrl = map['statusUrl'];
      if (statusUrl.isNotEmpty) {
        mediaUrls = [statusUrl];
      }
    }

    return StatusModel(
      uid: map[Constants.uid] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      statusId: map['statusId'] ?? '',
      statusUrl: map['statusUrl'] ?? '',
      mediaUrls: mediaUrls,
      caption: map['caption'] ?? '',
      statusType: _getStatusTypeFromString(map['statusType'] ?? 'image'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      backgroundColor: map['backgroundColor'] ?? '#000000',
      textColor: map['textColor'] ?? '#FFFFFF',
      fontStyle: map['fontStyle'] ?? 'normal',
      currentMediaIndex: 0, // Always start at the first media
    );
  }

  static StatusType _getStatusTypeFromString(String type) {
    switch (type) {
      case 'text':
        return StatusType.text;
      case 'video':
        return StatusType.video;
      case 'image':
      default:
        return StatusType.image;
    }
  }
  
  // Create a copy with modified fields
  StatusModel copyWith({
    String? uid,
    String? userName,
    String? userImage,
    String? statusId,
    String? statusUrl,
    List<String>? mediaUrls,
    String? caption,
    StatusType? statusType,
    DateTime? createdAt,
    List<String>? viewedBy,
    String? backgroundColor,
    String? textColor,
    String? fontStyle,
    int? currentMediaIndex,
  }) {
    return StatusModel(
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      statusId: statusId ?? this.statusId,
      statusUrl: statusUrl ?? this.statusUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      caption: caption ?? this.caption,
      statusType: statusType ?? this.statusType,
      createdAt: createdAt ?? this.createdAt,
      viewedBy: viewedBy ?? this.viewedBy,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontStyle: fontStyle ?? this.fontStyle,
      currentMediaIndex: currentMediaIndex ?? this.currentMediaIndex,
    );
  }
}