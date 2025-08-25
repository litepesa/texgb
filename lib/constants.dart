// lib/constants.dart - Simplified for Micro Dramas App
class Constants {
  // ===== SCREEN ROUTES =====
  
  // Authentication routes
  static const String landingScreen = '/landingScreen';
  static const String loginScreen = '/loginScreen';
  static const String otpScreen = '/otpScreen';
  static const String userInformationScreen = '/userInformationScreen';
  
  // Main app routes
  static const String homeScreen = '/homeScreen';
  static const String discoverScreen = '/discoverScreen';
  static const String searchScreen = '/searchScreen';
  static const String profileScreen = '/profileScreen';
  static const String settingsScreen = '/settingsScreen';
  
  // Drama viewer routes
  static const String dramaDetailsScreen = '/dramaDetailsScreen';
  static const String episodePlayerScreen = '/episodePlayerScreen';
  static const String favoritesScreen = '/favoritesScreen';
  static const String continueWatchingScreen = '/continueWatchingScreen';
  
  // Admin routes (hidden for normal users, shown only when userType == admin)
  static const String adminDashboardScreen = '/adminDashboardScreen';
  static const String createDramaScreen = '/createDramaScreen';
  static const String manageDramasScreen = '/manageDramasScreen';
  static const String editDramaScreen = '/editDramaScreen';
  static const String addEpisodeScreen = '/addEpisodeScreen';
  static const String episodeFeedScreen = '/episode-feed';
  
  // Premium routes
  static const String premiumScreen = '/premiumScreen';
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  
  // User profile routes
  static const String editProfileScreen = '/editProfileScreen';
  static const String myProfileScreen = '/myProfileScreen';
  
  // Support routes
  static const String aboutScreen = '/aboutScreen';
  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';

  // ===== COLLECTION NAMES =====
  
  // Core collections
  static const String users = 'users';
  static const String dramas = 'dramas';
  static const String episodes = 'episodes';
  
  // User interactions
  static const String favorites = 'favorites';
  static const String watchHistory = 'watchHistory';
  static const String watchProgress = 'watchProgress';
  
  // Premium features (wallet and coins system)
  static const String payments = 'payments';
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String dramaUnlocks = 'dramaUnlocks'; // Track drama unlock purchases
  
  // Content management
  static const String featuredDramas = 'featuredDramas';

  // File storage paths
  static const String userImages = 'userImages';
  static const String dramaBanners = 'dramaBanners';
  static const String episodeVideos = 'episodeVideos';
  static const String episodeThumbnails = 'episodeThumbnails';

  // ===== USER MODEL FIELD NAMES =====
  
  // Basic user fields
  static const String uid = 'uid';
  static const String name = 'name';
  static const String email = 'email';
  static const String phoneNumber = 'phoneNumber';
  static const String profileImage = 'profileImage';
  static const String fcmToken = 'fcmToken';
  static const String bio = 'bio';  // Added bio field
  static const String lastSeen = 'lastSeen';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  
  // User type and drama fields
  static const String userType = 'userType';
  static const String favoriteDramas = 'favoriteDramas';
  static const String dramaProgress = 'dramaProgress';
  static const String unlockedDramas = 'unlockedDramas'; // Premium dramas user has unlocked
  
  // Premium fields (wallet system)
  static const String coinsBalance = 'coinsBalance'; // User's coin balance
  static const String preferences = 'preferences';

  // ===== DRAMA MODEL FIELD NAMES =====
  
  static const String dramaId = 'dramaId';
  static const String title = 'title';
  static const String description = 'description';
  static const String bannerImage = 'bannerImage';
  static const String totalEpisodes = 'totalEpisodes';
  static const String isPremium = 'isPremium';
  static const String freeEpisodesCount = 'freeEpisodesCount'; // Admin sets per drama
  static const String viewCount = 'viewCount';
  static const String favoriteCount = 'favoriteCount';
  static const String isFeatured = 'isFeatured';
  static const String publishedAt = 'publishedAt';
  static const String isActive = 'isActive'; // Admin can activate/deactivate
  static const String createdBy = 'createdBy'; // Admin UID who created
  
  // ===== EPISODE MODEL FIELD NAMES =====
  
  static const String episodeId = 'episodeId';
  static const String episodeNumber = 'episodeNumber';
  static const String episodeTitle = 'episodeTitle';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String videoUrl = 'videoUrl';
  static const String videoDuration = 'videoDuration'; // in seconds
  static const String episodeViewCount = 'episodeViewCount';
  static const String releasedAt = 'releasedAt';
  static const String uploadedBy = 'uploadedBy'; // Admin UID who uploaded

  // ===== SHARED CONSTANTS =====
  
  // Authentication
  static const String verificationId = 'verificationId';
  static const String userModel = 'userModel';
  
  // Error messages
  static const String networkError = 'Network connection failed. Please try again.';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String dramaLocked = 'This drama is locked. Pay 99 coins to unlock all episodes.';
  static const String insufficientCoins = 'Not enough coins. Please add more coins to your wallet.';
  static const String adminOnly = 'Admin access required.'; // Won't be shown to users since screens are hidden
  static const String accessDenied = 'Access denied. This feature is not available.'; // Fallback if somehow accessed
  
  // Success messages
  static const String dramaCreated = 'Drama created successfully!';
  static const String episodeAdded = 'Episode added successfully!';
  static const String dramaUnlocked = 'Drama unlocked! You can now watch all episodes.';
  static const String favoriteAdded = 'Added to favorites';
  static const String favoriteRemoved = 'Removed from favorites';

  // ===== DRAMA UNLOCK PRICING =====
  
  static const int dramaUnlockCost = 99; // 99 coins to unlock any premium drama

  // ===== ADMIN FEATURES =====
  
  // Note: Admin screens/features are hidden in UI based on userType
  // Only users with userType == 'admin' (set in backend) will see admin functionality
  static const int maxEpisodesPerUpload = 50; // Max episodes admin can add at once
  static const int maxDramaDescriptionLength = 500;
  static const int maxEpisodeTitleLength = 100;
  static const int maxFreeEpisodes = 10; // Max free episodes admin can set for premium drama
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
}