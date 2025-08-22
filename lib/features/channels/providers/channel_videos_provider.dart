// lib/features/channels/providers/channel_videos_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/channel_video_model.dart';
import '../repositories/channel_repository.dart';

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
  final ChannelRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChannelVideosNotifier(this._repository) : super(const ChannelVideosState()) {
    // Initialize with empty state and load data
    loadVideos();
    loadLikedVideos();
  }

  // Debug method to help diagnose issues
  Future<void> debugChannelVideosData() async {
    debugPrint('======= DEBUGGING CHANNEL VIDEOS DATA =======');
    
    try {
      final videos = await _repository.getChannelVideos();
      debugPrint('Total videos from repository: ${videos.length}');
      debugPrint('Current state - videos count: ${state.videos.length}');
      debugPrint('======= END DEBUGGING CHANNEL VIDEOS DATA =======');
    } on RepositoryException catch (e) {
      debugPrint('Error during debugging: ${e.message}');
    } catch (e) {
      debugPrint('Error during debugging: $e');
    }
  }

  // Load videos from repository
  Future<void> loadVideos({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have videos, just return
    if (!forceRefresh && state.videos.isNotEmpty) {
      return;
    }
    
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      final videos = await _repository.getChannelVideos(forceRefresh: forceRefresh);
      
      // Update liked status for videos
      final videosWithLikedStatus = videos.map((video) {
        final isLiked = state.likedVideos.contains(video.id);
        return video.copyWith(isLiked: isLiked);
      }).toList();
      
      // Update state with videos
      state = state.copyWith(
        videos: videosWithLikedStatus,
        isLoading: false,
      );
    } on RepositoryException catch (e) {
      debugPrint('Error loading videos: ${e.message}');
      state = state.copyWith(
        error: e.message,
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
      final channelVideos = await _repository.getVideosByChannelId(channelId);
      
      // Update liked status for videos
      final videosWithLikedStatus = channelVideos.map((video) {
        final isLiked = state.likedVideos.contains(video.id);
        return video.copyWith(isLiked: isLiked);
      }).toList();
      
      return videosWithLikedStatus;
    } on RepositoryException catch (e) {
      debugPrint('Error loading channel videos: ${e.message}');
      state = state.copyWith(error: e.message);
      return [];
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
      final likedVideos = await _repository.getLikedVideos(uid);
      state = state.copyWith(likedVideos: likedVideos);
      
      // Update isLiked status for existing videos
      final updatedVideos = state.videos.map((video) {
        return video.copyWith(isLiked: likedVideos.contains(video.id));
      }).toList();
      
      state = state.copyWith(videos: updatedVideos);
    } on RepositoryException catch (e) {
      debugPrint('Error loading liked videos: ${e.message}');
      state = state.copyWith(error: e.message);
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
      
      // Get current liked videos
      List<String> likedVideos = List.from(state.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
        await _repository.unlikeVideo(videoId, uid);
      } else {
        likedVideos.add(videoId);
        await _repository.likeVideo(videoId, uid);
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
      
    } on RepositoryException catch (e) {
      debugPrint('Error toggling like: ${e.message}');
      state = state.copyWith(error: e.message);
      
      // Revert the optimistic update on error
      loadVideos();
      loadLikedVideos();
    } catch (e) {
      debugPrint('Error toggling like: $e');
      state = state.copyWith(error: e.toString());
      
      // Revert the optimistic update on error
      loadVideos();
      loadLikedVideos();
    }
  }

  // Upload a new video to the channel - UPDATED: Auto-ensure channel
  Future<void> uploadVideo({
    required File videoFile,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      final videoId = const Uuid().v4();
      
      // CRITICAL: Ensure user has a channel before uploading
      debugPrint('DEBUG: Ensuring user has channel before video upload');
      // Note: We need access to the channels provider here
      // This will be handled by the calling screen
      
      // For now, we'll assume the channel is ensured by the calling screen
      // and we'll get it from the repository
      final userChannel = await _repository.getUserChannel(uid);
      if (userChannel == null) {
        throw RepositoryException('No channel found. Please create a channel first.');
      }
      
      // Upload video to storage
      final videoUrl = await _repository.uploadVideo(
        videoFile,
        'channelVideos/$videoId.mp4',
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress);
        },
      );
      
      // Generate thumbnail (in a real app, you'd use FFmpeg or a server function)
      // For now, we'll just use an empty string as placeholder
      const thumbnailUrl = '';
      
      // Create video
      final videoData = await _repository.createVideo(
        channelId: userChannel.id,
        channelName: userChannel.name,
        channelImage: userChannel.profileImage,
        userId: uid,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags,
      );
      
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
    } on RepositoryException catch (e) {
      debugPrint('Error uploading video: ${e.message}');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
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

  // Upload multiple images to the channel - UPDATED: Auto-ensure channel
  Future<void> uploadImages({
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
      
      // CRITICAL: Ensure user has a channel before uploading
      debugPrint('DEBUG: Ensuring user has channel before image upload');
      final userChannel = await _repository.getUserChannel(uid);
      if (userChannel == null) {
        throw RepositoryException('No channel found. Please create a channel first.');
      }
      
      // Upload each image
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final imageUrl = await _repository.uploadImage(
          file,
          'channelImages/$postId/image_$i.jpg',
        );
        imageUrls.add(imageUrl);
        
        // Update progress
        final progress = (i + 1) / imageFiles.length;
        state = state.copyWith(uploadProgress: progress);
      }
      
      // Create image post
      final postData = await _repository.createImagePost(
        channelId: userChannel.id,
        channelName: userChannel.name,
        channelImage: userChannel.profileImage,
        userId: uid,
        imageUrls: imageUrls,
        caption: caption,
        tags: tags,
      );
      
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
    } on RepositoryException catch (e) {
      debugPrint('Error uploading images: ${e.message}');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
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
      await _repository.incrementViewCount(videoId);
      
      // Update local state
      final updatedVideos = state.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(views: video.views + 1);
        }
        return video;
      }).toList();
      
      state = state.copyWith(videos: updatedVideos);
    } on RepositoryException catch (e) {
      debugPrint('Error incrementing view count: ${e.message}');
      state = state.copyWith(error: e.message);
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
      await _repository.deleteVideo(videoId, uid);
      
      // Update local state
      final updatedVideos = state.videos.where((video) => video.id != videoId).toList();
      state = state.copyWith(videos: updatedVideos);
    } on RepositoryException catch (e) {
      debugPrint('Error deleting video: ${e.message}');
      state = state.copyWith(error: e.message);
      onError(e.message);
    } catch (e) {
      debugPrint('Error deleting video: $e');
      state = state.copyWith(error: e.toString());
      onError(e.toString());
    }
  }

  // Get a specific video by ID
  Future<ChannelVideoModel?> getVideoById(String videoId) async {
    try {
      final video = await _repository.getVideoById(videoId);
      if (video != null) {
        final isLiked = state.likedVideos.contains(videoId);
        return video.copyWith(isLiked: isLiked);
      }
      return null;
    } on RepositoryException catch (e) {
      debugPrint('Error getting video by ID: ${e.message}');
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      debugPrint('Error getting video by ID: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// Provider definition
final channelVideosProvider = StateNotifierProvider<ChannelVideosNotifier, ChannelVideosState>((ref) {
  final repository = ref.watch(channelRepositoryProvider);
  return ChannelVideosNotifier(repository);
});