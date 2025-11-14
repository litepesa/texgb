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

  // ==================== WALLET ROUTES ====================
  static const String wallet = '/wallet';
  static const String gifts = '/gifts';
  static const String coins = '/coins';
  static const String withdraw = '/withdraw';
  static const String earnings = '/earnings';

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
    if (path == chats) return 'chats';
    if (path == chatList) return 'chat_list';

    // Pattern matching for dynamic routes
    if (path.startsWith('/user/')) return 'user_profile';
    if (path.startsWith('/video/')) return 'single_video';
    if (path.startsWith('/post-detail/')) return 'post_detail';
    if (path.startsWith('/my-post/')) return 'my_post';
    if (path.startsWith('/contact/')) return 'contact_profile';
    if (path.startsWith('/hashtag/')) return 'hashtag';
    if (path.startsWith('/chat/')) return 'chat';

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
  static const String contacts = 'contacts';
  static const String addContact = 'addContact';
  static const String blockedContacts = 'blockedContacts';
  static const String contactProfile = 'contactProfile';
  static const String wallet = 'wallet';
  static const String search = 'search';
  static const String chats = 'chats';
  static const String chatList = 'chatList';
  static const String chat = 'chat';
  static const String chatWithUser = 'chatWithUser';
  static const String gifts = 'gifts';
}