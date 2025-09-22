// lib/features/video_chat/models/reaction_message.dart
// SIMPLIFIED: Message model specifically for video reactions - fool-proof design

import 'package:uuid/uuid.dart';

/// Types of messages in video reaction conversations
enum ReactionMessageType { 
  text, 
  image, 
  video, 
  link 
}

/// Simple message status tracking - only what matters
enum MessageStatus { 
  failed,    // ❌ Failed to send
  sent,      // ✓ Sent (1 grey tick)
  delivered, // ✓✓ Delivered (2 grey ticks)
  read       // ✓✓ Read (2 blue ticks)
}

class ReactionMessage {
  final String id;
  final String conversationId;  // Links to VideoConversation
  final String senderId;
  final String content;         // Text content or caption
  final ReactionMessageType type;
  final String? mediaUrl;       // For image/video/link preview
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Simple metadata for media info

  const ReactionMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.status,
    required this.timestamp,
    this.metadata,
  });

  // Create new message with auto-generated ID
  factory ReactionMessage.create({
    required String conversationId,
    required String senderId,
    required String content,
    required ReactionMessageType type,
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) {
    const uuid = Uuid();
    
    return ReactionMessage(
      id: uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      content: content.trim(),
      type: type,
      mediaUrl: mediaUrl,
      status: MessageStatus.sent, // Default to sent
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  // Safe JSON conversion with validation
  factory ReactionMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ReactionMessage(
        id: json['id']?.toString() ?? '',
        conversationId: json['conversationId']?.toString() ?? '',
        senderId: json['senderId']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        type: _parseMessageType(json['type']),
        mediaUrl: json['mediaUrl']?.toString(),
        status: _parseMessageStatus(json['status']),
        timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
        metadata: json['metadata'] != null 
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
      );
    } catch (e) {
      throw FormatException('Invalid ReactionMessage JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Helper parsers with fallbacks
  static ReactionMessageType _parseMessageType(dynamic type) {
    if (type is String) {
      return ReactionMessageType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => ReactionMessageType.text,
      );
    }
    return ReactionMessageType.text;
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status is String) {
      return MessageStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => MessageStatus.failed,
      );
    }
    return MessageStatus.failed;
  }

  // Create copy with updated status
  ReactionMessage withStatus(MessageStatus newStatus) {
    return ReactionMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: mediaUrl,
      status: newStatus,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  // Create copy with media URL (for after upload)
  ReactionMessage withMediaUrl(String url) {
    return ReactionMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      mediaUrl: url,
      status: status,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  // Helper methods for UI
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  
  bool get isText => type == ReactionMessageType.text;
  bool get isImage => type == ReactionMessageType.image;
  bool get isVideo => type == ReactionMessageType.video;
  bool get isLink => type == ReactionMessageType.link;

  String get displayContent {
    switch (type) {
      case ReactionMessageType.text:
        return content;
      case ReactionMessageType.image:
        return content.isNotEmpty ? content : '📷 Photo';
      case ReactionMessageType.video:
        return content.isNotEmpty ? content : '🎥 Video';
      case ReactionMessageType.link:
        return content.isNotEmpty ? content : '🔗 Link';
    }
  }

  // Status helpers for UI
  String get statusEmoji {
    switch (status) {
      case MessageStatus.failed:
        return '❌';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓'; // Blue in UI
    }
  }

  bool get isFailed => status == MessageStatus.failed;
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get canRetry => status == MessageStatus.failed;

  // Validation
  bool get isValid {
    return id.isNotEmpty && 
           conversationId.isNotEmpty && 
           senderId.isNotEmpty &&
           (content.isNotEmpty || hasMedia);
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Message ID is required');
    if (conversationId.isEmpty) errors.add('Conversation ID is required');
    if (senderId.isEmpty) errors.add('Sender ID is required');
    if (content.isEmpty && !hasMedia) errors.add('Message must have content or media');
    
    return errors;
  }

  // Time formatting helpers
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24 && timestamp.day == now.day) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String get fullTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ReactionMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReactionMessage(id: $id, type: $type, status: $status, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';
  }
}

// Message type extensions for UI helpers
extension ReactionMessageTypeExtension on ReactionMessageType {
  String get displayName {
    switch (this) {
      case ReactionMessageType.text:
        return 'Text';
      case ReactionMessageType.image:
        return 'Photo';
      case ReactionMessageType.video:
        return 'Video';
      case ReactionMessageType.link:
        return 'Link';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionMessageType.text:
        return '💬';
      case ReactionMessageType.image:
        return '📷';
      case ReactionMessageType.video:
        return '🎥';
      case ReactionMessageType.link:
        return '🔗';
    }
  }
}

// Message status extensions for UI helpers
extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.failed:
        return 'Failed';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
    }
  }
}

// Factory methods for different message types
extension ReactionMessageFactory on ReactionMessage {
  // Create text message
  static ReactionMessage text({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    return ReactionMessage.create(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: ReactionMessageType.text,
    );
  }

  // Create image message
  static ReactionMessage image({
    required String conversationId,
    required String senderId,
    required String mediaUrl,
    String caption = '',
  }) {
    return ReactionMessage.create(
      conversationId: conversationId,
      senderId: senderId,
      content: caption,
      type: ReactionMessageType.image,
      mediaUrl: mediaUrl,
    );
  }

  // Create video message
  static ReactionMessage video({
    required String conversationId,
    required String senderId,
    required String mediaUrl,
    String caption = '',
    Map<String, dynamic>? metadata,
  }) {
    return ReactionMessage.create(
      conversationId: conversationId,
      senderId: senderId,
      content: caption,
      type: ReactionMessageType.video,
      mediaUrl: mediaUrl,
      metadata: metadata,
    );
  }

  // Create link message
  static ReactionMessage link({
    required String conversationId,
    required String senderId,
    required String content,
    String? linkUrl,
  }) {
    return ReactionMessage.create(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: ReactionMessageType.link,
      mediaUrl: linkUrl,
    );
  }
}