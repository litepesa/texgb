// lib/features/live_streaming/models/live_stream_model.dart

// Live stream status enum
enum LiveStreamStatus {
  scheduled,  // Stream is scheduled for future
  live,       // Currently streaming
  ended,      // Stream has ended
  cancelled;  // Stream was cancelled

  String get displayName {
    switch (this) {
      case LiveStreamStatus.scheduled:
        return 'Scheduled';
      case LiveStreamStatus.live:
        return 'Live';
      case LiveStreamStatus.ended:
        return 'Ended';
      case LiveStreamStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Live stream category enum
enum LiveStreamCategory {
  entertainment,
  shopping,
  education,
  lifestyle,
  beauty,
  fitness,
  cooking,
  gaming,
  music,
  talk,
  other;

  String get displayName {
    switch (this) {
      case LiveStreamCategory.entertainment:
        return 'Entertainment';
      case LiveStreamCategory.shopping:
        return 'Shopping';
      case LiveStreamCategory.education:
        return 'Education';
      case LiveStreamCategory.lifestyle:
        return 'Lifestyle';
      case LiveStreamCategory.beauty:
        return 'Beauty & Fashion';
      case LiveStreamCategory.fitness:
        return 'Fitness & Sports';
      case LiveStreamCategory.cooking:
        return 'Cooking & Food';
      case LiveStreamCategory.gaming:
        return 'Gaming';
      case LiveStreamCategory.music:
        return 'Music';
      case LiveStreamCategory.talk:
        return 'Talk Show';
      case LiveStreamCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case LiveStreamCategory.entertainment:
        return '🎭';
      case LiveStreamCategory.shopping:
        return '🛍️';
      case LiveStreamCategory.education:
        return '📚';
      case LiveStreamCategory.lifestyle:
        return '✨';
      case LiveStreamCategory.beauty:
        return '💄';
      case LiveStreamCategory.fitness:
        return '💪';
      case LiveStreamCategory.cooking:
        return '👨‍🍳';
      case LiveStreamCategory.gaming:
        return '🎮';
      case LiveStreamCategory.music:
        return '🎵';
      case LiveStreamCategory.talk:
        return '🎙️';
      case LiveStreamCategory.other:
        return '📱';
    }
  }

  static LiveStreamCategory fromString(String? value) {
    if (value == null) return LiveStreamCategory.other;
    return LiveStreamCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LiveStreamCategory.other,
    );
  }
}

// Main Live Stream Model
class LiveStreamModel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostImage;
  final bool hostIsVerified;
  
  // Stream details
  final String title;
  final String description;
  final String thumbnailUrl;
  final LiveStreamCategory category;
  final List<String> tags;
  final LiveStreamStatus status;
  
  // Agora details
  final String channelName;
  final String? agoraToken;
  final String? agoraUid;
  
  // Metrics
  final int currentViewers;
  final int totalViewers;
  final int peakViewers;
  final int likesCount;
  final int giftsCount;
  final double totalGiftRevenue;  // Total KES earned from gifts
  
  // Products (for e-commerce streams)
  final List<LiveStreamProduct> products;
  final String? pinnedProductId;  // Currently highlighted product
  
  // Timestamps
  final String scheduledAt;  // When stream is scheduled to start
  final String? startedAt;   // When stream actually started
  final String? endedAt;     // When stream ended
  final String createdAt;
  final String updatedAt;
  
  // Settings
  final bool isRecording;        // Auto-save stream for replay
  final bool allowComments;      // Enable/disable chat
  final bool isPrivate;          // Private stream (followers only)
  
  // Moderation
  final List<String> blockedUserIds;  // Users blocked by host
  final List<String> moderatorIds;    // Users with mod privileges
  final int reportCount;              // Number of reports received

  const LiveStreamModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostImage,
    required this.hostIsVerified,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.tags,
    required this.status,
    required this.channelName,
    this.agoraToken,
    this.agoraUid,
    required this.currentViewers,
    required this.totalViewers,
    required this.peakViewers,
    required this.likesCount,
    required this.giftsCount,
    required this.totalGiftRevenue,
    required this.products,
    this.pinnedProductId,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isRecording,
    required this.allowComments,
    required this.isPrivate,
    required this.blockedUserIds,
    required this.moderatorIds,
    required this.reportCount,
  });

  // Create new stream (before going live)
  factory LiveStreamModel.create({
    required String hostId,
    required String hostName,
    required String hostImage,
    required bool hostIsVerified,
    required String title,
    String description = '',
    String thumbnailUrl = '',
    LiveStreamCategory category = LiveStreamCategory.other,
    List<String> tags = const [],
    bool isRecording = true,
    bool allowComments = true,
    bool isPrivate = false,
    String? scheduledAt,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    final channelName = 'live_${hostId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return LiveStreamModel(
      id: '',  // Will be set by backend
      hostId: hostId,
      hostName: hostName,
      hostImage: hostImage,
      hostIsVerified: hostIsVerified,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      category: category,
      tags: tags,
      status: scheduledAt != null 
          ? LiveStreamStatus.scheduled 
          : LiveStreamStatus.live,
      channelName: channelName,
      currentViewers: 0,
      totalViewers: 0,
      peakViewers: 0,
      likesCount: 0,
      giftsCount: 0,
      totalGiftRevenue: 0.0,
      products: [],
      scheduledAt: scheduledAt ?? now,
      createdAt: now,
      updatedAt: now,
      isRecording: isRecording,
      allowComments: allowComments,
      isPrivate: isPrivate,
      blockedUserIds: [],
      moderatorIds: [],
      reportCount: 0,
    );
  }

  // From JSON (backend response)
  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: json['id'] ?? '',
      hostId: json['hostId'] ?? json['host_id'] ?? '',
      hostName: json['hostName'] ?? json['host_name'] ?? '',
      hostImage: json['hostImage'] ?? json['host_image'] ?? '',
      hostIsVerified: json['hostIsVerified'] ?? json['host_is_verified'] ?? false,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? '',
      category: LiveStreamCategory.fromString(json['category']),
      tags: List<String>.from(json['tags'] ?? []),
      status: LiveStreamStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'ended'),
        orElse: () => LiveStreamStatus.ended,
      ),
      channelName: json['channelName'] ?? json['channel_name'] ?? '',
      agoraToken: json['agoraToken'] ?? json['agora_token'],
      agoraUid: json['agoraUid'] ?? json['agora_uid'],
      currentViewers: json['currentViewers'] ?? json['current_viewers'] ?? 0,
      totalViewers: json['totalViewers'] ?? json['total_viewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? json['peak_viewers'] ?? 0,
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      giftsCount: json['giftsCount'] ?? json['gifts_count'] ?? 0,
      totalGiftRevenue: (json['totalGiftRevenue'] ?? json['total_gift_revenue'] ?? 0).toDouble(),
      products: (json['products'] as List<dynamic>?)
          ?.map((p) => LiveStreamProduct.fromJson(p))
          .toList() ?? [],
      pinnedProductId: json['pinnedProductId'] ?? json['pinned_product_id'],
      scheduledAt: json['scheduledAt'] ?? json['scheduled_at'] ?? '',
      startedAt: json['startedAt'] ?? json['started_at'],
      endedAt: json['endedAt'] ?? json['ended_at'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
      updatedAt: json['updatedAt'] ?? json['updated_at'] ?? '',
      isRecording: json['isRecording'] ?? json['is_recording'] ?? true,
      allowComments: json['allowComments'] ?? json['allow_comments'] ?? true,
      isPrivate: json['isPrivate'] ?? json['is_private'] ?? false,
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? json['blocked_user_ids'] ?? []),
      moderatorIds: List<String>.from(json['moderatorIds'] ?? json['moderator_ids'] ?? []),
      reportCount: json['reportCount'] ?? json['report_count'] ?? 0,
    );
  }

  // To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'hostImage': hostImage,
      'hostIsVerified': hostIsVerified,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category.name,
      'tags': tags,
      'status': status.name,
      'channelName': channelName,
      'agoraToken': agoraToken,
      'agoraUid': agoraUid,
      'currentViewers': currentViewers,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'likesCount': likesCount,
      'giftsCount': giftsCount,
      'totalGiftRevenue': totalGiftRevenue,
      'products': products.map((p) => p.toJson()).toList(),
      'pinnedProductId': pinnedProductId,
      'scheduledAt': scheduledAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isRecording': isRecording,
      'allowComments': allowComments,
      'isPrivate': isPrivate,
      'blockedUserIds': blockedUserIds,
      'moderatorIds': moderatorIds,
      'reportCount': reportCount,
    };
  }

  // CopyWith method
  LiveStreamModel copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostImage,
    bool? hostIsVerified,
    String? title,
    String? description,
    String? thumbnailUrl,
    LiveStreamCategory? category,
    List<String>? tags,
    LiveStreamStatus? status,
    String? channelName,
    String? agoraToken,
    String? agoraUid,
    int? currentViewers,
    int? totalViewers,
    int? peakViewers,
    int? likesCount,
    int? giftsCount,
    double? totalGiftRevenue,
    List<LiveStreamProduct>? products,
    String? pinnedProductId,
    String? scheduledAt,
    String? startedAt,
    String? endedAt,
    String? createdAt,
    String? updatedAt,
    bool? isRecording,
    bool? allowComments,
    bool? isPrivate,
    List<String>? blockedUserIds,
    List<String>? moderatorIds,
    int? reportCount,
  }) {
    return LiveStreamModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostImage: hostImage ?? this.hostImage,
      hostIsVerified: hostIsVerified ?? this.hostIsVerified,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      channelName: channelName ?? this.channelName,
      agoraToken: agoraToken ?? this.agoraToken,
      agoraUid: agoraUid ?? this.agoraUid,
      currentViewers: currentViewers ?? this.currentViewers,
      totalViewers: totalViewers ?? this.totalViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      likesCount: likesCount ?? this.likesCount,
      giftsCount: giftsCount ?? this.giftsCount,
      totalGiftRevenue: totalGiftRevenue ?? this.totalGiftRevenue,
      products: products ?? this.products,
      pinnedProductId: pinnedProductId ?? this.pinnedProductId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecording: isRecording ?? this.isRecording,
      allowComments: allowComments ?? this.allowComments,
      isPrivate: isPrivate ?? this.isPrivate,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  // Helper getters
  bool get isLive => status == LiveStreamStatus.live;
  bool get isScheduled => status == LiveStreamStatus.scheduled;
  bool get isEnded => status == LiveStreamStatus.ended;
  bool get hasProducts => products.isNotEmpty;
  bool get hasPinnedProduct => pinnedProductId != null;
  
  LiveStreamProduct? get pinnedProduct {
    if (pinnedProductId == null) return null;
    try {
      return products.firstWhere((p) => p.id == pinnedProductId);
    } catch (e) {
      return null;
    }
  }

  String get durationText {
    if (startedAt == null) return '0:00';
    final start = DateTime.parse(startedAt!);
    final end = endedAt != null ? DateTime.parse(endedAt!) : DateTime.now();
    final duration = end.difference(start);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get viewersText {
    if (currentViewers < 1000) return '$currentViewers';
    if (currentViewers < 1000000) return '${(currentViewers / 1000).toStringAsFixed(1)}K';
    return '${(currentViewers / 1000000).toStringAsFixed(1)}M';
  }

  String get revenueText {
    if (totalGiftRevenue < 1000) return '${totalGiftRevenue.toStringAsFixed(0)} KES';
    if (totalGiftRevenue < 1000000) return '${(totalGiftRevenue / 1000).toStringAsFixed(1)}K KES';
    return '${(totalGiftRevenue / 1000000).toStringAsFixed(1)}M KES';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveStreamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Product model for live stream shopping
class LiveStreamProduct {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? discountPrice;  // Special live-only price
  final int stock;
  final String category;
  final bool isAvailable;
  final int soldCount;  // How many sold during this stream

  const LiveStreamProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.discountPrice,
    required this.stock,
    required this.category,
    required this.isAvailable,
    required this.soldCount,
  });

  factory LiveStreamProduct.fromJson(Map<String, dynamic> json) {
    return LiveStreamProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice'] != null 
          ? (json['discountPrice'] ?? json['discount_price']).toDouble() 
          : null,
      stock: json['stock'] ?? 0,
      category: json['category'] ?? '',
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      soldCount: json['soldCount'] ?? json['sold_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'category': category,
      'isAvailable': isAvailable,
      'soldCount': soldCount,
    };
  }

  LiveStreamProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    double? discountPrice,
    int? stock,
    String? category,
    bool? isAvailable,
    int? soldCount,
  }) {
    return LiveStreamProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      soldCount: soldCount ?? this.soldCount,
    );
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get isOutOfStock => stock <= 0;
  double get effectivePrice => hasDiscount ? discountPrice! : price;
  double get discountPercentage => hasDiscount 
      ? ((price - discountPrice!) / price * 100) 
      : 0;

  String get priceText => '${effectivePrice.toStringAsFixed(0)} KES';
  String get stockText => stock > 0 ? '$stock left' : 'Out of stock';
}