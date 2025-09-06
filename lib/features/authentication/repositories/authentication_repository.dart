// lib/features/authentication/repositories/authentication_repository.dart
// CLEAN VERSION: Firebase Auth + R2 Storage Only (NO Firebase Storage)
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import '../../../features/users/models/user_model.dart';
import '../../../constants.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface (Firebase Auth + Go Backend via HTTP)
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
  Future<void> unfollowUser({required String followerId, required String userId});
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
  });
  Future<VideoModel> createImagePost({
    required String userId,
    required String userName,
    required String userImage,
    required List<String> imageUrls,
    required String caption,
    List<String>? tags,
  });
  Future<void> deleteVideo(String videoId, String userId);
  Future<void> likeVideo(String videoId, String userId);
  Future<void> unlikeVideo(String videoId, String userId);
  Future<List<String>> getLikedVideos(String userId);
  Future<void> incrementViewCount(String videoId);

  // Comment operations
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  });
  Future<List<CommentModel>> getVideoComments(String videoId);
  Future<void> deleteComment(String commentId, String userId);
  Future<void> likeComment(String commentId, String userId);
  Future<void> unlikeComment(String commentId, String userId);

  // File operations (R2 via Go backend ONLY)
  Future<String> storeFileToStorage({
    required File file, 
    required String reference,
    Function(double)? onProgress,
  });

  // Current user info (Firebase Auth only)
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// CLEAN IMPLEMENTATION: Firebase Auth + Go Backend (NO Firebase Storage)
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  final FirebaseAuth _auth;
  final HttpClientService _httpClient;

  FirebaseAuthenticationRepository({
    FirebaseAuth? auth,
    HttpClientService? httpClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
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
        throw AuthRepositoryException('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.of(context).pushNamed(
          Constants.otpScreen,
          arguments: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: phoneNumber,
          },
        );
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
          name: firebaseUser.displayName ?? 'User', // Default name if empty
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImage: '', // EMPTY - will be uploaded to R2 during profile setup
          bio: '', // Empty bio - to be filled later
        );

        debugPrint('📤 Sending user data to backend: ${newUser.toMap()}');

        // Create user in backend (no auth middleware required for this endpoint)
        final response = await _httpClient.post('/auth/sync', body: newUser.toMap());
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final userData = responseData['user'] ?? responseData;
          debugPrint('✅ User created successfully: $userData');
          return UserModel.fromMap(userData);
        } else {
          debugPrint('❌ Failed to create user: ${response.statusCode} - ${response.body}');
          throw AuthRepositoryException('Failed to create user in backend: ${response.body}');
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
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ User profile retrieved: ${userData['name']}');
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
        debugPrint('🚫 User not found: $uid');
        return null;
      } else {
        throw AuthRepositoryException('Failed to get user profile: ${response.body}');
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
      debugPrint('🏗️ Creating user profile: ${user.name}');
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

      debugPrint('📤 Updating user profile in backend...');
      final response = await _httpClient.put('/users/${finalUser.uid}', body: finalUser.toMap());
      
      if (response.statusCode == 200) {
        debugPrint('✅ User profile created successfully');
        return finalUser;
      } else {
        throw AuthRepositoryException('Failed to create user profile: ${response.body}');
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
        throw AuthRepositoryException('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update user profile: $e');
    }
  }

  // ===============================
  // SOCIAL OPERATIONS
  // ===============================

  @override
  Future<void> followUser({required String followerId, required String userId}) async {
    try {
      final response = await _httpClient.post('/users/$userId/follow', body: {
        'followerId': followerId,
      });

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to follow user: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to follow user: $e');
    }
  }

  @override
  Future<void> unfollowUser({required String followerId, required String userId}) async {
    try {
      final response = await _httpClient.delete('/users/$userId/follow?followerId=$followerId');

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to unfollow user: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unfollow user: $e');
    }
  }

  @override
  Future<List<UserModel>> searchUsers({required String query}) async {
    try {
      final response = await _httpClient.get('/users/search?q=${Uri.encodeComponent(query)}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> usersData = responseData['users'] ?? [];
        return usersData
            .map((userData) => UserModel.fromMap(userData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to search users: ${response.body}');
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
            .map((userData) => UserModel.fromMap(userData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get all users: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get all users: $e');
    }
  }

  // ===============================
  // VIDEO OPERATIONS
  // ===============================

  @override
  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await _httpClient.get('/videos');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> videosData = responseData['videos'] ?? [];
        return videosData
            .map((videoData) => VideoModel.fromMap(videoData as Map<String, dynamic>))
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
            .map((videoData) => VideoModel.fromMap(videoData as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get user videos: ${response.body}');
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
        return VideoModel.fromMap(videoData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get video by ID: ${response.body}');
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
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
        'sharesCount': 0,
        'tags': tags ?? [],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'isActive': true,
        'isFeatured': false,
        'isMultipleImages': false,
        'imageUrls': [],
      };

      final response = await _httpClient.post('/videos', body: videoData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] : responseData;
        return VideoModel.fromMap(videoMap);
      } else {
        throw AuthRepositoryException('Failed to create video: ${response.body}');
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
        'likesCount': 0,
        'commentsCount': 0,
        'viewsCount': 0,
        'sharesCount': 0,
        'tags': tags ?? [],
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
        final videoMap = responseData.containsKey('video') ? responseData['video'] : responseData;
        return VideoModel.fromMap(videoMap);
      } else {
        throw AuthRepositoryException('Failed to create image post: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to create image post: $e');
    }
  }

  @override
  Future<void> deleteVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.delete('/videos/$videoId');
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to delete video: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete video: $e');
    }
  }

  @override
  Future<void> likeVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.post('/videos/$videoId/like', body: {});

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
        throw AuthRepositoryException('Failed to unlike video: ${response.body}');
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
        throw AuthRepositoryException('Failed to get liked videos: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get liked videos: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String videoId) async {
    try {
      final response = await _httpClient.post('/videos/$videoId/views', body: {});
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to increment view count: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to increment view count: $e');
    }
  }

  // ===============================
  // COMMENT OPERATIONS
  // ===============================

  @override
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) async {
    try {
      final timestamp = _createTimestamp();
      
      final commentData = {
        'videoId': videoId,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'content': content.trim(),
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'likesCount': 0,
        'isReply': repliedToCommentId != null,
        if (repliedToCommentId != null) 'repliedToCommentId': repliedToCommentId,
        if (repliedToAuthorName != null) 'repliedToAuthorName': repliedToAuthorName,
      };

      final response = await _httpClient.post('/videos/$videoId/comments', body: commentData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CommentModel.fromMap(responseData, responseData['id'] ?? '');
      } else {
        throw AuthRepositoryException('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to add comment: $e');
    }
  }

  @override
  Future<List<CommentModel>> getVideoComments(String videoId) async {
    try {
      final response = await _httpClient.get('/videos/$videoId/comments');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> commentsData = responseData['comments'] ?? [];
        return commentsData.map((commentData) {
          final Map<String, dynamic> data = commentData as Map<String, dynamic>;
          return CommentModel.fromMap(data, data['id'] ?? '');
        }).toList();
      } else {
        throw AuthRepositoryException('Failed to get video comments: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get video comments: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.delete('/comments/$commentId');
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to delete comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete comment: $e');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.post('/comments/$commentId/like', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to like comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to like comment: $e');
    }
  }

  @override
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.post('/comments/$commentId/unlike', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to unlike comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unlike comment: $e');
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
      debugPrint('☁️ Uploading file to R2 via backend: $reference');
      
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
        debugPrint('✅ File uploaded to R2 successfully: $r2Url');
        return r2Url;
      } else {
        throw AuthRepositoryException('Failed to upload file to R2: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ R2 upload failed: $e');
      throw AuthRepositoryException('Failed to upload file to R2: $e');
    }
  }

  // Helper method to determine file type from reference for R2 storage
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner') || reference.contains('cover')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    return 'profile'; // Default to profile
  }
}

// Exception class for repository errors
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);
  
  @override
  String toString() => 'AuthRepositoryException: $message';
}

// HTTP exception classes for compatibility
class NotFoundException extends AuthRepositoryException {
  const NotFoundException(String message) : super(message);
}