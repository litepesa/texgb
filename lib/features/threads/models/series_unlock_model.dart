// ===============================
// lib/features/series/models/series_unlock_model.dart
// Series Unlock Model - Track User Purchases & Progress (FINAL VERSION)
// 
// FEATURES:
// 1. Track which users unlocked which series
// 2. Track watching progress per user
// 3. Revenue attribution (CRITICAL for reposts)
// 4. Affiliate commission tracking (creator-controlled)
// 5. Purchase history and timestamps
// 6. Episode completion tracking
// ===============================

import 'dart:convert';

class SeriesUnlockModel {
  // Core identification
  final String id;                       // Unique unlock record ID
  final String userId;                   // User who unlocked
  final String seriesId;                 // Series that was unlocked
  
  // CRITICAL: Revenue attribution (for reposts)
  final String originalCreatorId;        // Series creator (gets creator %)
  final String? sharedByUserId;          // User who shared (gets affiliate % if enabled)
  
  // 🆕 AFFILIATE TRACKING (Creator-Controlled)
  final bool hasAffiliateEarnings;       // Did promoter earn commission?
  final double affiliateCommission;      // % earned by promoter (0-0.15)
  final double affiliateEarnings;        // Amount earned by promoter (in KES)
  
  // Purchase details
  final double unlockPrice;              // Price paid at time of unlock
  final String paymentMethod;            // M-Pesa, Card, etc.
  final String? transactionId;           // Payment transaction reference
  final String purchasedAt;              // When user unlocked (RFC3339)
  
  // Progress tracking
  final int currentEpisode;              // Last watched episode (1-based)
  final List<int> completedEpisodes;     // Episodes user has completed
  final int totalEpisodesWatched;        // Count of completed episodes
  final double watchProgress;            // Percentage complete (0-100)
  final String lastWatchedAt;            // Last activity timestamp
  
  // Series snapshot (at time of unlock)
  final String seriesTitle;              // Series name
  final String creatorName;              // Creator name
  final int totalEpisodes;               // Total episodes in series
  
  // Status
  final bool isActive;                   // Is unlock still valid?
  final String? deactivatedAt;           // If revoked/refunded
  final String? deactivationReason;      // Reason for deactivation
  
  // Timestamps
  final String createdAt;
  final String updatedAt;

