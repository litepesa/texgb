// lib/features/dramas/repositories/drama_repository.dart - FIXED ENDPOINTS VERSION
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:textgb/features/dramas/models/drama_model.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';

// Updated repository interface with progress callback
abstract class DramaRepository {
  // Core drama operations
  Future<List<DramaModel>> getAllDramas({int limit = 20, int offset = 0});
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10});
  Future<List<DramaModel>> getTrendingDramas({int limit = 10});
  Future<List<DramaModel>> getFreeDramas({int limit = 20});
  Future<List<DramaModel>> getPremiumDramas({int limit = 20});
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20});
  Future<DramaModel?> getDramaById(String dramaId);
  
  // UNIFIED CREATION - Create drama with all episodes at once
  Future<String> createDramaWithEpisodes(DramaModel drama);
  
  // Drama unlock
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  });
  
  // Verified user operations (formerly admin operations)
  Future<void> updateDrama(DramaModel drama, {File? bannerImage});
  Future<void> deleteDrama(String dramaId);
  Future<List<DramaModel>> getUserDramas();
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured);
  Future<void> toggleDramaActive(String dramaId, bool isActive);
  
  // User interactions
  Future<void> incrementDramaViews(String dramaId);
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding);
  
  // File upload helpers with progress tracking
  Future<String> uploadBannerImage(File imageFile, String dramaId);
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress});
}

// HTTP implementation with improved upload handling and fixed endpoints
class HttpDramaRepository implements DramaRepository {
  final HttpClientService _httpClient;

  HttpDramaRepository({HttpClientService? httpClient}) 
      : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // CORE DRAMA OPERATIONS (unchanged)
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
  // UNIFIED DRAMA CREATION WITH EPISODES - FIXED ENDPOINT
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
      
      // FIXED: Use verified user endpoint instead of admin endpoint
      final response = await _httpClient.post('/dramas', body: dramaData);

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
  // DRAMA UNLOCK - FIXED ENDPOINT
  // ===============================

