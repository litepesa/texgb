// ===============================
// Moment Feature Constants
// ===============================

class MomentConstants {
  // Media limits
  static const int maxImages = 9;
  static const int maxVideoDurationSeconds = 120; // 2 minutes
  static const int maxTextLength = 2000;
  static const int maxCommentLength = 200;

  // Image specifications
  static const double maxImageSizeMB = 10.0;
  static const int imageQuality = 85;
  static const int maxImageDimension = 1920;

  // Video specifications
  static const double maxVideoSizeMB = 100.0;
  static const int videoQuality = 85;

  // UI Constants
  static const int feedPageSize = 20;
  static const int commentsPageSize = 50;
  static const int userMomentsPageSize = 30;

  // Cache durations
  static const Duration feedCacheDuration = Duration(minutes: 5);
  static const Duration userMomentsCacheDuration = Duration(minutes: 10);
  static const Duration privacySettingsCacheDuration = Duration(hours: 1);

  // Animation durations
  static const Duration likeAnimationDuration = Duration(milliseconds: 300);
  static const Duration cardAnimationDuration = Duration(milliseconds: 200);

  // Refresh thresholds
  static const Duration backgroundRefreshInterval = Duration(minutes: 10);

  // Grid layout
  static const double imageGridSpacing = 4.0;
  static const double imageGridCrossAxisSpacing = 4.0;
  static const double imageGridMainAxisSpacing = 4.0;

  // Privacy
  static const int maxHiddenFromUsers = 1000;
  static const int maxVisibleToUsers = 1000;

  // Timeago format
  static const String timeagoLocale = 'en';

  // API endpoints (will be prefixed with base URL)
  static const String momentsEndpoint = '/api/v1/moments';
  static const String userMomentsEndpoint = '/api/v1/moments/user';
  static const String createMomentEndpoint = '/api/v1/moments';
  static const String deleteMomentEndpoint = '/api/v1/moments';
  static const String likeMomentEndpoint = '/api/v1/moments';
  static const String commentMomentEndpoint = '/api/v1/moments';
  static const String privacySettingsEndpoint = '/api/v1/moments/privacy';

  // Storage keys for caching
  static const String feedCacheKey = 'moments_feed_cache';
  static const String userMomentsCacheKey = 'user_moments_cache';
  static const String privacySettingsCacheKey = 'moments_privacy_cache';
}
