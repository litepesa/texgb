// lib/constants.dart (Complete TikTok-style with Category System + Property Routes)
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
  
  // NEW: Property Collections
  static const String properties = 'properties';
  static const String propertyLikes = 'property_likes';
  static const String propertyComments = 'property_comments';
  static const String propertyViews = 'property_views';
  static const String propertyInquiries = 'property_inquiries';
  static const String propertyReports = 'property_reports';
  static const String propertySubscriptions = 'property_subscriptions';
  static const String propertyAnalytics = 'property_analytics';
  static const String bookings = 'bookings';
  static const String propertyReviews = 'property_reviews';
  static const String propertyAvailability = 'property_availability';

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

  // ===================== NEW: PROPERTY ROUTES =====================
  
  // Property Feed Routes (TikTok-style)
  static const String propertyFeedScreen = '/propertyFeed';
  static const String singlePropertyScreen = '/singleProperty';
  static const String propertyDetailScreen = '/propertyDetail';
  static const String propertyVideoPlayerScreen = '/propertyVideoPlayer';
  
  // Property Management Routes (Host)
  static const String hostDashboardScreen = '/hostDashboard';
  static const String createPropertyScreen = '/createProperty';
  static const String editPropertyScreen = '/editProperty';
  static const String managePropertiesScreen = '/manageProperties';
  static const String propertyAnalyticsScreen = '/propertyAnalytics';
  static const String hostInquiriesScreen = '/hostInquiries';
  static const String propertySubscriptionScreen = '/propertySubscription';
  static const String hostBillingScreen = '/hostBilling';
  
  // Property Interaction Routes
  static const String propertyCommentsScreen = '/propertyComments';
  static const String propertyLikesScreen = '/propertyLikes';
  static const String propertyShareScreen = '/propertyShare';
  static const String propertyInquiryScreen = '/propertyInquiry';
  static const String propertyReportScreen = '/propertyReport';
  
  // Property Search & Discovery Routes
  static const String propertySearchScreen = '/propertySearch';
  static const String propertyFiltersScreen = '/propertyFilters';
  static const String propertiesByCityScreen = '/propertiesByCity';
  static const String trendingPropertiesScreen = '/trendingProperties';
  static const String featuredPropertiesScreen = '/featuredProperties';
  static const String nearbyPropertiesScreen = '/nearbyProperties';
  
  // Property Booking Routes
  static const String propertyBookingScreen = '/propertyBooking';
  static const String bookingConfirmationScreen = '/bookingConfirmation';
  static const String myBookingsScreen = '/myBookings';
  static const String bookingDetailScreen = '/bookingDetail';
  static const String bookingHistoryScreen = '/bookingHistory';
  
  // Property Reviews Routes
  static const String propertyReviewsScreen = '/propertyReviews';
  static const String writeReviewScreen = '/writeReview';
  static const String reviewDetailScreen = '/reviewDetail';
  
  // Host Setup & Onboarding Routes
  static const String becomeHostScreen = '/becomeHost';
  static const String hostOnboardingScreen = '/hostOnboarding';
  static const String hostVerificationScreen = '/hostVerification';
  static const String hostSetupScreen = '/hostSetup';
  static const String hostProfileScreen = '/hostProfile';
  static const String editHostProfileScreen = '/editHostProfile';
  
  // Property Media Routes
  static const String propertyPhotoGalleryScreen = '/propertyPhotoGallery';
  static const String propertyVideoRecorderScreen = '/propertyVideoRecorder';
  static const String propertyVideoEditorScreen = '/propertyVideoEditor';
  static const String propertyMediaManagerScreen = '/propertyMediaManager';
  
  // Property Settings Routes
  static const String propertySettingsScreen = '/propertySettings';
  static const String propertyAvailabilityScreen = '/propertyAvailability';
  static const String propertyPricingScreen = '/propertyPricing';
  static const String propertyAmenitiesScreen = '/propertyAmenities';
  static const String propertyRulesScreen = '/propertyRules';
  
  // Map & Location Routes
  static const String propertyMapScreen = '/propertyMap';
  static const String selectLocationScreen = '/selectLocation';
  static const String nearbyAmenitiesScreen = '/nearbyAmenities';
  
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
  
  // NEW: Property Navigation Arguments
  static const String propertyId = 'propertyId';
  static const String propertyModel = 'propertyModel';
  static const String hostId = 'hostId';
  static const String bookingId = 'bookingId';
  static const String reviewId = 'reviewId';
  static const String inquiryId = 'inquiryId';
  static const String city = 'city';
  static const String propertyType = 'propertyType';
  static const String maxRate = 'maxRate';
  static const String minRate = 'minRate';
  static const String checkInDate = 'checkInDate';
  static const String checkOutDate = 'checkOutDate';
  static const String guests = 'guests';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String isHost = 'isHost';
  static const String selectedPropertyTypes = 'selectedPropertyTypes';
  static const String selectedAmenities = 'selectedAmenities';
  static const String priceRange = 'priceRange';
  static const String sortBy = 'sortBy';
  static const String showOnMap = 'showOnMap';
  
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
  
  // NEW: Property Shared Preferences Keys
  static const String likedPropertiesKey = 'likedProperties';
  static const String viewedPropertiesKey = 'viewedProperties';
  static const String favoritePropertiesKey = 'favoriteProperties';
  static const String propertySearchHistoryKey = 'propertySearchHistory';
  static const String hostModeEnabledKey = 'hostModeEnabled';
  static const String lastPropertyFiltersKey = 'lastPropertyFilters';
  static const String propertyNotificationsKey = 'propertyNotifications';
  static const String bookingNotificationsKey = 'bookingNotifications';
  static const String hostNotificationsKey = 'hostNotifications';
  static const String propertyMapTypeKey = 'propertyMapType';
  static const String showPropertyMapKey = 'showPropertyMap';
  static const String autoplayPropertyVideosKey = 'autoplayPropertyVideos';
  static const String defaultCurrencyKey = 'defaultCurrency';
  static const String lastLocationKey = 'lastLocation';
  static const String hostOnboardingCompletedKey = 'hostOnboardingCompleted';
  static const String propertyAnalyticsEnabledKey = 'propertyAnalyticsEnabled';
  
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
  
  // NEW: Property Firebase Storage Paths
  static const String propertyVideosPath = 'propertyVideos';
  static const String propertyImagesPath = 'propertyImages';
  static const String propertyThumbnailsPath = 'propertyThumbnails';
  static const String hostProfileImagesPath = 'hostProfileImages';
  static const String propertyDocumentsPath = 'propertyDocuments';
  static const String verificationDocumentsPath = 'verificationDocuments';
  static const String propertyTempUploadsPath = 'propertyTempUploads';
  static const String bookingDocumentsPath = 'bookingDocuments';
  static const String reviewImagesPath = 'reviewImages';
  
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

  // Category UI
  static const double categoryCardHeight = 120.0;
  static const double categoryCardWidth = 200.0;
  static const double categoryIconSize = 48.0;
  static const double subcategoryChipHeight = 36.0;

  // NEW: Property UI Constants
  static const double propertyCardHeight = 280.0;
  static const double propertyCardWidth = 200.0;
  static const double propertyImageHeight = 160.0;
  static const double propertyVideoHeight = 300.0;
  static const double propertyAvatarSize = 32.0;
  static const double propertyActionButtonSize = 44.0;
  static const double propertyRatingStarSize = 16.0;
  static const double propertyPriceTextSize = 18.0;
  static const double propertyTitleTextSize = 16.0;
  static const double propertySubtitleTextSize = 14.0;
  static const double propertyDescriptionTextSize = 12.0;
  static const double propertyAmenityIconSize = 20.0;
  static const double propertyFilterChipHeight = 40.0;
  static const double propertySearchBarHeight = 48.0;
  static const double propertyMapMarkerSize = 24.0;
  static const double propertyGalleryImageHeight = 200.0;
  static const double propertyBottomSheetHeight = 400.0;
  static const double propertyBookingCardHeight = 120.0;
  static const double propertyReviewCardHeight = 100.0;
  static const double hostProfileImageSize = 60.0;
  static const double propertyDetailHeaderHeight = 250.0;
  static const double propertyFeedHeaderHeight = 80.0;

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

  // NEW: Property Video Constants
  static const int maxPropertyVideoLength = 300; // 5 minutes for property videos
  static const int minPropertyVideoLength = 10;  // 10 seconds minimum
  static const int maxPropertyImageCount = 20;   // More images for properties
  static const int propertyVideoQuality = 1080;  // Higher quality for properties
  static const int propertyThumbnailWidth = 400;
  static const int propertyThumbnailHeight = 300; // 4:3 aspect ratio for properties
  static const double propertyVideoAspectRatio = 4/3; // Different from TikTok

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

  // NEW: Property Content Limits
  static const int maxPropertyTitleLength = 100;
  static const int minPropertyTitleLength = 10;
  static const int maxPropertyDescriptionLength = 1000;
  static const int minPropertyDescriptionLength = 50;
  static const int maxPropertyAddressLength = 200;
  static const int maxPropertyRulesLength = 500;
  static const int maxPropertyAmenitiesCount = 20;
  static const int maxPropertyTagsCount = 10;
  static const int maxHostBioLength = 300;
  static const int minHostBioLength = 20;
  static const int maxPropertyCommentLength = 300;
  static const int maxPropertyReviewLength = 500;
  static const int minPropertyReviewLength = 20;

  // ===================== SOCIAL CONSTANTS =====================
  static const int maxSearchResults = 50;
  static const int maxCommentsPerLoad = 50;
  static const int maxVideosPerLoad = 20;
  static const int maxUsersPerLoad = 20;
  static const int maxNotificationsPerLoad = 30;
  static const int maxFollowingCount = 7500; // TikTok limit
  static const int maxLikesPerVideo = 999999999; // Display limit
  static const int maxVideosPerCategory = 100; // Maximum videos to load per category

  // NEW: Property Social Constants
  static const int maxPropertiesPerLoad = 20;
  static const int maxPropertyCommentsPerLoad = 30;
  static const int maxPropertyLikesPerLoad = 100;
  static const int maxPropertyInquiriesPerLoad = 50;
  static const int maxPropertyReviewsPerLoad = 20;
  static const int maxHostPropertiesPerLoad = 50;
  static const int maxBookingsPerLoad = 30;
  static const int maxPropertySearchResults = 100;
  static const int maxNearbyPropertiesRadius = 50; // km
  static const int maxPropertyViewsToTrack = 1000;
  static const int maxFavoriteProperties = 100;

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
  
  // NEW: Property Rate Limiting Constants
  static const int maxPropertyUploadsPerDay = 5;
  static const int maxPropertyCommentsPerMinute = 3;
  static const int maxPropertyLikesPerMinute = 30;
  static const int maxPropertyInquiriesPerDay = 20;
  static const int maxPropertyReviewsPerDay = 5;
  static const int maxPropertySearchQueriesPerMinute = 20;
  static const int maxPropertyReportsPerDay = 5;
  static const int maxBookingRequestsPerDay = 10;
  static const int maxPropertyViewsPerHour = 100;
  static const int maxHostContactsPerDay = 15;
  
  // ===================== CACHE DURATION (in minutes) =====================
  static const int videoCacheDuration = 30;
  static const int userCacheDuration = 60;
  static const int commentsCacheDuration = 10;
  static const int feedCacheDuration = 15;
  static const int searchCacheDuration = 60;
  static const int trendingCacheDuration = 30;
  
  // NEW: Property Cache Duration
  static const int propertyCacheDuration = 45;
  static const int propertyCommentsCacheDuration = 15;
  static const int propertyFeedCacheDuration = 20;
  static const int propertySearchCacheDuration = 90;
  static const int hostPropertiesCacheDuration = 60;
  static const int propertyAnalyticsCacheDuration = 120;
  static const int bookingsCacheDuration = 30;
  static const int propertyLocationCacheDuration = 180;
  static const int hostProfileCacheDuration = 60;
  
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
  
  // NEW: Property Error Messages
  static const String propertyCreateError = 'Failed to create property listing. Please try again.';
  static const String propertyUpdateError = 'Failed to update property. Please try again.';
  static const String propertyDeleteError = 'Failed to delete property. Please try again.';
  static const String propertyLoadError = 'Failed to load properties. Please try again.';
  static const String propertyLikeError = 'Failed to like property. Please try again.';
  static const String propertyCommentError = 'Failed to post comment. Please try again.';
  static const String propertyInquiryError = 'Failed to send inquiry. Please try again.';
  static const String propertyBookingError = 'Failed to create booking. Please try again.';
  static const String propertyReviewError = 'Failed to submit review. Please try again.';
  static const String propertySearchError = 'Property search failed. Please try again.';
  static const String propertyLocationError = 'Failed to get location. Please enable location services.';
  static const String propertyUploadError = 'Failed to upload property media. Please try again.';
  static const String hostVerificationError = 'Host verification failed. Please try again.';
  static const String bookingCancelError = 'Failed to cancel booking. Please try again.';
  static const String paymentError = 'Payment failed. Please try again.';
  static const String hostModeError = 'Failed to enable host mode. Please try again.';
  
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
  
  // NEW: Property Success Messages
  static const String propertyCreated = 'Property listing created successfully!';
  static const String propertyUpdated = 'Property updated successfully!';
  static const String propertyDeleted = 'Property deleted successfully!';
  static const String propertySubmitted = 'Property submitted for review!';
  static const String propertyPublished = 'Property published successfully!';
  static const String propertyLiked = 'Property liked!';
  static const String propertyCommentAdded = 'Comment added successfully!';
  static const String propertyInquirySent = 'Inquiry sent successfully!';
  static const String propertyBookingCreated = 'Booking request sent successfully!';
  static const String propertyReviewSubmitted = 'Review submitted successfully!';
  static const String propertyShared = 'Property shared successfully!';
  static const String propertyFavorited = 'Property added to favorites!';
  static const String hostModeEnabled = 'Host mode enabled successfully!';
  static const String hostVerificationSubmitted = 'Verification documents submitted!';
  static const String hostProfileUpdated = 'Host profile updated successfully!';
  static const String bookingConfirmed = 'Booking confirmed successfully!';
  static const String bookingCanceled = 'Booking canceled successfully!';
  static const String paymentSuccessful = 'Payment processed successfully!';
  
  // ===================== GUEST MODE MESSAGES =====================
  static const String guestModeRestriction = 'Sign in to access this feature';
  static const String guestModePrompt = 'Create an account to like, comment, and share videos';
  static const String guestModeUploadPrompt = 'Sign in to upload your own videos';
  static const String guestModeFollowPrompt = 'Sign in to follow your favorite creators';
  static const String guestModeCommentPrompt = 'Sign in to join the conversation';
  
  // NEW: Property Guest Mode Messages
  static const String guestPropertyLikePrompt = 'Sign in to like properties';
  static const String guestPropertyCommentPrompt = 'Sign in to comment on properties';
  static const String guestPropertyInquiryPrompt = 'Sign in to contact hosts';
  static const String guestPropertyBookingPrompt = 'Sign in to book properties';
  static const String guestPropertyFavoritePrompt = 'Sign in to save favorite properties';
  static const String guestHostModePrompt = 'Sign in to become a host';
  static const String guestPropertyReviewPrompt = 'Sign in to write reviews';
  static const String guestPropertySavePrompt = 'Sign in to save searches';

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
  
  // NEW: Property Validation Messages
  static const String propertyTitleTooShort = 'Property title must be at least 10 characters';
  static const String propertyTitleTooLong = 'Property title cannot exceed 100 characters';
  static const String propertyDescriptionTooShort = 'Description must be at least 50 characters';
  static const String propertyDescriptionTooLong = 'Description cannot exceed 1000 characters';
  static const String propertyAddressTooLong = 'Address cannot exceed 200 characters';
  static const String propertyPriceInvalid = 'Please enter a valid price';
  static const String propertyPriceTooLow = 'Price must be at least KES 100';
  static const String propertyPriceTooHigh = 'Price cannot exceed KES 1,000,000';
  static const String propertyVideoTooShort = 'Property video must be at least 10 seconds';
  static const String propertyVideoTooLong = 'Property video cannot exceed 5 minutes';
  static const String propertyImageLimitExceeded = 'You can upload maximum 20 images';
  static const String propertyLocationRequired = 'Property location is required';
  static const String propertyBedroomsInvalid = 'Number of bedrooms must be 0 or greater';
  static const String propertyBathroomsInvalid = 'Number of bathrooms must be at least 1';
  static const String propertyGuestsInvalid = 'Maximum guests must be at least 1';
  static const String propertyAmenitiesRequired = 'Please select at least one amenity';
  static const String propertyAvailabilityRequired = 'Please set property availability';
  static const String hostBioTooShort = 'Host bio must be at least 20 characters';
  static const String hostBioTooLong = 'Host bio cannot exceed 300 characters';
  static const String propertyReviewTooShort = 'Review must be at least 20 characters';
  static const String propertyReviewTooLong = 'Review cannot exceed 500 characters';
  static const String invalidRating = 'Please provide a valid rating';
  static const String checkInDateRequired = 'Check-in date is required';
  static const String checkOutDateRequired = 'Check-out date is required';
  static const String invalidDateRange = 'Check-out date must be after check-in date';
  static const String guestsCountRequired = 'Number of guests is required';
  
  // ===================== APP URLS =====================
  static const String websiteUrl = 'https://weibao.app';
  static const String privacyPolicyUrl = 'https://weibao.app/privacy';
  static const String termsOfServiceUrl = 'https://weibao.app/terms';
  static const String supportUrl = 'https://weibao.app/support';
  static const String feedbackUrl = 'https://weibao.app/feedback';
  static const String communityGuidelinesUrl = 'https://weibao.app/guidelines';
  static const String downloadUrl = 'https://weibao.app/download';

  // NEW: Property URLs
  static const String hostGuidelinesUrl = 'https://weibao.app/host-guidelines';
  static const String hostTermsUrl = 'https://weibao.app/host-terms';
  static const String bookingPolicyUrl = 'https://weibao.app/booking-policy';
  static const String cancellationPolicyUrl = 'https://weibao.app/cancellation-policy';
  static const String hostHelpUrl = 'https://weibao.app/host-help';
  static const String guestHelpUrl = 'https://weibao.app/guest-help';
  static const String safetyGuidelinesUrl = 'https://weibao.app/safety';
  static const String propertyStandardsUrl = 'https://weibao.app/property-standards';

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

  // NEW: Property Feature Flags
  static const bool enablePropertyFeature = true;
  static const bool enableHostMode = true;
  static const bool enablePropertyBooking = true;
  static const bool enablePropertyReviews = true;
  static const bool enablePropertyMap = true;
  static const bool enablePropertyAnalytics = true;
  static const bool enablePropertySharing = true;
  static const bool enablePropertyComments = true;
  static const bool enablePropertyLikes = true;
  static const bool enablePropertyInquiries = true;
  static const bool enablePropertyFilters = true;
  static const bool enablePropertySearch = true;
  static const bool enableHostVerification = true;
  static const bool enablePaymentIntegration = true;
  static const bool enablePropertySubscription = true;
  static const bool enablePropertyReporting = true;
  static const bool enableGeoLocation = true;
  static const bool enablePushNotificationsForBookings = true;

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

  // NEW: Property Analytics Events
  static const String eventPropertyView = 'property_view';
  static const String eventPropertyLike = 'property_like';
  static const String eventPropertyComment = 'property_comment';
  static const String eventPropertyShare = 'property_share';
  static const String eventPropertyInquiry = 'property_inquiry';
  static const String eventPropertyBooking = 'property_booking';
  static const String eventPropertyReview = 'property_review';
  static const String eventPropertyCreate = 'property_create';
  static const String eventPropertyUpdate = 'property_update';
  static const String eventPropertyDelete = 'property_delete';
  static const String eventPropertySearch = 'property_search';
  static const String eventPropertyFilter = 'property_filter';
  static const String eventHostModeEnable = 'host_mode_enable';
  static const String eventHostVerificationStart = 'host_verification_start';
  static const String eventHostVerificationComplete = 'host_verification_complete';
  static const String eventBookingConfirm = 'booking_confirm';
  static const String eventBookingCancel = 'booking_cancel';
  static const String eventPaymentInitiate = 'payment_initiate';
  static const String eventPaymentComplete = 'payment_complete';
  static const String eventPropertyMapView = 'property_map_view';
  static const String eventPropertyFavorite = 'property_favorite';
  static const String eventPropertyUnfavorite = 'property_unfavorite';
  static const String eventPropertyReport = 'property_report';
  static const String eventHostContactClick = 'host_contact_click';
  static const String eventWhatsappRedirect = 'whatsapp_redirect';

  // ===================== NOTIFICATION TYPES =====================
  static const String notificationLike = 'like';
  static const String notificationComment = 'comment';
  static const String notificationFollow = 'follow';
  static const String notificationMention = 'mention';
  static const String notificationVideoUpload = 'video_upload';
  static const String notificationGift = 'gift';
  static const String notificationSystem = 'system';
  static const String notificationPromotion = 'promotion';
  static const String notificationPriceAlert = 'price_alert';
  static const String notificationCategoryTrending = 'category_trending';

  // NEW: Property Notification Types
  static const String notificationPropertyLike = 'property_like';
  static const String notificationPropertyComment = 'property_comment';
  static const String notificationPropertyInquiry = 'property_inquiry';
  static const String notificationPropertyBooking = 'property_booking';
  static const String notificationPropertyReview = 'property_review';
  static const String notificationBookingConfirmation = 'booking_confirmation';
  static const String notificationBookingCancellation = 'booking_cancellation';
  static const String notificationBookingReminder = 'booking_reminder';
  static const String notificationPaymentReceived = 'payment_received';
  static const String notificationPaymentDue = 'payment_due';
  static const String notificationHostVerificationUpdate = 'host_verification_update';
  static const String notificationPropertyApproved = 'property_approved';
  static const String notificationPropertyRejected = 'property_rejected';
  static const String notificationPropertyExpiring = 'property_expiring';
  static const String notificationNewPropertyNearby = 'new_property_nearby';
  static const String notificationPriceDropAlert = 'price_drop_alert';
  static const String notificationAvailabilityAlert = 'availability_alert';
  static const String notificationGuestMessage = 'guest_message';
  static const String notificationHostMessage = 'host_message';

  // ===================== CONTENT MODERATION =====================
  static const List<String> bannedWords = [
    // Add content moderation words here
    'spam', 'fake', 'scam', 'hate', 'violence'
  ];
  
  static const List<String> restrictedHashtags = [
    // Add restricted hashtags here
    'hate', 'violence', 'spam'
  ];

  // Restricted categories (for content moderation)
  static const List<String> restrictedCategories = [
    // Categories that require special approval or moderation
  ];

  // NEW: Property Content Moderation
  static const List<String> bannedPropertyWords = [
    'scam', 'fake', 'fraud', 'illegal', 'drugs', 'violence', 'hate'
  ];
  
  static const List<String> restrictedPropertyTags = [
    'adult', 'illegal', 'dangerous', 'inappropriate'
  ];

  // Property amenities that require verification
  static const List<String> verificationRequiredAmenities = [
    'pool', 'gym', 'security', 'parking', 'wifi'
  ];

  // ===================== VIDEO EFFECTS & FILTERS =====================
  static const List<String> videoFilters = [
    'none', 'vintage', 'black_white', 'sepia', 'bright', 'contrast', 'warm', 'cool'
  ];
  
  static const List<String> videoEffects = [
    'none', 'slow_motion', 'fast_forward', 'reverse', 'time_lapse', 'boomerang'
  ];

  // NEW: Property Video Effects & Filters
  static const List<String> propertyVideoFilters = [
    'none', 'bright', 'contrast', 'warm', 'natural', 'professional', 'cozy', 'modern'
  ];
  
  static const List<String> propertyVideoEffects = [
    'none', 'pan', 'zoom', 'fade', 'slide', 'tour', 'highlight'
  ];

  // ===================== DEEP LINK SCHEMES =====================
  static const String deepLinkScheme = 'weibao';
  static const String webLinkDomain = 'weibao.app';
  static const String appStoreId = '123456789'; // Replace with actual App Store ID
  static const String playStoreId = 'com.weibao.app'; // Replace with actual Play Store ID

  // NEW: Property Deep Link Paths
  static const String propertyDeepLinkPath = '/property';
  static const String hostDeepLinkPath = '/host';
  static const String bookingDeepLinkPath = '/booking';
  static const String searchDeepLinkPath = '/search';

  // ===================== MONETIZATION CONSTANTS =====================
  static const int coinsPerDollar = 100;
  static const int minimumWithdrawal = 1000; // coins
  static const double platformFeePercentage = 0.05; // 5%
  static const int giftPriceMin = 1; // coins
  static const int giftPriceMax = 10000; // coins
  
  // Marketplace constants
  static const double maxPrice = 10000000.0; // KES 10 Million maximum price
  static const double minPrice = 0.0; // Free items allowed
  static const double defaultPriceStep = 100.0; // Price increment steps
  static const List<double> suggestedPrices = [
    0, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 500000, 1000000
  ]; // Common price suggestions

  // NEW: Property Monetization Constants
  static const double propertySubscriptionMonthly = 2000.0; // KES per month
  static const double propertySubscriptionYearly = 20000.0; // KES per year (2 months free)
  static const double featuredPropertyFee = 5000.0; // KES per week
  static const double priorityListingFee = 1000.0; // KES per week
  static const double propertyPromotionFee = 3000.0; // KES per week
  static const double hostVerificationFee = 1500.0; // One-time KES
  static const double bookingPlatformFeePercentage = 0.03; // 3% of booking value
  static const double hostPayoutFeePercentage = 0.02; // 2% of payout
  static const double minimumBookingAmount = 1000.0; // KES
  static const double maximumBookingAmount = 500000.0; // KES
  static const int bookingAdvancePaymentPercentage = 30; // 30% advance payment
  static const int hostPayoutDelayDays = 2; // Days after check-in
  static const int refundProcessingDays = 5; // Days for refund processing

  // Pricing tiers for property subscriptions
  static const Map<String, double> propertySubscriptionTiers = {
    'basic': 2000.0,     // 1 property, basic features
    'standard': 5000.0,  // 3 properties, standard features
    'premium': 10000.0,  // 10 properties, all features
    'enterprise': 20000.0, // Unlimited properties, enterprise features
  };

  // ===================== SECURITY CONSTANTS =====================
  static const int passwordMinLength = 8;
  static const int maxFailedLoginAttempts = 5;
  static const int accountLockoutMinutes = 30;
  static const int sessionTimeoutMinutes = 60;
  static const bool requireBiometricForSensitiveActions = true;

  // NEW: Property Security Constants
  static const bool requireIdentityVerificationForHosts = true;
  static const bool requirePropertyDocumentation = true;
  static const int maxPropertyReportsBeforeSuspension = 5;
  static const int hostVerificationDocumentRetentionDays = 365;
  static const bool enablePropertyImageWatermarking = true;
  static const bool requireHostPhoneVerification = true;
  static const bool enableBookingRequireApproval = true;
  static const int maxBookingDaysInAdvance = 365;
  static const int minBookingHoursInAdvance = 2;

  // ===================== FILE SIZE LIMITS =====================
  static const int maxVideoSizeMB = 50;
  static const int maxImageSizeMB = 10;
  static const int maxThumbnailSizeMB = 2;
  static const int maxProfileImageSizeMB = 5;

  // NEW: Property File Size Limits
  static const int maxPropertyVideoSizeMB = 100;
  static const int maxPropertyImageSizeMB = 15;
  static const int maxPropertyThumbnailSizeMB = 3;
  static const int maxHostProfileImageSizeMB = 8;
  static const int maxPropertyDocumentSizeMB = 10;
  static const int maxVerificationDocumentSizeMB = 5;
  static const int maxReviewImageSizeMB = 5;

  // ===================== PERFORMANCE CONSTANTS =====================
  static const int maxCachedVideos = 50;
  static const int maxCachedImages = 100;
  static const int preloadVideosCount = 3;
  static const int videoBufferDurationSeconds = 10;
  static const double videoCompressionQuality = 0.8;

  // NEW: Property Performance Constants
  static const int maxCachedProperties = 100;
  static const int maxCachedPropertyImages = 200;
  static const int preloadPropertiesCount = 5;
  static const int propertyImageCompressionQuality = 85; // 0-100
  static const double propertyVideoCompressionQuality = 0.85;
  static const int maxMapMarkersToShow = 50;
  static const int propertySearchDebounceMs = 500;
  static const int locationUpdateIntervalSeconds = 30;
  static const double nearbyPropertiesRadiusKm = 10.0;

  // ===================== LOCALIZATION =====================
  static const String defaultLanguage = 'en';
  static const List<String> supportedLanguages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ko', 'sw'];
  
  // NEW: Property Localization
  static const String defaultCurrency = 'KES';
  static const List<String> supportedCurrencies = ['KES', 'USD', 'EUR', 'GBP'];
  static const String defaultCountry = 'Kenya';
  static const List<String> supportedCountries = ['Kenya', 'Uganda', 'Tanzania', 'Rwanda'];

  // ===================== THEME CONSTANTS =====================
  static const String defaultTheme = 'system';
  static const List<String> availableThemes = ['light', 'dark', 'system'];

  // ===================== PROPERTY TYPE DEFINITIONS =====================
  static const List<String> propertyTypes = [
    'apartment',
    'house',
    'room',
    'studio',
    'villa',
    'cottage',
    'loft',
    'townhouse',
    'penthouse',
    'cabin',
    'guesthouse',
    'hostel'
  ];

  // ===================== AMENITY DEFINITIONS =====================
  static const List<String> basicAmenities = [
    'wifi',
    'parking',
    'kitchen',
    'air_conditioning',
    'washing_machine',
    'tv',
    'heating',
    'hot_water'
  ];

  static const List<String> luxuryAmenities = [
    'pool',
    'gym',
    'spa',
    'sauna',
    'jacuzzi',
    'game_room',
    'home_theater',
    'wine_cellar'
  ];

  static const List<String> outdoorAmenities = [
    'balcony',
    'garden',
    'terrace',
    'patio',
    'bbq_grill',
    'outdoor_furniture',
    'fire_pit',
    'gazebo'
  ];

  static const List<String> safetyAmenities = [
    'security_cameras',
    'smoke_detector',
    'carbon_monoxide_detector',
    'first_aid_kit',
    'fire_extinguisher',
    'security_system',
    'doorman',
    'gated_community'
  ];

  // ===================== BOOKING STATUS DEFINITIONS =====================
  static const List<String> bookingStatuses = [
    'pending',        // Awaiting host approval
    'confirmed',      // Host approved
    'checked_in',     // Guest arrived
    'checked_out',    // Guest departed
    'canceled',       // Booking canceled
    'completed',      // Booking finished and reviewed
    'disputed',       // Issue with booking
    'refunded'        // Payment refunded
  ];

  // ===================== CANCELLATION POLICY TYPES =====================
  static const List<String> cancellationPolicies = [
    'flexible',       // Full refund 1 day before
    'moderate',       // Full refund 5 days before
    'strict',         // Full refund 14 days before
    'super_strict',   // 50% refund 30 days before
    'non_refundable'  // No refund
  ];

  // ===================== PROPERTY SEARCH FILTERS =====================
  static const List<String> priceRanges = [
    '0-1000',
    '1000-2500',
    '2500-5000',
    '5000-10000',
    '10000-25000',
    '25000-50000',
    '50000+'
  ];

  static const List<String> sortOptions = [
    'price_low_to_high',
    'price_high_to_low',
    'newest_first',
    'oldest_first',
    'most_liked',
    'most_viewed',
    'nearest_first',
    'rating_high_to_low'
  ];

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

  /// Format property type for display
  static String formatPropertyType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  /// Format amenity for display
  static String formatAmenity(String amenity) {
    return amenity.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  /// Get property type icon
  static String getPropertyTypeIcon(String type) {
    switch (type) {
      case 'apartment':
        return '🏢';
      case 'house':
        return '🏠';
      case 'room':
        return '🛏️';
      case 'studio':
        return '🏙️';
      case 'villa':
        return '🏡';
      case 'cottage':
        return '🏘️';
      case 'loft':
        return '🏗️';
      case 'townhouse':
        return '🏘️';
      case 'penthouse':
        return '🏢';
      case 'cabin':
        return '🏕️';
      case 'guesthouse':
        return '🏠';
      case 'hostel':
        return '🏨';
      default:
        return '🏠';
    }
  }

  /// Get amenity icon
  static String getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'wifi':
        return '📶';
      case 'parking':
        return '🚗';
      case 'kitchen':
        return '🍳';
      case 'air_conditioning':
        return '❄️';
      case 'washing_machine':
        return '🧺';
      case 'tv':
        return '📺';
      case 'pool':
        return '🏊';
      case 'gym':
        return '💪';
      case 'balcony':
        return '🌅';
      case 'garden':
        return '🌺';
      default:
        return '✅';
    }
  }

  /// Validate property price
  static bool isValidPropertyPrice(double price) {
    return price >= minPrice && price <= maxPrice;
  }

  /// Get booking status color
  static String getBookingStatusColor(String status) {
    switch (status) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'confirmed':
        return '#008000'; // Green
      case 'checked_in':
        return '#0000FF'; // Blue
      case 'checked_out':
        return '#800080'; // Purple
      case 'canceled':
        return '#FF0000'; // Red
      case 'completed':
        return '#008000'; // Green
      case 'disputed':
        return '#FF4500'; // Red Orange
      case 'refunded':
        return '#808080'; // Gray
      default:
        return '#000000'; // Black
    }
  }

  /// Calculate platform fee
  static double calculatePlatformFee(double amount) {
    return amount * bookingPlatformFeePercentage;
  }

  /// Calculate host payout
  static double calculateHostPayout(double bookingAmount) {
    final platformFee = calculatePlatformFee(bookingAmount);
    final hostFee = bookingAmount * hostPayoutFeePercentage;
    return bookingAmount - platformFee - hostFee;
  }

  /// Calculate advance payment amount
  static double calculateAdvancePayment(double totalAmount) {
    return totalAmount * (bookingAdvancePaymentPercentage / 100);
  }

  /// Get cancellation policy description
  static String getCancellationPolicyDescription(String policy) {
    switch (policy) {
      case 'flexible':
        return 'Full refund 1 day prior to arrival';
      case 'moderate':
        return 'Full refund 5 days prior to arrival';
      case 'strict':
        return 'Full refund 14 days prior to arrival';
      case 'super_strict':
        return '50% refund 30 days prior to arrival';
      case 'non_refundable':
        return 'No refund';
      default:
        return 'Contact host for cancellation policy';
    }
  }

  /// Format duration in days
  static String formatDuration(int days) {
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days == 7) return '1 week';
    if (days < 30) return '${(days / 7).round()} weeks';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }

  /// Generate property reference number
  static String generatePropertyReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'WB$timestamp$random';
  }

  /// Generate booking reference number
  static String generateBookingReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'BK$timestamp$random';
  }
}

// Extension for easy access to commonly used constants
extension ConstantsExtension on Constants {
  static String get appDisplayName => Constants.appName;
  static String get fullVersion => '${Constants.appVersion}+${Constants.appBuildNumber}';
  
  // NEW: Property-specific extensions
  static List<String> get allAmenities => [
    ...Constants.basicAmenities,
    ...Constants.luxuryAmenities,
    ...Constants.outdoorAmenities,
    ...Constants.safetyAmenities,
  ];
  
  static List<String> get essentialAmenities => [
    'wifi',
    'parking',
    'kitchen',
    'hot_water',
    'heating',
  ];
  
  static Map<String, List<String>> get amenitiesByCategory => {
    'Basic': Constants.basicAmenities,
    'Luxury': Constants.luxuryAmenities,
    'Outdoor': Constants.outdoorAmenities,
    'Safety': Constants.safetyAmenities,
  };
}