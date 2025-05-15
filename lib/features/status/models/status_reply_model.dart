import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class StatusReplyModel {
  final String replyId;
  final String statusId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String receiverId;
  final String message;
  final MessageEnum messageType;
  final String timeSent;
  final String statusThumbnail; // URL of the status thumbnail image for context
  final StatusType statusType;

  StatusReplyModel({
    required this.replyId,
    required this.statusId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.statusThumbnail,
    required this.statusType,
  });

  factory StatusReplyModel.fromMap(Map<String, dynamic> map) {
    return StatusReplyModel(
      replyId: map['replyId'] ?? '',
      statusId: map[Constants.statusId] ?? '',
      senderId: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      timeSent: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      statusThumbnail: map['statusThumbnail'] ?? '',
      statusType: StatusTypeExtension.fromString(map['statusType'] ?? 'text'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'replyId': replyId,
      Constants.statusId: statusId,
      Constants.senderUID: senderId,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      'receiverId': receiverId,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent,
      'statusThumbnail': statusThumbnail,
      'statusType': statusType.name,
    };
  }
}