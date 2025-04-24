import 'package:cloud_firestore/cloud_firestore.dart';

class StatusReplyModel {
  final String replyId;
  final String statusId;
  final String statusItemId;
  final String statusOwnerId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String message;
  final String statusThumbnailUrl;
  final String statusCaption;
  final DateTime timestamp;
  final bool isRead;

  StatusReplyModel({
    required this.replyId,
    required this.statusId,
    required this.statusItemId,
    required this.statusOwnerId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.message,
    required this.statusThumbnailUrl,
    required this.statusCaption,
    required this.timestamp,
    required this.isRead,
  });

  // Create from map (Firestore document)
  factory StatusReplyModel.fromMap(Map<String, dynamic> map) {
    return StatusReplyModel(
      replyId: map['replyId'] ?? '',
      statusId: map['statusId'] ?? '',
      statusItemId: map['statusItemId'] ?? '',
      statusOwnerId: map['statusOwnerId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] ?? '',
      message: map['message'] ?? '',
      statusThumbnailUrl: map['statusThumbnailUrl'] ?? '',
      statusCaption: map['statusCaption'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'replyId': replyId,
      'statusId': statusId,
      'statusItemId': statusItemId,
      'statusOwnerId': statusOwnerId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'message': message,
      'statusThumbnailUrl': statusThumbnailUrl,
      'statusCaption': statusCaption,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
}