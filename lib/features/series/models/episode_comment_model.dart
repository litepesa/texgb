
// lib/features/series/models/episode_comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EpisodeCommentModel {
  final String id;
  final String episodeId;
  final String seriesId;                 // For organization and queries
  final String authorId;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;
  final int likesCount;
  final bool isReply;
  final String? repliedToCommentId;
  final String? repliedToAuthorName;

  EpisodeCommentModel({
    required this.id,
    required this.episodeId,
    required this.seriesId,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    required this.likedBy,
    required this.likesCount,
    this.isReply = false,
    this.repliedToCommentId,
    this.repliedToAuthorName,
  });

  factory EpisodeCommentModel.fromMap(Map<String, dynamic> map, String id) {
    return EpisodeCommentModel(
      id: id,
      episodeId: map['episodeId'] ?? '',
      seriesId: map['seriesId'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorImage: map['authorImage'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likesCount: map['likesCount'] ?? 0,
      isReply: map['isReply'] ?? false,
      repliedToCommentId: map['repliedToCommentId'],
      repliedToAuthorName: map['repliedToAuthorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'episodeId': episodeId,
      'seriesId': seriesId,
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likedBy': likedBy,
      'likesCount': likesCount,
      'isReply': isReply,
      if (repliedToCommentId != null) 'repliedToCommentId': repliedToCommentId,
      if (repliedToAuthorName != null) 'repliedToAuthorName': repliedToAuthorName,
    };
  }

  EpisodeCommentModel copyWith({
    String? id,
    String? episodeId,
    String? seriesId,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? content,
    DateTime? createdAt,
    List<String>? likedBy,
    int? likesCount,
    bool? isReply,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) {
    return EpisodeCommentModel(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      seriesId: seriesId ?? this.seriesId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likedBy: likedBy ?? this.likedBy,
      likesCount: likesCount ?? this.likesCount,
      isReply: isReply ?? this.isReply,
      repliedToCommentId: repliedToCommentId ?? this.repliedToCommentId,
      repliedToAuthorName: repliedToAuthorName ?? this.repliedToAuthorName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeCommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EpisodeCommentModel(id: $id, episode: $episodeId, content: $content)';
  }
}


