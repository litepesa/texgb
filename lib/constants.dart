// lib/constants.dart - Updated with status features and privacy features and cleaned of status reply code
class Constants {
  // ===== SCREEN ROUTES =====
  static const String landingScreen = '/landingScreen';
  static const String videoViewerScreen = '/videoViewerScreen';
  static const String loginScreen = '/loginScreen';
  static const String otpScreen = '/otpScreen';
  static const String userInformationScreen = '/userInformationScreen';
  static const String homeScreen = '/homeScreen';
  static const String chatScreen = '/chatScreen';
  static const String contactProfileScreen = '/contactProfileScreen';
  static const String myProfileScreen = '/myProfileScreen';
  static const String editProfileScreen = '/editProfileScreen';
  static const String searchScreen = '/searchScreen';
  static const String contactsScreen = '/contactsScreen';
  static const String addContactScreen = '/addContactScreen';
  static const String settingsScreen = '/settingsScreen';
  static const String aboutScreen = '/aboutScreen';
  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String privacySettingsScreen = '/privacySettingsScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';
  static const String blockedContactsScreen = '/blockedContactsScreen';
  
  // Status feature routes
  static const String statusScreen = '/statusScreen';
  static const String statusViewerScreen = '/statusViewerScreen';
  static const String createTextStatusScreen = '/createTextStatusScreen';
  static const String createPhotoStatusScreen = '/createPhotoStatusScreen';
  static const String createVideoStatusScreen = '/createVideoStatusScreen';
  static const String statusCameraScreen = '/statusCameraScreen';
  static const String statusPrivacyScreen = '/statusPrivacyScreen';
  static const String statusInfoScreen = '/statusInfoScreen';
  static const String myStatusScreen = '/myStatusScreen';
  static const String statusContactsScreen = '/statusContactsScreen';
  static const String statusReplyScreen = '/statusReplyScreen';
  static const String statusForwardScreen = '/statusForwardScreen';
  static const String statusSettingsScreen = '/statusSettingsScreen';

  // Mini-Series routes
  static const String miniSeriesFeedScreen = '/miniSeriesFeedScreen';
  static const String creatorDashboardScreen = '/creatorDashboardScreen';
  static const String createSeriesScreen = '/createSeriesScreen';
  static const String createEpisodeScreen = '/createEpisodeScreen';
  static const String seriesDetailScreen = '/seriesDetailScreen';
  static const String episodePlayerScreen = '/episodePlayerScreen';
  static const String seriesAnalyticsScreen = '/seriesAnalyticsScreen';
  static const String episodeManagementScreen = '/episodeManagementScreen';

  // Mini-Series collections
  static const String miniSeries = 'mini_series';
  static const String episodes = 'episodes';
  static const String episodeComments = 'episode_comments';
  static const String seriesAnalytics = 'series_analytics';
  static const String seriesFiles = 'series_files';
  
  // Group routes (Private Groups)
  static const String groupsMainScreen = '/groupsMainScreen';
  static const String groupSettingsScreen = '/groupSettingsScreen';
  static const String groupInformationScreen = '/groupInformationScreen';
  static const String groupsScreen = '/groupsScreen';
  static const String createGroupScreen = '/createGroupScreen';
  static const String pendingRequestsScreen = '/pendingRequestsScreen';
  static const String groupChatScreen = '/groupChatScreen';

  // Video feed routes
  static const String videoFeedScreen = '/videoFeedScreen';
  static const String createVideoScreen = '/createVideoScreen';
  static const String videoDetailScreen = '/videoDetailScreen';
  static const String videoCommentsScreen = '/videoCommentsScreen';
  static const String userVideosScreen = '/userVideosScreen';
  static const String recommendedPostsScreen = '/recommendedPostsScreen';

  // Channels routes
  static const String channelsFeedScreen = '/channelsFeedScreen';
  static const String createChannelScreen = '/createChannelScreen';
  static const String channelProfileScreen = '/channelProfileScreen';
  static const String myChannelScreen = '/myChannelScreen';
  static const String editChannelScreen = '/editChannelScreen';
  static const String createChannelPostScreen = '/createChannelPostScreen';
  static const String channelFeedScreen = '/channelFeedScreen';
  static const String channelCommentsScreen = '/channelCommentsScreen';
  static const String exploreChannelsScreen = '/exploreChannelsScreen';
  static const String myPostScreen = '/myPostScreen';
  static const String channelsListScreen = '/channelsListScreen';