  const SeriesUnlockModel({
    required this.id,
    required this.userId,
    required this.seriesId,
    required this.originalCreatorId,
    this.sharedByUserId,
    this.hasAffiliateEarnings = false,     // 🆕 Default: no affiliate
    this.affiliateCommission = 0.0,        // 🆕 Default: 0%
    this.affiliateEarnings = 0.0,          // 🆕 Default: 0 KES
    required this.unlockPrice,
    this.paymentMethod = 'M-Pesa',
    this.transactionId,
    required this.purchasedAt,
    this.currentEpisode = 1,
    this.completedEpisodes = const [],
    this.totalEpisodesWatched = 0,
    this.watchProgress = 0.0,
    required this.lastWatchedAt,
    required this.seriesTitle,
    required this.creatorName,
    required this.totalEpisodes,
    this.isActive = true,
    this.deactivatedAt,
    this.deactivationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===============================
  // FACTORY CONSTRUCTORS
  // ===============================

  factory SeriesUnlockModel.fromJson(Map<String, dynamic> json) {
    try {
      return SeriesUnlockModel(
        id: _parseString(json['id']),
        userId: _parseString(json['userId'] ?? json['user_id']),
        seriesId: _parseString(json['seriesId'] ?? json['series_id']),
        originalCreatorId: _parseString(json['originalCreatorId'] ?? json['original_creator_id']),
        sharedByUserId: _parseStringOrNull(json['sharedByUserId'] ?? json['shared_by_user_id']),
        hasAffiliateEarnings: _parseBool(json['hasAffiliateEarnings'] ?? json['has_affiliate_earnings'] ?? false),
        affiliateCommission: _parseDouble(json['affiliateCommission'] ?? json['affiliate_commission'] ?? 0.0),
        affiliateEarnings: _parsePrice(json['affiliateEarnings'] ?? json['affiliate_earnings'] ?? 0.0),
        unlockPrice: _parsePrice(json['unlockPrice'] ?? json['unlock_price']),
        paymentMethod: _parseString(json['paymentMethod'] ?? json['payment_method'] ?? 'M-Pesa'),
        transactionId: _parseStringOrNull(json['transactionId'] ?? json['transaction_id']),
        purchasedAt: _parseTimestamp(json['purchasedAt'] ?? json['purchased_at']),
        currentEpisode: _parseInt(json['currentEpisode'] ?? json['current_episode'] ?? 1),
        completedEpisodes: _parseIntList(json['completedEpisodes'] ?? json['completed_episodes']),
        totalEpisodesWatched: _parseInt(json['totalEpisodesWatched'] ?? json['total_episodes_watched'] ?? 0),
        watchProgress: _parseDouble(json['watchProgress'] ?? json['watch_progress'] ?? 0.0),
        lastWatchedAt: _parseTimestamp(json['lastWatchedAt'] ?? json['last_watched_at']),
        seriesTitle: _parseString(json['seriesTitle'] ?? json['series_title']),
        creatorName: _parseString(json['creatorName'] ?? json['creator_name']),
        totalEpisodes: _parseInt(json['totalEpisodes'] ?? json['total_episodes']),
        isActive: _parseBool(json['isActive'] ?? json['is_active'] ?? true),
        deactivatedAt: _parseStringOrNull(json['deactivatedAt'] ?? json['deactivated_at']),
        deactivationReason: _parseStringOrNull(json['deactivationReason'] ?? json['deactivation_reason']),
        createdAt: _parseTimestamp(json['createdAt'] ?? json['created_at']),
        updatedAt: _parseTimestamp(json['updatedAt'] ?? json['updated_at']),
      );
    } catch (e) {
      print('❌ Error parsing SeriesUnlockModel from JSON: $e');
      print('📄 JSON data: $json');
      
      // Return safe default
      final now = DateTime.now().toIso8601String();
      return SeriesUnlockModel(
        id: _parseString(json['id'] ?? ''),
        userId: _parseString(json['userId'] ?? ''),
        seriesId: _parseString(json['seriesId'] ?? ''),
        originalCreatorId: _parseString(json['originalCreatorId'] ?? ''),
        unlockPrice: 0.0,
        purchasedAt: now,
        lastWatchedAt: now,
        seriesTitle: 'Unknown Series',
        creatorName: 'Unknown Creator',
        totalEpisodes: 0,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  // Factory for creating new unlock
  factory SeriesUnlockModel.create({
    required String userId,
    required String seriesId,
    required String originalCreatorId,
    String? sharedByUserId,
    bool hasAffiliateEarnings = false,     // 🆕
    double affiliateCommission = 0.0,      // 🆕
    double affiliateEarnings = 0.0,        // 🆕
    required double unlockPrice,
    String paymentMethod = 'M-Pesa',
    String? transactionId,
    required String seriesTitle,
    required String creatorName,
    required int totalEpisodes,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    
    return SeriesUnlockModel(
      id: '', // Will be set by backend
      userId: userId,
      seriesId: seriesId,
      originalCreatorId: originalCreatorId,
      sharedByUserId: sharedByUserId,
      hasAffiliateEarnings: hasAffiliateEarnings,
      affiliateCommission: affiliateCommission,
      affiliateEarnings: affiliateEarnings,
      unlockPrice: unlockPrice,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      purchasedAt: now,
      lastWatchedAt: now,
      seriesTitle: seriesTitle,
      creatorName: creatorName,
      totalEpisodes: totalEpisodes,
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

  static String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
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
            .map((item) => int.tryParse(item.trim().replaceAll('"', '')) ?? 0)
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
      'userId': userId,
      'seriesId': seriesId,
      'originalCreatorId': originalCreatorId,
      'sharedByUserId': sharedByUserId,
      'hasAffiliateEarnings': hasAffiliateEarnings,
      'affiliateCommission': affiliateCommission,
      'affiliateEarnings': affiliateEarnings,
      'unlockPrice': unlockPrice,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'purchasedAt': purchasedAt,
      'currentEpisode': currentEpisode,
      'completedEpisodes': completedEpisodes,
      'totalEpisodesWatched': totalEpisodesWatched,
      'watchProgress': watchProgress,
      'lastWatchedAt': lastWatchedAt,
      'seriesTitle': seriesTitle,
      'creatorName': creatorName,
      'totalEpisodes': totalEpisodes,
      'isActive': isActive,
      'deactivatedAt': deactivatedAt,
      'deactivationReason': deactivationReason,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SeriesUnlockModel copyWith({
    String? id,
    String? userId,
    String? seriesId,
    String? originalCreatorId,
    String? sharedByUserId,
    bool? hasAffiliateEarnings,
    double? affiliateCommission,
    double? affiliateEarnings,
    double? unlockPrice,
    String? paymentMethod,
    String? transactionId,
    String? purchasedAt,
    int? currentEpisode,
    List<int>? completedEpisodes,
    int? totalEpisodesWatched,
    double? watchProgress,
    String? lastWatchedAt,
    String? seriesTitle,
    String? creatorName,
    int? totalEpisodes,
    bool? isActive,
    String? deactivatedAt,
    String? deactivationReason,
    String? createdAt,
    String? updatedAt,
  }) {
    return SeriesUnlockModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      seriesId: seriesId ?? this.seriesId,
      originalCreatorId: originalCreatorId ?? this.originalCreatorId,
      sharedByUserId: sharedByUserId ?? this.sharedByUserId,
      hasAffiliateEarnings: hasAffiliateEarnings ?? this.hasAffiliateEarnings,
      affiliateCommission: affiliateCommission ?? this.affiliateCommission,
      affiliateEarnings: affiliateEarnings ?? this.affiliateEarnings,
      unlockPrice: unlockPrice ?? this.unlockPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      completedEpisodes: completedEpisodes ?? this.completedEpisodes,
      totalEpisodesWatched: totalEpisodesWatched ?? this.totalEpisodesWatched,
      watchProgress: watchProgress ?? this.watchProgress,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      creatorName: creatorName ?? this.creatorName,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      deactivationReason: deactivationReason ?? this.deactivationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===============================
  // PROGRESS TRACKING
  // ===============================

  // Check if episode is completed
  bool isEpisodeCompleted(int episodeNumber) {
    return completedEpisodes.contains(episodeNumber);
  }

  // Mark episode as completed
  SeriesUnlockModel completeEpisode(int episodeNumber) {
    if (isEpisodeCompleted(episodeNumber)) return this;
    
    final newCompleted = List<int>.from(completedEpisodes)..add(episodeNumber);
    newCompleted.sort();
    
    final newWatchedCount = newCompleted.length;
    final newProgress = totalEpisodes > 0 ? (newWatchedCount / totalEpisodes) * 100 : 0.0;
    
    return copyWith(
      completedEpisodes: newCompleted,
      totalEpisodesWatched: newWatchedCount,
      watchProgress: newProgress,
      currentEpisode: episodeNumber < totalEpisodes ? episodeNumber + 1 : episodeNumber,
      lastWatchedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Update current episode (without marking as completed)
  SeriesUnlockModel updateCurrentEpisode(int episodeNumber) {
    return copyWith(
      currentEpisode: episodeNumber,
      lastWatchedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Reset progress
  SeriesUnlockModel resetProgress() {
    return copyWith(
      currentEpisode: 1,
      completedEpisodes: [],
      totalEpisodesWatched: 0,
      watchProgress: 0.0,
      lastWatchedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // STATUS HELPERS
  // ===============================

  bool get isUnlockedViaRepost => sharedByUserId != null && sharedByUserId!.isNotEmpty;
  
  bool get isCompleted => watchProgress >= 100.0;
  
  bool get isInProgress => watchProgress > 0.0 && watchProgress < 100.0;
  
  bool get notStarted => watchProgress == 0.0;

  int get remainingEpisodes => totalEpisodes - totalEpisodesWatched;

  // ===============================
  // REVENUE ATTRIBUTION (CRITICAL)
  // ===============================

  // 🆕 UPDATED: Creator earnings (adjusted for affiliate)
  double get creatorEarnings {
    if (hasAffiliateEarnings) {
      // Creator gets: (100% - 30% platform - affiliate commission)
      final creatorPercentage = 1.0 - 0.3 - affiliateCommission;
      return unlockPrice * creatorPercentage;
    }
    // No affiliate: Creator gets 70%
    return unlockPrice * 0.7;
  }

  // Platform earnings (always 30%)
  double get platformEarnings => unlockPrice * 0.3;

  // 🆕 Affiliate earnings (if applicable)
  // This is what the promoter (sharedByUserId) earns
  double get affiliateEarningsAmount => affiliateEarnings;

  // CRITICAL: Revenue ALWAYS includes original creator
  String get revenueRecipientId => originalCreatorId;

  // 🆕 Affiliate recipient (who gets the commission)
  String? get affiliateRecipientId => hasAffiliateEarnings ? sharedByUserId : null;

  // 🆕 UPDATED: Revenue source tracking
  String get revenueSource {
    if (hasAffiliateEarnings && sharedByUserId != null) {
      return 'Affiliate unlock by user $sharedByUserId (${(affiliateCommission * 100).toStringAsFixed(0)}% commission)';
    }
    if (sharedByUserId != null) {
      return 'Unlocked via repost by user $sharedByUserId (no commission)';
    }
    return 'Direct unlock';
  }

  // 🆕 Revenue breakdown
  Map<String, double> get revenueBreakdown {
    return {
      'total': unlockPrice,
      'creator': creatorEarnings,
      'affiliate': affiliateEarningsAmount,
      'platform': platformEarnings,
    };
  }

  String get formattedRevenueBreakdown {
    if (hasAffiliateEarnings) {
      return '''
Total: KES ${unlockPrice.toInt()}
├─ Creator: KES ${creatorEarnings.toInt()} (${((creatorEarnings/unlockPrice)*100).toStringAsFixed(0)}%)
├─ Affiliate: KES ${affiliateEarningsAmount.toInt()} (${(affiliateCommission*100).toStringAsFixed(0)}%)
└─ Platform: KES ${platformEarnings.toInt()} (30%)''';
    }
    return '''
Total: KES ${unlockPrice.toInt()}
├─ Creator: KES ${creatorEarnings.toInt()} (70%)
└─ Platform: KES ${platformEarnings.toInt()} (30%)''';
  }

  // ===============================
  // DISPLAY FORMATTING
  // ===============================

  String get formattedPrice {
    if (unlockPrice == 0) return 'Free';
    
    if (unlockPrice < 1000) {
      return 'KES ${unlockPrice.toInt()}';
    } else {
      return 'KES ${(unlockPrice / 1000).toStringAsFixed(1)}K';
    }
  }

  String get formattedProgress {
    return '${watchProgress.toStringAsFixed(1)}%';
  }

  String get progressStatus {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In Progress';
    return 'Not Started';
  }

  String get episodesProgress {
    return '$totalEpisodesWatched/$totalEpisodes episodes';
  }

  String get formattedAffiliateEarnings {
    if (!hasAffiliateEarnings) return 'KES 0';
    return 'KES ${affiliateEarningsAmount.toInt()}';
  }

  // Timestamps
  DateTime get purchasedAtDateTime {
    try {
      return DateTime.parse(purchasedAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime get lastWatchedAtDateTime {
    try {
      return DateTime.parse(lastWatchedAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get deactivatedAtDateTime {
    if (deactivatedAt == null) return null;
    try {
      return DateTime.parse(deactivatedAt!);
    } catch (e) {
      return null;
    }
  }

  String get timeSincePurchase {
    final now = DateTime.now();
    final purchased = purchasedAtDateTime;
    final difference = now.difference(purchased);

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

  String get timeSinceLastWatched {
    final now = DateTime.now();
    final lastWatched = lastWatchedAtDateTime;
    final difference = now.difference(lastWatched);

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
  // VALIDATION
  // ===============================

  bool get isValid {
    return id.isNotEmpty &&
           userId.isNotEmpty &&
           seriesId.isNotEmpty &&
           originalCreatorId.isNotEmpty &&
           unlockPrice >= 0 &&
           totalEpisodes > 0 &&
           currentEpisode >= 1 &&
           currentEpisode <= totalEpisodes &&
           watchProgress >= 0 && watchProgress <= 100 &&
           affiliateCommission >= 0 && affiliateCommission <= 0.15;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('ID is required');
    if (userId.isEmpty) errors.add('User ID is required');
    if (seriesId.isEmpty) errors.add('Series ID is required');
    if (originalCreatorId.isEmpty) errors.add('Original creator ID is required');
    if (unlockPrice < 0) errors.add('Unlock price cannot be negative');
    if (totalEpisodes <= 0) errors.add('Total episodes must be greater than 0');
    if (currentEpisode < 1) errors.add('Current episode must be at least 1');
    if (currentEpisode > totalEpisodes) errors.add('Current episode cannot exceed total episodes');
    if (watchProgress < 0 || watchProgress > 100) errors.add('Watch progress must be between 0 and 100');
    if (affiliateCommission < 0 || affiliateCommission > 0.15) errors.add('Affiliate commission must be between 0% and 15%');
    
    if (hasAffiliateEarnings && sharedByUserId == null) {
      errors.add('Affiliate earnings cannot exist without sharedByUserId');
    }
    
    return errors;
  }

  // ===============================
  // DEACTIVATION
  // ===============================

  SeriesUnlockModel deactivate(String reason) {
    return copyWith(
      isActive: false,
      deactivatedAt: DateTime.now().toIso8601String(),
      deactivationReason: reason,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  SeriesUnlockModel reactivate() {
    return copyWith(
      isActive: true,
      deactivatedAt: null,
      deactivationReason: null,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // ===============================
  // DEBUG & DISPLAY
  // ===============================

  @override
  String toString() {
    return 'SeriesUnlockModel(id: $id, user: $userId, series: $seriesTitle, progress: $formattedProgress, unlocked: $timeSincePurchase)';
  }

  String toDebugString() {
    return '''
SeriesUnlockModel {
  id: $id
  userId: $userId
  seriesId: $seriesId
  
  Series Info:
    title: $seriesTitle
    creator: $creatorName
    totalEpisodes: $totalEpisodes
  
  Purchase Info:
    price: $formattedPrice
    method: $paymentMethod
    transactionId: ${transactionId ?? 'N/A'}
    purchasedAt: $timeSincePurchase
  
  Revenue Attribution:
    originalCreatorId: $originalCreatorId
    sharedByUserId: ${sharedByUserId ?? 'Direct unlock'}
    hasAffiliateEarnings: $hasAffiliateEarnings
    affiliateRecipientId: ${affiliateRecipientId ?? 'N/A'}
    
    Revenue Breakdown:
$formattedRevenueBreakdown
  
  Progress:
    currentEpisode: $currentEpisode
    completedEpisodes: $totalEpisodesWatched/$totalEpisodes
    watchProgress: $formattedProgress
    status: $progressStatus
    lastWatched: $timeSinceLastWatched
  
  Status:
    isActive: $isActive
    deactivatedAt: ${deactivatedAt ?? 'N/A'}
    deactivationReason: ${deactivationReason ?? 'N/A'}
}''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesUnlockModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ===============================
// EXTENSIONS FOR LISTS
// ===============================

extension SeriesUnlockModelList on List<SeriesUnlockModel> {
  // Filter by status
  List<SeriesUnlockModel> get activeUnlocks => where((u) => u.isActive).toList();
  List<SeriesUnlockModel> get deactivatedUnlocks => where((u) => !u.isActive).toList();
  List<SeriesUnlockModel> get completedUnlocks => where((u) => u.isCompleted).toList();
  List<SeriesUnlockModel> get inProgressUnlocks => where((u) => u.isInProgress).toList();
  List<SeriesUnlockModel> get notStartedUnlocks => where((u) => u.notStarted).toList();
  List<SeriesUnlockModel> get repostUnlocks => where((u) => u.isUnlockedViaRepost).toList();
  List<SeriesUnlockModel> get directUnlocks => where((u) => !u.isUnlockedViaRepost).toList();
  List<SeriesUnlockModel> get affiliateUnlocks => where((u) => u.hasAffiliateEarnings).toList();
  
  // Sorting
  List<SeriesUnlockModel> sortByPurchaseDate({bool descending = true}) {
    final sorted = List<SeriesUnlockModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.purchasedAtDateTime.compareTo(a.purchasedAtDateTime)
        : a.purchasedAtDateTime.compareTo(b.purchasedAtDateTime));
    return sorted;
  }

  List<SeriesUnlockModel> sortByLastWatched({bool descending = true}) {
    final sorted = List<SeriesUnlockModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.lastWatchedAtDateTime.compareTo(a.lastWatchedAtDateTime)
        : a.lastWatchedAtDateTime.compareTo(a.lastWatchedAtDateTime));
    return sorted;
  }

  List<SeriesUnlockModel> sortByProgress({bool descending = true}) {
    final sorted = List<SeriesUnlockModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.watchProgress.compareTo(a.watchProgress)
        : a.watchProgress.compareTo(b.watchProgress));
    return sorted;
  }

  List<SeriesUnlockModel> sortByPrice({bool descending = true}) {
    final sorted = List<SeriesUnlockModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.unlockPrice.compareTo(a.unlockPrice)
        : a.unlockPrice.compareTo(b.unlockPrice));
    return sorted;
  }

  List<SeriesUnlockModel> sortByAffiliateEarnings({bool descending = true}) {
    final sorted = List<SeriesUnlockModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.affiliateEarningsAmount.compareTo(a.affiliateEarningsAmount)
        : a.affiliateEarningsAmount.compareTo(b.affiliateEarningsAmount));
    return sorted;
  }

  // Filtering
  List<SeriesUnlockModel> filterByUser(String userId) {
    return where((u) => u.userId == userId).toList();
  }

  List<SeriesUnlockModel> filterBySeries(String seriesId) {
    return where((u) => u.seriesId == seriesId).toList();
  }

  List<SeriesUnlockModel> filterByCreator(String creatorId) {
    return where((u) => u.originalCreatorId == creatorId).toList();
  }

  List<SeriesUnlockModel> filterByPromoter(String promoterId) {
    return where((u) => u.sharedByUserId == promoterId).toList();
  }

  List<SeriesUnlockModel> filterByPriceRange(double minPrice, double maxPrice) {
    return where((u) => u.unlockPrice >= minPrice && u.unlockPrice <= maxPrice).toList();
  }

  List<SeriesUnlockModel> filterByPaymentMethod(String method) {
    return where((u) => u.paymentMethod == method).toList();
  }

  // Aggregate metrics
  double get totalRevenue => fold<double>(0.0, (sum, u) => sum + u.unlockPrice);
  double get totalCreatorEarnings => fold<double>(0.0, (sum, u) => sum + u.creatorEarnings);
  double get totalPlatformEarnings => fold<double>(0.0, (sum, u) => sum + u.platformEarnings);
  double get totalAffiliateEarnings => fold<double>(0.0, (sum, u) => sum + u.affiliateEarningsAmount);
  
  double get averagePrice {
    if (isEmpty) return 0.0;
    return totalRevenue / length;
  }

  double get averageProgress {
    if (isEmpty) return 0.0;
    final totalProgress = fold<double>(0.0, (sum, u) => sum + u.watchProgress);
    return totalProgress / length;
  }

  int get totalEpisodesWatched => fold<int>(0, (sum, u) => sum + u.totalEpisodesWatched);

  // Completion statistics
  double get completionRate {
    if (isEmpty) return 0.0;
    return (completedUnlocks.length / length) * 100;
  }

  double get inProgressRate {
    if (isEmpty) return 0.0;
    return (inProgressUnlocks.length / length) * 100;
  }

  double get notStartedRate {
    if (isEmpty) return 0.0;
    return (notStartedUnlocks.length / length) * 100;
  }

  // Revenue attribution statistics
  double get affiliateRevenuePercentage {
    if (isEmpty || totalRevenue == 0) return 0.0;
    return (totalAffiliateEarnings / totalRevenue) * 100;
  }

  double get repostRevenuePercentage {
    if (isEmpty || totalRevenue == 0) return 0.0;
    final repostRevenue = repostUnlocks.fold<double>(0.0, (sum, u) => sum + u.unlockPrice);
    return (repostRevenue / totalRevenue) * 100;
  }

  Map<String, int> get paymentMethodBreakdown {
    final breakdown = <String, int>{};
    for (final unlock in this) {
      final method = unlock.paymentMethod;
      breakdown[method] = (breakdown[method] ?? 0) + 1;
    }
    return breakdown;
  }

  // Affiliate-specific statistics
  int get affiliateUnlocksCount => affiliateUnlocks.length;
  
  double get averageAffiliateCommission {
    final affiliates = affiliateUnlocks;
    if (affiliates.isEmpty) return 0.0;
    final totalCommission = affiliates.fold<double>(0.0, (sum, u) => sum + u.affiliateCommission);
    return totalCommission / affiliates.length;
  }

  double get averageAffiliateEarnings {
    final affiliates = affiliateUnlocks;
    if (affiliates.isEmpty) return 0.0;
    final totalEarnings = affiliates.fold<double>(0.0, (sum, u) => sum + u.affiliateEarningsAmount);
    return totalEarnings / affiliates.length;
  }

  // Top promoters
  Map<String, Map<String, dynamic>> get topPromoters {
    final promoterStats = <String, Map<String, dynamic>>{};
    
    for (final unlock in affiliateUnlocks) {
      final promoterId = unlock.sharedByUserId;
      if (promoterId == null) continue;
      
      if (!promoterStats.containsKey(promoterId)) {
        promoterStats[promoterId] = {
          'unlocks': 0,
          'earnings': 0.0,
          'revenue': 0.0,
        };
      }
      
      promoterStats[promoterId]!['unlocks'] = (promoterStats[promoterId]!['unlocks'] as int) + 1;
      promoterStats[promoterId]!['earnings'] = (promoterStats[promoterId]!['earnings'] as double) + unlock.affiliateEarningsAmount;
      promoterStats[promoterId]!['revenue'] = (promoterStats[promoterId]!['revenue'] as double) + unlock.unlockPrice;
    }
    
    return promoterStats;
  }

  // Revenue statistics
  Map<String, dynamic> get revenueStats {
    return {
      'totalRevenue': totalRevenue,
      'totalCreatorEarnings': totalCreatorEarnings,
      'totalPlatformEarnings': totalPlatformEarnings,
      'totalAffiliateEarnings': totalAffiliateEarnings,
      'averagePrice': averagePrice,
      'totalUnlocks': length,
      'directUnlocks': directUnlocks.length,
      'repostUnlocks': repostUnlocks.length,
      'affiliateUnlocks': affiliateUnlocksCount,
      'repostRevenuePercentage': repostRevenuePercentage,
      'affiliateRevenuePercentage': affiliateRevenuePercentage,
      'averageAffiliateCommission': averageAffiliateCommission,
      'averageAffiliateEarnings': averageAffiliateEarnings,
    };
  }

  // Engagement statistics
  Map<String, dynamic> get engagementStats {
    return {
      'totalUnlocks': length,
      'completedUnlocks': completedUnlocks.length,
      'inProgressUnlocks': inProgressUnlocks.length,
      'notStartedUnlocks': notStartedUnlocks.length,
      'completionRate': completionRate,
      'inProgressRate': inProgressRate,
      'notStartedRate': notStartedRate,
      'averageProgress': averageProgress,
      'totalEpisodesWatched': totalEpisodesWatched,
    };
  }

  // Top performing unlocks
  List<SeriesUnlockModel> get recentPurchases => sortByPurchaseDate().take(10).toList();
  List<SeriesUnlockModel> get recentlyWatched => sortByLastWatched().take(10).toList();
  List<SeriesUnlockModel> get mostCompleted => sortByProgress().take(10).toList();
  List<SeriesUnlockModel> get highestValue => sortByPrice().take(10).toList();
  List<SeriesUnlockModel> get topAffiliateEarners => sortByAffiliateEarnings().take(10).toList();
}