// lib/features/authentication/repositories/authentication_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/users/models/user_model.dart';
import '../../../constants.dart';
import '../../../shared/services/http_client.dart';
import '../../videos/models/video_model.dart';
import '../../comments/models/comment_model.dart';

// Abstract repository interface
abstract class AuthenticationRepository {
  // Firebase Auth operations (unchanged)
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
  Future<bool> checkUserExists(String userId);
  Future<UserModel?> getUserProfile(String userId);
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
  Future<void> deleteUserProfile(String userId);

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

  // Deprecated Firestore streams - keep for compatibility but make them no-ops
  Stream<DocumentSnapshot> userStream({required String userId});
  Stream<QuerySnapshot> getAllUsersStream({required String excludeUserId});
  Stream<QuerySnapshot> getVideosStream();
  Stream<List<CommentModel>> getCommentsStream(String videoId);

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
  // USER OPERATIONS (GO BACKEND VIA HTTP)
  // ===============================

  @override
  Future<bool> checkUserExists(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId');
      return response.statusCode == 200;
    } catch (e) {
      if (e is NotFoundException) return false;
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId');
      
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

      // Save to backend
      final response = await _httpClient.post('/users', body: finalUser.toMap());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
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

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      final response = await _httpClient.put('/users/$userId', body: {'isActive': false});
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to delete user profile: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete user profile: $e');
    }
  }

  // ===============================
  // SOCIAL OPERATIONS (GO BACKEND VIA HTTP)
  // ===============================

  @override
  Future<void> followUser({required String followerId, required String userId}) async {
    try {
      final response = await _httpClient.post('/users/$followerId/follow', body: {
        'targetUserId': userId,
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
      final response = await _httpClient.post('/users/$followerId/unfollow', body: {
        'targetUserId': userId,
      });

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
        final List<dynamic> usersData = jsonDecode(response.body);
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
        final List<dynamic> usersData = jsonDecode(response.body);
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
  // VIDEO OPERATIONS (GO BACKEND VIA HTTP)
  // ===============================

  @override
  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await _httpClient.get('/videos');
      
      if (response.statusCode == 200) {
        final List<dynamic> videosData = jsonDecode(response.body);
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
        final List<dynamic> videosData = jsonDecode(response.body);
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
        'likes': 0,
        'comments': 0,
        'views': 0,
        'shares': 0,
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
        return VideoModel.fromMap(responseData);
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
        'likes': 0,
        'comments': 0,
        'views': 0,
        'shares': 0,
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
        return VideoModel.fromMap(responseData);
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
      final response = await _httpClient.delete('/videos/$videoId?userId=$userId');
      
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
      final response = await _httpClient.post('/videos/$videoId/like', body: {
        'userId': userId,
      });

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
      final response = await _httpClient.post('/videos/$videoId/unlike', body: {
        'userId': userId,
      });

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
        final List<dynamic> likedVideosData = jsonDecode(response.body);
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
      final response = await _httpClient.post('/videos/$videoId/view', body: {});
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to increment view count: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to increment view count: $e');
    }
  }

  // ===============================
  // COMMENT OPERATIONS (GO BACKEND VIA HTTP)
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
        'likedBy': <String>[],
        'likesCount': 0,
        'isReply': repliedToCommentId != null,
        if (repliedToCommentId != null) 'repliedToCommentId': repliedToCommentId,
        if (repliedToAuthorName != null) 'repliedToAuthorName': repliedToAuthorName,
      };

      final response = await _httpClient.post('/comments', body: commentData);
      
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
        final List<dynamic> commentsData = jsonDecode(response.body);
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
      final response = await _httpClient.delete('/comments/$commentId?userId=$userId');
      
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
      final response = await _httpClient.post('/comments/$commentId/like', body: {
        'userId': userId,
      });

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
      final response = await _httpClient.post('/comments/$commentId/unlike', body: {
        'userId': userId,
      });

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

  // ===============================
  // DEPRECATED STREAM METHODS (NO-OPS FOR COMPATIBILITY)
  // ===============================

  @override
  Stream<DocumentSnapshot> userStream({required String userId}) {
    // Return empty stream for compatibility - streams are deprecated with HTTP backend
    return const Stream.empty();
  }

  @override
  Stream<QuerySnapshot> getAllUsersStream({required String excludeUserId}) {
    // Return empty stream for compatibility - streams are deprecated with HTTP backend
    return const Stream.empty();
  }

  @override
  Stream<QuerySnapshot> getVideosStream() {
    // Return empty stream for compatibility - streams are deprecated with HTTP backend
    return const Stream.empty();
  }

  @override
  Stream<List<CommentModel>> getCommentsStream(String videoId) {
    // Return empty stream for compatibility - streams are deprecated with HTTP backend
    return const Stream.empty();
  }

  // ===============================
  // ADDITIONAL HELPER METHODS
  // ===============================

  // Test backend connection
  Future<bool> testBackendConnection() async {
    try {
      return await _httpClient.testConnection();
    } catch (e) {
      debugPrint('Backend connection test failed: $e');
      return false;
    }
  }

  // Get current user's Firebase token
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

  // Refresh user token
  Future<String?> refreshUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // Force refresh
      }
      return null;
    } catch (e) {
      debugPrint('Failed to refresh user token: $e');
      return null;
    }
  }

  // Check if current user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Get current user's email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user's display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Listen to user changes
  Stream<User?> get userChanges => _auth.userChanges();
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