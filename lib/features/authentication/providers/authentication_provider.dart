// lib/features/authentication/providers/authentication_provider.dart
// Video-focused authentication provider with instant auth recognition, caching, and video updates
// OPTIMIZED: Videos load during app initialization for instant feed display
// ENHANCED: Simple force refresh solution for backend updates
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/authentication/repositories/authentication_repository.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/features/videos/services/video_thumbnail_service.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'authentication_provider.g.dart';

// Authentication states
enum AuthState {
  guest, // Can browse videos only
  authenticated, // Firebase user + profile exists
  partial, // Firebase authenticated but no backend profile
  loading,
  error
}

// State class for authentication (video-focused)
class AuthenticationState {
  final AuthState state;
  final bool isLoading;
  final bool isSuccessful;
  final UserModel? currentUser;
  final String? phoneNumber;
  final String? error;

  // Video-related state
  final List<VideoModel> videos;
  final List<String> likedVideos;
  final List<UserModel> users;
  final List<String> followedUsers;
  final bool isUploading;
  final double uploadProgress;

  const AuthenticationState({
    this.state = AuthState.guest,
    this.isLoading = false,
    this.isSuccessful = false,
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
    bool? isSuccessful,
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
      isSuccessful: isSuccessful ?? this.isSuccessful,
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
final authenticationRepositoryProvider =
    Provider<AuthenticationRepository>((ref) {
  return FirebaseAuthenticationRepository();
});

@riverpod
class Authentication extends _$Authentication {
  AuthenticationRepository get _repository =>
      ref.read(authenticationRepositoryProvider);

  // Cache keys
  static const String _userProfileCacheKey = 'cached_user_profile';
  static const String _usersListCacheKey = 'cached_users_list';
  static const String _lastSyncCacheKey = 'last_sync_timestamp';

  @override
  FutureOr<AuthenticationState> build() async {
    // INSTANT AUTH CHECK: Check Firebase Auth immediately (synchronous)
    final firebaseUser = _repository.currentUserId;

    if (firebaseUser != null) {
      // User is authenticated in Firebase - try to load cached data
      final cachedUser = await _loadCachedUserProfile();
      final cachedUsers = await _loadCachedUsers();

      if (cachedUser != null) {
        // Return authenticated state IMMEDIATELY with cached data
        final immediateState = AuthenticationState(
          state: AuthState.authenticated,
          isSuccessful: true,
          currentUser: cachedUser,
          phoneNumber: _repository.currentUserPhoneNumber,
          users: cachedUsers,
          videos: [], // Empty initially, will load below
        );

        // Set state immediately for instant UI
        state = AsyncValue.data(immediateState);

        // ✅ Load videos AND refresh user data in parallel (non-blocking)
        await Future.wait([
          _loadVideosInBackground(),
          _refreshDataInBackground(),
        ]);

        return state.value ?? immediateState;
      } else {
        // Firebase authenticated but no cached profile - check backend
        final userExists = await checkUserExists();

        if (userExists) {
          final userProfile = await getUserDataFromBackend();

          if (userProfile != null) {
            await _saveCachedUserProfile(userProfile);
            
            // ✅ Load videos AND users in parallel
            await Future.wait([
              loadVideos(),
              loadUsers(),
            ]);
            
            await _saveCachedUsers(state.value?.users ?? []);

            return AuthenticationState(
              state: AuthState.authenticated,
              isSuccessful: true,
              currentUser: userProfile,
              phoneNumber: _repository.currentUserPhoneNumber,
              users: state.value?.users ?? [],
              videos: state.value?.videos ?? [],
            );
          }
        } else {
          // Authenticated but no backend profile
          // ✅ Still load videos for browsing
          await Future.wait([
            loadVideos(),
            loadUsers(),
          ]);

          return AuthenticationState(
            state: AuthState.partial,
            isSuccessful: false,
            phoneNumber: _repository.currentUserPhoneNumber,
            users: state.value?.users ?? [],
            videos: state.value?.videos ?? [],
          );
        }
      }
    }

    // ✅ User not authenticated - load videos immediately for guest browsing
    debugPrint('🎬 Loading videos for guest user...');
    
    await Future.wait([
      loadVideos(),
      loadUsers(),
    ]);

    return AuthenticationState(
      state: AuthState.guest,
      users: state.value?.users ?? [],
      videos: state.value?.videos ?? [],
    );
  }

  // ===============================
  // CACHE MANAGEMENT METHODS
  // ===============================

  Future<UserModel?> _loadCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userProfileCacheKey);

      if (userJson != null && userJson.isNotEmpty) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromMap(userMap);
      }
    } catch (e) {
      debugPrint('Error loading cached user profile: $e');
    }
    return null;
  }

  Future<void> _saveCachedUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileCacheKey, jsonEncode(user.toMap()));
      await prefs.setInt(
          _lastSyncCacheKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('User profile cached successfully');
    } catch (e) {
      debugPrint('Error saving cached user profile: $e');
    }
  }

  Future<List<UserModel>> _loadCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersListCacheKey);

      if (usersJson != null && usersJson.isNotEmpty) {
        final List<dynamic> usersData = jsonDecode(usersJson);
        return usersData
            .map((userData) =>
                UserModel.fromMap(userData as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading cached users: $e');
    }
    return [];
  }

  Future<void> _saveCachedUsers(List<UserModel> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersData = users.map((user) => user.toMap()).toList();
      await prefs.setString(_usersListCacheKey, jsonEncode(usersData));
      debugPrint('Users list cached successfully (${users.length} users)');
    } catch (e) {
      debugPrint('Error saving cached users: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileCacheKey);
      await prefs.remove(_usersListCacheKey);
      await prefs.remove(_lastSyncCacheKey);
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Check if cache is fresh (optional optimization)
  Future<bool> _isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncCacheKey) ?? 0;
      final timeDiff = DateTime.now().millisecondsSinceEpoch - lastSync;

      // Cache valid for 1 hour (3600000 milliseconds)
      return timeDiff < 3600000;
    } catch (e) {
      debugPrint('Error checking cache freshness: $e');
      return false;
    }
  }

  // ✅ NEW: Load videos in background and update state
  Future<void> _loadVideosInBackground() async {
    try {
      debugPrint('🎬 Loading videos in background...');
      await loadVideos();
      debugPrint('✅ Videos loaded in background');
    } catch (e) {
      debugPrint('❌ Background video loading failed (non-critical): $e');
      // Don't throw - this is non-critical background operation
    }
  }

  // Background refresh without blocking UI
  Future<void> _refreshDataInBackground() async {
    try {
      debugPrint('Starting background data refresh...');

      // Refresh user profile
      final freshUserProfile = await getUserProfile();
      if (freshUserProfile != null) {
        await _saveCachedUserProfile(freshUserProfile);

        // Update state with fresh profile
        final currentState = state.value ?? const AuthenticationState();
        state = AsyncValue.data(currentState.copyWith(
          currentUser: freshUserProfile,
        ));
      }

      // Refresh users list
      await loadUsers();
      final currentState = state.value ?? const AuthenticationState();
      if (currentState.users.isNotEmpty) {
        await _saveCachedUsers(currentState.users);
      }

      debugPrint('Background data refresh completed');
    } catch (e) {
      debugPrint('Background refresh failed (non-critical): $e');
      // Don't update UI on background refresh failure
    }
  }

  // ===============================
  // 🆕 SIMPLE FORCE REFRESH METHODS
  // ===============================

  /// Force refresh user profile from backend, bypassing all caches
  /// This is the SIMPLE solution for pull-to-refresh
  Future<UserModel?> forceRefreshUserProfile() async {
    final userId = _repository.currentUserId;
    if (userId == null) return null;

    try {
      debugPrint('🔄 Force refreshing user profile from backend...');
      
      // 1. Fetch fresh data from backend (ignore cache completely)
      final freshProfile = await _repository.getUserProfile(userId);
      
      if (freshProfile != null) {
        debugPrint('✅ Fresh profile retrieved:');
        debugPrint('   - Name: ${freshProfile.name}');
        debugPrint('   - Verified: ${freshProfile.isVerified}');
        debugPrint('   - Role: ${freshProfile.role}');
        debugPrint('   - UID: ${freshProfile.uid}');
        
        // 2. Update state immediately with fresh data
        final currentState = state.value ?? const AuthenticationState();
        state = AsyncValue.data(currentState.copyWith(
          currentUser: freshProfile,
          state: AuthState.authenticated,
          isSuccessful: true,
        ));
        
        // 3. Update all caches with fresh data
        await _saveCachedUserProfile(freshProfile);
        
        // Also update SharedPreferences userModel
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userModel', jsonEncode(freshProfile.toMap()));
        
        debugPrint('✅ Profile refresh complete and all caches updated');
      }
      
      return freshProfile;
    } catch (e) {
      debugPrint('❌ Force refresh failed: $e');
      throw AuthRepositoryException('Failed to refresh user profile: $e');
    }
  }

  /// Clear only user-specific cache (not videos/users cache)
  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileCacheKey);
      await prefs.remove('userModel');
      debugPrint('🗑️ User cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
    }
  }

  // ===============================
  // AUTHENTICATION METHODS
  // ===============================

  Future<bool> checkUserExists() async {
    final userId = _repository.currentUserId;
    if (userId == null) return false;

    try {
      return await _repository.checkUserExists(userId);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return false;
    }
  }

  Future<UserModel?> getUserDataFromBackend() async {
    final userId = _repository.currentUserId;
    if (userId == null) return null;

    try {
      final userModel = await _repository.getUserProfile(userId);

      if (userModel != null) {
        final currentState = state.value ?? const AuthenticationState();
        state = AsyncValue.data(currentState.copyWith(
          currentUser: userModel,
          state: AuthState.authenticated,
          isSuccessful: true,
        ));

        // Cache the fresh user profile
        await _saveCachedUserProfile(userModel);
      }

      return userModel;
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      return null;
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
    state = AsyncValue.data(const AuthenticationState(
      state: AuthState.loading,
      isLoading: true,
    ));

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
    state = AsyncValue.data(const AuthenticationState(
      state: AuthState.loading,
      isLoading: true,
    ));

    try {
      await _repository.verifyOTPCode(
        verificationId: verificationId,
        otpCode: otpCode,
        context: context,
        onSuccess: () async {
          await _handlePostOTPVerification();
          onSuccess();
        },
      );
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      showSnackBar(context, e.message);
    }
  }

  Future<void> _handlePostOTPVerification() async {
    final uid = _repository.currentUserId;
    if (uid == null) return;

    try {
      final userExists = await checkUserExists();

      if (userExists) {
        final userModel = await getUserDataFromBackend();

        if (userModel != null) {
          await _saveCachedUserProfile(userModel);
          
          // ✅ Load videos and users in parallel
          await Future.wait([
            loadVideos(),
            loadUsers(),
          ]);
          
          await _saveCachedUsers(state.value?.users ?? []);

          state = AsyncValue.data(AuthenticationState(
            state: AuthState.authenticated,
            isSuccessful: true,
            currentUser: userModel,
            phoneNumber: _repository.currentUserPhoneNumber,
            users: state.value?.users ?? [],
            videos: state.value?.videos ?? [],
          ));
        }
      } else {
        // ✅ Still load videos for browsing even without profile
        await Future.wait([
          loadVideos(),
          loadUsers(),
        ]);

        state = AsyncValue.data(AuthenticationState(
          state: AuthState.partial,
          isSuccessful: false,
          phoneNumber: _repository.currentUserPhoneNumber,
          users: state.value?.users ?? [],
          videos: state.value?.videos ?? [],
        ));
      }
    } on AuthRepositoryException catch (e) {
      debugPrint('Failed to handle post-OTP verification: ${e.message}');
      
      // ✅ Still load videos even on error
      await Future.wait([
        loadVideos(),
        loadUsers(),
      ]);

      state = AsyncValue.data(AuthenticationState(
        state: AuthState.partial,
        isSuccessful: false,
        phoneNumber: _repository.currentUserPhoneNumber,
        users: state.value?.users ?? [],
        videos: state.value?.videos ?? [],
      ));
    }
  }

  Future<void> createUserProfile({
    required UserModel user,
    required File? profileImage,
    required File? coverImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    state = AsyncValue.data(const AuthenticationState(
      state: AuthState.loading,
      isLoading: true,
    ));

    try {
      final createdUser = await _repository.createUserProfile(
        user: user,
        profileImage: profileImage,
        coverImage: coverImage,
      );

      // Cache the new user profile
      await _saveCachedUserProfile(createdUser);
      
      // ✅ Load videos and users in parallel
      await Future.wait([
        loadVideos(),
        loadUsers(),
      ]);
      
      await _saveCachedUsers(state.value?.users ?? []);

      state = AsyncValue.data(AuthenticationState(
        state: AuthState.authenticated,
        isSuccessful: true,
        currentUser: createdUser,
        phoneNumber: _repository.currentUserPhoneNumber,
        users: state.value?.users ?? [],
        videos: state.value?.videos ?? [],
      ));

      onSuccess();
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      onFail();
    }
  }

  Future<void> updateUserProfile({
    required UserModel user,
    File? profileImage,
    File? coverImage,
  }) async {
    state = AsyncValue.data(state.value?.copyWith(isLoading: true) ??
        const AuthenticationState(isLoading: true));

    try {
      final updatedUser = await _repository.updateUserProfile(
        user: user,
        profileImage: profileImage,
        coverImage: coverImage,
      );

      final currentState = state.value ?? const AuthenticationState();

      state = AsyncValue.data(currentState.copyWith(
        currentUser: updatedUser,
        state: AuthState.authenticated,
        isSuccessful: true,
        isLoading: false,
      ));

      // Cache the updated profile
      await _saveCachedUserProfile(updatedUser);
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  Future<void> signOut() async {
    state = AsyncValue.data(const AuthenticationState(
      state: AuthState.loading,
      isLoading: true,
    ));

    try {
      await _repository.signOut();

      // Clear all cached data on sign out
      await _clearCache();

      // Also clear SharedPreferences userModel (your existing logic)
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await sharedPreferences.remove('userModel');

      // ✅ Reload videos for guest browsing
      await Future.wait([
        loadVideos(),
        loadUsers(),
      ]);

      state = AsyncValue.data(AuthenticationState(
        state: AuthState.guest,
        users: state.value?.users ?? [],
        videos: state.value?.videos ?? [],
      ));
    } on AuthRepositoryException catch (e) {
      state = AsyncValue.error(e.message, StackTrace.current);
      throw e.message;
    }
  }

  // ===============================
  // VIDEO METHODS
  // ===============================

  Future<void> loadVideos() async {
    try {
      debugPrint('🎬 Loading videos from backend...');
      
      final videos = await _repository.getVideos();
      
      debugPrint('✅ Loaded ${videos.length} videos successfully');

      final currentState = state.value ?? const AuthenticationState();
      final videosWithLikedStatus = videos.map((video) {
        final isLiked = currentState.likedVideos.contains(video.id);
        return video.copyWith(isLiked: isLiked);
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: videosWithLikedStatus));
      
    } on AuthRepositoryException catch (e) {
      debugPrint('❌ Error loading videos: ${e.message}');
      // ✅ Don't set error state - just log it to keep UI functional
    } catch (e) {
      debugPrint('❌ Unexpected error loading videos: $e');
      // ✅ Don't set error state - just log it to keep UI functional
    }
  }

  Future<void> loadUserVideos(String userId) async {
    try {
      final userVideos = await _repository.getUserVideos(userId);
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
      List<String> likedVideos = List.from(currentState.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);

      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
        await _repository.unlikeVideo(videoId, userId);
      } else {
        likedVideos.add(videoId);
        await _repository.likeVideo(videoId, userId);
      }

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
      await loadVideos();
      await loadLikedVideos();
    }
  }

  Future<void> createVideo({
    required File videoFile,
    required String caption,
    List<String>? tags,
    double? price,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated ||
        currentState.currentUser == null) {
      onError('User not authenticated');
      return;
    }

    state = AsyncValue.data(currentState.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    ));

    File? thumbnailFile;

    try {
      final user = currentState.currentUser!;

      // Generate thumbnail from video file
      debugPrint('🎬 Step 1/4: Generating thumbnail from video...');
      final thumbnailService = VideoThumbnailService();
      thumbnailFile = await thumbnailService.generateBestThumbnailFile(
        videoFile: videoFile,
        maxWidth: 400,
        maxHeight: 600,
        quality: 85,
      );

      if (thumbnailFile == null) {
        debugPrint('⚠️ Warning: Failed to generate thumbnail, continuing without it');
      } else {
        debugPrint('✅ Thumbnail generated successfully: ${thumbnailFile.path}');
      }

      // Update progress: Thumbnail generated (10%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.1,
      ));

      // Upload thumbnail to Cloudflare R2 (if generated)
      String thumbnailUrl = '';
      if (thumbnailFile != null) {
        debugPrint('☁️ Step 2/4: Uploading thumbnail to Cloudflare R2...');
        try {
          thumbnailUrl = await _repository.storeFileToStorage(
            file: thumbnailFile,
            reference: 'thumbnails/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          debugPrint('✅ Thumbnail uploaded to R2: $thumbnailUrl');
          
          // Clean up temporary thumbnail file after successful upload
          await thumbnailService.deleteThumbnailFile(thumbnailFile);
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to upload thumbnail: $e');
          // Continue without thumbnail - don't fail the entire upload
          thumbnailUrl = '';
          
          // Try to clean up the file anyway
          try {
            await thumbnailService.deleteThumbnailFile(thumbnailFile);
          } catch (_) {}
        }
      }

      // Update progress: Thumbnail uploaded (20%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.2,
      ));

      // Upload video to Cloudflare R2
      debugPrint('📹 Step 3/4: Uploading video to Cloudflare R2...');
      final videoUrl = await _repository.storeFileToStorage(
        file: videoFile,
        reference: 'videos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress: (progress) {
          // Map video upload progress from 20% to 90%
          final mappedProgress = 0.2 + (progress * 0.7);
          final currentState = state.value ?? const AuthenticationState();
          state = AsyncValue.data(currentState.copyWith(
            uploadProgress: mappedProgress,
          ));
        },
      );
      debugPrint('✅ Video uploaded to R2: $videoUrl');

      // Update progress: Video uploaded (90%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.9,
      ));

      // Create video record in database with price
      debugPrint('💾 Step 4/4: Creating video record in database...');
      debugPrint('💰 Video price: ${price ?? 0.0} KES');
      
      final videoData = await _repository.createVideo(
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags ?? [],
        price: price ?? 0.0,
      );
      debugPrint('✅ Video record created in database with price: ${videoData.price}');

      List<VideoModel> updatedVideos = [
        videoData,
        ...currentState.videos,
      ];

      // Update progress: Complete (100%)
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        videos: updatedVideos,
      ));

      debugPrint('✅ Video upload complete with thumbnail and price!');
      onSuccess('Video uploaded successfully');
    } on AuthRepositoryException catch (e) {
      debugPrint('❌ Error uploading video: ${e.message}');
      
      // Clean up thumbnail file if it exists
      if (thumbnailFile != null) {
        try {
          final thumbnailService = VideoThumbnailService();
          await thumbnailService.deleteThumbnailFile(thumbnailFile);
        } catch (_) {}
      }
      
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      ));
      onError(e.message);
    } catch (e) {
      debugPrint('❌ Unexpected error uploading video: $e');
      
      // Clean up thumbnail file if it exists
      if (thumbnailFile != null) {
        try {
          final thumbnailService = VideoThumbnailService();
          await thumbnailService.deleteThumbnailFile(thumbnailFile);
        } catch (_) {}
      }
      
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      ));
      onError('Failed to upload video: $e');
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
    if (currentState.state != AuthState.authenticated ||
        currentState.currentUser == null) {
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

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final imageUrl = await _repository.storeFileToStorage(
          file: file,
          reference:
              'images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        imageUrls.add(imageUrl);
      }

      final postData = await _repository.createImagePost(
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        imageUrls: imageUrls,
        caption: caption,
        tags: tags ?? [],
      );

      List<VideoModel> updatedVideos = [
        postData,
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

  // ===============================
  // VIDEO UPDATE METHODS
  // ===============================

  Future<void> updateVideo({
    required String videoId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated) {
      onError('User not authenticated');
      return;
    }

    try {
      // Call repository to update video
      final updatedVideo = await _repository.updateVideo(
        videoId: videoId,
        caption: caption,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
      );

      // Update local state with the updated video
      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return updatedVideo;
        }
        return video;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));

      onSuccess('Video updated successfully');
    } on AuthRepositoryException catch (e) {
      debugPrint('Error updating video: ${e.message}');
      onError(e.message);
    }
  }

  Future<void> updateVideoCaption({
    required String videoId,
    required String caption,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateVideo(
      videoId: videoId,
      caption: caption,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<void> updateVideoUrl({
    required String videoId,
    required String videoUrl,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateVideo(
      videoId: videoId,
      videoUrl: videoUrl,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<void> updateVideoThumbnail({
    required String videoId,
    required String thumbnailUrl,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateVideo(
      videoId: videoId,
      thumbnailUrl: thumbnailUrl,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<void> updateVideoTags({
    required String videoId,
    required List<String> tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateVideo(
      videoId: videoId,
      tags: tags,
      onSuccess: onSuccess,
      onError: onError,
    );
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

      final updatedVideos =
          currentState.videos.where((video) => video.id != videoId).toList();
      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error deleting video: ${e.message}');
      onError(e.message);
    }
  }

  Future<void> incrementViewCount(String videoId) async {
    try {
      await _repository.incrementViewCount(videoId);

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

      final updatedVideos = currentState.videos.map((video) {
        return video.copyWith(isLiked: likedVideos.contains(video.id));
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } on AuthRepositoryException catch (e) {
      debugPrint('Error loading liked videos: ${e.message}');
    }
  }

  // ===============================
  // USER/SOCIAL METHODS
  // ===============================

  Future<void> loadUsers() async {
    final currentUserId = _repository.currentUserId ?? '';

    try {
      final users = await _repository.getAllUsers(excludeUserId: currentUserId);
      final currentState = state.value ?? const AuthenticationState();

      state = AsyncValue.data(currentState.copyWith(users: users));

      // Cache users list after loading
      if (users.isNotEmpty) {
        await _saveCachedUsers(users);
      }
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
      List<String> followedUsers = List.from(currentState.followedUsers);
      bool isCurrentlyFollowed = followedUsers.contains(userId);

      if (isCurrentlyFollowed) {
        followedUsers.remove(userId);
        await _repository.unfollowUser(
            followerId: currentUserId, userId: userId);
      } else {
        followedUsers.add(userId);
        await _repository.followUser(followerId: currentUserId, userId: userId);
      }

      final updatedUsers = currentState.users.map((user) {
        if (user.uid == userId) {
          return user.copyWith(
            followers:
                isCurrentlyFollowed ? user.followers - 1 : user.followers + 1,
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

      // Update cached users with new follow state
      await _saveCachedUsers(updatedUsers);
    } on AuthRepositoryException catch (e) {
      debugPrint('Error toggling follow: ${e.message}');
      await loadUsers();
      await loadFollowedUsers();
    }
  }

  Future<void> loadFollowedUsers() async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated ||
        currentState.currentUser == null) return;

    try {
      final followedUsers = currentState.currentUser!.followingUIDs;
      state =
          AsyncValue.data(currentState.copyWith(followedUsers: followedUsers));
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

  // ===============================
  // COMMENT METHODS
  // ===============================

  Future<void> addComment({
    required String videoId,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const AuthenticationState();
    if (currentState.state != AuthState.authenticated ||
        currentState.currentUser == null) {
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

  // ===============================
  // UTILITY METHODS
  // ===============================

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
      state: AuthState.authenticated,
      isSuccessful: true,
    ));
  }

  // Helper getters for UI
  bool get isAuthenticated {
    final currentState = state.value;
    return currentState?.state == AuthState.authenticated &&
        currentState?.isSuccessful == true;
  }

  bool get isGuest {
    final currentState = state.value;
    return currentState?.state == AuthState.guest;
  }

  bool get needsProfileCreation {
    final currentState = state.value;
    return currentState?.state == AuthState.partial;
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

  UserPreferences get userPreferences {
    final user = currentUser;
    return user?.preferences ?? const UserPreferences();
  }

  // File operations
  Future<String> storeFileToStorage(
      {required File file, required String reference}) async {
    try {
      return await _repository.storeFileToStorage(
          file: file, reference: reference);
    } on AuthRepositoryException catch (e) {
      throw e.message;
    }
  }
}