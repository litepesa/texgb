// lib/constants.dart (Complete TikTok-style)
class Constants {
  // ===================== FIREBASE COLLECTIONS =====================
  static const String users = 'users';                    // was 'channels'
  static const String videos = 'videos';                  // was 'channelVideos'
  static const String comments = 'comments';              // was 'channelComments'
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String likes = 'likes';
  static const String shares = 'shares';
  static const String follows = 'follows';
  static const String analytics = 'analytics';
  static const String hashtags = 'hashtags';
  static const String trending = 'trending';

  // ===================== ROUTE NAMES =====================
  
  // Authentication Routes
  static const String landingScreen = '/landing';
  static const String loginScreen = '/login';
  static const String otpScreen = '/otp';
  
  // Main App Routes
  static const String homeScreen = '/home';
  static const String videosFeedScreen = '/videosFeed';              // was channelsFeedScreen
  static const String singleVideoScreen = '/singleVideo';           // was channelFeedScreen
  
  // User Profile Routes
  static const String createProfileScreen = '/createProfile';       // was createChannelScreen
  static const String myProfileScreen = '/myProfile';               // was myChannelScreen
  static const String userProfileScreen = '/userProfile';           // was channelProfileScreen
  static const String editProfileScreen = '/editProfile';           // was editChannelScreen
  static const String usersListScreen = '/usersList';               // was channelsListScreen
  static const String followingScreen = '/following';
  static const String followersScreen = '/followers';
  
  // Video/Content Routes
  static const String createPostScreen = '/createPost';             // was createChannelPostScreen
  static const String myPostScreen = '/myPost';
  static const String editPostScreen = '/editPost';
  static const String postDetailScreen = '/postDetail';
  static const String cameraScreen = '/camera';
  static const String videoEditorScreen = '/videoEditor';
  static const String videoPreviewScreen = '/videoPreview';
  
  // Discovery Routes
  static const String exploreScreen = '/explore';                   // was exploreChannelsScreen
  static const String searchScreen = '/search';
  static const String hashtagScreen = '/hashtag';
  static const String trendingScreen = '/trending';
  static const String recommendedPostsScreen = '/recommendedPosts';
  
  // Social Features Routes
  static const String commentsScreen = '/comments';
  static const String likesScreen = '/likes';
  static const String sharesScreen = '/shares';
  static const String mentionsScreen = '/mentions';
  
  // Settings & More Routes
  static const String settingsScreen = '/settings';
  static const String privacyScreen = '/privacy';
  static const String securityScreen = '/security';
  static const String notificationsSettingsScreen = '/notificationsSettings';
  static const String blockedUsersScreen = '/blockedUsers';
  static const String reportScreen = '/report';
  static const String aboutScreen = '/about';
  static const String helpScreen = '/help';
  
  // Wallet & Monetization Routes
  static const String walletScreen = '/wallet';
  static const String giftsScreen = '/gifts';
  static const String coinsScreen = '/coins';
  static const String withdrawScreen = '/withdraw';
  static const String earningsScreen = '/earnings';

  // ===================== NAVIGATION ARGUMENTS =====================
  static const String verificationId = 'verificationId';
  static const String phoneNumber = 'phoneNumber';
  static const String startVideoId = 'startVideoId';
  static const String userId = 'userId';                             // was channelId
  static const String videoId = 'videoId';
  static const String commentId = 'commentId';
  static const String hashtag = 'hashtag';
  static const String searchQuery = 'searchQuery';
  static const String userModel = 'userModel';                       // was channelModel
  static const String videoModel = 'videoModel';
  static const String isEditing = 'isEditing';
  static const String fromProfile = 'fromProfile';

  // ===================== SHARED PREFERENCES KEYS =====================
  static const String userModelKey = 'userModel';                    // was 'channelModel'
  static const String likedVideosKey = 'likedVideos';                // was 'likedChannelVideos'
  static const String followedUsersKey = 'followedUsers';            // was 'followedChannels'
  static const String searchHistoryKey = 'searchHistory';
  static const String themeKey = 'theme';
  static const String languageKey = 'language';
  static const String notificationsEnabledKey = 'notificationsEnabled';
  static const String autoPlayKey = 'autoPlay';
  static const String dataUsageKey = 'dataUsage';
  static const String lastAppVersionKey = 'lastAppVersion';
  static const String onboardingCompletedKey = 'onboardingCompleted';
  static const String biometricEnabledKey = 'biometricEnabled';

