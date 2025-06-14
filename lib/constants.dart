// lib/constants.dart - Updated for Channels feature and Wallet feature
class Constants {
  // screens routes
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
  
  // Group routes (keeping for backward compatibility)
  static const String groupSettingsScreen = '/groupSettingsScreen';
  static const String groupInformationScreen = '/groupInformationScreen';
  static const String groupsScreen = '/groupsScreen';
  static const String createGroupScreen = '/createGroupScreen';
  static const String pendingRequestsScreen = '/pendingRequestsScreen';
  static const String groupChatScreen = '/groupChatScreen';
  
  static const String blockedContactsScreen = '/blockedContactsScreen';

  // Video feed routes
  static const String videoFeedScreen = '/videoFeedScreen';
  static const String createVideoScreen = '/createVideoScreen';
  static const String videoDetailScreen = '/videoDetailScreen';
  static const String videoCommentsScreen = '/videoCommentsScreen';
  static const String userVideosScreen = '/userVideosScreen';

  // Channels routes (replacing Marketplace routes)
  static const String channelsFeedScreen = '/channelsFeedScreen';
  static const String createChannelScreen = '/createChannelScreen';
  static const String channelProfileScreen = '/channelProfileScreen';
  static const String myChannelScreen = '/myChannelScreen';
  static const String editChannelScreen = '/editChannelScreen';
  static const String createChannelPostScreen = '/createChannelPostScreen';
  static const String channelVideoDetailScreen = '/channelVideoDetailScreen';
  static const String channelCommentsScreen = '/channelCommentsScreen';
  static const String exploreChannelsScreen = '/exploreChannelsScreen';
  static const String myPostScreen = '/myPostScreen'; // New route for My Post Screen
  
  // Wallet routes
  static const String walletScreen = '/walletScreen';
  static const String topUpScreen = '/topUpScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String receiveMoneyScreen = '/receiveMoneyScreen';
  static const String transactionHistoryScreen = '/transactionHistoryScreen';
  
  // Status feature routes - Updated for WeChat Moments-like implementation (keeping for backward compatibility)
  static const String statusOverviewScreen = '/statusOverviewScreen';
  static const String createStatusScreen = '/createStatusScreen';
  static const String myStatusesScreen = '/myStatusesScreen';
  static const String statusViewerScreen = '/statusViewerScreen';
  static const String mediaViewScreen = '/mediaViewScreen';
  static const String statusDetailScreen = '/statusDetailScreen';
  static const String statusSettingsScreen = '/statusSettingsScreen';
  static const String editStatusScreen = '/editStatusScreen';
  
  // New alias routes for Moments feature - alternative names for the same screens
  static const String momentsFeedScreen = '/momentsFeedScreen'; // Alias for statusOverviewScreen
  static const String momentsDetailScreen = '/momentsDetailScreen'; // Alias for statusDetailScreen
  static const String createMomentScreen = '/createMomentScreen'; // Alias for createStatusScreen
  
  // Payment screen routes
  static const String paymentScreen = '/paymentScreen';
  static const String paymentSuccessScreen = '/paymentSuccessScreen';

  // Payment collections
  static const String payments = 'payments';
  static const String paymentStatus = 'paymentStatus';

  // Payment constants
  static const double activationFee = 99.0;
  static const String currency = 'KES';

  // Collection names for Channel feature
  static const String channels = 'channels';
  static const String channelVideos = 'channelVideos';
  static const String channelComments = 'channelComments';
  static const String channelFiles = 'channelFiles';
  static const String channelLikes = 'channelLikes';
  static const String channelViews = 'channelViews';
  
  // Collection names for Wallet feature
  static const String wallets = 'wallets';
  static const String transactions = 'transactions';
  static const String walletBalance = 'walletBalance';
  static const String transactionId = 'transactionId';
  static const String transactionType = 'transactionType';
  static const String transactionAmount = 'transactionAmount';
  static const String transactionDate = 'transactionDate';
  static const String recipientUID = 'recipientUID';
  static const String senderUID = 'senderUID';
  
  // Collection names for Status - Updated for new implementation
  static const String statuses = 'statuses'; // Keep for backward compatibility
  static const String statusPosts = 'status_posts'; // New collection for Moments-like posts
  static const String statusComments = 'status_comments';
  static const String statusReactions = 'status_reactions';
  static const String statusFiles = 'statusFiles';
  static const String statusId = 'statusId';
  static const String statusType = 'statusType';
  static const String statusViewCount = 'viewCount';

  // Payment-related constants
  static const String isAccountActivated = 'isAccountActivated';
  static const String paymentTransactionId = 'paymentTransactionId';
  static const String paymentDate = 'paymentDate';
  static const String amountPaid = 'amountPaid';
  
  // New constants for status replies
  static const String statusReplies = 'status_replies';
  static const String statusReplyId = 'replyId';
  static const String statusThumbnail = 'statusThumbnail';
  static const String statusContext = 'statusContext'; // Key for statusContext in message model
  
  // Collection names for Videos
  static const String videos = 'videos';
  static const String videoComments = 'videoComments';
  static const String videoLikes = 'videoLikes';
  static const String videoFiles = 'videoFiles';
  static const String videoId = 'videoId';
  
  // Channel model fields
  static const String channelId = 'channelId';
  static const String channelName = 'channelName';
  static const String channelDescription = 'channelDescription';
  static const String channelImage = 'channelImage';
  static const String isVerified = 'isVerified';
  static const String subscribersUIDs = 'subscribersUIDs';
  static const String adminUIDs = 'adminUIDs';
  static const String channelSettings = 'channelSettings';
  static const String lastPostAt = 'lastPostAt';

  // Video model fields
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
  
  // Channel post model fields
  static const String postId = 'postId';
  static const String mediaUrl = 'mediaUrl';
  static const String postViewCount = 'postViewCount';
  static const String isPinned = 'isPinned';
  
  // User-related constants
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
  static const String statusMutedUsers = 'statusMutedUsers'; // New field for muted users in status

  static const String verificationId = 'verificationId';

  static const String users = 'users';
  static const String userImages = 'userImages';
  static const String userModel = 'userModel';
  
  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String groupId = 'groupId';

  static const String senderName = 'senderName';
  static const String senderImage = 'senderImage';
  static const String contactUID = 'contactUID';
  static const String message = 'message';
  static const String messageType = 'messageType';
  static const String timeSent = 'timeSent';
  static const String messageId = 'messageId';
  static const String isSeen = 'isSeen';
  static const String repliedMessage = 'repliedMessage';
  static const String repliedTo = 'repliedTo';
  static const String repliedMessageType = 'repliedMessageType';
  static const String isMe = 'isMe';
  static const String reactions = 'reactions';
  static const String isSeenBy = 'isSeenBy';
  static const String deletedBy = 'deletedBy';

  static const String lastMessage = 'lastMessage';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  static const String chatFiles = 'chatFiles';

  static const String private = 'private';
  static const String public = 'public';

  // Group-related constants
  static const String creatorUID = 'creatorUID';
  static const String groupName = 'groupName';
  static const String groupDescription = 'groupDescription';
  static const String groupImage = 'groupImage';
  static const String isPrivate = 'isPrivate';
  static const String editSettings = 'editSettings';
  static const String approveMembers = 'approveMembers';
  static const String lockMessages = 'lockMessages';
  static const String requestToJoin = 'requestToJoin'; 
  static const String membersUIDs = 'membersUIDs';
  static const String adminsUIDs = 'adminsUIDs';
  static const String awaitingApprovalUIDs = 'awaitingApprovalUIDs';

  static const String groupImages = 'groupImages';

  static var privacySettings;
}