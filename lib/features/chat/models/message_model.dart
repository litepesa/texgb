// Enhanced Message Model with Status Reply Support
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
  final MessageStatus messageStatus;
  final String? repliedMessage;
  final String? repliedTo;
  final MessageEnum? repliedMessageType;
  final String? statusContext;
  final List<String> deletedBy;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final String? originalMessage;
  final String? editedAt;
  final Map<String, Map<String, String>> reactions;
  
  // Enhanced status reply fields
  final bool isStatusReply;
  final String? statusThumbnailUrl;
  final StatusType? statusType;
  final String? statusId;
  final String? statusCaption;

  // Compatibility properties
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
    this.isStatusReply = false,
    this.statusThumbnailUrl,
    this.statusType,
    this.statusId,
    this.statusCaption,
  }) : this.reactions = reactions ?? {};

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    try {
      return MessageModel(
        messageId: map[Constants.messageId]?.toString() ?? '',
        senderUID: map[Constants.senderUID]?.toString() ?? '',
        senderName: map[Constants.senderName]?.toString() ?? '',
        senderImage: map[Constants.senderImage]?.toString() ?? '',
        message: map[Constants.message]?.toString() ?? '',
        messageType: ((map[Constants.messageType] as String?) ?? 'text').toMessageEnum(),
        timeSent: map[Constants.timeSent]?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
        messageStatus: map['messageStatus'] != null 
            ? MessageStatus.fromString(map['messageStatus'].toString()) 
            : (map['isDelivered'] == true 
                ? MessageStatus.delivered 
                : (map['isSent'] == true ? MessageStatus.sent : MessageStatus.sending)),
        repliedMessage: map[Constants.repliedMessage]?.toString(),
        repliedTo: map[Constants.repliedTo]?.toString(),
        repliedMessageType: map[Constants.repliedMessageType] != null
            ? (map[Constants.repliedMessageType].toString()).toMessageEnum()
            : null,
        statusContext: map[Constants.statusContext]?.toString(),
        deletedBy: (map[Constants.deletedBy] as List?)
            ?.map((item) => item.toString())
            .toList()
            .cast<String>() ?? [],
        isDeletedForEveryone: map['isDeletedForEveryone'] == true,
        isEdited: map['isEdited'] == true,
        originalMessage: map['originalMessage']?.toString(),
        editedAt: map['editedAt']?.toString(),
        reactions: map['reactions'] != null
            ? _parseReactionsMap(map['reactions'])
            : {},
        // Enhanced status reply fields
        isStatusReply: map['isStatusReply'] == true,
        statusThumbnailUrl: map['statusThumbnailUrl']?.toString(),
        statusType: map['statusType'] != null 
            ? StatusTypeExtension.fromString(map['statusType'].toString())
            : null,
        statusId: map['statusId']?.toString(),
        statusCaption: map['statusCaption']?.toString(),
      );
    } catch (e, stackTrace) {
      print('Error parsing MessageModel: $e');
      print('Map data: $map');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Map<String, Map<String, String>> _parseReactionsMap(dynamic reactions) {
    if (reactions is! Map) {
      return {};
    }

    try {
      return Map<String, Map<String, String>>.from(
        reactions.map((key, value) {
          if (value is! Map) {
            return MapEntry(key.toString(), <String, String>{});
          }
          
          return MapEntry(
            key.toString(),
            Map<String, String>.from(
              value.map((k, v) => MapEntry(k.toString(), v.toString()))
            ),
          );
        }),
      );
    } catch (e) {
      print('Error parsing reactions map: $e');
      return {};
    }
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
      // Enhanced status reply fields
      'isStatusReply': isStatusReply,
      'statusThumbnailUrl': statusThumbnailUrl,
      'statusType': statusType?.name,
      'statusId': statusId,
      'statusCaption': statusCaption,
    };

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
    bool? isStatusReply,
    String? statusThumbnailUrl,
    StatusType? statusType,
    String? statusId,
    String? statusCaption,
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
      isStatusReply: isStatusReply ?? this.isStatusReply,
      statusThumbnailUrl: statusThumbnailUrl ?? this.statusThumbnailUrl,
      statusType: statusType ?? this.statusType,
      statusId: statusId ?? this.statusId,
      statusCaption: statusCaption ?? this.statusCaption,
    );
  }
  
  // Helper methods remain the same...
  MessageModel addReaction(String userId, String emoji) {
    final newReactions = Map<String, Map<String, String>>.from(reactions);
    newReactions[userId] = {
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    return copyWith(reactions: newReactions);
  }
  
  MessageModel removeReaction(String userId) {
    final newReactions = Map<String, Map<String, String>>.from(reactions);
    newReactions.remove(userId);
    
    return copyWith(reactions: newReactions);
  }
  
  MessageModel updateStatus(MessageStatus newStatus) {
    return copyWith(messageStatus: newStatus);
  }
  
  MessageModel markAsEdited(String newMessage) {
    return copyWith(
      message: newMessage,
      isEdited: true,
      originalMessage: originalMessage ?? message,
      editedAt: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
  
  MessageModel markAsDeletedFor(String userId) {
    if (deletedBy.contains(userId)) {
      return this;
    }
    
    final newDeletedBy = List<String>.from(deletedBy);
    newDeletedBy.add(userId);
    
    return copyWith(deletedBy: newDeletedBy);
  }
  
  MessageModel markAsDeletedForEveryone() {
    return copyWith(isDeletedForEveryone: true);
  }
  
  bool isDeletedFor(String userId) {
    return deletedBy.contains(userId) || isDeletedForEveryone;
  }
  
  bool shouldShowFor(String userId) {
    return !isDeletedFor(userId);
  }
}