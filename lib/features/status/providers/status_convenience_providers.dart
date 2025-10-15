// lib/features/status/providers/status_convenience_providers.dart
// Convenience providers for easy access to status data
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

part 'status_convenience_providers.g.dart';

// ========================================
// STATUS LIST PROVIDERS
// ========================================

/// Get all statuses
@riverpod
List<StatusModel> allStatuses(AllStatusesRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.statuses ?? [];
}

/// Get my statuses (current user's statuses)
@riverpod
List<StatusModel> myStatuses(MyStatusesRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.myStatuses ?? [];
}

/// Get unviewed statuses
@riverpod
List<StatusModel> unviewedStatuses(UnviewedStatusesRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.unviewedStatuses ?? [];
}

/// Get active statuses (not expired)
@riverpod
List<StatusModel> activeStatuses(ActiveStatusesRef ref) {
  final statuses = ref.watch(allStatusesProvider);
  return statuses.where((status) => status.isActive).toList();
}

/// Get expired statuses
@riverpod
List<StatusModel> expiredStatuses(ExpiredStatusesRef ref) {
  final statuses = ref.watch(allStatusesProvider);
  return statuses.where((status) => status.isExpired).toList();
}

/// Get image statuses
@riverpod
List<StatusModel> imageStatuses(ImageStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.where((status) => status.isImage).toList();
}

/// Get video statuses
@riverpod
List<StatusModel> videoStatuses(VideoStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.where((status) => status.isVideo).toList();
}

/// Get text statuses
@riverpod
List<StatusModel> textStatuses(TextStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.where((status) => status.isText).toList();
}

/// Get media statuses (image + video)
@riverpod
List<StatusModel> mediaStatuses(MediaStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.where((status) => status.isMediaStatus).toList();
}

/// Get statuses from specific user
@riverpod
Future<List<StatusModel>> userStatuses(UserStatusesRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getUserStatuses(userId);
}

/// Get filtered statuses (search by user name)
@riverpod
List<StatusModel> filteredStatuses(FilteredStatusesRef ref, String query) {
  final statuses = ref.watch(activeStatusesProvider);
  
  if (query.isEmpty) return statuses;
  
  final lowerQuery = query.toLowerCase();
  return statuses.where((status) {
    final userName = status.userName.toLowerCase();
    final caption = status.caption?.toLowerCase() ?? '';
    final textContent = status.textContent?.toLowerCase() ?? '';
    
    return userName.contains(lowerQuery) || 
           caption.contains(lowerQuery) || 
           textContent.contains(lowerQuery);
  }).toList();
}

// ========================================
// SPECIFIC STATUS PROVIDERS
// ========================================

/// Get specific status by ID
@riverpod
Future<StatusModel?> statusById(StatusByIdRef ref, String statusId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getStatusById(statusId);
}

/// Check if status has been viewed
@riverpod
Future<bool> hasViewedStatus(HasViewedStatusRef ref, String statusId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.hasViewedStatus(statusId);
}

/// Check if current user can view a status
@riverpod
Future<bool> canViewStatus(CanViewStatusRef ref, String statusId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) return false;
  
  return await statusNotifier.canViewStatus(statusId, currentUserId);
}

// ========================================
// MUTE PROVIDERS
// ========================================

/// Get list of muted users
@riverpod
List<String> mutedUsers(MutedUsersRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.mutedUsers ?? [];
}

/// Check if user is muted
@riverpod
Future<bool> isUserMuted(IsUserMutedRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.isUserMuted(userId);
}

/// Check if user is in muted list (synchronous)
@riverpod
bool isUserInMutedList(IsUserInMutedListRef ref, String userId) {
  final mutedUsers = ref.watch(mutedUsersProvider);
  return mutedUsers.contains(userId);
}

// ========================================
// STATISTICS PROVIDERS
// ========================================

/// Get total view count for current user's statuses
@riverpod
Future<int> myTotalViewCount(MyTotalViewCountRef ref) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) return 0;
  
  return await statusNotifier.getTotalViewCount(currentUserId);
}

/// Get total view count for specific user
@riverpod
Future<int> userTotalViewCount(UserTotalViewCountRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getTotalViewCount(userId);
}

/// Get view count for specific status
@riverpod
Future<int> statusViewCount(StatusViewCountRef ref, String statusId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getStatusViewCount(statusId);
}

/// Get most viewed status for current user
@riverpod
Future<StatusModel?> myMostViewedStatus(MyMostViewedStatusRef ref) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) return null;
  
  return await statusNotifier.getMostViewedStatus(currentUserId);
}

/// Get most viewed status for specific user
@riverpod
Future<StatusModel?> userMostViewedStatus(UserMostViewedStatusRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getMostViewedStatus(userId);
}

