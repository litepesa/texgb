// lib/constants.dart - Updated with Moments feature
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
  
  // Group routes (Private Groups)
  static const String groupsMainScreen = '/groupsMainScreen'; // New main screen for both private and public
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

  // Public Groups routes (NEW)
  static const String publicGroupsScreen = '/publicGroupsScreen'; // FIXED: Added proper route string
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
  
  // Status feature routes - Updated for WeChat Moments-like implementation (keeping for backward compatibility)
  static const String statusOverviewScreen = '/statusOverviewScreen';
  static const String createStatusScreen = '/createStatusScreen';
  static const String myStatusesScreen = '/myStatusesScreen';
  static const String statusViewerScreen = '/statusViewerScreen';
  static const String mediaViewScreen = '/mediaViewScreen';
  static const String statusDetailScreen = '/statusDetailScreen';
  static const String statusSettingsScreen = '/statusSettingsScreen';
  static const String editStatusScreen = '/editStatusScreen';
  
  // New Moments feature routes - WeChat Moments-like implementation
  static const String momentsFeedScreen = '/momentsFeedScreen';
  static const String createMomentScreen = '/createMomentScreen';
  static const String momentDetailScreen = '/momentDetailScreen';
  static const String mediaViewerScreen = '/mediaViewerScreen';
  static const String myMomentsScreen = '/myMomentsScreen';
  
  // New alias routes for Moments feature - alternative names for the same screens
  static const String momentsDetailScreen = '/momentsDetailScreen'; // Alias for momentDetailScreen
  
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

  // Collection names for Public Groups feature (NEW)
  static const String publicGroups = 'public_groups';
  static const String publicGroupPosts = 'public_group_posts';
  static const String postComments = 'post_comments';
  static const String publicGroupFiles = 'public_group_files';
  static const String publicGroupReactions = 'public_group_reactions';
  static const String publicGroupSubscribers = 'public_group_subscribers';
  
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

  // Collection names for Moments feature (NEW)
  static const String moments = 'moments';
  static const String momentComments = 'moment_comments';
  static const String momentReactions = 'moment_reactions';
  static const String momentFiles = 'moment_files';
  static const String momentLikes = 'moment_likes';

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

  // Public Group model fields (NEW)
  static const String publicGroupId = 'publicGroupId';
  static const String publicGroupName = 'publicGroupName';
  static const String publicGroupDescription = 'publicGroupDescription';
  static const String publicGroupImage = 'publicGroupImage';
  static const String creatorUID = 'creatorUID';
  static const String subscribersCount = 'subscribersCount';
  static const String publicGroupSettings = 'publicGroupSettings';
  
  // Public Group Post model fields (NEW)
  static const String publicPostId = 'publicPostId';
  static const String publicGroupPostId = 'publicGroupPostId';
  static const String authorUID = 'authorUID';
  static const String authorName = 'authorName';
  static const String authorImage = 'authorImage';
  static const String content = 'content';
  static const String mediaUrls = 'mediaUrls';
  static const String postType = 'postType';
  static const String reactions = 'reactions';
  static const String reactionsCount = 'reactionsCount';
  static const String metadata = 'metadata';

  // Moments model fields (NEW)
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
  
  // Comment model fields (NEW)
  static const String commentId = 'commentId';
  static const String repliedToCommentId = 'repliedToCommentId';
  static const String repliedToAuthorName = 'repliedToAuthorName';
  
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
  static const String followedPublicGroups = 'followedPublicGroups'; // NEW field for public groups

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
  static const String isSeenBy = 'isSeenBy';
  static const String deletedBy = 'deletedBy';

  static const String lastMessage = 'lastMessage';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String groups = 'groups';
  static const String chatFiles = 'chatFiles';

  static const String private = 'private';
  static const String public = 'public';

  // Group-related constants (Private Groups)
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
}