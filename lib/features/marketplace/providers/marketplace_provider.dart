// lib/features/marketplace/providers/marketplace_provider.dart
// Marketplace-focused provider with marketplace video management and comment support
// 🆕 EXTRACTED FROM: authentication_provider.dart (video/comment methods only)
// ENHANCED: Simple force refresh solution for backend updates
// UPGRADED: Enhanced comment system with media support and pinning
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/marketplace/repositories/marketplace_repository.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/marketplace/models/marketplace_comment_model.dart';
import 'package:textgb/features/marketplace/services/marketplace_thumbnail_service.dart';

part 'marketplace_provider.g.dart';

// State class for marketplace
class MarketplaceState {
  final List<MarketplaceVideoModel> videos;
  final List<String> likedVideos;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const MarketplaceState({
    this.videos = const [],
    this.likedVideos = const [],
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
  });

  MarketplaceState copyWith({
    List<MarketplaceVideoModel>? videos,
    List<String>? likedVideos,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return MarketplaceState(
      videos: videos ?? this.videos,
      likedVideos: likedVideos ?? this.likedVideos,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
    );
  }
}

// Repository provider
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return FirebaseMarketplaceRepository();
});

@riverpod
class Marketplace extends _$Marketplace {
  MarketplaceRepository get _repository => ref.read(marketplaceRepositoryProvider);

  @override
  FutureOr<MarketplaceState> build() async {
    // Load marketplace videos on initialization
    debugPrint('🛒 Loading marketplace videos...');
    await loadMarketplaceVideos();
    return state.value ?? const MarketplaceState();
  }

  // ===============================
  // MARKETPLACE VIDEO METHODS
  // ===============================

  Future<void> loadMarketplaceVideos() async {
    try {
      debugPrint('🛒 Loading marketplace videos from backend...');

      final videos = await _repository.getMarketplaceVideos();

      debugPrint('✅ Loaded ${videos.length} marketplace videos successfully');

      final currentState = state.value ?? const MarketplaceState();
      final videosWithLikedStatus = videos.map((video) {
        final isLiked = currentState.likedVideos.contains(video.id);
        return video.copyWith(isLiked: isLiked);
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: videosWithLikedStatus));

    } catch (e) {
      debugPrint('❌ Error loading marketplace videos: $e');
      // Don't set error state - just log it to keep UI functional
    }
  }

  Future<void> loadUserMarketplaceVideos(String userId) async {
    try {
      final userVideos = await _repository.getUserMarketplaceVideos(userId);
    } catch (e) {
      debugPrint('Error loading user marketplace videos: $e');
    }
  }

