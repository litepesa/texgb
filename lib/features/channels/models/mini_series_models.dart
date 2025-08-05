// lib/features/channels/models/mini_series_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MiniSeriesModel {
  final String id;
  final String channelId;
  final String channelName;
  final String channelImage;
  final String userId;
  final String title;
  final String description;
  final String trailerUrl;
  final String thumbnailUrl;
  final List<MiniSeriesEpisode> episodes;
  final int totalEpisodes;
  final int views;
  final int likes;
  final int comments;
  final List<String> tags;
  final Timestamp createdAt;
  final Timestamp? lastEpisodeAt;
  final bool isActive;
  final bool isFeatured;
  final bool isCompleted;

  MiniSeriesModel({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelImage,
    required this.userId,
    required this.title,
    required this.description,
    required this.trailerUrl,
    required this.thumbnailUrl,
    required this.episodes,
    required this.totalEpisodes,
    required this.views,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.createdAt,
    this.lastEpisodeAt,
    required this.isActive,
    required this.isFeatured,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'channelId': channelId,
      'channelName': channelName,
      'channelImage': channelImage,
      'userId': userId,
      'title': title,
      'description': description,
      'trailerUrl': trailerUrl,
      'thumbnailUrl': thumbnailUrl,
      'episodes': episodes.map((ep) => ep.toMap()).toList(),
      'totalEpisodes': totalEpisodes,
      'views': views,
      'likes': likes,
      'comments': comments,
      'tags': tags,
      'createdAt': createdAt,
      'lastEpisodeAt': lastEpisodeAt,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isCompleted': isCompleted,
    };
  }

  factory MiniSeriesModel.fromMap(Map<String, dynamic> map, String id) {
    if (id.isEmpty) {
      debugPrint('WARNING: Creating MiniSeriesModel with empty ID');
    }

    List<MiniSeriesEpisode> episodes = [];
    if (map['episodes'] != null) {
      episodes = (map['episodes'] as List)
          .map((ep) => MiniSeriesEpisode.fromMap(ep))
          .toList();
    }

    return MiniSeriesModel(
      id: id,
      channelId: map['channelId'] ?? '',
      channelName: map['channelName'] ?? '',
      channelImage: map['channelImage'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      trailerUrl: map['trailerUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      episodes: episodes,
      totalEpisodes: map['totalEpisodes'] ?? 0,
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastEpisodeAt: map['lastEpisodeAt'],
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  MiniSeriesModel copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelImage,
    String? userId,
    String? title,
    String? description,
    String? trailerUrl,
    String? thumbnailUrl,
    List<MiniSeriesEpisode>? episodes,
    int? totalEpisodes,
    int? views,
    int? likes,
    int? comments,
    List<String>? tags,
    Timestamp? createdAt,
    Timestamp? lastEpisodeAt,
    bool? isActive,
    bool? isFeatured,
    bool? isCompleted,
  }) {
    return MiniSeriesModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelImage: channelImage ?? this.channelImage,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      episodes: episodes ?? this.episodes,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastEpisodeAt: lastEpisodeAt ?? this.lastEpisodeAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MiniSeriesEpisode {
  final String id;
  final int episodeNumber;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final Duration duration;
  final int views;
  final int likes;
  final int comments;
  final Timestamp createdAt;
  final bool isActive;

  MiniSeriesEpisode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.views,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episodeNumber': episodeNumber,
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration.inSeconds,
      'views': views,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory MiniSeriesEpisode.fromMap(Map<String, dynamic> map) {
    return MiniSeriesEpisode(
      id: map['id'] ?? '',
      episodeNumber: map['episodeNumber'] ?? 0,
      title: map['title'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      duration: Duration(seconds: map['duration'] ?? 0),
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  MiniSeriesEpisode copyWith({
    String? id,
    int? episodeNumber,
    String? title,
    String? videoUrl,
    String? thumbnailUrl,
    Duration? duration,
    int? views,
    int? likes,
    int? comments,
    Timestamp? createdAt,
    bool? isActive,
  }) {
    return MiniSeriesEpisode(
      id: id ?? this.id,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Extended video model to support mini-series trailers
class ChannelVideoModelExtended {
  final String id;
  final String channelId;
  final String channelName;
  final String channelImage;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int likes;
  final int comments;
  final int views;
  final int shares;
  final bool isLiked;
  final List<String> tags;
  final Timestamp createdAt;
  final bool isActive;
  final bool isFeatured;
  final bool isMultipleImages;
  final List<String> imageUrls;
  
  // Mini-series specific fields
  final bool isMiniSeries;
  final String? miniSeriesId;
  final String? miniSeriesTitle;
  final int? totalEpisodes;

  ChannelVideoModelExtended({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.channelImage,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.views,
    required this.shares,
    required this.isLiked,
    required this.tags,
    required this.createdAt,
    required this.isActive,
    required this.isFeatured,
    this.isMultipleImages = false,
    this.imageUrls = const [],
    this.isMiniSeries = false,
    this.miniSeriesId,
    this.miniSeriesTitle,
    this.totalEpisodes,
  });

  // Convert from existing ChannelVideoModel
  factory ChannelVideoModelExtended.fromChannelVideo(
    dynamic channelVideo, {
    bool isMiniSeries = false,
    String? miniSeriesId,
    String? miniSeriesTitle,
    int? totalEpisodes,
  }) {
    return ChannelVideoModelExtended(
      id: channelVideo.id,
      channelId: channelVideo.channelId,
      channelName: channelVideo.channelName,
      channelImage: channelVideo.channelImage,
      userId: channelVideo.userId,
      videoUrl: channelVideo.videoUrl,
      thumbnailUrl: channelVideo.thumbnailUrl,
      caption: channelVideo.caption,
      likes: channelVideo.likes,
      comments: channelVideo.comments,
      views: channelVideo.views,
      shares: channelVideo.shares,
      isLiked: channelVideo.isLiked,
      tags: channelVideo.tags,
      createdAt: channelVideo.createdAt,
      isActive: channelVideo.isActive,
      isFeatured: channelVideo.isFeatured,
      isMultipleImages: channelVideo.isMultipleImages,
      imageUrls: channelVideo.imageUrls,
      isMiniSeries: isMiniSeries,
      miniSeriesId: miniSeriesId,
      miniSeriesTitle: miniSeriesTitle,
      totalEpisodes: totalEpisodes,
    );
  }

  ChannelVideoModelExtended copyWith({
    String? id,
    String? channelId,
    String? channelName,
    String? channelImage,
    String? userId,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    int? likes,
    int? comments,
    int? views,
    int? shares,
    bool? isLiked,
    List<String>? tags,
    Timestamp? createdAt,
    bool? isActive,
    bool? isFeatured,
    bool? isMultipleImages,
    List<String>? imageUrls,
    bool? isMiniSeries,
    String? miniSeriesId,
    String? miniSeriesTitle,
    int? totalEpisodes,
  }) {
    return ChannelVideoModelExtended(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelImage: channelImage ?? this.channelImage,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
      isMiniSeries: isMiniSeries ?? this.isMiniSeries,
      miniSeriesId: miniSeriesId ?? this.miniSeriesId,
      miniSeriesTitle: miniSeriesTitle ?? this.miniSeriesTitle,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
    );
  }
}