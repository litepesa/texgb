// lib/features/properties/constants/property_constants.dart

class PropertyConstants {
  // ===================== PROPERTY ROUTE CONSTANTS =====================
  static const String propertyFeedScreen = '/properties';
  static const String propertyDetailsScreen = '/property-details';
  static const String propertySearchScreen = '/property-search';
  static const String propertyFiltersScreen = '/property-filters';
  
  // Host Dashboard Routes
  static const String hostDashboardScreen = '/host-dashboard';
  static const String createPropertyScreen = '/create-property';
  static const String editPropertyScreen = '/edit-property';
  static const String hostPropertiesScreen = '/host-properties';
  static const String propertyAnalyticsScreen = '/property-analytics';
  static const String hostInquiriesScreen = '/host-inquiries';
  
  // Discovery Routes
  static const String trendingPropertiesScreen = '/trending-properties';
  static const String featuredPropertiesScreen = '/featured-properties';
  static const String propertiesByCityScreen = '/properties-by-city';
  
  // ===================== NAVIGATION ARGUMENTS =====================
  static const String propertyId = 'propertyId';
  static const String propertyModel = 'propertyModel';
  static const String hostId = 'hostId';
  static const String city = 'city';
  static const String propertyType = 'propertyType';
  static const String searchQuery = 'searchQuery';
  static const String filters = 'filters';
  static const String initialPropertyId = 'initialPropertyId';
  static const String isEditing = 'isEditing';
  static const String fromDashboard = 'fromDashboard';
  
  // ===================== SHARED PREFERENCES KEYS =====================
  static const String cachedPropertiesKey = 'cached_properties';
  static const String cachedHostPropertiesKey = 'cached_host_properties';
  static const String propertyFiltersKey = 'property_filters';
  static const String propertySearchHistoryKey = 'property_search_history';
  static const String lastPropertyViewKey = 'last_property_view';
  static const String propertyNotificationsKey = 'property_notifications';
  static const String hostPreferencesKey = 'host_preferences';
  
  // ===================== STORAGE PATHS =====================
  static const String propertyVideosPath = 'properties/videos';
  static const String propertyImagesPath = 'properties/images';
  static const String propertyThumbnailsPath = 'properties/thumbnails';
  static const String hostProfilesPath = 'properties/hosts';
  static const String propertyDocumentsPath = 'properties/documents';
  
  // ===================== PROPERTY BUSINESS RULES =====================
  
  // Subscription & Billing
  static const double subscriptionFeeKES = 8000.0; // Annual fee per property listing
  static const int subscriptionDurationDays = 365; // 1 year
  static const int subscriptionReminderDays = 30; // Remind 30 days before expiry
  static const int gracePeriodDays = 7; // Grace period after expiry
  
  // Property Listing Limits
  static const int maxPropertiesPerHost = 50; // Maximum properties per host
  static const int maxImagesPerProperty = 20; // Maximum images per property
  static const int maxVideoDurationMinutes = 2; // Maximum video length (2 minutes)
  static const int maxVideoSizeMB = 100; // Maximum video file size
  static const int minVideoDurationSeconds = 10; // Minimum video length
  
  // Property Content Limits
  static const int maxTitleLength = 100;
  static const int minTitleLength = 10;
  static const int maxDescriptionLength = 1000;
  static const int minDescriptionLength = 50;
  static const int maxTagsCount = 10;
  static const int maxAmenitiesCount = 30;
  
  // Property Rules
  static const int maxGuestsLimit = 20; // Maximum guests per property
  static const int maxBedroomsLimit = 10; // Maximum bedrooms
  static const int maxBathroomsLimit = 10; // Maximum bathrooms
  static const double maxRatePerNightKES = 500000.0; // Maximum rate (KES 500,000)
  static const double minRatePerNightKES = 100.0; // Minimum rate (KES 100)
  
  // ===================== ENGAGEMENT LIMITS =====================
  static const int maxCommentsPerLoad = 50;
  static const int maxLikesPerProperty = 999999;
  static const int maxViewsPerProperty = 999999999;
  static const int maxInquiriesPerDay = 100; // Per user per day
  static const int maxPropertiesPerFeedLoad = 20;
  
  // Rate Limiting
  static const int maxPropertyCreationsPerDay = 5; // Per host
  static const int maxPropertyUpdatesPerDay = 20; // Per host
  static const int maxInquiriesPerHour = 10; // Per user
  static const int maxLikesPerMinute = 30; // Per user
  static const int maxCommentsPerHour = 50; // Per user
  
  // ===================== CACHE DURATIONS (minutes) =====================
  static const int propertyFeedCacheDuration = 15;
  static const int propertyDetailsCacheDuration = 60;
  static const int hostPropertiesCacheDuration = 30;
  static const int propertyAnalyticsCacheDuration = 120; // 2 hours
  static const int searchResultsCacheDuration = 30;
  static const int citiesCacheDuration = 1440; // 24 hours
  
