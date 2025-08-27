// lib/models/drama_model.dart
import 'package:textgb/constants.dart';

class DramaModel {
  final String dramaId;
  final String title;
  final String description;
  final String bannerImage;
  final int totalEpisodes;
  final bool isPremium;
  final int freeEpisodesCount;        // How many episodes are free (admin sets per drama)
  final int viewCount;
  final int favoriteCount;
  final bool isFeatured;              // Featured in main feed
  final String publishedAt;
  final bool isActive;                // Admin can activate/deactivate
  
  // Admin info
  final String createdBy;             // Admin UID who created this drama
  final String createdAt;
  final String updatedAt;

  const DramaModel({
    required this.dramaId,
    required this.title,
    required this.description,
    this.bannerImage = '',
    this.totalEpisodes = 0,
    this.isPremium = false,
    this.freeEpisodesCount = 0,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isFeatured = false,
    required this.publishedAt,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper method to create RFC3339 timestamps
  static String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // Factory constructor for creating new drama with current timestamps
  factory DramaModel.create({
    required String title,
    required String description,
    required String createdBy,
    String bannerImage = '',
    bool isPremium = false,
    int freeEpisodesCount = 0,
    bool isFeatured = false,
    bool isActive = true,
  }) {
    final now = DramaModel._createTimestamp();
    return DramaModel(
      dramaId: '', // Will be set by backend
      title: title,
      description: description,
      bannerImage: bannerImage,
      isPremium: isPremium,
      freeEpisodesCount: freeEpisodesCount,
      isFeatured: isFeatured,
      isActive: isActive,
      publishedAt: now,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DramaModel.fromMap(Map<String, dynamic> map) {
    return DramaModel(
      dramaId: map[Constants.dramaId]?.toString() ?? '',
      title: map[Constants.title]?.toString() ?? '',
      description: map[Constants.description]?.toString() ?? '',
      bannerImage: map[Constants.bannerImage]?.toString() ?? '',
      totalEpisodes: map[Constants.totalEpisodes]?.toInt() ?? 0,
      isPremium: map[Constants.isPremium] ?? false,
      freeEpisodesCount: map[Constants.freeEpisodesCount]?.toInt() ?? 0,
      viewCount: map[Constants.viewCount]?.toInt() ?? 0,
      favoriteCount: map[Constants.favoriteCount]?.toInt() ?? 0,
      isFeatured: map[Constants.isFeatured] ?? false,
      publishedAt: map[Constants.publishedAt]?.toString() ?? '',
      isActive: map[Constants.isActive] ?? true,
      createdBy: map[Constants.createdBy]?.toString() ?? '',
      createdAt: map[Constants.createdAt]?.toString() ?? '',
      updatedAt: map[Constants.updatedAt]?.toString() ?? '',
    );
  }

  // Updated toMap with conditional dramaId inclusion
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      Constants.title: title,
      Constants.description: description,
      Constants.bannerImage: bannerImage,
      Constants.totalEpisodes: totalEpisodes,
      Constants.isPremium: isPremium,
      Constants.freeEpisodesCount: freeEpisodesCount,
      Constants.viewCount: viewCount,
      Constants.favoriteCount: favoriteCount,
      Constants.isFeatured: isFeatured,
      Constants.publishedAt: publishedAt,
      Constants.isActive: isActive,
      Constants.createdBy: createdBy,
      Constants.createdAt: createdAt,
      Constants.updatedAt: updatedAt,
    };

    // Only include dramaId if it's not empty and includeId is true
    if (includeId && dramaId.isNotEmpty) {
      map[Constants.dramaId] = dramaId;
    }

    return map;
  }

  // Separate method specifically for creation requests (excludes dramaId completely)
  Map<String, dynamic> toCreateMap() {
    return {
      Constants.title: title,
      Constants.description: description,
      Constants.bannerImage: bannerImage,
      Constants.totalEpisodes: totalEpisodes,
      Constants.isPremium: isPremium,
      Constants.freeEpisodesCount: freeEpisodesCount,
      Constants.viewCount: viewCount,
      Constants.favoriteCount: favoriteCount,
      Constants.isFeatured: isFeatured,
      Constants.publishedAt: publishedAt,
      Constants.isActive: isActive,
      Constants.createdBy: createdBy,
      Constants.createdAt: createdAt,
      Constants.updatedAt: updatedAt,
      // Note: dramaId is intentionally excluded for creation
    };
  }

  DramaModel copyWith({
    String? dramaId,
    String? title,
    String? description,
    String? bannerImage,
    int? totalEpisodes,
    bool? isPremium,
    int? freeEpisodesCount,
    int? viewCount,
    int? favoriteCount,
    bool? isFeatured,
    String? publishedAt,
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
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      isPremium: isPremium ?? this.isPremium,
      freeEpisodesCount: freeEpisodesCount ?? this.freeEpisodesCount,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to update timestamps when modifying
  DramaModel withUpdatedTimestamp() {
    return copyWith(updatedAt: _createTimestamp());
  }

  // Helper methods for drama logic
  bool get isFree => !isPremium;
  bool get hasPremiumContent => isPremium && totalEpisodes > freeEpisodesCount;
  int get paidEpisodesCount => isPremium ? totalEpisodes - freeEpisodesCount : 0;
  
  // Check if specific episode is free
  bool isEpisodeFree(int episodeNumber) {
    if (!isPremium) return true; // All episodes free for free dramas
    return episodeNumber <= freeEpisodesCount; // First X episodes are free for premium dramas
  }
  
  // Check if user can watch specific episode
  bool canWatchEpisode(int episodeNumber, bool hasUnlockedDrama) {
    if (!isPremium) return true; // All episodes free
    if (episodeNumber <= freeEpisodesCount) return true; // Free episodes
    return hasUnlockedDrama; // Premium episodes require unlock
  }

  // Get drama status for display
  String get statusText {
    if (!isActive) return 'Inactive';
    if (totalEpisodes == 0) return 'Coming Soon';
    return 'Available';
  }

  // Get premium info for display
  String get premiumInfo {
    if (!isPremium) return 'Free Drama';
    if (freeEpisodesCount == 0) return 'Premium Drama';
    return 'First $freeEpisodesCount episodes free';
  }

  // Parse datetime helpers
  DateTime? get createdAtDateTime {
    try {
      return createdAt.isNotEmpty ? DateTime.parse(createdAt) : null;
    } catch (e) {
      return null;
    }
  }

  DateTime? get updatedAtDateTime {
    try {
      return updatedAt.isNotEmpty ? DateTime.parse(updatedAt) : null;
    } catch (e) {
      return null;
    }
  }

  DateTime? get publishedAtDateTime {
    try {
      return publishedAt.isNotEmpty ? DateTime.parse(publishedAt) : null;
    } catch (e) {
      return null;
    }
  }

  // Validation helpers
  bool get isValidForCreation {
    return title.trim().isNotEmpty &&
           description.trim().isNotEmpty &&
           createdBy.isNotEmpty &&
           createdAt.isNotEmpty &&
           updatedAt.isNotEmpty &&
           publishedAt.isNotEmpty;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    if (title.trim().isEmpty) errors.add('Title is required');
    if (description.trim().isEmpty) errors.add('Description is required');
    if (createdBy.isEmpty) errors.add('Created by is required');
    if (isPremium && freeEpisodesCount < 0) errors.add('Free episodes count cannot be negative');
    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DramaModel && other.dramaId == dramaId;
  }

  @override
  int get hashCode => dramaId.hashCode;

  @override
  String toString() {
    return 'DramaModel(dramaId: $dramaId, title: $title, isPremium: $isPremium, episodes: $totalEpisodes, createdAt: $createdAt)';
  }
}