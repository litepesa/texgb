// lib/features/live_streaming/models/live_chat_message_model.dart

// Message type enum
enum ChatMessageType {
  text,           // Regular text message
  gift,           // Gift announcement message
  system,         // System message (user joined, etc.)
  product,        // Product announcement
  welcome,        // Welcome message for new viewers
  announcement;   // Host announcement

  String get displayName {
    switch (this) {
      case ChatMessageType.text:
        return 'Text';
      case ChatMessageType.gift:
        return 'Gift';
      case ChatMessageType.system:
        return 'System';
      case ChatMessageType.product:
        return 'Product';
      case ChatMessageType.welcome:
        return 'Welcome';
      case ChatMessageType.announcement:
        return 'Announcement';
    }
  }

  bool get isSpecialMessage =>
      this == ChatMessageType.gift ||
      this == ChatMessageType.system ||
      this == ChatMessageType.product ||
      this == ChatMessageType.welcome ||
      this == ChatMessageType.announcement;
}

// Main Live Chat Message Model
class LiveChatMessageModel {
  final String id;
  final String liveStreamId;
  final ChatMessageType type;

  // Sender info
  final String senderId;
  final String senderName;
  final String senderImage;
  final bool senderIsVerified;
  final bool senderIsHost;       // Is this message from the stream host?
  final bool senderIsModerator;  // Is this sender a moderator?

  // Message content
  final String message;
  final String? translatedMessage; // For future multi-language support

  // Gift info (if type is gift)
  final String? giftId;
  final String? giftName;
  final String? giftEmoji;
  final double? giftPrice;
  final int? giftComboCount;

  // Product info (if type is product)
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final double? productPrice;

  // Metadata
  final String sentAt;
  final bool isDeleted;
  final String? deletedAt;
  final String? deletedBy;      // User ID who deleted it
  final bool isPinned;          // Pinned by host/moderator
  final String? pinnedAt;
  final int likesCount;         // Users can like chat messages
  final List<String> likedBy;   // User IDs who liked this message

  // Moderation
  final bool isReported;
  final int reportCount;

  const LiveChatMessageModel({
    required this.id,
    required this.liveStreamId,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.senderIsVerified,
    required this.senderIsHost,
    required this.senderIsModerator,
    required this.message,
    this.translatedMessage,
    this.giftId,
    this.giftName,
    this.giftEmoji,
    this.giftPrice,
    this.giftComboCount,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.productPrice,
    required this.sentAt,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.isPinned = false,
    this.pinnedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.isReported = false,
    this.reportCount = 0,
  });

