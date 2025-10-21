// ===============================
// lib/features/series/models/series_model.dart
// Premium Video Series Model (Verified Users Only)
// 
// FEATURES:
// 1. Multi-episode video series (up to 100 episodes)
// 2. Monetization (10-1,000 KES unlock price)
// 3. Freemium model (1-20 free episodes)
// 4. Creator-controlled affiliate program
// 5. Revenue tracking (70% creator, 30% platform, optional affiliate)
// 6. Progress tracking per user
// 7. Minimal interactions (likes only)
// 8. Analytics & performance metrics
// ===============================

import 'dart:convert';

class SeriesModel {
  // Core identification
  final String id;
  final String title;
  final String description;
  final String bannerImage;              // Series cover/poster
  
  // Creator information (VERIFIED USERS ONLY)
  final String creatorId;
  final String creatorName;
  final String creatorImage;
  final bool isVerified;                 // Must be true to create series
  
  // Episodes (video only, up to 100 episodes)
  final List<String> episodeVideoUrls;   // Video URLs for each episode
  final List<String> episodeThumbnails;  // Thumbnail for each episode
  final List<int> episodeDurations;      // Duration in seconds (max 120 per episode)
  
  // Monetization (ALWAYS premium)
  final bool isPremium;                  // Always true for series
  final double unlockPrice;              // 10-1,000 KES range
  final int freeEpisodesCount;           // 1-20 free episodes (teaser)
  
  // AFFILIATE PROGRAM CONTROLS (Creator decides)
  final bool allowReposts;               // Can users repost this series?
  final bool hasAffiliateProgram;        // Enable commission for promoters?
  final double affiliateCommission;      // 0.01-0.15 (1%-15% of unlock price)
  
  // Engagement metrics
  final int viewCount;                   // Total series views
  final int unlockCount;                 // Number of purchases
  final int favoriteCount;               // Bookmarks/favorites
  final int likes;                       // Simple like count
  
  // Series properties
  final bool isActive;                   // Is series visible?
  final bool isFeatured;                 // Featured on platform?
  final List<String> tags;               // Categories/genres
  
  // Timestamps
  final String createdAt;                // RFC3339 format
  final String updatedAt;                // RFC3339 format

  // Runtime state (not stored in DB)
  final bool hasUnlocked;                // Did current user unlock?
  final bool isFavorited;                // Did current user favorite?
  final bool isLiked;                    // Did current user like?
  final int currentEpisode;              // User's progress (1-based)

  const SeriesModel({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerImage,
    required this.creatorId,
    required this.creatorName,
    required this.creatorImage,
    this.isVerified = true,              // Series require verification
    required this.episodeVideoUrls,
    this.episodeThumbnails = const [],
    this.episodeDurations = const [],
    this.isPremium = true,               // Series are always premium
    required this.unlockPrice,
    required this.freeEpisodesCount,
    this.allowReposts = true,            // Default: reposts allowed
    this.hasAffiliateProgram = false,    // Default: no affiliate
    this.affiliateCommission = 0.0,      // Default: 0% commission
    this.viewCount = 0,
    this.unlockCount = 0,
    this.favoriteCount = 0,
    this.likes = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.hasUnlocked = false,
    this.isFavorited = false,
    this.isLiked = false,
    this.currentEpisode = 1,
  });

