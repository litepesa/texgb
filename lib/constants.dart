// lib/constants.dart - Updated for Coins-based Micro Dramas App
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
  static const String coinPackagesScreen = '/coinPackagesScreen';
  
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
  
  // Coins & Wallet system (updated for coins)
  static const String wallets = 'wallets';
  static const String walletTransactions = 'wallet_transactions';
  static const String coinPurchases = 'coin_purchases'; // Track coin package purchases
  static const String dramaUnlocks = 'drama_unlocks'; // Track drama unlock purchases
  static const String episodeUnlocks = 'episode_unlocks'; // Track individual episode unlocks
  
  // Payment tracking (M-Pesa)
  static const String payments = 'payments';
  static const String paymentVerifications = 'payment_verifications'; // For admin to verify M-Pesa payments
  
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
  static const String bio = 'bio';
  static const String lastSeen = 'lastSeen';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  
  // User type and drama fields
  static const String userType = 'userType';
  static const String favoriteDramas = 'favoriteDramas';
  static const String dramaProgress = 'dramaProgress';
  static const String unlockedDramas = 'unlockedDramas'; // Premium dramas user has unlocked
  static const String unlockedEpisodes = 'unlockedEpisodes'; // Individual premium episodes unlocked
  
  // Coins system fields
  static const String coinsBalance = 'coinsBalance'; // User's coin balance
  static const String preferences = 'preferences';

  // ===== WALLET MODEL FIELD NAMES =====
  
  // Wallet fields (updated for coins)
  static const String walletId = 'walletId';
  static const String userId = 'userId';
  static const String userPhoneNumber = 'userPhoneNumber';
  static const String userName = 'userName';
  static const String lastUpdated = 'lastUpdated';
  
  // Transaction fields
  static const String transactionId = 'transactionId';
  static const String transactionType = 'type'; // coin_purchase, episode_unlock, admin_credit
  static const String coinAmount = 'coinAmount';
  static const String balanceBefore = 'balanceBefore';
  static const String balanceAfter = 'balanceAfter';
  static const String referenceId = 'referenceId';
  static const String adminNote = 'adminNote';
  static const String paymentMethod = 'paymentMethod';
  static const String paymentReference = 'paymentReference';
  static const String packageId = 'packageId';
  static const String paidAmount = 'paidAmount';
  static const String metadata = 'metadata';

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
  
  // Error messages (updated for coins system)
  static const String networkError = 'Network connection failed. Please try again.';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String dramaLocked = 'This drama is locked. Pay coins to unlock all premium episodes.';
  static const String episodeLocked = 'This episode is locked. Pay coins to unlock and watch.';
  static const String insufficientCoins = 'Not enough coins. Please buy more coins to continue.';
  static const String paymentFailed = 'Payment failed. Please try again or contact support.';
  static const String adminOnly = 'Admin access required.'; // Won't be shown to users since screens are hidden
  static const String accessDenied = 'Access denied. This feature is not available.'; // Fallback if somehow accessed
  
  // Success messages (updated for coins system)
  static const String dramaCreated = 'Drama created successfully!';
  static const String episodeAdded = 'Episode added successfully!';
  static const String dramaUnlocked = 'Drama unlocked! You can now watch all premium episodes.';
  static const String episodeUnlocked = 'Episode unlocked successfully! Enjoy watching.';
  static const String favoriteAdded = 'Added to favorites';
  static const String favoriteRemoved = 'Removed from favorites';
  static const String coinsPurchased = 'Coins added to your wallet successfully!';
  static const String paymentPending = 'Payment received. Coins will be added within 30 minutes.';

  // ===== COINS SYSTEM PRICING =====
  
  // Drama/Episode unlock costs (in coins)
  static const int dramaUnlockCost = 50; // 50 coins to unlock entire premium drama
  static const int episodeUnlockCost = 5; // 5 coins to unlock single premium episode
  
  // Coin package definitions (coins : KES price)
  static const Map<int, double> coinPackages = {
    99: 100.0,   // Starter Pack: 99 coins for KES 100
    495: 500.0,  // Popular Pack: 495 coins for KES 500
    990: 1000.0, // Value Pack: 990 coins for KES 1000
  };
  
  // Individual coin package IDs
  static const String starterPackageId = 'coins_99';
  static const String popularPackageId = 'coins_495';
  static const String valuePackageId = 'coins_990';
  
  // Coin package names
  static const String starterPackageName = 'Starter Pack';
  static const String popularPackageName = 'Popular Pack';
  static const String valuePackageName = 'Value Pack';
  
  // Minimum coins required for various actions
  static const int minCoinsForDrama = dramaUnlockCost;
  static const int minCoinsForEpisode = episodeUnlockCost;
  
  // ===== M-PESA PAYMENT DETAILS =====
  
  static const String mpesaBusinessName = 'Pomasoft Limited';
  static const String mpesaPaybillNumber = '4146499';
  static const int minimumTopupAmount = 100; // KES 100 minimum

  // ===== ADMIN FEATURES =====
  
  // Note: Admin screens/features are hidden in UI based on userType
  // Only users with userType == 'admin' (set in backend) will see admin functionality
  static const int maxEpisodesPerUpload = 50; // Max episodes admin can add at once
  static const int maxDramaDescriptionLength = 500;
  static const int maxEpisodeTitleLength = 100;
  static const int maxFreeEpisodes = 10; // Max free episodes admin can set for premium drama
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Admin coin management
  static const int maxCoinsPerTransaction = 10000; // Max coins admin can add in single transaction
  static const int minCoinsPerTransaction = 1; // Min coins admin can add
  
  // ===== TRANSACTION TYPES =====
  
  static const String coinPurchaseTransaction = 'coin_purchase';
  static const String episodeUnlockTransaction = 'episode_unlock';
  static const String dramaUnlockTransaction = 'drama_unlock';
  static const String adminCreditTransaction = 'admin_credit';
  static const String refundTransaction = 'refund';
  
  // ===== PAYMENT METHODS =====
  
  static const String mpesaPayment = 'mpesa';
  static const String adminCreditPayment = 'admin_credit';
  static const String refundPayment = 'refund';
  
  // ===== UI DISPLAY CONSTANTS =====
  
  // Currency symbols
  static const String coinSymbol = '🪙';
  static const String kesSymbol = 'KES';
  
  // Loading states
  static const String loadingDramas = 'Loading dramas...';
  static const String loadingEpisodes = 'Loading episodes...';
  static const String loadingWallet = 'Loading wallet...';
  static const String processingPayment = 'Processing payment...';
  static const String unlockingContent = 'Unlocking content...';
  
  // Empty states
  static const String noDramasFound = 'No dramas found';
  static const String noEpisodesFound = 'No episodes available';
  static const String noTransactionsFound = 'No transactions yet';
  static const String noFavoritesFound = 'No favorites yet. Start exploring!';
  
  // ===== PREMIUM FEATURE LIMITS =====
  
  // Free tier limitations
  static const int maxFavoritesForFreeUsers = 100; // Unlimited for now
  static const int maxWatchHistoryItems = 1000; // Keep last 1000 watched episodes
  
  // Premium benefits
  static const String premiumBenefit1 = 'Unlock any premium drama episodes';
  static const String premiumBenefit2 = 'Ad-free viewing experience';
  static const String premiumBenefit3 = 'Early access to new releases';
  static const String premiumBenefit4 = 'Offline download capability';
  
  // ===== NOTIFICATION MESSAGES =====
  
  static const String newEpisodeNotification = 'New episode available for';
  static const String favoriteUpdatedNotification = 'Your favorite drama has been updated!';
  static const String lowCoinsNotification = 'Your coin balance is running low. Top up now!';
  static const String paymentSuccessNotification = 'Payment successful! Coins have been added to your wallet.';
  
  // ===== REGEX PATTERNS =====
  
  static const String phoneNumberPattern = r'^(?:\+254|254|0)([17]\d{8})$'; // Kenyan phone numbers
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // ===== API TIMEOUTS =====
  
  static const int networkTimeoutSeconds = 30;
  static const int paymentTimeoutSeconds = 60;
  static const int videoLoadTimeoutSeconds = 45;
}