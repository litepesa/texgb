// lib/features/video_chat/models/video_conversation.dart
// SIMPLIFIED: Video-centric conversation model - fool-proof design

class VideoConversation {
  final String id;
  final String videoId;          // ALWAYS tied to original video
  final String videoUrl;         // For context and display
  final String videoThumbnail;   // For UI thumbnail
  final String videoCreator;     // Original video creator name
  final String videoCreatorId;   // Original video creator ID
  final List<String> participants; // Always exactly 2 users
  final DateTime createdAt;
  final ReactionMessage? lastMessage;
  final Map<String, int> unreadCounts; // Simple unread tracking

  const VideoConversation({
    required this.id,
    required this.videoId,
    required this.videoUrl,
    required this.videoThumbnail,
    required this.videoCreator,
    required this.videoCreatorId,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    required this.unreadCounts,
  });

  // Create from video and participants
  factory VideoConversation.createNew({
    required String videoId,
    required String videoUrl,
    required String videoThumbnail,
    required String videoCreator,
    required String videoCreatorId,
    required String currentUserId,
    required String otherUserId,
  }) {
    // Generate deterministic ID based on video and participants
    final participantIds = [currentUserId, otherUserId]..sort();
    final conversationId = '${videoId}_${participantIds.join('_')}';
    
    return VideoConversation(
      id: conversationId,
      videoId: videoId,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      videoCreator: videoCreator,
      videoCreatorId: videoCreatorId,
      participants: participantIds,
      createdAt: DateTime.now(),
      unreadCounts: {
        currentUserId: 0,
        otherUserId: 0,
      },
    );
  }

  // Safe JSON conversion with validation
  factory VideoConversation.fromJson(Map<String, dynamic> json) {
    try {
      return VideoConversation(
        id: json['id']?.toString() ?? '',
        videoId: json['videoId']?.toString() ?? '',
        videoUrl: json['videoUrl']?.toString() ?? '',
        videoThumbnail: json['videoThumbnail']?.toString() ?? '',
        videoCreator: json['videoCreator']?.toString() ?? 'Unknown',
        videoCreatorId: json['videoCreatorId']?.toString() ?? '',
        participants: List<String>.from(json['participants'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        lastMessage: json['lastMessage'] != null 
            ? ReactionMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      );
    } catch (e) {
      throw FormatException('Invalid VideoConversation JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'videoUrl': videoUrl,
      'videoThumbnail': videoThumbnail,
      'videoCreator': videoCreator,
      'videoCreatorId': videoCreatorId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCounts': unreadCounts,
    };
  }

  // Helper methods
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : '',
    );
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  // Create updated copy with new message
  VideoConversation withLastMessage(ReactionMessage message) {
    return VideoConversation(
      id: id,
      videoId: videoId,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      videoCreator: videoCreator,
      videoCreatorId: videoCreatorId,
      participants: participants,
      createdAt: createdAt,
      lastMessage: message,
      unreadCounts: unreadCounts,
    );
  }

  // Update unread count for user
  VideoConversation withUnreadCount(String userId, int count) {
    final newUnreadCounts = Map<String, int>.from(unreadCounts);
    newUnreadCounts[userId] = count;
    
    return VideoConversation(
      id: id,
      videoId: videoId,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      videoCreator: videoCreator,
      videoCreatorId: videoCreatorId,
      participants: participants,
      createdAt: createdAt,
      lastMessage: lastMessage,
      unreadCounts: newUnreadCounts,
    );
  }

  // Mark as read for user
  VideoConversation markAsRead(String userId) {
    return withUnreadCount(userId, 0);
  }

  // Validation
  bool get isValid {
    return id.isNotEmpty && 
           videoId.isNotEmpty && 
           videoUrl.isNotEmpty &&
           participants.length == 2 &&
           participants.every((id) => id.isNotEmpty);
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Conversation ID is required');
    if (videoId.isEmpty) errors.add('Video ID is required');
    if (videoUrl.isEmpty) errors.add('Video URL is required');
    if (participants.length != 2) errors.add('Must have exactly 2 participants');
    if (participants.any((id) => id.isEmpty)) errors.add('Participant IDs cannot be empty');
    
    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VideoConversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VideoConversation(id: $id, videoId: $videoId, participants: $participants)';
  }
}

// Import for ReactionMessage
class ReactionMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final ReactionMessageType type;
  final String? mediaUrl;
  final MessageStatus status;
  final DateTime timestamp;

  const ReactionMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    this.mediaUrl,
    required this.status,
    required this.timestamp,
  });

  // Placeholder fromJson for VideoConversation dependency
  factory ReactionMessage.fromJson(Map<String, dynamic> json) {
    return ReactionMessage(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      type: ReactionMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReactionMessageType.text,
      ),
      mediaUrl: json['mediaUrl'],
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.failed,
      ),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
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
    };
  }
}

enum ReactionMessageType { text, image, video, link }
enum MessageStatus { failed, sent, delivered, read }