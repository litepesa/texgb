// lib/features/authentication/repositories/authentication_repository.dart
// COMPLETE VERSION: Firebase Auth + R2 Storage + Video + Series + Enhanced Comments
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/threads/models/comment_model.dart';
import 'package:textgb/features/threads/models/series_model.dart';
import 'package:textgb/features/threads/models/series_unlock_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import '../../../features/users/models/user_model.dart';
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

  // ===============================
  // 🆕 SERIES OPERATIONS
  // ===============================
  
  // Series CRUD
  Future<SeriesModel> createSeries({
    required String creatorId,
    required String creatorName,
    required String creatorImage,
    required String title,
    required String description,
    required String bannerImage,
    required List<String> episodeVideoUrls,
    required List<String> episodeThumbnails,
    required List<int> episodeDurations,
    required double unlockPrice,
    required int freeEpisodesCount,
    bool allowReposts = true,
    bool hasAffiliateProgram = false,
    double affiliateCommission = 0.0,
    List<String>? tags,
  });
  
  Future<List<SeriesModel>> getAllSeries();
  Future<List<SeriesModel>> getUserSeries(String userId);
  Future<SeriesModel?> getSeriesById(String seriesId);
  
  Future<SeriesModel> updateSeries({
    required String seriesId,
    String? title,
    String? description,
    String? bannerImage,
    List<String>? episodeVideoUrls,
    List<String>? episodeThumbnails,
    List<int>? episodeDurations,
    double? unlockPrice,
    int? freeEpisodesCount,
    bool? allowReposts,
    bool? hasAffiliateProgram,
    double? affiliateCommission,
    List<String>? tags,
  });
  
  Future<void> deleteSeries(String seriesId, String userId);
  
  // Series interactions
  Future<void> likeSeries(String seriesId, String userId);
  Future<void> unlikeSeries(String seriesId, String userId);
  Future<void> favoriteSeries(String seriesId, String userId);
  Future<void> unfavoriteSeries(String seriesId, String userId);
  Future<void> incrementSeriesViewCount(String seriesId);
  
  // Series unlock/purchase
  Future<SeriesUnlockModel> unlockSeries({
    required String userId,
    required String seriesId,
    required String originalCreatorId,
    String? sharedByUserId,
    bool hasAffiliateEarnings = false,
    double affiliateCommission = 0.0,
    double affiliateEarnings = 0.0,
    required double unlockPrice,
    String paymentMethod = 'M-Pesa',
    String? transactionId,
    required String seriesTitle,
    required String creatorName,
    required int totalEpisodes,
  });
  
  Future<bool> hasUnlockedSeries(String userId, String seriesId);
  Future<SeriesUnlockModel?> getSeriesUnlock(String userId, String seriesId);
  Future<List<SeriesUnlockModel>> getUserUnlocks(String userId);
  
  // Episode progress tracking
  Future<SeriesUnlockModel> updateEpisodeProgress({
    required String unlockId,
    required int episodeNumber,
  });
  
  Future<SeriesUnlockModel> completeEpisode({
    required String unlockId,
    required int episodeNumber,
  });
  
  // Series statistics
  Future<Map<String, dynamic>> getSeriesStats(String seriesId);

  // ===============================
  // 🆕 ENHANCED COMMENT OPERATIONS (WITH MEDIA)
  // ===============================
  
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls, // 🆕 Support 0-2 images/GIFs
    String? parentCommentId,
    String? replyToUserId,
    String? replyToUserName,
  });
  
  Future<List<CommentModel>> getVideoComments(String videoId);
  Future<CommentModel?> getCommentById(String commentId);
  
  Future<CommentModel> updateComment({
    required String commentId,
    required String content,
    List<String>? imageUrls,
  });
  
  Future<void> deleteComment(String commentId, String userId);
  Future<void> likeComment(String commentId, String userId);
  Future<void> unlikeComment(String commentId, String userId);
  
  // 🆕 Pin comment (video creator only)
  Future<void> pinComment(String commentId, String videoId, String userId);
  Future<void> unpinComment(String commentId, String videoId, String userId);

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