  // Public Groups routes
  static const String publicGroupsScreen = '/publicGroupsScreen';
  static const String publicGroupFeedScreen = '/publicGroupFeedScreen';
  static const String createPublicGroupScreen = '/createPublicGroupScreen';
  static const String publicGroupInfoScreen = '/publicGroupInfoScreen';
  static const String editPublicGroupScreen = '/editPublicGroupScreen';
  static const String explorePublicGroupsScreen = '/explorePublicGroupsScreen';
  static const String createPublicGroupPostScreen = '/createPublicGroupPostScreen';
  static const String editPublicGroupPostScreen = '/editPublicGroupPostScreen';
  static const String publicGroupPostCommentsScreen = '/publicGroupPostCommentsScreen';
  static const String publicGroupPostDetailScreen = '/publicGroupPostDetailScreen';
  static const String myPublicGroupsScreen = '/myPublicGroupsScreen';
  
  // Shop feature routes
  static const String shopsListScreen = '/shopsListScreen';
  static const String individualShopScreen = '/individualShopScreen';
  static const String shopProfileScreen = '/shopProfileScreen';
  static const String createShopScreen = '/createShopScreen';
  static const String editShopScreen = '/editShopScreen';
  static const String shopCatalogScreen = '/shopCatalogScreen';
  static const String shopProductScreen = '/shopProductScreen';
  static const String shopOrdersScreen = '/shopOrdersScreen';
  static const String shopAnalyticsScreen = '/shopAnalyticsScreen';
  
  // Wallet routes
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String receiveMoneyScreen = '/receiveMoneyScreen';
  static const String transactionHistoryScreen = '/transactionHistoryScreen';
  
  // Moments feature routes (keeping for backward compatibility)
  static const String momentsFeedScreen = '/momentsFeedScreen';
  static const String createMomentScreen = '/createMomentScreen';
  static const String myMomentsScreen = '/myMomentsScreen';
  static const String momentsRecommendationsScreen = '/momentsRecommendationsScreen';
  static const String momentCommentsScreen = '/momentCommentsScreen';

  
  // Payment screen routes
  static const String paymentScreen = '/paymentScreen';
  static const String paymentSuccessScreen = '/paymentSuccessScreen';

  // ===== COLLECTION NAMES =====
  
  // Core collections
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  
  // Status collections
  static const String statuses = 'statuses';
  static const String statusViews = 'status_views';
  static const String statusLikes = 'status_likes';
  static const String statusReplies = 'status_replies';
  static const String statusPrivacy = 'status_privacy';
  static const String statusViewers = 'status_viewers';
  static const String statusFiles = 'status_files';
  
  // Shop collections
  static const String shops = 'shops';
  static const String shopProducts = 'shop_products';
  static const String shopOrders = 'shop_orders';
  static const String shopReviews = 'shop_reviews';
  static const String shopCategories = 'shop_categories';
  static const String shopAnalytics = 'shop_analytics';
  static const String shopFiles = 'shop_files';
  
  // Payment collections
  static const String payments = 'payments';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';

  // Channel collections
  static const String channels = 'channels';
  static const String channelVideos = 'channelVideos';
  static const String channelComments = 'channelComments';
  static const String channelFiles = 'channelFiles';
  static const String channelLikes = 'channelLikes';
  static const String channelViews = 'channelViews';

  // Public Groups collections
  static const String publicGroups = 'public_groups';
  static const String publicGroupPosts = 'public_group_posts';
  static const String postComments = 'post_comments';
  static const String publicGroupFiles = 'public_group_files';
  static const String publicGroupReactions = 'public_group_reactions';
  static const String publicGroupSubscribers = 'public_group_subscribers';
  
  // Video collections
  static const String videos = 'videos';
  static const String videoComments = 'videoComments';
  static const String videoLikes = 'videoLikes';
  static const String videoFiles = 'videoFiles';

  // Moments collections
  static const String moments = 'moments';
  static const String momentComments = 'moment_comments';
  static const String momentFiles = 'moment_files';
  static const String momentLikes = 'moment_likes';

  // File storage paths
  static const String userImages = 'userImages';
  static const String chatFiles = 'chatFiles';
  static const String groupImages = 'groupImages';
  static const String statusImages = 'statusImages';
  static const String statusVideos = 'statusVideos';
  static const String shopImages = 'shopImages';

