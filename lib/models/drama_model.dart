// lib/models/drama_model.dart - SIMPLIFIED UNIFIED MODEL
import 'package:textgb/constants.dart';

class DramaModel {
  final String dramaId;
  final String title;
  final String description;
  final String bannerImage;
  final List<String> episodeVideos;   // Video URLs for episodes 1, 2, 3... up to 100
  final bool isPremium;
  final int freeEpisodesCount;        // How many episodes are free (for premium dramas)
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;
  final bool isActive;
  
  // Admin info
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  const DramaModel({
    required this.dramaId,
    required this.title,
    required this.description,
    this.bannerImage = '',
    this.episodeVideos = const [],
    this.isPremium = false,
    this.freeEpisodesCount = 0,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isFeatured = false,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating new drama
  factory DramaModel.create({
    required String title,
    required String description,
    required String createdBy,
    required List<String> episodeVideos, // All episodes provided at creation
    String bannerImage = '',
    bool isPremium = false,
    int freeEpisodesCount = 0,
    bool isFeatured = false,
    bool isActive = true,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return DramaModel(
      dramaId: '', // Will be set by backend
      title: title,
      description: description,
      bannerImage: bannerImage,
      episodeVideos: episodeVideos,
      isPremium: isPremium,
      freeEpisodesCount: freeEpisodesCount,
      isFeatured: isFeatured,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DramaModel.fromMap(Map<String, dynamic> map) {
    // Handle episodeVideos as either List<String> or List<dynamic>
    List<String> episodes = [];
    if (map[Constants.episodeVideos] != null) {
      final dynamic episodeData = map[Constants.episodeVideos];
      if (episodeData is List) {
        episodes = episodeData.map((e) => e.toString()).toList();
      }
    }

    return DramaModel(
      dramaId: map[Constants.dramaId]?.toString() ?? '',
      title: map[Constants.title]?.toString() ?? '',
      description: map[Constants.description]?.toString() ?? '',
      bannerImage: map[Constants.bannerImage]?.toString() ?? '',
      episodeVideos: episodes,
      isPremium: map[Constants.isPremium] ?? false,
      freeEpisodesCount: map[Constants.freeEpisodesCount]?.toInt() ?? 0,
      viewCount: map[Constants.viewCount]?.toInt() ?? 0,
      favoriteCount: map[Constants.favoriteCount]?.toInt() ?? 0,
      isFeatured: map[Constants.isFeatured] ?? false,
      isActive: map[Constants.isActive] ?? true,
      createdBy: map[Constants.createdBy]?.toString() ?? '',
      createdAt: map[Constants.createdAt]?.toString() ?? '',
      updatedAt: map[Constants.updatedAt]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      Constants.title: title,
      Constants.description: description,
      Constants.bannerImage: bannerImage,
      Constants.episodeVideos: episodeVideos,
      Constants.isPremium: isPremium,
      Constants.freeEpisodesCount: freeEpisodesCount,
      Constants.viewCount: viewCount,
      Constants.favoriteCount: favoriteCount,
      Constants.isFeatured: isFeatured,
      Constants.isActive: isActive,
      Constants.createdBy: createdBy,
      Constants.createdAt: createdAt,
      Constants.updatedAt: updatedAt,
      // Note: dramaId excluded for creation
    };
  }

  Map<String, dynamic> toMap() {
    final map = toCreateMap();
    if (dramaId.isNotEmpty) {
      map[Constants.dramaId] = dramaId;
    }
    return map;
  }

  DramaModel copyWith({
    String? dramaId,
    String? title,
    String? description,
    String? bannerImage,
    List<String>? episodeVideos,
    bool? isPremium,
    int? freeEpisodesCount,
    int? viewCount,
    int? favoriteCount,
    bool? isFeatured,
    bool? isActive,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return DramaModel(
      dramaId: dramaId ?? this.dramaId,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerImage: bannerImage ?? this.bannerImage,
      episodeVideos: episodeVideos ?? this.episodeVideos,
      isPremium: isPremium ?? this.isPremium,
      freeEpisodesCount: freeEpisodesCount ?? this.freeEpisodesCount,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  int get totalEpisodes => episodeVideos.length;
  bool get hasEpisodes => episodeVideos.isNotEmpty;
  bool get isFree => !isPremium;
  
  // Get video URL for specific episode (1-indexed)
  String? getEpisodeVideo(int episodeNumber) {
    if (episodeNumber < 1 || episodeNumber > episodeVideos.length) {
      return null;
    }
    return episodeVideos[episodeNumber - 1]; // Convert to 0-indexed
  }

  // Check if user can watch specific episode
  bool canWatchEpisode(int episodeNumber, bool hasUnlockedDrama) {
    if (episodeNumber < 1 || episodeNumber > totalEpisodes) return false;
    if (!isPremium) return true; // All episodes free
    if (episodeNumber <= freeEpisodesCount) return true; // Free episodes
    return hasUnlockedDrama; // Premium episodes require unlock
  }

  // Get episode title for display
  String getEpisodeTitle(int episodeNumber) {
    return 'Episode $episodeNumber';
  }

  // Validation for creation
  bool get isValidForCreation {
    return title.trim().isNotEmpty &&
           description.trim().isNotEmpty &&
           episodeVideos.isNotEmpty &&
           episodeVideos.length <= 100 && // Max 100 episodes
           createdBy.isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    if (title.trim().isEmpty) errors.add('Title is required');
    if (description.trim().isEmpty) errors.add('Description is required');
    if (episodeVideos.isEmpty) errors.add('At least one episode is required');
    if (episodeVideos.length > 100) errors.add('Maximum 100 episodes allowed');
    if (createdBy.isEmpty) errors.add('Creator is required');
    if (isPremium && freeEpisodesCount > episodeVideos.length) {
      errors.add('Free episodes cannot exceed total episodes');
    }
    return errors;
  }

  // Get premium info for display
  String get premiumInfo {
    if (!isPremium) return 'Free Drama - All episodes included';
    if (freeEpisodesCount == 0) return 'Premium Drama - Unlock required for all episodes';
    if (freeEpisodesCount >= totalEpisodes) return 'Free Drama - All episodes included';
    return 'First $freeEpisodesCount episodes free, unlock for remaining ${totalEpisodes - freeEpisodesCount}';
  }

  @override
  String toString() {
    return 'DramaModel(dramaId: $dramaId, title: $title, episodes: ${episodeVideos.length})';
  }
}

// SIMPLIFIED EPISODE CLASS (for UI convenience only)
class Episode {
  final int number;
  final String videoUrl;
  final String dramaId;
  final String dramaTitle;

  const Episode({
    required this.number,
    required this.videoUrl,
    required this.dramaId,
    required this.dramaTitle,
  });

  // Helper methods
  String get title => 'Episode $number';
  String get displayTitle => '$dramaTitle - Episode $number';
  bool get hasVideo => videoUrl.isNotEmpty;
  
  // Create from drama and episode number
  factory Episode.fromDrama(DramaModel drama, int episodeNumber) {
    final videoUrl = drama.getEpisodeVideo(episodeNumber) ?? '';
    return Episode(
      number: episodeNumber,
      videoUrl: videoUrl,
      dramaId: drama.dramaId,
      dramaTitle: drama.title,
    );
  }
}