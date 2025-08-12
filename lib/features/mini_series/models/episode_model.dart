// lib/features/mini_series/models/episode_model.dart
class EpisodeModel {
  final String episodeId;
  final String seriesId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int episodeNumber;
  final Duration duration;
  final DateTime createdAt;
  final DateTime publishedAt;
  final int views;
  final int likes;
  final int comments;
  final bool isPublished;
  final List<String> likedBy;
  final Map<String, dynamic> metadata;

  const EpisodeModel({
    required this.episodeId,
    required this.seriesId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.episodeNumber,
    required this.duration,
    required this.createdAt,
    required this.publishedAt,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.isPublished = false,
    this.likedBy = const [],
    this.metadata = const {},
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      episodeId: map['episodeId']?.toString() ?? '',
      seriesId: map['seriesId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      episodeNumber: map['episodeNumber']?.toInt() ?? 1,
      duration: Duration(seconds: map['durationSeconds']?.toInt() ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['publishedAt']?.toString() ?? '0') ?? 0,
      ),
      views: map['views']?.toInt() ?? 0,
      likes: map['likes']?.toInt() ?? 0,
      comments: map['comments']?.toInt() ?? 0,
      isPublished: map['isPublished'] ?? false,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'episodeId': episodeId,
      'seriesId': seriesId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'episodeNumber': episodeNumber,
      'durationSeconds': duration.inSeconds,
      'createdAt': createdAt.millisecondsSinceEpoch.toString(),
      'publishedAt': publishedAt.millisecondsSinceEpoch.toString(),
      'views': views,
      'likes': likes,
      'comments': comments,
      'isPublished': isPublished,
      'likedBy': likedBy,
      'metadata': metadata,
    };
  }

  EpisodeModel copyWith({
    String? episodeId,
    String? seriesId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? episodeNumber,
    Duration? duration,
    DateTime? createdAt,
    DateTime? publishedAt,
    int? views,
    int? likes,
    int? comments,
    bool? isPublished,
    List<String>? likedBy,
    Map<String, dynamic>? metadata,
  }) {
    return EpisodeModel(
      episodeId: episodeId ?? this.episodeId,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isPublished: isPublished ?? this.isPublished,
      likedBy: likedBy ?? this.likedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);
}
