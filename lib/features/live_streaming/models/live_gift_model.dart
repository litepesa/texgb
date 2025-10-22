// lib/features/live_streaming/models/live_gift_model.dart

// Gift rarity/tier enum
enum GiftTier {
  basic,      // 10-50 KES
  popular,    // 100-500 KES
  premium,    // 1000-2000 KES
  luxury,     // 5000+ KES
  exclusive;  // Special limited gifts

  String get displayName {
    switch (this) {
      case GiftTier.basic:
        return 'Basic';
      case GiftTier.popular:
        return 'Popular';
      case GiftTier.premium:
        return 'Premium';
      case GiftTier.luxury:
        return 'Luxury';
      case GiftTier.exclusive:
        return 'Exclusive';
    }
  }

  String get color {
    switch (this) {
      case GiftTier.basic:
        return '#9CA3AF'; // Gray
      case GiftTier.popular:
        return '#3B82F6'; // Blue
      case GiftTier.premium:
        return '#8B5CF6'; // Purple
      case GiftTier.luxury:
        return '#F59E0B'; // Gold
      case GiftTier.exclusive:
        return '#EF4444'; // Red
    }
  }
}

// Animation type for gift display
enum GiftAnimationType {
  float,          // Floats up from bottom (basic gifts)
  burst,          // Explodes in center (popular gifts)
  cascade,        // Multiple items cascade down (premium)
  fullscreen,     // Takes over screen (luxury)
  combo;          // Combo multiplier effect

  String get description {
    switch (this) {
      case GiftAnimationType.float:
        return 'Floats gently upward';
      case GiftAnimationType.burst:
        return 'Bursts with particles';
      case GiftAnimationType.cascade:
        return 'Cascades across screen';
      case GiftAnimationType.fullscreen:
        return 'Fullscreen spectacular';
      case GiftAnimationType.combo:
        return 'Combo multiplier';
    }
  }
}

// Predefined gift type
class GiftType {
  final String id;
  final String name;
  final String emoji;           // Unicode emoji
  final String? lottieUrl;      // Lottie animation URL (optional)
  final String? imageUrl;       // Static image URL (fallback)
  final double price;           // Price in KES
  final GiftTier tier;
  final GiftAnimationType animationType;
  final int durationMs;         // Animation duration in milliseconds
  final bool isAvailable;       // Can be purchased
  final bool isLimited;         // Limited time offer
  final String? expiresAt;      // When limited gift expires

  const GiftType({
    required this.id,
    required this.name,
    required this.emoji,
    this.lottieUrl,
    this.imageUrl,
    required this.price,
    required this.tier,
    required this.animationType,
    this.durationMs = 2000,
    this.isAvailable = true,
    this.isLimited = false,
    this.expiresAt,
  });

  factory GiftType.fromJson(Map<String, dynamic> json) {
    return GiftType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '🎁',
      lottieUrl: json['lottieUrl'] ?? json['lottie_url'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      price: (json['price'] ?? 0).toDouble(),
      tier: GiftTier.values.firstWhere(
        (e) => e.name == (json['tier'] ?? 'basic'),
        orElse: () => GiftTier.basic,
      ),
      animationType: GiftAnimationType.values.firstWhere(
        (e) => e.name == (json['animationType'] ?? json['animation_type'] ?? 'float'),
        orElse: () => GiftAnimationType.float,
      ),
      durationMs: json['durationMs'] ?? json['duration_ms'] ?? 2000,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      isLimited: json['isLimited'] ?? json['is_limited'] ?? false,
      expiresAt: json['expiresAt'] ?? json['expires_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'lottieUrl': lottieUrl,
      'imageUrl': imageUrl,
      'price': price,
      'tier': tier.name,
      'animationType': animationType.name,
      'durationMs': durationMs,
      'isAvailable': isAvailable,
      'isLimited': isLimited,
      'expiresAt': expiresAt,
    };
  }

  String get priceText => '${price.toStringAsFixed(0)} KES';
  
  bool get isExpired {
    if (!isLimited || expiresAt == null) return false;
    return DateTime.parse(expiresAt!).isBefore(DateTime.now());
  }

  // Default gift types (can be loaded from backend)
  static List<GiftType> get defaultGifts => [
    // Basic Tier (10-50 KES)
    const GiftType(
      id: 'rose',
      name: 'Rose',
      emoji: '🌹',
      price: 10,
      tier: GiftTier.basic,
      animationType: GiftAnimationType.float,
      durationMs: 2000,
    ),
    const GiftType(
      id: 'heart',
      name: 'Heart',
      emoji: '❤️',
      price: 20,
      tier: GiftTier.basic,
      animationType: GiftAnimationType.float,
      durationMs: 2000,
    ),
    const GiftType(
      id: 'clap',
      name: 'Clap',
      emoji: '👏',
      price: 30,
      tier: GiftTier.basic,
      animationType: GiftAnimationType.float,
      durationMs: 2000,
    ),
    const GiftType(
      id: 'fire',
      name: 'Fire',
      emoji: '🔥',
      price: 50,
      tier: GiftTier.basic,
      animationType: GiftAnimationType.float,
      durationMs: 2000,
    ),

    // Popular Tier (100-500 KES)
    const GiftType(
      id: 'star',
      name: 'Star',
      emoji: '⭐',
      price: 100,
      tier: GiftTier.popular,
      animationType: GiftAnimationType.burst,
      durationMs: 3000,
    ),
    const GiftType(
      id: 'diamond',
      name: 'Diamond',
      emoji: '💎',
      price: 200,
      tier: GiftTier.popular,
      animationType: GiftAnimationType.burst,
      durationMs: 3000,
    ),
    const GiftType(
      id: 'trophy',
      name: 'Trophy',
      emoji: '🏆',
      price: 500,
      tier: GiftTier.popular,
      animationType: GiftAnimationType.burst,
      durationMs: 3000,
    ),

    // Premium Tier (1000-2000 KES)
    const GiftType(
      id: 'crown',
      name: 'Crown',
      emoji: '👑',
      price: 1000,
      tier: GiftTier.premium,
      animationType: GiftAnimationType.cascade,
      durationMs: 4000,
    ),
    const GiftType(
      id: 'rocket',
      name: 'Rocket',
      emoji: '🚀',
      price: 1500,
      tier: GiftTier.premium,
      animationType: GiftAnimationType.cascade,
      durationMs: 4000,
    ),

    // Luxury Tier (5000+ KES)
    const GiftType(
      id: 'sports_car',
      name: 'Sports Car',
      emoji: '🏎️',
      price: 5000,
      tier: GiftTier.luxury,
      animationType: GiftAnimationType.fullscreen,
      durationMs: 5000,
    ),
    const GiftType(
      id: 'mansion',
      name: 'Mansion',
      emoji: '🏰',
      price: 10000,
      tier: GiftTier.luxury,
      animationType: GiftAnimationType.fullscreen,
      durationMs: 5000,
    ),
  ];
}

// Gift transaction model (when a user sends a gift)
class LiveGiftModel {
  final String id;
  final String liveStreamId;
  final String giftTypeId;
  