  // ===================== UI CONSTANTS =====================
  
  // Feed UI
  static const double propertyVideoHeight = 600.0; // TikTok-style height
  static const double propertyVideoAspectRatio = 9 / 16; // Vertical aspect ratio
  static const double propertyInfoOverlayHeight = 200.0;
  static const double actionsSidebarWidth = 80.0;
  
  // Cards & Lists
  static const double propertyCardHeight = 300.0;
  static const double propertyCardWidth = 250.0;
  static const double propertyThumbnailHeight = 200.0;
  static const double hostAvatarSize = 50.0;
  static const double propertyIconSize = 24.0;
  
  // Forms
  static const double formFieldHeight = 56.0;
  static const double formSectionSpacing = 24.0;
  static const double formButtonHeight = 48.0;
  static const double imagePickerHeight = 120.0;
  static const double amenityChipHeight = 36.0;
  
  // Analytics
  static const double chartHeight = 200.0;
  static const double metricCardHeight = 100.0;
  static const double analyticsGridSpacing = 16.0;
  
  // ===================== VALIDATION MESSAGES =====================
  static const String titleRequired = 'Property title is required';
  static const String titleTooShort = 'Title must be at least 10 characters';
  static const String titleTooLong = 'Title cannot exceed 100 characters';
  static const String descriptionRequired = 'Property description is required';
  static const String descriptionTooShort = 'Description must be at least 50 characters';
  static const String descriptionTooLong = 'Description cannot exceed 1000 characters';
  static const String rateRequired = 'Rate per night is required';
  static const String rateInvalid = 'Please enter a valid rate between KES 100 and KES 500,000';
  static const String videoRequired = 'Property video is required';
  static const String videoTooLong = 'Video cannot exceed 2 minutes';
  static const String videoTooShort = 'Video must be at least 10 seconds';
  static const String videoTooLarge = 'Video file size cannot exceed 100MB';
  static const String addressRequired = 'Property address is required';
  static const String cityRequired = 'City is required';
  static const String countyRequired = 'County is required';
  static const String bedroomsInvalid = 'Number of bedrooms must be between 0 and 10';
  static const String bathroomsInvalid = 'Number of bathrooms must be between 1 and 10';
  static const String guestsInvalid = 'Maximum guests must be between 1 and 20';
  static const String whatsappInvalid = 'Please enter a valid WhatsApp number (254XXXXXXXXX)';
  static const String availabilityRequired = 'At least one availability period is required';
  
  // ===================== ERROR MESSAGES =====================
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authenticationError = 'Authentication failed. Please login again.';
  static const String permissionError = 'Permission denied. Please grant required permissions.';
  static const String subscriptionExpiredError = 'Your property subscription has expired. Please renew to continue.';
  static const String hostOnlyError = 'Only hosts can perform this action.';
  static const String propertyNotFoundError = 'Property not found.';
  static const String hostNotFoundError = 'Host not found.';
  static const String propertyCreateError = 'Failed to create property listing.';
  static const String propertyUpdateError = 'Failed to update property listing.';
  static const String propertyDeleteError = 'Failed to delete property listing.';
  static const String videoUploadError = 'Failed to upload property video.';
  static const String imageUploadError = 'Failed to upload property images.';
  static const String likeError = 'Failed to like property.';
  static const String commentError = 'Failed to add comment.';
  static const String inquiryError = 'Failed to record inquiry.';
  static const String searchError = 'Search failed. Please try again.';
  static const String analyticsError = 'Failed to load analytics data.';
  static const String subscriptionError = 'Failed to process subscription payment.';
  
  // ===================== SUCCESS MESSAGES =====================
  static const String propertyCreated = 'Property listing created successfully!';
  static const String propertyUpdated = 'Property listing updated successfully!';
  static const String propertyDeleted = 'Property listing deleted successfully!';
  static const String propertySubmitted = 'Property submitted for admin review!';
  static const String videoUploaded = 'Property video uploaded successfully!';
  static const String imagesUploaded = 'Property images uploaded successfully!';
  static const String propertyLiked = 'Property liked!';
  static const String propertyUnliked = 'Property unliked!';
  static const String commentAdded = 'Comment added successfully!';
  static const String inquiryRecorded = 'Inquiry sent to host!';
  static const String subscriptionRenewed = 'Subscription renewed successfully!';
  static const String availabilityUpdated = 'Availability updated successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  
  // ===================== GUEST MODE MESSAGES =====================
  static const String guestModePropertyRestriction = 'Sign in to view property details';
  static const String guestModeLikePrompt = 'Sign in to like properties';
  static const String guestModeCommentPrompt = 'Sign in to comment on properties';
  static const String guestModeInquiryPrompt = 'Sign in to contact hosts';
  static const String guestModeCreatePrompt = 'Sign in to create property listings';
  static const String guestModeHostPrompt = 'Sign in as a host to access this feature';
  