  @override
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  }) async {
    try {
      // FIXED: Use correct unlock endpoint
      final response = await _httpClient.post('/dramas/unlock', body: {
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
  // VERIFIED USER OPERATIONS - FIXED ENDPOINTS
  // ===============================

  @override
  Future<void> updateDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      String bannerUrl = drama.bannerImage;
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, drama.dramaId);
      }

      final dramaData = drama.copyWith(bannerImage: bannerUrl).toMap();
      
      // FIXED: Use verified user endpoint instead of admin endpoint
      final response = await _httpClient.put('/dramas/${drama.dramaId}', body: dramaData);

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
      // FIXED: Use verified user endpoint instead of admin endpoint
      final response = await _httpClient.delete('/dramas/$dramaId');
      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to delete drama: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to delete drama: $e');
    }
  }

  @override
  Future<List<DramaModel>> getUserDramas() async {
    try {
      // FIXED: Use verified user endpoint to get user's own dramas
      final response = await _httpClient.get('/my/dramas');
      return _handleDramaListResponse(response);
    } catch (e) {
      throw DramaRepositoryException('Failed to get user dramas: $e');
    }
  }

  @override
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured) async {
    try {
      // FIXED: Use verified user endpoint instead of admin endpoint
      final response = await _httpClient.post('/dramas/$dramaId/featured', body: {
        'isFeatured': isFeatured,
      });
      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to toggle featured: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle featured: $e');
    }
  }

  @override
  Future<void> toggleDramaActive(String dramaId, bool isActive) async {
    try {
      // FIXED: Use verified user endpoint instead of admin endpoint
      final response = await _httpClient.post('/dramas/$dramaId/active', body: {
        'isActive': isActive,
      });
      if (response.statusCode != 200) {
        throw DramaRepositoryException('Failed to toggle active: ${response.body}');
      }
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle active: $e');
    }
  }

  // ===============================
  // USER INTERACTIONS - FIXED ENDPOINTS
  // ===============================

  @override
  Future<void> incrementDramaViews(String dramaId) async {
    try {
      await _httpClient.post('/dramas/$dramaId/views');
    } catch (e) {
      debugPrint('Failed to increment drama views: $e');
    }
  }

  @override
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding) async {
    try {
      // FIXED: Use correct endpoint for drama favorites
      await _httpClient.post('/dramas/$dramaId/favorite', body: {
        'isAdding': isAdding,
      });
    } catch (e) {
      debugPrint('Failed to update drama favorites: $e');
    }
  }

  // ===============================
  // IMPROVED FILE UPLOAD OPERATIONS WITH PROGRESS TRACKING
  // ===============================

  @override
  Future<String> uploadBannerImage(File imageFile, String dramaId) async {
    try {
      debugPrint('Uploading banner image: ${imageFile.path}');
      
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {'type': 'banner'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final url = responseData['url'] as String;
        debugPrint('Banner uploaded successfully: $url');
        return url;
      } else {
        throw DramaRepositoryException('Failed to upload banner: ${response.body}');
      }
    } catch (e) {
      debugPrint('Banner upload failed: $e');
      throw DramaRepositoryException('Failed to upload banner: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress}) async {
    try {
      debugPrint('Uploading video: ${videoFile.path} for episode: $episodeId');
      
      // Get file size for progress tracking
      final fileSizeInBytes = await videoFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      debugPrint('Video file size: ${fileSizeInMB.toStringAsFixed(2)}MB');
      
      // Simulate progress updates during upload (since http package doesn't provide real progress)
      // In a real implementation, you might use a different HTTP client like dio for progress tracking
      if (onProgress != null) {
        _simulateUploadProgress(onProgress, fileSizeInMB);
      }
      
      final response = await _httpClient.uploadFile(
        '/upload',
        videoFile,
        'file',
        additionalFields: {'type': 'video'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final url = responseData['url'] as String;
        debugPrint('Video uploaded successfully: $url');
        
        // Complete progress
        if (onProgress != null) {
          onProgress(100.0);
        }
        
        return url;
      } else {
        throw DramaRepositoryException('Failed to upload video: ${response.body}');
      }
    } catch (e) {
      debugPrint('Video upload failed: $e');
      throw DramaRepositoryException('Failed to upload video: $e');
    }
  }

  // Simulate upload progress based on file size
  // In a real implementation, you'd use a proper HTTP client with progress callbacks
  void _simulateUploadProgress(Function(double) onProgress, double fileSizeInMB) {
    // Estimate upload time based on file size (assuming 10MB/s upload speed)
    final estimatedSeconds = (fileSizeInMB / 10).clamp(1, 30);
    final totalSteps = (estimatedSeconds * 2).round(); // Update every 0.5 seconds
    
    for (int i = 1; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 500 * i), () {
        final progress = (i / totalSteps * 95).clamp(0.0, 95.0); // Stop at 95%, let actual completion set to 100%
        onProgress(progress);
      });
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

// Enhanced HTTP Client Service for better upload handling
extension UploadExtensions on HttpClientService {
  // Enhanced upload method with better error handling and timeout
  Future<http.Response> uploadFileWithRetry(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? additionalFields,
    int maxRetries = 3,
    Duration timeout = const Duration(minutes: 10), // Longer timeout for large files
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        debugPrint('Upload attempt ${attempt + 1} of $maxRetries for file: ${file.path}');
        
        final response = await uploadFile(
          endpoint,
          file,
          fieldName,
          additionalFields: additionalFields,
        ).timeout(timeout);
        
        // If successful, return immediately
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('Upload successful on attempt ${attempt + 1}');
          return response;
        }
        
        // If it's a client error (4xx), don't retry
        if (response.statusCode >= 400 && response.statusCode < 500) {
          debugPrint('Client error ${response.statusCode}, not retrying');
          return response;
        }
        
        // Server error (5xx), retry
        debugPrint('Server error ${response.statusCode}, retrying...');
        attempt++;
        
        if (attempt < maxRetries) {
          // Exponential backoff: 2s, 4s, 8s...
          final delay = Duration(seconds: 2 * attempt);
          debugPrint('Waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
        }
        
      } catch (e) {
        attempt++;
        debugPrint('Upload attempt ${attempt} failed: $e');
        
        if (attempt >= maxRetries) {
          debugPrint('All upload attempts failed');
          rethrow;
        }
        
        // Wait before retry
        final delay = Duration(seconds: 2 * attempt);
        debugPrint('Waiting ${delay.inSeconds}s before retry...');
        await Future.delayed(delay);
      }
    }
    
    throw HttpException('Upload failed after $maxRetries attempts');
  }
}

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