  // Sender info
  final String senderId;
  final String senderName;
  final String senderImage;
  final bool senderIsVerified;
  
  // Receiver info (host)
  final String receiverId;
  final String receiverName;
  
  // Gift details
  final String giftName;
  final String giftEmoji;
  final double giftPrice;
  final GiftTier giftTier;
  final GiftAnimationType animationType;
  
  // Combo tracking
  final int comboCount;         // How many in a row (1 = single gift)
  final bool isCombo;           // Is this part of a combo?
  final String? comboId;        // Group ID for combo gifts
  
  // Transaction details
  final String sentAt;
  final String? displayedAt;    // When animation was shown
  final bool isDisplayed;       // Has been shown to viewers
  
  // Revenue
  final double hostRevenue;     // 70% of price
  final double platformFee;     // 30% of price

  const LiveGiftModel({
    required this.id,
    required this.liveStreamId,
    required this.giftTypeId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.senderIsVerified,
    required this.receiverId,
    required this.receiverName,
    required this.giftName,
    required this.giftEmoji,
    required this.giftPrice,
    required this.giftTier,
    required this.animationType,
    this.comboCount = 1,
    this.isCombo = false,
    this.comboId,
    required this.sentAt,
    this.displayedAt,
    this.isDisplayed = false,
    required this.hostRevenue,
    required this.platformFee,
  });

  // Create from gift type
  factory LiveGiftModel.create({
    required String liveStreamId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required bool senderIsVerified,
    required String receiverId,
    required String receiverName,
    required GiftType giftType,
    int comboCount = 1,
    String? comboId,
  }) {
    final totalPrice = giftType.price * comboCount;
    final hostRevenue = totalPrice * 0.70; // 70% to host
    final platformFee = totalPrice * 0.30; // 30% platform fee
    final now = DateTime.now().toUtc().toIso8601String();

    return LiveGiftModel(
      id: '', // Will be set by backend
      liveStreamId: liveStreamId,
      giftTypeId: giftType.id,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      senderIsVerified: senderIsVerified,
      receiverId: receiverId,
      receiverName: receiverName,
      giftName: giftType.name,
      giftEmoji: giftType.emoji,
      giftPrice: totalPrice,
      giftTier: giftType.tier,
      animationType: comboCount > 1 
          ? GiftAnimationType.combo 
          : giftType.animationType,
      comboCount: comboCount,
      isCombo: comboCount > 1,
      comboId: comboId,
      sentAt: now,
      hostRevenue: hostRevenue,
      platformFee: platformFee,
    );
  }