  // ===== USER MODEL FIELD NAMES =====
  
  // Basic user fields
  static const String uid = 'uid';
  static const String name = 'name';
  static const String phoneNumber = 'phoneNumber';
  static const String image = 'image';
  static const String token = 'token';
  static const String aboutMe = 'aboutMe';
  static const String lastSeen = 'lastSeen';
  static const String createdAt = 'createdAt';
  static const String isOnline = 'isOnline';
  static const String contactsUIDs = 'contactsUIDs';
  static const String blockedUIDs = 'blockedUIDs';
  static const String followedPublicGroups = 'followedPublicGroups';
  static const String verificationId = 'verificationId';
  static const String userModel = 'userModel';

  // ===== PRIVACY SETTINGS FIELD NAMES =====
  
  static const String privacySettings = 'privacySettings';
  static const String messagePermission = 'messagePermission';
  static const String allowedContactsList = 'allowedContactsList';
  static const String readReceiptVisibility = 'readReceiptVisibility';
  static const String lastSeenVisibility = 'lastSeenVisibility';
  static const String profilePhotoVisibility = 'profilePhotoVisibility';
  static const String allowGroupInvites = 'allowGroupInvites';
  static const String allowChannelInvites = 'allowChannelInvites';
  static const String allowForwarding = 'allowForwarding';
  static const String allowCallsFromContacts = 'allowCallsFromContacts';
  static const String blockedFromCalls = 'blockedFromCalls';
  
  // Status privacy settings
  static const String statusPrivacySettings = 'statusPrivacySettings';
  static const String statusVisibility = 'statusVisibility';
  //static const String statusViewers = 'statusViewers';
  static const String statusExcluded = 'statusExcluded';
  static const String statusOnlyContacts = 'statusOnlyContacts';
  static const String statusCustomList = 'statusCustomList';
  static const String statusReadReceipts = 'statusReadReceipts';

  // Privacy permission levels
  static const String permissionEveryone = 'everyone';
  static const String permissionContactsOnly = 'contactsOnly';
  static const String permissionSelectedContacts = 'selectedContacts';
  static const String permissionNobody = 'nobody';
  static const String permissionExceptContacts = 'exceptContacts';

  // ===== STATUS MODEL FIELD NAMES =====
  
  static const String statusId = 'statusId';
  static const String statusType = 'statusType';
  static const String statusContent = 'statusContent';
  static const String statusMediaUrl = 'statusMediaUrl';
  static const String statusMediaType = 'statusMediaType';
  static const String statusThumbnail = 'statusThumbnail';
  static const String statusBackgroundColor = 'statusBackgroundColor';
  static const String statusTextColor = 'statusTextColor';
  static const String statusFont = 'statusFont';
  static const String statusDuration = 'statusDuration';
  static const String statusCreatedAt = 'statusCreatedAt';
  static const String statusExpiresAt = 'statusExpiresAt';
  static const String statusPrivacyLevel = 'statusPrivacyLevel';
  static const String statusAllowedViewers = 'statusAllowedViewers';
  static const String statusExcludedViewers = 'statusExcludedViewers';
  static const String statusViewsCount = 'statusViewsCount';
  static const String statusLikesCount = 'statusLikesCount';
  static const String statusRepliesCount = 'statusRepliesCount';
  static const String statusForwardsCount = 'statusForwardsCount';
  static const String statusIsActive = 'statusIsActive';
  static const String statusMetadata = 'statusMetadata';
  
  // Status types
  static const String statusTypeText = 'text';
  static const String statusTypeImage = 'image';
  static const String statusTypeVideo = 'video';
  static const String statusTypeAudio = 'audio';
  static const String statusTypeGif = 'gif';
  
  // Status privacy settings
  //static const String statusPrivacySettings = 'statusPrivacySettings';
  static const String defaultStatusPrivacy = 'defaultPrivacy';
  static const String statusAllowedViewersList = 'allowedViewers';
  static const String statusExcludedViewersList = 'excludedViewers';
  static const String statusMutedUsers = 'mutedUsers';

  // ===== SHOP MODEL FIELD NAMES =====
  
