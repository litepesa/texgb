// lib/features/chat/models/message_model.dart

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
  final MessageStatus messageStatus; // For enhanced status tracking
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  final String? statusContext;
  final List<String> deletedBy;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final String? originalMessage;
  final String? editedAt; // Track when message was edited
  final Map<String, Map<String, String>> reactions;

  // Add compatibility properties for backward compatibility
  bool get isDelivered => messageStatus.isDelivered;
  bool get isRead => messageStatus.isRead;
  bool get isSent => messageStatus.isSent;
  bool get isFailed => messageStatus.isFailed;

  MessageModel({
    required this.messageId,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.message,
    required this.messageType,
    required this.timeSent,
    this.messageStatus = MessageStatus.sending,
    this.repliedMessage,
    this.repliedTo,
    this.repliedMessageType,
    this.statusContext,
    required this.deletedBy,
    this.isDeletedForEveryone = false,
    this.isEdited = false,
    this.originalMessage,
    this.editedAt,
    Map<String, Map<String, String>>? reactions,
  }) : this.reactions = reactions ?? {};

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map[Constants.messageId] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      timeSent: map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      messageStatus: map['messageStatus'] != null 
          ? MessageStatus.fromString(map['messageStatus']) 
          : (map['isDelivered'] == true 
              ? MessageStatus.delivered 
              : (map['isSent'] == true ? MessageStatus.sent : MessageStatus.sending)),
      repliedMessage: map[Constants.repliedMessage],
      repliedTo: map[Constants.repliedTo],
      repliedMessageType: map[Constants.repliedMessageType] != null
          ? (map[Constants.repliedMessageType] as String).toMessageEnum()
          : null,
      statusContext: map[Constants.statusContext],
      deletedBy: List<String>.from(map[Constants.deletedBy] ?? []),
      isDeletedForEveryone: map['isDeletedForEveryone'] ?? false,
      isEdited: map['isEdited'] ?? false,
      originalMessage: map['originalMessage'],
      editedAt: map['editedAt'],
      reactions: map['reactions'] != null
          ? Map<String, Map<String, String>>.from(
              map['reactions'].map((key, value) => MapEntry(
                key,
                Map<String, String>.from(value),
              )),
            )
          : {},
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
      'messageStatus': messageStatus.name,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType?.name,
      Constants.deletedBy: deletedBy,
      'isDeletedForEveryone': isDeletedForEveryone,
      'isEdited': isEdited,
      'originalMessage': originalMessage,
      'editedAt': editedAt,
      'reactions': reactions,
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
    MessageStatus? messageStatus,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    String? statusContext,
    List<String>? deletedBy,
    bool? isDeletedForEveryone,
    bool? isEdited,
    String? originalMessage,
    String? editedAt,
    Map<String, Map<String, String>>? reactions,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderUID: senderUID ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timeSent: timeSent ?? this.timeSent,
      messageStatus: messageStatus ?? this.messageStatus,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      statusContext: statusContext ?? this.statusContext,
      deletedBy: deletedBy ?? List.from(this.deletedBy),
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      originalMessage: originalMessage ?? this.originalMessage,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? Map.from(this.reactions),
    );
  }
  
  // Helper method to add a reaction
  MessageModel addReaction(String userId, String emoji) {
    final newReactions = Map<String, Map<String, String>>.from(reactions);
    newReactions[userId] = {
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    return copyWith(reactions: newReactions);
  }
  
  // Helper method to remove a reaction
  MessageModel removeReaction(String userId) {
    final newReactions = Map<String, Map<String, String>>.from(reactions);
    newReactions.remove(userId);
    
    return copyWith(reactions: newReactions);
  }
  
  // Helper method to update message status
  MessageModel updateStatus(MessageStatus newStatus) {
    return copyWith(messageStatus: newStatus);
  }
  
  // Helper method to mark message as edited
  MessageModel markAsEdited(String newMessage) {
    return copyWith(
      message: newMessage,
      isEdited: true,
      originalMessage: originalMessage ?? message,
      editedAt: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
  
  // Helper method to mark message as deleted for a user
  MessageModel markAsDeletedFor(String userId) {
    if (deletedBy.contains(userId)) {
      return this;
    }
    
    final newDeletedBy = List<String>.from(deletedBy);
    newDeletedBy.add(userId);
    
    return copyWith(deletedBy: newDeletedBy);
  }
  
  // Helper method to mark message as deleted for everyone
  MessageModel markAsDeletedForEveryone() {
    return copyWith(isDeletedForEveryone: true);
  }
  
  // Helper method to check if message is deleted for a user
  bool isDeletedFor(String userId) {
    return deletedBy.contains(userId) || isDeletedForEveryone;
  }
  
  // Helper method to check if message should be shown in UI
  bool shouldShowFor(String userId) {
    return !isDeletedFor(userId);
  }
}