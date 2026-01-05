// lib/features/authentication/providers/auth_convenience_providers.dart
// FIXED: Proper AsyncValue handling to eliminate temporary "login required" messages
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';

part 'auth_convenience_providers.g.dart';

// Convenience provider to get current user
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.currentUser,
    loading: () => null, // Return null while loading instead of causing flash
    error: (_, __) => null,
  );
}

// Convenience provider to check if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.state == AuthState.authenticated,
    loading: () =>
        false, // Default to false while loading (prevents login flash)
    error: (_, __) => false,
  );
}

// Convenience provider to check if user is guest
@riverpod
bool isGuest(IsGuestRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.state == AuthState.guest,
    loading: () => true, // Assume guest while loading (prevents login flash)
    error: (_, __) => true,
  );
}

// Convenience provider to check loading state
@riverpod
bool isAuthLoading(IsAuthLoadingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.isLoading,
    loading: () => true, // Return true when AsyncValue is loading
    error: (_, __) => false,
  );
}

// Convenience provider to check upload state
@riverpod
bool isUploading(IsUploadingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.isUploading,
    loading: () => false, // Default to false while loading
    error: (_, __) => false,
  );
}

// Convenience provider to get upload progress
@riverpod
double uploadProgress(UploadProgressRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.uploadProgress,
    loading: () => 0.0, // Default to 0 while loading
    error: (_, __) => 0.0,
  );
}

// Convenience provider to get current user ID - UPDATED
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.currentUser?.uid,
    loading: () => null, // Return null while loading
    error: (_, __) => null,
  );
}

// Convenience provider to get current phone number
@riverpod
String? currentPhoneNumber(CurrentPhoneNumberRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.phoneNumber,
    loading: () => null, // Return null while loading
    error: (_, __) => null,
  );
}

// Convenience provider to get videos
@riverpod
List<VideoModel> videos(VideosRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.videos,
    loading: () => [], // Return empty list while loading (prevents null errors)
    error: (_, __) => [],
  );
}

// Convenience provider to get users
@riverpod
List<UserModel> users(UsersRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.users,
    loading: () => [], // Return empty list while loading (prevents null errors)
    error: (_, __) => [],
  );
}

// Convenience provider to get liked videos
@riverpod
List<String> likedVideos(LikedVideosRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.likedVideos,
    loading: () => [], // Return empty list while loading
    error: (_, __) => [],
  );
}

// Convenience provider to get followed users
@riverpod
List<String> followedUsers(FollowedUsersRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.followedUsers,
    loading: () => [], // Return empty list while loading
    error: (_, __) => [],
  );
}

// Helper methods as providers
@riverpod
bool isVideoLiked(IsVideoLikedRef ref, String videoId) {
  final likedVideos = ref.watch(likedVideosProvider);
  return likedVideos.contains(videoId);
}

@riverpod
bool isUserFollowed(IsUserFollowedRef ref, String userId) {
  final followedUsers = ref.watch(followedUsersProvider);
  return followedUsers.contains(userId);
}

// Authentication state provider
@riverpod
AuthState authState(AuthStateRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.state,
    loading: () => AuthState.loading, // Return loading state while loading
    error: (_, __) => AuthState.error,
  );
}

// Error provider
@riverpod
String? authError(AuthErrorRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.error,
    loading: () => null, // No error while loading
    error: (error, __) => error.toString(), // Return the actual error
  );
}

// NEW: Provider to check if app is still initializing
@riverpod
bool isAppInitializing(IsAppInitializingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (_) => false, // App is initialized when we have data
    loading: () => true, // App is still initializing
    error: (_, __) => false, // Even with error, initialization is done
  );
}

// NEW: Provider to get auth state safely with loading handling
@riverpod
AuthenticationState? authenticationStateOrNull(
    AuthenticationStateOrNullRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data,
    loading: () => null, // Return null while loading
    error: (_, __) => null,
  );
}

// NEW: Provider to check if we have any cached data available
@riverpod
bool hasCachedData(HasCachedDataRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.users.isNotEmpty || data.currentUser != null,
    loading: () => false, // No cached data while loading
    error: (_, __) => false,
  );
}

// NEW: Provider specifically for checking authentication without loading flash
@riverpod
AuthState safeAuthState(SafeAuthStateRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.state,
    loading: () =>
        AuthState.loading, // Use loading state instead of defaulting to guest
    error: (_, __) => AuthState.error,
  );
}

// NEW: Provider for checking if user needs profile creation
@riverpod
bool needsProfileCreation(NeedsProfileCreationRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (data) => data.state == AuthState.partial,
    loading: () => false, // Don't show profile creation while loading
    error: (_, __) => false,
  );
}
