// lib/features/groups/models/group_message_model.dart

enum MessageMediaType {
  text,
  image,
  video,
  audio,
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

  static MessageMediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'text':
        return MessageMediaType.text;
      case 'image':
        return MessageMediaType.image;
      case 'video':
        return MessageMediaType.video;
      case 'audio':
        return MessageMediaType.audio;
      case 'file':
        return MessageMediaType.file;
      default:
        return MessageMediaType.text;
    }
  }

  String toJson() => name;
}

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String messageText;
  final String? mediaUrl;
  final MessageMediaType mediaType;
  final List<String> readBy;
  final DateTime insertedAt;
  final DateTime? updatedAt;
  final String? senderName;
  final String? senderImage;

  const GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.messageText,
    this.mediaUrl,
    this.mediaType = MessageMediaType.text,
    this.readBy = const [],
    required this.insertedAt,
    this.updatedAt,
    this.senderName,
    this.senderImage,
  });

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupMessageModel(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      messageText: json['message_text'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] != null
          ? MessageMediaType.fromString(json['media_type'])
          : MessageMediaType.text,
      readBy: json['read_by'] != null ? List<String>.from(json['read_by']) : [],
      insertedAt: json['inserted_at'] != null
          ? DateTime.parse(json['inserted_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      senderName: json['sender_name'],
      senderImage: json['sender_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'message_text': messageText,
      'media_url': mediaUrl,
      'media_type': mediaType.toJson(),
      'read_by': readBy,
      'inserted_at': insertedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sender_name': senderName,
      'sender_image': senderImage,
    };
  }

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? messageText,
    String? mediaUrl,
    MessageMediaType? mediaType,
    List<String>? readBy,
    DateTime? insertedAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderImage,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      readBy: readBy ?? this.readBy,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
    );
  }

  // Helper methods
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
