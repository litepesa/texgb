// lib/features/dramas/repositories/drama_repository.dart (Fixed)
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/shared/services/http_client.dart';

// Import custom exceptions from drama actions provider
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';

// Abstract repository interface (updated for Go backend)
abstract class DramaRepository {
  // Drama CRUD operations
  Future<List<DramaModel>> getAllDramas({int limit = 20, int offset = 0});
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10});
  Future<List<DramaModel>> getTrendingDramas({int limit = 10});
  Future<List<DramaModel>> getFreeDramas({int limit = 20});
  Future<List<DramaModel>> getPremiumDramas({int limit = 20});
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20});
  Future<DramaModel?> getDramaById(String dramaId);
  
  // ATOMIC DRAMA UNLOCK - Main method
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  });
  
  // Admin drama operations
  Future<String> createDrama(DramaModel drama, {File? bannerImage});
  Future<void> updateDrama(DramaModel drama, {File? bannerImage});
  Future<void> deleteDrama(String dramaId);
  Future<List<DramaModel>> getDramasByAdmin(String adminId);
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured);
  Future<void> toggleDramaActive(String dramaId, bool isActive);
  
  // Episode CRUD operations
  Future<List<EpisodeModel>> getDramaEpisodes(String dramaId);
  Future<EpisodeModel?> getEpisodeById(String episodeId);
  Future<String> addEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile});
  Future<void> updateEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile});
  Future<void> deleteEpisode(String episodeId, String dramaId);
  
  // User interaction operations
  Future<void> incrementDramaViews(String dramaId);
  Future<void> incrementEpisodeViews(String episodeId);
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding);
  
  // File upload operations
  Future<String> uploadBannerImage(File imageFile, String dramaId);
  Future<String> uploadThumbnail(File imageFile, String episodeId);
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress});
}

// HTTP Backend implementation
class HttpDramaRepository implements DramaRepository {
  final HttpClientService _httpClient;

  HttpDramaRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // DRAMA CRUD OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<List<DramaModel>> getAllDramas({int limit = 20, int offset = 0}) async {
    try {
      final queryParams = 'limit=$limit&offset=$offset';
      final response = await _httpClient.get('/dramas?$queryParams');

      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/dramas/featured?limit=$limit');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get featured dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getTrendingDramas({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/dramas/trending?limit=$limit');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get trending dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFreeDramas({int limit = 20}) async {
    try {
      // Filter for non-premium dramas
      final response = await _httpClient.get('/dramas?limit=$limit&premium=false');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get free dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getPremiumDramas({int limit = 20}) async {
    try {
      // Filter for premium dramas
      final response = await _httpClient.get('/dramas?limit=$limit&premium=true');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get premium dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await _httpClient.get('/dramas/search?q=$encodedQuery&limit=$limit');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to search dramas: $e');
    }
  }

  @override
  Future<DramaModel?> getDramaById(String dramaId) async {
    try {
      final response = await _httpClient.get('/dramas/$dramaId');
      
      if (response.statusCode == 200) {
        final dramaData = jsonDecode(response.body) as Map<String, dynamic>;
        return DramaModel.fromMap(dramaData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw DramaRepositoryException('Failed to get drama: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw DramaRepositoryException('Failed to get drama: $e');
    }
  }

  // ===============================
  // ATOMIC DRAMA UNLOCK (HTTP BACKEND)
  // ===============================

  @override
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  }) async {
    try {
      final response = await _httpClient.post('/unlock-drama', body: {
        'dramaId': dramaId,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Unknown error';
        
        // Map backend errors to drama unlock exceptions
        switch (errorMessage) {
          case 'Insufficient coins':
          case 'insufficient_funds':
            throw const InsufficientFundsException();
          case 'Drama already unlocked':
          case 'already_unlocked':
            throw const DramaAlreadyUnlockedException();
          case 'Drama not found':
          case 'drama_not_found':
            throw const DramaNotFoundException();
          case 'User not authenticated':
          case 'user_not_authenticated':
            throw const UserNotAuthenticatedException();
          case 'This drama is free to watch':
          case 'drama_free':
            throw const DramaUnlockException('This drama is free to watch', 'DRAMA_FREE');
          default:
            throw DramaUnlockException('Transaction failed: $errorMessage', 'TRANSACTION_FAILED');
        }
      }
    } catch (e) {
      if (e is DramaUnlockException) rethrow;
      throw DramaUnlockException('Network error: $e', 'NETWORK_ERROR');
    }
  }

  // ===============================
  // ADMIN DRAMA OPERATIONS (HTTP BACKEND) - FIXED
  // ===============================

  @override
  Future<String> createDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      debugPrint('=== CREATING DRAMA ===');
      debugPrint('Initial drama: $drama');
      
      // First upload banner image if provided
      String bannerUrl = '';
      if (bannerImage != null) {
        debugPrint('Uploading banner image...');
        bannerUrl = await uploadBannerImage(bannerImage, '');
        debugPrint('Banner uploaded: $bannerUrl');
      }

      // FIXED: Use toCreateMap() which excludes dramaId completely
      final dramaWithBanner = drama.copyWith(bannerImage: bannerUrl);
      final dramaData = dramaWithBanner.toCreateMap();
      
      debugPrint('Drama data being sent: ${jsonEncode(dramaData)}');
      debugPrint('Endpoint: /admin/dramas');
      
      final response = await _httpClient.post('/admin/dramas', body: dramaData);

      debugPrint('=== RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final dramaId = responseData['dramaId'] as String;
        debugPrint('Drama created successfully with ID: $dramaId');
        return dramaId;
      } else {
        debugPrint('Drama creation failed: ${response.statusCode} - ${response.body}');
        throw DramaRepositoryException('Failed to create drama: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during drama creation: $e');
      throw DramaRepositoryException('Failed to create drama: $e');
    }
  }

  @override
  Future<void> updateDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      // Upload new banner image if provided
      String bannerUrl = drama.bannerImage;
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, drama.dramaId);
      }

      // Update drama with new banner URL - use regular toMap for updates (includes dramaId)
      final dramaData = drama.copyWith(bannerImage: bannerUrl).toMap();
      final response = await _httpClient.put('/admin/dramas/${drama.dramaId}', body: dramaData);

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to update drama: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to update drama: $e');
    }
  }

  @override
  Future<void> deleteDrama(String dramaId) async {
    try {
      final response = await _httpClient.delete('/admin/dramas/$dramaId');

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to delete drama: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to delete drama: $e');
    }
  }

  @override
  Future<List<DramaModel>> getDramasByAdmin(String adminId) async {
    try {
      final response = await _httpClient.get('/admin/dramas');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get admin dramas: $e');
    }
  }

  @override
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured) async {
    try {
      final response = await _httpClient.post('/admin/dramas/$dramaId/featured', body: {
        'isFeatured': isFeatured,
      });

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to toggle featured status: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle featured status: $e');
    }
  }

  @override
  Future<void> toggleDramaActive(String dramaId, bool isActive) async {
    try {
      final response = await _httpClient.post('/admin/dramas/$dramaId/active', body: {
        'isActive': isActive,
      });

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to toggle active status: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle active status: $e');
    }
  }

  // ===============================
  // EPISODE OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String dramaId) async {
    try {
      final response = await _httpClient.get('/dramas/$dramaId/episodes');
      return _handleEpisodeListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get episodes: $e');
    }
  }

  @override
  Future<EpisodeModel?> getEpisodeById(String episodeId) async {
    try {
      final response = await _httpClient.get('/episodes/$episodeId');
      
      if (response.statusCode == 200) {
        final episodeData = jsonDecode(response.body) as Map<String, dynamic>;
        return EpisodeModel.fromMap(episodeData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw DramaRepositoryException('Failed to get episode: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw DramaRepositoryException('Failed to get episode: $e');
    }
  }

  @override
  Future<String> addEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    try {
      // Upload files first if provided
      String thumbnailUrl = episode.thumbnailUrl;
      String videoUrl = episode.videoUrl;

      if (thumbnailImage != null) {
        thumbnailUrl = await uploadThumbnail(thumbnailImage, '');
      }
      if (videoFile != null) {
        videoUrl = await uploadVideo(videoFile, '');
      }

      // Create episode with file URLs
      final episodeData = episode.copyWith(
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
      ).toMap();

      final response = await _httpClient.post('/admin/dramas/${episode.dramaId}/episodes', body: episodeData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['episodeId'] as String;
      } else {
        throw DramaRepositoryException('Failed to add episode: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to add episode: $e');
    }
  }

  @override
  Future<void> updateEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    try {
      // Upload new files if provided
      String thumbnailUrl = episode.thumbnailUrl;
      String videoUrl = episode.videoUrl;

      if (thumbnailImage != null) {
        thumbnailUrl = await uploadThumbnail(thumbnailImage, episode.episodeId);
      }
      if (videoFile != null) {
        videoUrl = await uploadVideo(videoFile, episode.episodeId);
      }

      // Update episode with new file URLs
      final episodeData = episode.copyWith(
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
      ).toMap();

      final response = await _httpClient.put('/admin/episodes/${episode.episodeId}', body: episodeData);

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to update episode: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to update episode: $e');
    }
  }

  @override
  Future<void> deleteEpisode(String episodeId, String dramaId) async {
    try {
      final response = await _httpClient.delete('/admin/episodes/$episodeId');

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to delete episode: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to delete episode: $e');
    }
  }

  // ===============================
  // USER INTERACTION OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<void> incrementDramaViews(String dramaId) async {
    try {
      // Fire and forget - don't throw errors for view counting
      await _httpClient.post('/dramas/$dramaId/views');
    } catch (e) {
      // Silently fail for view counting
      debugPrint('Failed to increment drama views: $e');
    }
  }

  @override
  Future<void> incrementEpisodeViews(String episodeId) async {
    try {
      // Fire and forget - don't throw errors for view counting
      await _httpClient.post('/episodes/$episodeId/views');
    } catch (e) {
      // Silently fail for view counting
      debugPrint('Failed to increment episode views: $e');
    }
  }

  @override
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding) async {
    try {
      // Fire and forget - don't throw errors for favorite counting
      await _httpClient.post('/dramas/$dramaId/favorites', body: {
        'increment': isAdding ? 1 : -1,
      });
    } catch (e) {
      // Silently fail for favorite counting
      debugPrint('Failed to update drama favorites: $e');
    }
  }

  // ===============================
  // FILE UPLOAD OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<String> uploadBannerImage(File imageFile, String dramaId) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'banner',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['url'] as String;
      } else {
        throw DramaRepositoryException('Failed to upload banner: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to upload banner: $e');
    }
  }

  @override
  Future<String> uploadThumbnail(File imageFile, String episodeId) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'thumbnail',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['url'] as String;
      } else {
        throw DramaRepositoryException('Failed to upload thumbnail: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to upload thumbnail: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress}) async {
    try {
      // Note: Progress callback not implemented in basic HTTP client
      // Could be enhanced later if needed
      final response = await _httpClient.uploadFile(
        '/upload',
        videoFile,
        'file',
        additionalFields: {
          'type': 'video',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['url'] as String;
      } else {
        throw DramaRepositoryException('Failed to upload video: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to upload video: $e');
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  List<DramaModel> _handleDramaListResponse(http.Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DramaModel.fromMap(item as Map<String, dynamic>)).toList();
    } else {
      throw DramaRepositoryException('Failed to fetch dramas: ${response.body}');
    }
  }

  List<EpisodeModel> _handleEpisodeListResponse(http.Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => EpisodeModel.fromMap(item as Map<String, dynamic>)).toList();
    } else {
      throw DramaRepositoryException('Failed to fetch episodes: ${response.body}');
    }
  }
}

// Exception class for drama repository errors (unchanged)
class DramaRepositoryException implements Exception {
  final String message;
  const DramaRepositoryException(this.message);
  
  @override
  String toString() => 'DramaRepositoryException: $message';
}