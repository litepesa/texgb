// lib/features/channels/repositories/channel_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/channel_video_model.dart';

// Abstract repository interface
abstract class ChannelRepository {
  // Channel operations
  Future<List<ChannelModel>> getChannels({bool forceRefresh = false});
  Future<ChannelModel?> getChannelById(String channelId);
  Future<ChannelModel?> getUserChannel(String userId);
  Future<ChannelModel> createChannel({
    required String userId,
    required String name,
    required String description,
    required String profileImageUrl,
    required String coverImageUrl,
    List<String>? tags,
  }); // Manual channel creation
  Future<ChannelModel> updateChannel({
    required ChannelModel channel,
    required String profileImageUrl,
    required String coverImageUrl,
  });
  Future<void> deleteChannel(String channelId, String userId);
  Future<void> followChannel(String channelId, String userId);
  Future<void> unfollowChannel(String channelId, String userId);
  Future<List<String>> getFollowedChannels(String userId);

  // Video operations - UPDATED: Added price parameter
  Future<List<ChannelVideoModel>> getChannelVideos({bool forceRefresh = false});
  Future<List<ChannelVideoModel>> getVideosByChannelId(String channelId);
  Future<ChannelVideoModel?> getVideoById(String videoId);
  Future<ChannelVideoModel> createVideo({
    required String channelId,
    required String channelName,
    required String channelImage,
    required String userId,
    required String videoUrl,
    required String thumbnailUrl,
    required String caption,
    required double price, // NEW: Price parameter
    List<String>? tags,
  });
  Future<ChannelVideoModel> createImagePost({
    required String channelId,
    required String channelName,
    required String channelImage,
    required String userId,
    required List<String> imageUrls,
    required String caption,
    required double price, // NEW: Price parameter
    List<String>? tags,
  });
  Future<void> deleteVideo(String videoId, String userId);
  Future<void> likeVideo(String videoId, String userId);
  Future<void> unlikeVideo(String videoId, String userId);
  Future<List<String>> getLikedVideos(String userId);
  Future<void> incrementViewCount(String videoId);

  // File upload operations
  Future<String> uploadImage(File imageFile, String path);
  Future<String> uploadVideo(File videoFile, String path, {Function(double)? onProgress});
}

