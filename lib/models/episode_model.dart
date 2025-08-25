// lib/models/episode_model.dart
import 'package:textgb/constants.dart';

class EpisodeModel {
  final String episodeId;
  final String dramaId;               // Which drama this episode belongs to
  final int episodeNumber;            // Sequential: 1, 2, 3...
  final String episodeTitle;
  final String thumbnailUrl;
  final String videoUrl;
  final int videoDuration;            // Duration in seconds
  final int episodeViewCount;
  final String releasedAt;
  
  // Admin info
  final String uploadedBy;            // Admin UID who uploaded this episode
  final String createdAt;
  final String updatedAt;

  const EpisodeModel({
    required this.episodeId,
    required this.dramaId,
    required this.episodeNumber,
    required this.episodeTitle,
    this.thumbnailUrl = '',
    this.videoUrl = '',
    this.videoDuration = 0,
    this.episodeViewCount = 0,
    required this.releasedAt,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      episodeId: map[Constants.episodeId]?.toString() ?? '',
      dramaId: map[Constants.dramaId]?.toString() ?? '',
      episodeNumber: map[Constants.episodeNumber]?.toInt() ?? 1,
      episodeTitle: map[Constants.episodeTitle]?.toString() ?? '',
      thumbnailUrl: map[Constants.thumbnailUrl]?.toString() ?? '',
      videoUrl: map[Constants.videoUrl]?.toString() ?? '',
      videoDuration: map[Constants.videoDuration]?.toInt() ?? 0,
      episodeViewCount: map[Constants.episodeViewCount]?.toInt() ?? 0,
      releasedAt: map[Constants.releasedAt]?.toString() ?? '',
      uploadedBy: map[Constants.uploadedBy]?.toString() ?? '',
      createdAt: map[Constants.createdAt]?.toString() ?? '',
      updatedAt: map[Constants.updatedAt]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constants.episodeId: episodeId,
      Constants.dramaId: dramaId,
      Constants.episodeNumber: episodeNumber,
      Constants.episodeTitle: episodeTitle,
      Constants.thumbnailUrl: thumbnailUrl,
      Constants.videoUrl: videoUrl,
      Constants.videoDuration: videoDuration,
      Constants.episodeViewCount: episodeViewCount,
      Constants.releasedAt: releasedAt,
      Constants.uploadedBy: uploadedBy,
      Constants.createdAt: createdAt,
      Constants.updatedAt: updatedAt,
    };
  }

  EpisodeModel copyWith({
    String? episodeId,
    String? dramaId,
    int? episodeNumber,
    String? episodeTitle,
    String? thumbnailUrl,
    String? videoUrl,
    int? videoDuration,
    int? episodeViewCount,
    String? releasedAt,
    String? uploadedBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return EpisodeModel(
      episodeId: episodeId ?? this.episodeId,
      dramaId: dramaId ?? this.dramaId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      videoDuration: videoDuration ?? this.videoDuration,
      episodeViewCount: episodeViewCount ?? this.episodeViewCount,
      releasedAt: releasedAt ?? this.releasedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for episode logic
  bool get hasVideo => videoUrl.isNotEmpty;
  bool get hasThumbnail => thumbnailUrl.isNotEmpty;
  
  // Format duration for display
  String get formattedDuration {
    if (videoDuration <= 0) return '0:00';
    
    final minutes = videoDuration ~/ 60;
    final seconds = videoDuration % 60;
    
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Get episode display title
  String get displayTitle {
    if (episodeTitle.isNotEmpty) {
      return 'Ep $episodeNumber: $episodeTitle';
    }
    return 'Episode $episodeNumber';
  }

  // Get short episode title for lists
  String get shortTitle {
    if (episodeTitle.isNotEmpty) {
      return episodeTitle;
    }
    return 'Episode $episodeNumber';
  }

  // Check if episode is ready to watch
  bool get isWatchable => hasVideo && videoUrl.isNotEmpty;

  // Get episode status for admin
  String get statusText {
    if (!hasVideo) return 'No video';
    if (!hasThumbnail) return 'No thumbnail';
    return 'Ready';
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
    return 'EpisodeModel(episodeId: $episodeId, dramaId: $dramaId, episodeNumber: $episodeNumber, title: $episodeTitle)';
  }
}