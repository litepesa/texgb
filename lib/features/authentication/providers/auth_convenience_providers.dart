// lib/features/authentication/providers/auth_convenience_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';

part 'auth_convenience_providers.g.dart';

// Convenience provider to get current user
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.currentUser;
}

// Convenience provider to check if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.state == AuthState.authenticated;
}

// Convenience provider to check if user is guest
@riverpod
bool isGuest(IsGuestRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.state == AuthState.guest;
}

// Convenience provider to check loading state
@riverpod
bool isAuthLoading(IsAuthLoadingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.isLoading ?? false;
}

// Convenience provider to get current user ID
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.currentUser?.id;
}

// Convenience provider to get current phone number
@riverpod
String? currentPhoneNumber(CurrentPhoneNumberRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.phoneNumber;
}

// Convenience provider to get videos
@riverpod
List<VideoModel> videos(VideosRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.videos ?? [];
}

// Convenience provider to get users
@riverpod
List<UserModel> users(UsersRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.users ?? [];
}

// Convenience provider to get liked videos
@riverpod
List<String> likedVideos(LikedVideosRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.likedVideos ?? [];
}

// Convenience provider to get followed users
@riverpod
List<String> followedUsers(FollowedUsersRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.followedUsers ?? [];
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
  return authState.value?.state ?? AuthState.guest;
}

// Error provider
@riverpod
String? authError(AuthErrorRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.error;
}