  Future<void> likeMarketplaceVideo(String videoId) async {
    final currentState = state.value ?? const MarketplaceState();

    // For marketplace, we'll allow guest likes (remove authentication check)
    // Or you can add authentication check by getting userId from another provider

    try {
      List<String> likedVideos = List.from(currentState.likedVideos);
      bool isCurrentlyLiked = likedVideos.contains(videoId);

      if (isCurrentlyLiked) {
        likedVideos.remove(videoId);
        await _repository.unlikeMarketplaceVideo(videoId, ''); // Pass actual userId
      } else {
        likedVideos.add(videoId);
        await _repository.likeMarketplaceVideo(videoId, ''); // Pass actual userId
      }

      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? video.likes - 1 : video.likes + 1,
          );
        }
        return video;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(
        videos: updatedVideos,
        likedVideos: likedVideos,
      ));
    } catch (e) {
      debugPrint('Error toggling like: $e');
      await loadMarketplaceVideos();
      await loadLikedMarketplaceVideos(''); // Pass actual userId
    }
  }

  Future<void> createMarketplaceVideo({
    required File videoFile,
    File? thumbnailFile,
    required String caption,
    List<String>? tags,
    double? price,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    state = AsyncValue.data(currentState.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    ));

    try {
      // For marketplace, you'll need to get user info from authentication provider
      // This is a placeholder - update with actual user data
      final String userId = 'user-id'; // Get from auth provider
      final String userName = 'User Name'; // Get from auth provider
      final String userImage = ''; // Get from auth provider

      debugPrint('🛒 Step 1/4: Using pre-generated thumbnail...');

      if (thumbnailFile == null) {
        debugPrint('⚠️ Warning: No thumbnail provided, continuing without it');
      } else {
        debugPrint('✅ Pre-generated thumbnail received: ${thumbnailFile.path}');
      }

      // Update progress: Thumbnail ready (10%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.1,
      ));

      // Upload thumbnail to Cloudflare R2 (if provided)
      String thumbnailUrl = '';
      if (thumbnailFile != null) {
        debugPrint('☁️ Step 2/4: Uploading thumbnail to Cloudflare R2...');
        try {
          thumbnailUrl = await _repository.storeFileToStorage(
            file: thumbnailFile,
            reference: 'thumbnails/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          debugPrint('✅ Thumbnail uploaded to R2: $thumbnailUrl');

          // Clean up temporary thumbnail file after successful upload
          final thumbnailService = MarketplaceThumbnailService();
          await thumbnailService.deleteThumbnailFile(thumbnailFile);
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to upload thumbnail: $e');
          thumbnailUrl = '';

          try {
            final thumbnailService = MarketplaceThumbnailService();
            await thumbnailService.deleteThumbnailFile(thumbnailFile);
          } catch (_) {}
        }
      }

      // Update progress: Thumbnail uploaded (20%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.2,
      ));

      // Upload video to Cloudflare R2
      debugPrint('🎹 Step 3/4: Uploading video to Cloudflare R2...');
      final videoUrl = await _repository.storeFileToStorage(
        file: videoFile,
        reference: 'marketplace/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress: (progress) {
          final mappedProgress = 0.2 + (progress * 0.7);
          final currentState = state.value ?? const MarketplaceState();
          state = AsyncValue.data(currentState.copyWith(
            uploadProgress: mappedProgress,
          ));
        },
      );
      debugPrint('✅ Video uploaded to R2: $videoUrl');

      // Update progress: Video uploaded (90%)
      state = AsyncValue.data(currentState.copyWith(
        uploadProgress: 0.9,
      ));

      // Create marketplace video record in database with price
      debugPrint('💾 Step 4/4: Creating marketplace video record in database...');
      debugPrint('💰 Video price: ${price ?? 0.0} KES');

      final videoData = await _repository.createMarketplaceVideo(
        userId: userId,
        userName: userName,
        userImage: userImage,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags ?? [],
        price: price ?? 0.0,
      );
      debugPrint('✅ Marketplace video record created in database with price: ${videoData.price}');

      List<MarketplaceVideoModel> updatedVideos = [
        videoData,
        ...currentState.videos,
      ];

      // Update progress: Complete (100%)
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        videos: updatedVideos,
      ));

      debugPrint('✅ Marketplace video upload complete with thumbnail and price!');
      onSuccess('Marketplace video uploaded successfully');
    } catch (e) {
      debugPrint('❌ Error uploading marketplace video: $e');

      // Clean up thumbnail file if it exists
      if (thumbnailFile != null) {
        try {
          final thumbnailService = MarketplaceThumbnailService();
          await thumbnailService.deleteThumbnailFile(thumbnailFile);
        } catch (_) {}
      }

      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      ));
      onError('Failed to upload marketplace video: $e');
    }
  }

  Future<void> createMarketplaceImagePost({
    required List<File> imageFiles,
    required String caption,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    if (imageFiles.isEmpty) {
      onError('No images selected');
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isUploading: true));

    try {
      // For marketplace, you'll need to get user info from authentication provider
      final String userId = 'user-id'; // Get from auth provider
      final String userName = 'User Name'; // Get from auth provider
      final String userImage = ''; // Get from auth provider

      final List<String> imageUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final imageUrl = await _repository.storeFileToStorage(
          file: file,
          reference: 'marketplace/images/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        imageUrls.add(imageUrl);
      }

      final postData = await _repository.createMarketplaceImagePost(
        userId: userId,
        userName: userName,
        userImage: userImage,
        imageUrls: imageUrls,
        caption: caption,
        tags: tags ?? [],
      );

      List<MarketplaceVideoModel> updatedVideos = [
        postData,
        ...currentState.videos,
      ];

      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        videos: updatedVideos,
      ));

      onSuccess('Images uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading images: $e');
      state = AsyncValue.data(currentState.copyWith(isUploading: false));
      onError('Failed to upload images: $e');
    }
  }

  // ===============================
  // MARKETPLACE VIDEO UPDATE METHODS
  // ===============================

  Future<void> updateMarketplaceVideo({
    required String videoId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      final updatedVideo = await _repository.updateMarketplaceVideo(
        videoId: videoId,
        caption: caption,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
      );

      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return updatedVideo;
        }
        return video;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));

      onSuccess('Marketplace video updated successfully');
    } catch (e) {
      debugPrint('Error updating marketplace video: $e');
      onError('Failed to update marketplace video: $e');
    }
  }

  Future<void> updateMarketplaceVideoCaption({
    required String videoId,
    required String caption,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateMarketplaceVideo(
      videoId: videoId,
      caption: caption,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<void> deleteMarketplaceVideo(String videoId, Function(String) onError) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      await _repository.deleteMarketplaceVideo(videoId, ''); // Pass actual userId

      final updatedVideos = currentState.videos.where((video) => video.id != videoId).toList();
      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } catch (e) {
      debugPrint('Error deleting marketplace video: $e');
      onError('Failed to delete marketplace video: $e');
    }
  }

  Future<void> incrementMarketplaceVideoViewCount(String videoId) async {
    try {
      await _repository.incrementMarketplaceVideoViewCount(videoId);

      final currentState = state.value ?? const MarketplaceState();
      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return video.copyWith(views: video.views + 1);
        }
        return video;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> loadLikedMarketplaceVideos(String userId) async {
    try {
      final likedVideos = await _repository.getLikedMarketplaceVideos(userId);
      final currentState = state.value ?? const MarketplaceState();

      state = AsyncValue.data(currentState.copyWith(likedVideos: likedVideos));

      final updatedVideos = currentState.videos.map((video) {
        return video.copyWith(isLiked: likedVideos.contains(video.id));
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
    } catch (e) {
      debugPrint('Error loading liked marketplace videos: $e');
    }
  }

  // ===============================
  // BOOST METHODS
  // ===============================

  /// Purchase marketplace video boost using wallet coins
  Future<void> boostMarketplaceVideo({
    required String videoId,
    required String boostTier,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      debugPrint('🚀 Starting boost purchase for marketplace video: $videoId');
      debugPrint('   - Boost Tier: $boostTier');

      // Determine coin amount based on boost tier
      final int coinAmount;
      switch (boostTier.toLowerCase()) {
        case 'basic':
          coinAmount = 99;
          break;
        case 'standard':
          coinAmount = 999;
          break;
        case 'advanced':
          coinAmount = 9999;
          break;
        default:
          onError('Invalid boost tier');
          return;
      }

      debugPrint('   - Coin Amount: $coinAmount');

      // Call repository to boost video (backend will handle wallet deduction)
      final boostedVideo = await _repository.boostMarketplaceVideo(
        videoId: videoId,
        userId: '', // Pass actual userId from auth provider
        boostTier: boostTier.toLowerCase(),
        coinAmount: coinAmount,
      );

      debugPrint('✅ Boost purchase successful');
      debugPrint('   - Video now boosted: ${boostedVideo.isBoosted}');
      debugPrint('   - Boost tier: ${boostedVideo.boostTier}');

      // Update video in local state
      final updatedVideos = currentState.videos.map((video) {
        if (video.id == videoId) {
          return boostedVideo;
        }
        return video;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));

      onSuccess('Marketplace video boosted successfully! 🚀');

    } catch (e) {
      debugPrint('❌ Boost purchase failed: $e');

      // Handle specific error cases
      if (e.toString().toLowerCase().contains('insufficient')) {
        onError('Insufficient wallet balance. Please top up your wallet.');
      } else if (e.toString().toLowerCase().contains('already boosted')) {
        onError('This video is already boosted.');
      } else {
        onError('Failed to boost video: $e');
      }
    }
  }

  /// Check if user can afford a specific boost tier
  bool canAffordBoost(String boostTier) {
    // This is a simple check - actual wallet balance check should be done via wallet provider
    final int requiredCoins;
    switch (boostTier.toLowerCase()) {
      case 'basic':
        requiredCoins = 99;
        break;
      case 'standard':
        requiredCoins = 999;
        break;
      case 'advanced':
        requiredCoins = 9999;
        break;
      default:
        return false;
    }

    // Note: This is a placeholder - real implementation should check wallet balance
    // For now, we'll always return true and let the backend handle the actual check
    return true;
  }

  /// Get boost tier price
  int getBoostTierPrice(String boostTier) {
    switch (boostTier.toLowerCase()) {
      case 'basic':
        return 99;
      case 'standard':
        return 999;
      case 'advanced':
        return 9999;
      default:
        return 0;
    }
  }

  /// Get boost tier display info
  Map<String, dynamic> getBoostTierInfo(String boostTier) {
    switch (boostTier.toLowerCase()) {
      case 'basic':
        return {
          'name': 'Basic Boost',
          'price': 99,
          'viewRange': '1,713 - 10K views',
          'duration': '72 hours',
          'icon': '⚡',
        };
      case 'standard':
        return {
          'name': 'Standard Boost',
          'price': 999,
          'viewRange': '17,138 - 100K views',
          'duration': '72 hours',
          'icon': '🚀',
        };
      case 'advanced':
        return {
          'name': 'Advanced Boost',
          'price': 9999,
          'viewRange': '171,388 - 1M views',
          'duration': '72 hours',
          'icon': '⭐',
        };
      default:
        return {
          'name': 'Unknown',
          'price': 0,
          'viewRange': 'N/A',
          'duration': '0 hours',
          'icon': '',
        };
    }
  }

  // ===============================
  // 🆕 ENHANCED MARKETPLACE COMMENT METHODS WITH MEDIA SUPPORT
  // ===============================

  /// 🆕 ENHANCED: Add marketplace comment with optional image attachments
  Future<void> addMarketplaceComment({
    required String videoId,
    required String content,
    List<File>? imageFiles,
    String? repliedToCommentId,
    String? repliedToAuthorName,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      // For marketplace, you'll need to get user info from authentication provider
      final String userId = 'user-id'; // Get from auth provider
      final String userName = 'User Name'; // Get from auth provider
      final String userImage = ''; // Get from auth provider

      debugPrint('💬 Adding marketplace comment to video: $videoId');
      if (imageFiles != null && imageFiles.isNotEmpty) {
        debugPrint('📸 Marketplace comment includes ${imageFiles.length} image(s)');
      }

      // 🆕 Upload images if provided (max 2 images)
      List<String>? imageUrls;
      if (imageFiles != null && imageFiles.isNotEmpty) {
        try {
          final filesToUpload = imageFiles.take(2).toList();

          debugPrint('☁️ Uploading ${filesToUpload.length} marketplace comment images to R2...');

          imageUrls = await _repository.storeFilesToStorage(
            files: filesToUpload,
            referencePrefix: 'marketplace/comments/$userId/${DateTime.now().millisecondsSinceEpoch}',
          );

          debugPrint('✅ Marketplace comment images uploaded successfully');
        } catch (e) {
          debugPrint('⚠️ Warning: Failed to upload marketplace comment images: $e');
          imageUrls = null;
        }
      }

      // Create marketplace comment with uploaded image URLs
      await _repository.addMarketplaceComment(
        videoId: videoId,
        authorId: userId,
        authorName: userName,
        authorImage: userImage,
        content: content,
        imageUrls: imageUrls,
        repliedToCommentId: repliedToCommentId,
        repliedToAuthorName: repliedToAuthorName,
      );

      debugPrint('✅ Marketplace comment added successfully');
      onSuccess('Comment added successfully');
    } catch (e) {
      debugPrint('❌ Error adding marketplace comment: $e');
      onError('Failed to add comment: $e');
    }
  }

  Future<List<MarketplaceCommentModel>> getMarketplaceVideoComments(String videoId) async {
    try {
      debugPrint('📥 Fetching marketplace comments for video: $videoId');
      final comments = await _repository.getMarketplaceVideoComments(videoId);
      debugPrint('✅ Retrieved ${comments.length} marketplace comments');
      return comments;
    } catch (e) {
      debugPrint('❌ Error getting marketplace video comments: $e');
      return [];
    }
  }

  Future<void> deleteMarketplaceComment(String commentId, Function(String) onError) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      debugPrint('🗑️ Deleting marketplace comment: $commentId');
      await _repository.deleteMarketplaceComment(commentId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting marketplace comment: $e');
      onError('Failed to delete marketplace comment: $e');
    }
  }

  Future<void> likeMarketplaceComment(String commentId) async {
    try {
      debugPrint('❤️ Liking marketplace comment: $commentId');
      await _repository.likeMarketplaceComment(commentId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment liked successfully');
    } catch (e) {
      debugPrint('❌ Error liking marketplace comment: $e');
    }
  }

  Future<void> unlikeMarketplaceComment(String commentId) async {
    try {
      debugPrint('💔 Unliking marketplace comment: $commentId');
      await _repository.unlikeMarketplaceComment(commentId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment unliked successfully');
    } catch (e) {
      debugPrint('❌ Error unliking marketplace comment: $e');
    }
  }

  // 🆕 NEW: Pin marketplace comment (video creator only)
  Future<void> pinMarketplaceComment(
    String commentId,
    String videoId,
    Function(String) onError,
  ) async {
    try {
      debugPrint('📌 Pinning marketplace comment: $commentId');
      await _repository.pinMarketplaceComment(commentId, videoId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment pinned successfully');
    } catch (e) {
      debugPrint('❌ Error pinning marketplace comment: $e');
      onError('Failed to pin marketplace comment: $e');
    }
  }

  // 🆕 NEW: Unpin marketplace comment (video creator only)
  Future<void> unpinMarketplaceComment(
    String commentId,
    String videoId,
    Function(String) onError,
  ) async {
    try {
      debugPrint('📍 Unpinning marketplace comment: $commentId');
      await _repository.unpinMarketplaceComment(commentId, videoId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment unpinned successfully');
    } catch (e) {
      debugPrint('❌ Error unpinning marketplace comment: $e');
      onError('Failed to unpin marketplace comment: $e');
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  // Helper getters for UI
  bool get isUploading {
    final currentState = state.value;
    return currentState?.isUploading ?? false;
  }

  double get uploadProgress {
    final currentState = state.value;
    return currentState?.uploadProgress ?? 0.0;
  }

  List<MarketplaceVideoModel> get videos {
    final currentState = state.value;
    return currentState?.videos ?? [];
  }

  bool isVideoLiked(String videoId) {
    final currentState = state.value;
    return currentState?.likedVideos.contains(videoId) ?? false;
  }

  // File operations
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
  }) async {
    try {
      return await _repository.storeFileToStorage(
        file: file,
        reference: reference,
      );
    } catch (e) {
      throw 'Failed to store file: $e';
    }
  }
}
