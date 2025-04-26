// lib/constants.dart

class Constants {
  // screens routes
  static const String landingScreen = '/landingScreen';
  static const String loginScreen = '/loginScreen';
  static const String otpScreen = '/otpScreen';
  static const String userInformationScreen = '/userInformationScreen';
  static const String homeScreen = '/homeScreen';
  static const String chatScreen = '/chatScreen';
  static const String profileScreen = '/profileScreen';
  static const String editProfileScreen = '/editProfileScreen';
  static const String searchScreen = '/searchScreen';
  static const String contactsScreen = '/contactsScreen';
  static const String addContactScreen = '/addContactScreen';
  static const String settingsScreen = '/settingsScreen';
  static const String aboutScreen = '/aboutScreen';
  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';
  static const String groupSettingsScreen = '/groupSettingsScreen';
  static const String groupInformationScreen = '/groupInformationScreen';
  static const String groupsScreen = '/groupsScreen';
  static const String createGroupScreen = '/createGroupScreen';
  static const String blockedContactsScreen = '/blockedContactsScreen';
  
  // Status feature routes
  static const String statusScreen = '/statusScreen';
  static const String createStatusScreen = '/createStatusScreen';
  static const String statusDetailScreen = '/statusDetailScreen';
  static const String myStatusScreen = '/myStatusScreen';
  static const String mediaViewScreen = '/mediaViewScreen';
  static const String statusCommentsScreen = '/statusCommentsScreen';
  
  // Channel feature routes
  static const String channelsScreen = '/channelsScreen';
  static const String createChannelScreen = '/createChannelScreen';
  static const String channelDetailScreen = '/channelDetailScreen';
  static const String createChannelPostScreen = '/createChannelPostScreen';
  static const String channelSettingsScreen = '/channelSettingsScreen';
  static const String exploreChannelsScreen = '/exploreChannelsScreen';
  static const String myChannelsScreen = '/myChannelsScreen';
  
  // Collection names for Status
  static const String statuses = 'statuses';
  static const String statusFiles = 'statusFiles';
  static const String statusId = 'statusId';
  static const String statusUrl = 'statusUrl';
  static const String statusType = 'statusType';
  static const String statusReplies = 'statusReplies';
  static const String statusViewCount = 'statusViewCount';   
  static const String statusLikes = 'statusLikes';
  
  // Collection names for Channels
  static const String channels = 'channels';
  static const String channelPosts = 'channelPosts';
  static const String channelFiles = 'channelFiles';
  static const String subscribedChannels = 'subscribedChannels';
  
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

  static const String verificationId = 'verificationId';

  static const String users = 'users';
  static const String userImages = 'userImages';
  static const String userModel = 'userModel';
  
  static const String contactName = 'contactName';
  static const String contactImage = 'contactImage';
  static const String groupId = 'groupId';

  static const String senderUID = 'senderUID';
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
}