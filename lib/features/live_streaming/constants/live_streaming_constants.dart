// lib/features/live_streaming/constants/live_streaming_constants.dart

class LiveStreamingConstants {
  LiveStreamingConstants._();

  // ==================== AGORA SETTINGS ====================

  static const String agoraAppId = 'YOUR_AGORA_APP_ID'; // Replace with actual app ID
  static const int agoraTokenExpirySeconds = 3600; // 1 hour
  static const int agoraTokenRenewalThresholdSeconds = 300; // Renew 5 minutes before expiry

  // ==================== DEFAULT VALUES ====================

  static const int defaultPageLimit = 20;
  static const int defaultOffset = 0;
  static const int maxStreamsPerPage = 50;
  static const int defaultGiftLimit = 50;
  static const int leaderboardLimit = 10;

  // ==================== STREAM SETTINGS ====================

  static const int minStreamTitleLength = 5;
  static const int maxStreamTitleLength = 100;
  static const int minStreamDescriptionLength = 10;
  static const int maxStreamDescriptionLength = 500;
  static const int maxStreamTags = 10;
  static const int maxFeaturedProducts = 10; // For shop streams
  static const int minStreamDurationSeconds = 60; // 1 minute minimum
  static const int maxStreamDurationHours = 8; // 8 hours maximum
  static const int streamInactivityTimeoutMinutes = 30; // Auto-end after 30 min of inactivity

  // ==================== VIDEO QUALITY PRESETS ====================

  static const Map<String, Map<String, dynamic>> videoQualityPresets = {
    'low': {
      'width': 320,
      'height': 240,
      'frameRate': 15,
      'bitrate': 200,
    },
    'medium': {
      'width': 640,
      'height': 360,
      'frameRate': 24,
      'bitrate': 500,
    },
    'high': {
      'width': 1280,
      'height': 720,
      'frameRate': 30,
      'bitrate': 1500,
    },
    'ultra': {
      'width': 1920,
      'height': 1080,
      'frameRate': 30,
      'bitrate': 2500,
    },
  };

  // ==================== GIFT SETTINGS ====================

  static const double giftConversionRate = 1.0; // 1 coin = 1 KES
  static const int minGiftQuantity = 1;
  static const int maxGiftQuantity = 999;
  static const int minGiftValue = 1; // 1 coin
  static const int maxGiftValue = 10000; // 10,000 coins
  static const double minGiftAmount = 1.0; // KES 1
  static const double maxGiftAmount = 10000.0; // KES 10,000
  static const int giftAnimationDurationMs = 3000; // 3 seconds
  static const int giftComboTimeoutSeconds = 3; // Combo if sent within 3 seconds

  // ==================== SHOP LIVE SETTINGS ====================

  static const double defaultShopCommissionRate = 10.0; // 10%
  static const double minCommissionRate = 5.0;
  static const double maxCommissionRate = 30.0;
  static const int flashSaleMinDuration = 5; // 5 minutes minimum
  static const int flashSaleMaxDuration = 120; // 2 hours maximum
  static const int pinnedProductDisplaySeconds = 15; // Show pinned product for 15 seconds
  static const int maxProductsInCatalog = 100;

  // ==================== VIEWER SETTINGS ====================

  static const int maxChatMessageLength = 200;
  static const int chatRateLimitSeconds = 2; // One message every 2 seconds
  static const int maxChatMessagesVisible = 50;
  static const int viewerCountUpdateIntervalSeconds = 5; // Update every 5 seconds
  static const int heartbeatIntervalSeconds = 30; // Send heartbeat every 30 seconds
  static const int maxSimultaneousViewers = 10000;

  // ==================== HOST SETTINGS ====================

  static const int minHostLevel = 1; // Minimum level to go live
  static const int cooldownBetweenStreamsMinutes = 5; // 5 minutes between streams
  static const int maxStreamsPerDay = 10;
  static const int minFollowersToGoLive = 0; // No minimum by default
  static const int verifiedBadgeFollowerRequirement = 1000;

  // ==================== MODERATION ====================

  static const int maxBlockedUsers = 1000;
  static const int reportReviewTimeHours = 24; // Reports reviewed within 24 hours
  static const int autoModChatLengthThreshold = 300; // Auto-flag messages > 300 chars
  static const int spamDetectionThreshold = 5; // Flag if same message sent 5 times
  static const List<String> bannedKeywords = [
    // Add banned keywords
  ];

  // ==================== STREAM CATEGORIES ====================

  static const List<String> streamCategories = [
    'Entertainment',
    'Music',
    'Gaming',
    'Education',
    'Shopping',
    'Fashion',
    'Beauty',
    'Cooking',
    'Sports',
    'Fitness',
    'Travel',
    'Technology',
    'Art & Craft',
    'Talk Show',
    'Other'
  ];

  // ==================== GIFT TYPES ====================

