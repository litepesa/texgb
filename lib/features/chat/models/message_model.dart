// lib/features/chat/models/message_model.dart

enum MessageType {
  text('text'),
  image('image'),
  video('video'),
  audio('audio'),
  document('document'),
  location('location'),
  contact('contact'),
  sticker('sticker'),
  gif('gif');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'sticker':
        return MessageType.sticker;
      case 'gif':
        return MessageType.gif;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

enum MessageStatus {
  sending('sending'),     // Message is being sent
  sent('sent'),          // Message sent to server
  delivered('delivered'), // Message delivered to recipient
  failed('failed');      // Message failed to send

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'failed':
        return MessageStatus.failed;
      case 'sending':
      default:
        return MessageStatus.sending;
    }
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String content;
  final MessageType type;
  final MessageStatus status;
  
  // Media fields (for images, videos, documents, etc.)
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize; // in bytes
  final int? duration; // for audio/video in seconds
  
  // Reply/Quote fields
  final String? repliedToMessageId;
  final String? repliedToContent;
  final String? repliedToSenderName;
  final MessageType? repliedToType;
  
  // Location fields
  final double? latitude;
  final double? longitude;
  final String? locationName;
  
  // Contact fields
  final String? contactName;
  final String? contactPhone;
  
  // Reactions and interactions
  final Map<String, String> reactions; // emoji -> userId
  final bool isForwarded;
  final bool isStarred;
  final bool isDeleted; // User has deleted this message for themselves
  
  // Timestamps
  final String createdAt;
  final String? updatedAt;
  final String? deliveredAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.content,
    required this.type,
    required this.status,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    this.repliedToMessageId,
    this.repliedToContent,
    this.repliedToSenderName,
    this.repliedToType,
    this.latitude,
    this.longitude,
    this.locationName,
    this.contactName,
    this.contactPhone,
    this.reactions = const {},
    this.isForwarded = false,
    this.isStarred = false,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? map['chat_id'] ?? '',
      senderId: map['senderId'] ?? map['sender_id'] ?? '',
      senderName: map['senderName'] ?? map['sender_name'] ?? '',
      senderImage: map['senderImage'] ?? map['sender_image'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.fromString(map['type']),
      status: MessageStatus.fromString(map['status']),
      mediaUrl: map['mediaUrl'] ?? map['media_url'],
      thumbnailUrl: map['thumbnailUrl'] ?? map['thumbnail_url'],
      fileName: map['fileName'] ?? map['file_name'],
      fileSize: map['fileSize'] ?? map['file_size'],
      duration: map['duration'],
      repliedToMessageId: map['repliedToMessageId'] ?? map['replied_to_message_id'],
      repliedToContent: map['repliedToContent'] ?? map['replied_to_content'],
      repliedToSenderName: map['repliedToSenderName'] ?? map['replied_to_sender_name'],
      repliedToType: map['repliedToType'] != null || map['replied_to_type'] != null
          ? MessageType.fromString(map['repliedToType'] ?? map['replied_to_type'])
          : null,
      latitude: _extractDouble(map['latitude']),
      longitude: _extractDouble(map['longitude']),
      locationName: map['locationName'] ?? map['location_name'],
      contactName: map['contactName'] ?? map['contact_name'],
      contactPhone: map['contactPhone'] ?? map['contact_phone'],
      reactions: _parseReactions(map['reactions']),
      isForwarded: map['isForwarded'] ?? map['is_forwarded'] ?? false,
      isStarred: map['isStarred'] ?? map['is_starred'] ?? false,
      isDeleted: map['isDeleted'] ?? map['is_deleted'] ?? false,
      createdAt: map['createdAt'] ?? map['created_at'] ?? '',
      updatedAt: map['updatedAt'] ?? map['updated_at'],
      deliveredAt: map['deliveredAt'] ?? map['delivered_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'content': content,
      'type': type.value,
      'status': status.value,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'repliedToMessageId': repliedToMessageId,
      'repliedToContent': repliedToContent,
      'repliedToSenderName': repliedToSenderName,
      'repliedToType': repliedToType?.value,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'reactions': reactions,
      'isForwarded': isForwarded,
      'isStarred': isStarred,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deliveredAt': deliveredAt,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderImage,
    String? content,
    MessageType? type,
    MessageStatus? status,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    String? repliedToMessageId,
    String? repliedToContent,
    String? repliedToSenderName,
    MessageType? repliedToType,
    double? latitude,
    double? longitude,
    String? locationName,
    String? contactName,
    String? contactPhone,
    Map<String, String>? reactions,
    bool? isForwarded,
    bool? isStarred,
    bool? isDeleted,
    String? deletedFor,
    String? createdAt,
    String? updatedAt,
    String? deliveredAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      repliedToMessageId: repliedToMessageId ?? this.repliedToMessageId,
      repliedToContent: repliedToContent ?? this.repliedToContent,
      repliedToSenderName: repliedToSenderName ?? this.repliedToSenderName,
      repliedToType: repliedToType ?? this.repliedToType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      reactions: reactions ?? this.reactions,
      isForwarded: isForwarded ?? this.isForwarded,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  // Helper methods
  static double? _extractDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Map<String, String> _parseReactions(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return {};
  }

  // Timestamp helpers
  DateTime get createdAtDateTime => DateTime.parse(createdAt);
  DateTime? get updatedAtDateTime => updatedAt != null ? DateTime.parse(updatedAt!) : null;
  DateTime? get deliveredAtDateTime => deliveredAt != null ? DateTime.parse(deliveredAt!) : null;

  // Status helpers
  bool get isSending => status == MessageStatus.sending;
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isFailed => status == MessageStatus.failed;

  // Type helpers
  bool get isTextMessage => type == MessageType.text;
  bool get isImageMessage => type == MessageType.image;
  bool get isVideoMessage => type == MessageType.video;
  bool get isAudioMessage => type == MessageType.audio;
  bool get isDocumentMessage => type == MessageType.document;
  bool get isLocationMessage => type == MessageType.location;
  bool get isContactMessage => type == MessageType.contact;
  bool get isStickerMessage => type == MessageType.sticker;
  bool get isGifMessage => type == MessageType.gif;
  bool get isMediaMessage => isImageMessage || isVideoMessage || isAudioMessage;

  // Reply helpers
  bool get isReply => repliedToMessageId != null;
  bool get hasReactions => reactions.isNotEmpty;

  // Time formatting
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAtDateTime);

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

  String get formattedTime {
    final time = createdAtDateTime;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // File size formatting
  String get formattedFileSize {
    if (fileSize == null) return '';
    
    final size = fileSize!;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Duration formatting
  String get formattedDuration {
    if (duration == null) return '';
    
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MessageModel(id: $id, type: ${type.value}, status: ${status.value}, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}