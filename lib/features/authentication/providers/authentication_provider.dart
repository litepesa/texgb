// lib/features/authentication/providers/authentication_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/authentication/repositories/authentication_repository.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'authentication_provider.g.dart';

// Authentication states
enum AuthState {
  guest,           // Can browse videos only
  authenticated,   // Firebase user + profile exists
  loading,
  error
}

// State class for authentication
class AuthenticationState {
  final AuthState state;
  final bool isLoading;
  final UserModel? currentUser;
  final String? phoneNumber;
  final String? error;
  final List<VideoModel> videos;
  final List<String> likedVideos;
  final List<UserModel> users;
  final List<String> followedUsers;
  final bool isUploading;
  final double uploadProgress;

  const AuthenticationState({
    this.state = AuthState.guest,
    this.isLoading = false,
    this.currentUser,
    this.phoneNumber,
    this.error,
    this.videos = const [],
    this.likedVideos = const [],
    this.users = const [],
    this.followedUsers = const [],
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  AuthenticationState copyWith({
    AuthState? state,
    bool? isLoading,
    UserModel? currentUser,
    String? phoneNumber,
    String? error,
    List<VideoModel>? videos,
    List<String>? likedVideos,
    List<UserModel>? users,
    List<String>? followedUsers,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return AuthenticationState(
      state: state ?? this.state,
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error,
      videos: videos ?? this.videos,
      likedVideos: likedVideos ?? this.likedVideos,
      users: users ?? this.users,
      followedUsers: followedUsers ?? this.followedUsers,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Repository provider
final authenticationRepositoryProvider = Provider<AuthenticationRepository>((ref) {
  return FirebaseAuthenticationRepository();
});

@riverpod
class Authentication extends _$Authentication {
  AuthenticationRepository get _repository => ref.read(authenticationRepositoryProvider);

  @override
  FutureOr<AuthenticationState> build() async {
    // Check authentication state on initialization
    final isAuthenticated = await checkAuthenticationState();
    
    if (isAuthenticated && _repository.currentUserId != null) {
      final userProfile = await getUserProfile();
      await loadUserDataFromSharedPreferences();
      
      if (userProfile != null) {
        // Load all app data for authenticated user
        await loadVideos();
        await loadLikedVideos();
        await loadUsers();
        await loadFollowedUsers();
        
        return AuthenticationState(
          state: AuthState.authenticated,
          currentUser: userProfile,
          phoneNumber: _repository.currentUserPhoneNumber,
          videos: state.value?.videos ?? [],
          likedVideos: state.value?.likedVideos ?? [],
          users: state.value?.users ?? [],
          followedUsers: state.value?.followedUsers ?? [],
        );
      }
    }
    
    // Load videos for guest browsing
    await loadVideos();
    await loadUsers();
    
    return AuthenticationState(
      state: AuthState.guest,
      videos: state.value?.videos ?? [],
      users: state.value?.users ?? [],
    );
  }

  // Authentication methods
  Future<bool> checkAuthenticationState() async {
    try {
      return await _repository.checkAuthenticationState();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      await _repository.signInWithPhoneNumber(
        phoneNumber: phoneNumber,
        context: context,
      );
      
      state = AsyncValue.data(AuthenticationState(
        state: AuthState.loading,
        phoneNumber: phoneNumber,
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      showSnackBar(context, e.message);
    }
  }

  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      await _repository.verifyOTPCode(
        verificationId: verificationId,
        otpCode: otpCode,
        context: context,
        onSuccess: onSuccess,
      );
      
      // Check if user profile exists
      final userId = _repository.currentUserId;
      if (userId != null) {
        final userExists = await _repository.checkUserExists(userId);
        
        if (userExists) {
          // User profile exists, load full authentication state
          final userProfile = await _repository.getUserProfile(userId);
          await saveUserDataToSharedPreferences();
          await loadVideos();
          await loadLikedVideos();
          await loadUsers();
          await loadFollowedUsers();
          
          state = AsyncValue.data(AuthenticationState(
            state: AuthState.authenticated,
            currentUser: userProfile,
            phoneNumber: _repository.currentUserPhoneNumber,
            videos: state.value?.videos ?? [],
            likedVideos: state.value?.likedVideos ?? [],
            users: state.value?.users ?? [],
            followedUsers: state.value?.followedUsers ?? [],
          ));
        } else {
          // User profile doesn't exist, need to create profile
          state = AsyncValue.data(AuthenticationState(
            state: AuthState.loading,
            phoneNumber: _repository.currentUserPhoneNumber,
          ));
        }
      }
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      showSnackBar(context, e.message);
    }
  }

  Future<void> createUserProfile({
    required UserModel user,
    required File? profileImage,
    required File? coverImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));

    try {
      final createdUser = await _repository.createUserProfile(
        user: user,
        profileImage: profileImage,
        coverImage: coverImage,
      );
      
      await saveUserDataToSharedPreferences();
      await loadVideos();
      await loadLikedVideos();
      await loadUsers();
      await loadFollowedUsers();
      
      state = AsyncValue.data(AuthenticationState(
        state: AuthState.authenticated,
        currentUser: createdUser,
        phoneNumber: _repository.currentUserPhoneNumber,
        videos: state.value?.videos ?? [],
        likedVideos: state.value?.likedVideos ?? [],
        users: state.value?.users ?? [],
        followedUsers: state.value?.followedUsers ?? [],
      ));
      
      onSuccess();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      onFail();
    }
  }

  Future<UserModel?> getUserProfile() async {
    final userId = _repository.currentUserId;
    if (userId == null) return null;
    
    try {
      return await _repository.getUserProfile(userId);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
    }
  }

  Future<void> updateUserProfile({
    required UserModel user,
    File? profileImage,
    File? coverImage,
  }) async {
    state = AsyncValue.data(state.value?.copyWith(isLoading: true) ?? const AuthenticationState(isLoading: true));
    
    try {
      final updatedUser = await _repository.updateUserProfile(
        user: user,
        profileImage: profileImage,
        coverImage: coverImage,
      );

      // Update local state
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(
        currentUser: updatedUser,
        isLoading: false,
      ));

      await saveUserDataToSharedPreferences();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(isLoading: true));
    
    try {
      await _repository.signOut();
      
      // Clear local user data
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.remove('userModel');
      
      // Keep videos and users for guest browsing
      await loadVideos();
      await loadUsers();
      
      state = AsyncValue.data(AuthenticationState(
        state: AuthState.guest,
        videos: state.value?.videos ?? [],
        users: state.value?.users ?? [],
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  // Video methods
  Future<void> loadVideos() async {
    try {
      final videos = await _repository.getVideos();
      
      // Update liked status for videos if user is authenticated
      final currentState = state.value ?? const AuthenticationState();
      final videosWithLikedStatus = videos.map((video) {
        final isLiked = currentState.likedVideos.contains(video.id);
        return video.copyWith(isLiked: isLiked);
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(videos: videosWithLikedStatus));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading videos: ${e.message}');
    }
  }

  Future<void> loadUserVideos(String userId) async {
    try {
      final userVideos = await _repository.getUserVideos(userId);
      // You can add this to a separate state if needed
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading user videos: ${e.message}');
    }
  }

  Future<void> likeVideo(String videoId) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) return;
    
    final userId = _repository.currentUserId;
    if (userId == null) return;
    
    try {
      // Get current liked videos
      List<String> likedVideos = List.from(currentState.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
        await _repository.unlikeVideo(videoId, userId);
      } else {
        likedVideos.add(videoId);
        await _repository.likeVideo(videoId, userId);
      }
      
      // Update videos list with new like status
      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? video.likes - 1 : video.likes + 1,
          );
        }
        return video;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(
        videos: updatedVideos,
        likedVideos: likedVideos,
      ));
      
    } on AuthRepositoryException catch (e) {
      debugPrint('Error toggling like: ${e.message}');
      // Revert the optimistic update on error
      await loadVideos();
      await loadLikedVideos();
    }
  }

  Future<void> createVideo({
    required File videoFile,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated || currentState.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    // Set uploading state to true
    state = AsyncValue.data(currentState.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    ));
    
    try {
      final user = currentState.currentUser!;
      
      // Upload video to storage with progress tracking
      final videoUrl = await _repository.storeFileToStorage(
        file: videoFile,
        reference: 'videos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress: (progress) {
          // Update upload progress in real-time
          final currentState = state.value ?? const AuthenticationState();
          state = AsyncValue.data(currentState.copyWith(
            uploadProgress: progress,
          ));
        },
      );
      
      // Generate thumbnail (placeholder for now)
      const thumbnailUrl = '';
      
      // Create video
      final videoData = await _repository.createVideo(
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags,
      );
      
      // Update local state
      List<VideoModel> updatedVideos = [
        videoData, // Add new video at the beginning
        ...currentState.videos,
      ];
      
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        videos: updatedVideos,
      ));
      
      onSuccess('Video uploaded successfully');
    } on AuthRepositoryException catch (e) {
      debugPrint('Error uploading video: ${e.message}');
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      ));
      onError(e.message);
    }
  }

  Future<void> createImagePost({
    required List<File> imageFiles,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated || currentState.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (imageFiles.isEmpty) {
      onError('No images selected');
      return;
    }
    
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    try {
      final user = currentState.currentUser!;
      final List<String> imageUrls = [];
      
      // Upload each image
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final imageUrl = await _repository.storeFileToStorage(
          file: file,
          reference: 'images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        imageUrls.add(imageUrl);
      }
      
      // Create image post
      final postData = await _repository.createImagePost(
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        imageUrls: imageUrls,
        caption: caption,
        tags: tags,
      );
      
      // Update local state
      List<VideoModel> updatedVideos = [
        postData, // Add new post at the beginning
        ...currentState.videos,
      ];
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        videos: updatedVideos,
      ));
      
      onSuccess('Images uploaded successfully');
    } on AuthRepositoryException catch (e) {
      debugPrint('Error uploading images: ${e.message}');
      state = AsyncValue.data(currentState.copyWith(isLoading: false));
      onError(e.message);
    }
  }

  Future<void> deleteVideo(String videoId, Function(String) onError) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) {
      onError('User not authenticated');
      return;
    }
    
    final userId = _repository.currentUserId;
    if (userId == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      await _repository.deleteVideo(videoId, userId);
      
      // Update local state
      final updatedVideos = currentState.videos.where((video) => video.id != videoId).toList();
      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error deleting video: ${e.message}');
      onError(e.message);
    }
  }

  Future<void> incrementViewCount(String videoId) async {
    try {
      await _repository.incrementViewCount(videoId);
      
      // Update local state
      final currentState = state.value ?? const AuthenticationState();
      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(views: video.views + 1);
        }
        return video;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error incrementing view count: ${e.message}');
    }
  }

  Future<void> loadLikedVideos() async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    
    try {
      final likedVideos = await _repository.getLikedVideos(userId);
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(likedVideos: likedVideos));
      
      // Update isLiked status for existing videos
      final updatedVideos = currentState.videos.map((video) {
        return video.copyWith(isLiked: likedVideos.contains(video.id));
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading liked videos: ${e.message}');
    }
  }

  // User/Social methods
  Future<void> loadUsers() async {
    final currentUserId = _repository.currentUserId ?? '';
    
    try {
      final users = await _repository.getAllUsers(excludeUserId: currentUserId);
      final currentState = state.value ?? const AuthenticationState();
      
      state = AsyncValue.data(currentState.copyWith(users: users));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading users: ${e.message}');
    }
  }

  Future<void> followUser(String userId) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) return;
    
    final currentUserId = _repository.currentUserId;
    if (currentUserId == null) return;
    
    try {
      // Get current followed users
      List<String> followedUsers = List.from(currentState.followedUsers);
      bool isCurrentlyFollowed = followedUsers.contains(userId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyFollowed) {
        followedUsers.remove(userId);
        await _repository.unfollowUser(followerId: currentUserId, userId: userId);
      } else {
        followedUsers.add(userId);
        await _repository.followUser(followerId: currentUserId, userId: userId);
      }
      
      // Update users list with new follow status
      final updatedUsers = currentState.users.map((user) {
        if (user.uid == userId) {
          return user.copyWith(
            followers: isCurrentlyFollowed ? user.followers - 1 : user.followers + 1,
            followerUIDs: isCurrentlyFollowed
                ? (List.from(user.followerUIDs)..remove(currentUserId))
                : (List.from(user.followerUIDs)..add(currentUserId)),
          );
        }
        return user;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(
        users: updatedUsers,
        followedUsers: followedUsers,
      ));
      
    } on AuthRepositoryException catch (e) {
      debugPrint('Error toggling follow: ${e.message}');
      // Revert the optimistic update on error
      await loadUsers();
      await loadFollowedUsers();
    }
  }

  Future<void> loadFollowedUsers() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated || currentState.currentUser == null) return;
    
    try {
      final followedUsers = currentState.currentUser!.followingUIDs;
      state = AsyncValue.data(currentState.copyWith(followedUsers: followedUsers));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading followed users: ${e.message}');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _repository.searchUsers(query: query);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error searching users: ${e.message}');
      return [];
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      return await _repository.getUserProfile(userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error getting user by ID: ${e.message}');
      return null;
    }
  }

  // Comment methods
  Future<void> addComment({
    required String videoId,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated || currentState.currentUser == null) {
      onError('User not authenticated');
      return;
    }

    try {
      final user = currentState.currentUser!;
      
      await _repository.addComment(
        videoId: videoId,
        authorId: user.uid,
        authorName: user.name,
        authorImage: user.profileImage,
        content: content,
        repliedToCommentId: repliedToCommentId,
        repliedToAuthorName: repliedToAuthorName,
      );

      onSuccess('Comment added successfully');
    } catch (e) {
      debugPrint('Error adding comment: $e');
      onError('Failed to add comment');
    }
  }

  Future<List<CommentModel>> getVideoComments(String videoId) async {
    try {
      return await _repository.getVideoComments(videoId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error getting video comments: ${e.message}');
      return [];
    }
  }

  Future<void> deleteComment(String commentId, Function(String) onError) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) {
      onError('User not authenticated');
      return;
    }
    
    final userId = _repository.currentUserId;
    if (userId == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      await _repository.deleteComment(commentId, userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error deleting comment: ${e.message}');
      onError(e.message);
    }
  }

  Future<void> likeComment(String commentId) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) return;
    
    final userId = _repository.currentUserId;
    if (userId == null) return;
    
    try {
      await _repository.likeComment(commentId, userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error liking comment: ${e.message}');
    }
  }

  Future<void> unlikeComment(String commentId) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) return;
    
    final userId = _repository.currentUserId;
    if (userId == null) return;
    
    try {
      await _repository.unlikeComment(commentId, userId);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error unliking comment: ${e.message}');
    }
  }

  // Utility methods
  Future<void> saveUserDataToSharedPreferences() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.currentUser == null) return;
    
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        'userModel', jsonEncode(currentState.currentUser!.toMap()));
  }

  Future<void> loadUserDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String userModelString = sharedPreferences.getString('userModel') ?? '';
    
    if (userModelString.isEmpty) return;
    
    final Map<String, dynamic> userMap = jsonDecode(userModelString);
    final user = UserModel.fromMap(userMap);
    final currentState = state.value ?? const AuthenticationState();
    
    state = AsyncValue.data(currentState.copyWith(
      currentUser: user,
      phoneNumber: user.phoneNumber,
    ));
  }

  // Helper methods for UI
  bool get isAuthenticated {
    final currentState = state.value;
    return currentState?.state == AuthState.authenticated;
  }

  bool get isGuest {
    final currentState = state.value;
    return currentState?.state == AuthState.guest;
  }

  bool get isLoading {
    final currentState = state.value;
    return currentState?.isLoading ?? false;
  }

  bool get isUploading {
    final currentState = state.value;
    return currentState?.isUploading ?? false;
  }

  double get uploadProgress {
    final currentState = state.value;
    return currentState?.uploadProgress ?? 0.0;
  }

  UserModel? get currentUser {
    final currentState = state.value;
    return currentState?.currentUser;
  }

  String? get phoneNumber {
    final currentState = state.value;
    return currentState?.phoneNumber;
  }

  List<VideoModel> get videos {
    final currentState = state.value;
    return currentState?.videos ?? [];
  }

  List<UserModel> get users {
    final currentState = state.value;
    return currentState?.users ?? [];
  }

  bool isVideoLiked(String videoId) {
    final currentState = state.value;
    return currentState?.likedVideos.contains(videoId) ?? false;
  }

  bool isUserFollowed(String userId) {
    final currentState = state.value;
    return currentState?.followedUsers.contains(userId) ?? false;
  }

  // File operations
  Future<String> storeFileToStorage({required File file, required String reference}) async {
    try {
      return await _repository.storeFileToStorage(file: file, reference: reference);
    } on AuthRepositoryException catch (e) {
      throw e.message;
    }
  }

  // Deprecated stream methods - kept for compatibility but return empty streams
  Stream<DocumentSnapshot> userStream({required String userId}) {
    return const Stream.empty();
  }

  Stream<QuerySnapshot> getAllUsersStream({required String excludeUserId}) {
    return const Stream.empty();
  }

  Stream<QuerySnapshot> getVideosStream() {
    return const Stream.empty();
  }

  Stream<List<CommentModel>> getCommentsStream(String videoId) {
    return const Stream.empty();
  }
}