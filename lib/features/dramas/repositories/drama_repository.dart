// lib/features/dramas/repositories/drama_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/shared/services/http_client.dart';

// Import custom exceptions from drama actions provider
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';

// Abstract repository interface (unchanged)
abstract class DramaRepository {
  // Drama CRUD operations
  Future<List<DramaModel>> getAllDramas({int limit = 20, DocumentSnapshot? lastDocument});
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
  
  // Streams for real-time updates (deprecated for HTTP)
  Stream<List<DramaModel>> featuredDramasStream();
  Stream<List<DramaModel>> trendingDramasStream();
  Stream<DramaModel> dramaStream(String dramaId);
  Stream<List<EpisodeModel>> dramaEpisodesStream(String dramaId);
  
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
  Future<List<DramaModel>> getAllDramas({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      final queryParams = 'limit=$limit';
      final response = await _httpClient.get('/dramas?$queryParams');

      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/dramas/featured?limit=$limit');
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get featured dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getTrendingDramas({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/dramas/trending?limit=$limit');
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get trending dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFreeDramas({int limit = 20}) async {
    try {
      final response = await _httpClient.get('/dramas/free?limit=$limit');
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get free dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getPremiumDramas({int limit = 20}) async {
    try {
      final response = await _httpClient.get('/dramas/premium?limit=$limit');
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get premium dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await _httpClient.get('/dramas/search?q=$encodedQuery&limit=$limit');
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
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
      final response = await _httpClient.post('/dramas/$dramaId/unlock', body: {
        'userId': userId,
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
  // ADMIN DRAMA OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<String> createDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      // First upload banner image if provided
      String bannerUrl = '';
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, '');
      }

      // Create drama with banner URL
      final dramaData = drama.copyWith(bannerImage: bannerUrl).toMap();
      final response = await _httpClient.post('/admin/dramas', body: dramaData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['dramaId'] as String;
      } else {
        throw DramaRepositoryException('Failed to create drama: ${response.body}');
      }
    } catch (e) {
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

      // Update drama with new banner URL
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
      return _httpClient.handleListResponse(response, (data) => DramaModel.fromMap(data));
    } catch (e) {
      throw DramaRepositoryException('Failed to get admin dramas: $e');
    }
  }

  @override
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured) async {
    try {
      final response = await _httpClient.post('/admin/dramas/$dramaId/toggle-featured', body: {
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
      final response = await _httpClient.post('/admin/dramas/$dramaId/toggle-active', body: {
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
      return _httpClient.handleListResponse(response, (data) => EpisodeModel.fromMap(data));
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
      String thumbnailUrl = '';
      String videoUrl = '';

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
      print('Failed to increment drama views: $e');
    }
  }

  @override
  Future<void> incrementEpisodeViews(String episodeId) async {
    try {
      // Fire and forget - don't throw errors for view counting
      await _httpClient.post('/episodes/$episodeId/views');
    } catch (e) {
      // Silently fail for view counting
      print('Failed to increment episode views: $e');
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
      print('Failed to update drama favorites: $e');
    }
  }

  // ===============================
  // DEPRECATED STREAM METHODS
  // ===============================

  @override
  Stream<List<DramaModel>> featuredDramasStream() {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  @override
  Stream<List<DramaModel>> trendingDramasStream() {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  @override
  Stream<DramaModel> dramaStream(String dramaId) {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  @override
  Stream<List<EpisodeModel>> dramaEpisodesStream(String dramaId) {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
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
}

// Firebase implementation (kept for backward compatibility)
class FirebaseDramaRepository implements DramaRepository {
  @override
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  }) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getAllDramas({int limit = 20, DocumentSnapshot? lastDocument}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getTrendingDramas({int limit = 10}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getFreeDramas({int limit = 20}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getPremiumDramas({int limit = 20}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<DramaModel?> getDramaById(String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<String> createDrama(DramaModel drama, {File? bannerImage}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> updateDrama(DramaModel drama, {File? bannerImage}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> deleteDrama(String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<DramaModel>> getDramasByAdmin(String adminId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> toggleDramaActive(String dramaId, bool isActive) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<EpisodeModel?> getEpisodeById(String episodeId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<String> addEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> updateEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> deleteEpisode(String episodeId, String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> incrementDramaViews(String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> incrementEpisodeViews(String episodeId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Stream<List<DramaModel>> featuredDramasStream() {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Stream<List<DramaModel>> trendingDramasStream() {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Stream<DramaModel> dramaStream(String dramaId) {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Stream<List<EpisodeModel>> dramaEpisodesStream(String dramaId) {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<String> uploadBannerImage(File imageFile, String dramaId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<String> uploadThumbnail(File imageFile, String episodeId) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }

  @override
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress}) async {
    throw UnimplementedError('Use HttpDramaRepository for new backend');
  }
}

// Exception class for drama repository errors (unchanged)
class DramaRepositoryException implements Exception {
  final String message;
  const DramaRepositoryException(this.message);
  
  @override
  String toString() => 'DramaRepositoryException: $message';
}