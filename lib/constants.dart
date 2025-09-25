// lib/constants.dart (Complete TikTok-style with Category System)
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
  static const String categories = 'categories';          // NEW: Categories collection

  // ===================== CATEGORY FIELD NAMES =====================
  static const String mainCategory = 'mainCategory';
  static const String mainCategoryId = 'mainCategoryId';
  static const String mainCategoryName = 'mainCategoryName';
  static const String subCategory = 'subCategory';
  static const String subCategoryId = 'subCategoryId';
  static const String subCategoryName = 'subCategoryName';
  static const String categoryIcon = 'categoryIcon';
  static const String categoryColor = 'categoryColor';
  static const String categoryPostCount = 'categoryPostCount';

  // ===================== CATEGORY CONSTANTS =====================
  
  // Main Category Keys
  static const String vehiclesCategory = 'vehicles';
  static const String fashionCategory = 'fashion';
  static const String electronicsCategory = 'electronics';
  static const String furnitureCategory = 'furniture_home';
  static const String airbnbCategory = 'airbnb';
  static const String hotelsCategory = 'hotels_restaurants';
  static const String realEstateCategory = 'real_estate';
  static const String servicesCategory = 'services';
  static const String sportsCategory = 'sports_hobbies';
  static const String jobsCategory = 'jobs_business';

  // Category Colors
  static const String vehiclesCategoryColor = '#FF6B6B';
  static const String fashionCategoryColor = '#4ECDC4';
  static const String electronicsCategoryColor = '#45B7D1';
  static const String furnitureCategoryColor = '#96CEB4';
  static const String airbnbCategoryColor = '#FF5A5F';
  static const String hotelsCategoryColor = '#FF8A65';
  static const String realEstateCategoryColor = '#FECA57';
  static const String servicesCategoryColor = '#A8E6CF';
  static const String sportsCategoryColor = '#FFD93D';
  static const String jobsCategoryColor = '#FF9FF3';

  // Category Icons
  static const String vehiclesCategoryIcon = 'car_icon';
  static const String fashionCategoryIcon = 'fashion_icon';
  static const String electronicsCategoryIcon = 'electronics_icon';
  static const String furnitureCategoryIcon = 'furniture_icon';
  static const String airbnbCategoryIcon = 'airbnb_icon';
  static const String hotelsCategoryIcon = 'hotel_restaurant_icon';
  static const String realEstateCategoryIcon = 'real_estate_icon';
  static const String servicesCategoryIcon = 'services_icon';
  static const String sportsCategoryIcon = 'sports_icon';
  static const String jobsCategoryIcon = 'jobs_icon';

  // Vehicles Subcategories
  static const String carsSubcategory = 'cars';
  static const String vehiclePartsSubcategory = 'vehicle_parts';
  static const String trucksSubcategory = 'trucks_trailers';
  static const String busesSubcategory = 'buses_microbuses';
  static const String motorcyclesSubcategory = 'motorcycles';
  static const String heavyMachinerySubcategory = 'heavy_machinery';
  static const String bicyclesSubcategory = 'bicycles';
  static const String boatsSubcategory = 'boats_watercraft';

  // Fashion Subcategories
  static const String menFashionSubcategory = 'men_fashion';
  static const String womenFashionSubcategory = 'women_fashion';
  static const String childrenFashionSubcategory = 'children_fashion';
  static const String shoesSubcategory = 'shoes';
  static const String bagsAccessoriesSubcategory = 'bags_accessories';
  static const String jewelryWatchesSubcategory = 'jewelry_watches';
  static const String beautyCosmeticsSubcategory = 'beauty_cosmetics';
  static const String traditionalWearSubcategory = 'traditional_wear';

  // Electronics Subcategories
  static const String smartphonesSubcategory = 'smartphones';
  static const String computersLaptopsSubcategory = 'computers_laptops';
  static const String tabletsSubcategory = 'tablets';
  static const String tvAudioSubcategory = 'tv_audio';
  static const String gamingSubcategory = 'gaming';
  static const String camerasSubcategory = 'cameras';
  static const String homeAppliancesSubcategory = 'home_appliances';
  static const String electronicsAccessoriesSubcategory = 'accessories';

  // Furniture & Home Subcategories
  static const String livingRoomSubcategory = 'living_room';
  static const String bedroomSubcategory = 'bedroom';
  static const String kitchenDiningSubcategory = 'kitchen_dining';
  static const String officeFurnitureSubcategory = 'office_furniture';
  static const String homeDecorSubcategory = 'home_decor';
  static const String gardenOutdoorSubcategory = 'garden_outdoor';
  static const String lightingSubcategory = 'lighting';
  static const String storageOrganizationSubcategory = 'storage_organization';

  // Real Estate Subcategories
  static const String apartmentsRentSubcategory = 'apartments_rent';
  static const String apartmentsSaleSubcategory = 'apartments_sale';
  static const String housesRentSubcategory = 'houses_rent';
  static const String housesSaleSubcategory = 'houses_sale';
  static const String commercialSubcategory = 'commercial';
  static const String landSubcategory = 'land';
  static const String roommatesSubcategory = 'roommates';

  // Services Subcategories
  static const String homeServicesSubcategory = 'home_services';
  static const String beautyWellnessSubcategory = 'beauty_wellness';
  static const String automotiveServicesSubcategory = 'automotive_services';
  static const String tutoringClassesSubcategory = 'tutoring_classes';
  static const String eventServicesSubcategory = 'event_services';
  static const String businessServicesSubcategory = 'business_services';
  static const String healthMedicalSubcategory = 'health_medical';
  static const String freelanceDigitalSubcategory = 'freelance_digital';

  // Sports & Hobbies Subcategories
  static const String gymFitnessSubcategory = 'gym_fitness';
  static const String outdoorSportsSubcategory = 'outdoor_sports';
  static const String indoorGamesSubcategory = 'indoor_games';
  static const String musicalInstrumentsSubcategory = 'musical_instruments';
  static const String booksMediaSubcategory = 'books_media';
  static const String artCraftsSubcategory = 'art_crafts';
  static const String collectiblesSubcategory = 'collectibles';
  static const String partyEventsSubcategory = 'party_events';

  // Jobs & Business Subcategories
  static const String fullTimeJobsSubcategory = 'full_time_jobs';
  static const String partTimeJobsSubcategory = 'part_time_jobs';
  static const String internshipsSubcategory = 'internships';
  static const String freelanceGigsSubcategory = 'freelance_gigs';
  static const String businessForSaleSubcategory = 'business_for_sale';
  static const String franchiseOpportunitiesSubcategory = 'franchise_opportunities';
  static const String partnershipsSubcategory = 'partnerships';
  static const String investmentsSubcategory = 'investments';

  // ===================== ROUTE NAMES =====================

  // ===== CHAT MODEL FIELD NAMES =====
  
  static const String chatId = 'chatId';
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageType = 'lastMessageType';
  static const String lastMessageSender = 'lastMessageSender';
  static const String lastMessageTime = 'lastMessageTime';
  static const String unreadCounts = 'unreadCounts';
  static const String isArchived = 'isArchived';
  static const String isPinned = 'isPinned';
  static const String isMuted = 'isMuted';
  static const String chatWallpapers = 'chatWallpapers';
  static const String fontSizes = 'fontSizes';

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
  
  // Discovery Routes
  static const String exploreScreen = '/explore';                   // was exploreChannelsScreen
  static const String searchScreen = '/search';
  static const String hashtagScreen = '/hashtag';
  static const String trendingScreen = '/trending';
  static const String recommendedPostsScreen = '/recommendedPosts';
  
  // NEW: Category Routes
  static const String categoriesScreen = '/categories';
  static const String categoryFeedScreen = '/categoryFeed';
  static const String categoryDetailsScreen = '/categoryDetails';
  static const String selectCategoryScreen = '/selectCategory';
  
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

  // Contacts Routes
  static const String contactsScreen = '/contactsScreen';
  static const String addContactScreen = '/addContactScreen';
  static const String blockedContactsScreen = '/blockedContactsScreen';
  static const String contactProfileScreen = '/contactProfileScreen';

  // Chat Routes
  static const String videoReactionChatScreen = '/video-reaction-chat';
  static const String videoReactionsListScreen = '/video-reactions-list';
  


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
  static const String categoryKey = 'categoryKey';                    // NEW: Category navigation
  static const String subcategoryKey = 'subcategoryKey';            // NEW: Subcategory navigation

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
  static const String selectedCategoriesKey = 'selectedCategories';   // NEW: User's preferred categories
  static const String categoryPreferencesKey = 'categoryPreferences'; // NEW: Category preferences

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
  static const String categoryImagesPath = 'categoryImages';          // NEW: Category images

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

  // NEW: Category UI
  static const double categoryCardHeight = 120.0;
  static const double categoryCardWidth = 200.0;
  static const double categoryIconSize = 48.0;
  static const double subcategoryChipHeight = 36.0;

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

  // ===================== CATEGORY CONSTANTS =====================
  static const int maxCategoriesPerUser = 5;              // Maximum categories a user can select as interests
  static const int maxFeaturedCategories = 8;             // Maximum featured categories on home screen
  static const int maxTrendingCategoriesPerCategory = 10;  // Maximum trending items per category
  static const int categoryRefreshIntervalMinutes = 60;    // How often to refresh category data

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
  static const int maxCategoryViewsPerDay = 1000;         // Limit category browsing

  // ===================== CACHE DURATION (in minutes) =====================
  static const int videoCacheDuration = 30;
  static const int userCacheDuration = 60;
  static const int commentsCacheDuration = 10;
  static const int feedCacheDuration = 15;
  static const int searchCacheDuration = 60;
  static const int trendingCacheDuration = 30;
  static const int categoryCacheDuration = 120;            // Categories change less frequently

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
  static const String categoryError = 'Failed to load categories. Please try again.'; // NEW: Category error
  static const String categorySelectionError = 'Please select a category.';           // NEW: Category selection error

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
  static const String categorySelected = 'Category selected successfully!';           // NEW: Category success
  static const String categoryPreferencesSaved = 'Category preferences saved!';      // NEW: Category preferences success

  // ===================== GUEST MODE MESSAGES =====================
  static const String guestModeRestriction = 'Sign in to access this feature';
  static const String guestModePrompt = 'Create an account to like, comment, and share videos';
  static const String guestModeUploadPrompt = 'Sign in to upload your own videos';
  static const String guestModeFollowPrompt = 'Sign in to follow your favorite creators';
  static const String guestModeCommentPrompt = 'Sign in to join the conversation';
  static const String guestModeCategoryPrompt = 'Sign in to save your favorite categories'; // NEW: Guest mode category

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
  static const String priceTooHigh = 'Price cannot exceed KES 10,000,000';            // NEW: Price validation
  static const String priceInvalid = 'Please enter a valid price';                   // NEW: Price validation
  static const String categoryRequired = 'Please select a category';                 // NEW: Category validation

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
  static const bool enableCategories = true; // NEW: Category system
  static const bool enableCategoryFiltering = true; // NEW: Category filtering
  static const bool enablePricing = true; // NEW: Pricing system

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
  static const String eventCategoryView = 'category_view';            // NEW: Category analytics
  static const String eventCategorySelect = 'category_select';        // NEW: Category analytics
  static const String eventPriceFilter = 'price_filter';              // NEW: Price analytics

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
  
  // NEW: Marketplace constants
  static const double maxPrice = 10000000.0; // KES 10 Million maximum price
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

  // ===================== LOCALIZATION =====================
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ko', 'sw'];
  
  // ===================== THEME CONSTANTS =====================
  static const String defaultTheme = 'system';
  static const List<String> availableThemes = ['light', 'dark', 'system'];

  // ===================== CATEGORY HELPER METHODS =====================
  
  /// Get category display name from key
  static String getCategoryDisplayName(String categoryKey) {
    switch (categoryKey) {
      case vehiclesCategory:
        return 'Vehicles';
      case fashionCategory:
        return 'Fashion & Beauty';
      case electronicsCategory:
        return 'Electronics';
      case furnitureCategory:
        return 'Furniture & Home';
      case airbnbCategory:
        return 'Airbnb';
      case hotelsCategory:
        return 'Hotels & Restaurants';
      case realEstateCategory:
        return 'Real Estate';
      case servicesCategory:
        return 'Services';
      case sportsCategory:
        return 'Sports & Hobbies';
      case jobsCategory:
        return 'Jobs & Business';
      default:
        return 'Unknown Category';
    }
  }

  /// Get category color from key
  static String getCategoryColor(String categoryKey) {
    switch (categoryKey) {
      case vehiclesCategory:
        return vehiclesCategoryColor;
      case fashionCategory:
        return fashionCategoryColor;
      case electronicsCategory:
        return electronicsCategoryColor;
      case furnitureCategory:
        return furnitureCategoryColor;
      case airbnbCategory:
        return airbnbCategoryColor;
      case hotelsCategory:
        return hotelsCategoryColor;
      case realEstateCategory:
        return realEstateCategoryColor;
      case servicesCategory:
        return servicesCategoryColor;
      case sportsCategory:
        return sportsCategoryColor;
      case jobsCategory:
        return jobsCategoryColor;
      default:
        return '#6B7280'; // Default gray color
    }
  }

  /// Get category icon from key
  static String getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case vehiclesCategory:
        return vehiclesCategoryIcon;
      case fashionCategory:
        return fashionCategoryIcon;
      case electronicsCategory:
        return electronicsCategoryIcon;
      case furnitureCategory:
        return furnitureCategoryIcon;
      case airbnbCategory:
        return airbnbCategoryIcon;
      case hotelsCategory:
        return hotelsCategoryIcon;
      case realEstateCategory:
        return realEstateCategoryIcon;
      case servicesCategory:
        return servicesCategoryIcon;
      case sportsCategory:
        return sportsCategoryIcon;
      case jobsCategory:
        return jobsCategoryIcon;
      default:
        return 'default_category_icon';
    }
  }

  /// Get all main category keys
  static List<String> getAllCategoryKeys() {
    return [
      vehiclesCategory,
      fashionCategory,
      electronicsCategory,
      furnitureCategory,
      airbnbCategory,
      hotelsCategory,
      realEstateCategory,
      servicesCategory,
      sportsCategory,
      jobsCategory,
    ];
  }

  /// Get categories that have subcategories
  static List<String> getCategoriesWithSubcategories() {
    return [
      vehiclesCategory,
      fashionCategory,
      electronicsCategory,
      furnitureCategory,
      realEstateCategory,
      servicesCategory,
      sportsCategory,
      jobsCategory,
    ];
  }

  /// Get independent categories (no subcategories)
  static List<String> getIndependentCategories() {
    return [
      airbnbCategory,
      hotelsCategory,
    ];
  }

  /// Check if category has subcategories
  static bool categoryHasSubcategories(String categoryKey) {
    return getCategoriesWithSubcategories().contains(categoryKey);
  }

  /// Validate price
  static bool isValidPrice(double price) {
    return price >= minPrice && price <= maxPrice;
  }

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
}

// Extension for easy access to commonly used constants
extension ConstantsExtension on Constants {
  static bool get isDebug => Constants.environment == 'development';
  static bool get isProduction => Constants.environment == 'production';
  static String get appDisplayName => Constants.appName;
  static String get fullVersion => '${Constants.appVersion}+${Constants.appBuildNumber}';
  
  // NEW: Category extension methods
  static bool get categoriesEnabled => Constants.enableCategories;
  static bool get pricingEnabled => Constants.enablePricing;
  static bool get categoryFilteringEnabled => Constants.enableCategoryFiltering;
}