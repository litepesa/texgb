// lib/features/marketplace/repositories/marketplace_repository.dart
// MARKETPLACE VERSION: Marketplace-specific operations with R2 Storage + Advanced Comment System
// 🆕 EXTRACTED FROM: authentication_repository.dart (video/comment methods only)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/marketplace/models/marketplace_comment_model.dart';
import '../../../shared/services/http_client.dart';

// Abstract repository interface for marketplace operations
abstract class MarketplaceRepository {
  // Marketplace video operations
  Future<List<MarketplaceVideoModel>> getMarketplaceVideos();
  Future<List<MarketplaceVideoModel>> getUserMarketplaceVideos(String userId);
  Future<MarketplaceVideoModel?> getMarketplaceVideoById(String videoId);
  Future<MarketplaceVideoModel> createMarketplaceVideo({
    required String userId,
    required String userName,
    required String userImage,
    required String videoUrl,
    required String thumbnailUrl,
    required String caption,
    List<String>? tags,
    double? price,
  });
  Future<MarketplaceVideoModel> createMarketplaceImagePost({
    required String userId,
    required String userName,
    required String userImage,
    required List<String> imageUrls,
    required String caption,
    List<String>? tags,
    double? price,
  });
  Future<MarketplaceVideoModel> updateMarketplaceVideo({
    required String videoId,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
    double? price,
  });
  Future<void> deleteMarketplaceVideo(String videoId, String userId);
  Future<void> likeMarketplaceVideo(String videoId, String userId);
  Future<void> unlikeMarketplaceVideo(String videoId, String userId);
  Future<List<String>> getLikedMarketplaceVideos(String userId);
  Future<void> incrementMarketplaceVideoViewCount(String videoId);

  // 🆕 ENHANCED Marketplace comment operations with media support
  Future<MarketplaceCommentModel> addMarketplaceComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  });
  Future<List<MarketplaceCommentModel>> getMarketplaceVideoComments(String videoId);
  Future<void> deleteMarketplaceComment(String commentId, String userId);
  Future<void> likeMarketplaceComment(String commentId, String userId);
  Future<void> unlikeMarketplaceComment(String commentId, String userId);

  // 🆕 NEW: Pin/Unpin marketplace comment operations
  Future<MarketplaceCommentModel> pinMarketplaceComment(String commentId, String videoId, String userId);
  Future<MarketplaceCommentModel> unpinMarketplaceComment(String commentId, String videoId, String userId);

  // Boost operations
  Future<MarketplaceVideoModel> boostMarketplaceVideo({
    required String videoId,
    required String userId,
    required String boostTier,
    required int coinAmount,
  });

  // File operations (R2 via Go backend)
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
    Function(double)? onProgress,
  });

  // 🆕 NEW: Upload multiple files (for marketplace comment images)
  Future<List<String>> storeFilesToStorage({
    required List<File> files,
    required String referencePrefix,
    Function(double)? onProgress,
  });
}

// COMPLETE IMPLEMENTATION: Marketplace Repository
class FirebaseMarketplaceRepository implements MarketplaceRepository {
  final HttpClientService _httpClient;

  FirebaseMarketplaceRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // ===============================
  // MARKETPLACE VIDEO OPERATIONS (WITH PRICE SUPPORT)
  // ===============================

  @override
  Future<List<MarketplaceVideoModel>> getMarketplaceVideos() async {
    try {
      final response = await _httpClient.get('/marketplace');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> videosData = responseData['items'] ?? responseData['videos'] ?? [];
        return videosData
            .map((videoData) => MarketplaceVideoModel.fromJson(videoData as Map<String, dynamic>))
            .toList();
      } else {
        throw MarketplaceRepositoryException('Failed to get marketplace videos: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to get marketplace videos: $e');
    }
  }

