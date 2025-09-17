// lib/features/chat/models/chat_model.dart
import 'package:textgb/enums/enums.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final MessageEnum lastMessageType;
  final String lastMessageSender;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final Map<String, bool> isArchived;
  final Map<String, bool> isPinned;
  final Map<String, bool> isMuted;
  final DateTime createdAt;
  final Map<String, String>? chatWallpapers; // userId -> wallpaper URL
  final Map<String, double>? fontSizes; // userId -> font size

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageSender,
    required this.lastMessageTime,
    required this.unreadCounts,
    required this.isArchived,
    required this.isPinned,
    required this.isMuted,
    required this.createdAt,
    this.chatWallpapers,
    this.fontSizes,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: MessageEnum.values.firstWhere(
        (e) => e.name == map['lastMessageType'],
        orElse: () => MessageEnum.text,
      ),
      lastMessageSender: map['lastMessageSender'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime'] ?? DateTime.now().toIso8601String()),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      isArchived: Map<String, bool>.from(map['isArchived'] ?? {}),
      isPinned: Map<String, bool>.from(map['isPinned'] ?? {}),
      isMuted: Map<String, bool>.from(map['isMuted'] ?? {}),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      chatWallpapers: map['chatWallpapers'] != null 
        ? Map<String, String>.from(map['chatWallpapers']) 
        : null,
      fontSizes: map['fontSizes'] != null 
        ? Map<String, double>.from(map['fontSizes']) 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType.name,
      'lastMessageSender': lastMessageSender,
      'lastMessageTime': lastMessageTime.toUtc().toIso8601String(),
      'unreadCounts': unreadCounts,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'chatWallpapers': chatWallpapers,
      'fontSizes': fontSizes,
    };
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    MessageEnum? lastMessageType,
    String? lastMessageSender,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    Map<String, bool>? isArchived,
    Map<String, bool>? isPinned,
    Map<String, bool>? isMuted,
    DateTime? createdAt,
    Map<String, String>? chatWallpapers,
    Map<String, double>? fontSizes,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      chatWallpapers: chatWallpapers ?? this.chatWallpapers,
      fontSizes: fontSizes ?? this.fontSizes,
    );
  }

  // Helper methods
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool isPinnedForUser(String userId) {
    return isPinned[userId] ?? false;
  }

  bool isArchivedForUser(String userId) {
    return isArchived[userId] ?? false;
  }

  bool isMutedForUser(String userId) {
    return isMuted[userId] ?? false;
  }

  String? getWallpaperForUser(String userId) {
    return chatWallpapers?[userId];
  }

  double getFontSizeForUser(String userId) {
    return fontSizes?[userId] ?? 16.0;
  }
}