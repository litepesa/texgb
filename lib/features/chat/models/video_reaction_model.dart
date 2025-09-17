// lib/features/chat/models/video_reaction_model.dart
// UPDATED: Renamed channel references to user references for users-based system
class VideoReactionModel {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;
  final String userName;
  final String userImage;
  final String? reaction; // emoji or text reaction
  final DateTime timestamp;

  const VideoReactionModel({
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.userName,
    required this.userImage,
    this.reaction,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'userName': userName,
      'userImage': userImage,
      'reaction': reaction,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  factory VideoReactionModel.fromMap(Map<String, dynamic> map) {
    return VideoReactionModel(
      videoId: map['videoId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      reaction: map['reaction'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  VideoReactionModel copyWith({
    String? videoId,
    String? videoUrl,
    String? thumbnailUrl,
    String? userName,
    String? userImage,
    String? reaction,
    DateTime? timestamp,
  }) {
    return VideoReactionModel(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Convenience methods
  bool get hasReaction => reaction != null && reaction!.isNotEmpty;
  
  String get displayContent => reaction ?? '';
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  // Validation
  bool get isValid {
    return videoId.isNotEmpty && 
           videoUrl.isNotEmpty && 
           userName.isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (videoId.isEmpty) errors.add('Video ID is required');
    if (videoUrl.isEmpty) errors.add('Video URL is required');
    if (userName.isEmpty) errors.add('User name is required');
    
    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is VideoReactionModel &&
        other.videoId == videoId &&
        other.videoUrl == videoUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.userName == userName &&
        other.userImage == userImage &&
        other.reaction == reaction &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return videoId.hashCode ^
        videoUrl.hashCode ^
        thumbnailUrl.hashCode ^
        userName.hashCode ^
        userImage.hashCode ^
        reaction.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'VideoReactionModel(videoId: $videoId, userName: $userName, reaction: $reaction, timestamp: $timestamp)';
  }

  // Factory constructor for creating from VideoModel and UserModel
  factory VideoReactionModel.fromVideoAndUser({
    required String videoId,
    required String videoUrl,
    required String thumbnailUrl,
    required String userName,
    required String userImage,
    String? reaction,
    DateTime? timestamp,
  }) {
    return VideoReactionModel(
      videoId: videoId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      userName: userName,
      userImage: userImage,
      reaction: reaction,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Create a copy with new reaction
  VideoReactionModel withReaction(String newReaction) {
    return copyWith(
      reaction: newReaction,
      timestamp: DateTime.now(),
    );
  }

  // Create a copy without reaction (for sharing video without reaction)
  VideoReactionModel withoutReaction() {
    return copyWith(
      reaction: null,
      timestamp: DateTime.now(),
    );
  }

  // Convert to JSON string for debugging
  String toJson() {
    return '''
    {
      "videoId": "$videoId",
      "videoUrl": "$videoUrl",
      "thumbnailUrl": "$thumbnailUrl",
      "userName": "$userName",
      "userImage": "$userImage",
      "reaction": ${reaction != null ? '"$reaction"' : 'null'},
      "timestamp": "${timestamp.toUtc().toIso8601String()}"
    }''';
  }

  // Debug information
  Map<String, dynamic> toDebugMap() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'userName': userName,
      'userImage': userImage,
      'reaction': reaction,
      'timestamp': timestamp.toIso8601String(),
      'timeAgo': timeAgo,
      'hasReaction': hasReaction,
      'isValid': isValid,
      'validationErrors': validationErrors,
    };
  }
}