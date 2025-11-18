// lib/features/groups/models/group_message_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_message_model.freezed.dart';
part 'group_message_model.g.dart';

enum MessageMediaType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('file')
  file;

  String get displayName {
    switch (this) {
      case MessageMediaType.text:
        return 'Text';
      case MessageMediaType.image:
        return 'Image';
      case MessageMediaType.video:
        return 'Video';
      case MessageMediaType.audio:
        return 'Audio';
      case MessageMediaType.file:
        return 'File';
    }
  }
}

@freezed
class GroupMessageModel with _$GroupMessageModel {
  const factory GroupMessageModel({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'message_text') required String messageText,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'media_type') @Default(MessageMediaType.text) MessageMediaType mediaType,
    @JsonKey(name: 'read_by') @Default([]) List<String> readBy,
    @JsonKey(name: 'inserted_at') required DateTime insertedAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Optional sender details (populated from join query)
    @JsonKey(name: 'sender_name') String? senderName,
    @JsonKey(name: 'sender_image') String? senderImage,
  }) = _GroupMessageModel;

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageModelFromJson(json);
}

// Extension methods for GroupMessageModel
extension GroupMessageModelExtension on GroupMessageModel {
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  bool get isTextOnly => mediaType == MessageMediaType.text && !hasMedia;

  bool get isImage => mediaType == MessageMediaType.image;

  bool get isVideo => mediaType == MessageMediaType.video;

  bool get isAudio => mediaType == MessageMediaType.audio;

  bool get isFile => mediaType == MessageMediaType.file;

  String get displaySenderName => senderName ?? 'Unknown';

  bool isReadBy(String userId) => readBy.contains(userId);

  int get readCount => readBy.length;

  // Time ago for message timestamp
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(insertedAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Formatted time for display (HH:MM)
  String get formattedTime {
    final hour = insertedAt.hour.toString().padLeft(2, '0');
    final minute = insertedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Display text based on media type
  String get displayText {
    if (isTextOnly) return messageText;
    if (isImage) return '📷 Image';
    if (isVideo) return '🎥 Video';
    if (isAudio) return '🎵 Audio';
    if (isFile) return '📎 File';
    return messageText;
  }
}
