// lib/features/chat/models/message_model.dart
// Instead of completely changing the model structure, we'll extend it more safely

import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class MessageModel {
  final String messageId;
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String message;
  final MessageEnum messageType;
  final String timeSent;
  final bool isSeen;
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  // Add statusContext with a safe default value of null
  final String? statusContext; 
  final List<String> seenBy;
  final List<String> deletedBy;

  MessageModel({
    required this.messageId,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    this.statusContext, // Optional parameter with default value of null
    required this.seenBy,
    required this.deletedBy,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map[Constants.messageId] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      timeSent: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage],
      repliedTo: map[Constants.repliedTo],
      repliedMessageType: map[Constants.repliedMessageType] != null
          ? (map[Constants.repliedMessageType] as String).toMessageEnum()
          : null,
      // Safely extract statusContext if present
      statusContext: map[Constants.statusContext],
      seenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> result = {
      Constants.messageId: messageId,
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType?.name,
      Constants.isSeenBy: seenBy,
      Constants.deletedBy: deletedBy,
    };

    // Only add statusContext if it exists
    if (statusContext != null) {
      result[Constants.statusContext] = statusContext;
    }

    return result;
  }

  MessageModel copyWith({
    String? messageId,
    String? senderUID,
    String? senderName,
    String? senderImage,
    String? message,
    MessageEnum? messageType,
    String? timeSent,
    bool? isSeen,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    String? statusContext,
    List<String>? seenBy,
    List<String>? deletedBy,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUID: senderUID ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timeSent: timeSent ?? this.timeSent,
      isSeen: isSeen ?? this.isSeen,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      statusContext: statusContext ?? this.statusContext,
      seenBy: seenBy ?? List.from(this.seenBy),
      deletedBy: deletedBy ?? List.from(this.deletedBy),
    );
  }
}