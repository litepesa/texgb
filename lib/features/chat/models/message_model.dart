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
  final List<String> deletedBy;
  final bool isDeletedForEveryone;
  final bool isEdited;
  final String? originalMessage;
  final String? editedAt;
  final Map<String, Map<String, String>> reactions;

  // Compatibility properties
  bool get isDelivered => messageStatus.isDelivered;
  bool get isRead => messageStatus.isRead;
  bool get isSent => messageStatus.isSent;
  bool get isFailed => messageStatus.isFailed;

  const MessageModel({
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
    this.deletedBy = const [],
    this.isDeletedForEveryone = false,
    this.isEdited = false,
    this.originalMessage,
    this.editedAt,
    this.reactions = const {},
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    try {
      return MessageModel(
        messageId: map[Constants.messageId]?.toString() ?? '',
        senderUID: map[Constants.senderUID]?.toString() ?? '',
        senderName: map[Constants.senderName]?.toString() ?? '',
        senderImage: map[Constants.senderImage]?.toString() ?? '',
        message: map[Constants.message]?.toString() ?? '',
        messageType: _parseMessageType(map[Constants.messageType]?.toString()),
        timeSent: map[Constants.timeSent]?.toString() ?? 
          DateTime.now().millisecondsSinceEpoch.toString(),
        messageStatus: _parseMessageStatus(map['messageStatus']?.toString()),
        repliedMessage: map[Constants.repliedMessage]?.toString(),
        repliedTo: map[Constants.repliedTo]?.toString(),
        repliedMessageType: map[Constants.repliedMessageType] != null
            ? _parseMessageType(map[Constants.repliedMessageType].toString())
            : null,
        deletedBy: _parseStringList(map[Constants.deletedBy]),
        isDeletedForEveryone: map['isDeletedForEveryone'] == true,
        isEdited: map['isEdited'] == true,
        originalMessage: map['originalMessage']?.toString(),
        editedAt: map['editedAt']?.toString(),
        reactions: _parseReactionsMap(map['reactions']),
      );
    } catch (e, stackTrace) {
      throw FormatException('Error parsing MessageModel: $e\nStack trace: $stackTrace');
    }
  }

  static MessageEnum _parseMessageType(String? type) {
    if (type == null) return MessageEnum.text;
    
    switch (type.toLowerCase()) {
      case 'image': return MessageEnum.image;
      case 'video': return MessageEnum.video;
      case 'audio': return MessageEnum.audio;
      case 'file': return MessageEnum.file;
      case 'location': return MessageEnum.location;
      case 'contact': return MessageEnum.contact;
      default: return MessageEnum.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    if (status == null) return MessageStatus.sending;
    
    switch (status.toLowerCase()) {
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      case 'failed': return MessageStatus.failed;
      default: return MessageStatus.sending;
    }
  }

  static List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    }
    return [];
  }

  static Map<String, Map<String, String>> _parseReactionsMap(dynamic reactions) {
    if (reactions == null || reactions is! Map) {
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
      return {};
    }
  }

  Map<String, dynamic> toMap() {
    return {
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
      deletedBy: deletedBy ?? List<String>.from(this.deletedBy),
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      originalMessage: originalMessage ?? this.originalMessage,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? Map<String, Map<String, String>>.from(this.reactions),
    );
  }
  
  // Helper methods
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && 
           other.messageId == messageId &&
           other.senderUID == senderUID &&
           other.message == message &&
           other.timeSent == timeSent;
  }

  @override
  int get hashCode {
    return Object.hash(messageId, senderUID, message, timeSent);
  }

  @override
  String toString() {
    return 'MessageModel(id: $messageId, sender: $senderUID, type: $messageType, status: $messageStatus)';
  }
}