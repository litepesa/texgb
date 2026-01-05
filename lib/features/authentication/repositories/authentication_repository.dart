// lib/features/authentication/repositories/authentication_repository.dart
// ENHANCED VERSION: Firebase Auth + R2 Storage + Video Support + Advanced Comment System + Boost
// 🆕 NEW: Comment media upload, pin/unpin, and enhanced comment operations
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import '../../../features/users/models/user_model.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface (Firebase Auth + Go Backend via HTTP + Advanced Comments)
abstract class AuthenticationRepository {
  // Firebase Authentication only (NO storage)
  Future<bool> checkAuthenticationState();
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  });
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  });
  Future<void> signOut();

  // User operations (Go backend via HTTP)
  Future<UserModel?> syncUserWithBackend(String uid);
  Future<bool> checkUserExists(String uid);
  Future<UserModel?> getUserProfile(String uid);
  Future<UserModel> createUserProfile({
    required UserModel user,
    required File? profileImage,
    required File? coverImage,
  });
  Future<UserModel> updateUserProfile({
    required UserModel user,
    File? profileImage,
    File? coverImage,
  });

  // Social operations
  Future<void> followUser({required String followerId, required String userId});
  Future<void> unfollowUser(
      {required String followerId, required String userId});
  Future<List<UserModel>> searchUsers({required String query});
  Future<List<UserModel>> getAllUsers({required String excludeUserId});

  // Video operations
  Future<List<VideoModel>> getVideos();
  Future<List<VideoModel>> getUserVideos(String userId);
  Future<VideoModel?> getVideoById(String videoId);
  Future<VideoModel> createVideo({
    required String userId,
    required String userName,
    required String userImage,
    required String videoUrl,
    required String thumbnailUrl,
    required String caption,
    List<String>? tags,
    double? price,
  });
  Future<VideoModel> createImagePost({
    required String userId,
    required String userName,
    required String userImage,
    required List<String> imageUrls,
    required String caption,
    List<String>? tags,
    double? price,
  });
  Future<VideoModel> updateVideo({
    required String videoId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    double? price,
  });
  Future<void> deleteVideo(String videoId, String userId);
  Future<void> likeVideo(String videoId, String userId);
  Future<void> unlikeVideo(String videoId, String userId);
  Future<List<String>> getLikedVideos(String userId);
  Future<void> incrementViewCount(String videoId);

  // 🆕 ENHANCED Comment operations with media support
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  });
  Future<List<CommentModel>> getVideoComments(String videoId);
  Future<void> deleteComment(String commentId, String userId);
  Future<void> likeComment(String commentId, String userId);
  Future<void> unlikeComment(String commentId, String userId);

  // 🆕 NEW: Pin/Unpin comment operations
  Future<CommentModel> pinComment(
      String commentId, String videoId, String userId);
  Future<CommentModel> unpinComment(
      String commentId, String videoId, String userId);

  // Boost operations
  Future<VideoModel> boostVideo({
    required String videoId,
    required String userId,
    required String boostTier,
    required int coinAmount,
  });

  // File operations (R2 via Go backend ONLY)
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
    Function(double)? onProgress,
  });

  // 🆕 NEW: Upload multiple files (for comment images)
  Future<List<String>> storeFilesToStorage({
    required List<File> files,
    required String referencePrefix,
    Function(double)? onProgress,
  });

  // Current user info (Firebase Auth only)
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// COMPLETE IMPLEMENTATION: Firebase Auth + Go Backend + Advanced Comment System
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  final FirebaseAuth _auth;
  final HttpClientService _httpClient;

  FirebaseAuthenticationRepository({
    FirebaseAuth? auth,
    HttpClientService? httpClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? HttpClientService();

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // ===============================
  // FIREBASE AUTH METHODS ONLY (NO STORAGE)
  // ===============================

  @override
  Future<bool> checkAuthenticationState() async {
    await Future.delayed(const Duration(seconds: 1));
    return _auth.currentUser != null;
  }

  @override
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw AuthRepositoryException(
            'Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) async {
        context.go(RoutePaths.otp, extra: {
          'verificationId': verificationId,
          'phoneNumber': phoneNumber,
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);
      onSuccess();
    } on FirebaseAuthException catch (e) {
      throw AuthRepositoryException('OTP verification failed: ${e.message}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthRepositoryException('Sign out failed: ${e.message}');
    }
  }

  // ===============================
  // USER SYNC OPERATIONS (GO BACKEND + R2 STORAGE)
  // ===============================

  @override
  Future<UserModel?> syncUserWithBackend(String uid) async {
    try {
      debugPrint('🔄 Syncing user with backend: $uid');

      // First check if user exists in backend
      final userExists = await checkUserExists(uid);

      if (userExists) {
        debugPrint('✅ User exists in backend, fetching profile');
        return await getUserProfile(uid);
      } else {
        debugPrint('🆕 User does not exist, creating new user');

        // Get Firebase user info (PHONE ONLY - no storage access)
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          throw AuthRepositoryException('No Firebase user found');
        }

        // Create minimal user model (PHONE-ONLY, NO Firebase URLs)
        final newUser = UserModel.create(
          uid: uid,
          name: firebaseUser.displayName ?? 'User',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImage: '',
          bio: '',
        );

        debugPrint('📤 Sending user data to backend: ${newUser.toMap()}');

        // Create user in backend
        final response =
            await _httpClient.post('/auth/sync', body: newUser.toMap());

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          final userData = responseData['user'] ?? responseData;
          debugPrint('✅ User created successfully');
          return UserModel.fromMap(userData);
        } else {
          debugPrint(
              '❌ Failed to create user: ${response.statusCode} - ${response.body}');
          throw AuthRepositoryException(
              'Failed to create user in backend: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ syncUserWithBackend error: $e');
      throw AuthRepositoryException('Failed to sync user with backend: $e');
    }
  }

  // ===============================
  // USER OPERATIONS (GO BACKEND)
  // ===============================

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      debugPrint('🔍 Checking if user exists: $uid');
      final response = await _httpClient.get('/users/$uid');
      final exists = response.statusCode == 200;
      debugPrint('👤 User exists: $exists');
      return exists;
    } catch (e) {
      if (e is NotFoundException) return false;
      debugPrint('❌ Error checking user existence: $e');
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      debugPrint('📥 Getting user profile: $uid');
      final response = await _httpClient.get('/users/$uid');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ User profile retrieved: ${userData['name']}');
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        debugPrint('🚫 User not found: $uid');
        return null;
      } else {
        throw AuthRepositoryException(
            'Failed to get user profile: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get user profile: $e');
    }
  }

  @override
  Future<UserModel> createUserProfile({
    required UserModel user,
    required File? profileImage,
    required File? coverImage,
  }) async {
    try {
      debugPrint('🗃️ Creating user profile: ${user.name}');
      UserModel updatedUser = user;

      // Upload profile image to R2 (NOT Firebase)
      if (profileImage != null) {
        debugPrint('📸 Uploading profile image to R2...');
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
        debugPrint('✅ Profile image uploaded to R2: $profileImageUrl');
      }

      // Upload cover image to R2 (NOT Firebase)
      if (coverImage != null) {
        debugPrint('🖼️ Uploading cover image to R2...');
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
        debugPrint('✅ Cover image uploaded to R2: $coverImageUrl');
      }

      // Set creation and update timestamps
      final timestamp = _createTimestamp();
      final finalUser = updatedUser.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        lastSeen: timestamp,
      );

      debugPrint('📤 Creating user profile in backend...');

      final response =
          await _httpClient.post('/auth/sync', body: finalUser.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['user'] ?? responseData;
        final createdUser = UserModel.fromMap(userData);

        debugPrint('✅ User profile created successfully');
        return createdUser;
      } else {
        debugPrint(
            '❌ Failed to create user profile: ${response.statusCode} - ${response.body}');
        throw AuthRepositoryException(
            'Failed to create user profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      throw AuthRepositoryException('Failed to create user profile: $e');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required UserModel user,
    File? profileImage,
    File? coverImage,
  }) async {
    try {
      UserModel updatedUser = user;

      // Upload new profile image to R2 (NOT Firebase)
      if (profileImage != null) {
        debugPrint('📸 Uploading new profile image to R2...');
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
        debugPrint('✅ New profile image uploaded to R2: $profileImageUrl');
      }

      // Upload new cover image to R2 (NOT Firebase)
      if (coverImage != null) {
        debugPrint('🖼️ Uploading new cover image to R2...');
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
        debugPrint('✅ New cover image uploaded to R2: $coverImageUrl');
      }

      // Update timestamp
      final userWithTimestamp = updatedUser.copyWith(
        updatedAt: _createTimestamp(),
      );

      final response = await _httpClient.put('/users/${userWithTimestamp.uid}',
          body: userWithTimestamp.toMap());

      if (response.statusCode == 200) {
        debugPrint('✅ User profile updated successfully');
        return userWithTimestamp;
      } else {
        throw AuthRepositoryException(
            'Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update user profile: $e');
    }
  }

  // ===============================
  // SOCIAL OPERATIONS
  // ===============================

  @override
  Future<void> followUser(
      {required String followerId, required String userId}) async {
    try {
      final response = await _httpClient.post('/users/$userId/follow', body: {
        'followerId': followerId,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException(
            'Failed to follow user: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to follow user: $e');
    }
  }

  @override
  Future<void> unfollowUser(
      {required String followerId, required String userId}) async {
    try {
      final response = await _httpClient
          .delete('/users/$userId/follow?followerId=$followerId');

      if (response.statusCode != 200) {
        throw AuthRepositoryException(
            'Failed to unfollow user: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unfollow user: $e');
    }
  }

  @override
  Future<List<UserModel>> searchUsers({required String query}) async {
    try {
      final response = await _httpClient
          .get('/users/search?q=${Uri.encodeComponent(query)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> usersData = responseData['users'] ?? [];
        return usersData
            .map((userData) =>
                UserModel.fromMap(userData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException(
            'Failed to search users: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to search users: $e');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers({required String excludeUserId}) async {
    try {
      final response = await _httpClient.get('/users?exclude=$excludeUserId');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> usersData = responseData['users'] ?? [];
        return usersData
            .map((userData) =>
                UserModel.fromMap(userData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException(
            'Failed to get all users: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get all users: $e');
    }
  }

  // ===============================
  // VIDEO OPERATIONS (WITH PRICE SUPPORT)
  // ===============================

  @override
  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await _httpClient.get('/videos');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> videosData = responseData['videos'] ?? [];
        return videosData
            .map((videoData) =>
                VideoModel.fromJson(videoData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get videos: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get videos: $e');
    }
  }

  @override
  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/videos');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> videosData = responseData['videos'] ?? [];
        return videosData
            .map((videoData) =>
                VideoModel.fromJson(videoData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException(
            'Failed to get user videos: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get user videos: $e');
    }
  }

  @override
  Future<VideoModel?> getVideoById(String videoId) async {
    try {
      final response = await _httpClient.get('/videos/$videoId');

      if (response.statusCode == 200) {
        final videoData = jsonDecode(response.body) as Map<String, dynamic>;
        return VideoModel.fromJson(videoData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException(
            'Failed to get video by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get video by ID: $e');
    }
  }

  @override
  Future<VideoModel> createVideo({
    required String userId,
    required String userName,
    required String userImage,
    required String videoUrl,
    required String thumbnailUrl,
    required String caption,
    List<String>? tags,
    double? price,
  }) async {
    try {
      final timestamp = _createTimestamp();

      final videoData = {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'price': price ?? 0.0,
        'tags': tags ?? [],
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
        'sharesCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isActive': true,
        'isFeatured': false,
        'isMultipleImages': false,
        'imageUrls': <String>[],
      };

      final response = await _httpClient.post('/videos', body: videoData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video')
            ? responseData['video']
            : responseData;
        return VideoModel.fromJson(videoMap);
      } else {
        throw AuthRepositoryException(
            'Failed to create video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to create video: $e');
    }
  }

  @override
  Future<VideoModel> createImagePost({
    required String userId,
    required String userName,
    required String userImage,
    required List<String> imageUrls,
    required String caption,
    List<String>? tags,
    double? price,
  }) async {
    try {
      final timestamp = _createTimestamp();

      final postData = {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'videoUrl': '',
        'thumbnailUrl': imageUrls.isNotEmpty ? imageUrls.first : '',
        'caption': caption,
        'price': price ?? 0.0,
        'tags': tags ?? [],
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
        'sharesCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isActive': true,
        'isFeatured': false,
        'isMultipleImages': true,
        'imageUrls': imageUrls,
      };

      final response = await _httpClient.post('/videos', body: postData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video')
            ? responseData['video']
            : responseData;
        return VideoModel.fromJson(videoMap);
      } else {
        throw AuthRepositoryException(
            'Failed to create image post: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to create image post: $e');
    }
  }

  @override
  Future<VideoModel> updateVideo({
    required String videoId,
    String? caption,
    double? price,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    try {
      debugPrint('🔄 Updating video: $videoId');

      final Map<String, dynamic> updateData = {
        'updatedAt': _createTimestamp(),
      };

      if (caption != null) updateData['caption'] = caption;
      if (price != null) updateData['price'] = price;
      if (videoUrl != null) updateData['videoUrl'] = videoUrl;
      if (thumbnailUrl != null) updateData['thumbnailUrl'] = thumbnailUrl;
      if (tags != null) updateData['tags'] = tags;

      final response =
          await _httpClient.put('/videos/$videoId', body: updateData);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video')
            ? responseData['video']
            : responseData;
        return VideoModel.fromJson(videoMap);
      } else {
        throw AuthRepositoryException(
            'Failed to update video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update video: $e');
    }
  }

  @override
  Future<void> deleteVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.delete('/videos/$videoId');

      if (response.statusCode != 200) {
        throw AuthRepositoryException(
            'Failed to delete video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete video: $e');
    }
  }

  @override
  Future<void> likeVideo(String videoId, String userId) async {
    try {
      final response =
          await _httpClient.post('/videos/$videoId/like', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to like video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to like video: $e');
    }
  }

  @override
  Future<void> unlikeVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.delete('/videos/$videoId/like');

      if (response.statusCode != 200) {
        throw AuthRepositoryException(
            'Failed to unlike video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unlike video: $e');
    }
  }

  @override
  Future<List<String>> getLikedVideos(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/liked-videos');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> likedVideosData = responseData['videos'] ?? [];
        return likedVideosData.cast<String>();
      } else {
        throw AuthRepositoryException(
            'Failed to get liked videos: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get liked videos: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String videoId) async {
    try {
      final response =
          await _httpClient.post('/videos/$videoId/views', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException(
            'Failed to increment view count: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to increment view count: $e');
    }
  }

  // ===============================
  // 🆕 ENHANCED COMMENT OPERATIONS WITH MEDIA SUPPORT
  // ===============================

  @override
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) async {
    try {
      debugPrint('💬 Adding comment to video: $videoId');
      if (imageUrls != null && imageUrls.isNotEmpty) {
        debugPrint('📸 Comment includes ${imageUrls.length} image(s)');
      }

      final timestamp = _createTimestamp();

      final commentData = {
        'videoId': videoId,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'content': content.trim(),
        'imageUrls': imageUrls ?? [],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'likesCount': 0,
        'isReply': repliedToCommentId != null,
        'isPinned': false,
        'isEdited': false,
        'isActive': true,
        if (repliedToCommentId != null)
          'repliedToCommentId': repliedToCommentId,
        if (repliedToCommentId != null) 'parentCommentId': repliedToCommentId,
        if (repliedToAuthorName != null)
          'repliedToAuthorName': repliedToAuthorName,
      };

      final response = await _httpClient.post('/videos/$videoId/comments',
          body: commentData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Comment added successfully');
        return CommentModel.fromJson(responseData);
      } else {
        debugPrint(
            '❌ Failed to add comment: ${response.statusCode} - ${response.body}');
        throw AuthRepositoryException(
            'Failed to add comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error adding comment: $e');
      throw AuthRepositoryException('Failed to add comment: $e');
    }
  }

  @override
  Future<List<CommentModel>> getVideoComments(String videoId) async {
    try {
      debugPrint('📥 Fetching comments for video: $videoId');
      final response = await _httpClient.get('/videos/$videoId/comments');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> commentsData = responseData['comments'] ?? [];

        final comments = commentsData.map((commentData) {
          final Map<String, dynamic> data = commentData as Map<String, dynamic>;
          return CommentModel.fromJson(data);
        }).toList();

        debugPrint('✅ Retrieved ${comments.length} comments');
        return comments;
      } else {
        throw AuthRepositoryException(
            'Failed to get video comments: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching comments: $e');
      throw AuthRepositoryException('Failed to get video comments: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      debugPrint('🗑️ Deleting comment: $commentId');
      final response =
          await _httpClient.delete('/comments/$commentId?userId=$userId');

      if (response.statusCode == 200) {
        debugPrint('✅ Comment deleted successfully');
      } else {
        throw AuthRepositoryException(
            'Failed to delete comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      throw AuthRepositoryException('Failed to delete comment: $e');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    try {
      debugPrint('❤️ Liking comment: $commentId');
      final response =
          await _httpClient.post('/comments/$commentId/like', body: {
        'userId': userId,
      });

      if (response.statusCode == 200) {
        debugPrint('✅ Comment liked successfully');
      } else {
        throw AuthRepositoryException(
            'Failed to like comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error liking comment: $e');
      throw AuthRepositoryException('Failed to like comment: $e');
    }
  }

  @override
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      debugPrint('💔 Unliking comment: $commentId');
      final response =
          await _httpClient.delete('/comments/$commentId/like?userId=$userId');

      if (response.statusCode == 200) {
        debugPrint('✅ Comment unliked successfully');
      } else {
        throw AuthRepositoryException(
            'Failed to unlike comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error unliking comment: $e');
      throw AuthRepositoryException('Failed to unlike comment: $e');
    }
  }

  // 🆕 NEW: Pin comment operation
  @override
  Future<CommentModel> pinComment(
      String commentId, String videoId, String userId) async {
    try {
      debugPrint('📌 Pinning comment: $commentId');
      final response =
          await _httpClient.post('/comments/$commentId/pin', body: {
        'videoId': videoId,
        'userId': userId,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Comment pinned successfully');
        return CommentModel.fromJson(responseData);
      } else {
        debugPrint(
            '❌ Failed to pin comment: ${response.statusCode} - ${response.body}');
        throw AuthRepositoryException(
            'Failed to pin comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error pinning comment: $e');
      throw AuthRepositoryException('Failed to pin comment: $e');
    }
  }

  // 🆕 NEW: Unpin comment operation
  @override
  Future<CommentModel> unpinComment(
      String commentId, String videoId, String userId) async {
    try {
      debugPrint('📍 Unpinning comment: $commentId');
      final response = await _httpClient
          .delete('/comments/$commentId/pin?videoId=$videoId&userId=$userId');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Comment unpinned successfully');
        return CommentModel.fromJson(responseData);
      } else {
        debugPrint(
            '❌ Failed to unpin comment: ${response.statusCode} - ${response.body}');
        throw AuthRepositoryException(
            'Failed to unpin comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error unpinning comment: $e');
      throw AuthRepositoryException('Failed to unpin comment: $e');
    }
  }

  // ===============================
  // BOOST OPERATIONS
  // ===============================

  @override
  Future<VideoModel> boostVideo({
    required String videoId,
    required String userId,
    required String boostTier,
    required int coinAmount,
  }) async {
    try {
      debugPrint('🚀 Boosting video: $videoId with tier: $boostTier');

      final response = await _httpClient.post('/videos/$videoId/boost', body: {
        'userId': userId,
        'boostTier': boostTier,
        'coinAmount': coinAmount,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video')
            ? responseData['video']
            : responseData;
        debugPrint('✅ Video boosted successfully');
        return VideoModel.fromJson(videoMap);
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorData['error'] ?? errorData['message'] ?? 'Unknown error';
          throw AuthRepositoryException('Failed to boost video: $errorMessage');
        } catch (_) {
          throw AuthRepositoryException(
              'Failed to boost video: ${response.body}');
        }
      }
    } catch (e) {
      if (e is AuthRepositoryException) rethrow;
      throw AuthRepositoryException('Failed to boost video: $e');
    }
  }

  // ===============================
  // R2 STORAGE OPERATIONS (VIA GO BACKEND)
  // ===============================

  @override
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file before uploading
      if (!await file.exists()) {
        throw AuthRepositoryException('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw AuthRepositoryException('File is empty (0 bytes): ${file.path}');
      }

      debugPrint(
          '☁️ Uploading file to R2: $reference (${fileSize / (1024 * 1024)}MB)');

      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {
          'type': _getFileTypeFromReference(reference),
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final r2Url = responseData['url'] as String;
        debugPrint('✅ File uploaded to R2: $r2Url');
        return r2Url;
      } else {
        throw AuthRepositoryException(
            'Failed to upload file to R2: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ R2 upload failed: $e');
      throw AuthRepositoryException('Failed to upload file to R2: $e');
    }
  }

  // 🆕 NEW: Upload multiple files (for comment images)
  @override
  Future<List<String>> storeFilesToStorage({
    required List<File> files,
    required String referencePrefix,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('☁️ Uploading ${files.length} files to R2...');

      final List<String> uploadedUrls = [];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final reference =
            '$referencePrefix/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        debugPrint('📤 Uploading file ${i + 1}/${files.length}: $reference');

        final url = await storeFileToStorage(
          file: file,
          reference: reference,
          onProgress: onProgress,
        );

        uploadedUrls.add(url);

        // Update overall progress
        if (onProgress != null) {
          final progress = (i + 1) / files.length;
          onProgress(progress);
        }
      }

      debugPrint('✅ All ${files.length} files uploaded successfully');
      return uploadedUrls;
    } catch (e) {
      debugPrint('❌ Multiple files upload failed: $e');
      throw AuthRepositoryException('Failed to upload files to R2: $e');
    }
  }

  // Helper method to determine file type from reference
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages'))
      return 'profile';
    if (reference.contains('banner') || reference.contains('cover'))
      return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    if (reference.contains('comment')) return 'comment';
    return 'profile';
  }

  // ===============================
  // ADDITIONAL HELPER METHODS
  // ===============================

  Future<bool> testBackendConnection() async {
    try {
      return await _httpClient.testConnection();
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }

  Future<String?> getCurrentUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get current user token: $e');
      return null;
    }
  }

  Future<String?> refreshUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to refresh user token: $e');
      return null;
    }
  }

  bool get isUserAuthenticated => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserDisplayName => _auth.currentUser?.displayName;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Stream<User?> get userChanges => _auth.userChanges();
}

// ===============================
// EXCEPTION CLASSES
// ===============================

class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);

  @override
  String toString() => 'AuthRepositoryException: $message';
}

class NotFoundException extends AuthRepositoryException {
  const NotFoundException(super.message);
}