  static const String shopId = 'shopId';
  static const String shopName = 'shopName';
  static const String shopDescription = 'shopDescription';
  static const String shopImage = 'shopImage';
  static const String shopCoverImage = 'shopCoverImage';
  static const String shopCategory = 'shopCategory';
  static const String shopOwnerUID = 'shopOwnerUID';
  static const String shopAddress = 'shopAddress';
  static const String shopLocation = 'shopLocation';
  static const String shopContactInfo = 'shopContactInfo';
  static const String shopRating = 'shopRating';
  static const String shopReviewsCount = 'shopReviewsCount';
  static const String shopFollowersCount = 'shopFollowersCount';
  static const String shopProductsCount = 'shopProductsCount';
  static const String shopIsVerified = 'shopIsVerified';
  static const String shopIsActive = 'shopIsActive';
  static const String shopBusinessHours = 'shopBusinessHours';
  static const String shopPaymentMethods = 'shopPaymentMethods';
  static const String shopDeliveryOptions = 'shopDeliveryOptions';
  static const String shopPolicies = 'shopPolicies';
  static const String shopSocialLinks = 'shopSocialLinks';
  static const String shopTags = 'shopTags';

  // ===== MESSAGE MODEL FIELD NAMES =====
  
  static const String messageId = 'messageId';
  static const String senderUID = 'senderUID';
  static const String senderName = 'senderName';
  static const String senderImage = 'senderImage';
  static const String message = 'message';
  static const String messageType = 'messageType';
  static const String timeSent = 'timeSent';
  static const String messageStatus = 'messageStatus';
  static const String repliedMessage = 'repliedMessage';
  static const String repliedTo = 'repliedTo';
  static const String repliedMessageType = 'repliedMessageType';
  static const String deletedBy = 'deletedBy';
  static const String originalMessage = 'originalMessage';
  static const String editedAt = 'editedAt';
  static const String reactions = 'reactions';
  static const String isSeen = 'isSeen';
  static const String isMe = 'isMe';
  static const String isSeenBy = 'isSeenBy';

  // ===== CHAT MODEL FIELD NAMES =====
  
  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String contactUID = 'contactUID';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageSender = 'lastMessageSender';
  static const String unreadCountByUser = 'unreadCountByUser';
  static const String isPinned = 'isPinned';
  static const String pinnedAt = 'pinnedAt';

  // ===== GROUP MODEL FIELD NAMES =====
  
  static const String groupId = 'groupId';
  static const String groupName = 'groupName';
  static const String groupDescription = 'groupDescription';
  static const String groupImage = 'groupImage';
  static const String creatorUID = 'creatorUID';
  static const String isPrivate = 'isPrivate';
  static const String editSettings = 'editSettings';
  static const String approveMembers = 'approveMembers';
  static const String lockMessages = 'lockMessages';
  static const String requestToJoin = 'requestToJoin';
  static const String membersUIDs = 'membersUIDs';
  static const String adminsUIDs = 'adminsUIDs';
  static const String awaitingApprovalUIDs = 'awaitingApprovalUIDs';

  // ===== CHANNEL MODEL FIELD NAMES =====
  
  static const String channelId = 'channelId';
  static const String channelName = 'channelName';
  static const String channelDescription = 'channelDescription';
  static const String channelImage = 'channelImage';
  static const String isVerified = 'isVerified';
  static const String subscribersUIDs = 'subscribersUIDs';
  static const String adminUIDs = 'adminUIDs';
  static const String channelSettings = 'channelSettings';
  static const String lastPostAt = 'lastPostAt';

  // ===== VIDEO MODEL FIELD NAMES =====
  
  static const String videoId = 'videoId';
  static const String userId = 'userId';
  static const String videoUrl = 'videoUrl';
  static const String caption = 'caption';
  static const String songName = 'songName';
  static const String likesCount = 'likesCount';
  static const String commentsCount = 'commentsCount';
  static const String sharesCount = 'sharesCount';
  static const String likedBy = 'likedBy';
  static const String viewCount = 'viewCount';
  static const String duration = 'duration';

  // ===== POST MODEL FIELD NAMES =====
  
  static const String postId = 'postId';
  static const String mediaUrl = 'mediaUrl';
  static const String postViewCount = 'postViewCount';

