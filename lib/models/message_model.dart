import 'package:textgb/constants.dart';
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
  final String? statusThumbnailUrl; // New field for status thumbnail
  final String? statusCaption; // New field for status caption

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
    this.statusThumbnailUrl, // Optional status thumbnail
    this.statusCaption, // Optional status caption
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.messageId: messageId,
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.contactUID: contactUID,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType?.name ?? '',
      Constants.reactions: reactions,
      Constants.isSeenBy: isSeenBy,
      Constants.deletedBy: deletedBy,
      'statusThumbnailUrl': statusThumbnailUrl, // Add status thumbnail
      'statusCaption': statusCaption, // Add status caption
    };
  }

  // from map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map[Constants.messageId] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] == null)
          ? MessageEnum.text
          : map[Constants.messageType].toString().toMessageEnum(),
      timeSent: map[Constants.timeSent] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(map[Constants.timeSent]),
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage] ?? '',
      repliedTo: map[Constants.repliedTo] ?? '',
      repliedMessageType: map[Constants.repliedMessageType] == null ||
              map[Constants.repliedMessageType] == ''
          ? null
          : map[Constants.repliedMessageType].toString().toMessageEnum(),
      reactions: List<String>.from(map[Constants.reactions] ?? []),
      isSeenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      statusThumbnailUrl: map['statusThumbnailUrl'], // Extract status thumbnail
      statusCaption: map['statusCaption'], // Extract status caption
    );
  }

  // copy with
  MessageModel copyWith({
    String? messageId,
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
    String? userId,
    String? statusThumbnailUrl,
    String? statusCaption,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUID: senderUID ?? this.senderUID,
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
      statusThumbnailUrl: statusThumbnailUrl ?? this.statusThumbnailUrl,
      statusCaption: statusCaption ?? this.statusCaption,
    );
  }
}