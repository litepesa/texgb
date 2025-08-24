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
}