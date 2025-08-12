// lib/features/mini_series/models/comment_model.dart
class EpisodeCommentModel {
  final String commentId;
  final String episodeId;
  final String seriesId;
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final String? parentCommentId; // For replies
  final List<String> replies;

  const EpisodeCommentModel({
    required this.commentId,
    required this.episodeId,
    required this.seriesId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.parentCommentId,
    this.replies = const [],
  });

  factory EpisodeCommentModel.fromMap(Map<String, dynamic> map) {
    return EpisodeCommentModel(
      commentId: map['commentId']?.toString() ?? '',
      episodeId: map['episodeId']?.toString() ?? '',
      seriesId: map['seriesId']?.toString() ?? '',
      authorUID: map['authorUID']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      authorImage: map['authorImage']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      likes: map['likes']?.toInt() ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      parentCommentId: map['parentCommentId']?.toString(),
      replies: List<String>.from(map['replies'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'episodeId': episodeId,
      'seriesId': seriesId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch.toString(),
      'likes': likes,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'replies': replies,
    };
  }

  EpisodeCommentModel copyWith({
    String? commentId,
    String? episodeId,
    String? seriesId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
    String? parentCommentId,
    List<String>? replies,
  }) {
    return EpisodeCommentModel(
      commentId: commentId ?? this.commentId,
      episodeId: episodeId ?? this.episodeId,
      seriesId: seriesId ?? this.seriesId,
      authorUID: authorUID ?? this.authorUID,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
    );
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
}

