// lib/constants.dart - Updated with Series feature constants
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

  // UPDATED: Series routes (repurposed from channels)
  static const String seriesFeedScreen = '/seriesFeedScreen';                    // Main feed of featured episodes
  static const String createSeriesScreen = '/createSeriesScreen';               // Create new series
  static const String seriesDetailsScreen = '/seriesDetailsScreen';             // Series profile/details
  static const String mySeriesScreen = '/mySeriesScreen';                       // Creator's series management
  static const String editSeriesScreen = '/editSeriesScreen';                   // Edit series info
  static const String addEpisodeScreen = '/addEpisodeScreen';                   // Add episode to series
  static const String seriesEpisodesScreen = '/seriesEpisodesScreen';           // Episode player screen
  static const String episodeCommentsScreen = '/episodeCommentsScreen';         // Episode comments
  static const String exploreSeriesScreen = '/exploreSeriesScreen';             // Browse all series
  static const String myEpisodesScreen = '/myEpisodesScreen';                   // Creator's episode management
  static const String seriesListScreen = '/seriesListScreen';                   // List view of series
  static const String featuredEpisodesScreen = '/featuredEpisodesScreen';       // Featured episodes feed

  // Legacy channel routes (for backward compatibility during migration)
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
  static const String recommendedPostsScreen = '/recommendedPostsScreen';

  // Moments feature routes (keeping for backward compatibility)
  static const String momentsFeedScreen = '/momentsFeedScreen';
  static const String createMomentScreen = '/createMomentScreen';
  static const String myMomentsScreen = '/myMomentsScreen';
  static const String momentsRecommendationsScreen = '/momentsRecommendationsScreen';
  static const String momentCommentsScreen = '/momentCommentsScreen';

  // Wallet routes
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String receiveMoneyScreen = '/receiveMoneyScreen';
  static const String transactionHistoryScreen = '/transactionHistoryScreen';
  

  // ===== COLLECTION NAMES =====
  
  // Core collections
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  
  // Payment collections
  static const String payments = 'payments';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';

  // UPDATED: Series collections (repurposed from channels)
  static const String series = 'series';                        // Main series collection
  static const String seriesEpisodes = 'seriesEpisodes';        // Episodes collection
  static const String episodeComments = 'episodeComments';      // Episode comments
  static const String seriesPurchases = 'seriesPurchases';      // User purchases of series
  static const String seriesFiles = 'seriesFiles';              // File storage references
  static const String seriesLikes = 'seriesLikes';              // Series likes
  static const String episodeLikes = 'episodeLikes';            // Episode likes
  static const String seriesViews = 'seriesViews';              // Series views
  static const String episodeViews = 'episodeViews';            // Episode views
  static const String reports = 'reports';                      // Content reports

  // Legacy channel collections (for backward compatibility)
  static const String channels = 'channels';
  static const String channelVideos = 'channelVideos';
  static const String channelComments = 'channelComments';
  static const String channelFiles = 'channelFiles';
  static const String channelLikes = 'channelLikes';
  static const String channelViews = 'channelViews';

  // Moments collections
  static const String moments = 'moments';
  static const String momentComments = 'moment_comments';
  static const String momentFiles = 'moment_files';
  static const String momentLikes = 'moment_likes';

  // File storage paths
  static const String userImages = 'userImages';
  static const String chatFiles = 'chatFiles';
  static const String seriesImages = 'seriesImages';            // Series thumbnails/covers
  static const String episodeFiles = 'episodeFiles';            // Episode videos/images

  // ===== SERIES MODEL FIELD NAMES =====
  
  static const String seriesId = 'seriesId';
  static const String seriesTitle = 'seriesTitle';
  static const String seriesDescription = 'seriesDescription';
  static const String seriesThumbnail = 'seriesThumbnail';
  static const String seriesCover = 'seriesCover';
  static const String creatorId = 'creatorId';
  static const String creatorName = 'creatorName';
  static const String creatorImage = 'creatorImage';
  static const String episodeCount = 'episodeCount';
  static const String totalDurationSeconds = 'totalDurationSeconds';
  static const String subscribers = 'subscribers';
  static const String subscriberUIDs = 'subscriberUIDs';
  static const String isPublished = 'isPublished';              // Key field for backend control
  static const String publishedAt = 'publishedAt';
  static const String freeEpisodeCount = 'freeEpisodeCount';    // First X episodes free
  static const String seriesPrice = 'seriesPrice';             // Price for paid episodes
  static const String hasPaywall = 'hasPaywall';               // Series has paid content
  static const String nextEpisodeNumber = 'nextEpisodeNumber'; // Auto-increment episodes

  // ===== EPISODE MODEL FIELD NAMES =====
  
  static const String episodeId = 'episodeId';
  static const String episodeNumber = 'episodeNumber';          // Sequential: 1, 2, 3...
  static const String episodeTitle = 'episodeTitle';
  static const String episodeDescription = 'episodeDescription';
  static const String videoUrl = 'videoUrl';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String durationSeconds = 'durationSeconds';      // Max 120 seconds
  static const String isFeatured = 'isFeatured';               // Featured in main feed
  static const String episodeShares = 'episodeShares';

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
  static const String verificationId = 'verificationId';
  static const String userModel = 'userModel';

  // Series-related user fields
  static const String ownedSeriesUIDs = 'ownedSeriesUIDs';      // Series created by user
  static const String subscribedSeriesUIDs = 'subscribedSeriesUIDs'; // Series user follows
  static const String purchasedSeriesUIDs = 'purchasedSeriesUIDs';   // Series user bought
  static const String likedEpisodesUIDs = 'likedEpisodesUIDs'; // Episodes user liked

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

  // ===== CHAT MODEL FIELD NAMES =====
  
  static const String chatId = 'chatId';
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageType = 'lastMessageType';
  static const String lastMessageSender = 'lastMessageSender';
  static const String lastMessageTime = 'lastMessageTime';
  static const String unreadCounts = 'unreadCounts';
  static const String isArchived = 'isArchived';
  static const String isPinned = 'isPinned';
  static const String isMuted = 'isMuted';
  static const String chatWallpapers = 'chatWallpapers';
  static const String fontSizes = 'fontSizes';

  // ===== MESSAGE MODEL FIELD NAMES =====
  
  static const String messageId = 'messageId';
  static const String senderId = 'senderId';
  static const String content = 'content';
  static const String type = 'type';
  static const String status = 'status';
  static const String timestamp = 'timestamp';
  static const String mediaUrl = 'mediaUrl';
  static const String mediaMetadata = 'mediaMetadata';
  static const String replyToMessageId = 'replyToMessageId';
  static const String replyToContent = 'replyToContent';
  static const String replyToSender = 'replyToSender';
  static const String reactions = 'reactions';
  static const String isEdited = 'isEdited';
  static const String editedAt = 'editedAt';
  static const String readBy = 'readBy';
  static const String deliveredTo = 'deliveredTo';

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

  // ===== LEGACY CHANNEL MODEL FIELD NAMES (for backward compatibility) =====
  
  static const String channelId = 'channelId';
  static const String channelName = 'channelName';
  static const String channelDescription = 'channelDescription';
  static const String channelImage = 'channelImage';
  static const String isVerified = 'isVerified';
  static const String adminUIDs = 'adminUIDs';
  static const String channelSettings = 'channelSettings';
  static const String lastPostAt = 'lastPostAt';

  // ===== LEGACY VIDEO MODEL FIELD NAMES =====
  
  static const String userId = 'userId';
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
  static const String mediaUrls = 'mediaUrls';
  static const String postViewCount = 'postViewCount';
  static const String authorUID = 'authorUID';
  static const String authorName = 'authorName';
  static const String authorImage = 'authorImage';
  static const String postType = 'postType';
  static const String reactionsCount = 'reactionsCount';
  static const String metadata = 'metadata';

  // ===== COMMENT MODEL FIELD NAMES =====
  
  static const String commentId = 'commentId';
  static const String repliedToCommentId = 'repliedToCommentId';
  static const String repliedToAuthorName = 'repliedToAuthorName';

  // ===== SERIES VALIDATION LIMITS =====
  
  static const int maxEpisodeDurationSeconds = 120;            // 2 minutes max per episode
  static const int maxEpisodesPerSeries = 100;                // 100 episodes max per series
  static const int maxFeaturedEpisodesPerSeries = 5;          // Max 5 featured episodes per series
  static const double minSeriesPrice = 100.0;                 // KES 100 minimum for paid series
  static const int maxSeriesTitle = 100;                      // Max characters for series title
  static const int maxEpisodeTitle = 80;                      // Max characters for episode title
  static const int maxSeriesDescription = 500;                // Max characters for series description
  static const int maxEpisodeDescription = 300;               // Max characters for episode description

  // ===== GENERAL VALIDATION LIMITS =====
  
  static const int maxMessageLength = 4000;
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB (as requested)
  static const int maxImageSize = 50 * 1024 * 1024; // 50MB (no compression as requested)
  static const Duration maxVideoDuration = Duration(minutes: 5);
  static const Duration maxAudioDuration = Duration(minutes: 10);

  // ===== CHAT SPECIFIC LIMITS =====
  
  static const int maxChatMessageLength = 4000;
  static const int maxChatFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxPinnedMessages = 10;
  static const int chatMessagesPageSize = 50;
  static const int maxSearchResults = 100;

  // ===== ERROR MESSAGES =====
  
  static const String errorUserNotAuthenticated = 'User not authenticated';
  static const String errorChatNotFound = 'Chat not found';
  static const String errorMessageNotFound = 'Message not found';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorPrivacyRestriction = 'Cannot send messages due to privacy settings';
  static const String errorNetworkConnection = 'Network connection error';
  static const String errorFileUpload = 'File upload failed';
  static const String errorFileTooLarge = 'File size too large (max 50MB)';
  static const String errorInvalidFileType = 'Invalid file type';
  static const String errorChatCreationFailed = 'Failed to create chat';
  static const String errorMessageSendFailed = 'Failed to send message';
  static const String errorMessageEditFailed = 'Failed to edit message';
  static const String errorMessageDeleteFailed = 'Failed to delete message';
  static const String errorContactBlocked = 'Contact is blocked';
  static const String errorMaxPinnedMessages = 'Maximum pinned messages reached';

  // UPDATED: Series-specific error messages
  static const String errorSeriesNotFound = 'Series not found';
  static const String errorEpisodeNotFound = 'Episode not found';
  static const String errorSeriesNotPublished = 'Series is not published yet';
  static const String errorEpisodeTooLong = 'Episode exceeds 2 minute limit';
  static const String errorMaxEpisodesReached = 'Maximum 100 episodes per series';
  static const String errorMaxFeaturedEpisodesReached = 'Maximum 5 featured episodes per series';
  static const String errorSeriesPriceTooLow = 'Series price must be at least KES 100';
  static const String errorEpisodeLocked = 'This episode requires purchase to access';
  static const String errorSeriesCreationFailed = 'Failed to create series';
  static const String errorEpisodeUploadFailed = 'Failed to upload episode';
  static const String errorSeriesPurchaseFailed = 'Failed to purchase series';

  // ===== SUCCESS MESSAGES =====
  
  static const String messageSent = 'Message sent';
  static const String messageEdited = 'Message edited';
  static const String messageDeleted = 'Message deleted';
  static const String messagePinned = 'Message pinned';
  static const String messageUnpinned = 'Message unpinned';
  static const String chatPinned = 'Chat pinned';
  static const String chatUnpinned = 'Chat unpinned';
  static const String chatArchived = 'Chat archived';
  static const String chatUnarchived = 'Chat unarchived';
  static const String chatMuted = 'Chat muted';
  static const String chatUnmuted = 'Chat unmuted';
  static const String contactBlocked = 'Contact blocked';
  static const String contactUnblocked = 'Contact unblocked';

  // UPDATED: Series-specific success messages
  static const String seriesCreated = 'Series created successfully';
  static const String seriesUpdated = 'Series updated successfully';
  static const String episodeAdded = 'Episode added successfully';
  static const String episodeUpdated = 'Episode updated successfully';
  static const String seriesSubscribed = 'Subscribed to series';
  static const String seriesUnsubscribed = 'Unsubscribed from series';
  static const String seriesPurchased = 'Series purchased successfully';
  static const String episodeLiked = 'Episode liked';
  static const String episodeUnliked = 'Episode unliked';

  // ===== CHAT SETTINGS =====
  
  static const String defaultChatWallpaper = '';
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  
  // ===== NOTIFICATION SETTINGS =====
  
  static const String notificationChannelId = 'chat_messages';
  static const String notificationChannelName = 'Chat Messages';
  static const String notificationChannelDescription = 'Notifications for new chat messages';

  // UPDATED: Series notification settings
  static const String seriesNotificationChannelId = 'series_updates';
  static const String seriesNotificationChannelName = 'Series Updates';
  static const String seriesNotificationDescription = 'Notifications for new episodes and series updates';

  // ===== GENERAL CONSTANTS =====
  
  static const String private = 'private';
  static const String public = 'public';
  static const String online = 'online';
  static const String offline = 'offline';
  static const String typing = 'typing';
  static const String deleted = 'deleted';
  static const String edited = 'edited';
  
  // Series-specific constants
  static const String published = 'published';
  static const String unpublished = 'unpublished';
  static const String free = 'free';
  static const String paid = 'paid';
  static const String featured = 'featured';
  static const String regular = 'regular';

  // ===== SERIES PAYWALL CONSTANTS =====
  
  static const String paywallTypeNone = 'none';               // All episodes free (entire series free)
  static const String paywallTypeBulk = 'bulk';               // First X free, rest paid
  static const int defaultFreeEpisodes = 3;                   // Default: first 3 episodes free
  static const int maxFreeEpisodes = 10;                      // Max episodes that can be free
  static const int maxFeaturedEpisodesLimit = 5;              // Max 5 featured episodes per series
}