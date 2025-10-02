// lib/constants.dart (Complete TikTok-style with Category System + Search Support)
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
  
  // 🆕 NEW: Search Collections
  static const String searchHistory = 'searchHistory';
  static const String searchSuggestions = 'searchSuggestions';
  static const String popularSearchTerms = 'popularSearchTerms';
  
  // ===== MESSAGE MODEL FIELD NAMES =====
  
  static const String messageId = 'messageId';
  static const String senderId = 'senderId';
  static const String content = 'content';
  static const String type = 'type';
  static const String status = 'status';
  static const String timestamp = 'timestamp';
  static const String mediaUrl = 'mediaUrl';
  static const String mediaMetadata = 'mediaMetadata';
  static const String replyToMessageId = 'replyToMessageId';
  static const String replyToContent = 'replyToContent';
  static const String replyToSender = 'replyToSender';
  static const String reactions = 'reactions';
  static const String isEdited = 'isEdited';
  static const String editedAt = 'editedAt';
  static const String readBy = 'readBy';
  static const String deliveredTo = 'deliveredTo';
  
  // Authentication Routes
  static const String landingScreen = '/landing';
  static const String loginScreen = '/login';
  static const String otpScreen = '/otp';

  static const String discoverScreen = '/discover';
  
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

  static const String privacyPolicyScreen = '/privacyPolicyScreen';
  static const String privacySettingsScreen = '/privacySettingsScreen';
  static const String termsAndConditionsScreen = '/termsAndConditionsScreen';
  
  // Video/Content Routes
  static const String createPostScreen = '/createPost';             // was createChannelPostScreen
  static const String myPostScreen = '/myPost';
  static const String editPostScreen = '/editPost';
  static const String postDetailScreen = '/postDetail';
  static const String cameraScreen = '/camera';
  static const String videoEditorScreen = '/videoEditor';
  static const String videoPreviewScreen = '/videoPreview';
  static const String managePostsScreen = '/managePosts';
  static const String featuredVideosScreen = '/featured-videos';
  static const String liveUsersScreen = '/live-users';
  
  // Discovery Routes
  static const String exploreScreen = '/explore';                   // was exploreChannelsScreen
  static const String searchScreen = '/search';
  static const String hashtagScreen = '/hashtag';
  static const String trendingScreen = '/trending';
  static const String recommendedPostsScreen = '/recommendedPosts';
  
  // 🆕 NEW: Search Routes
  static const String videoSearchScreen = '/videoSearch';
  static const String advancedSearchScreen = '/advancedSearch';
  static const String searchResultsScreen = '/searchResults';
  static const String searchHistoryScreen = '/searchHistory';
  
  // Social Features Routes
  static const String commentsScreen = '/comments';
  static const String likesScreen = '/likes';
  static const String sharesScreen = '/shares';
  static const String mentionsScreen = '/mentions';

  
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
  
  // 🆕 NEW: Search Arguments
  static const String searchFilters = 'searchFilters';
  static const String searchMode = 'searchMode';
  static const String searchResults = 'searchResults';
  static const String searchSuggestion = 'searchSuggestion';
  static const String isFromSuggestion = 'isFromSuggestion';
  static const String searchType = 'searchType';
  
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
  
  // 🆕 NEW: Search Preferences
  static const String recentSearchesKey = 'recentSearches';
  static const String searchPreferencesKey = 'searchPreferences';
  static const String savedSearchFiltersKey = 'savedSearchFilters';
  static const String searchSuggestionsEnabledKey = 'searchSuggestionsEnabled';
  static const String trendingSearchEnabledKey = 'trendingSearchEnabled';
  static const String searchHistoryEnabledKey = 'searchHistoryEnabled';
  static const String lastSearchTimestampKey = 'lastSearchTimestamp';
  
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
  
  // ===================== API ENDPOINTS =====================
  static const String baseApiUrl = '/api/v1';
  
  // Video Endpoints
  static const String videosEndpoint = '$baseApiUrl/videos';
  static const String featuredVideosEndpoint = '$baseApiUrl/videos/featured';
  static const String trendingVideosEndpoint = '$baseApiUrl/videos/trending';
  static const String popularVideosEndpoint = '$baseApiUrl/videos/popular';
  
  // 🆕 NEW: Search Endpoints
  static const String searchEndpoint = '$baseApiUrl/videos/search';
  static const String advancedSearchEndpoint = '$baseApiUrl/videos/search';
  static const String searchSuggestionsEndpoint = '$baseApiUrl/videos/search/suggestions';
  static const String popularSearchTermsEndpoint = '$baseApiUrl/videos/search/popular';
  static const String bulkVideosEndpoint = '$baseApiUrl/videos/bulk';
  
  // User Endpoints
  static const String usersEndpoint = '$baseApiUrl/users';
  static const String userSearchEndpoint = '$baseApiUrl/users/search';
  
  // ===================== APP CONFIGURATION =====================
  static const String appName = 'WeiBao';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appPackageName = 'com.weibao.app';
  

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

  // NEW: Category UI
  static const double categoryCardHeight = 120.0;
  static const double categoryCardWidth = 200.0;
  static const double categoryIconSize = 48.0;
  static const double subcategoryChipHeight = 36.0;
  
  // 🆕 NEW: Search UI Constants
  static const double searchBarHeight = 56.0;
  static const double searchOverlayTopPadding = 60.0;
  static const double searchResultCardHeight = 120.0;
  static const double searchResultImageSize = 80.0;
  static const double searchSuggestionItemHeight = 48.0;
  static const double searchFilterChipHeight = 36.0;
  static const double searchEmptyStateImageSize = 120.0;
  static const int searchResultsGridCrossAxisCount = 2;
  static const double searchResultsGridSpacing = 8.0;
  static const double searchResultsGridChildAspectRatio = 0.7;

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
  static const int minAboutLength = 5;
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
  static const int maxVideosPerCategory = 100;             // Maximum videos to load per category

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
  
  // 🆕 NEW: Search Rate Limiting
  static const int maxSearchesPerMinute = 60;
  static const int maxSearchSuggestionsPerMinute = 120;
  static const int maxSearchHistoryItems = 50;
  static const int maxRecentSearches = 20;
  static const int maxSavedSearchFilters = 10;
  
  // ===================== CACHE DURATION (in minutes) =====================
  static const int videoCacheDuration = 30;
  static const int userCacheDuration = 60;
  static const int commentsCacheDuration = 10;
  static const int feedCacheDuration = 15;
  static const int searchCacheDuration = 60;
  static const int trendingCacheDuration = 30;
  
  // 🆕 NEW: Search Cache Duration
  static const int searchResultsCacheDuration = 15;  // 15 minutes
  static const int searchSuggestionsCacheDuration = 30; // 30 minutes
  static const int popularTermsCacheDuration = 60;   // 1 hour
  static const int searchHistoryCacheDuration = 1440; // 24 hours
  
  // ===================== SEARCH CONSTANTS =====================
  
  // 🆕 NEW: Search Configuration
  static const int minSearchQueryLength = 2;
  static const int maxSearchQueryLength = 100;
  static const int searchDebounceDelayMs = 500;
  static const int searchTimeoutSeconds = 30;
  static const int maxSearchSuggestions = 10;
  static const int defaultSearchLimit = 20;
  static const int maxSearchLimit = 50;
  
  // Search Modes
  static const String searchModeExact = 'exact';
  static const String searchModeFuzzy = 'fuzzy';
  static const String searchModeFullText = 'fulltext';
  static const String searchModeCombined = 'combined';
  
  // Search Filter Types
  static const String filterMediaTypeAll = 'all';
  static const String filterMediaTypeVideo = 'video';
  static const String filterMediaTypeImage = 'image';
  
  static const String filterTimeRangeAll = 'all';
  static const String filterTimeRangeDay = 'day';
  static const String filterTimeRangeWeek = 'week';
  static const String filterTimeRangeMonth = 'month';
  
  static const String filterSortByRelevance = 'relevance';
  static const String filterSortByLatest = 'latest';
  static const String filterSortByPopular = 'popular';
  static const String filterSortByViews = 'views';
  static const String filterSortByLikes = 'likes';
  
  // Search Suggestion Types
  static const String suggestionTypeRecent = 'recent';
  static const String suggestionTypeTrending = 'trending';
  static const String suggestionTypeCompletion = 'completion';
  static const String suggestionTypePopular = 'popular';
  
  // Search Result Types
  static const String searchResultTypeVideo = 'video';
  static const String searchResultTypeUser = 'user';
  static const String searchResultTypeHashtag = 'hashtag';
  
  // Match Types
  static const String matchTypeCaption = 'caption';
  static const String matchTypeUsername = 'username';
  static const String matchTypeTag = 'tag';
  static const String matchTypeFulltext = 'fulltext';
  
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
  
  // 🆕 NEW: Search Error Messages
  static const String searchQueryTooShort = 'Search query must be at least 2 characters';
  static const String searchQueryTooLong = 'Search query cannot exceed 100 characters';
  static const String searchNoResults = 'No results found for your search';
  static const String searchSuggestionsError = 'Failed to load search suggestions';
  static const String searchHistoryError = 'Failed to load search history';
  static const String searchTimeoutError = 'Search timed out. Please try again.';
  static const String searchRateLimitError = 'Too many searches. Please wait and try again.';
  static const String searchNetworkError = 'Check your connection and try searching again';
  
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
  
  // 🆕 NEW: Search Success Messages
  static const String searchCompleted = 'Search completed successfully!';
  static const String searchSaved = 'Search saved to history';
  static const String searchFiltersSaved = 'Search filters saved';
  static const String searchHistoryCleared = 'Search history cleared';
  
  // ===================== GUEST MODE MESSAGES =====================
  static const String guestModeRestriction = 'Sign in to access this feature';
  static const String guestModePrompt = 'Create an account to like, comment, and share videos';
  static const String guestModeUploadPrompt = 'Sign in to upload your own videos';
  static const String guestModeFollowPrompt = 'Sign in to follow your favorite creators';
  static const String guestModeCommentPrompt = 'Sign in to join the conversation';
  
  // 🆕 NEW: Search Guest Mode Messages
  static const String guestModeSearchRestriction = 'Sign in for advanced search features';
  static const String guestModeSearchHistoryPrompt = 'Sign in to save your search history';
  static const String guestModeSearchFiltersPrompt = 'Sign in to save custom search filters';

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
  
  // 🆕 NEW: Search Feature Flags
  static const bool enableVideoSearch = true;
  static const bool enableAdvancedSearch = true;
  static const bool enableSearchSuggestions = true;
  static const bool enableSearchHistory = true;
  static const bool enableTrendingSearch = true;
  static const bool enableFuzzySearch = true;
  static const bool enableSearchFilters = true;
  static const bool enableSearchCache = true;

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
  
  // 🆕 NEW: Search Analytics Events
  static const String eventSearchQuery = 'search_query';
  static const String eventSearchResult = 'search_result';
  static const String eventSearchSuggestion = 'search_suggestion';
  static const String eventSearchFilter = 'search_filter';
  static const String eventSearchHistoryView = 'search_history_view';
  static const String eventSearchResultClick = 'search_result_click';
  static const String eventSearchEmpty = 'search_empty';
  static const String eventSearchError = 'search_error';
  static const String eventAdvancedSearch = 'advanced_search';
  static const String eventSearchModeChange = 'search_mode_change';

  // ===================== NOTIFICATION TYPES =====================
  static const String notificationLike = 'like';
  static const String notificationComment = 'comment';
  static const String notificationFollow = 'follow';
  static const String notificationMention = 'mention';
  static const String notificationVideoUpload = 'video_upload';
  static const String notificationGift = 'gift';
  static const String notificationSystem = 'system';
  static const String notificationPromotion = 'promotion';
  static const String notificationPriceAlert = 'price_alert';         // NEW: Price alert notification
  static const String notificationCategoryTrending = 'category_trending'; // NEW: Category trending notification
  
  // 🆕 NEW: Search Notification Types
  static const String notificationSearchTrending = 'search_trending';
  static const String notificationSearchResult = 'search_result';
  static const String notificationSearchUpdate = 'search_update';

  // ===================== CONTENT MODERATION =====================
  static const List<String> bannedWords = [
    // Add content moderation words here
    'spam', 'fake', 'scam', 'hate', 'violence'
  ];
  
  static const List<String> restrictedHashtags = [
    // Add restricted hashtags here
    'hate', 'violence', 'spam'
  ];

  // NEW: Restricted categories (for content moderation)
  static const List<String> restrictedCategories = [
    // Categories that require special approval or moderation
  ];
  
  // 🆕 NEW: Search Content Moderation
  static const List<String> bannedSearchTerms = [
    // Add banned search terms here
    'inappropriate', 'harmful'
  ];
  
  static const List<String> restrictedSearchFilters = [
    // Search filters that require special permissions
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
  
  // 🆕 NEW: Search Deep Links
  static const String searchDeepLinkPath = '/search';
  static const String searchResultDeepLinkPath = '/search/result';

  // ===================== MONETIZATION CONSTANTS =====================
  static const int coinsPerDollar = 100;
  static const int minimumWithdrawal = 1000; // coins
  static const double platformFeePercentage = 0.05; // 5%
  static const int giftPriceMin = 1; // coins
  static const int giftPriceMax = 10000; // coins
  
  // NEW: Marketplace constants
  static const double maxPrice = 1000000000.0; // KES 1 Billion maximum price
  static const double minPrice = 0.0; // Free items allowed
  static const double defaultPriceStep = 100.0; // Price increment steps
  static const List<double> suggestedPrices = [
    0, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 500000, 1000000
  ]; // Common price suggestions

  // ===================== SECURITY CONSTANTS =====================
  static const int passwordMinLength = 8;
  static const int maxFailedLoginAttempts = 5;
  static const int accountLockoutMinutes = 30;
  static const int sessionTimeoutMinutes = 60;
  static const bool requireBiometricForSensitiveActions = true;

  // ===================== FILE SIZE LIMITS =====================
  static const int maxVideoSizeMB = 50;
  static const int maxImageSizeMB = 10;
  static const int maxThumbnailSizeMB = 2;
  static const int maxProfileImageSizeMB = 5;

  // ===================== PERFORMANCE CONSTANTS =====================
  static const int maxCachedVideos = 50;
  static const int maxCachedImages = 100;
  static const int preloadVideosCount = 3;
  static const int videoBufferDurationSeconds = 10;
  static const double videoCompressionQuality = 0.8;
  
  // 🆕 NEW: Search Performance Constants
  static const int maxCachedSearchResults = 100;
  static const int maxCachedSearchSuggestions = 50;
  static const int searchResultPreloadCount = 5;
  static const int searchImageCacheSize = 20;

  // ===================== LOCALIZATION =====================
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ko', 'sw'];
  
  // ===================== THEME CONSTANTS =====================
  static const String defaultTheme = 'system';
  static const List<String> availableThemes = ['light', 'dark', 'system'];

  // ===================== SEARCH HELPER METHODS =====================
  
  /// Validate search query length and content
  static bool isValidSearchQuery(String query) {
    final trimmed = query.trim();
    return trimmed.isNotEmpty && 
           trimmed.length >= minSearchQueryLength &&
           trimmed.length <= maxSearchQueryLength &&
           !bannedSearchTerms.any((banned) => trimmed.toLowerCase().contains(banned.toLowerCase()));
  }
  
  /// Clean and format search query
  static String cleanSearchQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Check if search query is trending term
  static bool isTrendingSearchQuery(String query, List<String> trendingTerms) {
    return trendingTerms.any((term) => term.toLowerCase() == query.toLowerCase());
  }
  
  /// Get search mode display name
  static String getSearchModeDisplayName(String mode) {
    switch (mode) {
      case searchModeExact:
        return 'Exact Match';
      case searchModeFuzzy:
        return 'Smart Search';
      case searchModeFullText:
        return 'Full Text';
      case searchModeCombined:
        return 'Best Match';
      default:
        return 'Search';
    }
  }
  
  /// Get search filter display name
  static String getSearchFilterDisplayName(String filterType, String filterValue) {
    switch (filterType) {
      case 'mediaType':
        switch (filterValue) {
          case filterMediaTypeVideo:
            return 'Videos';
          case filterMediaTypeImage:
            return 'Images';
          case filterMediaTypeAll:
            return 'All Media';
          default:
            return filterValue;
        }
      case 'timeRange':
        switch (filterValue) {
          case filterTimeRangeDay:
            return 'Today';
          case filterTimeRangeWeek:
            return 'This Week';
          case filterTimeRangeMonth:
            return 'This Month';
          case filterTimeRangeAll:
            return 'All Time';
          default:
            return filterValue;
        }
      case 'sortBy':
        switch (filterValue) {
          case filterSortByRelevance:
            return 'Most Relevant';
          case filterSortByLatest:
            return 'Latest';
          case filterSortByPopular:
            return 'Most Popular';
          case filterSortByViews:
            return 'Most Viewed';
          case filterSortByLikes:
            return 'Most Liked';
          default:
            return filterValue;
        }
      default:
        return filterValue;
    }
  }
  
  /// Get suggestion type display name
  static String getSuggestionTypeDisplayName(String type) {
    switch (type) {
      case suggestionTypeRecent:
        return 'Recent';
      case suggestionTypeTrending:
        return 'Trending';
      case suggestionTypeCompletion:
        return 'Suggestion';
      case suggestionTypePopular:
        return 'Popular';
      default:
        return 'Search';
    }
  }
  
  /// Get match type display name
  static String getMatchTypeDisplayName(String matchType) {
    switch (matchType) {
      case matchTypeCaption:
        return 'Found in caption';
      case matchTypeUsername:
        return 'Found in creator name';
      case matchTypeTag:
        return 'Found in tags';
      case matchTypeFulltext:
        return 'Text match';
      default:
        return 'Match found';
    }
  }
  
  /// Format search result count
  static String formatSearchResultCount(int count) {
    if (count == 0) return 'No results';
    if (count == 1) return '1 result';
    if (count < 1000) return '$count results';
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K results';
    }
    return '${(count / 1000000).toStringAsFixed(1)}M results';
  }
  
  /// Format search time taken
  static String formatSearchTime(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else {
      return '${(milliseconds / 1000).toStringAsFixed(1)}s';
    }
  }
  
  /// Check if search filter is active (not default)
  static bool isSearchFilterActive(String filterType, dynamic filterValue) {
    switch (filterType) {
      case 'mediaType':
        return filterValue != filterMediaTypeAll;
      case 'timeRange':
        return filterValue != filterTimeRangeAll;
      case 'sortBy':
        return filterValue != filterSortByRelevance;
      case 'minLikes':
        return filterValue != null && filterValue > 0;
      case 'hasPrice':
      case 'isVerified':
        return filterValue != null;
      default:
        return false;
    }
  }
  
  /// Get default search filters
  static Map<String, dynamic> getDefaultSearchFilters() {
    return {
      'mediaType': filterMediaTypeAll,
      'timeRange': filterTimeRangeAll,
      'sortBy': filterSortByRelevance,
      'minLikes': 0,
      'hasPrice': null,
      'isVerified': null,
    };
  }
  
  /// Get search placeholder text based on context
  static String getSearchPlaceholder({String? context}) {
    switch (context) {
      case 'videos':
        return 'Search videos and creators...';
      case 'users':
        return 'Search users...';
      case 'premium':
        return 'Search premium content...';
      case 'verified':
        return 'Search verified content...';
      default:
        return 'Search videos and creators...';
    }
  }

  // ===================== CATEGORY HELPER METHODS =====================

  /// Format price for display
  static String formatPrice(double price) {
    if (price == 0) {
      return 'Free';
    }
    
    if (price < 1000000) {
      // Format with commas for thousands
      return 'KES ${price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      // Format in millions
      double millions = price / 1000000;
      if (millions == millions.toInt()) {
        // Whole number of millions
        return 'KES ${millions.toInt()}M';
      } else {
        // Decimal millions (e.g., 1.5M)
        return 'KES ${millions.toStringAsFixed(1)}M';
      }
    }
  }
  
  /// Format count for display (likes, views, etc.)
  static String formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  
  /// Format duration for display
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
  
  /// Get time ago string
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Validate file extension
  static bool isValidFileExtension(String fileName, List<String> allowedExtensions) {
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }
  
  /// Get file size string
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Check if URL is valid
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Generate unique ID
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (999999 - 1000) * (DateTime.now().microsecond / 1000000)).round().toString();
  }
  
  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
  
  /// Get video quality string
  static String getVideoQualityString(int quality) {
    switch (quality) {
      case 480:
        return '480p';
      case 720:
        return 'HD';
      case 1080:
        return 'Full HD';
      case 1440:
        return '2K';
      case 2160:
        return '4K';
      default:
        return '${quality}p';
    }
  }
}

