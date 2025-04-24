import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/enums/enums.dart';

class MessageModel {
  final String messageId;
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String contactUID;
  final String message;
  final MessageEnum messageType;
  final DateTime? timeSent;
  final bool isSeen;
  final String repliedMessage;
  final String repliedTo;
  final MessageEnum? repliedMessageType;
  final List<String> reactions;
  final List<String> isSeenBy;
  final List<String> deletedBy;
  
  // Status reply fields
  final bool isStatusReply;
  final String? statusId;
  final String? statusItemId;
  final String? statusThumbnailUrl;
  final String? statusCaption;

  MessageModel({
    required this.messageId,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.contactUID,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
    required this.repliedMessage,
    required this.repliedTo,
    required this.repliedMessageType,
    required this.reactions,
    required this.isSeenBy,
    required this.deletedBy,
    this.isStatusReply = false,
    this.statusId,
    this.statusItemId,
    this.statusThumbnailUrl,
    this.statusCaption,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      senderUID: map['senderUID'] ?? '',
      senderName: map['senderName'] ?? '',
      senderImage: map['senderImage'] ?? '',
      contactUID: map['contactUID'] ?? '',
      message: map['message'] ?? '',
      messageType: MessageEnum.values.firstWhere(
        (element) => element.name == map['messageType'],
        orElse: () => MessageEnum.text,
      ),
      timeSent: map['timeSent'] != null
          ? (map['timeSent'] is Timestamp
              ? (map['timeSent'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(map['timeSent']))
          : null,
      isSeen: map['isSeen'] ?? false,
      repliedMessage: map['repliedMessage'] ?? '',
      repliedTo: map['repliedTo'] ?? '',
      repliedMessageType: map['repliedMessageType'] != null && map['repliedMessageType'] != ''
          ? MessageEnum.values.firstWhere(
              (element) => element.name == map['repliedMessageType'],
              orElse: () => MessageEnum.text,
            )
          : null,
      reactions: List<String>.from(map['reactions'] ?? []),
      isSeenBy: List<String>.from(map['isSeenBy'] ?? []),
      deletedBy: List<String>.from(map['deletedBy'] ?? []),
      // Status reply fields
      isStatusReply: map['isStatusReply'] ?? false,
      statusId: map['statusId'],
      statusItemId: map['statusItemId'],
      statusThumbnailUrl: map['statusThumbnailUrl'],
      statusCaption: map['statusCaption'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderUID': senderUID,
      'senderName': senderName,
      'senderImage': senderImage,
      'contactUID': contactUID,
      'message': message,
      'messageType': messageType.name,
      'timeSent': timeSent?.millisecondsSinceEpoch,
      'isSeen': isSeen,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType?.name ?? '',
      'reactions': reactions,
      'isSeenBy': isSeenBy,
      'deletedBy': deletedBy,
      // Status reply fields
      'isStatusReply': isStatusReply,
      'statusId': statusId,
      'statusItemId': statusItemId,
      'statusThumbnailUrl': statusThumbnailUrl,
      'statusCaption': statusCaption,
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? userId,
    String? senderUID,
    String? senderName,
    String? senderImage,
    String? contactUID,
    String? message,
    MessageEnum? messageType,
    DateTime? timeSent,
    bool? isSeen,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    List<String>? reactions,
    List<String>? isSeenBy,
    List<String>? deletedBy,
    bool? isStatusReply,
    String? statusId,
    String? statusItemId,
    String? statusThumbnailUrl,
    String? statusCaption,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUID: userId ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      contactUID: contactUID ?? this.contactUID,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timeSent: timeSent ?? this.timeSent,
      isSeen: isSeen ?? this.isSeen,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      reactions: reactions ?? this.reactions,
      isSeenBy: isSeenBy ?? this.isSeenBy,
      deletedBy: deletedBy ?? this.deletedBy,
      isStatusReply: isStatusReply ?? this.isStatusReply,
      statusId: statusId ?? this.statusId,
      statusItemId: statusItemId ?? this.statusItemId,
      statusThumbnailUrl: statusThumbnailUrl ?? this.statusThumbnailUrl,
      statusCaption: statusCaption ?? this.statusCaption,
    );
  }
}