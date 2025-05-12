import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChatMessage {
  final String messageId;
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String message;
  final MessageEnum messageType;
  final DateTime timeSent;
  final bool isSeen;
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  final List<String> isSeenBy;
  final List<String> deletedBy;
  final Map<String, String> reactions;
  final Map<String, dynamic>? mediaMetadata; // For media file details

  ChatMessage({
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
    required this.isSeenBy,
    required this.deletedBy,
    required this.reactions,
    this.mediaMetadata,
  });

  Map<String, dynamic> toMap() {
    return {
      Constants.messageId: messageId,
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent.millisecondsSinceEpoch,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType?.name,
      Constants.isSeenBy: isSeenBy,
      Constants.deletedBy: deletedBy,
      Constants.reactions: reactions,
      'mediaMetadata': mediaMetadata,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map[Constants.messageId] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] ?? 'text').toString().toMessageEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map[Constants.timeSent] ?? 0),
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage],
      repliedTo: map[Constants.repliedTo],
      repliedMessageType: map[Constants.repliedMessageType] != null
          ? (map[Constants.repliedMessageType] as String).toMessageEnum()
          : null,
      isSeenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      reactions: Map<String, String>.from(map[Constants.reactions] ?? {}),
      mediaMetadata: map['mediaMetadata'],
    );
  }

  // Create a copy with updated fields
  ChatMessage copyWith({
    String? messageId,
    String? senderUID,
    String? senderName,
    String? senderImage,
    String? message,
    MessageEnum? messageType,
    DateTime? timeSent,
    bool? isSeen,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    List<String>? isSeenBy,
    List<String>? deletedBy,
    Map<String, String>? reactions,
    Map<String, dynamic>? mediaMetadata,
  }) {
    return ChatMessage(
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
      isSeenBy: isSeenBy ?? List.from(this.isSeenBy),
      deletedBy: deletedBy ?? List.from(this.deletedBy),
      reactions: reactions ?? Map.from(this.reactions),
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
    );
  }
}
