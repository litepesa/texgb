// lib/features/channels/repositories/channel_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    required String userName,
    required String userImage,
    required String name,
    required String description,
    required String profileImageUrl,
    required String coverImageUrl,
    List<String>? tags,
  });
  Future<ChannelModel> updateChannel({
    required ChannelModel channel,
    required String profileImageUrl,
    required String coverImageUrl,
  });
  Future<void> deleteChannel(String channelId, String userId);
  Future<void> followChannel(String channelId, String userId);
  Future<void> unfollowChannel(String channelId, String userId);
  Future<List<String>> getFollowedChannels(String userId);

  // Video operations
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
    List<String>? tags,
  });
  Future<ChannelVideoModel> createImagePost({
    required String channelId,
    required String channelName,
    required String channelImage,
    required String userId,
    required List<String> imageUrls,
    required String caption,
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
    required String userName,
    required String userImage,
    required String name,
    required String description,
    required String profileImageUrl,
    required String coverImageUrl,
    List<String>? tags,
  }) async {
    try {
      final channelId = _generateId();
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
        isActive: true,
        isFeatured: false,
      );

      await _firestore
          .collection(_channelsCollection)
          .doc(channelId)
          .set(channel.toMap());

      // Update user's owned channels
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ownedChannels': FieldValue.arrayUnion([channelId]),
      });

      return channel;
    } catch (e) {
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
    List<String>? tags,
  }) async {
    try {
      final videoId = _generateId();
      final video = ChannelVideoModel(
        id: videoId,
        channelId: channelId,
        channelName: channelName,
        channelImage: channelImage,
        userId: userId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        likes: 0,
        comments: 0,
        views: 0,
        shares: 0,
        isLiked: false,
        tags: tags ?? [],
        createdAt: Timestamp.now(),
        isActive: true,
        isFeatured: false,
        isMultipleImages: false,
        imageUrls: [],
      );

      await _firestore
          .collection(_videosCollection)
          .doc(videoId)
          .set(video.toMap());

      // Update channel's video count
      await _firestore.collection(_channelsCollection).doc(channelId).update({
        'videosCount': FieldValue.increment(1),
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
    List<String>? tags,
  }) async {
    try {
      final postId = _generateId();
      final post = ChannelVideoModel(
        id: postId,
        channelId: channelId,
        channelName: channelName,
        channelImage: channelImage,
        userId: userId,
        videoUrl: '',
        thumbnailUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
        caption: caption,
        likes: 0,
        comments: 0,
        views: 0,
        shares: 0,
        isLiked: false,
        tags: tags ?? [],
        createdAt: Timestamp.now(),
        isActive: true,
        isFeatured: false,
        isMultipleImages: true,
        imageUrls: imageUrls,
      );

      await _firestore
          .collection(_videosCollection)
          .doc(postId)
          .set(post.toMap());

      // Update channel's video count
      await _firestore.collection(_channelsCollection).doc(channelId).update({
        'videosCount': FieldValue.increment(1),
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

      // Decrement channel's video count
      await _firestore.collection(_channelsCollection).doc(video.channelId).update({
        'videosCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw RepositoryException('Failed to delete video: $e');
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