  // ===================== FIREBASE STORAGE PATHS =====================
  static const String userImagesPath = 'userImages';                 // was 'channelImages'
  static const String videosPath = 'videos';                         // was 'channelVideos'
  static const String thumbnailsPath = 'thumbnails';
  static const String imagesPath = 'images';
  static const String profileImagesPath = 'profileImages';
  static const String coverImagesPath = 'coverImages';
  static const String tempUploadsPath = 'tempUploads';
  static const String giftsPath = 'gifts';
  static const String effectsPath = 'effects';

  // ===================== APP CONFIGURATION =====================
  static const String appName = 'WeiBao';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appPackageName = 'com.weibao.app';
  
  // API Configuration
  static const String baseApiUrl = 'https://api.weibao.app/v1';
  static const String socketUrl = 'wss://api.weibao.app';
  static const String cdnUrl = 'https://cdn.weibao.app';
  
  // Environment
  static const String environment = 'production'; // 'development', 'staging', 'production'

  // ===================== UI CONSTANTS =====================
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 20.0;
  static const double defaultIconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;
  
  // Video Player UI
  static const double videoControlsHeight = 60.0;
  static const double videoProgressBarHeight = 4.0;
  static const double videoSeekBarHeight = 20.0;
  
  // Feed UI
  static const double feedVideoHeight = 400.0;
  static const double feedUserAvatarSize = 40.0;
  static const double feedActionButtonSize = 48.0;

  // ===================== VIDEO CONSTANTS =====================
  static const int maxVideoLength = 180; // 3 minutes (TikTok-style)
  static const int minVideoLength = 3;   // 3 seconds minimum
  static const int maxImageCount = 10;
  static const int videoQuality = 720;   // Default video quality
  static const int videoFrameRate = 30;
  static const String videoFormat = 'mp4';
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Video Processing
  static const int thumbnailWidth = 320;
  static const int thumbnailHeight = 568; // 9:16 aspect ratio
  static const double videoAspectRatio = 9/16; // TikTok aspect ratio

  // ===================== USER PROFILE CONSTANTS =====================
  static const int maxNameLength = 50;
  static const int minNameLength = 2;
  static const int maxAboutLength = 150;
  static const int minAboutLength = 10;
  static const int maxTagsCount = 5;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  
  // Content Limits
  static const int maxCaptionLength = 2200;
  static const int maxCommentLength = 500;
  static const int maxHashtagLength = 30;
  static const int maxHashtagsPerPost = 10;

  // ===================== SOCIAL CONSTANTS =====================
  static const int maxSearchResults = 50;
  static const int maxCommentsPerLoad = 50;
  static const int maxVideosPerLoad = 20;
  static const int maxUsersPerLoad = 20;
  static const int maxNotificationsPerLoad = 30;
  static const int maxFollowingCount = 7500; // TikTok limit
  static const int maxLikesPerVideo = 999999999; // Display limit

  // ===================== AUTHENTICATION CONSTANTS =====================
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 60;
  static const int phoneNumberMinLength = 10;
  static const int phoneNumberMaxLength = 15;
  static const int maxLoginAttempts = 5;
  static const int loginCooldownMinutes = 15;

  // ===================== RATE LIMITING CONSTANTS =====================
  static const int maxUploadsPerDay = 10;
  static const int maxCommentsPerMinute = 5;
  static const int maxLikesPerMinute = 50;
  static const int maxFollowsPerDay = 200;
  static const int maxUnfollowsPerDay = 100;
  static const int maxReportsPerDay = 10;
  static const int maxSearchQueriesPerMinute = 30;

  // ===================== CACHE DURATION (in minutes) =====================
  static const int videoCacheDuration = 30;
  static const int userCacheDuration = 60;
  static const int commentsCacheDuration = 10;
  static const int feedCacheDuration = 15;
  static const int searchCacheDuration = 60;
  static const int trendingCacheDuration = 30;

