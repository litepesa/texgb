// lib/core/router/route_paths.dart
/// Centralized route path definitions for type-safe navigation
/// 
/// Usage:
/// - context.go(RoutePaths.home)
/// - context.push(RoutePaths.userProfile(userId))
class RoutePaths {
  // Private constructor to prevent instantiation
  RoutePaths._();
  
  // ==================== ROOT & AUTH ROUTES ====================
  static const String root = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String createProfile = '/create-profile';
  
  // ==================== MAIN APP ROUTES ====================
  static const String home = '/home';
  static const String discover = '/discover';
  static const String explore = '/explore';
  
  // ==================== USER PROFILE ROUTES ====================
  static const String myProfile = '/my-profile';
  static const String editProfile = '/edit-profile';
  static const String usersList = '/users-list';
  static const String liveUsers = '/live-users';
  
  // Dynamic route with parameter
  static String userProfile(String userId) => '/user/$userId';
  static const String userProfilePattern = '/user/:userId';
  
  // ==================== VIDEO ROUTES ====================
  static const String videosFeed = '/videos-feed';
  static const String createPost = '/create-post';
  static const String recommendedPosts = '/recommended-posts';
  static const String managePosts = '/manage-posts';
  static const String featuredVideos = '/featured-videos';
  
  // Dynamic video routes
  static String singleVideo(String videoId) => '/video/$videoId';
  static const String singleVideoPattern = '/video/:videoId';
  
  static String myPost(String videoId) => '/my-post/$videoId';
  static const String myPostPattern = '/my-post/:videoId';
  
  static String postDetail(String videoId) => '/post-detail/$videoId';
  static const String postDetailPattern = '/post-detail/:videoId';

  // ==================== MARKETPLACE ROUTES ====================
  static const String marketplaceFeed = '/marketplace-feed';
  static const String createMarketplaceListing = '/create-marketplace-listing';
  static const String recommendedMarketplaceListings = '/recommended-marketplace-listings';
  static const String featuredMarketplace = '/featured-marketplace';
  static const String manageMarketplaceListings = '/manage-marketplace-listings';

  // Dynamic marketplace routes
  static String singleMarketplaceVideo(String itemId) => '/marketplace-video/$itemId';
  static const String singleMarketplaceVideoPattern = '/marketplace-video/:itemId';

  static String myListing(String itemId) => '/my-marketplace-listing/$itemId';
  static const String myListingPattern = '/my-marketplace-listing/:itemId';

  static String listingDetail(String itemId) => '/marketplace-listing-detail/$itemId';
  static const String listingDetailPattern = '/marketplace-listing-detail/:itemId';

  // ==================== CONTACTS ROUTES ====================
  static const String contacts = '/contacts';
  static const String addContact = '/add-contact';
  static const String blockedContacts = '/blocked-contacts';
  
  static String contactProfile(String userId) => '/contact/$userId';
  static const String contactProfilePattern = '/contact/:userId';
  
  // ==================== CHAT ROUTES ====================
  static const String chats = '/chats';
  static const String chatList = '/chat-list';

  // Dynamic chat routes
  static String chat(String chatId) => '/chat/$chatId';
  static const String chatPattern = '/chat/:chatId';

  static String chatWithUser(String userId) => '/chat/user/$userId';
  static const String chatWithUserPattern = '/chat/user/:userId';

  // ==================== GROUPS ROUTES ====================
  static const String groupsList = '/groups';
  static const String createGroup = '/create-group';

  // Dynamic group routes
  static String groupChat(String groupId) => '/group/$groupId';
  static const String groupChatPattern = '/group/:groupId';

  static String groupSettings(String groupId) => '/group/$groupId/settings';
  static const String groupSettingsPattern = '/group/:groupId/settings';

  static String groupMembers(String groupId) => '/group/$groupId/members';
  static const String groupMembersPattern = '/group/:groupId/members';

  // ==================== CALL ROUTES ====================
  static const String incomingCall = '/incoming-call';
  static const String outgoingCall = '/outgoing-call';
  static const String activeCall = '/active-call';

  // Dynamic call routes
  static String call(String callId) => '/call/$callId';
  static const String callPattern = '/call/:callId';

  // ==================== WALLET ROUTES ====================
  static const String wallet = '/wallet';
  static const String gifts = '/gifts';
  static const String coins = '/coins';
  static const String withdraw = '/withdraw';
  static const String earnings = '/earnings';

