// lib/features/authentication/repositories/authentication_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/models/comment_model.dart';
import 'package:textgb/constants.dart';

// Abstract repository interface
abstract class AuthenticationRepository {
  // Auth operations
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

  // User profile operations
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

  // File operations - UPDATED with progress callback
  Future<String> storeFileToStorage({
    required File file, 
    required String reference,
    Function(double)? onProgress, // NEW: Progress callback
  });

  // Streams
  Stream<DocumentSnapshot> userStream({required String userId});
  Stream<QuerySnapshot> getAllUsersStream({required String excludeUserId});
  Stream<QuerySnapshot> getVideosStream();
  Stream<List<CommentModel>> getCommentsStream(String videoId);

  // Current user info
  String? get currentUserId;
  String? get currentUserPhoneNumber;
}

// Firebase implementation
class FirebaseAuthenticationRepository implements AuthenticationRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseAuthenticationRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserPhoneNumber => _auth.currentUser?.phoneNumber;

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

  @override
  Future<bool> checkUserExists(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      throw AuthRepositoryException('Failed to check user existence: $e');
    }
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();
      
      if (!doc.exists) return null;
      
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
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
          reference: 'userImages/${user.id}/profile',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
      }

      // Upload cover image if provided
      if (coverImage != null) {
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'userImages/${user.id}/cover',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
      }

      // Set creation timestamp
      final finalUser = updatedUser.copyWith(
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.users)
          .doc(user.id)
          .set(finalUser.toMap());
      
      return finalUser;
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to create user profile: ${e.message}');
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
          reference: 'userImages/${user.id}/profile',
        );
        updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
      }

      // Upload new cover image if provided
      if (coverImage != null) {
        String coverImageUrl = await storeFileToStorage(
          file: coverImage,
          reference: 'userImages/${user.id}/cover',
        );
        updatedUser = updatedUser.copyWith(coverImage: coverImageUrl);
      }

      await _firestore
          .collection(Constants.users)
          .doc(user.id)
          .update(updatedUser.toMap());

      return updatedUser;
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to update user profile: ${e.message}');
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore
          .collection(Constants.users)
          .doc(userId)
          .update({'isActive': false});
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to delete user profile: ${e.message}');
    }
  }

  @override
  Future<void> followUser({required String followerId, required String userId}) async {
    try {
      final batch = _firestore.batch();
      
      // Update follower's following list
      final followerRef = _firestore.collection(Constants.users).doc(followerId);
      batch.update(followerRef, {
        'followingUIDs': FieldValue.arrayUnion([userId]),
        'following': FieldValue.increment(1),
      });
      
      // Update target user's followers list
      final userRef = _firestore.collection(Constants.users).doc(userId);
      batch.update(userRef, {
        'followerUIDs': FieldValue.arrayUnion([followerId]),
        'followers': FieldValue.increment(1),
      });
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to follow user: ${e.message}');
    }
  }

  @override
  Future<void> unfollowUser({required String followerId, required String userId}) async {
    try {
      final batch = _firestore.batch();
      
      // Update follower's following list
      final followerRef = _firestore.collection(Constants.users).doc(followerId);
      batch.update(followerRef, {
        'followingUIDs': FieldValue.arrayRemove([userId]),
        'following': FieldValue.increment(-1),
      });
      
      // Update target user's followers list
      final userRef = _firestore.collection(Constants.users).doc(userId);
      batch.update(userRef, {
        'followerUIDs': FieldValue.arrayRemove([followerId]),
        'followers': FieldValue.increment(-1),
      });
      
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to unfollow user: ${e.message}');
    }
  }

  @override
  Future<List<UserModel>> searchUsers({required String query}) async {
    try {
      List<UserModel> users = [];
      
      // Search by user name (case-insensitive)
      QuerySnapshot nameQuery = await _firestore
          .collection(Constants.users)
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThan: '${query.toLowerCase()}z')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();
      
      for (QueryDocumentSnapshot doc in nameQuery.docs) {
        users.add(UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        ));
      }
      
      return users;
    } catch (e) {
      throw AuthRepositoryException('Failed to search users: $e');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers({required String excludeUserId}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.users)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != excludeUserId)
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw AuthRepositoryException('Failed to get all users: $e');
    }
  }

  @override
  Future<List<VideoModel>> getVideos() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.videos)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      throw AuthRepositoryException('Failed to get videos: $e');
    }
  }

  @override
  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.videos)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VideoModel.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();
    } catch (e) {
      throw AuthRepositoryException('Failed to get user videos: $e');
    }
  }

  @override
  Future<VideoModel?> getVideoById(String videoId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(Constants.videos)
          .doc(videoId)
          .get();

      if (!doc.exists) return null;
      return VideoModel.fromMap(doc.data() as Map<String, dynamic>, id: videoId);
    } catch (e) {
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
      final videoRef = _firestore.collection(Constants.videos).doc();
      final videoId = videoRef.id;
      final now = Timestamp.now();
      
      final video = VideoModel(
        id: videoId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        likes: 0,
        comments: 0,
        views: 0,
        shares: 0,
        isLiked: false,
        tags: tags ?? [],
        createdAt: now,
        isActive: true,
        isFeatured: false,
        isMultipleImages: false,
        imageUrls: [],
      );

      await videoRef.set(video.toMap());

      // Update user's video count AND lastPostAt
      await _firestore.collection(Constants.users).doc(userId).update({
        'videosCount': FieldValue.increment(1),
        'lastPostAt': now,
      });

      return video;
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
      final postRef = _firestore.collection(Constants.videos).doc();
      final postId = postRef.id;
      final now = Timestamp.now();
      
      final post = VideoModel(
        id: postId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        videoUrl: '',
        thumbnailUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
        caption: caption,
        likes: 0,
        comments: 0,
        views: 0,
        shares: 0,
        isLiked: false,
        tags: tags ?? [],
        createdAt: now,
        isActive: true,
        isFeatured: false,
        isMultipleImages: true,
        imageUrls: imageUrls,
      );

      await postRef.set(post.toMap());

      // Update user's video count AND lastPostAt
      await _firestore.collection(Constants.users).doc(userId).update({
        'videosCount': FieldValue.increment(1),
        'lastPostAt': now,
      });

      return post;
    } catch (e) {
      throw AuthRepositoryException('Failed to create image post: $e');
    }
  }

  @override
  Future<void> deleteVideo(String videoId, String userId) async {
    try {
      // Get video to verify ownership
      final video = await getVideoById(videoId);
      if (video == null) {
        throw AuthRepositoryException('Video not found');
      }

      // Verify ownership
      if (video.userId != userId) {
        throw AuthRepositoryException('Unauthorized: Cannot delete video');
      }

      await _firestore
          .collection(Constants.videos)
          .doc(videoId)
          .update({'isActive': false});

      // Update user's video count
      await _firestore.collection(Constants.users).doc(userId).update({
        'videosCount': FieldValue.increment(-1),
      });

      // Update lastPostAt to the most recent remaining video
      await _updateUserLastPostAt(userId);
      
    } catch (e) {
      throw AuthRepositoryException('Failed to delete video: $e');
    }
  }

  // Helper method to update lastPostAt after video deletion
  Future<void> _updateUserLastPostAt(String userId) async {
    try {
      // Get the most recent active video for this user
      final querySnapshot = await _firestore
          .collection(Constants.videos)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update to the most recent video's timestamp
        final latestVideoTimestamp = querySnapshot.docs.first.data()['createdAt'];
        await _firestore.collection(Constants.users).doc(userId).update({
          'lastPostAt': latestVideoTimestamp,
        });
      } else {
        // No videos left, set lastPostAt to null
        await _firestore.collection(Constants.users).doc(userId).update({
          'lastPostAt': null,
        });
      }
    } catch (e) {
      // Don't throw error for this operation as it's not critical
      debugPrint('Failed to update lastPostAt after deletion: $e');
    }
  }

  @override
  Future<void> likeVideo(String videoId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's liked videos
      batch.update(
        _firestore.collection(Constants.users).doc(userId),
        {
          'likedVideos': FieldValue.arrayUnion([videoId]),
        },
      );

      // Update video's like count
      batch.update(
        _firestore.collection(Constants.videos).doc(videoId),
        {
          'likes': FieldValue.increment(1),
        },
      );

      // Update video owner's total likes
      final video = await getVideoById(videoId);
      if (video != null) {
        batch.update(
          _firestore.collection(Constants.users).doc(video.userId),
          {
            'likesCount': FieldValue.increment(1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw AuthRepositoryException('Failed to like video: $e');
    }
  }

  @override
  Future<void> unlikeVideo(String videoId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's liked videos
      batch.update(
        _firestore.collection(Constants.users).doc(userId),
        {
          'likedVideos': FieldValue.arrayRemove([videoId]),
        },
      );

      // Update video's like count
      batch.update(
        _firestore.collection(Constants.videos).doc(videoId),
        {
          'likes': FieldValue.increment(-1),
        },
      );

      // Update video owner's total likes
      final video = await getVideoById(videoId);
      if (video != null) {
        batch.update(
          _firestore.collection(Constants.users).doc(video.userId),
          {
            'likesCount': FieldValue.increment(-1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw AuthRepositoryException('Failed to unlike video: $e');
    }
  }

  @override
  Future<List<String>> getLikedVideos(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['likedVideos'] ?? []);
    } catch (e) {
      throw AuthRepositoryException('Failed to fetch liked videos: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore
          .collection(Constants.videos)
          .doc(videoId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      throw AuthRepositoryException('Failed to increment view count: $e');
    }
  }

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
      final commentRef = _firestore.collection(Constants.comments).doc();
      final commentId = commentRef.id;
      
      final comment = CommentModel(
        id: commentId,
        videoId: videoId,
        authorId: authorId,
        authorName: authorName,
        authorImage: authorImage,
        content: content.trim(),
        createdAt: DateTime.now(),
        likedBy: [],
        likesCount: 0,
        isReply: repliedToCommentId != null,
        repliedToCommentId: repliedToCommentId,
        repliedToAuthorName: repliedToAuthorName,
      );

      await commentRef.set(comment.toMap());

      // Update video comment count
      await _firestore.collection(Constants.videos).doc(videoId).update({
        'comments': FieldValue.increment(1),
      });

      // If it's a reply, increment the parent comment's reply count
      if (repliedToCommentId != null) {
        await _firestore.collection(Constants.comments).doc(repliedToCommentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }

      return comment;
    } catch (e) {
      throw AuthRepositoryException('Failed to add comment: $e');
    }
  }

  @override
  Future<List<CommentModel>> getVideoComments(String videoId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.comments)
          .where('videoId', isEqualTo: videoId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw AuthRepositoryException('Failed to get video comments: $e');
    }
  }

  @override
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      // Get the comment to check ownership and get video ID
      final commentDoc = await _firestore.collection(Constants.comments).doc(commentId).get();
      if (!commentDoc.exists) {
        throw AuthRepositoryException('Comment not found');
      }

      final commentData = commentDoc.data()!;
      
      // Check if user owns the comment
      if (commentData['authorId'] != userId) {
        throw AuthRepositoryException('Not authorized to delete this comment');
      }

      final videoId = commentData['videoId'];
      final isReply = commentData['isReply'] ?? false;
      final repliedToCommentId = commentData['repliedToCommentId'];

      // Delete the comment
      await _firestore.collection(Constants.comments).doc(commentId).delete();

      // Update video comment count
      await _firestore.collection(Constants.videos).doc(videoId).update({
        'comments': FieldValue.increment(-1),
      });

      // If it was a reply, decrement the parent comment's reply count
      if (isReply && repliedToCommentId != null) {
        await _firestore.collection(Constants.comments).doc(repliedToCommentId).update({
          'replyCount': FieldValue.increment(-1),
        });
      }

      // Also delete any replies to this comment
      final repliesQuery = await _firestore
          .collection(Constants.comments)
          .where('repliedToCommentId', isEqualTo: commentId)
          .get();

      if (repliesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final replyDoc in repliesQuery.docs) {
          batch.delete(replyDoc.reference);
        }
        
        await batch.commit();

        // Update video comment count for deleted replies
        await _firestore.collection(Constants.videos).doc(videoId).update({
          'comments': FieldValue.increment(-repliesQuery.docs.length),
        });
      }
    } catch (e) {
      throw AuthRepositoryException('Failed to delete comment: $e');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    try {
      await _firestore.collection(Constants.comments).doc(commentId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw AuthRepositoryException('Failed to like comment: $e');
    }
  }

  @override
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _firestore.collection(Constants.comments).doc(commentId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw AuthRepositoryException('Failed to unlike comment: $e');
    }
  }

  // UPDATED: storeFileToStorage with progress tracking
  @override
  Future<String> storeFileToStorage({
    required File file, 
    required String reference,
    Function(double)? onProgress, // NEW: Progress callback
  }) async {
    try {
      UploadTask uploadTask = _storage.ref().child(reference).putFile(file);
      
      // Listen to upload progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }
      
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } on FirebaseException catch (e) {
      throw AuthRepositoryException('Failed to upload file: ${e.message}');
    }
  }

  @override
  Stream<DocumentSnapshot> userStream({required String userId}) {
    return _firestore.collection(Constants.users).doc(userId).snapshots();
  }

  @override
  Stream<QuerySnapshot> getAllUsersStream({required String excludeUserId}) {
    return _firestore
        .collection(Constants.users)
        .where('id', isNotEqualTo: excludeUserId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getVideosStream() {
    return _firestore
        .collection(Constants.videos)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Stream<List<CommentModel>> getCommentsStream(String videoId) {
    return _firestore
        .collection(Constants.comments)
        .where('videoId', isEqualTo: videoId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}

// Exception class for repository errors
class AuthRepositoryException implements Exception {
  final String message;
  const AuthRepositoryException(this.message);
  
  @override
  String toString() => 'AuthRepositoryException: $message';
}