  // ===============================
  // FACTORY CONSTRUCTORS
  // ===============================

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    try {
      return SeriesModel(
        id: _parseString(json['id']),
        title: _parseString(json['title']),
        description: _parseString(json['description']),
        bannerImage: _parseString(json['bannerImage'] ?? json['banner_image']),
        
        creatorId: _parseString(json['creatorId'] ?? json['creator_id']),
        creatorName: _parseString(json['creatorName'] ?? json['creator_name']),
        creatorImage: _parseString(json['creatorImage'] ?? json['creator_image']),
        isVerified: _parseBool(json['isVerified'] ?? json['is_verified'] ?? true),
        
        episodeVideoUrls: _parseStringList(json['episodeVideoUrls'] ?? json['episode_video_urls']),
        episodeThumbnails: _parseStringList(json['episodeThumbnails'] ?? json['episode_thumbnails']),
        episodeDurations: _parseIntList(json['episodeDurations'] ?? json['episode_durations']),
        
        isPremium: _parseBool(json['isPremium'] ?? json['is_premium'] ?? true),
        unlockPrice: _parsePrice(json['unlockPrice'] ?? json['unlock_price']),
        freeEpisodesCount: _parseInt(json['freeEpisodesCount'] ?? json['free_episodes_count'] ?? 1),
        
        allowReposts: _parseBool(json['allowReposts'] ?? json['allow_reposts'] ?? true),
        hasAffiliateProgram: _parseBool(json['hasAffiliateProgram'] ?? json['has_affiliate_program'] ?? false),
        affiliateCommission: _parseDouble(json['affiliateCommission'] ?? json['affiliate_commission'] ?? 0.0),
        
        viewCount: _parseInt(json['viewCount'] ?? json['view_count'] ?? 0),
        unlockCount: _parseInt(json['unlockCount'] ?? json['unlock_count'] ?? 0),
        favoriteCount: _parseInt(json['favoriteCount'] ?? json['favorite_count'] ?? 0),
        likes: _parseInt(json['likes'] ?? json['likesCount'] ?? json['likes_count'] ?? 0),
        
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        isFeatured: _parseBool(json['isFeatured'] ?? json['is_featured'] ?? false),
        tags: _parseStringList(json['tags']),
        
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
        
        hasUnlocked: _parseBool(json['hasUnlocked'] ?? false),
        isFavorited: _parseBool(json['isFavorited'] ?? false),
        isLiked: _parseBool(json['isLiked'] ?? false),
        currentEpisode: _parseInt(json['currentEpisode'] ?? 1),
      );
    } catch (e) {
      print('❌ Error parsing SeriesModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return safe default
      return SeriesModel(
        id: _parseString(json['id'] ?? ''),
        title: _parseString(json['title'] ?? 'Untitled Series'),
        description: _parseString(json['description'] ?? ''),
        bannerImage: '',
        creatorId: _parseString(json['creatorId'] ?? ''),
        creatorName: _parseString(json['creatorName'] ?? 'Unknown'),
        creatorImage: '',
        episodeVideoUrls: [],
        unlockPrice: 100.0,
        freeEpisodesCount: 1,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  // Factory for creating new series
  factory SeriesModel.create({
    required String title,
    required String description,
    required String bannerImage,
    required String creatorId,
    required String creatorName,
    required String creatorImage,
    required List<String> episodeVideoUrls,
    List<String>? episodeThumbnails,
    List<int>? episodeDurations,
    required double unlockPrice,
    required int freeEpisodesCount,
    bool allowReposts = true,
    bool hasAffiliateProgram = false,
    double affiliateCommission = 0.0,
    List<String>? tags,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    
    return SeriesModel(
      id: '', // Will be set by backend
      title: title,
      description: description,
      bannerImage: bannerImage,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorImage: creatorImage,
      isVerified: true,
      episodeVideoUrls: episodeVideoUrls,
      episodeThumbnails: episodeThumbnails ?? [],
      episodeDurations: episodeDurations ?? [],
      unlockPrice: unlockPrice,
      freeEpisodesCount: freeEpisodesCount,
      allowReposts: allowReposts,
      hasAffiliateProgram: hasAffiliateProgram,
      affiliateCommission: affiliateCommission,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===============================
  // PARSING HELPERS
  // ===============================

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is double) return value < 0 ? 0 : value.round();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? parsed : 0;
    }
    return 0;
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value < 0 ? 0.0 : value;
    if (value is int) return value < 0 ? 0.0 : value.toDouble();
    
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      final parsed = double.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? parsed : 0.0;
    }
    
    return 0.0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // PostgreSQL array format: {item1,item2}
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        return content
            .split(',')
            .map((item) {
              final cleaned = item.trim();
              if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                return cleaned.substring(1, cleaned.length - 1);
              }
              return cleaned;
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      // JSON array format
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded
                .map((e) => e?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON array: $trimmed');
        }
      }
      
      return [trimmed];
    }
    
    return [];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    
    if (value is List) {
      return value
          .map((e) {
            if (e is int) return e;
            if (e is double) return e.round();
            if (e is String) return int.tryParse(e) ?? 0;
            return 0;
          })
          .where((i) => i >= 0)
          .toList();
    }
    
    if (value is String && value.isNotEmpty) {
      final trimmed = value.trim();
      
      // PostgreSQL array format
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        if (content.isEmpty) return [];
        
        return content
            .split(',')
            .map((item) {
              final cleaned = item.trim().replaceAll('"', '');
              return int.tryParse(cleaned) ?? 0;
            })
            .where((i) => i >= 0)
            .toList();
      }
      
      // JSON array format
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is List) {
            return decoded
                .map((e) => e is int ? e : (e is double ? e.round() : 0))
                .where((i) => i >= 0)
                .toList();
          }
        } catch (e) {
          print('⚠️ Warning: Could not parse JSON int array: $trimmed');
        }
      }
    }
    
    return [];
  }

  static String _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return DateTime.now().toIso8601String();
      
      try {
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    return DateTime.now().toIso8601String();
  }

  // ===============================
  // CONVERSION METHODS
  // ===============================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'bannerImage': bannerImage,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImage': creatorImage,
      'isVerified': isVerified,
      'episodeVideoUrls': episodeVideoUrls,
      'episodeThumbnails': episodeThumbnails,
      'episodeDurations': episodeDurations,
      'isPremium': isPremium,
      'unlockPrice': unlockPrice,
      'freeEpisodesCount': freeEpisodesCount,
      'allowReposts': allowReposts,
      'hasAffiliateProgram': hasAffiliateProgram,
      'affiliateCommission': affiliateCommission,
      'viewCount': viewCount,
      'unlockCount': unlockCount,
      'favoriteCount': favoriteCount,
      'likes': likes,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'hasUnlocked': hasUnlocked,
      'isFavorited': isFavorited,
      'isLiked': isLiked,
      'currentEpisode': currentEpisode,
    };
  }

  SeriesModel copyWith({
    String? id,
    String? title,
    String? description,
    String? bannerImage,
    String? creatorId,
    String? creatorName,
    String? creatorImage,
    bool? isVerified,
    List<String>? episodeVideoUrls,
    List<String>? episodeThumbnails,
    List<int>? episodeDurations,
    bool? isPremium,
    double? unlockPrice,
    int? freeEpisodesCount,
    bool? allowReposts,
    bool? hasAffiliateProgram,
    double? affiliateCommission,
    int? viewCount,
    int? unlockCount,
    int? favoriteCount,
    int? likes,
    bool? isActive,
    bool? isFeatured,
    List<String>? tags,
    String? createdAt,
    String? updatedAt,
    bool? hasUnlocked,
    bool? isFavorited,
    bool? isLiked,
    int? currentEpisode,
  }) {
    return SeriesModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerImage: bannerImage ?? this.bannerImage,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      isVerified: isVerified ?? this.isVerified,
      episodeVideoUrls: episodeVideoUrls ?? this.episodeVideoUrls,
      episodeThumbnails: episodeThumbnails ?? this.episodeThumbnails,
      episodeDurations: episodeDurations ?? this.episodeDurations,
      isPremium: isPremium ?? this.isPremium,
      unlockPrice: unlockPrice ?? this.unlockPrice,
      freeEpisodesCount: freeEpisodesCount ?? this.freeEpisodesCount,
      allowReposts: allowReposts ?? this.allowReposts,
      hasAffiliateProgram: hasAffiliateProgram ?? this.hasAffiliateProgram,
      affiliateCommission: affiliateCommission ?? this.affiliateCommission,
      viewCount: viewCount ?? this.viewCount,
      unlockCount: unlockCount ?? this.unlockCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      likes: likes ?? this.likes,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasUnlocked: hasUnlocked ?? this.hasUnlocked,
      isFavorited: isFavorited ?? this.isFavorited,
      isLiked: isLiked ?? this.isLiked,
      currentEpisode: currentEpisode ?? this.currentEpisode,
    );
  }

  // ===============================
  // EPISODE HELPERS
  // ===============================

  int get totalEpisodes => episodeVideoUrls.length;
  
  bool get hasEpisodes => episodeVideoUrls.isNotEmpty;
  
  int get lockedEpisodesCount => totalEpisodes - freeEpisodesCount;
  
  bool get hasLockedEpisodes => lockedEpisodesCount > 0;

  // Get video URL for specific episode (1-indexed)
  String? getEpisodeVideo(int episodeNumber) {
    if (episodeNumber < 1 || episodeNumber > totalEpisodes) return null;
    return episodeVideoUrls[episodeNumber - 1];
  }

  // Get thumbnail for specific episode (1-indexed)
  String? getEpisodeThumbnail(int episodeNumber) {
    if (episodeNumber < 1 || episodeNumber > episodeThumbnails.length) return null;
    return episodeThumbnails[episodeNumber - 1];
  }

  // Get duration for specific episode (1-indexed)
  int? getEpisodeDuration(int episodeNumber) {
    if (episodeNumber < 1 || episodeNumber > episodeDurations.length) return null;
    return episodeDurations[episodeNumber - 1];
  }

  // Check if user can watch specific episode
  bool canWatchEpisode(int episodeNumber) {
    if (episodeNumber < 1 || episodeNumber > totalEpisodes) return false;
    if (episodeNumber <= freeEpisodesCount) return true; // Free episodes
    return hasUnlocked; // Premium episodes require unlock
  }

  // Get episode title for display
  String getEpisodeTitle(int episodeNumber) {
    return 'Episode $episodeNumber';
  }

  // Get formatted duration for episode
  String? getFormattedEpisodeDuration(int episodeNumber) {
    final duration = getEpisodeDuration(episodeNumber);
    if (duration == null) return null;
    
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Total series duration in minutes
  int get totalDurationMinutes {
    if (episodeDurations.isEmpty) return 0;
    final totalSeconds = episodeDurations.fold<int>(0, (sum, duration) => sum + duration);
    return (totalSeconds / 60).ceil();
  }

  String get formattedTotalDuration {
    final minutes = totalDurationMinutes;
    if (minutes < 60) return '${minutes}min';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}min';
  }

  // ===============================
  // PRICING & REVENUE
  // ===============================

  // Format price for display
  String get formattedPrice {
    if (unlockPrice == 0) return 'Free';
    
    if (unlockPrice < 1000) {
      return 'KES ${unlockPrice.toInt()}';
    } else {
      return 'KES ${(unlockPrice / 1000).toStringAsFixed(1)}K';
    }
  }

  // AFFILIATE COMMISSION DISPLAY
  String get formattedAffiliateCommission {
    if (!hasAffiliateProgram || affiliateCommission == 0) return '0%';
    return '${(affiliateCommission * 100).toStringAsFixed(0)}%';
  }

  double get affiliateCommissionAmount {
    return unlockPrice * affiliateCommission;
  }

  String get formattedAffiliateAmount {
    if (!hasAffiliateProgram) return 'KES 0';
    final amount = affiliateCommissionAmount;
    return 'KES ${amount.toInt()}';
  }

  // REVENUE SPLITS (With Affiliate)
  // Total revenue generated
  double get totalRevenue => unlockCount * unlockPrice;

  // Creator earnings (adjusted for affiliate)
  double get creatorEarnings {
    if (hasAffiliateProgram) {
      // Creator gets: (100% - 30% platform - affiliate%)
      final creatorPercentage = 1.0 - 0.3 - affiliateCommission;
      return totalRevenue * creatorPercentage;
    }
    // No affiliate: Creator gets 70%
    return totalRevenue * 0.7;
  }

  // Platform revenue (always 30%)
  double get platformRevenue => totalRevenue * 0.3;

  // Total affiliate earnings paid out
  double get totalAffiliateEarnings {
    if (!hasAffiliateProgram) return 0.0;
    return totalRevenue * affiliateCommission;
  }

  // Formatted revenue
  String get formattedTotalRevenue {
    if (totalRevenue == 0) return 'KES 0';
    
    if (totalRevenue < 1000000) {
      return 'KES ${totalRevenue.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      final millions = totalRevenue / 1000000;
      return 'KES ${millions.toStringAsFixed(1)}M';
    }
  }

  String get formattedCreatorEarnings {
    if (creatorEarnings == 0) return 'KES 0';
    
    if (creatorEarnings < 1000000) {
      return 'KES ${creatorEarnings.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      final millions = creatorEarnings / 1000000;
      return 'KES ${millions.toStringAsFixed(1)}M';
    }
  }

  // Conversion rate (views to unlocks)
  double get conversionRate {
    if (viewCount == 0) return 0.0;
    return (unlockCount / viewCount) * 100.0;
  }

  String get formattedConversionRate {
    return '${conversionRate.toStringAsFixed(1)}%';
  }

  // Revenue per view
  double get revenuePerView {
    if (viewCount == 0) return 0.0;
    return totalRevenue / viewCount;
  }

  // ===============================
  // PERFORMANCE METRICS
  // ===============================

  bool get isProfitable => unlockCount > 0;
  
  bool get isPopular => viewCount > 1000;
  
  bool get isHighConverting => conversionRate > 5.0;

  String get performanceLevel {
    if (unlockCount == 0) return 'No Sales';
    if (conversionRate > 10) return 'Excellent';
    if (conversionRate > 5) return 'Good';
    if (conversionRate > 2) return 'Average';
    return 'Needs Improvement';
  }

  // Engagement score (0-100)
  double get engagementScore {
    if (viewCount == 0) return 0.0;
    
    final viewScore = viewCount * 1.0;
    final favoriteScore = favoriteCount * 5.0;
    final unlockScore = unlockCount * 20.0;
    final likeScore = likes * 2.0;
    
    final totalScore = viewScore + favoriteScore + unlockScore + likeScore;
    final maxPossibleScore = viewCount * 28.0;
    
    return maxPossibleScore > 0 ? (totalScore / maxPossibleScore) * 100 : 0.0;
  }

  String get formattedEngagementScore {
    return '${engagementScore.toStringAsFixed(1)}%';
  }

  // ===============================
  // DISPLAY FORMATTING
  // ===============================

  String get formattedViews => _formatCount(viewCount);
  String get formattedUnlocks => _formatCount(unlockCount);
  String get formattedFavorites => _formatCount(favoriteCount);
  String get formattedLikes => _formatCount(likes);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Timestamps
  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get updatedAtDateTime {
    try {
      return DateTime.parse(updatedAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final created = createdAtDateTime;
    final difference = now.difference(created);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // ===============================
  // PREMIUM INFO
  // ===============================

  String get premiumInfo {
    if (freeEpisodesCount == 0) {
      return 'Premium Series - Unlock required for all episodes';
    }
    if (freeEpisodesCount >= totalEpisodes) {
      return 'Free Series - All episodes included';
    }
    return 'First $freeEpisodesCount episodes free, unlock for remaining $lockedEpisodesCount';
  }

  // AFFILIATE PROGRAM INFO
  String get affiliateInfo {
    if (!allowReposts) {
      return 'Reposting disabled - Exclusive content';
    }
    if (!hasAffiliateProgram) {
      return 'Reposts allowed - No commission';
    }
    return 'Earn ${formattedAffiliateCommission} commission per unlock!';
  }

  String get repostPolicy {
    if (!allowReposts) return 'No reposts allowed';
    if (hasAffiliateProgram) return 'Repost & earn ${formattedAffiliateCommission}';
    return 'Reposts allowed';
  }

  // ===============================
  // INTERACTION METHODS
  // ===============================

  SeriesModel toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likes: isLiked ? likes - 1 : likes + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  SeriesModel toggleFavorite() {
    return copyWith(
      isFavorited: !isFavorited,
      favoriteCount: isFavorited ? favoriteCount - 1 : favoriteCount + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  SeriesModel incrementViews() {
    return copyWith(
      viewCount: viewCount + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  SeriesModel incrementUnlocks() {
    return copyWith(
      unlockCount: unlockCount + 1,
      hasUnlocked: true,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  SeriesModel updateProgress(int episode) {
    return copyWith(
      currentEpisode: episode,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // VALIDATION
  // ===============================

  bool get isValid {
    return id.isNotEmpty &&
           title.isNotEmpty &&
           description.isNotEmpty &&
           creatorId.isNotEmpty &&
           isVerified && // Must be verified
           totalEpisodes > 0 &&
           totalEpisodes <= 100 &&
           unlockPrice >= 10 && unlockPrice <= 1000 &&
           freeEpisodesCount >= 1 && freeEpisodesCount <= 20 &&
           freeEpisodesCount < totalEpisodes && // Can't have all episodes free
           affiliateCommission >= 0 && affiliateCommission <= 0.15; // 0-15% max
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (title.isEmpty) errors.add('Title is required');
    if (description.isEmpty) errors.add('Description is required');
    if (creatorId.isEmpty) errors.add('Creator ID is required');
    if (!isVerified) errors.add('Creator must be verified to create series');
    
    if (totalEpisodes == 0) errors.add('At least one episode is required');
    if (totalEpisodes > 100) errors.add('Maximum 100 episodes allowed');
    
    if (unlockPrice < 10) errors.add('Minimum unlock price is 10 KES');
    if (unlockPrice > 1000) errors.add('Maximum unlock price is 1,000 KES');
    
    if (freeEpisodesCount < 1) errors.add('At least 1 free episode required');
    if (freeEpisodesCount > 20) errors.add('Maximum 20 free episodes allowed');
    if (freeEpisodesCount >= totalEpisodes) errors.add('Free episodes must be less than total episodes');
    
    // AFFILIATE VALIDATION
    if (affiliateCommission < 0) errors.add('Affiliate commission cannot be negative');
    if (affiliateCommission > 0.15) errors.add('Maximum affiliate commission is 15%');
    if (hasAffiliateProgram && affiliateCommission == 0) {
      errors.add('Affiliate program enabled but commission is 0%');
    }
    if (!allowReposts && hasAffiliateProgram) {
      errors.add('Cannot have affiliate program if reposts are disabled');
    }
    
    if (episodeDurations.isNotEmpty) {
      for (int i = 0; i < episodeDurations.length; i++) {
        if (episodeDurations[i] > 120) {
          errors.add('Episode ${i + 1} exceeds 2 minutes maximum');
        }
      }
    }
    
    return errors;
  }

  // ===============================
  // SEARCH & FILTERING
  // ===============================

  bool containsQuery(String query) {
    if (query.isEmpty) return true;
    
    final searchQuery = query.toLowerCase();
    
    return title.toLowerCase().contains(searchQuery) ||
           description.toLowerCase().contains(searchQuery) ||
           creatorName.toLowerCase().contains(searchQuery) ||
           tags.any((tag) => tag.toLowerCase().contains(searchQuery));
  }

  bool hasTag(String tag) {
    return tags.any((t) => t.toLowerCase() == tag.toLowerCase());
  }

  // ===============================
  // STATISTICS FOR ADMIN/CREATOR
  // ===============================

  Map<String, dynamic> get performanceStats {
    return {
      'totalViews': viewCount,
      'totalFavorites': favoriteCount,
      'totalUnlocks': unlockCount,
      'totalLikes': likes,
      'totalRevenue': totalRevenue,
      'creatorEarnings': creatorEarnings,
      'platformRevenue': platformRevenue,
      'totalAffiliateEarnings': totalAffiliateEarnings,
      'conversionRate': conversionRate,
      'revenuePerView': revenuePerView,
      'performanceLevel': performanceLevel,
      'engagementScore': engagementScore,
      'isProfitable': isProfitable,
      'isPopular': isPopular,
      'isHighConverting': isHighConverting,
      'hasAffiliateProgram': hasAffiliateProgram,
      'affiliateCommission': formattedAffiliateCommission,
    };
  }

  Map<String, dynamic> get engagementMetrics {
    return {
      'viewToFavoriteRate': viewCount > 0 ? (favoriteCount / viewCount) * 100 : 0.0,
      'favoriteToUnlockRate': favoriteCount > 0 ? (unlockCount / favoriteCount) * 100 : 0.0,
      'viewToUnlockRate': conversionRate,
      'totalEngagementScore': engagementScore,
    };
  }

  Map<String, dynamic> get episodeStats {
    return {
      'totalEpisodes': totalEpisodes,
      'freeEpisodes': freeEpisodesCount,
      'lockedEpisodes': lockedEpisodesCount,
      'totalDurationMinutes': totalDurationMinutes,
      'averageEpisodeDuration': episodeDurations.isNotEmpty 
          ? episodeDurations.reduce((a, b) => a + b) / episodeDurations.length 
          : 0,
    };
  }

  // ===============================
  // DEBUG & DISPLAY
  // ===============================

  @override
  String toString() {
    return 'SeriesModel(id: $id, title: "$title", episodes: $totalEpisodes, price: ${formattedPrice}, unlocks: $unlockCount, revenue: ${formattedTotalRevenue})';
  }

  String toDebugString() {
    return '''
SeriesModel {
  id: $id
  title: $title
  description: $description
  creator: $creatorName (verified: $isVerified)
  
  Episodes:
    total: $totalEpisodes
    free: $freeEpisodesCount
    locked: $lockedEpisodesCount
    duration: $formattedTotalDuration
  
  Pricing:
    unlockPrice: ${formattedPrice}
  
  Affiliate Program:
    allowReposts: $allowReposts
    hasAffiliateProgram: $hasAffiliateProgram
    affiliateCommission: ${formattedAffiliateCommission}
    affiliateAmount: ${formattedAffiliateAmount}
  
  Metrics:
    views: $formattedViews
    unlocks: $formattedUnlocks
    favorites: $formattedFavorites
    likes: $formattedLikes
  
  Revenue:
    total: ${formattedTotalRevenue}
    creator: ${formattedCreatorEarnings} (${hasAffiliateProgram ? (1.0 - 0.3 - affiliateCommission)*100 : 70}%)
    affiliate: KES ${totalAffiliateEarnings.toInt()} (${formattedAffiliateCommission})
    platform: KES ${platformRevenue.toInt()} (30%)
  
  Performance:
    conversionRate: ${formattedConversionRate}
    engagementScore: ${formattedEngagementScore}
    performanceLevel: $performanceLevel
  
  Status:
    isActive: $isActive
    isFeatured: $isFeatured
    createdAt: $timeAgo
}''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// EXTENSIONS FOR LISTS
// ===============================

extension SeriesModelList on List<SeriesModel> {
  // Filter by status
  List<SeriesModel> get activeSeries => where((s) => s.isActive).toList();
  List<SeriesModel> get featuredSeries => where((s) => s.isFeatured).toList();
  List<SeriesModel> get verifiedSeries => where((s) => s.isVerified).toList();
  List<SeriesModel> get profitableSeries => where((s) => s.isProfitable).toList();
  List<SeriesModel> get popularSeries => where((s) => s.isPopular).toList();
  List<SeriesModel> get affiliateSeries => where((s) => s.hasAffiliateProgram).toList();
  List<SeriesModel> get repostableSeries => where((s) => s.allowReposts).toList();
  
  // Sorting
  List<SeriesModel> sortByViews({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending ? b.viewCount.compareTo(a.viewCount) : a.viewCount.compareTo(b.viewCount));
    return sorted;
  }
  
  List<SeriesModel> sortByUnlocks({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending ? b.unlockCount.compareTo(a.unlockCount) : a.unlockCount.compareTo(b.unlockCount));
    return sorted;
  }
  
  List<SeriesModel> sortByRevenue({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending ? b.totalRevenue.compareTo(a.totalRevenue) : a.totalRevenue.compareTo(b.totalRevenue));
    return sorted;
  }
  
  List<SeriesModel> sortByConversionRate({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.conversionRate.compareTo(a.conversionRate) 
        : a.conversionRate.compareTo(b.conversionRate));
    return sorted;
  }
  
  List<SeriesModel> sortByDate({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.createdAtDateTime.compareTo(a.createdAtDateTime)
        : a.createdAtDateTime.compareTo(b.createdAtDateTime));
    return sorted;
  }

  List<SeriesModel> sortByPrice({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.unlockPrice.compareTo(a.unlockPrice) 
        : a.unlockPrice.compareTo(b.unlockPrice));
    return sorted;
  }

  List<SeriesModel> sortByAffiliateCommission({bool descending = true}) {
    final sorted = List<SeriesModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.affiliateCommission.compareTo(a.affiliateCommission) 
        : a.affiliateCommission.compareTo(b.affiliateCommission));
    return sorted;
  }
  
  // Filtering
  List<SeriesModel> filterByCreator(String creatorId) {
    return where((s) => s.creatorId == creatorId).toList();
  }
  
  List<SeriesModel> filterByTag(String tag) {
    return where((s) => s.hasTag(tag)).toList();
  }
  
  List<SeriesModel> filterByPriceRange(double minPrice, double maxPrice) {
    return where((s) => s.unlockPrice >= minPrice && s.unlockPrice <= maxPrice).toList();
  }

  List<SeriesModel> filterByEpisodeCount(int minEpisodes, int maxEpisodes) {
    return where((s) => s.totalEpisodes >= minEpisodes && s.totalEpisodes <= maxEpisodes).toList();
  }

  List<SeriesModel> filterByAffiliateCommission(double minCommission, double maxCommission) {
    return where((s) => s.affiliateCommission >= minCommission && s.affiliateCommission <= maxCommission).toList();
  }
  
  List<SeriesModel> search(String query) {
    return where((s) => s.containsQuery(query)).toList();
  }
  
  // Aggregate metrics
  int get totalViews => fold<int>(0, (sum, s) => sum + s.viewCount);
  int get totalUnlocks => fold<int>(0, (sum, s) => sum + s.unlockCount);
  int get totalFavorites => fold<int>(0, (sum, s) => sum + s.favoriteCount);
  int get totalLikes => fold<int>(0, (sum, s) => sum + s.likes);
  double get totalRevenue => fold<double>(0.0, (sum, s) => sum + s.totalRevenue);
  double get totalCreatorEarnings => fold<double>(0.0, (sum, s) => sum + s.creatorEarnings);
  double get totalPlatformRevenue => fold<double>(0.0, (sum, s) => sum + s.platformRevenue);
  double get totalAffiliateEarnings => fold<double>(0.0, (sum, s) => sum + s.totalAffiliateEarnings);
  
  double get averageConversionRate {
    if (isEmpty) return 0.0;
    final totalConversion = fold<double>(0.0, (sum, s) => sum + s.conversionRate);
    return totalConversion / length;
  }

  double get averagePrice {
    if (isEmpty) return 0.0;
    final totalPrice = fold<double>(0.0, (sum, s) => sum + s.unlockPrice);
    return totalPrice / length;
  }

  double get averageEpisodes {
    if (isEmpty) return 0.0;
    final totalEpisodes = fold<int>(0, (sum, s) => sum + s.totalEpisodes);
    return totalEpisodes / length;
  }

  double get averageAffiliateCommission {
    final affiliateOnly = affiliateSeries;
    if (affiliateOnly.isEmpty) return 0.0;
    final totalCommission = affiliateOnly.fold<double>(0.0, (sum, s) => sum + s.affiliateCommission);
    return totalCommission / affiliateOnly.length;
  }

  // Top performers
  List<SeriesModel> get topEarners => sortByRevenue().take(10).toList();
  List<SeriesModel> get topConverters => sortByConversionRate().take(10).toList();
  List<SeriesModel> get mostViewed => sortByViews().take(10).toList();
  List<SeriesModel> get mostUnlocked => sortByUnlocks().take(10).toList();
  List<SeriesModel> get topAffiliateEarners => sortByAffiliateCommission().take(10).toList();

  // Performance breakdown
  Map<String, int> get performanceLevelBreakdown {
    final breakdown = <String, int>{};
    for (final series in this) {
      final level = series.performanceLevel;
      breakdown[level] = (breakdown[level] ?? 0) + 1;
    }
    return breakdown;
  }

  // Revenue statistics
  Map<String, dynamic> get revenueStats {
    return {
      'totalRevenue': totalRevenue,
      'totalCreatorEarnings': totalCreatorEarnings,
      'totalPlatformRevenue': totalPlatformRevenue,
      'totalAffiliateEarnings': totalAffiliateEarnings,
      'averageRevenuePerSeries': isEmpty ? 0.0 : totalRevenue / length,
      'totalProfitableSeries': profitableSeries.length,
      'profitablePercentage': isEmpty ? 0.0 : (profitableSeries.length / length) * 100,
      'affiliateSeriesCount': affiliateSeries.length,
      'affiliateSeriesPercentage': isEmpty ? 0.0 : (affiliateSeries.length / length) * 100,
    };
  }

  // Engagement statistics
  Map<String, dynamic> get engagementStats {
    return {
      'totalViews': totalViews,
      'totalUnlocks': totalUnlocks,
      'totalFavorites': totalFavorites,
      'totalLikes': totalLikes,
      'averageViewsPerSeries': isEmpty ? 0.0 : totalViews / length,
      'averageUnlocksPerSeries': isEmpty ? 0.0 : totalUnlocks / length,
      'averageConversionRate': averageConversionRate,
      'totalPopularSeries': popularSeries.length,
      'popularPercentage': isEmpty ? 0.0 : (popularSeries.length / length) * 100,
    };
  }
}