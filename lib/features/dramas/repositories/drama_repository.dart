// lib/features/dramas/repositories/drama_repository.dart - SIMPLIFIED UNIFIED WITH EPISODE ADDITION
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';

// Simplified repository interface
abstract class DramaRepository {
  // Core drama operations (simplified)
  Future<List<DramaModel>> getAllDramas({int limit = 20, int offset = 0});
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10});
  Future<List<DramaModel>> getTrendingDramas({int limit = 10});
  Future<List<DramaModel>> getFreeDramas({int limit = 20});
  Future<List<DramaModel>> getPremiumDramas({int limit = 20});
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20});
  Future<DramaModel?> getDramaById(String dramaId);
  
  // UNIFIED CREATION - Create drama with all episodes at once
  Future<String> createDramaWithEpisodes(DramaModel drama);
  
  // NEW: Add episodes to existing drama
  Future<void> addEpisodesToDrama(String dramaId, List<String> newEpisodeUrls);
  
  // Drama unlock (unchanged)
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  });
  
  // Admin operations (simplified)
  Future<void> updateDrama(DramaModel drama, {File? bannerImage});
  Future<void> deleteDrama(String dramaId);
  Future<List<DramaModel>> getDramasByAdmin(String adminId);
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured);
  Future<void> toggleDramaActive(String dramaId, bool isActive);
  
  // User interactions (simplified - drama level only)
  Future<void> incrementDramaViews(String dramaId);
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding);
  
  // File upload helpers
  Future<String> uploadBannerImage(File imageFile, String dramaId);
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress});
}

// HTTP implementation - simplified with episode addition
class HttpDramaRepository implements DramaRepository {
  final HttpClientService _httpClient;

  HttpDramaRepository({HttpClientService? httpClient}) 
      : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // CORE DRAMA OPERATIONS (unchanged but simplified)
  // ===============================

