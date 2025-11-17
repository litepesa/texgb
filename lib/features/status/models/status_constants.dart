// ===============================
// Status Constants
// Configuration and constants for status feature
// ===============================

class StatusConstants {
  StatusConstants._();

  // ===============================
  // TIMING
  // ===============================

  // Status expiry duration (24 hours)
  static const Duration expiryDuration = Duration(hours: 24);

  // Default display durations (in seconds)
  static const int textStatusDuration = 5;
  static const int imageStatusDuration = 5;
  static const int videoStatusMinDuration = 1;
  static const int videoStatusMaxDuration = 30; // Max 30 seconds for status videos

  // Auto-advance delay between statuses (milliseconds)
  static const int autoAdvanceDelay = 300;

  // Progress indicator update interval (milliseconds)
  static const int progressUpdateInterval = 50;

  // ===============================
  // MEDIA
  // ===============================

  // Maximum file sizes
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50 MB

  // Image quality for compression
  static const int imageQuality = 85; // 0-100

  // Video compression quality
  static const String videoQuality = 'medium'; // low, medium, high

  // Thumbnail quality
  static const int thumbnailQuality = 70;
  static const int thumbnailMaxWidth = 400;
  static const int thumbnailMaxHeight = 400;

  // ===============================
  // UI
  // ===============================

  // Status ring sizes
  static const double ringAvatarSize = 64.0;
  static const double ringBorderWidth = 3.0;
  static const double ringSpacing = 12.0;

  // Status viewer
  static const double viewerProgressHeight = 2.0;
  static const double viewerProgressSpacing = 4.0;
  static const double viewerPadding = 16.0;

  // Interaction button sizes
  static const double interactionButtonSize = 48.0;
  static const double interactionIconSize = 28.0;
  static const double interactionSpacing = 12.0;

  // Text status
  static const double textStatusMaxWidth = 340.0;
  static const double textStatusMinFontSize = 20.0;
  static const double textStatusMaxFontSize = 32.0;
  static const int textStatusMaxLength = 200;

  // ===============================
  // COLORS
  // ===============================

  // Ring gradient colors (viewed vs unviewed)
  static const List<String> unviewedGradient = ['#FF6B6B', '#4ECDC4']; // Red to Teal
  static const List<String> viewedGradient = ['#9CA3AF', '#9CA3AF']; // Gray

  // My status ring color
  static const List<String> myStatusGradient = ['#3B82F6', '#8B5CF6']; // Blue to Purple

  // ===============================
  // LIMITS
  // ===============================

  // Maximum number of statuses per user
  static const int maxStatusesPerUser = 10;

  // Maximum visible contacts in status list (before "load more")
  static const int maxVisibleContacts = 20;

  // Cache configuration
  static const int maxCachedStatuses = 50;
  static const Duration cacheDuration = Duration(hours: 1);

  // ===============================
  // PRIVACY
  // ===============================

  // Show view count but not viewer names (privacy enhancement)
  static const bool showViewerNames = false;
  static const bool showViewCount = true;

  // ===============================
  // INTERACTION TYPES
  // ===============================

  static const String interactionTypeLike = 'like';
  static const String interactionTypeGift = 'gift';
  static const String interactionTypeSave = 'save';
  static const String interactionTypeDM = 'dm';
  static const String interactionTypeView = 'view';

  // ===============================
  // ERROR MESSAGES
  // ===============================

  static const String errorUploadFailed = 'Failed to upload status';
  static const String errorDeleteFailed = 'Failed to delete status';
  static const String errorLoadFailed = 'Failed to load statuses';
  static const String errorExpired = 'This status has expired';
  static const String errorTooLarge = 'File is too large';
  static const String errorInvalidFormat = 'Invalid file format';
  static const String errorNoPermission = 'No permission to view this status';

  // ===============================
  // SUCCESS MESSAGES
  // ===============================

  static const String successUploaded = 'Status uploaded successfully';
  static const String successDeleted = 'Status deleted';
  static const String successSaved = 'Status saved to gallery';
  static const String successGiftSent = 'Gift sent';

  // ===============================
  // API ENDPOINTS (relative to base URL)
  // ===============================

  static const String apiGetStatuses = '/statuses';
  static const String apiGetMyStatuses = '/statuses/me';
  static const String apiGetUserStatuses = '/statuses/user';
  static const String apiCreateStatus = '/statuses';
  static const String apiDeleteStatus = '/statuses';
  static const String apiViewStatus = '/statuses/{id}/view';
  static const String apiLikeStatus = '/statuses/{id}/like';
  static const String apiUnlikeStatus = '/statuses/{id}/unlike';
  static const String apiSendGift = '/gifts/send';
  static const String apiUploadMedia = '/upload/status';
}
