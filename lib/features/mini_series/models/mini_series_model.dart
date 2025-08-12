// lib/features/mini_series/models/mini_series_model.dart
import 'package:textgb/constants.dart';

class MiniSeriesModel {
  final String seriesId;
  final String title;
  final String description;
  final String coverImageUrl;
  final String creatorUID;
  final String creatorName;
  final String creatorImage;
  final List<String> tags;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalEpisodes;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final bool isActive;
  final bool isPublished;
  final String language;
  final Map<String, dynamic> metadata;

  const MiniSeriesModel({
    required this.seriesId,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.creatorUID,
    required this.creatorName,
    required this.creatorImage,
    this.tags = const [],
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.totalEpisodes = 0,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.isActive = true,
    this.isPublished = false,
    this.language = 'en',
    this.metadata = const {},
  });

  factory MiniSeriesModel.fromMap(Map<String, dynamic> map) {
    return MiniSeriesModel(
      seriesId: map['seriesId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      coverImageUrl: map['coverImageUrl']?.toString() ?? '',
      creatorUID: map['creatorUID']?.toString() ?? '',
      creatorName: map['creatorName']?.toString() ?? '',
      creatorImage: map['creatorImage']?.toString() ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      category: map['category']?.toString() ?? 'general',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['createdAt']?.toString() ?? '0') ?? 0,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['updatedAt']?.toString() ?? '0') ?? 0,
      ),
      totalEpisodes: map['totalEpisodes']?.toInt() ?? 0,
      totalViews: map['totalViews']?.toInt() ?? 0,
      totalLikes: map['totalLikes']?.toInt() ?? 0,
      totalComments: map['totalComments']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      isPublished: map['isPublished'] ?? false,
      language: map['language']?.toString() ?? 'en',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesId': seriesId,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'creatorUID': creatorUID,
      'creatorName': creatorName,
      'creatorImage': creatorImage,
      'tags': tags,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch.toString(),
      'updatedAt': updatedAt.millisecondsSinceEpoch.toString(),
      'totalEpisodes': totalEpisodes,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'isActive': isActive,
      'isPublished': isPublished,
      'language': language,
      'metadata': metadata,
    };
  }

  MiniSeriesModel copyWith({
    String? seriesId,
    String? title,
    String? description,
    String? coverImageUrl,
    String? creatorUID,
    String? creatorName,
    String? creatorImage,
    List<String>? tags,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalEpisodes,
    int? totalViews,
    int? totalLikes,
    int? totalComments,
    bool? isActive,
    bool? isPublished,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    return MiniSeriesModel(
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      creatorUID: creatorUID ?? this.creatorUID,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      totalViews: totalViews ?? this.totalViews,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      language: language ?? this.language,
      metadata: metadata ?? this.metadata,
    );
  }
}