// ===================== SEARCH EXTENSIONS =====================

/// Extension for easy access to search-related constants
extension SearchConstants on Constants {
  static List<String> get allSearchModes => [
    Constants.searchModeExact,
    Constants.searchModeFuzzy,
    Constants.searchModeFullText,
    Constants.searchModeCombined,
  ];
  
  static List<String> get allMediaTypes => [
    Constants.filterMediaTypeAll,
    Constants.filterMediaTypeVideo,
    Constants.filterMediaTypeImage,
  ];
  
  static List<String> get allTimeRanges => [
    Constants.filterTimeRangeAll,
    Constants.filterTimeRangeDay,
    Constants.filterTimeRangeWeek,
    Constants.filterTimeRangeMonth,
  ];
  
  static List<String> get allSortOptions => [
    Constants.filterSortByRelevance,
    Constants.filterSortByLatest,
    Constants.filterSortByPopular,
    Constants.filterSortByViews,
    Constants.filterSortByLikes,
  ];
  
  static List<String> get allSuggestionTypes => [
    Constants.suggestionTypeRecent,
    Constants.suggestionTypeTrending,
    Constants.suggestionTypeCompletion,
    Constants.suggestionTypePopular,
  ];
  
  static List<String> get allMatchTypes => [
    Constants.matchTypeCaption,
    Constants.matchTypeUsername,
    Constants.matchTypeTag,
    Constants.matchTypeFulltext,
  ];
}

// Extension for easy access to commonly used constants
extension ConstantsExtension on Constants {
  static String get appDisplayName => Constants.appName;
  static String get fullVersion => '${Constants.appVersion}+${Constants.appBuildNumber}';
  static String get searchVersion => '1.0.0'; // 🆕 NEW: Search feature version
  
  // 🆕 NEW: Search feature availability
  static bool get isSearchEnabled => Constants.enableVideoSearch;
  static bool get isAdvancedSearchEnabled => Constants.enableAdvancedSearch;
  static bool get isSearchSuggestionsEnabled => Constants.enableSearchSuggestions;
  static bool get isSearchHistoryEnabled => Constants.enableSearchHistory;
  static bool get isFuzzySearchEnabled => Constants.enableFuzzySearch;
}