  // ===================== ERROR MESSAGES =====================
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authenticationError = 'Authentication failed. Please try again.';
  static const String permissionError = 'Permission denied. Please grant required permissions.';
  static const String videoUploadError = 'Failed to upload video. Please try again.';
  static const String profileUpdateError = 'Failed to update profile. Please try again.';
  static const String commentError = 'Failed to post comment. Please try again.';
  static const String followError = 'Failed to follow user. Please try again.';
  static const String unfollowError = 'Failed to unfollow user. Please try again.';
  static const String likeError = 'Failed to like video. Please try again.';
  static const String shareError = 'Failed to share video. Please try again.';
  static const String reportError = 'Failed to report content. Please try again.';
  static const String searchError = 'Search failed. Please try again.';

  // ===================== SUCCESS MESSAGES =====================
  static const String loginSuccess = 'Successfully logged in!';
  static const String profileCreated = 'Profile created successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String videoUploaded = 'Video uploaded successfully!';
  static const String videoDeleted = 'Video deleted successfully!';
  static const String commentAdded = 'Comment added successfully!';
  static const String commentDeleted = 'Comment deleted successfully!';
  static const String userFollowed = 'User followed successfully!';
  static const String userUnfollowed = 'User unfollowed successfully!';
  static const String videoLiked = 'Video liked!';
  static const String videoShared = 'Video shared successfully!';
  static const String reportSubmitted = 'Report submitted successfully!';
  static const String settingsSaved = 'Settings saved successfully!';

  // ===================== GUEST MODE MESSAGES =====================
  static const String guestModeRestriction = 'Sign in to access this feature';
  static const String guestModePrompt = 'Create an account to like, comment, and share videos';
  static const String guestModeUploadPrompt = 'Sign in to upload your own videos';
  static const String guestModeFollowPrompt = 'Sign in to follow your favorite creators';
  static const String guestModeCommentPrompt = 'Sign in to join the conversation';

  // ===================== VALIDATION MESSAGES =====================
  static const String requiredField = 'This field is required';
  static const String invalidPhoneNumber = 'Please enter a valid phone number';
  static const String invalidOTP = 'Please enter a valid OTP';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String nameTooShort = 'Name must be at least 2 characters';
  static const String nameTooLong = 'Name cannot exceed 50 characters';
  static const String aboutTooShort = 'About must be at least 10 characters';
  static const String aboutTooLong = 'About cannot exceed 150 characters';
  static const String captionTooLong = 'Caption cannot exceed 2200 characters';
  static const String commentTooLong = 'Comment cannot exceed 500 characters';
  static const String usernameTooShort = 'Username must be at least 3 characters';
  static const String usernameTooLong = 'Username cannot exceed 30 characters';
  static const String usernameInvalid = 'Username can only contain letters, numbers, and underscores';
  static const String videoTooShort = 'Video must be at least 3 seconds long';
  static const String videoTooLong = 'Video cannot exceed 3 minutes';
  static const String fileTooLarge = 'File size is too large';

  // ===================== APP URLS =====================
  static const String websiteUrl = 'https://weibao.app';
  static const String privacyPolicyUrl = 'https://weibao.app/privacy';
  static const String termsOfServiceUrl = 'https://weibao.app/terms';
  static const String supportUrl = 'https://weibao.app/support';
  static const String feedbackUrl = 'https://weibao.app/feedback';
  static const String communityGuidelinesUrl = 'https://weibao.app/guidelines';
  static const String downloadUrl = 'https://weibao.app/download';

  // ===================== SOCIAL MEDIA LINKS =====================
  static const String instagramUrl = 'https://instagram.com/weibaoofficialapp';
  static const String twitterUrl = 'https://twitter.com/weibaoofficialapp';
  static const String tiktokUrl = 'https://tiktok.com/@weibaoofficialapp';
  static const String facebookUrl = 'https://facebook.com/weibaoofficialapp';
  static const String youtubeUrl = 'https://youtube.com/@weibaoofficialapp';
  static const String linkedinUrl = 'https://linkedin.com/company/weibao';

  // ===================== FEATURE FLAGS =====================
  static const bool enableGuestMode = true;
  static const bool enableVideoComments = true;
  static const bool enableVideoSharing = true;
  static const bool enableUserSearch = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableReporting = true;
  static const bool enableHashtags = true;
  static const bool enableTrending = true;
  static const bool enableGifts = false; // Premium feature
  static const bool enableLiveStreaming = false; // Future feature
  static const bool enableStories = false; // Future feature
  static const bool enableDirectMessages = false; // Future feature