  factory LiveGiftModel.fromJson(Map<String, dynamic> json) {
    return LiveGiftModel(
      id: json['id'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      giftTypeId: json['giftTypeId'] ?? json['gift_type_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderImage: json['senderImage'] ?? json['sender_image'] ?? '',
      senderIsVerified: json['senderIsVerified'] ?? json['sender_is_verified'] ?? false,
      receiverId: json['receiverId'] ?? json['receiver_id'] ?? '',
      receiverName: json['receiverName'] ?? json['receiver_name'] ?? '',
      giftName: json['giftName'] ?? json['gift_name'] ?? '',
      giftEmoji: json['giftEmoji'] ?? json['gift_emoji'] ?? '🎁',
      giftPrice: (json['giftPrice'] ?? json['gift_price'] ?? 0).toDouble(),
      giftTier: GiftTier.values.firstWhere(
        (e) => e.name == (json['giftTier'] ?? json['gift_tier'] ?? 'basic'),
        orElse: () => GiftTier.basic,
      ),
      animationType: GiftAnimationType.values.firstWhere(
        (e) => e.name == (json['animationType'] ?? json['animation_type'] ?? 'float'),
        orElse: () => GiftAnimationType.float,
      ),
      comboCount: json['comboCount'] ?? json['combo_count'] ?? 1,
      isCombo: json['isCombo'] ?? json['is_combo'] ?? false,
      comboId: json['comboId'] ?? json['combo_id'],
      sentAt: json['sentAt'] ?? json['sent_at'] ?? '',
      displayedAt: json['displayedAt'] ?? json['displayed_at'],
      isDisplayed: json['isDisplayed'] ?? json['is_displayed'] ?? false,
      hostRevenue: (json['hostRevenue'] ?? json['host_revenue'] ?? 0).toDouble(),
      platformFee: (json['platformFee'] ?? json['platform_fee'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liveStreamId': liveStreamId,
      'giftTypeId': giftTypeId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'senderIsVerified': senderIsVerified,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'giftPrice': giftPrice,
      'giftTier': giftTier.name,
      'animationType': animationType.name,
      'comboCount': comboCount,
      'isCombo': isCombo,
      'comboId': comboId,
      'sentAt': sentAt,
      'displayedAt': displayedAt,
      'isDisplayed': isDisplayed,
      'hostRevenue': hostRevenue,
      'platformFee': platformFee,
    };
  }

  LiveGiftModel copyWith({
    String? id,
    String? liveStreamId,
    String? giftTypeId,
    String? senderId,
    String? senderName,
    String? senderImage,
    bool? senderIsVerified,
    String? receiverId,
    String? receiverName,
    String? giftName,
    String? giftEmoji,
    double? giftPrice,
    GiftTier? giftTier,
    GiftAnimationType? animationType,
    int? comboCount,
    bool? isCombo,
    String? comboId,
    String? sentAt,
    String? displayedAt,
    bool? isDisplayed,
    double? hostRevenue,
    double? platformFee,
  }) {
    return LiveGiftModel(
      id: id ?? this.id,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      giftTypeId: giftTypeId ?? this.giftTypeId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      senderIsVerified: senderIsVerified ?? this.senderIsVerified,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      giftName: giftName ?? this.giftName,
      giftEmoji: giftEmoji ?? this.giftEmoji,
      giftPrice: giftPrice ?? this.giftPrice,
      giftTier: giftTier ?? this.giftTier,
      animationType: animationType ?? this.animationType,
      comboCount: comboCount ?? this.comboCount,
      isCombo: isCombo ?? this.isCombo,
      comboId: comboId ?? this.comboId,
      sentAt: sentAt ?? this.sentAt,
      displayedAt: displayedAt ?? this.displayedAt,
      isDisplayed: isDisplayed ?? this.isDisplayed,
      hostRevenue: hostRevenue ?? this.hostRevenue,
      platformFee: platformFee ?? this.platformFee,
    );
  }

  // Helper getters
  String get displayText {
    if (isCombo) {
      return '$senderName sent $comboCount × $giftEmoji';
    }
    return '$senderName sent $giftEmoji $giftName';
  }

  String get priceText => '${giftPrice.toStringAsFixed(0)} KES';
  String get hostRevenueText => '${hostRevenue.toStringAsFixed(0)} KES';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveGiftModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Leaderboard entry for top gifters
class GiftLeaderboardEntry {
  final String userId;
  final String userName;
  final String userImage;
  final bool isVerified;
  final int rank;
  final double totalSpent;
  final int giftsCount;
  final String? lastGiftAt;

  const GiftLeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.isVerified,
    required this.rank,
    required this.totalSpent,
    required this.giftsCount,
    this.lastGiftAt,
  });

  factory GiftLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GiftLeaderboardEntry(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      userImage: json['userImage'] ?? json['user_image'] ?? '',
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      rank: json['rank'] ?? 0,
      totalSpent: (json['totalSpent'] ?? json['total_spent'] ?? 0).toDouble(),
      giftsCount: json['giftsCount'] ?? json['gifts_count'] ?? 0,
      lastGiftAt: json['lastGiftAt'] ?? json['last_gift_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'isVerified': isVerified,
      'rank': rank,
      'totalSpent': totalSpent,
      'giftsCount': giftsCount,
      'lastGiftAt': lastGiftAt,
    };
  }

  String get totalSpentText {
    if (totalSpent < 1000) return '${totalSpent.toStringAsFixed(0)} KES';
    if (totalSpent < 1000000) return '${(totalSpent / 1000).toStringAsFixed(1)}K KES';
    return '${(totalSpent / 1000000).toStringAsFixed(1)}M KES';
  }

  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}