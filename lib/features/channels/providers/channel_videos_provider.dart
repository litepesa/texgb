import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:uuid/uuid.dart';

// Define the channel videos state
class ChannelVideosState {
  final bool isLoading;
  final List<ChannelVideoModel> videos;
  final List<String> likedVideos;
  final String? error;
  final bool isUploading;
  final double uploadProgress;

  const ChannelVideosState({
    this.isLoading = false,
    this.videos = const [],
    this.likedVideos = const [],
    this.error,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  ChannelVideosState copyWith({
    bool? isLoading,
    List<ChannelVideoModel>? videos,
    List<String>? likedVideos,
    String? error,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return ChannelVideosState(
      isLoading: isLoading ?? this.isLoading,
      videos: videos ?? this.videos,
      likedVideos: likedVideos ?? this.likedVideos,
      error: error,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Create the channel videos provider
class ChannelVideosNotifier extends StateNotifier<ChannelVideosState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ChannelVideosNotifier() : super(const ChannelVideosState()) {
    // Initialize with empty state and load data
    loadVideos();
    loadLikedVideos();
  }

  // Debug method to help diagnose issues
  Future<void> debugChannelVideosData() async {
    debugPrint('======= DEBUGGING CHANNEL VIDEOS DATA =======');
    
    try {
      final allDocsSnap = await _firestore.collection(Constants.channelVideos).get();
      debugPrint('Total videos in collection: ${allDocsSnap.docs.length}');
      
      // Log document details
      int activeCount = 0;
      for (var doc in allDocsSnap.docs) {
        final data = doc.data();
        debugPrint('Document ID: ${doc.id}');
        debugPrint('  isActive: ${data['isActive']} (${data['isActive'].runtimeType})');
        debugPrint('  caption: ${data['caption']}');
        if (data['isActive'] == true) activeCount++;
      }
      debugPrint('Videos with isActive=true: $activeCount');
      
      debugPrint('Current state - videos count: ${state.videos.length}');
      
      debugPrint('======= END DEBUGGING CHANNEL VIDEOS DATA =======');
    } catch (e) {
      debugPrint('Error during debugging: $e');
    }
  }

  // Load videos from Firestore
  Future<void> loadVideos({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have videos, just return
    if (!forceRefresh && state.videos.isNotEmpty) {
      return;
    }
    
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get all active videos sorted by creation date
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channelVideos)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<ChannelVideoModel> videos = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if user has liked this video
        final isLiked = state.likedVideos.contains(doc.id);
        
        videos.add(ChannelVideoModel.fromMap(data, id: doc.id, isLiked: isLiked));
      }
      
      // Update state with videos
      state = state.copyWith(
        videos: videos,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading videos: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Load videos for a specific channel
  Future<List<ChannelVideoModel>> loadChannelVideos(String channelId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(Constants.channelVideos)
          .where('channelId', isEqualTo: channelId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      List<ChannelVideoModel> channelVideos = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if user has liked this video
        final isLiked = state.likedVideos.contains(doc.id);
        
        channelVideos.add(ChannelVideoModel.fromMap(data, id: doc.id, isLiked: isLiked));
      }
      
      return channelVideos;
    } catch (e) {
      debugPrint('Error loading channel videos: $e');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Load user's liked videos
  Future<void> loadLikedVideos() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('likedChannelVideos')) {
        final likedVideos = List<String>.from(userDoc.data()!['likedChannelVideos'] ?? []);
        state = state.copyWith(likedVideos: likedVideos);
        
        // Update isLiked status for existing videos
        final updatedVideos = state.videos.map((video) {
          return video.copyWith(isLiked: likedVideos.contains(video.id));
        }).toList();
        
        state = state.copyWith(videos: updatedVideos);
      }
    } catch (e) {
      debugPrint('Error loading liked videos: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Like or unlike a video
  Future<void> likeVideo(String videoId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final videoDoc = _firestore.collection(Constants.channelVideos).doc(videoId);
      
      // Get current liked videos
      List<String> likedVideos = List.from(state.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
      } else {
        likedVideos.add(videoId);
      }
      
      // Update videos list with new like status
      final updatedVideos = state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? video.likes - 1 : video.likes + 1,
          );
        }
        return video;
      }).toList();
      
      state = state.copyWith(
        videos: updatedVideos,
        likedVideos: likedVideos,
      );
      
      // Update Firestore
      // 1. Update user's liked videos
      await _firestore.collection(Constants.users).doc(uid).update({
        'likedChannelVideos': isCurrentlyLiked
            ? FieldValue.arrayRemove([videoId])
            : FieldValue.arrayUnion([videoId]),
      });
      
      // 2. Update video's like count
      await videoDoc.update({
        'likes': isCurrentlyLiked
            ? FieldValue.increment(-1)
            : FieldValue.increment(1),
      });
      
      // 3. Update channel's total likes
      final videoData = (await videoDoc.get()).data() as Map<String, dynamic>?;
      if (videoData != null && videoData['channelId'] != null) {
        final channelId = videoData['channelId'];
        await _firestore.collection(Constants.channels).doc(channelId).update({
          'likesCount': isCurrentlyLiked
              ? FieldValue.increment(-1)
              : FieldValue.increment(1),
        });
      }
      
    } catch (e) {
      debugPrint('Error toggling like: $e');
      state = state.copyWith(error: e.toString());
      
      // Revert the optimistic update on error
      loadVideos();
      loadLikedVideos();
    }
  }

  // Upload a new video to the channel
  Future<void> uploadVideo({
    required ChannelModel channel,
    required File videoFile,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError, required Duration trimEnd, required Duration trimStart, Uint8List? thumbnail, Duration? duration,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      final videoId = const Uuid().v4();
      
      // Upload video to storage
      final storageRef = _storage.ref().child('channelVideos/$videoId.mp4');
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        state = state.copyWith(uploadProgress: progress);
      });
      
      // Wait for upload to complete
      final taskSnapshot = await uploadTask;
      final videoUrl = await taskSnapshot.ref.getDownloadURL();
      
      // Generate thumbnail (in a real app, you'd use FFmpeg or a server function)
      // For now, we'll just use an empty string as placeholder
      const thumbnailUrl = '';
      
      // Create video model
      final ChannelVideoModel videoData = ChannelVideoModel(
        id: videoId,
        channelId: channel.id,
        channelName: channel.name,
        channelImage: channel.profileImage,
        userId: uid,
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
      
      // Save to Firestore
      await _firestore
          .collection(Constants.channelVideos)
          .doc(videoId)
          .set(videoData.toMap());
      
      // Update channel's video count
      await _firestore.collection(Constants.channels).doc(channel.id).update({
        'videosCount': FieldValue.increment(1),
      });
      
      // Update local state
      List<ChannelVideoModel> updatedVideos = [
        videoData, // Add new video at the beginning
        ...state.videos,
      ];
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        videos: updatedVideos,
      );
      
      onSuccess('Video uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading video: $e');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      
      onError(e.toString());
    }
  }