// COMPLETE IMPLEMENTATION: Firebase Auth + Go Backend
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
          '/otp',
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
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
      debugPrint('📄 Syncing user with backend: $uid');
      
      final userExists = await checkUserExists(uid);
      
      if (userExists) {
        debugPrint('✅ User exists in backend, fetching profile');
        return await getUserProfile(uid);
      } else {
        debugPrint('🆕 User does not exist, creating new user');
        
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null) {
          throw AuthRepositoryException('No Firebase user found');
        }

        final newUser = UserModel.create(
          uid: uid,
          name: firebaseUser.displayName ?? 'User',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          profileImage: '',
          bio: '',
        );

        debugPrint('📤 Sending user data to backend: ${newUser.toMap()}');

        final response = await _httpClient.post('/auth/sync', body: newUser.toMap());
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final userData = responseData['user'] ?? responseData;
          debugPrint('✅ User created successfully');
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
      debugPrint('🔥 Getting user profile: $uid');
      final response = await _httpClient.get('/users/$uid');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
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
      debugPrint('🗃️ Creating user profile: ${user.name}');
      UserModel updatedUser = user;

      if (profileImage != null) {
        debugPrint('📸 Uploading profile image to R2...');
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
        debugPrint('✅ Profile image uploaded to R2: $profileImageUrl');
      }

      if (coverImage != null) {
        debugPrint('🖼️ Uploading cover image to R2...');
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
        debugPrint('✅ Cover image uploaded to R2: $coverImageUrl');
      }

      final timestamp = _createTimestamp();
      final finalUser = updatedUser.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        lastSeen: timestamp,
      );

      debugPrint('📤 Creating user profile in backend...');
      
      final response = await _httpClient.post('/auth/sync', body: finalUser.toMap());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = responseData['user'] ?? responseData;
        final createdUser = UserModel.fromMap(userData);
        
        debugPrint('✅ User profile created successfully');
        return createdUser;
      } else {
        debugPrint('❌ Failed to create user profile: ${response.statusCode} - ${response.body}');
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

      if (profileImage != null) {
        debugPrint('📸 Uploading new profile image to R2...');
        String profileImageUrl = await storeFileToStorage(
          file: profileImage,
          reference: 'profile/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
        debugPrint('✅ New profile image uploaded to R2: $profileImageUrl');
      }

      if (coverImage != null) {
        debugPrint('🖼️ Uploading new cover image to R2...');
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'cover/${user.uid}',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
        debugPrint('✅ New cover image uploaded to R2: $coverImageUrl');
      }

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
            .map((videoData) => VideoModel.fromJson(videoData as Map<String, dynamic>))
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
            .map((videoData) => VideoModel.fromJson(videoData as Map<String, dynamic>))
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
        return VideoModel.fromJson(videoData);
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

      debugPrint('📤 Creating video with price: ${price ?? 0.0}');

      final response = await _httpClient.post('/videos', body: videoData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] : responseData;
        debugPrint('✅ Video created successfully');
        return VideoModel.fromJson(videoMap);
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
        final videoMap = responseData.containsKey('video') ? responseData['video'] : responseData;
        return VideoModel.fromJson(videoMap);
      } else {
        throw AuthRepositoryException('Failed to create image post: ${response.body}');
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

      debugPrint('📤 Sending update data: $updateData');

      final response = await _httpClient.put('/videos/$videoId', body: updateData);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] : responseData;
        debugPrint('✅ Video updated successfully');
        return VideoModel.fromJson(videoMap);
      } else {
        debugPrint('❌ Failed to update video: ${response.statusCode} - ${response.body}');
        throw AuthRepositoryException('Failed to update video: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error updating video: $e');
      throw AuthRepositoryException('Failed to update video: $e');
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
  // 🆕 SERIES OPERATIONS
  // ===============================

  @override
  Future<SeriesModel> createSeries({
    required String creatorId,
    required String creatorName,
    required String creatorImage,
    required String title,
    required String description,
    required String bannerImage,
    required List<String> episodeVideoUrls,
    required List<String> episodeThumbnails,
    required List<int> episodeDurations,
    required double unlockPrice,
    required int freeEpisodesCount,
    bool allowReposts = true,
    bool hasAffiliateProgram = false,
    double affiliateCommission = 0.0,
    List<String>? tags,
  }) async {
    try {
      final timestamp = _createTimestamp();
      
      final seriesData = {
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorImage': creatorImage,
        'title': title,
        'description': description,
        'bannerImage': bannerImage,
        'episodeVideoUrls': episodeVideoUrls,
        'episodeThumbnails': episodeThumbnails,
        'episodeDurations': episodeDurations,
        'isPremium': true,
        'unlockPrice': unlockPrice,
        'freeEpisodesCount': freeEpisodesCount,
        'allowReposts': allowReposts,
        'hasAffiliateProgram': hasAffiliateProgram,
        'affiliateCommission': affiliateCommission,
        'tags': tags ?? [],
        'viewCount': 0,
        'unlockCount': 0,
        'favoriteCount': 0,
        'likes': 0,
        'isActive': true,
        'isFeatured': false,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      debugPrint('📤 Creating series: $title');

      final response = await _httpClient.post('/series', body: seriesData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final seriesMap = responseData.containsKey('series') ? responseData['series'] : responseData;
        debugPrint('✅ Series created successfully');
        return SeriesModel.fromJson(seriesMap);
      } else {
        throw AuthRepositoryException('Failed to create series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to create series: $e');
    }
  }

  @override
  Future<List<SeriesModel>> getAllSeries() async {
    try {
      final response = await _httpClient.get('/series');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> seriesData = responseData['series'] ?? [];
        return seriesData
            .map((data) => SeriesModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get all series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get all series: $e');
    }
  }

  @override
  Future<List<SeriesModel>> getUserSeries(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/series');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> seriesData = responseData['series'] ?? [];
        return seriesData
            .map((data) => SeriesModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get user series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get user series: $e');
    }
  }

  @override
  Future<SeriesModel?> getSeriesById(String seriesId) async {
    try {
      final response = await _httpClient.get('/series/$seriesId');
      
      if (response.statusCode == 200) {
        final seriesData = jsonDecode(response.body) as Map<String, dynamic>;
        return SeriesModel.fromJson(seriesData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get series by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get series by ID: $e');
    }
  }

  @override
  Future<SeriesModel> updateSeries({
    required String seriesId,
    String? title,
    String? description,
    String? bannerImage,
    List<String>? episodeVideoUrls,
    List<String>? episodeThumbnails,
    List<int>? episodeDurations,
    double? unlockPrice,
    int? freeEpisodesCount,
    bool? allowReposts,
    bool? hasAffiliateProgram,
    double? affiliateCommission,
    List<String>? tags,
  }) async {
    try {
      debugPrint('🔄 Updating series: $seriesId');
      
      final Map<String, dynamic> updateData = {
        'updatedAt': _createTimestamp(),
      };
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (bannerImage != null) updateData['bannerImage'] = bannerImage;
      if (episodeVideoUrls != null) updateData['episodeVideoUrls'] = episodeVideoUrls;
      if (episodeThumbnails != null) updateData['episodeThumbnails'] = episodeThumbnails;
      if (episodeDurations != null) updateData['episodeDurations'] = episodeDurations;
      if (unlockPrice != null) updateData['unlockPrice'] = unlockPrice;
      if (freeEpisodesCount != null) updateData['freeEpisodesCount'] = freeEpisodesCount;
      if (allowReposts != null) updateData['allowReposts'] = allowReposts;
      if (hasAffiliateProgram != null) updateData['hasAffiliateProgram'] = hasAffiliateProgram;
      if (affiliateCommission != null) updateData['affiliateCommission'] = affiliateCommission;
      if (tags != null) updateData['tags'] = tags;

      final response = await _httpClient.put('/series/$seriesId', body: updateData);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final seriesMap = responseData.containsKey('series') ? responseData['series'] : responseData;
        debugPrint('✅ Series updated successfully');
        return SeriesModel.fromJson(seriesMap);
      } else {
        throw AuthRepositoryException('Failed to update series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update series: $e');
    }
  }

  @override
  Future<void> deleteSeries(String seriesId, String userId) async {
    try {
      final response = await _httpClient.delete('/series/$seriesId');
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to delete series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete series: $e');
    }
  }

  @override
  Future<void> likeSeries(String seriesId, String userId) async {
    try {
      final response = await _httpClient.post('/series/$seriesId/like', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to like series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to like series: $e');
    }
  }

  @override
  Future<void> unlikeSeries(String seriesId, String userId) async {
    try {
      final response = await _httpClient.delete('/series/$seriesId/like');

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to unlike series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unlike series: $e');
    }
  }

  @override
  Future<void> favoriteSeries(String seriesId, String userId) async {
    try {
      final response = await _httpClient.post('/series/$seriesId/favorite', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to favorite series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to favorite series: $e');
    }
  }

  @override
  Future<void> unfavoriteSeries(String seriesId, String userId) async {
    try {
      final response = await _httpClient.delete('/series/$seriesId/favorite');

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to unfavorite series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unfavorite series: $e');
    }
  }

  @override
  Future<void> incrementSeriesViewCount(String seriesId) async {
    try {
      final response = await _httpClient.post('/series/$seriesId/views', body: {});
      
      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to increment series view count: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to increment series view count: $e');
    }
  }

  @override
  Future<SeriesUnlockModel> unlockSeries({
    required String userId,
    required String seriesId,
    required String originalCreatorId,
    String? sharedByUserId,
    bool hasAffiliateEarnings = false,
    double affiliateCommission = 0.0,
    double affiliateEarnings = 0.0,
    required double unlockPrice,
    String paymentMethod = 'M-Pesa',
    String? transactionId,
    required String seriesTitle,
    required String creatorName,
    required int totalEpisodes,
  }) async {
    try {
      final timestamp = _createTimestamp();
      
      final unlockData = {
        'userId': userId,
        'seriesId': seriesId,
        'originalCreatorId': originalCreatorId,
        'sharedByUserId': sharedByUserId,
        'hasAffiliateEarnings': hasAffiliateEarnings,
        'affiliateCommission': affiliateCommission,
        'affiliateEarnings': affiliateEarnings,
        'unlockPrice': unlockPrice,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'purchasedAt': timestamp,
        'seriesTitle': seriesTitle,
        'creatorName': creatorName,
        'totalEpisodes': totalEpisodes,
        'currentEpisode': 1,
        'completedEpisodes': [],
        'totalEpisodesWatched': 0,
        'watchProgress': 0.0,
        'lastWatchedAt': timestamp,
        'isActive': true,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      debugPrint('📤 Unlocking series: $seriesTitle for user: $userId');

      final response = await _httpClient.post('/series/$seriesId/unlock', body: unlockData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final unlockMap = responseData.containsKey('unlock') ? responseData['unlock'] : responseData;
        debugPrint('✅ Series unlocked successfully');
        return SeriesUnlockModel.fromJson(unlockMap);
      } else {
        throw AuthRepositoryException('Failed to unlock series: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unlock series: $e');
    }
  }

  @override
  Future<bool> hasUnlockedSeries(String userId, String seriesId) async {
    try {
      final response = await _httpClient.get('/users/$userId/series/$seriesId/unlock');
      return response.statusCode == 200;
    } catch (e) {
      if (e is NotFoundException) return false;
      throw AuthRepositoryException('Failed to check series unlock status: $e');
    }
  }

  @override
  Future<SeriesUnlockModel?> getSeriesUnlock(String userId, String seriesId) async {
    try {
      final response = await _httpClient.get('/users/$userId/series/$seriesId/unlock');
      
      if (response.statusCode == 200) {
        final unlockData = jsonDecode(response.body) as Map<String, dynamic>;
        return SeriesUnlockModel.fromJson(unlockData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get series unlock: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get series unlock: $e');
    }
  }

  @override
  Future<List<SeriesUnlockModel>> getUserUnlocks(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/unlocks');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> unlocksData = responseData['unlocks'] ?? [];
        return unlocksData
            .map((data) => SeriesUnlockModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get user unlocks: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get user unlocks: $e');
    }
  }

  @override
  Future<SeriesUnlockModel> updateEpisodeProgress({
    required String unlockId,
    required int episodeNumber,
  }) async {
    try {
      final updateData = {
        'currentEpisode': episodeNumber,
        'lastWatchedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      };

      final response = await _httpClient.put('/unlocks/$unlockId/progress', body: updateData);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final unlockMap = responseData.containsKey('unlock') ? responseData['unlock'] : responseData;
        return SeriesUnlockModel.fromJson(unlockMap);
      } else {
        throw AuthRepositoryException('Failed to update episode progress: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update episode progress: $e');
    }
  }

  @override
  Future<SeriesUnlockModel> completeEpisode({
    required String unlockId,
    required int episodeNumber,
  }) async {
    try {
      final updateData = {
        'episodeNumber': episodeNumber,
        'lastWatchedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      };

      final response = await _httpClient.post('/unlocks/$unlockId/complete-episode', body: updateData);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final unlockMap = responseData.containsKey('unlock') ? responseData['unlock'] : responseData;
        return SeriesUnlockModel.fromJson(unlockMap);
      } else {
        throw AuthRepositoryException('Failed to complete episode: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to complete episode: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSeriesStats(String seriesId) async {
    try {
      final response = await _httpClient.get('/series/$seriesId/stats');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw AuthRepositoryException('Failed to get series stats: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get series stats: $e');
    }
  }

  // ===============================
  // 🆕 ENHANCED COMMENT OPERATIONS (WITH MEDIA)
  // ===============================

  @override
  Future<CommentModel> addComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls,
    String? parentCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) async {
    try {
      final timestamp = _createTimestamp();
      
      final commentData = {
        'videoId': videoId,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'content': content.trim(),
        'imageUrls': imageUrls ?? [], // 🆕 Media support
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'likesCount': 0,
        'replies': 0,
        'isReply': parentCommentId != null,
        'isPinned': false,
        'isEdited': false,
        'isActive': true,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
        if (replyToUserId != null) 'replyToUserId': replyToUserId,
        if (replyToUserName != null) 'replyToUserName': replyToUserName,
      };

      final response = await _httpClient.post('/videos/$videoId/comments', body: commentData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CommentModel.fromJson(responseData);
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
        return commentsData
            .map((data) => CommentModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw AuthRepositoryException('Failed to get video comments: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to get video comments: $e');
    }
  }

  @override
  Future<CommentModel?> getCommentById(String commentId) async {
    try {
      final response = await _httpClient.get('/comments/$commentId');
      
      if (response.statusCode == 200) {
        final commentData = jsonDecode(response.body) as Map<String, dynamic>;
        return CommentModel.fromJson(commentData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw AuthRepositoryException('Failed to get comment by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw AuthRepositoryException('Failed to get comment by ID: $e');
    }
  }

  @override
  Future<CommentModel> updateComment({
    required String commentId,
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final updateData = {
        'content': content.trim(),
        'imageUrls': imageUrls ?? [],
        'isEdited': true,
        'editedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      };

      final response = await _httpClient.put('/comments/$commentId', body: updateData);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return CommentModel.fromJson(responseData);
      } else {
        throw AuthRepositoryException('Failed to update comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to update comment: $e');
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

  @override
  Future<void> pinComment(String commentId, String videoId, String userId) async {
    try {
      final response = await _httpClient.post('/videos/$videoId/comments/$commentId/pin', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to pin comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to pin comment: $e');
    }
  }

  @override
  Future<void> unpinComment(String commentId, String videoId, String userId) async {
    try {
      final response = await _httpClient.post('/videos/$videoId/comments/$commentId/unpin', body: {});

      if (response.statusCode != 200) {
        throw AuthRepositoryException('Failed to unpin comment: ${response.body}');
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to unpin comment: $e');
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

  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner') || reference.contains('cover')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    if (reference.contains('comment')) return 'comment'; // 🆕 Comment media
    if (reference.contains('series')) return 'series'; // 🆕 Series media
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