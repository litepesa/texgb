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

  // Additional fields for file/video reaction messages
  final String? fileName;
  final Map<String, dynamic>? videoReactionData;
  final bool? isOriginalReaction;

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
    this.fileName,
    this.videoReactionData,
    this.isOriginalReaction,
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
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
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
        ? DateTime.parse(map['editedAt']) 
        : null,
      isPinned: map['isPinned'] ?? false,
      readBy: map['readBy'] != null
        ? Map<String, DateTime>.from(
            (map['readBy'] as Map).map((k, v) =>
              MapEntry(k.toString(), DateTime.parse(v))))
        : null,
      deliveredTo: map['deliveredTo'] != null
        ? Map<String, DateTime>.from(
            (map['deliveredTo'] as Map).map((k, v) =>
              MapEntry(k.toString(), DateTime.parse(v))))
        : null,
      fileName: map['fileName'],
      videoReactionData: map['videoReactionData'] != null
        ? Map<String, dynamic>.from(map['videoReactionData'])
        : null,
      isOriginalReaction: map['isOriginalReaction'],
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
      'timestamp': timestamp.toUtc().toIso8601String(),
      'mediaUrl': mediaUrl,
      'mediaMetadata': mediaMetadata,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSender': replyToSender,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt?.toUtc().toIso8601String(),
      'isPinned': isPinned,
      'readBy': readBy?.map((k, v) => MapEntry(k, v.toUtc().toIso8601String())),
      'deliveredTo': deliveredTo?.map((k, v) => MapEntry(k, v.toUtc().toIso8601String())),
      if (fileName != null) 'fileName': fileName,
      if (videoReactionData != null) 'videoReactionData': videoReactionData,
      if (isOriginalReaction != null) 'isOriginalReaction': isOriginalReaction,
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
    String? fileName,
    Map<String, dynamic>? videoReactionData,
    bool? isOriginalReaction,
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
      fileName: fileName ?? this.fileName,
      videoReactionData: videoReactionData ?? this.videoReactionData,
      isOriginalReaction: isOriginalReaction ?? this.isOriginalReaction,
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
        return content.isNotEmpty ? content : '📷 Photo';
      case MessageEnum.video:
        return content.isNotEmpty ? content : '📹 Video';
      case MessageEnum.file:
        return '📎 ${mediaMetadata?['fileName'] ?? 'Document'}';
      case MessageEnum.audio:
        return '🎤 Voice message';
      case MessageEnum.location:
        return '📍 Location';
      case MessageEnum.contact:
        return '👤 Contact';
      default:
        return content;
    }
  }
}