  // ==================== CHANNELS ROUTES ====================
  static const String channelsHome = '/channels';
  static const String channelsFeed = '/channels-feed';
  static const String discoverChannels = '/discover-channels';
  static const String createChannel = '/create-channel';
  static const String editChannel = '/edit-channel';
  static const String myChannel = '/my-channel';

  // Dynamic channel routes
  static String channelDetail(String channelId) => '/channel/$channelId';
  static const String channelDetailPattern = '/channel/:channelId';

  static String channelProfile(String channelId) => '/channel/$channelId';
  static const String channelProfilePattern = '/channel/:channelId';

  static String createChannelPost(String channelId) => '/channel/$channelId/create-post';
  static const String createChannelPostPattern = '/channel/:channelId/create-post';

  static String channelPost(String postId) => '/channel-post/$postId';
  static const String channelPostPattern = '/channel-post/:postId';

  static String channelVideo(String videoId) => '/channel-video/$videoId';
  static const String channelVideoPattern = '/channel-video/:videoId';

  // ==================== MOMENTS ROUTES ====================
  static const String momentsFeed = '/moments-feed';
  static const String createMoment = '/create-moment';

  // Dynamic moments routes
  static String userMoments(String userId) => '/moments/user/$userId';
  static const String userMomentsPattern = '/moments/user/:userId';

  static String momentDetail(String momentId) => '/moment/$momentId';
  static const String momentDetailPattern = '/moment/:momentId';

  static String momentMediaViewer(String momentId, int index) => '/moment/$momentId/media/$index';
  static const String momentMediaViewerPattern = '/moment/:momentId/media/:index';

  static String momentVideoViewer(String momentId) => '/moment/$momentId/video';
  static const String momentVideoViewerPattern = '/moment/:momentId/video';

  // ==================== STATUS ROUTES ====================
  static const String statusFeed = '/status-feed';
  static const String createStatus = '/create-status';
  static const String statusViewer = '/status-viewer';

  // Dynamic status routes
  static String userStatus(String userId) => '/status/user/$userId';
  static const String userStatusPattern = '/status/user/:userId';

  // ==================== SEARCH ROUTES ====================
  static const String search = '/search';
  static const String videoSearch = '/video-search';
  static const String advancedSearch = '/advanced-search';
  static const String searchResults = '/search-results';
  static const String searchHistory = '/search-history';
  
  // ==================== SOCIAL ROUTES ====================
  static const String comments = '/comments';
  static const String likes = '/likes';
  static const String shares = '/shares';
  static const String mentions = '/mentions';
  
  static String hashtag(String tag) => '/hashtag/$tag';
  static const String hashtagPattern = '/hashtag/:tag';
  
  // ==================== SETTINGS ROUTES ====================
  static const String privacyPolicy = '/privacy-policy';
  static const String privacySettings = '/privacy-settings';
  static const String termsAndConditions = '/terms-and-conditions';
  
  // ==================== HELPER METHODS ====================
  
  /// Check if a path is an auth route
  static bool isAuthRoute(String path) {
    return path == landing || path == login || path == otp || path == createProfile;
  }
  
  /// Check if a path requires authentication
  static bool requiresAuth(String path) {
    return !isAuthRoute(path) && path != root;
  }
  
  /// Get route name from path (for analytics)
  static String getRouteName(String path) {
    if (path == root || path == home) return 'home';
    if (path == landing) return 'landing';
    if (path == login) return 'login';
    if (path == otp) return 'otp';
    if (path == createProfile) return 'create_profile';
    if (path == discover) return 'discover';
    if (path == explore) return 'explore';
    if (path == myProfile) return 'my_profile';
    if (path == editProfile) return 'edit_profile';
    if (path == videosFeed) return 'videos_feed';
    if (path == createPost) return 'create_post';
    if (path == wallet) return 'wallet';
    if (path == contacts) return 'contacts';
    if (path == search) return 'search';
    if (path == channelsFeed) return 'channels_feed';
    if (path == createChannel) return 'create_channel';
    if (path == momentsFeed) return 'moments_feed';
    if (path == createMoment) return 'create_moment';
    if (path == statusFeed) return 'status_feed';
    if (path == createStatus) return 'create_status';
    if (path == statusViewer) return 'status_viewer';
    if (path == chats) return 'chats';
    if (path == chatList) return 'chat_list';
    if (path == incomingCall) return 'incoming_call';
    if (path == outgoingCall) return 'outgoing_call';
    if (path == activeCall) return 'active_call';

    // Pattern matching for dynamic routes
    if (path.startsWith('/user/')) return 'user_profile';
    if (path.startsWith('/video/')) return 'single_video';
    if (path.startsWith('/post-detail/')) return 'post_detail';
    if (path.startsWith('/my-post/')) return 'my_post';
    if (path.startsWith('/contact/')) return 'contact_profile';
    if (path.startsWith('/hashtag/')) return 'hashtag';
    if (path.startsWith('/channel/')) return 'channel_profile';
    if (path.startsWith('/channel-video/')) return 'channel_video';
    if (path.startsWith('/moments/user/')) return 'user_moments';
    if (path.startsWith('/moment/')) return 'moment_detail';
    if (path.startsWith('/status/user/')) return 'user_status';
    if (path.startsWith('/chat/')) return 'chat';
    if (path.startsWith('/call/')) return 'call';

    return 'unknown';
  }
  
