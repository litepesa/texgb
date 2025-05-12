import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChatModel {
  final String contactUID; // The contact's ID this chat is with
  final String lastMessage; // The content of the last message
  final String senderId; // Who sent the last message
  final int timeSent; // When the last message was sent
  final bool isSeen; // Whether the last message is seen
  final MessageEnum lastMessageType; // Type of the last message
  final int unreadCount; // Count of unread messages
  final bool isPinned; // Whether chat is pinned
  final bool isMuted; // Whether chat notifications are muted
  final Map<String, dynamic>? chatSettings; // Custom settings for this chat
  final int? expiryTime; // For disappearing messages

  const ChatModel({
    required this.contactUID,
    required this.lastMessage,
    required this.senderId,
    required this.timeSent,
    required this.isSeen,
    required this.lastMessageType,
    required this.unreadCount,
    this.isPinned = false,
    this.isMuted = false,
    this.chatSettings,
    this.expiryTime,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      contactUID: map[Constants.contactUID] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      senderId: map[Constants.senderUID] ?? '',
      timeSent: map[Constants.timeSent] ?? 0,
      isSeen: map[Constants.isSeen] ?? false,
      lastMessageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      unreadCount: map['unreadCount'] ?? 0,
      isPinned: map['isPinned'] ?? false,
      isMuted: map['isMuted'] ?? false,
      chatSettings: map['chatSettings'],
      expiryTime: map['expiryTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.contactUID: contactUID,
      Constants.lastMessage: lastMessage,
      Constants.senderUID: senderId,
      Constants.timeSent: timeSent,
      Constants.isSeen: isSeen,
      Constants.messageType: lastMessageType.name,
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'chatSettings': chatSettings,
      'expiryTime': expiryTime,
    };
  }

  // Copy with method for creating a new instance with updated fields
  ChatModel copyWith({
    String? contactUID,
    String? lastMessage,
    String? senderId,
    int? timeSent,
    bool? isSeen,
    MessageEnum? lastMessageType,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
    Map<String, dynamic>? chatSettings,
    int? expiryTime,
  }) {
    return ChatModel(
      contactUID: contactUID ?? this.contactUID,
      lastMessage: lastMessage ?? this.lastMessage,
      senderId: senderId ?? this.senderId,
      timeSent: timeSent ?? this.timeSent,
      isSeen: isSeen ?? this.isSeen,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      chatSettings: chatSettings ?? this.chatSettings,
      expiryTime: expiryTime ?? this.expiryTime,
    );
  }
}