  // ===================== ANALYTICS EVENTS =====================
  static const String eventAppOpen = 'app_open';
  static const String eventSignIn = 'sign_in';
  static const String eventSignUp = 'sign_up';
  static const String eventSignOut = 'sign_out';
  static const String eventProfileCreate = 'profile_create';
  static const String eventProfileUpdate = 'profile_update';
  static const String eventVideoUpload = 'video_upload';
  static const String eventVideoView = 'video_view';
  static const String eventVideoLike = 'video_like';
  static const String eventVideoShare = 'video_share';
  static const String eventVideoComment = 'video_comment';
  static const String eventUserFollow = 'user_follow';
  static const String eventUserUnfollow = 'user_unfollow';
  static const String eventSearch = 'search';
  static const String eventHashtagClick = 'hashtag_click';
  static const String eventReportSubmit = 'report_submit';
  static const String eventSettingsChange = 'settings_change';
  static const String eventErrorOccurred = 'error_occurred';

  // ===================== NOTIFICATION TYPES =====================
  static const String notificationLike = 'like';
  static const String notificationComment = 'comment';
  static const String notificationFollow = 'follow';
  static const String notificationMention = 'mention';
  static const String notificationVideoUpload = 'video_upload';
  static const String notificationGift = 'gift';
  static const String notificationSystem = 'system';
  static const String notificationPromotion = 'promotion';

  // ===================== CONTENT MODERATION =====================
  static const List<String> bannedWords = [
    // Add content moderation words here
    'spam', 'fake', 'scam', 'hate', 'violence'
  ];
  
  static const List<String> restrictedHashtags = [
    // Add restricted hashtags here
    'hate', 'violence', 'spam'
  ];

  // ===================== VIDEO EFFECTS & FILTERS =====================
  static const List<String> videoFilters = [
    'none', 'vintage', 'black_white', 'sepia', 'bright', 'contrast', 'warm', 'cool'
  ];
  
  static const List<String> videoEffects = [
    'none', 'slow_motion', 'fast_forward', 'reverse', 'time_lapse', 'boomerang'
  ];

  // ===================== DEEP LINK SCHEMES =====================
  static const String deepLinkScheme = 'weibao';
  static const String webLinkDomain = 'weibao.app';
  static const String appStoreId = '123456789'; // Replace with actual App Store ID
  static const String playStoreId = 'com.weibao.app'; // Replace with actual Play Store ID

  // ===================== MONETIZATION CONSTANTS =====================
  static const int coinsPerDollar = 100;
  static const int minimumWithdrawal = 1000; // coins
  static const double platformFeePercentage = 0.05; // 5%
  static const int giftPriceMin = 1; // coins
  static const int giftPriceMax = 10000; // coins

  // ===================== SECURITY CONSTANTS =====================
  static const int passwordMinLength = 8;
  static const int maxFailedLoginAttempts = 5;
  static const int accountLockoutMinutes = 30;
  static const int sessionTimeoutMinutes = 60;
  static const bool requireBiometricForSensitiveActions = true;

  // ===================== FILE SIZE LIMITS =====================
  static const int maxVideoSizeMB = 100;
  static const int maxImageSizeMB = 10;
  static const int maxThumbnailSizeMB = 2;
  static const int maxProfileImageSizeMB = 5;

  // ===================== PERFORMANCE CONSTANTS =====================
  static const int maxCachedVideos = 50;
  static const int maxCachedImages = 100;
  static const int preloadVideosCount = 3;
  static const int videoBufferDurationSeconds = 10;
  static const double videoCompressionQuality = 0.8;

  // ===================== LOCALIZATION =====================
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ko', 'sw'];
  
  // ===================== THEME CONSTANTS =====================
  static const String defaultTheme = 'system';
  static const List<String> availableThemes = ['light', 'dark', 'system'];
}

// Extension for easy access to commonly used constants
extension ConstantsExtension on Constants {
  static bool get isDebug => Constants.environment == 'development';
  static bool get isProduction => Constants.environment == 'production';
  static String get appDisplayName => Constants.appName;
  static String get fullVersion => '${Constants.appVersion}+${Constants.appBuildNumber}';
}