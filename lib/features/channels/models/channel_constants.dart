// ===============================
// Channel Feature Constants
// Configuration values for channels/videos feature
// ===============================

class ChannelConstants {
  // Video constraints
  static const int maxVideoDurationSeconds = 180; // 3 minutes (TikTok style)
  static const int maxVideoSizeMB = 500;
  static const int videoQuality = 85; // Compression quality

  // Channel constraints
  static const int maxChannelNameLength = 50;
  static const int minChannelNameLength = 3;
  static const int maxBioLength = 500;
  static const int maxTagsCount = 10;

  // Feed pagination
  static const int feedPageSize = 20; // Videos per page
  static const int profileVideosPageSize = 12;

  // Cache settings
  static const Duration feedCacheDuration = Duration(minutes: 5);
  static const String feedCacheKey = 'channels_feed_cache';
  static const String channelCacheKey = 'channel_cache';

  // Video caching (for playback)
  static const int precacheSegments = 3; // Precache first 3 segments
  static const int preloadNextVideos = 2; // Preload next N videos
  static const int preloadPreviousVideos = 1; // Preload previous N videos

  // API endpoints (for backend integration)
  static const String channelBaseUrl = '/api/v1/channels';

  // Channel categories
  static const List<String> channelCategories = [
    'General',
    'Tech',
    'Fashion',
    'Food',
    'Travel',
    'Music',
    'Sports',
    'Gaming',
    'Education',
    'Comedy',
    'Beauty',
    'Fitness',
    'Business',
    'News',
    'Entertainment',
    'Lifestyle',
    'Art',
    'DIY',
    'Pets',
    'Other',
  ];

  // Verification requirements (for display/info)
  static const int verificationMinFollowers = 1000;
  static const int verificationMinVideos = 10;
  static const int verificationMinViews = 10000;
}