  // ===================== PROPERTY STATUS MESSAGES =====================
  static const String statusDraft = 'Draft - Complete your listing to submit for review';
  static const String statusPending = 'Pending Review - Your listing is under admin review';
  static const String statusVerified = 'Active - Your listing is live and visible to users';
  static const String statusRejected = 'Rejected - Please check admin feedback and resubmit';
  static const String statusInactive = 'Inactive - Your listing has been deactivated';
  static const String statusExpired = 'Expired - Please renew your subscription to reactivate';
  
  // ===================== PROPERTY TYPES =====================
  static const List<String> propertyTypeLabels = [
    'Room',
    'Apartment', 
    'House',
    'Studio',
    'Villa',
    'Cottage',
  ];
  
  static const List<String> propertyTypeDescriptions = [
    'A single room in a shared space',
    'A self-contained apartment unit',
    'An entire house for guests',
    'A compact studio apartment',
    'A luxury villa with premium amenities',
    'A cozy cottage retreat',
  ];
  
  // ===================== AMENITIES CATEGORIES =====================
  static const List<String> basicAmenities = [
    'WiFi',
    'Parking',
    'Kitchen',
    'Air Conditioning',
    'Washing Machine',
    'TV',
  ];
  
  static const List<String> luxuryAmenities = [
    'Pool',
    'Gym',
    'Balcony',
    'Garden',
    'Spa',
    'Home Theater',
  ];
  
  static const List<String> safetyAmenities = [
    'Security Guard',
    'CCTV',
    'Fire Extinguisher',
    'First Aid Kit',
    'Smoke Detector',
    'Emergency Exit',
  ];
  
  // ===================== KENYAN COUNTIES =====================
  static const List<String> kenyanCounties = [
    'Nairobi',
    'Mombasa',
    'Kiambu',
    'Nakuru',
    'Kajiado',
    'Machakos',
    'Meru',
    'Kisumu',
    'Uasin Gishu',
    'Laikipia',
    'Nyeri',
    'Murang\'a',
    'Kilifi',
    'Kwale',
    'Kakamega',
    'Bungoma',
    'Kericho',
    'Bomet',
    'Nandi',
    'Trans Nzoia',
    'Elgeyo-Marakwet',
    'West Pokot',
    'Baringo',
    'Turkana',
    'Samburu',
    'Isiolo',
    'Marsabit',
    'Mandera',
    'Wajir',
    'Garissa',
    'Tana River',
    'Lamu',
    'Taita-Taveta',
    'Makueni',
    'Kitui',
    'Embu',
    'Tharaka-Nithi',
    'Kirinyaga',
    'Nyandarua',
    'Vihiga',
    'Busia',
    'Siaya',
    'Kisii',
    'Nyamira',
    'Migori',
    'Homa Bay',
    'Narok',
  ];
  
  // ===================== MAJOR KENYAN CITIES =====================
  static const List<String> majorKenyanCities = [
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
    'Thika',
    'Malindi',
    'Kitale',
    'Garissa',
    'Kakamega',
    'Machakos',
    'Meru',
    'Nyeri',
    'Kericho',
    'Naivasha',
    'Voi',
    'Kilifi',
    'Lamu',
    'Isiolo',
    'Nanyuki',
  ];
  
  // ===================== ANALYTICS EVENTS =====================
  static const String eventPropertyView = 'property_view';
  static const String eventPropertyLike = 'property_like';
  static const String eventPropertyComment = 'property_comment';
  static const String eventPropertyInquiry = 'property_inquiry';
  static const String eventPropertyShare = 'property_share';
  static const String eventPropertyCreate = 'property_create';
  static const String eventPropertyUpdate = 'property_update';
  static const String eventPropertyDelete = 'property_delete';
  static const String eventPropertySearch = 'property_search';
  static const String eventPropertyFilter = 'property_filter';
  static const String eventHostDashboardView = 'host_dashboard_view';
  static const String eventSubscriptionRenewal = 'subscription_renewal';
  static const String eventWhatsAppRedirect = 'whatsapp_redirect';
  
  // ===================== NOTIFICATION TYPES =====================
  static const String notificationPropertyLiked = 'property_liked';
  static const String notificationPropertyCommented = 'property_commented';
  static const String notificationPropertyInquiry = 'property_inquiry';
  static const String notificationPropertyApproved = 'property_approved';
  static const String notificationPropertyRejected = 'property_rejected';
  static const String notificationSubscriptionExpiring = 'subscription_expiring';
  static const String notificationSubscriptionExpired = 'subscription_expired';
  static const String notificationNewMessage = 'new_message';
  