/// Check if user has active statuses
@riverpod
Future<bool> hasActiveStatuses(HasActiveStatusesRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.hasActiveStatuses(userId);
}

/// Get active status count for user
@riverpod
Future<int> activeStatusCount(ActiveStatusCountRef ref, String userId) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getActiveStatusCount(userId);
}

/// Get users with active statuses
@riverpod
Future<List<String>> usersWithActiveStatuses(UsersWithActiveStatusesRef ref) async {
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getUsersWithActiveStatuses();
}

// ========================================
// STATUS STATE PROVIDERS
// ========================================

/// Check if statuses are loading
@riverpod
bool isStatusLoading(IsStatusLoadingRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.isLoading ?? false;
}

/// Check if status is uploading
@riverpod
bool isStatusUploading(IsStatusUploadingRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.isUploading ?? false;
}

/// Get upload progress
@riverpod
double statusUploadProgress(StatusUploadProgressRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.uploadProgress ?? 0.0;
}

/// Get status error if any
@riverpod
String? statusError(StatusErrorRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.error;
}

/// Get last sync time
@riverpod
DateTime? lastStatusSync(LastStatusSyncRef ref) {
  final statusState = ref.watch(statusProvider);
  return statusState.value?.lastSync;
}

// ========================================
// COUNT PROVIDERS
// ========================================

/// Get total status count
@riverpod
int totalStatusCount(TotalStatusCountRef ref) {
  final statuses = ref.watch(allStatusesProvider);
  return statuses.length;
}

/// Get active status count (all users)
@riverpod
int totalActiveStatusCount(TotalActiveStatusCountRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.length;
}

/// Get my status count
@riverpod
int myStatusCount(MyStatusCountRef ref) {
  final myStatuses = ref.watch(myStatusesProvider);
  return myStatuses.length;
}

/// Get unviewed status count
@riverpod
int unviewedStatusCount(UnviewedStatusCountRef ref) {
  final unviewedStatuses = ref.watch(unviewedStatusesProvider);
  return unviewedStatuses.length;
}

/// Get image status count
@riverpod
int imageStatusCount(ImageStatusCountRef ref) {
  final imageStatuses = ref.watch(imageStatusesProvider);
  return imageStatuses.length;
}

/// Get video status count
@riverpod
int videoStatusCount(VideoStatusCountRef ref) {
  final videoStatuses = ref.watch(videoStatusesProvider);
  return videoStatuses.length;
}

/// Get text status count
@riverpod
int textStatusCount(TextStatusCountRef ref) {
  final textStatuses = ref.watch(textStatusesProvider);
  return textStatuses.length;
}

/// Get muted users count
@riverpod
int mutedUsersCount(MutedUsersCountRef ref) {
  final mutedUsers = ref.watch(mutedUsersProvider);
  return mutedUsers.length;
}

// ========================================
// STATUS TYPE CHECKERS
// ========================================

/// Check if status is image
@riverpod
bool isImageStatus(IsImageStatusRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.isImage;
}

/// Check if status is video
@riverpod
bool isVideoStatus(IsVideoStatusRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.isVideo;
}

/// Check if status is text
@riverpod
bool isTextStatus(IsTextStatusRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.isText;
}

/// Check if status is expired
@riverpod
bool isStatusExpired(IsStatusExpiredRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: DateTime.now().toIso8601String(),
    ),
  );
  return status.isExpired;
}

/// Check if status is active
@riverpod
bool isStatusActive(IsStatusActiveRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: DateTime.now().toIso8601String(),
    ),
  );
  return status.isActive;
}

// ========================================
// STATUS PRIVACY PROVIDERS
// ========================================

/// Check if status is public
@riverpod
bool isStatusPublic(IsStatusPublicRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.isPublic;
}

/// Check if status is contacts only
@riverpod
bool isStatusContactsOnly(IsStatusContactsOnlyRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.isContactsOnly;
}

/// Check if status has privacy restrictions
@riverpod
bool hasStatusPrivacyRestrictions(HasStatusPrivacyRestrictionsRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.hasPrivacyRestrictions;
}

// ========================================
// TIME-RELATED PROVIDERS
// ========================================

/// Get time until expiration for status
@riverpod
Duration timeUntilExpiration(TimeUntilExpirationRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: DateTime.now().toIso8601String(),
    ),
  );
  return status.timeUntilExpiration;
}

/// Get time remaining text for status
@riverpod
String timeRemainingText(TimeRemainingTextRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: DateTime.now().toIso8601String(),
    ),
  );
  return status.timeRemainingText;
}