  // Create text message
  factory LiveChatMessageModel.createTextMessage({
    required String liveStreamId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required bool senderIsVerified,
    required bool senderIsHost,
    required bool senderIsModerator,
    required String message,
  }) {
    return LiveChatMessageModel(
      id: '', // Will be set by backend
      liveStreamId: liveStreamId,
      type: ChatMessageType.text,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      senderIsVerified: senderIsVerified,
      senderIsHost: senderIsHost,
      senderIsModerator: senderIsModerator,
      message: message.trim(),
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Create gift announcement message
  factory LiveChatMessageModel.createGiftMessage({
    required String liveStreamId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required bool senderIsVerified,
    required String giftId,
    required String giftName,
    required String giftEmoji,
    required double giftPrice,
    int giftComboCount = 1,
  }) {
    String message;
    if (giftComboCount > 1) {
      message = '$senderName sent $giftComboCount × $giftEmoji $giftName';
    } else {
      message = '$senderName sent $giftEmoji $giftName';
    }

    return LiveChatMessageModel(
      id: '',
      liveStreamId: liveStreamId,
      type: ChatMessageType.gift,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      senderIsVerified: senderIsVerified,
      senderIsHost: false,
      senderIsModerator: false,
      message: message,
      giftId: giftId,
      giftName: giftName,
      giftEmoji: giftEmoji,
      giftPrice: giftPrice,
      giftComboCount: giftComboCount,
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Create system message
  factory LiveChatMessageModel.createSystemMessage({
    required String liveStreamId,
    required String message,
  }) {
    return LiveChatMessageModel(
      id: '',
      liveStreamId: liveStreamId,
      type: ChatMessageType.system,
      senderId: 'system',
      senderName: 'System',
      senderImage: '',
      senderIsVerified: false,
      senderIsHost: false,
      senderIsModerator: false,
      message: message,
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Create product announcement message
  factory LiveChatMessageModel.createProductMessage({
    required String liveStreamId,
    required String hostId,
    required String hostName,
    required String hostImage,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double productPrice,
  }) {
    return LiveChatMessageModel(
      id: '',
      liveStreamId: liveStreamId,
      type: ChatMessageType.product,
      senderId: hostId,
      senderName: hostName,
      senderImage: hostImage,
      senderIsVerified: false,
      senderIsHost: true,
      senderIsModerator: false,
      message: '📦 Check out $productName - ${productPrice.toStringAsFixed(0)} KES',
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      productPrice: productPrice,
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Create welcome message
  factory LiveChatMessageModel.createWelcomeMessage({
    required String liveStreamId,
    required String userId,
    required String userName,
    required String userImage,
    required bool isVerified,
  }) {
    return LiveChatMessageModel(
      id: '',
      liveStreamId: liveStreamId,
      type: ChatMessageType.welcome,
      senderId: userId,
      senderName: userName,
      senderImage: userImage,
      senderIsVerified: isVerified,
      senderIsHost: false,
      senderIsModerator: false,
      message: '$userName joined the stream',
      sentAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // Create host announcement
  factory LiveChatMessageModel.createAnnouncement({
    required String liveStreamId,
    required String hostId,
    required String hostName,
    required String hostImage,
    required String announcement,
  }) {
    return LiveChatMessageModel(
      id: '',
      liveStreamId: liveStreamId,
      type: ChatMessageType.announcement,
      senderId: hostId,
      senderName: hostName,
      senderImage: hostImage,
      senderIsVerified: false,
      senderIsHost: true,
      senderIsModerator: false,
      message: announcement,
      sentAt: DateTime.now().toUtc().toIso8601String(),
      isPinned: true,
      pinnedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  // From JSON (backend response or WebSocket message)
  factory LiveChatMessageModel.fromJson(Map<String, dynamic> json) {
    return LiveChatMessageModel(
      id: json['id'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => ChatMessageType.text,
      ),
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderImage: json['senderImage'] ?? json['sender_image'] ?? '',
      senderIsVerified: json['senderIsVerified'] ?? json['sender_is_verified'] ?? false,
      senderIsHost: json['senderIsHost'] ?? json['sender_is_host'] ?? false,
      senderIsModerator: json['senderIsModerator'] ?? json['sender_is_moderator'] ?? false,
      message: json['message'] ?? '',
      translatedMessage: json['translatedMessage'] ?? json['translated_message'],
      giftId: json['giftId'] ?? json['gift_id'],
      giftName: json['giftName'] ?? json['gift_name'],
      giftEmoji: json['giftEmoji'] ?? json['gift_emoji'],
      giftPrice: json['giftPrice'] != null ? (json['giftPrice'] ?? json['gift_price']).toDouble() : null,
      giftComboCount: json['giftComboCount'] ?? json['gift_combo_count'],
      productId: json['productId'] ?? json['product_id'],
      productName: json['productName'] ?? json['product_name'],
      productImageUrl: json['productImageUrl'] ?? json['product_image_url'],
      productPrice: json['productPrice'] != null ? (json['productPrice'] ?? json['product_price']).toDouble() : null,
      sentAt: json['sentAt'] ?? json['sent_at'] ?? DateTime.now().toUtc().toIso8601String(),
      isDeleted: json['isDeleted'] ?? json['is_deleted'] ?? false,
      deletedAt: json['deletedAt'] ?? json['deleted_at'],
      deletedBy: json['deletedBy'] ?? json['deleted_by'],
      isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
      pinnedAt: json['pinnedAt'] ?? json['pinned_at'],
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? json['liked_by'] ?? []),
      isReported: json['isReported'] ?? json['is_reported'] ?? false,
      reportCount: json['reportCount'] ?? json['report_count'] ?? 0,
    );
  }

  // To JSON (for API requests and WebSocket messages)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liveStreamId': liveStreamId,
      'type': type.name,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'senderIsVerified': senderIsVerified,
      'senderIsHost': senderIsHost,
      'senderIsModerator': senderIsModerator,
      'message': message,
      'translatedMessage': translatedMessage,
      'giftId': giftId,
      'giftName': giftName,
      'giftEmoji': giftEmoji,
      'giftPrice': giftPrice,
      'giftComboCount': giftComboCount,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'productPrice': productPrice,
      'sentAt': sentAt,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'isReported': isReported,
      'reportCount': reportCount,
    };
  }

  // CopyWith method
  LiveChatMessageModel copyWith({
    String? id,
    String? liveStreamId,
    ChatMessageType? type,
    String? senderId,
    String? senderName,
    String? senderImage,
    bool? senderIsVerified,
    bool? senderIsHost,
    bool? senderIsModerator,
    String? message,
    String? translatedMessage,
    String? giftId,
    String? giftName,
    String? giftEmoji,
    double? giftPrice,
    int? giftComboCount,
    String? productId,
    String? productName,
    String? productImageUrl,
    double? productPrice,
    String? sentAt,
    bool? isDeleted,
    String? deletedAt,
    String? deletedBy,
    bool? isPinned,
    String? pinnedAt,
    int? likesCount,
    List<String>? likedBy,
    bool? isReported,
    int? reportCount,
  }) {
    return LiveChatMessageModel(
      id: id ?? this.id,
      liveStreamId: liveStreamId ?? this.liveStreamId,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      senderIsVerified: senderIsVerified ?? this.senderIsVerified,
      senderIsHost: senderIsHost ?? this.senderIsHost,
      senderIsModerator: senderIsModerator ?? this.senderIsModerator,
      message: message ?? this.message,
      translatedMessage: translatedMessage ?? this.translatedMessage,
      giftId: giftId ?? this.giftId,
      giftName: giftName ?? this.giftName,
      giftEmoji: giftEmoji ?? this.giftEmoji,
      giftPrice: giftPrice ?? this.giftPrice,
      giftComboCount: giftComboCount ?? this.giftComboCount,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productPrice: productPrice ?? this.productPrice,
      sentAt: sentAt ?? this.sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      isReported: isReported ?? this.isReported,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  // Helper getters
  bool get isTextMessage => type == ChatMessageType.text;
  bool get isGiftMessage => type == ChatMessageType.gift;
  bool get isSystemMessage => type == ChatMessageType.system;
  bool get isProductMessage => type == ChatMessageType.product;
  bool get isWelcomeMessage => type == ChatMessageType.welcome;
  bool get isAnnouncementMessage => type == ChatMessageType.announcement;
  bool get isSpecialMessage => type.isSpecialMessage;

  bool get canBeDeleted => !isDeleted && !isSystemMessage;
  bool get canBePinned => !isPinned && (isTextMessage || isAnnouncementMessage);
  bool get canBeLiked => !isSystemMessage && !isWelcomeMessage;

  String get timeAgo {
    final sent = DateTime.parse(sentAt);
    final now = DateTime.now();
    final difference = now.difference(sent);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String get displayText {
    if (isDeleted) return '[Message deleted]';
    return message;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveChatMessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveChatMessageModel(id: $id, type: ${type.name}, sender: $senderName, message: $message)';
  }
}

// Chat settings model (for stream chat configuration)
class ChatSettingsModel {
  final bool isEnabled;                  // Chat enabled/disabled
  final bool slowMode;                   // Slow mode (rate limiting)
  final int slowModeInterval;            // Seconds between messages
  final bool subscribersOnly;            // Only followers can chat
  final bool verifiedOnly;               // Only verified users can chat
  final int maxMessageLength;            // Maximum message length
  final List<String> blockedWords;       // Blocked words list
  final List<String> allowedEmojis;      // Allowed emojis (if restricted)

  const ChatSettingsModel({
    this.isEnabled = true,
    this.slowMode = false,
    this.slowModeInterval = 3,
    this.subscribersOnly = false,
    this.verifiedOnly = false,
    this.maxMessageLength = 200,
    this.blockedWords = const [],
    this.allowedEmojis = const [],
  });

  factory ChatSettingsModel.fromJson(Map<String, dynamic> json) {
    return ChatSettingsModel(
      isEnabled: json['isEnabled'] ?? json['is_enabled'] ?? true,
      slowMode: json['slowMode'] ?? json['slow_mode'] ?? false,
      slowModeInterval: json['slowModeInterval'] ?? json['slow_mode_interval'] ?? 3,
      subscribersOnly: json['subscribersOnly'] ?? json['subscribers_only'] ?? false,
      verifiedOnly: json['verifiedOnly'] ?? json['verified_only'] ?? false,
      maxMessageLength: json['maxMessageLength'] ?? json['max_message_length'] ?? 200,
      blockedWords: List<String>.from(json['blockedWords'] ?? json['blocked_words'] ?? []),
      allowedEmojis: List<String>.from(json['allowedEmojis'] ?? json['allowed_emojis'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'slowMode': slowMode,
      'slowModeInterval': slowModeInterval,
      'subscribersOnly': subscribersOnly,
      'verifiedOnly': verifiedOnly,
      'maxMessageLength': maxMessageLength,
      'blockedWords': blockedWords,
      'allowedEmojis': allowedEmojis,
    };
  }

  ChatSettingsModel copyWith({
    bool? isEnabled,
    bool? slowMode,
    int? slowModeInterval,
    bool? subscribersOnly,
    bool? verifiedOnly,
    int? maxMessageLength,
    List<String>? blockedWords,
    List<String>? allowedEmojis,
  }) {
    return ChatSettingsModel(
      isEnabled: isEnabled ?? this.isEnabled,
      slowMode: slowMode ?? this.slowMode,
      slowModeInterval: slowModeInterval ?? this.slowModeInterval,
      subscribersOnly: subscribersOnly ?? this.subscribersOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      maxMessageLength: maxMessageLength ?? this.maxMessageLength,
      blockedWords: blockedWords ?? this.blockedWords,
      allowedEmojis: allowedEmojis ?? this.allowedEmojis,
    );
  }
}