  // ===================== PROPERTY HELPER METHODS =====================
  
  /// Format property rate for display
  static String formatRate(double rate) {
    if (rate < 1000) {
      return 'KES ${rate.toInt()}';
    } else if (rate < 1000000) {
      return 'KES ${(rate / 1000).toStringAsFixed(rate % 1000 == 0 ? 0 : 1)}k';
    } else {
      return 'KES ${(rate / 1000000).toStringAsFixed(1)}M';
    }
  }
  
  /// Format guest count
  static String formatGuestCount(int guests) {
    if (guests == 1) return '1 guest';
    return '$guests guests';
  }
  
  /// Format bedroom count
  static String formatBedroomCount(int bedrooms) {
    if (bedrooms == 0) return 'Studio';
    if (bedrooms == 1) return '1 bedroom';
    return '$bedrooms bedrooms';
  }
  
  /// Format bathroom count
  static String formatBathroomCount(int bathrooms) {
    if (bathrooms == 1) return '1 bathroom';
    return '$bathrooms bathrooms';
  }
  
  /// Format view count
  static String formatViewCount(int views) {
    if (views < 1000) {
      return views.toString();
    } else if (views < 1000000) {
      return '${(views / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(views / 1000000).toStringAsFixed(1)}m';
    }
  }
  
  /// Format like count
  static String formatLikeCount(int likes) {
    return formatViewCount(likes); // Same formatting logic
  }
  
  /// Format comment count
  static String formatCommentCount(int comments) {
    return formatViewCount(comments); // Same formatting logic
  }
  
  /// Validate WhatsApp number format (Kenyan)
  static bool isValidWhatsAppNumber(String number) {
    // Remove any non-digit characters
    String cleanedNumber = number.replaceAll(RegExp(r'\D'), '');
    
    // Check if it's a valid Kenyan number format
    if (cleanedNumber.length == 12 && cleanedNumber.startsWith('254')) {
      return true;
    }
    
    // Check if it's in local format (0XXXXXXXXX) and convert
    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) {
      return true;
    }
    
    // Check if it's without country code (9 digits)
    if (cleanedNumber.length == 9) {
      return true;
    }
    
    return false;
  }
  
  /// Format WhatsApp number to international format
  static String formatWhatsAppNumber(String number) {
    String cleanedNumber = number.replaceAll(RegExp(r'\D'), '');
    
    if (cleanedNumber.length == 12 && cleanedNumber.startsWith('254')) {
      return cleanedNumber;
    }
    
    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) {
      return '254${cleanedNumber.substring(1)}';
    }
    
    if (cleanedNumber.length == 9) {
      return '254$cleanedNumber';
    }
    
    return cleanedNumber;
  }
  
  /// Generate WhatsApp link
  static String generateWhatsAppLink(String number, {String? message}) {
    String formattedNumber = formatWhatsAppNumber(number);
    String baseUrl = 'https://wa.me/$formattedNumber';
    
    if (message != null && message.isNotEmpty) {
      String encodedMessage = Uri.encodeComponent(message);
      return '$baseUrl?text=$encodedMessage';
    }
    
    return baseUrl;
  }
  
  /// Check if property is available on a specific date
  static bool isPropertyAvailableOnDate(
    List<Map<String, dynamic>> availabilityPeriods,
    DateTime date,
  ) {
    for (var period in availabilityPeriods) {
      DateTime startDate = DateTime.parse(period['startDate']);
      DateTime endDate = DateTime.parse(period['endDate']);
      bool isAvailable = period['isAvailable'] ?? true;
      
      if (isAvailable &&
          date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        return true;
      }
    }
    return false;
  }
  
  /// Calculate days until subscription expires
  static int daysUntilExpiry(DateTime expiryDate) {
    return expiryDate.difference(DateTime.now()).inDays;
  }
  
  /// Check if subscription is expiring soon
  static bool isSubscriptionExpiringSoon(DateTime expiryDate) {
    return daysUntilExpiry(expiryDate) <= subscriptionReminderDays;
  }
  
  /// Check if subscription has expired
  static bool isSubscriptionExpired(DateTime expiryDate) {
    return DateTime.now().isAfter(expiryDate);
  }
  
  /// Generate property deep link
  static String generatePropertyDeepLink(String propertyId) {
    return 'weibao://property/$propertyId';
  }
  
  /// Generate property share text
  static String generatePropertyShareText(String propertyTitle, String propertyId) {
    return 'Check out this amazing property: $propertyTitle\n\nView on WeiBao: ${generatePropertyDeepLink(propertyId)}';
  }
}