  /// Extract parameter from path
  static String? extractParam(String path, String pattern) {
    final pathSegments = path.split('/');
    final patternSegments = pattern.split('/');
    
    for (var i = 0; i < patternSegments.length; i++) {
      if (patternSegments[i].startsWith(':')) {
        if (i < pathSegments.length) {
          return pathSegments[i];
        }
      }
    }
    return null;
  }
}

// ==================== ROUTE NAMES (for backward compatibility) ====================
/// Use these if you need to reference routes by name
class RouteNames {
  RouteNames._();
  
  static const String root = 'root';
  static const String landing = 'landing';
  static const String login = 'login';
  static const String otp = 'otp';
  static const String createProfile = 'createProfile';
  static const String home = 'home';
  static const String discover = 'discover';
  static const String explore = 'explore';
  static const String myProfile = 'myProfile';
  static const String editProfile = 'editProfile';
  static const String userProfile = 'userProfile';
  static const String usersList = 'usersList';
  static const String liveUsers = 'liveUsers';
  static const String videosFeed = 'videosFeed';
  static const String singleVideo = 'singleVideo';
  static const String createPost = 'createPost';
  static const String myPost = 'myPost';
  static const String postDetail = 'postDetail';
  static const String recommendedPosts = 'recommendedPosts';
  static const String managePosts = 'managePosts';
  static const String featuredVideos = 'featuredVideos';
  static const String marketplaceFeed = 'marketplaceFeed';
  static const String singleMarketplaceVideo = 'singleMarketplaceVideo';
  static const String myListing = 'myListing';
  static const String createMarketplaceListing = 'createMarketplaceListing';
  static const String recommendedMarketplaceListings = 'recommendedMarketplaceListings';
  static const String manageMarketplaceListings = 'manageMarketplaceListings';
  static const String featuredMarketplace = 'featuredMarketplace';
  static const String contacts = 'contacts';
  static const String addContact = 'addContact';
  static const String blockedContacts = 'blockedContacts';
  static const String contactProfile = 'contactProfile';
  static const String wallet = 'wallet';
  static const String search = 'search';
  static const String channelsHome = 'channelsHome';
  static const String channelsFeed = 'channelsFeed';
  static const String channelDetail = 'channelDetail';
  static const String channelProfile = 'channelProfile';
  static const String channelPost = 'channelPost';
  static const String channelVideo = 'channelVideo';
  static const String createChannel = 'createChannel';
  static const String createChannelPost = 'createChannelPost';
  static const String editChannel = 'editChannel';
  static const String myChannel = 'myChannel';
  static const String discoverChannels = 'discoverChannels';
  static const String momentsFeed = 'momentsFeed';
  static const String createMoment = 'createMoment';
  static const String userMoments = 'userMoments';
  static const String momentDetail = 'momentDetail';
  static const String momentMediaViewer = 'momentMediaViewer';
  static const String momentVideoViewer = 'momentVideoViewer';
  static const String statusFeed = 'statusFeed';
  static const String createStatus = 'createStatus';
  static const String statusViewer = 'statusViewer';
  static const String userStatus = 'userStatus';
  static const String chats = 'chats';
  static const String chatList = 'chatList';
  static const String chat = 'chat';
  static const String chatWithUser = 'chatWithUser';
  static const String groupsList = 'groupsList';
  static const String createGroup = 'createGroup';
  static const String groupChat = 'groupChat';
  static const String groupSettings = 'groupSettings';
  static const String groupMembers = 'groupMembers';
  static const String incomingCall = 'incomingCall';
  static const String outgoingCall = 'outgoingCall';
  static const String activeCall = 'activeCall';
  static const String call = 'call';
  static const String gifts = 'gifts';
}