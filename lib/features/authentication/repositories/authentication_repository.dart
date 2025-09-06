// lib/features/authentication/repositories/authentication_repository.dart (Updated with syncUserWithBackend)
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import '../../../features/users/models/user_model.dart';
import '../../../constants.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface (updated for Go backend)
abstract class AuthenticationRepository {
  // Authentication operations (Firebase Auth only - unchanged)
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

  // NEW: User sync and data operations (Go backend via HTTP)
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

  // Social operations (Go backend via HTTP)
  Future<void> followUser({required String followerId, required String userId});
  Future<void> unfollowUser({required String followerId, required String userId});
  Future<List<UserModel>> searchUsers({required String query});
  Future<List<UserModel>> getAllUsers({required String excludeUserId});

  // Video operations (Go backend via HTTP)
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

  // Comment operations (Go backend via HTTP)
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

  // File operations (R2 via Go backend)
  Future<String> storeFileToStorage({
    required File file, 
    required String reference,
    Function(double)? onProgress,
  });

  // Current user info (Firebase Auth - unchanged)
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase Auth + Go Backend implementation
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
  // FIREBASE AUTH METHODS (UNCHANGED)
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
  // NEW: USER SYNC OPERATIONS (GO BACKEND VIA HTTP)
  // ===============================

  @override
  Future<UserModel?> syncUserWithBackend(String uid) async {
    try {
      // First check if user exists in backend
      final userExists = await checkUserExists(uid);
      
      if (userExists) {
        // Get existing user data
        return await getUserProfile(uid);
      } else {
        // Create new minimal user with Firebase info
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          throw AuthRepositoryException('No Firebase user found');
        }

        // Create minimal user model
        final newUser = UserModel.create(
          uid: uid,
          name: firebaseUser.displayName ?? '', // Empty name - to be filled later
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImage: firebaseUser.photoURL ?? '',
          bio: '', // Empty bio - to be filled later
        );

        // Create user in backend (no auth middleware required for this endpoint)
        final response = await _httpClient.post('/auth/sync', body: newUser.toMap());
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          return UserModel.fromMap(responseData['user'] ?? responseData);
        } else {
          throw AuthRepositoryException('Failed to create user in backend: ${response.body}');
        }
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to sync user with backend: $e');
    }
  }

  // ===============================
  // USER OPERATIONS (GO BACKEND VIA HTTP)
  // ===============================

  @override
  Future<bool> checkUserExists(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      return response.statusCode == 200;
    } catch (e) {
      if (e is NotFoundException) return false;
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final response = await _httpClient.get('/users/$uid');
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      } else if (response.statusCode == 404) {
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
      UserModel updatedUser = user;

      // Upload profile image if provided
      if (profileImage != null) {
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
      }

      // Upload cover image if provided
      if (coverImage != null) {
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
      }

      // Set creation and update timestamps using proper RFC3339 format
      final timestamp = _createTimestamp();
      final finalUser = updatedUser.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        lastSeen: timestamp,
      );

      // Save to backend (this now works because user exists from sync)
      final response = await _httpClient.put('/users/${finalUser.uid}', body: finalUser.toMap());
      
      if (response.statusCode == 200) {
        return finalUser;
      } else {
        throw AuthRepositoryException('Failed to create user profile: ${response.body}');
      }
    } catch (e) {
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

      // Upload new profile image if provided
      if (profileImage != null) {
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
      }

      // Upload new cover image if provided
      if (coverImage != null) {
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
      }

      // Update timestamp
      final userWithTimestamp = updatedUser.copyWith(
        updatedAt: _createTimestamp(),
      );

      final response = await _httpClient.put('/users/${userWithTimestamp.uid}', 
        body: userWithTimestamp.toMap());

      if (response.statusCode == 200) {
        return userWithTimestamp;
      } else {
        throw AuthRepositoryException('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update user profile: $e');
    }
  }

  // ===============================
  // SOCIAL OPERATIONS (GO BACKEND VIA HTTP)
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
  // VIDEO OPERATIONS (GO BACKEND VIA HTTP) - Keep existing implementation
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
        // Handle both direct video data and wrapped response
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
  // COMMENT OPERATIONS (GO BACKEND VIA HTTP) - Keep existing implementation
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
  // FILE OPERATIONS (R2 VIA GO BACKEND)
  // ===============================

  @override
  Future<String> storeFileToStorage({
    required File file, 
    required String reference,
    Function(double)? onProgress,
  }) async {
    try {
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
        return responseData['url'] as String;
      } else {
        throw AuthRepositoryException('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to upload file: $e');
    }
  }

  // Helper method to determine file type from reference
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner') || reference.contains('cover')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    return 'profile'; // Default to profile
  }
}

// Exception class for repository errors (unchanged)
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);
  
  @override
  String toString() => 'AuthRepositoryException: $message';
}

// Dummy classes for compatibility with existing code
class DocumentSnapshot {
  final bool exists = false;
  final Map<String, dynamic>? data;
  final String id;
  
  DocumentSnapshot({this.data, required this.id});
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs = [];
}

class QueryDocumentSnapshot {
  final Map<String, dynamic> _data;
  final String id;
  
  QueryDocumentSnapshot(this._data, this.id);
  
  Map<String, dynamic> data() => _data;
}