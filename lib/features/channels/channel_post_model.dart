import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';

class ChannelPostModel {
  final String id;
  final String channelId;
  final String creatorUID;
  final String message;
  final MessageEnum messageType;
  final String mediaUrl;
  final String createdAt;
  final Map<String, String> reactions;
  final int viewCount;
  final bool isPinned;
  
  ChannelPostModel({
    required this.id,
    required this.channelId,
    required this.creatorUID,
    required this.message,
    required this.messageType,
    required this.mediaUrl,
    required this.createdAt,
    required this.reactions,
    required this.viewCount,
    required this.isPinned,
  });

  // Factory constructor to create ChannelPostModel from a Map
  factory ChannelPostModel.fromMap(Map<String, dynamic> map) {
    return ChannelPostModel(
      id: map[Constants.postId] ?? '',
      channelId: map[Constants.channelId] ?? '',
      creatorUID: map[Constants.creatorUID] ?? '',
      message: map[Constants.message] ?? '',
      messageType: (map[Constants.messageType] as String? ?? 'text').toMessageEnum(),
      mediaUrl: map[Constants.mediaUrl] ?? '',
      createdAt: map[Constants.createdAt] ?? '',
      reactions: Map<String, String>.from(map[Constants.reactions] ?? {}),
      viewCount: map[Constants.postViewCount] ?? 0,
      isPinned: map[Constants.isPinned] ?? false,
    );
  }

  // Method to convert ChannelPostModel to a Map
  Map<String, dynamic> toMap() {
    return {
      Constants.postId: id,
      Constants.channelId: channelId,
      Constants.creatorUID: creatorUID,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.mediaUrl: mediaUrl,
      Constants.createdAt: createdAt,
      Constants.reactions: reactions,
      Constants.postViewCount: viewCount,
      Constants.isPinned: isPinned,
    };
  }

  // Create a copy of ChannelPostModel with updated fields
  ChannelPostModel copyWith({
    String? id,
    String? channelId,
    String? creatorUID,
    String? message,
    MessageEnum? messageType,
    String? mediaUrl,
    String? createdAt,
    Map<String, String>? reactions,
    int? viewCount,
    bool? isPinned,
  }) {
    return ChannelPostModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      creatorUID: creatorUID ?? this.creatorUID,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      viewCount: viewCount ?? this.viewCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}