  // Public Group Post fields
  static const String publicGroupId = 'publicGroupId';
  static const String publicGroupName = 'publicGroupName';
  static const String publicGroupDescription = 'publicGroupDescription';
  static const String publicGroupImage = 'publicGroupImage';
  static const String subscribersCount = 'subscribersCount';
  static const String publicGroupSettings = 'publicGroupSettings';
  static const String publicPostId = 'publicPostId';
  static const String publicGroupPostId = 'publicGroupPostId';
  static const String authorUID = 'authorUID';
  static const String authorName = 'authorName';
  static const String authorImage = 'authorImage';
  static const String content = 'content';
  static const String mediaUrls = 'mediaUrls';
  static const String postType = 'postType';
  static const String reactionsCount = 'reactionsCount';
  static const String metadata = 'metadata';

  // ===== MOMENTS MODEL FIELD NAMES =====
  
  static const String momentId = 'momentId';
  static const String momentContent = 'momentContent';
  static const String momentMediaUrls = 'momentMediaUrls';
  static const String momentMediaType = 'momentMediaType';
  static const String momentPrivacy = 'momentPrivacy';
  static const String momentVisibleTo = 'momentVisibleTo';
  static const String momentCreatedAt = 'momentCreatedAt';
  static const String momentLikesCount = 'momentLikesCount';
  static const String momentCommentsCount = 'momentCommentsCount';


  // ===== COMMENT MODEL FIELD NAMES =====
  
  static const String commentId = 'commentId';
  static const String repliedToCommentId = 'repliedToCommentId';
  static const String repliedToAuthorName = 'repliedToAuthorName';

  // ===== PAYMENT-RELATED CONSTANTS =====
  
  static const String paymentStatus = 'paymentStatus';
  static const String isAccountActivated = 'isAccountActivated';
  static const String paymentTransactionId = 'paymentTransactionId';
  static const String paymentDate = 'paymentDate';
  static const String amountPaid = 'amountPaid';
  static const String walletBalance = 'walletBalance';
  static const String transactionId = 'transactionId';
  static const String transactionType = 'transactionType';
  static const String transactionAmount = 'transactionAmount';
  static const String transactionDate = 'transactionDate';
  static const String recipientUID = 'recipientUID';
  static const String currency = 'KES';
  static const double activationFee = 99.0;

  // ===== STATUS-RELATED CONSTANTS =====
  
  // Status durations (in hours)
  static const int statusDefaultDuration = 24;
  static const int statusMaxDuration = 48;
  static const int statusMinDuration = 1;
  
  // Status interaction limits
  static const int maxStatusViewersToShow = 100;
  static const int maxStatusRepliesPerUser = 10;
  static const int maxStatusLength = 700;
  
  // Status media constants
  static const int maxStatusImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxStatusVideoSize = 20 * 1024 * 1024; // 20MB
  static const Duration maxStatusVideoDuration = Duration(seconds: 30);
  static const Duration maxStatusAudioDuration = Duration(minutes: 1);

  // ===== VALIDATION LIMITS =====
  
  static const int maxMessageLength = 4000;
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const Duration maxVideoDuration = Duration(minutes: 5);
  static const Duration maxAudioDuration = Duration(minutes: 10);
  
  // Shop validation limits
  static const int maxShopNameLength = 50;
  static const int maxShopDescriptionLength = 500;
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 1000;
  static const double maxProductPrice = 1000000.0;

  // ===== ERROR MESSAGES =====
  
  static const String errorUserNotAuthenticated = 'User not authenticated';
  static const String errorChatNotFound = 'Chat not found';
  static const String errorMessageNotFound = 'Message not found';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorPrivacyRestriction = 'Cannot send messages due to privacy settings';
  static const String errorNetworkConnection = 'Network connection error';
  static const String errorFileUpload = 'File upload failed';
  static const String errorFileTooLarge = 'File size too large';
  static const String errorInvalidFileType = 'Invalid file type';
  
  // Status error messages
  static const String errorStatusExpired = 'Status has expired';
  static const String errorStatusNotFound = 'Status not found';
  static const String errorStatusPrivacyRestriction = 'Cannot view status due to privacy settings';
  static const String errorStatusCreationFailed = 'Failed to create status';
  static const String errorStatusUpdateFailed = 'Failed to update status';
  static const String errorStatusDeleteFailed = 'Failed to delete status';
  
  // Shop error messages
  static const String errorShopNotFound = 'Shop not found';
  static const String errorShopCreationFailed = 'Failed to create shop';
  static const String errorShopUpdateFailed = 'Failed to update shop';
  static const String errorProductNotFound = 'Product not found';
  static const String errorOrderFailed = 'Order placement failed';

