// lib/features/marketplace/providers/marketplace_provider.dart
// Marketplace-focused provider with marketplace item management and comment support
// 🆕 EXTRACTED FROM: authentication_provider.dart (video/comment methods only)
// ENHANCED: Simple force refresh solution for backend updates
// UPGRADED: Enhanced comment system with media support and pinning
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/marketplace/repositories/marketplace_repository.dart';
import 'package:textgb/features/marketplace/models/marketplace_item_model.dart';
import 'package:textgb/features/marketplace/models/marketplace_comment_model.dart';
import 'package:textgb/features/marketplace/services/marketplace_thumbnail_service.dart';

part 'marketplace_provider.g.dart';

// State class for marketplace
class MarketplaceState {
  final List<MarketplaceItemModel> items;
  final List<String> likedItems;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const MarketplaceState({
    this.items = const [],
    this.likedItems = const [],
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
  });

  MarketplaceState copyWith({
    List<MarketplaceItemModel>? items,
    List<String>? likedItems,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return MarketplaceState(
      items: items ?? this.items,
      likedItems: likedItems ?? this.likedItems,
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
    // Load marketplace items on initialization
    debugPrint('🛒 Loading marketplace items...');
    await loadMarketplaceItems();
    return state.value ?? const MarketplaceState();
  }

  // ===============================
  // MARKETPLACE ITEM METHODS
  // ===============================

  Future<void> loadMarketplaceItems() async {
    try {
      debugPrint('🛒 Loading marketplace items from backend...');

      final items = await _repository.getMarketplaceItems();

      debugPrint('✅ Loaded ${items.length} marketplace items successfully');

      final currentState = state.value ?? const MarketplaceState();
      final itemsWithLikedStatus = items.map((item) {
        final isLiked = currentState.likedItems.contains(item.id);
        return item.copyWith(isLiked: isLiked);
      }).toList();

      state = AsyncValue.data(currentState.copyWith(items: itemsWithLikedStatus));

    } catch (e) {
      debugPrint('❌ Error loading marketplace items: $e');
      // Don't set error state - just log it to keep UI functional
    }
  }

  Future<void> loadUserMarketplaceItems(String userId) async {
    try {
      final userItems = await _repository.getUserMarketplaceItems(userId);
    } catch (e) {
      debugPrint('Error loading user marketplace items: $e');
    }
  }

  Future<void> likeMarketplaceItem(String itemId) async {
    final currentState = state.value ?? const MarketplaceState();

    // For marketplace, we'll allow guest likes (remove authentication check)
    // Or you can add authentication check by getting userId from another provider

    try {
      List<String> likedItems = List.from(currentState.likedItems);
      bool isCurrentlyLiked = likedItems.contains(itemId);

      if (isCurrentlyLiked) {
        likedItems.remove(itemId);
        await _repository.unlikeMarketplaceItem(itemId, ''); // Pass actual userId
      } else {
        likedItems.add(itemId);
        await _repository.likeMarketplaceItem(itemId, ''); // Pass actual userId
      }

      final updatedItems = currentState.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? item.likes - 1 : item.likes + 1,
          );
        }
        return item;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(
        items: updatedItems,
        likedItems: likedItems,
      ));
    } catch (e) {
      debugPrint('Error toggling like: $e');
      await loadMarketplaceItems();
      await loadLikedMarketplaceItems(''); // Pass actual userId
    }
  }

  Future<void> createMarketplaceItem({
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

      // Create marketplace item record in database with price
      debugPrint('💾 Step 4/4: Creating marketplace item record in database...');
      debugPrint('💰 Item price: ${price ?? 0.0} KES');

      final itemData = await _repository.createMarketplaceItem(
        userId: userId,
        userName: userName,
        userImage: userImage,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        tags: tags ?? [],
        price: price ?? 0.0,
      );
      debugPrint('✅ Marketplace item record created in database with price: ${itemData.price}');

      List<MarketplaceItemModel> updatedItems = [
        itemData,
        ...currentState.items,
      ];

      // Update progress: Complete (100%)
      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        items: updatedItems,
      ));

      debugPrint('✅ Marketplace item upload complete with thumbnail and price!');
      onSuccess('Marketplace item uploaded successfully');
    } catch (e) {
      debugPrint('❌ Error uploading marketplace item: $e');

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
      onError('Failed to upload marketplace item: $e');
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

      List<MarketplaceItemModel> updatedItems = [
        postData,
        ...currentState.items,
      ];

      state = AsyncValue.data(currentState.copyWith(
        isUploading: false,
        items: updatedItems,
      ));

      onSuccess('Images uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading images: $e');
      state = AsyncValue.data(currentState.copyWith(isUploading: false));
      onError('Failed to upload images: $e');
    }
  }

  // ===============================
  // MARKETPLACE ITEM UPDATE METHODS
  // ===============================

  Future<void> updateMarketplaceItem({
    required String itemId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      final updatedItem = await _repository.updateMarketplaceItem(
        itemId: itemId,
        caption: caption,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
      );

      final updatedItems = currentState.items.map((item) {
        if (item.id == itemId) {
          return updatedItem;
        }
        return item;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(items: updatedItems));

      onSuccess('Marketplace item updated successfully');
    } catch (e) {
      debugPrint('Error updating marketplace item: $e');
      onError('Failed to update marketplace item: $e');
    }
  }

  Future<void> updateMarketplaceItemCaption({
    required String itemId,
    required String caption,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    await updateMarketplaceItem(
      itemId: itemId,
      caption: caption,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  Future<void> deleteMarketplaceItem(String itemId, Function(String) onError) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      await _repository.deleteMarketplaceItem(itemId, ''); // Pass actual userId

      final updatedItems = currentState.items.where((item) => item.id != itemId).toList();
      state = AsyncValue.data(currentState.copyWith(items: updatedItems));
    } catch (e) {
      debugPrint('Error deleting marketplace item: $e');
      onError('Failed to delete marketplace item: $e');
    }
  }

  Future<void> incrementMarketplaceItemViewCount(String itemId) async {
    try {
      await _repository.incrementMarketplaceItemViewCount(itemId);

      final currentState = state.value ?? const MarketplaceState();
      final updatedItems = currentState.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(views: item.views + 1);
        }
        return item;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(items: updatedItems));
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  Future<void> loadLikedMarketplaceItems(String userId) async {
    try {
      final likedItems = await _repository.getLikedMarketplaceItems(userId);
      final currentState = state.value ?? const MarketplaceState();

      state = AsyncValue.data(currentState.copyWith(likedItems: likedItems));

      final updatedItems = currentState.items.map((item) {
        return item.copyWith(isLiked: likedItems.contains(item.id));
      }).toList();

      state = AsyncValue.data(currentState.copyWith(items: updatedItems));
    } catch (e) {
      debugPrint('Error loading liked marketplace items: $e');
    }
  }

  // ===============================
  // BOOST METHODS
  // ===============================

  /// Purchase marketplace item boost using wallet coins
  Future<void> boostMarketplaceItem({
    required String itemId,
    required String boostTier,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final currentState = state.value ?? const MarketplaceState();

    try {
      debugPrint('🚀 Starting boost purchase for marketplace item: $itemId');
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

      // Call repository to boost item (backend will handle wallet deduction)
      final boostedItem = await _repository.boostMarketplaceItem(
        itemId: itemId,
        userId: '', // Pass actual userId from auth provider
        boostTier: boostTier.toLowerCase(),
        coinAmount: coinAmount,
      );

      debugPrint('✅ Boost purchase successful');
      debugPrint('   - Item now boosted: ${boostedItem.isBoosted}');
      debugPrint('   - Boost tier: ${boostedItem.boostTier}');

      // Update item in local state
      final updatedItems = currentState.items.map((item) {
        if (item.id == itemId) {
          return boostedItem;
        }
        return item;
      }).toList();

      state = AsyncValue.data(currentState.copyWith(items: updatedItems));

      onSuccess('Marketplace item boosted successfully! 🚀');

    } catch (e) {
      debugPrint('❌ Boost purchase failed: $e');

      // Handle specific error cases
      if (e.toString().toLowerCase().contains('insufficient')) {
        onError('Insufficient wallet balance. Please top up your wallet.');
      } else if (e.toString().toLowerCase().contains('already boosted')) {
        onError('This item is already boosted.');
      } else {
        onError('Failed to boost item: $e');
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
    required String itemId,
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

      debugPrint('💬 Adding marketplace comment to item: $itemId');
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
        videoId: itemId,
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

  Future<List<MarketplaceCommentModel>> getMarketplaceItemComments(String itemId) async {
    try {
      debugPrint('📥 Fetching marketplace comments for item: $itemId');
      final comments = await _repository.getMarketplaceItemComments(itemId);
      debugPrint('✅ Retrieved ${comments.length} marketplace comments');
      return comments;
    } catch (e) {
      debugPrint('❌ Error getting marketplace item comments: $e');
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

  // 🆕 NEW: Pin marketplace comment (item creator only)
  Future<void> pinMarketplaceComment(
    String commentId,
    String itemId,
    Function(String) onError,
  ) async {
    try {
      debugPrint('📌 Pinning marketplace comment: $commentId');
      await _repository.pinMarketplaceComment(commentId, itemId, ''); // Pass actual userId
      debugPrint('✅ Marketplace comment pinned successfully');
    } catch (e) {
      debugPrint('❌ Error pinning marketplace comment: $e');
      onError('Failed to pin marketplace comment: $e');
    }
  }

  // 🆕 NEW: Unpin marketplace comment (item creator only)
  Future<void> unpinMarketplaceComment(
    String commentId,
    String itemId,
    Function(String) onError,
  ) async {
    try {
      debugPrint('📍 Unpinning marketplace comment: $commentId');
      await _repository.unpinMarketplaceComment(commentId, itemId, ''); // Pass actual userId
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

  List<MarketplaceItemModel> get items {
    final currentState = state.value;
    return currentState?.items ?? [];
  }

  bool isItemLiked(String itemId) {
    final currentState = state.value;
    return currentState?.likedItems.contains(itemId) ?? false;
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
