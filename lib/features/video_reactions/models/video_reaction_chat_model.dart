// lib/features/video_reactions/models/video_reaction_chat_model.dart
// NEW: Model for video reaction-based chat conversations
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';

class VideoReactionChatModel {
  final String chatId;
  final VideoReactionModel originalReaction; // The video reaction that started this chat
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
  final Map<String, String>? chatWallpapers;
  final Map<String, double>? fontSizes;

  const VideoReactionChatModel({
    required this.chatId,
    required this.originalReaction,
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

  factory VideoReactionChatModel.fromMap(Map<String, dynamic> map) {
    // Helper functions (copied from ChatModel)
    Map<String, int> parseIntMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, int>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v is int ? v : (v is num ? v.toInt() : 0)));
      }
      return {};
    }

    Map<String, bool> parseBoolMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, bool>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v is bool ? v : (v == true || v == 'true')));
      }
      return {};
    }

    Map<String, double> parseDoubleMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, double>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) {
          if (v is double) return MapEntry(k, v);
          if (v is int) return MapEntry(k, v.toDouble());
          if (v is num) return MapEntry(k, v.toDouble());
          return MapEntry(k, 16.0);
        });
      }
      return {};
    }

    Map<String, String> parseStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, String>) return value;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
      return {};
    }

    return VideoReactionChatModel(
      chatId: map['chatId'] ?? '',
      originalReaction: VideoReactionModel.fromMap(
        map['originalReaction'] ?? <String, dynamic>{},
      ),
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: MessageEnum.values.firstWhere(
        (e) => e.name == map['lastMessageType'],
        orElse: () => MessageEnum.text,
      ),
      lastMessageSender: map['lastMessageSender'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime'] ?? DateTime.now().toIso8601String()),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'originalReaction': originalReaction.toMap(),
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

  VideoReactionChatModel copyWith({
    String? chatId,
    VideoReactionModel? originalReaction,
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
    return VideoReactionChatModel(
      chatId: chatId ?? this.chatId,
      originalReaction: originalReaction ?? this.originalReaction,
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

  // Helper methods (copied from ChatModel)
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
    return 'VideoReactionChatModel(chatId: $chatId, participants: $participants, originalVideo: ${originalReaction.videoId})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is VideoReactionChatModel &&
      other.chatId == chatId &&
      other.lastMessageTime == lastMessageTime;
  }

  @override
  int get hashCode {
    return chatId.hashCode ^ lastMessageTime.hashCode;
  }
}