// Firebase implementation
class FirebaseChannelRepository implements ChannelRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _channelsCollection;
  final String _videosCollection;
  final String _usersCollection;

  FirebaseChannelRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    String channelsCollection = 'channels',
    String videosCollection = 'channelVideos',
    String usersCollection = 'users',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _channelsCollection = channelsCollection,
       _videosCollection = videosCollection,
       _usersCollection = usersCollection;

  @override
  Future<List<ChannelModel>> getChannels({bool forceRefresh = false}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_channelsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch channels: $e');
    }
  }

  @override
  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_channelsCollection)
          .doc(channelId)
          .get();

      if (!docSnapshot.exists) return null;
      return ChannelModel.fromMap(docSnapshot.data()!, channelId);
    } catch (e) {
      throw RepositoryException('Failed to fetch channel: $e');
    }
  }

  @override
  Future<ChannelModel?> getUserChannel(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_channelsCollection)
          .where('ownerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      
      final doc = querySnapshot.docs.first;
      return ChannelModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      throw RepositoryException('Failed to fetch user channel: $e');
    }
  }

  @override
  Future<ChannelModel> createChannel({
    required String userId,
    required String name,
    required String description,
    required String profileImageUrl,
    required String coverImageUrl,
    List<String>? tags,
  }) async {
    try {
      debugPrint('DEBUG: Creating channel manually for $userId');

      // Get user data for additional info
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) {
        throw RepositoryException('User data not found');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'User';
      final userImage = userData['image'] ?? '';

      // CRITICAL: Use atomic transaction to prevent duplicate channels
      final channelRef = _firestore.collection(_channelsCollection).doc();
      final channelId = channelRef.id;

      return await _firestore.runTransaction<ChannelModel>((transaction) async {
        // Check if user already has a channel
        final userDocRef = _firestore.collection(_usersCollection).doc(userId);
        final userDocSnapshot = await transaction.get(userDocRef);
        
        if (userDocSnapshot.exists) {
          final userData = userDocSnapshot.data()!;
          final ownedChannels = List<String>.from(userData['ownedChannels'] ?? []);
          
          // Check if user already has channels
          if (ownedChannels.isNotEmpty) {
            // User already has channels, check if any are active
            for (String existingChannelId in ownedChannels) {
              final existingChannelRef = _firestore.collection(_channelsCollection).doc(existingChannelId);
              final existingChannelSnapshot = await transaction.get(existingChannelRef);
              
              if (existingChannelSnapshot.exists) {
                final existingChannelData = existingChannelSnapshot.data()!;
                if (existingChannelData['isActive'] == true) {
                  throw RepositoryException('You already have an active channel');
                }
              }
            }
          }
        }

        // Create new channel
        final channel = ChannelModel(
          id: channelId,
          ownerId: userId,
          ownerName: userName,
          ownerImage: userImage,
          name: name,
          description: description,
          profileImage: profileImageUrl,
          coverImage: coverImageUrl,
          followers: 0,
          videosCount: 0,
          likesCount: 0,
          isVerified: false,
          tags: tags ?? [],
          followerUIDs: [],
          createdAt: Timestamp.now(),
          lastPostAt: null,
          isActive: true,
          isFeatured: false,
        );

        // Set channel data in transaction
        transaction.set(channelRef, channel.toMap());

        // Update user's owned channels in transaction
        transaction.update(userDocRef, {
          'ownedChannels': FieldValue.arrayUnion([channelId]),
        });

        debugPrint('DEBUG: Created channel $channelId for user $userId');
        return channel;
      });
    } catch (e) {
      debugPrint('ERROR: Failed to create channel: $e');
      throw RepositoryException('Failed to create channel: $e');
    }
  }

  @override
  Future<ChannelModel> updateChannel({
    required ChannelModel channel,
    required String profileImageUrl,
    required String coverImageUrl,
  }) async {
    try {
      final updates = channel.toMap();
      updates['profileImage'] = profileImageUrl;
      updates['coverImage'] = coverImageUrl;

      await _firestore
          .collection(_channelsCollection)
          .doc(channel.id)
          .update(updates);

      return channel.copyWith(
        profileImage: profileImageUrl,
        coverImage: coverImageUrl,
      );
    } catch (e) {
      throw RepositoryException('Failed to update channel: $e');
    }
  }

  @override
  Future<void> deleteChannel(String channelId, String userId) async {
    try {
      // Verify ownership
      final channel = await getChannelById(channelId);
      if (channel?.ownerId != userId) {
        throw RepositoryException('Unauthorized: Cannot delete channel');
      }

      await _firestore
          .collection(_channelsCollection)
          .doc(channelId)
          .update({'isActive': false});

      // Remove from user's owned channels
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ownedChannels': FieldValue.arrayRemove([channelId]),
      });
    } catch (e) {
      throw RepositoryException('Failed to delete channel: $e');
    }
  }

  @override
  Future<void> followChannel(String channelId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's followed channels
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'followedChannels': FieldValue.arrayUnion([channelId]),
          'followingCount': FieldValue.increment(1),
        },
      );

      // Update channel's followers
      batch.update(
        _firestore.collection(_channelsCollection).doc(channelId),
        {
          'followers': FieldValue.increment(1),
          'followerUIDs': FieldValue.arrayUnion([userId]),
        },
      );

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to follow channel: $e');
    }
  }

  @override
  Future<void> unfollowChannel(String channelId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's followed channels
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'followedChannels': FieldValue.arrayRemove([channelId]),
          'followingCount': FieldValue.increment(-1),
        },
      );

      // Update channel's followers
      batch.update(
        _firestore.collection(_channelsCollection).doc(channelId),
        {
          'followers': FieldValue.increment(-1),
          'followerUIDs': FieldValue.arrayRemove([userId]),
        },
      );

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to unfollow channel: $e');
    }
  }

  @override
  Future<List<String>> getFollowedChannels(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['followedChannels'] ?? []);
    } catch (e) {
      throw RepositoryException('Failed to fetch followed channels: $e');
    }
  }

  @override
  Future<List<ChannelVideoModel>> getChannelVideos({bool forceRefresh = false}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_videosCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChannelVideoModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch videos: $e');
    }
  }

  @override
  Future<List<ChannelVideoModel>> getVideosByChannelId(String channelId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_videosCollection)
          .where('channelId', isEqualTo: channelId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChannelVideoModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch channel videos: $e');
    }
  }

  @override
  Future<ChannelVideoModel?> getVideoById(String videoId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_videosCollection)
          .doc(videoId)
          .get();

      if (!docSnapshot.exists) return null;
      return ChannelVideoModel.fromMap(docSnapshot.data()!, id: videoId);
    } catch (e) {
      throw RepositoryException('Failed to fetch video: $e');
    }
  }

  @override
  Future<ChannelVideoModel> createVideo({
    required String channelId,
    required String channelName,
    required String channelImage,
    required String userId,
    required String videoUrl,
    required String thumbnailUrl,
    required String caption,
    required double price, // NEW: Price parameter
    List<String>? tags,
  }) async {
    try {
      final videoId = _generateId();
      final now = Timestamp.now();
      
      final video = ChannelVideoModel(
        id: videoId,
        channelId: channelId,
        channelName: channelName,
        channelImage: channelImage,
        userId: userId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        price: price, // Include price
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

      await _firestore
          .collection(_videosCollection)
          .doc(videoId)
          .set(video.toMap());

      // Update channel's video count AND lastPostAt
      await _firestore.collection(_channelsCollection).doc(channelId).update({
        'videosCount': FieldValue.increment(1),
        'lastPostAt': now,
      });

      return video;
    } catch (e) {
      throw RepositoryException('Failed to create video: $e');
    }
  }

  @override
  Future<ChannelVideoModel> createImagePost({
    required String channelId,
    required String channelName,
    required String channelImage,
    required String userId,
    required List<String> imageUrls,
    required String caption,
    required double price, // NEW: Price parameter
    List<String>? tags,
  }) async {
    try {
      final postId = _generateId();
      final now = Timestamp.now();
      
      final post = ChannelVideoModel(
        id: postId,
        channelId: channelId,
        channelName: channelName,
        channelImage: channelImage,
        userId: userId,
        videoUrl: '',
        thumbnailUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
        caption: caption,
        price: price, // Include price
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

      await _firestore
          .collection(_videosCollection)
          .doc(postId)
          .set(post.toMap());

      // Update channel's video count AND lastPostAt
      await _firestore.collection(_channelsCollection).doc(channelId).update({
        'videosCount': FieldValue.increment(1),
        'lastPostAt': now,
      });

      return post;
    } catch (e) {
      throw RepositoryException('Failed to create image post: $e');
    }
  }

  @override
  Future<void> deleteVideo(String videoId, String userId) async {
    try {
      // Get video to verify ownership
      final video = await getVideoById(videoId);
      if (video == null) {
        throw RepositoryException('Video not found');
      }

      // Verify channel ownership
      final channel = await getChannelById(video.channelId);
      if (channel?.ownerId != userId) {
        throw RepositoryException('Unauthorized: Cannot delete video');
      }

      await _firestore
          .collection(_videosCollection)
          .doc(videoId)
          .update({'isActive': false});

      // Update channel's video count
      await _firestore.collection(_channelsCollection).doc(video.channelId).update({
        'videosCount': FieldValue.increment(-1),
      });

      // Update lastPostAt to the most recent remaining video
      await _updateChannelLastPostAt(video.channelId);
      
    } catch (e) {
      throw RepositoryException('Failed to delete video: $e');
    }
  }

  // Helper method to update lastPostAt after video deletion
  Future<void> _updateChannelLastPostAt(String channelId) async {
    try {
      // Get the most recent active video for this channel
      final querySnapshot = await _firestore
          .collection(_videosCollection)
          .where('channelId', isEqualTo: channelId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update to the most recent video's timestamp
        final latestVideoTimestamp = querySnapshot.docs.first.data()['createdAt'];
        await _firestore.collection(_channelsCollection).doc(channelId).update({
          'lastPostAt': latestVideoTimestamp,
        });
      } else {
        // No videos left, set lastPostAt to null
        await _firestore.collection(_channelsCollection).doc(channelId).update({
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
        _firestore.collection(_usersCollection).doc(userId),
        {
          'likedChannelVideos': FieldValue.arrayUnion([videoId]),
        },
      );

      // Update video's like count
      batch.update(
        _firestore.collection(_videosCollection).doc(videoId),
        {
          'likes': FieldValue.increment(1),
        },
      );

      // Update channel's total likes
      final video = await getVideoById(videoId);
      if (video != null) {
        batch.update(
          _firestore.collection(_channelsCollection).doc(video.channelId),
          {
            'likesCount': FieldValue.increment(1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to like video: $e');
    }
  }

  @override
  Future<void> unlikeVideo(String videoId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's liked videos
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'likedChannelVideos': FieldValue.arrayRemove([videoId]),
        },
      );

      // Update video's like count
      batch.update(
        _firestore.collection(_videosCollection).doc(videoId),
        {
          'likes': FieldValue.increment(-1),
        },
      );

      // Update channel's total likes
      final video = await getVideoById(videoId);
      if (video != null) {
        batch.update(
          _firestore.collection(_channelsCollection).doc(video.channelId),
          {
            'likesCount': FieldValue.increment(-1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to unlike video: $e');
    }
  }

  @override
  Future<List<String>> getLikedVideos(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['likedChannelVideos'] ?? []);
    } catch (e) {
      throw RepositoryException('Failed to fetch liked videos: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore
          .collection(_videosCollection)
          .doc(videoId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      throw RepositoryException('Failed to increment view count: $e');
    }
  }

  @override
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw RepositoryException('Failed to upload image: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String path, {Function(double)? onProgress}) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw RepositoryException('Failed to upload video: $e');
    }
  }

  String _generateId() {
    return _firestore.collection('temp').doc().id;
  }
}

// Exception class for repository errors
class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
  
  @override
  String toString() => 'RepositoryException: $message';
}