  // Upload multiple images to the channel
  Future<void> uploadImages({
    required ChannelModel channel,
    required List<File> imageFiles,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (imageFiles.isEmpty) {
      onError('No images selected');
      return;
    }
    
    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      final postId = const Uuid().v4();
      final List<String> imageUrls = [];
      
      // Upload each image
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final storageRef = _storage.ref().child('channelImages/$postId/image_$i.jpg');
        final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final taskProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          final overallProgress = (i / imageFiles.length) + (taskProgress / imageFiles.length);
          state = state.copyWith(uploadProgress: overallProgress);
        });
        
        final taskSnapshot = await uploadTask;
        final imageUrl = await taskSnapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
      
      // Create video model (actually an image carousel post)
      final ChannelVideoModel postData = ChannelVideoModel(
        id: postId,
        channelId: channel.id,
        channelName: channel.name,
        channelImage: channel.profileImage,
        userId: uid,
        videoUrl: '', // No video URL for image posts
        thumbnailUrl: imageUrls.first, // Use first image as thumbnail
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
      
      // Save to Firestore
      await _firestore
          .collection(Constants.channelVideos)
          .doc(postId)
          .set(postData.toMap());
      
      // Update channel's video count
      await _firestore.collection(Constants.channels).doc(channel.id).update({
        'videosCount': FieldValue.increment(1),
      });
      
      // Update local state
      List<ChannelVideoModel> updatedVideos = [
        postData, // Add new post at the beginning
        ...state.videos,
      ];
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        videos: updatedVideos,
      );
      
      onSuccess('Images uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading images: $e');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      
      onError(e.toString());
    }
  }

  // Increment view count for a video
  Future<void> incrementViewCount(String videoId) async {
    try {
      await _firestore.collection(Constants.channelVideos).doc(videoId).update({
        'views': FieldValue.increment(1),
      });
      
      // Update local state
      final updatedVideos = state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(views: video.views + 1);
        }
        return video;
      }).toList();
      
      state = state.copyWith(videos: updatedVideos);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete a video (mark as inactive)
  Future<void> deleteVideo(String videoId, Function(String) onError) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Get the video document
      final videoDoc = await _firestore.collection(Constants.channelVideos).doc(videoId).get();
      final videoData = videoDoc.data();
      
      // Check if the current user is the owner of the channel
      if (videoData != null) {
        final channelId = videoData['channelId'];
        final channelDoc = await _firestore.collection(Constants.channels).doc(channelId).get();
        final channelData = channelDoc.data();
        
        if (channelData != null && channelData['ownerId'] == uid) {
          // Mark as inactive instead of deleting
          await _firestore.collection(Constants.channelVideos).doc(videoId).update({
            'isActive': false,
          });
          
          // Decrement channel's video count
          await _firestore.collection(Constants.channels).doc(channelId).update({
            'videosCount': FieldValue.increment(-1),
          });
          
          // Update local state
          final updatedVideos = state.videos.where((video) => video.id != videoId).toList();
          state = state.copyWith(videos: updatedVideos);
        } else {
          onError('You can only delete videos from your own channel');
        }
      } else {
        onError('Video not found');
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      state = state.copyWith(error: e.toString());
      onError(e.toString());
    }
  }

  // Get a specific video by ID
  Future<ChannelVideoModel?> getVideoById(String videoId) async {
    try {
      final docSnapshot = await _firestore
          .collection(Constants.channelVideos)
          .doc(videoId)
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final isLiked = state.likedVideos.contains(videoId);
      
      return ChannelVideoModel.fromMap(data, id: videoId, isLiked: isLiked);
    } catch (e) {
      debugPrint('Error getting video by ID: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// Provider definition
final channelVideosProvider = StateNotifierProvider<ChannelVideosNotifier, ChannelVideosState>((ref) {
  return ChannelVideosNotifier();
});