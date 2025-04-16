import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusModel {
  final String uid;
  final String userName;
  final String userImage;
  final String statusId;
  final String statusUrl;
  final String caption;
  final StatusType statusType;
  final DateTime createdAt;
  final List<String> viewedBy;
  final String backgroundColor; // For text statuses
  final String textColor; // For text statuses
  final String fontStyle; // For text statuses

  StatusModel({
    required this.uid,
    required this.userName,
    required this.userImage,
    required this.statusId,
    required this.statusUrl,
    required this.caption,
    required this.statusType,
    required this.createdAt,
    required this.viewedBy,
    this.backgroundColor = '#000000',
    this.textColor = '#FFFFFF',
    this.fontStyle = 'normal',
  });

  // Check if status is expired (24 hours)
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours >= 24;
  }

  // Calculate time remaining
  String get timeRemaining {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final remaining = const Duration(hours: 24) - difference;
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return 'Expires soon';
    }
  }

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.uid: uid,
      Constants.name: userName,
      Constants.image: userImage,
      'statusId': statusId,
      'statusUrl': statusUrl,
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
    return StatusModel(
      uid: map[Constants.uid] ?? '',
      userName: map[Constants.name] ?? '',
      userImage: map[Constants.image] ?? '',
      statusId: map['statusId'] ?? '',
      statusUrl: map['statusUrl'] ?? '',
      caption: map['caption'] ?? '',
      statusType: _getStatusTypeFromString(map['statusType'] ?? 'image'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      viewedBy: List<String>.from(map['viewedBy'] ?? []),
      backgroundColor: map['backgroundColor'] ?? '#000000',
      textColor: map['textColor'] ?? '#FFFFFF',
      fontStyle: map['fontStyle'] ?? 'normal',
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
}