  @override
  Future<List<MarketplaceVideoModel>> getUserMarketplaceVideos(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/marketplace');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> videosData = responseData['items'] ?? responseData['videos'] ?? [];
        return videosData
            .map((videoData) => MarketplaceVideoModel.fromJson(videoData as Map<String, dynamic>))
            .toList();
      } else {
        throw MarketplaceRepositoryException('Failed to get user marketplace videos: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to get user marketplace videos: $e');
    }
  }

  @override
  Future<MarketplaceVideoModel?> getMarketplaceVideoById(String videoId) async {
    try {
      final response = await _httpClient.get('/marketplace/$videoId');

      if (response.statusCode == 200) {
        final videoData = jsonDecode(response.body) as Map<String, dynamic>;
        return MarketplaceVideoModel.fromJson(videoData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw MarketplaceRepositoryException('Failed to get marketplace video by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw MarketplaceRepositoryException('Failed to get marketplace video by ID: $e');
    }
  }

  @override
  Future<MarketplaceVideoModel> createMarketplaceVideo({
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

      final response = await _httpClient.post('/marketplace', body: videoData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] :
                       responseData.containsKey('video') ? responseData['video'] : responseData;
        return MarketplaceVideoModel.fromJson(videoMap);
      } else {
        throw MarketplaceRepositoryException('Failed to create marketplace video: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to create marketplace video: $e');
    }
  }

  @override
  Future<MarketplaceVideoModel> createMarketplaceImagePost({
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

      final response = await _httpClient.post('/marketplace', body: postData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] :
                       responseData.containsKey('video') ? responseData['video'] : responseData;
        return MarketplaceVideoModel.fromJson(videoMap);
      } else {
        throw MarketplaceRepositoryException('Failed to create marketplace image post: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to create marketplace image post: $e');
    }
  }

  @override
  Future<MarketplaceVideoModel> updateMarketplaceVideo({
    required String videoId,
    String? caption,
    double? price,
    String? videoUrl,
    String? thumbnailUrl,
    List<String>? tags,
  }) async {
    try {
      debugPrint('🔄 Updating marketplace video: $videoId');

      final Map<String, dynamic> updateData = {
        'updatedAt': _createTimestamp(),
      };

      if (caption != null) updateData['caption'] = caption;
      if (price != null) updateData['price'] = price;
      if (videoUrl != null) updateData['videoUrl'] = videoUrl;
      if (thumbnailUrl != null) updateData['thumbnailUrl'] = thumbnailUrl;
      if (tags != null) updateData['tags'] = tags;

      final response = await _httpClient.put('/marketplace/$videoId', body: updateData);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] :
                       responseData.containsKey('video') ? responseData['video'] : responseData;
        return MarketplaceVideoModel.fromJson(videoMap);
      } else {
        throw MarketplaceRepositoryException('Failed to update marketplace video: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to update marketplace video: $e');
    }
  }

  @override
  Future<void> deleteMarketplaceVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.delete('/marketplace/$videoId');

      if (response.statusCode != 200) {
        throw MarketplaceRepositoryException('Failed to delete marketplace video: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to delete marketplace video: $e');
    }
  }

  @override
  Future<void> likeMarketplaceVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.post('/marketplace/$videoId/like', body: {});

      if (response.statusCode != 200) {
        throw MarketplaceRepositoryException('Failed to like marketplace video: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to like marketplace video: $e');
    }
  }

  @override
  Future<void> unlikeMarketplaceVideo(String videoId, String userId) async {
    try {
      final response = await _httpClient.delete('/marketplace/$videoId/like');

      if (response.statusCode != 200) {
        throw MarketplaceRepositoryException('Failed to unlike marketplace video: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to unlike marketplace video: $e');
    }
  }

  @override
  Future<List<String>> getLikedMarketplaceVideos(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/liked-marketplace');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> likedVideosData = responseData['items'] ?? responseData['videos'] ?? [];
        return likedVideosData.cast<String>();
      } else {
        throw MarketplaceRepositoryException('Failed to get liked marketplace videos: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to get liked marketplace videos: $e');
    }
  }

  @override
  Future<void> incrementMarketplaceVideoViewCount(String videoId) async {
    try {
      final response = await _httpClient.post('/marketplace/$videoId/views', body: {});

      if (response.statusCode != 200) {
        throw MarketplaceRepositoryException('Failed to increment marketplace video view count: ${response.body}');
      }
    } catch (e) {
      throw MarketplaceRepositoryException('Failed to increment marketplace video view count: $e');
    }
  }

  // ===============================
  // 🆕 ENHANCED MARKETPLACE COMMENT OPERATIONS WITH MEDIA SUPPORT
  // ===============================

  @override
  Future<MarketplaceCommentModel> addMarketplaceComment({
    required String videoId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    List<String>? imageUrls,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) async {
    try {
      debugPrint('💬 Adding marketplace comment to item: $videoId');
      if (imageUrls != null && imageUrls.isNotEmpty) {
        debugPrint('📸 Marketplace comment includes ${imageUrls.length} image(s)');
      }

      final timestamp = _createTimestamp();

      final commentData = {
        'videoId': videoId,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'content': content.trim(),
        'imageUrls': imageUrls ?? [],
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'likesCount': 0,
        'isReply': repliedToCommentId != null,
        'isPinned': false,
        'isEdited': false,
        'isActive': true,
        if (repliedToCommentId != null) 'repliedToCommentId': repliedToCommentId,
        if (repliedToCommentId != null) 'parentCommentId': repliedToCommentId,
        if (repliedToAuthorName != null) 'repliedToAuthorName': repliedToAuthorName,
      };

      final response = await _httpClient.post('/marketplace/$videoId/comments', body: commentData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Marketplace comment added successfully');
        return MarketplaceCommentModel.fromJson(responseData);
      } else {
        debugPrint('❌ Failed to add marketplace comment: ${response.statusCode} - ${response.body}');
        throw MarketplaceRepositoryException('Failed to add marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error adding marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to add marketplace comment: $e');
    }
  }

  @override
  Future<List<MarketplaceCommentModel>> getMarketplaceVideoComments(String videoId) async {
    try {
      debugPrint('📥 Fetching marketplace comments for item: $videoId');
      final response = await _httpClient.get('/marketplace/$videoId/comments');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> commentsData = responseData['comments'] ?? [];

        final comments = commentsData.map((commentData) {
          final Map<String, dynamic> data = commentData as Map<String, dynamic>;
          return MarketplaceCommentModel.fromJson(data);
        }).toList();

        debugPrint('✅ Retrieved ${comments.length} marketplace comments');
        return comments;
      } else {
        throw MarketplaceRepositoryException('Failed to get marketplace video comments: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching marketplace comments: $e');
      throw MarketplaceRepositoryException('Failed to get marketplace video comments: $e');
    }
  }

  @override
  Future<void> deleteMarketplaceComment(String commentId, String userId) async {
    try {
      debugPrint('🗑️ Deleting marketplace comment: $commentId');
      final response = await _httpClient.delete('/marketplace/comments/$commentId?userId=$userId');

      if (response.statusCode == 200) {
        debugPrint('✅ Marketplace comment deleted successfully');
      } else {
        throw MarketplaceRepositoryException('Failed to delete marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to delete marketplace comment: $e');
    }
  }

  @override
  Future<void> likeMarketplaceComment(String commentId, String userId) async {
    try {
      debugPrint('❤️ Liking marketplace comment: $commentId');
      final response = await _httpClient.post('/marketplace/comments/$commentId/like', body: {
        'userId': userId,
      });

      if (response.statusCode == 200) {
        debugPrint('✅ Marketplace comment liked successfully');
      } else {
        throw MarketplaceRepositoryException('Failed to like marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error liking marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to like marketplace comment: $e');
    }
  }

  @override
  Future<void> unlikeMarketplaceComment(String commentId, String userId) async {
    try {
      debugPrint('💔 Unliking marketplace comment: $commentId');
      final response = await _httpClient.delete('/marketplace/comments/$commentId/like?userId=$userId');

      if (response.statusCode == 200) {
        debugPrint('✅ Marketplace comment unliked successfully');
      } else {
        throw MarketplaceRepositoryException('Failed to unlike marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error unliking marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to unlike marketplace comment: $e');
    }
  }

  // 🆕 NEW: Pin marketplace comment operation
  @override
  Future<MarketplaceCommentModel> pinMarketplaceComment(String commentId, String videoId, String userId) async {
    try {
      debugPrint('📌 Pinning marketplace comment: $commentId');
      final response = await _httpClient.post('/marketplace/comments/$commentId/pin', body: {
        'videoId': videoId,
        'userId': userId,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Marketplace comment pinned successfully');
        return MarketplaceCommentModel.fromJson(responseData);
      } else {
        debugPrint('❌ Failed to pin marketplace comment: ${response.statusCode} - ${response.body}');
        throw MarketplaceRepositoryException('Failed to pin marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error pinning marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to pin marketplace comment: $e');
    }
  }

  // 🆕 NEW: Unpin marketplace comment operation
  @override
  Future<MarketplaceCommentModel> unpinMarketplaceComment(String commentId, String videoId, String userId) async {
    try {
      debugPrint('📍 Unpinning marketplace comment: $commentId');
      final response = await _httpClient.delete('/marketplace/comments/$commentId/pin?videoId=$videoId&userId=$userId');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Marketplace comment unpinned successfully');
        return MarketplaceCommentModel.fromJson(responseData);
      } else {
        debugPrint('❌ Failed to unpin marketplace comment: ${response.statusCode} - ${response.body}');
        throw MarketplaceRepositoryException('Failed to unpin marketplace comment: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error unpinning marketplace comment: $e');
      throw MarketplaceRepositoryException('Failed to unpin marketplace comment: $e');
    }
  }

  // ===============================
  // BOOST OPERATIONS
  // ===============================

  @override
  Future<MarketplaceVideoModel> boostMarketplaceVideo({
    required String videoId,
    required String userId,
    required String boostTier,
    required int coinAmount,
  }) async {
    try {
      debugPrint('🚀 Boosting marketplace video: $videoId with tier: $boostTier');

      final response = await _httpClient.post('/marketplace/$videoId/boost', body: {
        'userId': userId,
        'boostTier': boostTier,
        'coinAmount': coinAmount,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoMap = responseData.containsKey('video') ? responseData['video'] :
                       responseData.containsKey('video') ? responseData['video'] : responseData;
        debugPrint('✅ Marketplace video boosted successfully');
        return MarketplaceVideoModel.fromJson(videoMap);
      } else {
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Unknown error';
          throw MarketplaceRepositoryException('Failed to boost marketplace video: $errorMessage');
        } catch (_) {
          throw MarketplaceRepositoryException('Failed to boost marketplace video: ${response.body}');
        }
      }
    } catch (e) {
      if (e is MarketplaceRepositoryException) rethrow;
      throw MarketplaceRepositoryException('Failed to boost marketplace video: $e');
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
      debugPrint('☁️ Uploading file to R2: $reference');

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
        debugPrint('✅ File uploaded to R2: $r2Url');
        return r2Url;
      } else {
        throw MarketplaceRepositoryException('Failed to upload file to R2: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ R2 upload failed: $e');
      throw MarketplaceRepositoryException('Failed to upload file to R2: $e');
    }
  }

  // 🆕 NEW: Upload multiple files (for marketplace comment images)
  @override
  Future<List<String>> storeFilesToStorage({
    required List<File> files,
    required String referencePrefix,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('☁️ Uploading ${files.length} files to R2...');

      final List<String> uploadedUrls = [];

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final reference = '$referencePrefix/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        debugPrint('📤 Uploading file ${i + 1}/${files.length}: $reference');

        final url = await storeFileToStorage(
          file: file,
          reference: reference,
          onProgress: onProgress,
        );

        uploadedUrls.add(url);

        // Update overall progress
        if (onProgress != null) {
          final progress = (i + 1) / files.length;
          onProgress(progress);
        }
      }

      debugPrint('✅ All ${files.length} files uploaded successfully');
      return uploadedUrls;
    } catch (e) {
      debugPrint('❌ Multiple files upload failed: $e');
      throw MarketplaceRepositoryException('Failed to upload files to R2: $e');
    }
  }

  // Helper method to determine file type from reference
  String _getFileTypeFromReference(String reference) {
    if (reference.contains('profile') || reference.contains('userImages')) return 'profile';
    if (reference.contains('banner') || reference.contains('cover')) return 'banner';
    if (reference.contains('thumbnail')) return 'thumbnail';
    if (reference.contains('video')) return 'video';
    if (reference.contains('comment')) return 'comment';
    return 'profile';
  }
}

// ===============================
// EXCEPTION CLASSES
// ===============================

class MarketplaceRepositoryException implements Exception {
  final String message;
  const MarketplaceRepositoryException(this.message);

  @override
  String toString() => 'MarketplaceRepositoryException: $message';
}

class NotFoundException extends MarketplaceRepositoryException {
  const NotFoundException(super.message);
}
