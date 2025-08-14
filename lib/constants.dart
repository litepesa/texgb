// lib/constants.dart - Cleaned version with only active features
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
  static const String recommendedPostsScreen = '/recommendedPostsScreen';
  
  // Wallet routes
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String receiveMoneyScreen = '/receiveMoneyScreen';
  static const String transactionHistoryScreen = '/transactionHistoryScreen';
  
  // Payment screen routes
  static const String paymentScreen = '/paymentScreen';
  static const String paymentSuccessScreen = '/paymentSuccessScreen';

  // ===== COLLECTION NAMES =====
  
  // Core collections
  static const String users = 'users';
  static const String chats = 'chats';
  static const String messages = 'messages';
  
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
  static const String reports = 'reports';

  // File storage paths
  static const String userImages = 'userImages';
  static const String chatFiles = 'chatFiles';

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
  static const String authorUID = 'authorUID';
  static const String authorName = 'authorName';
  static const String authorImage = 'authorImage';
  static const String content = 'content';
  static const String mediaUrls = 'mediaUrls';
  static const String postType = 'postType';
  static const String reactionsCount = 'reactionsCount';
  static const String metadata = 'metadata';

  // ===== COMMENT MODEL FIELD NAMES =====
  
  static const String commentId = 'commentId';
  static const String repliedToCommentId = 'repliedToCommentId';
  static const String repliedToAuthorName = 'repliedToAuthorName';


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

  // ===== GENERAL CONSTANTS =====
  
  static const String private = 'private';
  static const String public = 'public';
}