  // ===== CACHE KEYS =====
  
  static const String cacheKeyUserPrivacy = 'user_privacy_cache';
  static const String cacheKeyContactPermissions = 'contact_permissions_cache';
  static const String cacheKeyBlockedUsers = 'blocked_users_cache';
  static const String cacheKeyStatusPrivacy = 'status_privacy_cache';
  static const String cacheKeyStatusViewers = 'status_viewers_cache';
  static const String cacheKeyShopData = 'shop_data_cache';
  static const String cacheKeyShopProducts = 'shop_products_cache';

  // ===== NOTIFICATION TYPES =====
  
  static const String notificationTypeMessage = 'message';
  static const String notificationTypeGroupInvite = 'group_invite';
  static const String notificationTypeChannelInvite = 'channel_invite';
  static const String notificationTypeCall = 'call';
  static const String notificationTypeReaction = 'reaction';
  static const String notificationTypeStatusReply = 'status_reply';
  static const String notificationTypeStatusMention = 'status_mention';
  static const String notificationTypeShopOrder = 'shop_order';
  static const String notificationTypeShopUpdate = 'shop_update';

  // ===== FEATURE FLAGS =====
  
  static const String featurePrivacyControls = 'privacy_controls';
  static const String featureMessageReactions = 'message_reactions';
  static const String featureMessageEditing = 'message_editing';
  static const String featureCallBlocking = 'call_blocking';
  static const String featureAdvancedPrivacy = 'advanced_privacy';
  static const String featureStatusUpdates = 'status_updates';
  static const String featureStatusReplies = 'status_replies';
  static const String featureStatusForwarding = 'status_forwarding';
  static const String featureShops = 'shops';
  static const String featureShopOrders = 'shop_orders';
  static const String featureShopAnalytics = 'shop_analytics';

  // ===== BACKEND MIGRATION PREPARATION =====
  
  static const String backendTypeFirebase = 'firebase';
  static const String backendTypeElixir = 'elixir';
  static const String currentBackend = backendTypeFirebase;

  // WebSocket events (for future Elixir/Phoenix channels)
  static const String eventMessageSent = 'message_sent';
  static const String eventMessageReceived = 'message_received';
  static const String eventUserTyping = 'user_typing';
  static const String eventUserOnline = 'user_online';
  static const String eventUserOffline = 'user_offline';
  static const String eventStatusCreated = 'status_created';
  static const String eventStatusViewed = 'status_viewed';
  static const String eventStatusReply = 'status_reply';
  static const String eventShopUpdate = 'shop_update';
  static const String eventOrderPlaced = 'order_placed';

  // ===== GENERAL CONSTANTS =====
  
  static const String private = 'private';
  static const String public = 'public';
  
  // Status background colors for text statuses
  static const List<int> statusBackgroundColors = [
    0xFF1976D2, // Blue
    0xFF388E3C, // Green
    0xFFD32F2F, // Red
    0xFFF57C00, // Orange
    0xFF7B1FA2, // Purple
    0xFF303F9F, // Indigo
    0xFF0097A7, // Cyan
    0xFF5D4037, // Brown
    0xFF455A64, // Blue Grey
    0xFF424242, // Grey
  ];
  
  // Status text fonts
  static const List<String> statusTextFonts = [
    'Roboto',
    'Roboto Bold',
    'Roboto Light',
    'Dancing Script',
    'Pacifico',
    'Lobster',
    'Comfortaa',
    'Quicksand',
  ];
  
  // Shop categories
  /*static const List<String> shopCategories = [
    'Fashion & Style',
    'Electronics',
    'Food & Snacks',
    'Beauty & Care',
    'Sports & Fitness',
    'Home & Living',
    'Books & Media',
    'Automotive',
    'Health & Wellness',
    'Arts & Crafts',
    'Services',
    'Other',
  ];
  
  // Payment methods for shops
  static const List<String> shopPaymentMethods = [
    'M-Pesa',
    'Cash on Delivery',
    'Bank Transfer',
    'Credit/Debit Card',
    'PayPal',
    'Airtel Money',
    'T-Kash',
  ];
  
  // Delivery options for shops
  static const List<String> shopDeliveryOptions = [
    'Pickup',
    'Local Delivery',
    'Nationwide Shipping',
    'International Shipping',
    'Digital Delivery',
  ];*/
}