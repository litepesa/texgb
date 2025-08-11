// lib/features/duanju/models/mini_series_model.dart
import 'package:textgb/constants.dart';

enum SeriesStatus {
  draft,
  published,
  completed,
  paused;

  String get name {
    switch (this) {
      case SeriesStatus.draft: return 'draft';
      case SeriesStatus.published: return 'published';
      case SeriesStatus.completed: return 'completed';
      case SeriesStatus.paused: return 'paused';
    }
  }

  static SeriesStatus fromString(String status) {
    switch (status) {
      case 'published': return SeriesStatus.published;
      case 'completed': return SeriesStatus.completed;
      case 'paused': return SeriesStatus.paused;
      default: return SeriesStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case SeriesStatus.draft: return 'Draft';
      case SeriesStatus.published: return 'Published';
      case SeriesStatus.completed: return 'Completed';
      case SeriesStatus.paused: return 'Paused';
    }
  }
}

enum SeriesGenre {
  romance,
  drama,
  comedy,
  thriller,
  action,
  fantasy,
  mystery,
  slice_of_life,
  historical,
  sci_fi,
  horror,
  other;

  String get name {
    switch (this) {
      case SeriesGenre.romance: return 'romance';
      case SeriesGenre.drama: return 'drama';
      case SeriesGenre.comedy: return 'comedy';
      case SeriesGenre.thriller: return 'thriller';
      case SeriesGenre.action: return 'action';
      case SeriesGenre.fantasy: return 'fantasy';
      case SeriesGenre.mystery: return 'mystery';
      case SeriesGenre.slice_of_life: return 'slice_of_life';
      case SeriesGenre.historical: return 'historical';
      case SeriesGenre.sci_fi: return 'sci_fi';
      case SeriesGenre.horror: return 'horror';
      case SeriesGenre.other: return 'other';
    }
  }

  static SeriesGenre fromString(String genre) {
    switch (genre) {
      case 'romance': return SeriesGenre.romance;
      case 'drama': return SeriesGenre.drama;
      case 'comedy': return SeriesGenre.comedy;
      case 'thriller': return SeriesGenre.thriller;
      case 'action': return SeriesGenre.action;
      case 'fantasy': return SeriesGenre.fantasy;
      case 'mystery': return SeriesGenre.mystery;
      case 'slice_of_life': return SeriesGenre.slice_of_life;
      case 'historical': return SeriesGenre.historical;
      case 'sci_fi': return SeriesGenre.sci_fi;
      case 'horror': return SeriesGenre.horror;
      default: return SeriesGenre.other;
    }
  }

  String get displayName {
    switch (this) {
      case SeriesGenre.romance: return 'Romance';
      case SeriesGenre.drama: return 'Drama';
      case SeriesGenre.comedy: return 'Comedy';
      case SeriesGenre.thriller: return 'Thriller';
      case SeriesGenre.action: return 'Action';
      case SeriesGenre.fantasy: return 'Fantasy';
      case SeriesGenre.mystery: return 'Mystery';
      case SeriesGenre.slice_of_life: return 'Slice of Life';
      case SeriesGenre.historical: return 'Historical';
      case SeriesGenre.sci_fi: return 'Sci-Fi';
      case SeriesGenre.horror: return 'Horror';
      case SeriesGenre.other: return 'Other';
    }
  }
}

class MiniSeriesModel {
  final String seriesId;
  final String title;
  final String description;
  final String coverImageUrl;
  final String trailerVideoUrl;
  final String creatorUID;
  final String creatorName;
  final String creatorImage;
  final SeriesGenre genre;
  final List<String> tags;
  final SeriesStatus status;
  final int totalEpisodes;
  final int publishedEpisodes;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int followersCount;
  final double averageRating;
  final String createdAt;
  final String updatedAt;
  final String? lastEpisodeDate;
  final List<String> episodes; // List of episode IDs
  final bool isVerified;
  final bool allowComments;
  final bool allowLikes;
  final Map<String, dynamic> metadata;

