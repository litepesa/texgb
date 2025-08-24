// ============================================================================

// lib/features/series/models/series_episode_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeriesEpisodeModel {
  final String id;
  final String seriesId;
  final String seriesTitle;
  final String seriesImage;
  final int episodeNumber;               // Sequential: 1, 2, 3...
  final String title;                    // Episode title
  final String description;
  final String creatorId;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSeconds;             // Max 120 seconds (2 minutes)
  final bool isFeatured;                 // Featured episodes appear in main feed
  
  // Engagement metrics
  final int likes;
  final int comments;
  final int views;
  final int shares;
  final bool isLiked;                    // For current user
  
  // Content metadata
  final List<String> tags;
  final Timestamp createdAt;
  final bool isActive;
  
  // Media support (keep existing functionality)
  final bool isMultipleImages;
  final List<String> imageUrls;

  SeriesEpisodeModel({
    required this.id,
    required this.seriesId,
    required this.seriesTitle,
    required this.seriesImage,
    required this.episodeNumber,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.isFeatured,
    required this.likes,
    required this.comments,
    required this.views,
    required this.shares,
    required this.isLiked,
    required this.tags,
    required this.createdAt,
    required this.isActive,
    this.isMultipleImages = false,
    this.imageUrls = const [],
  });

  // Helper getters
  String get formattedDuration {
    if (durationSeconds <= 0) return '0:00';
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get episodeTitle => 'Episode $episodeNumber: $title';
  String get shortEpisodeTitle => 'Ep $episodeNumber';
  bool get isValidDuration => durationSeconds <= 120; // 2 minutes max
  Duration get duration => Duration(seconds: durationSeconds);

  Map<String, dynamic> toMap() {
    return {
      'seriesId': seriesId,
      'seriesTitle': seriesTitle,
      'seriesImage': seriesImage,
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'isFeatured': isFeatured,
      'likes': likes,
      'comments': comments,
      'views': views,
      'shares': shares,
      'tags': tags,
      'createdAt': createdAt,
      'isActive': isActive,
      'isMultipleImages': isMultipleImages,
      'imageUrls': imageUrls,
    };
  }

  factory SeriesEpisodeModel.fromMap(Map<String, dynamic> map, {String? id, bool isLiked = false}) {
    final episodeId = id ?? map['id'] ?? '';
    
    if (episodeId.isEmpty) {
      debugPrint('WARNING: Creating SeriesEpisodeModel with empty ID');
    }
    
    return SeriesEpisodeModel(
      id: episodeId,
      seriesId: map['seriesId'] ?? '',
      seriesTitle: map['seriesTitle'] ?? '',
      seriesImage: map['seriesImage'] ?? '',
      episodeNumber: map['episodeNumber'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      views: map['views'] ?? 0,
      shares: map['shares'] ?? 0,
      isLiked: isLiked,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      isMultipleImages: map['isMultipleImages'] ?? false,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  SeriesEpisodeModel copyWith({
    String? id,
    String? seriesId,
    String? seriesTitle,
    String? seriesImage,
    int? episodeNumber,
    String? title,
    String? description,
    String? creatorId,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    bool? isFeatured,
    int? likes,
    int? comments,
    int? views,
    int? shares,
    bool? isLiked,
    List<String>? tags,
    Timestamp? createdAt,
    bool? isActive,
    bool? isMultipleImages,
    List<String>? imageUrls,
  }) {
    return SeriesEpisodeModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesImage: seriesImage ?? this.seriesImage,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isFeatured: isFeatured ?? this.isFeatured,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isMultipleImages: isMultipleImages ?? this.isMultipleImages,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  String toString() {
    return 'SeriesEpisodeModel(id: $id, series: $seriesTitle, episode: $episodeNumber, featured: $isFeatured)';
  }
}