/// Get time ago text for status
@riverpod
String statusTimeAgo(StatusTimeAgoRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: DateTime.now().toIso8601String(),
      expiresAt: '',
    ),
  );
  return status.timeAgo;
}

// ========================================
// GROUPED STATUS PROVIDERS
// ========================================

/// Get statuses grouped by user
@riverpod
Map<String, List<StatusModel>> statusesGroupedByUser(StatusesGroupedByUserRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  final Map<String, List<StatusModel>> grouped = {};
  
  for (final status in statuses) {
    if (!grouped.containsKey(status.userId)) {
      grouped[status.userId] = [];
    }
    grouped[status.userId]!.add(status);
  }
  
  return grouped;
}

/// Get users with unviewed statuses
@riverpod
List<String> usersWithUnviewedStatuses(UsersWithUnviewedStatusesRef ref) {
  final unviewedStatuses = ref.watch(unviewedStatusesProvider);
  final userIds = <String>{};
  
  for (final status in unviewedStatuses) {
    userIds.add(status.userId);
  }
  
  return userIds.toList();
}

/// Get count of unviewed statuses per user
@riverpod
Map<String, int> unviewedStatusCountPerUser(UnviewedStatusCountPerUserRef ref) {
  final unviewedStatuses = ref.watch(unviewedStatusesProvider);
  final Map<String, int> counts = {};
  
  for (final status in unviewedStatuses) {
    counts[status.userId] = (counts[status.userId] ?? 0) + 1;
  }
  
  return counts;
}

/// Get unviewed count for specific user
@riverpod
int unviewedCountForUser(UnviewedCountForUserRef ref, String userId) {
  final counts = ref.watch(unviewedStatusCountPerUserProvider);
  return counts[userId] ?? 0;
}

// ========================================
// RECENTLY POSTED PROVIDERS
// ========================================

/// Get recently posted statuses (last 1 hour)
@riverpod
List<StatusModel> recentlyPostedStatuses(RecentlyPostedStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
  
  return statuses.where((status) {
    return status.createdAtDateTime.isAfter(oneHourAgo);
  }).toList();
}

/// Get soon expiring statuses (expires in less than 1 hour)
@riverpod
List<StatusModel> soonExpiringStatuses(SoonExpiringStatusesRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  
  return statuses.where((status) {
    return status.timeUntilExpiration.inHours < 1;
  }).toList();
}

// ========================================
// POPULAR STATUS PROVIDERS
// ========================================

/// Get most viewed statuses (sorted by views)
@riverpod
List<StatusModel> mostViewedStatuses(MostViewedStatusesRef ref, {int limit = 10}) {
  final statuses = ref.watch(activeStatusesProvider);
  final sorted = List<StatusModel>.from(statuses)
    ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
  
  return sorted.take(limit).toList();
}

/// Get statuses with views
@riverpod
List<StatusModel> statusesWithViews(StatusesWithViewsRef ref) {
  final statuses = ref.watch(activeStatusesProvider);
  return statuses.where((status) => status.hasViews).toList();
}

// ========================================
// CURRENT USER STATUS PROVIDERS
// ========================================

/// Check if current user has active statuses
@riverpod
Future<bool> currentUserHasActiveStatuses(CurrentUserHasActiveStatusesRef ref) async {
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) return false;
  
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.hasActiveStatuses(currentUserId);
}

/// Get current user's active status count
@riverpod
Future<int> currentUserActiveStatusCount(CurrentUserActiveStatusCountRef ref) async {
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  if (currentUserId.isEmpty) return 0;
  
  final statusNotifier = ref.read(statusProvider.notifier);
  return await statusNotifier.getActiveStatusCount(currentUserId);
}

/// Check if current user owns a status
@riverpod
bool isMyStatus(IsMyStatusRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  
  return status.userId == currentUserId;
}

// ========================================
// HELPER PROVIDERS
// ========================================

/// Get status user name
@riverpod
String statusUserName(StatusUserNameRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.userName;
}

/// Get status user image
@riverpod
String statusUserImage(StatusUserImageRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.userImage;
}

/// Get status caption
@riverpod
String? statusCaption(StatusCaptionRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.caption;
}

/// Get formatted duration for video status
@riverpod
String formattedStatusDuration(FormattedStatusDurationRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.formattedDuration;
}

/// Get formatted file size
@riverpod
String formattedStatusFileSize(FormattedStatusFileSizeRef ref, String statusId) {
  final statuses = ref.watch(allStatusesProvider);
  final status = statuses.firstWhere(
    (s) => s.id == statusId,
    orElse: () => StatusModel(
      id: '',
      userId: '',
      userName: '',
      userImage: '',
      type: StatusType.text,
      createdAt: '',
      expiresAt: '',
    ),
  );
  return status.formattedFileSize;
}