  static const Map<String, int> commonGifts = {
    'Heart': 1,
    'Rose': 5,
    'Diamond': 10,
    'Crown': 50,
    'Rocket': 100,
    'Castle': 500,
    'Galaxy': 1000,
  };

  // ==================== STREAM STATES ====================

  static const List<String> streamStatuses = [
    'scheduled',
    'live',
    'ended',
    'cancelled',
    'banned'
  ];

  // ==================== LEADERBOARD ====================

  static const int leaderboardTopN = 10;
  static const int leaderboardUpdateIntervalSeconds = 10; // Update every 10 seconds
  static const int leaderboardResetHours = 24; // Reset daily

  // ==================== NOTIFICATIONS ====================

  static const int streamStartNotificationRadius = 100; // Notify top 100 followers
  static const int streamEndDelaySeconds = 5; // Wait 5 seconds before ending
  static const int goLiveNotificationCooldownHours = 2; // Don't spam notifications

  // ==================== ANALYTICS ====================

  static const int minWatchTimeForViewSeconds = 10; // Count as view after 10 seconds
  static const int minWatchTimeForEngagementSeconds = 60; // Count as engaged after 1 minute
  static const int analyticsAggregationIntervalMinutes = 5; // Aggregate every 5 minutes

  // ==================== EARNINGS ====================

  static const double hostRevenueShare = 0.70; // Host gets 70%
  static const double platformRevenueShare = 0.30; // Platform gets 30%
  static const double minWithdrawalAmount = 100.0; // KES 100
  static const double maxWithdrawalAmount = 500000.0; // KES 500K
  static const int withdrawalProcessingDays = 5; // 5 days to process

  // ==================== CONNECTION ====================

  static const int connectionTimeoutSeconds = 30;
  static const int reconnectionMaxAttempts = 3;
  static const int reconnectionDelaySeconds = 5;
  static const int maxPacketLossPercentage = 30; // Warn if packet loss > 30%
  static const int minBitrateKbps = 100; // Minimum bitrate
  static const int maxBitrateKbps = 3000; // Maximum bitrate

  // ==================== VALIDATION MESSAGES ====================

  static const String invalidTitleMessage = 'Title must be between 5 and 100 characters';
  static const String invalidDescriptionMessage = 'Description must be between 10 and 500 characters';
  static const String insufficientBalanceMessage = 'Insufficient balance to send gift';
  static const String streamNotFoundMessage = 'Live stream not found';
  static const String alreadyLiveMessage = 'You already have an active live stream';
  static const String cooldownActiveMessage = 'Please wait before starting another stream';
  static const String maxStreamsReachedMessage = 'Maximum streams per day reached';
  static const String connectionFailedMessage = 'Failed to connect to stream';
  static const String blockedFromStreamMessage = 'You are blocked from this stream';

  // ==================== SUCCESS MESSAGES ====================

  static const String streamStartedMessage = 'Live stream started successfully';
  static const String streamEndedMessage = 'Live stream ended';
  static const String giftSentMessage = 'Gift sent successfully';
  static const String productPinnedMessage = 'Product pinned';
  static const String flashSaleStartedMessage = 'Flash sale started';
  static const String userBlockedMessage = 'User blocked from stream';

  // ==================== ERROR MESSAGES ====================

  static const String cameraPermissionDeniedMessage = 'Camera permission denied';
  static const String micPermissionDeniedMessage = 'Microphone permission denied';
  static const String agoraInitFailedMessage = 'Failed to initialize streaming service';
  static const String joinStreamFailedMessage = 'Failed to join stream';
  static const String sendGiftFailedMessage = 'Failed to send gift';
  static const String networkErrorMessage = 'Network error. Please check your connection';
  static const String tokenExpiredMessage = 'Session expired. Please rejoin';

  // ==================== WEBSOCKET EVENTS ====================

  static const String eventViewerJoined = 'viewer_joined';
  static const String eventViewerLeft = 'viewer_left';
  static const String eventGiftSent = 'gift_sent';
  static const String eventProductPinned = 'product_pinned';
  static const String eventFlashSaleStarted = 'flash_sale_started';
  static const String eventStreamEnded = 'stream_ended';
  static const String eventChatMessage = 'chat_message';
  static const String eventViewerCountUpdated = 'viewer_count_updated';
  static const String eventLeaderboardUpdated = 'leaderboard_updated';

  // ==================== UI CONSTANTS ====================

  static const double videoAspectRatio = 9 / 16; // Portrait mode
  static const double chatOverlayOpacity = 0.8;
  static const double controlsAutoHideSeconds = 5; // Hide controls after 5 seconds
  static const int maxVisibleComments = 20;
  static const int commentDisplayDurationSeconds = 5;

  // ==================== PERFORMANCE ====================

  static const int maxConcurrentRequests = 10;
  static const int apiTimeoutSeconds = 30;
  static const int cacheExpiryMinutes = 5;
  static const int maxCachedStreams = 100;
}
