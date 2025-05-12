import 'package:textgb/enums/enums.dart';

class DraftMessageModel {
  final String contactUID; // The contact this draft is for
  final String message; // The draft message content
  final MessageEnum messageType; // Type of message
  final int lastEdited; // Timestamp when the draft was last edited
  final String? repliedMessage; // For drafts that are replies to messages
  final String? repliedTo; // UID of the user being replied to
  final MessageEnum? repliedMessageType; // Type of the message being replied to
  final String? mediaPath; // Local path to any media being attached
  final Map<String, dynamic>? attachmentData; // Additional data for attachments

  const DraftMessageModel({
    required this.contactUID,
    required this.message,
    required this.messageType,
    required this.lastEdited,
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    this.mediaPath,
    this.attachmentData,
  });

  factory DraftMessageModel.fromMap(Map<String, dynamic> map) {
    return DraftMessageModel(
      contactUID: map['contactUID'] ?? '',
      message: map['message'] ?? '',
      messageType: MessageEnumExtension(map['messageType'] ?? 'text').toMessageEnum(),
      lastEdited: map['lastEdited'] ?? DateTime.now().millisecondsSinceEpoch,
      repliedMessage: map['repliedMessage'],
      repliedTo: map['repliedTo'],
      repliedMessageType: map['repliedMessageType'] != null
          ? MessageEnumExtension(map['repliedMessageType']).toMessageEnum()
          : null,
      mediaPath: map['mediaPath'],
      attachmentData: map['attachmentData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactUID': contactUID,
      'message': message,
      'messageType': messageType.name,
      'lastEdited': lastEdited,
      'repliedMessage': repliedMessage,
      'repliedTo': repliedTo,
      'repliedMessageType': repliedMessageType?.name,
      'mediaPath': mediaPath,
      'attachmentData': attachmentData,
    };
  }

  // Copy with method for creating a new instance with updated fields
  DraftMessageModel copyWith({
    String? contactUID,
    String? message,
    MessageEnum? messageType,
    int? lastEdited,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    String? mediaPath,
    Map<String, dynamic>? attachmentData,
  }) {
    return DraftMessageModel(
      contactUID: contactUID ?? this.contactUID,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      lastEdited: lastEdited ?? this.lastEdited,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      mediaPath: mediaPath ?? this.mediaPath,
      attachmentData: attachmentData ?? this.attachmentData,
    );
  }
}