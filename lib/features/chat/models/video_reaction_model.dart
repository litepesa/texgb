// lib/features/chat/models/video_reaction_model.dart
class VideoReactionModel {
  final String videoId;
  final String videoUrl;
  final String thumbnailUrl;
  final String channelName;
  final String channelImage;
  final String? reaction; // emoji or text reaction
  final DateTime timestamp;

  const VideoReactionModel({
    required this.videoId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.channelName,
    required this.channelImage,
    this.reaction,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'channelName': channelName,
      'channelImage': channelImage,
      'reaction': reaction,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  factory VideoReactionModel.fromMap(Map<String, dynamic> map) {
    return VideoReactionModel(
      videoId: map['videoId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      channelName: map['channelName'] ?? '',
      channelImage: map['channelImage'] ?? '',
      reaction: map['reaction'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  VideoReactionModel copyWith({
    String? videoId,
    String? videoUrl,
    String? thumbnailUrl,
    String? channelName,
    String? channelImage,
    String? reaction,
    DateTime? timestamp,
  }) {
    return VideoReactionModel(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelName: channelName ?? this.channelName,
      channelImage: channelImage ?? this.channelImage,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}