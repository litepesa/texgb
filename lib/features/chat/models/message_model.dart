import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class MessageModel {
  final String messageId;
  final String senderUID;
  final String senderName;
  final String senderImage;
  String message; // Changed from final to support editing
  final MessageEnum messageType;
  final String timeSent;
  final bool isDelivered; // For delivery status only
  final String? editedAt; // New field for edit tracking
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  final String? statusContext;
  final List<String> deliveredTo; // For delivery tracking only
  final List<String> deletedBy;
  final Map<String, String> reactions; // New field for message reactions
  final bool deletedForEveryone; // Flag for messages deleted for everyone

  MessageModel({
    required this.messageId,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.message,
    required this.messageType,
    required this.timeSent,
    this.isDelivered = false,
    this.editedAt,
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    this.statusContext,
    required this.deliveredTo,
    required this.deletedBy,
    this.reactions = const {},
    this.deletedForEveryone = false,
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
      isDelivered: map[Constants.isDelivered] ?? false,
      editedAt: map[Constants.editedAt],
      repliedMessage: map[Constants.repliedMessage],
      repliedTo: map[Constants.repliedTo],
      repliedMessageType: map[Constants.repliedMessageType] != null
          ? (map[Constants.repliedMessageType] as String).toMessageEnum()
          : null,
      statusContext: map[Constants.statusContext],
      deliveredTo: List<String>.from(map[Constants.deliveredTo] ?? []),
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      reactions: Map<String, String>.from(map[Constants.reactions] ?? {}),
      deletedForEveryone: map[Constants.deletedForEveryone] ?? false,
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
      Constants.isDelivered: isDelivered,
      Constants.deliveredTo: deliveredTo,
      Constants.deletedBy: deletedBy,
      Constants.reactions: reactions,
      Constants.deletedForEveryone: deletedForEveryone,
    };

    // Only add optional fields if they exist
    if (editedAt != null) {
      result[Constants.editedAt] = editedAt;
    }
    
    if (repliedMessage != null) {
      result[Constants.repliedMessage] = repliedMessage;
    }
    
    if (repliedTo != null) {
      result[Constants.repliedTo] = repliedTo;
    }
    
    if (repliedMessageType != null) {
      result[Constants.repliedMessageType] = repliedMessageType!.name;
    }

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
    bool? isDelivered,
    String? editedAt,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    String? statusContext,
    List<String>? deliveredTo,
    List<String>? deletedBy,
    Map<String, String>? reactions,
    bool? deletedForEveryone,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUID: senderUID ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timeSent: timeSent ?? this.timeSent,
      isDelivered: isDelivered ?? this.isDelivered,
      editedAt: editedAt ?? this.editedAt,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      statusContext: statusContext ?? this.statusContext,
      deliveredTo: deliveredTo ?? List.from(this.deliveredTo),
      deletedBy: deletedBy ?? List.from(this.deletedBy),
      reactions: reactions ?? Map.from(this.reactions),
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
    );
  }
}