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

  // Video reaction chat fields (optional - only for video reaction chats)
  final String? originalVideoId;
  final String? originalVideoUrl;
  final String? originalVideoThumbnail;
  final String? originalVideoCaption;
  final DateTime? updatedAt;

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
    this.originalVideoId,
    this.originalVideoUrl,
    this.originalVideoThumbnail,
    this.originalVideoCaption,
    this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse int map
    Map<String, int> parseIntMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, int>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v is int ? v : (v is num ? v.toInt() : 0)));
      }
      return {};
    }

    // Helper function to safely parse bool map
    Map<String, bool> parseBoolMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, bool>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v is bool ? v : (v == true || v == 'true')));
      }
      return {};
    }

    // Helper function to safely parse double map with int handling
    Map<String, double> parseDoubleMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, double>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) {
          if (v is double) return MapEntry(k, v);
          if (v is int) return MapEntry(k, v.toDouble());
          if (v is num) return MapEntry(k, v.toDouble());
          return MapEntry(k, 16.0); // default font size
        });
      }
      return {};
    }

    // Helper function to safely parse string map
    Map<String, String> parseStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, String>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
      return {};
    }

    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: MessageEnum.values.firstWhere(
        (e) => e.name == map['lastMessageType'],
        orElse: () => MessageEnum.text,
      ),
      lastMessageSender: map['lastMessageSender'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime'] ?? DateTime(2000, 1, 1).toIso8601String()),
      unreadCounts: parseIntMap(map['unreadCounts']),
      isArchived: parseBoolMap(map['isArchived']),
      isPinned: parseBoolMap(map['isPinned']),
      isMuted: parseBoolMap(map['isMuted']),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      chatWallpapers: map['chatWallpapers'] != null
        ? parseStringMap(map['chatWallpapers'])
        : null,
      fontSizes: map['fontSizes'] != null
        ? parseDoubleMap(map['fontSizes'])
        : null,
      originalVideoId: map['originalVideoId'],
      originalVideoUrl: map['originalVideoUrl'],
      originalVideoThumbnail: map['originalVideoThumbnail'],
      originalVideoCaption: map['originalVideoCaption'],
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
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
      if (originalVideoId != null) 'originalVideoId': originalVideoId,
      if (originalVideoUrl != null) 'originalVideoUrl': originalVideoUrl,
      if (originalVideoThumbnail != null) 'originalVideoThumbnail': originalVideoThumbnail,
      if (originalVideoCaption != null) 'originalVideoCaption': originalVideoCaption,
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
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
    String? originalVideoId,
    String? originalVideoUrl,
    String? originalVideoThumbnail,
    String? originalVideoCaption,
    DateTime? updatedAt,
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
      originalVideoId: originalVideoId ?? this.originalVideoId,
      originalVideoUrl: originalVideoUrl ?? this.originalVideoUrl,
      originalVideoThumbnail: originalVideoThumbnail ?? this.originalVideoThumbnail,
      originalVideoCaption: originalVideoCaption ?? this.originalVideoCaption,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
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

  @override
  String toString() {
    return 'ChatModel(chatId: $chatId, participants: $participants, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ChatModel &&
      other.chatId == chatId &&
      other.lastMessageTime == lastMessageTime;
  }

  @override
  int get hashCode {
    return chatId.hashCode ^ lastMessageTime.hashCode;
  }
}