  const MiniSeriesModel({
    required this.seriesId,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.trailerVideoUrl,
    required this.creatorUID,
    required this.creatorName,
    required this.creatorImage,
    required this.genre,
    required this.tags,
    required this.status,
    required this.totalEpisodes,
    required this.publishedEpisodes,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
    required this.followersCount,
    required this.averageRating,
    required this.createdAt,
    required this.updatedAt,
    this.lastEpisodeDate,
    required this.episodes,
    this.isVerified = false,
    this.allowComments = true,
    this.allowLikes = true,
    this.metadata = const {},
  });

  factory MiniSeriesModel.fromMap(Map<String, dynamic> map) {
    return MiniSeriesModel(
      seriesId: map['seriesId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      coverImageUrl: map['coverImageUrl']?.toString() ?? '',
      trailerVideoUrl: map['trailerVideoUrl']?.toString() ?? '',
      creatorUID: map['creatorUID']?.toString() ?? '',
      creatorName: map['creatorName']?.toString() ?? '',
      creatorImage: map['creatorImage']?.toString() ?? '',
      genre: SeriesGenre.fromString(map['genre']?.toString() ?? 'other'),
      tags: List<String>.from(map['tags'] ?? []),
      status: SeriesStatus.fromString(map['status']?.toString() ?? 'draft'),
      totalEpisodes: map['totalEpisodes']?.toInt() ?? 0,
      publishedEpisodes: map['publishedEpisodes']?.toInt() ?? 0,
      totalViews: map['totalViews']?.toInt() ?? 0,
      totalLikes: map['totalLikes']?.toInt() ?? 0,
      totalComments: map['totalComments']?.toInt() ?? 0,
      followersCount: map['followersCount']?.toInt() ?? 0,
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      lastEpisodeDate: map['lastEpisodeDate']?.toString(),
      episodes: List<String>.from(map['episodes'] ?? []),
      isVerified: map['isVerified'] ?? false,
      allowComments: map['allowComments'] ?? true,
      allowLikes: map['allowLikes'] ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesId': seriesId,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'trailerVideoUrl': trailerVideoUrl,
      'creatorUID': creatorUID,
      'creatorName': creatorName,
      'creatorImage': creatorImage,
      'genre': genre.name,
      'tags': tags,
      'status': status.name,
      'totalEpisodes': totalEpisodes,
      'publishedEpisodes': publishedEpisodes,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'followersCount': followersCount,
      'averageRating': averageRating,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastEpisodeDate': lastEpisodeDate,
      'episodes': episodes,
      'isVerified': isVerified,
      'allowComments': allowComments,
      'allowLikes': allowLikes,
      'metadata': metadata,
    };
  }

  MiniSeriesModel copyWith({
    String? seriesId,
    String? title,
    String? description,
    String? coverImageUrl,
    String? trailerVideoUrl,
    String? creatorUID,
    String? creatorName,
    String? creatorImage,
    SeriesGenre? genre,
    List<String>? tags,
    SeriesStatus? status,
    int? totalEpisodes,
    int? publishedEpisodes,
    int? totalViews,
    int? totalLikes,
    int? totalComments,
    int? followersCount,
    double? averageRating,
    String? createdAt,
    String? updatedAt,
    String? lastEpisodeDate,
    List<String>? episodes,
    bool? isVerified,
    bool? allowComments,
    bool? allowLikes,
    Map<String, dynamic>? metadata,
  }) {
    return MiniSeriesModel(
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      trailerVideoUrl: trailerVideoUrl ?? this.trailerVideoUrl,
      creatorUID: creatorUID ?? this.creatorUID,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      genre: genre ?? this.genre,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      publishedEpisodes: publishedEpisodes ?? this.publishedEpisodes,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      followersCount: followersCount ?? this.followersCount,
      averageRating: averageRating ?? this.averageRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastEpisodeDate: lastEpisodeDate ?? this.lastEpisodeDate,
      episodes: episodes ?? this.episodes,
      isVerified: isVerified ?? this.isVerified,
      allowComments: allowComments ?? this.allowComments,
      allowLikes: allowLikes ?? this.allowLikes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MiniSeriesModel && other.seriesId == seriesId;
  }

  @override
  int get hashCode => seriesId.hashCode;

  @override
  String toString() {
    return 'MiniSeriesModel(seriesId: $seriesId, title: $title, status: $status)';
  }
}

class EpisodeModel {
  final String episodeId;
  final String seriesId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int episodeNumber;
  final int duration; // in seconds
  final int views;
  final int likes;
  final int comments;
  final String createdAt;
  final String updatedAt;
  final bool isPublished;
  final Map<String, dynamic> metadata;
  final List<String> likedBy;

  const EpisodeModel({
    required this.episodeId,
    required this.seriesId,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.episodeNumber,
    required this.duration,
    required this.views,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
    this.metadata = const {},
    this.likedBy = const [],
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      episodeId: map['episodeId']?.toString() ?? '',
      seriesId: map['seriesId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? '',
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? '',
      episodeNumber: map['episodeNumber']?.toInt() ?? 0,
      duration: map['duration']?.toInt() ?? 0,
      views: map['views']?.toInt() ?? 0,
      likes: map['likes']?.toInt() ?? 0,
      comments: map['comments']?.toInt() ?? 0,
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      isPublished: map['isPublished'] ?? false,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      likedBy: List<String>.from(map['likedBy'] ?? []),
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
      'duration': duration,
      'views': views,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPublished': isPublished,
      'metadata': metadata,
      'likedBy': likedBy,
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
    int? duration,
    int? views,
    int? likes,
    int? comments,
    String? createdAt,
    String? updatedAt,
    bool? isPublished,
    Map<String, dynamic>? metadata,
    List<String>? likedBy,
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
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeModel && other.episodeId == episodeId;
  }

  @override
  int get hashCode => episodeId.hashCode;

  @override
  String toString() {
    return 'EpisodeModel(episodeId: $episodeId, title: $title, episodeNumber: $episodeNumber)';
  }
}

class SeriesCommentModel {
  final String commentId;
  final String seriesId;
  final String? episodeId; // null for series-level comments
  final String authorUID;
  final String authorName;
  final String authorImage;
  final String content;
  final String createdAt;
  final String updatedAt;
  final int likes;
  final List<String> likedBy;
  final String? repliedToCommentId;
  final String? repliedToAuthorName;
  final int repliesCount;

  const SeriesCommentModel({
    required this.commentId,
    required this.seriesId,
    this.episodeId,
    required this.authorUID,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likes,
    required this.likedBy,
    this.repliedToCommentId,
    this.repliedToAuthorName,
    required this.repliesCount,
  });

  factory SeriesCommentModel.fromMap(Map<String, dynamic> map) {
    return SeriesCommentModel(
      commentId: map['commentId']?.toString() ?? '',
      seriesId: map['seriesId']?.toString() ?? '',
      episodeId: map['episodeId']?.toString(),
      authorUID: map['authorUID']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      authorImage: map['authorImage']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      likes: map['likes']?.toInt() ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      repliedToCommentId: map['repliedToCommentId']?.toString(),
      repliedToAuthorName: map['repliedToAuthorName']?.toString(),
      repliesCount: map['repliesCount']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'seriesId': seriesId,
      'episodeId': episodeId,
      'authorUID': authorUID,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'likes': likes,
      'likedBy': likedBy,
      'repliedToCommentId': repliedToCommentId,
      'repliedToAuthorName': repliedToAuthorName,
      'repliesCount': repliesCount,
    };
  }

  SeriesCommentModel copyWith({
    String? commentId,
    String? seriesId,
    String? episodeId,
    String? authorUID,
    String? authorName,
    String? authorImage,
    String? content,
    String? createdAt,
    String? updatedAt,
    int? likes,
    List<String>? likedBy,
    String? repliedToCommentId,
    String? repliedToAuthorName,
    int? repliesCount,
  }) {
    return SeriesCommentModel(
      commentId: commentId ?? this.commentId,
      seriesId: seriesId ?? this.seriesId,
      episodeId: episodeId ?? this.episodeId,
      authorUID: authorUID ?? this.authorUID,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      repliedToCommentId: repliedToCommentId ?? this.repliedToCommentId,
      repliedToAuthorName: repliedToAuthorName ?? this.repliedToAuthorName,
      repliesCount: repliesCount ?? this.repliesCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesCommentModel && other.commentId == commentId;
  }

  @override
  int get hashCode => commentId.hashCode;

  @override
  String toString() {
    return 'SeriesCommentModel(commentId: $commentId, content: $content)';
  }
}

class SeriesAnalyticsModel {
  final String seriesId;
  final Map<String, int> dailyViews; // date -> views
  final Map<String, int> dailyLikes; // date -> likes
  final Map<String, int> dailyComments; // date -> comments
  final Map<String, int> episodeViews; // episodeId -> views
  final Map<String, int> episodeLikes; // episodeId -> likes
  final Map<String, int> episodeComments; // episodeId -> comments
  final Map<String, double> watchTimeStats; // episodeId -> average watch time percentage
  final Map<String, int> viewerDemographics; // age group -> count
  final Map<String, int> topCountries; // country -> views
  final double totalWatchTime; // in hours
  final double averageWatchTime; // in minutes per episode
  final int uniqueViewers;
  final int returningViewers;
  final double engagementRate; // (likes + comments) / views
  final String lastUpdated;

  const SeriesAnalyticsModel({
    required this.seriesId,
    required this.dailyViews,
    required this.dailyLikes,
    required this.dailyComments,
    required this.episodeViews,
    required this.episodeLikes,
    required this.episodeComments,
    required this.watchTimeStats,
    required this.viewerDemographics,
    required this.topCountries,
    required this.totalWatchTime,
    required this.averageWatchTime,
    required this.uniqueViewers,
    required this.returningViewers,
    required this.engagementRate,
    required this.lastUpdated,
  });

  factory SeriesAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return SeriesAnalyticsModel(
      seriesId: map['seriesId']?.toString() ?? '',
      dailyViews: Map<String, int>.from(map['dailyViews'] ?? {}),
      dailyLikes: Map<String, int>.from(map['dailyLikes'] ?? {}),
      dailyComments: Map<String, int>.from(map['dailyComments'] ?? {}),
      episodeViews: Map<String, int>.from(map['episodeViews'] ?? {}),
      episodeLikes: Map<String, int>.from(map['episodeLikes'] ?? {}),
      episodeComments: Map<String, int>.from(map['episodeComments'] ?? {}),
      watchTimeStats: Map<String, double>.from(map['watchTimeStats'] ?? {}),
      viewerDemographics: Map<String, int>.from(map['viewerDemographics'] ?? {}),
      topCountries: Map<String, int>.from(map['topCountries'] ?? {}),
      totalWatchTime: map['totalWatchTime']?.toDouble() ?? 0.0,
      averageWatchTime: map['averageWatchTime']?.toDouble() ?? 0.0,
      uniqueViewers: map['uniqueViewers']?.toInt() ?? 0,
      returningViewers: map['returningViewers']?.toInt() ?? 0,
      engagementRate: map['engagementRate']?.toDouble() ?? 0.0,
      lastUpdated: map['lastUpdated']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesId': seriesId,
      'dailyViews': dailyViews,
      'dailyLikes': dailyLikes,
      'dailyComments': dailyComments,
      'episodeViews': episodeViews,
      'episodeLikes': episodeLikes,
      'episodeComments': episodeComments,
      'watchTimeStats': watchTimeStats,
      'viewerDemographics': viewerDemographics,
      'topCountries': topCountries,
      'totalWatchTime': totalWatchTime,
      'averageWatchTime': averageWatchTime,
      'uniqueViewers': uniqueViewers,
      'returningViewers': returningViewers,
      'engagementRate': engagementRate,
      'lastUpdated': lastUpdated,
    };
  }

  @override
  String toString() {
    return 'SeriesAnalyticsModel(seriesId: $seriesId, totalViews: ${dailyViews.values.fold(0, (a, b) => a + b)})';
  }
}