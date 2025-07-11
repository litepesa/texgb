// lib/constants.dart - Updated with privacy features and cleaned of status reply code
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

  // Channels routes
  static const String channelsFeedScreen = '/channelsFeedScreen';
  static const String createChannelScreen = '/createChannelScreen';
  static const String channelProfileScreen = '/channelProfileScreen';
  static const String myChannelScreen = '/myChannelScreen';
  static const String editChannelScreen = '/editChannelScreen';
  static const String createChannelPostScreen = '/createChannelPostScreen';
  static const String channelVideoDetailScreen = '/channelVideoDetailScreen';
  static const String channelCommentsScreen = '/channelCommentsScreen';
  static const String exploreChannelsScreen = '/exploreChannelsScreen';
  static const String myPostScreen = '/myPostScreen';

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
  
  // Wallet routes
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String receiveMoneyScreen = '/receiveMoneyScreen';
  static const String transactionHistoryScreen = '/transactionHistoryScreen';
  
  // Moments feature routes (keeping for backward compatibility)
  static const String momentsFeedScreen = '/momentsFeedScreen';
  static const String createMomentScreen = '/createMomentScreen';
  static const String momentDetailScreen = '/momentDetailScreen';
  static const String mediaViewerScreen = '/mediaViewerScreen';
  static const String myMomentsScreen = '/myMomentsScreen';
  static const String momentsDetailScreen = '/momentsDetailScreen';
  
  // Payment screen routes
  static const String paymentScreen = '/paymentScreen';
  static const String paymentSuccessScreen = '/paymentSuccessScreen';

  // ===== COLLECTION NAMES =====
  
  // Core collections
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  
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
  static const String momentReactions = 'moment_reactions';
  static const String momentFiles = 'moment_files';
  static const String momentLikes = 'moment_likes';

  // File storage paths
  static const String userImages = 'userImages';
  static const String chatFiles = 'chatFiles';
  static const String groupImages = 'groupImages';

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

  // Privacy permission levels
  static const String permissionEveryone = 'everyone';
  static const String permissionContactsOnly = 'contactsOnly';
  static const String permissionSelectedContacts = 'selectedContacts';
  static const String permissionNobody = 'nobody';

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
  static const String momentLocation = 'momentLocation';
  static const String momentPrivacy = 'momentPrivacy';
  static const String momentVisibleTo = 'momentVisibleTo';
  static const String momentHiddenFrom = 'momentHiddenFrom';
  static const String momentCreatedAt = 'momentCreatedAt';
  static const String momentLikesCount = 'momentLikesCount';
  static const String momentCommentsCount = 'momentCommentsCount';
  static const String momentLikedBy = 'momentLikedBy';

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

  // ===== VALIDATION LIMITS =====
  
  static const int maxMessageLength = 4000;
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const Duration maxVideoDuration = Duration(minutes: 5);
  static const Duration maxAudioDuration = Duration(minutes: 10);

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

  // ===== CACHE KEYS =====
  
  static const String cacheKeyUserPrivacy = 'user_privacy_cache';
  static const String cacheKeyContactPermissions = 'contact_permissions_cache';
  static const String cacheKeyBlockedUsers = 'blocked_users_cache';

  // ===== NOTIFICATION TYPES =====
  
  static const String notificationTypeMessage = 'message';
  static const String notificationTypeGroupInvite = 'group_invite';
  static const String notificationTypeChannelInvite = 'channel_invite';
  static const String notificationTypeCall = 'call';
  static const String notificationTypeReaction = 'reaction';

  // ===== FEATURE FLAGS =====
  
  static const String featurePrivacyControls = 'privacy_controls';
  static const String featureMessageReactions = 'message_reactions';
  static const String featureMessageEditing = 'message_editing';
  static const String featureCallBlocking = 'call_blocking';
  static const String featureAdvancedPrivacy = 'advanced_privacy';

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

  // ===== GENERAL CONSTANTS =====
  
  static const String private = 'private';
  static const String public = 'public';

  // In your constants.dart file, add:
  static const String shopsListScreen = '/shops-list-screen';
  static const String individualShopScreen = '/individual-shop-screen';
}