  @override
  Future<List<DramaModel>> getAllDramas({int limit = 20, int offset = 0}) async {
    try {
      final response = await _httpClient.get('/dramas?limit=$limit&offset=$offset');
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
      final response = await _httpClient.get('/dramas?limit=$limit&premium=false');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get free dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getPremiumDramas({int limit = 20}) async {
    try {
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
  // UNIFIED DRAMA CREATION WITH EPISODES
  // ===============================

  @override
  Future<String> createDramaWithEpisodes(DramaModel drama) async {
    try {
      debugPrint('=== CREATING DRAMA WITH ${drama.episodeVideos.length} EPISODES ===');
      
      // Validate drama has episodes
      if (drama.episodeVideos.isEmpty) {
        throw DramaRepositoryException('Drama must have at least one episode');
      }
      
      if (drama.episodeVideos.length > 100) {
        throw DramaRepositoryException('Drama cannot have more than 100 episodes');
      }

      // Create the drama with all episode URLs in one request
      final dramaData = drama.toCreateMap();
      
      debugPrint('Creating drama with data: ${jsonEncode(dramaData)}');
      
      final response = await _httpClient.post('/admin/dramas/create-with-episodes', body: dramaData);

      debugPrint('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final dramaId = responseData['dramaId'] as String;
        debugPrint('Drama created successfully with ID: $dramaId');
        return dramaId;
      } else {
        throw DramaRepositoryException('Failed to create drama: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during drama creation: $e');
      throw DramaRepositoryException('Failed to create drama: $e');
    }
  }

  // ===============================
  // NEW: ADD EPISODES TO EXISTING DRAMA
  // ===============================

  @override
  Future<void> addEpisodesToDrama(String dramaId, List<String> newEpisodeUrls) async {
    try {
      debugPrint('=== ADDING ${newEpisodeUrls.length} EPISODES TO DRAMA $dramaId ===');
      
      if (newEpisodeUrls.isEmpty) {
        throw DramaRepositoryException('No episodes provided to add');
      }
      
      if (newEpisodeUrls.length > 100) {
        throw DramaRepositoryException('Cannot add more than 100 episodes at once');
      }

      final requestData = {
        'dramaId': dramaId,
        'newEpisodeUrls': newEpisodeUrls,
        'episodeCount': newEpisodeUrls.length,
      };
      
      debugPrint('Adding episodes with data: ${jsonEncode(requestData)}');
      
      final response = await _httpClient.post('/admin/dramas/$dramaId/add-episodes', body: requestData);

      debugPrint('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Episodes added successfully: ${responseData['message'] ?? 'Success'}');
      } else {
        throw DramaRepositoryException('Failed to add episodes: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during episode addition: $e');
      throw DramaRepositoryException('Failed to add episodes: $e');
    }
  }

  // ===============================
  // DRAMA UNLOCK (unchanged)
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
  // ADMIN OPERATIONS (simplified)
  // ===============================

  @override
  Future<void> updateDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      String bannerUrl = drama.bannerImage;
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, drama.dramaId);
      }

      final dramaData = drama.copyWith(bannerImage: bannerUrl).toMap();
      final response = await _httpClient.put('/admin/dramas/${drama.dramaId}', body: dramaData);

      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to update drama: ${response.body}');
      }

      debugPrint('Drama updated successfully: ${drama.dramaId}');
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
      debugPrint('Drama deleted successfully: $dramaId');
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
        throw DramaRepositoryException('Failed to toggle featured: ${response.body}');
      }
      debugPrint('Drama featured status updated: $dramaId -> $isFeatured');
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle featured: $e');
    }
  }

  @override
  Future<void> toggleDramaActive(String dramaId, bool isActive) async {
    try {
      final response = await _httpClient.post('/admin/dramas/$dramaId/active', body: {
        'isActive': isActive,
      });
      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to toggle active: ${response.body}');
      }
      debugPrint('Drama active status updated: $dramaId -> $isActive');
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle active: $e');
    }
  }

  // ===============================
  // USER INTERACTIONS (simplified)
  // ===============================

  @override
  Future<void> incrementDramaViews(String dramaId) async {
    try {
      await _httpClient.post('/dramas/$dramaId/views');
      debugPrint('Drama view count incremented: $dramaId');
    } catch (e) {
      debugPrint('Failed to increment drama views: $e');
    }
  }

  @override
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding) async {
    try {
      await _httpClient.post('/dramas/$dramaId/favorites', body: {
        'increment': isAdding ? 1 : -1,
      });
      debugPrint('Drama favorite count updated: $dramaId -> ${isAdding ? 'added' : 'removed'}');
    } catch (e) {
      debugPrint('Failed to update drama favorites: $e');
    }
  }

  // ===============================
  // FILE UPLOAD OPERATIONS
  // ===============================

  @override
  Future<String> uploadBannerImage(File imageFile, String dramaId) async {
    try {
      debugPrint('Uploading banner image for drama: $dramaId');
      
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'banner',
          'dramaId': dramaId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = responseData['url'] as String;
        debugPrint('Banner image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        throw DramaRepositoryException('Failed to upload banner: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to upload banner: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress}) async {
    try {
      debugPrint('Uploading video for episode: $episodeId');
      
      // Get file size for progress calculation
      final fileSize = await videoFile.length();
      debugPrint('Video file size: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB');
      
      final response = await _httpClient.uploadFile(
        '/upload',
        videoFile,
        'file',
        additionalFields: {
          'type': 'video',
          'episodeId': episodeId,
        },
        //onProgress: onProgress,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoUrl = responseData['url'] as String;
        debugPrint('Video uploaded successfully: $videoUrl');
        return videoUrl;
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
      try {
        final dynamic responseData = jsonDecode(response.body);
        
        if (responseData == null) return [];
        
        if (responseData is List) {
          return responseData.map((item) => DramaModel.fromMap(item as Map<String, dynamic>)).toList();
        }
        
        if (responseData is Map<String, dynamic>) {
          final dramas = responseData['dramas'] ?? responseData['data'] ?? [];
          if (dramas is List) {
            return dramas.map((item) => DramaModel.fromMap(item as Map<String, dynamic>)).toList();
          }
        }
        
        return [];
        
      } catch (e) {
        debugPrint('Failed to parse dramas response: $e');
        return [];
      }
    } else {
      throw DramaRepositoryException('Failed to fetch dramas: ${response.body}');
    }
  }
}

// REMOVED: All episode-specific repository methods
// REMOVED: Complex episode CRUD operations
// REMOVED: Episode file upload methods
// REMOVED: Episode view counting (now drama-level only)
// ADDED: addEpisodesToDrama method for extending existing dramas

// Exception classes (unchanged)
class DramaRepositoryException implements Exception {
  final String message;
  const DramaRepositoryException(this.message);
  
  @override
  String toString() => 'DramaRepositoryException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
  
  @override
  String toString() => 'NotFoundException: $message';
}