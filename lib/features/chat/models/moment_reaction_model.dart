// lib/features/chat/models/moment_reaction_model.dart
class MomentReactionModel {
  final String momentId;
  final String mediaUrl; // Video URL or first image URL
  final String? thumbnailUrl;
  final String authorName;
  final String authorImage;
  final String content; // Original moment content/caption
  final String reaction; // User's reaction text
  final DateTime timestamp;
  final String mediaType; // 'video' or 'image'

  const MomentReactionModel({
    required this.momentId,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.reaction,
    required this.timestamp,
    required this.mediaType,
  });

  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'reaction': reaction,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'mediaType': mediaType,
    };
  }

  factory MomentReactionModel.fromMap(Map<String, dynamic> map) {
    return MomentReactionModel(
      momentId: map['momentId'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      reaction: map['reaction'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      mediaType: map['mediaType'] ?? 'image',
    );
  }

  MomentReactionModel copyWith({
    String? momentId,
    String? mediaUrl,
    String? thumbnailUrl,
    String? authorName,
    String? authorImage,
    String? content,
    String? reaction,
    DateTime? timestamp,
    String? mediaType,
  }) {
    return MomentReactionModel(
      momentId: momentId ?? this.momentId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MomentReactionModel &&
        other.momentId == momentId &&
        other.mediaUrl == mediaUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.authorName == authorName &&
        other.authorImage == authorImage &&
        other.content == content &&
        other.reaction == reaction &&
        other.timestamp == timestamp &&
        other.mediaType == mediaType;
  }

  @override
  int get hashCode {
    return momentId.hashCode ^
        mediaUrl.hashCode ^
        thumbnailUrl.hashCode ^
        authorName.hashCode ^
        authorImage.hashCode ^
        content.hashCode ^
        reaction.hashCode ^
        timestamp.hashCode ^
        mediaType.hashCode;
  }

  @override
  String toString() {
    return 'MomentReactionModel(momentId: $momentId, authorName: $authorName, reaction: $reaction, mediaType: $mediaType)';
  }
}