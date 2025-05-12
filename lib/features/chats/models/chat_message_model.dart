import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChatMessageModel {
  final String messageId;
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String contactUID;
  final String message;
  final MessageEnum messageType;
  final int timeSent;
  final bool isSeen;
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  final bool isMe;
  final Map<String, String> reactions;
  final List<String> isSeenBy;
  final List<String> deletedBy;
  final String? mediaUrl; // For storing URLs of images, videos, etc.
  final int? mediaDuration; // For audio/video duration in seconds
  final String? thumbnailUrl; // For video thumbnails
  final int? mediaSize; // Size in bytes
  final String? mediaName; // Original filename for documents
  final Map<String, dynamic>? locationData; // For location messages
  final Map<String, dynamic>? contactData; // For contact sharing

  const ChatMessageModel({
    required this.messageId,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.contactUID,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    required this.isMe,
    required this.reactions,
    required this.isSeenBy,
    required this.deletedBy,
    this.mediaUrl,
    this.mediaDuration,
    this.thumbnailUrl,
    this.mediaSize,
    this.mediaName,
    this.locationData,
    this.contactData,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      messageId: map[Constants.messageId] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      timeSent: map[Constants.timeSent] ?? 0,
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage],
      repliedTo: map[Constants.repliedTo],
      repliedMessageType: map[Constants.repliedMessageType] != null
          ? (map[Constants.repliedMessageType] as String).toMessageEnum()
          : null,
      isMe: map[Constants.isMe] ?? false,
      reactions: Map<String, String>.from(map[Constants.reactions] ?? {}),
      isSeenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      mediaUrl: map['mediaUrl'],
      mediaDuration: map['mediaDuration'],
      thumbnailUrl: map['thumbnailUrl'],
      mediaSize: map['mediaSize'],
      mediaName: map['mediaName'],
      locationData: map['locationData'],
      contactData: map['contactData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.messageId: messageId,
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.contactUID: contactUID,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType?.name,
      Constants.isMe: isMe,
      Constants.reactions: reactions,
      Constants.isSeenBy: isSeenBy,
      Constants.deletedBy: deletedBy,
      'mediaUrl': mediaUrl,
      'mediaDuration': mediaDuration,
      'thumbnailUrl': thumbnailUrl,
      'mediaSize': mediaSize,
      'mediaName': mediaName,
      'locationData': locationData,
      'contactData': contactData,
    };
  }

  // Copy with method to create a new instance with updated fields
  ChatMessageModel copyWith({
    String? messageId,
    String? senderUID,
    String? senderName,
    String? senderImage,
    String? contactUID,
    String? message,
    MessageEnum? messageType,
    int? timeSent,
    bool? isSeen,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    bool? isMe,
    Map<String, String>? reactions,
    List<String>? isSeenBy,
    List<String>? deletedBy,
    String? mediaUrl,
    int? mediaDuration,
    String? thumbnailUrl,
    int? mediaSize,
    String? mediaName,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? contactData,
  }) {
    return ChatMessageModel(
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
      isMe: isMe ?? this.isMe,
      reactions: reactions ?? Map<String, String>.from(this.reactions),
      isSeenBy: isSeenBy ?? List<String>.from(this.isSeenBy),
      deletedBy: deletedBy ?? List<String>.from(this.deletedBy),
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaDuration: mediaDuration ?? this.mediaDuration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaSize: mediaSize ?? this.mediaSize,
      mediaName: mediaName ?? this.mediaName,
      locationData: locationData ?? this.locationData,
      contactData: contactData ?? this.contactData,
    );
  }

  // Method to check if the message has been deleted by a specific user
  bool isDeletedBy(String uid) {
    return deletedBy.contains(uid);
  }
  
  // Method to check if the message contains media
  bool get hasMedia {
    return messageType.isMedia;
  }
  
  // Method to check if the message is a reply
  bool get isReply {
    return repliedMessage != null && repliedTo != null;
  }
}