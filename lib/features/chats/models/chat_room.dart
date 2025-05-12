import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/chats/models/chat_message.dart';

class ChatRoom {
  final String chatId;
  final List<String> participantsUIDs;
  final Map<String, String> participantsInfo; // Map of UID to name
  final Map<String, String> participantsImages; // Map of UID to profile image
  final ChatMessage? lastMessage;
  final Map<String, dynamic> chatSettings; // Settings like mute, pin, etc.
  final DateTime createdAt;
  final String createdBy;
  final Map<String, int> unreadCount; // Map of UID to unread count

  ChatRoom({
    required this.chatId,
    required this.participantsUIDs,
    required this.participantsInfo,
    required this.participantsImages,
    this.lastMessage,
    required this.chatSettings,
    required this.createdAt,
    required this.createdBy,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participantsUIDs': participantsUIDs,
      'participantsInfo': participantsInfo,
      'participantsImages': participantsImages,
      'lastMessage': lastMessage?.toMap(),
      'chatSettings': chatSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      chatId: map['chatId'] ?? '',
      participantsUIDs: List<String>.from(map['participantsUIDs'] ?? []),
      participantsInfo: Map<String, String>.from(map['participantsInfo'] ?? {}),
      participantsImages: Map<String, String>.from(map['participantsImages'] ?? {}),
      lastMessage: map['lastMessage'] != null
          ? ChatMessage.fromMap(map['lastMessage'])
          : null,
      chatSettings: Map<String, dynamic>.from(map['chatSettings'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  // Create a copy with updated fields
  ChatRoom copyWith({
    String? chatId,
    List<String>? participantsUIDs,
    Map<String, String>? participantsInfo,
    Map<String, String>? participantsImages,
    ChatMessage? lastMessage,
    Map<String, dynamic>? chatSettings,
    DateTime? createdAt,
    String? createdBy,
    Map<String, int>? unreadCount,
  }) {
    return ChatRoom(
      chatId: chatId ?? this.chatId,
      participantsUIDs: participantsUIDs ?? List.from(this.participantsUIDs),
      participantsInfo: participantsInfo ?? Map.from(this.participantsInfo),
      participantsImages: participantsImages ?? Map.from(this.participantsImages),
      lastMessage: lastMessage ?? this.lastMessage,
      chatSettings: chatSettings ?? Map.from(this.chatSettings),
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      unreadCount: unreadCount ?? Map.from(this.unreadCount),
    );
  }
}