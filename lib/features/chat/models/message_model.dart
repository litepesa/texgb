// lib/features/chat/models/message_model.dart
import 'package:textgb/enums/enums.dart';

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String content;
  final MessageEnum type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? mediaUrl;
  final Map<String, dynamic>? mediaMetadata;
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSender;
  final Map<String, String>? reactions; // userId -> emoji
  final bool isEdited;
  final DateTime? editedAt;
  final bool isPinned;
  final Map<String, DateTime>? readBy; // userId -> read timestamp
  final Map<String, DateTime>? deliveredTo; // userId -> delivered timestamp

  const MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.mediaUrl,
    this.mediaMetadata,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSender,
    this.reactions,
    this.isEdited = false,
    this.editedAt,
    this.isPinned = false,
    this.readBy,
    this.deliveredTo,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      type: MessageEnum.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageEnum.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sending,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      mediaUrl: map['mediaUrl'],
      mediaMetadata: map['mediaMetadata'] != null 
        ? Map<String, dynamic>.from(map['mediaMetadata']) 
        : null,
      replyToMessageId: map['replyToMessageId'],
      replyToContent: map['replyToContent'],
      replyToSender: map['replyToSender'],
      reactions: map['reactions'] != null 
        ? Map<String, String>.from(map['reactions']) 
        : null,
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['editedAt']) 
        : null,
      isPinned: map['isPinned'] ?? false,
      readBy: map['readBy'] != null 
        ? Map<String, DateTime>.from(
            (map['readBy'] as Map).map((k, v) => 
              MapEntry(k.toString(), DateTime.fromMillisecondsSinceEpoch(v)))) 
        : null,
      deliveredTo: map['deliveredTo'] != null 
        ? Map<String, DateTime>.from(
            (map['deliveredTo'] as Map).map((k, v) => 
              MapEntry(k.toString(), DateTime.fromMillisecondsSinceEpoch(v)))) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'mediaUrl': mediaUrl,
      'mediaMetadata': mediaMetadata,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSender': replyToSender,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'isPinned': isPinned,
      'readBy': readBy?.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      'deliveredTo': deliveredTo?.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
    };
  }

  MessageModel copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? content,
    MessageEnum? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? mediaUrl,
    Map<String, dynamic>? mediaMetadata,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSender,
    Map<String, String>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    bool? isPinned,
    Map<String, DateTime>? readBy,
    Map<String, DateTime>? deliveredTo,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSender: replyToSender ?? this.replyToSender,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isPinned: isPinned ?? this.isPinned,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
    );
  }

  // Helper methods
  bool isReadBy(String userId) {
    return readBy?.containsKey(userId) ?? false;
  }

  bool isDeliveredTo(String userId) {
    return deliveredTo?.containsKey(userId) ?? false;
  }

  String? getReaction(String userId) {
    return reactions?[userId];
  }

  bool hasReactions() {
    return reactions != null && reactions!.isNotEmpty;
  }

  bool isReply() {
    return replyToMessageId != null;
  }

  bool hasMedia() {
    return mediaUrl != null && mediaUrl!.isNotEmpty;
  }

  String getDisplayContent() {
    switch (type) {
      case MessageEnum.text:
        return content;
      case MessageEnum.image:
        return '📷 Photo';
      case MessageEnum.file:
        return '📎 ${mediaMetadata?['fileName'] ?? 'Document'}';
      default:
        return content;
    }
  }
}

