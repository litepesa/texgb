// lib/features/properties/repositories/property_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:textgb/features/properties/models/property_listing_model.dart';
import 'package:textgb/features/properties/models/property_engagement_models.dart';
import 'package:textgb/shared/services/http_client.dart';

// Abstract property repository interface
abstract class PropertyRepository {
  // Property CRUD operations (Host only)
  Future<PropertyListingModel> createPropertyListing({
    required PropertyListingModel property,
    required File videoFile,
    List<File>? imageFiles,
  });
  Future<PropertyListingModel> updatePropertyListing({
    required PropertyListingModel property,
    File? newVideoFile,
    List<File>? newImageFiles,
  });
  Future<void> deletePropertyListing(String propertyId, String hostId);
  
  // Property retrieval operations
  Future<List<PropertyListingModel>> getActiveProperties({
    int limit = 20,
    String? lastPropertyId,
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  });
  Future<List<PropertyListingModel>> getHostProperties(String hostId);
  Future<PropertyListingModel?> getPropertyById(String propertyId);
  Future<List<PropertyListingModel>> searchProperties({
    required String query,
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  });
  
  // Engagement operations (independent system)
  Future<void> likeProperty(String propertyId, String userId, String userName, String userImage);
  Future<void> unlikeProperty(String propertyId, String userId);
  Future<List<PropertyLikeModel>> getPropertyLikes(String propertyId, {int limit = 50});
  Future<bool> isPropertyLiked(String propertyId, String userId);
  
  // Comment operations (independent system)
  Future<PropertyCommentModel> addPropertyComment({
    required String propertyId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    String? parentCommentId,
    String? repliedToAuthorName,
  });
  Future<List<PropertyCommentModel>> getPropertyComments(String propertyId, {int limit = 50});
  Future<void> deletePropertyComment(String commentId, String userId);
  Future<void> likePropertyComment(String commentId, String userId);
  Future<void> unlikePropertyComment(String commentId, String userId);
  
  // View tracking
  Future<void> recordPropertyView({
    required String propertyId,
    String? userId,
    String? userName,
    required String ipAddress,
    int durationWatchedSeconds = 0,
    required String userAgent,
    String? referrer,
  });
  Future<List<PropertyViewModel>> getPropertyViews(String propertyId, {int limit = 100});
  
  // Inquiry tracking
  Future<PropertyInquiryModel> recordPropertyInquiry({
    required String propertyId,
    required String inquirerId,
    required String inquirerName,
    required String inquirerImage,
    required String inquirerPhoneNumber,
    String? message,
    bool wasRedirectedToWhatsApp = true,
  });
  Future<List<PropertyInquiryModel>> getHostInquiries(String hostId, {int limit = 50});
  Future<List<PropertyInquiryModel>> getPropertyInquiries(String propertyId, {int limit = 50});
  
  // File operations (R2 storage in separate folders)
  Future<String> uploadPropertyVideo(File videoFile, String propertyId);
  Future<List<String>> uploadPropertyImages(List<File> imageFiles, String propertyId);
  Future<String> uploadPropertyThumbnail(File thumbnailFile, String propertyId);
  
  // Analytics for hosts
  Future<Map<String, dynamic>> getPropertyAnalytics(String propertyId);
  Future<Map<String, dynamic>> getHostAnalytics(String hostId);
  
  // Additional utility methods
  Future<List<PropertyListingModel>> getTrendingProperties({int limit = 10});
  Future<List<PropertyListingModel>> getFeaturedProperties({int limit = 5});
  Future<List<PropertyListingModel>> getPropertiesByCity(String city, {int limit = 20});
  Future<List<String>> getAvailableCities();
  Future<void> submitPropertyForReview(String propertyId, String hostId);
  Future<bool> isPropertyTitleAvailable(String title, String hostId, {String? excludePropertyId});
  Future<Map<String, dynamic>> getPropertyStats(String propertyId);
}

// HTTP Backend implementation for properties
class HttpPropertyRepository implements PropertyRepository {
  final HttpClientService _httpClient;

  HttpPropertyRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // PROPERTY CRUD OPERATIONS
  // ===============================

  @override
  Future<PropertyListingModel> createPropertyListing({
    required PropertyListingModel property,
    required File videoFile,
    List<File>? imageFiles,
  }) async {
    try {
      // First, upload the video file to R2
      final videoUrl = await uploadPropertyVideo(videoFile, property.id);
      
      // Upload thumbnail (extracted from video or provided)
      // For now, we'll use the first frame of video as thumbnail
      final thumbnailUrl = videoUrl; // Backend will generate thumbnail
      
      // Upload additional images if provided
      final imageUrls = imageFiles != null && imageFiles.isNotEmpty
          ? await uploadPropertyImages(imageFiles, property.id)
          : <String>[];
      
      // Update property with uploaded URLs
      final updatedProperty = property.copyWith(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create property in backend
      final response = await _httpClient.post('/properties', body: updatedProperty.toMap());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final propertyData = responseData.containsKey('property') ? responseData['property'] : responseData;
        return PropertyListingModel.fromMap(propertyData);
      } else {
        throw PropertyRepositoryException('Failed to create property listing: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to create property listing: $e');
    }
  }

  @override
  Future<PropertyListingModel> updatePropertyListing({
    required PropertyListingModel property,
    File? newVideoFile,
    List<File>? newImageFiles,
  }) async {
    try {
      PropertyListingModel updatedProperty = property;
      
      // Upload new video if provided
      if (newVideoFile != null) {
        final videoUrl = await uploadPropertyVideo(newVideoFile, property.id);
        updatedProperty = updatedProperty.copyWith(
          videoUrl: videoUrl,
          thumbnailUrl: videoUrl, // Backend will generate new thumbnail
        );
      }
      
      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final imageUrls = await uploadPropertyImages(newImageFiles, property.id);
        updatedProperty = updatedProperty.copyWith(imageUrls: imageUrls);
      }
      
      // Update timestamps
      updatedProperty = updatedProperty.copyWith(updatedAt: DateTime.now());
      
      // Update property in backend
      final response = await _httpClient.put('/properties/${property.id}', body: updatedProperty.toMap());
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final propertyData = responseData.containsKey('property') ? responseData['property'] : responseData;
        return PropertyListingModel.fromMap(propertyData);
      } else {
        throw PropertyRepositoryException('Failed to update property listing: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to update property listing: $e');
    }
  }

  @override
  Future<void> deletePropertyListing(String propertyId, String hostId) async {
    try {
      final response = await _httpClient.delete('/properties/$propertyId?hostId=$hostId');
      
      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to delete property listing: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to delete property listing: $e');
    }
  }

  // ===============================
  // PROPERTY RETRIEVAL OPERATIONS
  // ===============================

  @override
  Future<List<PropertyListingModel>> getActiveProperties({
    int limit = 20,
    String? lastPropertyId,
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) async {
    try {
      String endpoint = '/properties/active?limit=$limit';
      
      if (lastPropertyId != null) endpoint += '&after=$lastPropertyId';
      if (city != null) endpoint += '&city=${Uri.encodeComponent(city)}';
      if (maxRate != null) endpoint += '&maxRate=$maxRate';
      if (minRate != null) endpoint += '&minRate=$minRate';
      if (propertyType != null) endpoint += '&propertyType=${propertyType.value}';
      
      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get active properties: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get active properties: $e');
    }
  }

  @override
  Future<List<PropertyListingModel>> getHostProperties(String hostId) async {
    try {
      final response = await _httpClient.get('/properties/host/$hostId');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get host properties: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get host properties: $e');
    }
  }

  @override
  Future<PropertyListingModel?> getPropertyById(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId');
      
      if (response.statusCode == 200) {
        final propertyData = jsonDecode(response.body) as Map<String, dynamic>;
        return PropertyListingModel.fromMap(propertyData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw PropertyRepositoryException('Failed to get property by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw PropertyRepositoryException('Failed to get property by ID: $e');
    }
  }

  @override
  Future<List<PropertyListingModel>> searchProperties({
    required String query,
    String? city,
    double? maxRate,
    double? minRate,
    PropertyType? propertyType,
  }) async {
    try {
      String endpoint = '/properties/search?q=${Uri.encodeComponent(query)}';
      
      if (city != null) endpoint += '&city=${Uri.encodeComponent(city)}';
      if (maxRate != null) endpoint += '&maxRate=$maxRate';
      if (minRate != null) endpoint += '&minRate=$minRate';
      if (propertyType != null) endpoint += '&propertyType=${propertyType.value}';
      
      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to search properties: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to search properties: $e');
    }
  }

  // ===============================
  // ENGAGEMENT OPERATIONS
  // ===============================

  @override
  Future<void> likeProperty(String propertyId, String userId, String userName, String userImage) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/like', body: {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PropertyRepositoryException('Failed to like property: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to like property: $e');
    }
  }

  @override
  Future<void> unlikeProperty(String propertyId, String userId) async {
    try {
      final response = await _httpClient.delete('/properties/$propertyId/like?userId=$userId');

      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to unlike property: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to unlike property: $e');
    }
  }

  @override
  Future<List<PropertyLikeModel>> getPropertyLikes(String propertyId, {int limit = 50}) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/likes?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> likesData = responseData['likes'] ?? [];
        return likesData
            .map((likeData) => PropertyLikeModel.fromMap(likeData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get property likes: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property likes: $e');
    }
  }

  @override
  Future<bool> isPropertyLiked(String propertyId, String userId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/liked?userId=$userId');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['isLiked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // COMMENT OPERATIONS
  // ===============================

  @override
  Future<PropertyCommentModel> addPropertyComment({
    required String propertyId,
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    String? parentCommentId,
    String? repliedToAuthorName,
  }) async {
    try {
      final commentData = {
        'propertyId': propertyId,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'content': content.trim(),
        'isReply': parentCommentId != null,
        'parentCommentId': parentCommentId,
        'repliedToAuthorName': repliedToAuthorName,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final response = await _httpClient.post('/properties/$propertyId/comments', body: commentData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final commentMap = responseData.containsKey('comment') ? responseData['comment'] : responseData;
        return PropertyCommentModel.fromMap(commentMap);
      } else {
        throw PropertyRepositoryException('Failed to add property comment: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to add property comment: $e');
    }
  }

  @override
  Future<List<PropertyCommentModel>> getPropertyComments(String propertyId, {int limit = 50}) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/comments?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> commentsData = responseData['comments'] ?? [];
        return commentsData
            .map((commentData) => PropertyCommentModel.fromMap(commentData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get property comments: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property comments: $e');
    }
  }

  @override
  Future<void> deletePropertyComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.delete('/properties/comments/$commentId?userId=$userId');
      
      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to delete property comment: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to delete property comment: $e');
    }
  }

  @override
  Future<void> likePropertyComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.post('/properties/comments/$commentId/like', body: {
        'userId': userId,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PropertyRepositoryException('Failed to like property comment: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to like property comment: $e');
    }
  }

  @override
  Future<void> unlikePropertyComment(String commentId, String userId) async {
    try {
      final response = await _httpClient.delete('/properties/comments/$commentId/like?userId=$userId');

      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to unlike property comment: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to unlike property comment: $e');
    }
  }

  // ===============================
  // VIEW TRACKING
  // ===============================

  @override
  Future<void> recordPropertyView({
    required String propertyId,
    String? userId,
    String? userName,
    required String ipAddress,
    int durationWatchedSeconds = 0,
    required String userAgent,
    String? referrer,
  }) async {
    try {
      final viewData = {
        'propertyId': propertyId,
        'userId': userId,
        'userName': userName,
        'ipAddress': ipAddress,
        'durationWatchedSeconds': durationWatchedSeconds,
        'userAgent': userAgent,
        'referrer': referrer,
        'viewedAt': DateTime.now().toIso8601String(),
      };

      final response = await _httpClient.post('/properties/$propertyId/views', body: viewData);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        // Non-critical operation, log but don't throw
        print('Warning: Failed to record property view: ${response.body}');
      }
    } catch (e) {
      // Non-critical operation, log but don't throw
      print('Warning: Failed to record property view: $e');
    }
  }

  @override
  Future<List<PropertyViewModel>> getPropertyViews(String propertyId, {int limit = 100}) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/views?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> viewsData = responseData['views'] ?? [];
        return viewsData
            .map((viewData) => PropertyViewModel.fromMap(viewData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get property views: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property views: $e');
    }
  }

  // ===============================
  // INQUIRY TRACKING
  // ===============================

  @override
  Future<PropertyInquiryModel> recordPropertyInquiry({
    required String propertyId,
    required String inquirerId,
    required String inquirerName,
    required String inquirerImage,
    required String inquirerPhoneNumber,
    String? message,
    bool wasRedirectedToWhatsApp = true,
  }) async {
    try {
      // Get property details for the inquiry
      final property = await getPropertyById(propertyId);
      if (property == null) {
        throw PropertyRepositoryException('Property not found');
      }

      final inquiryData = {
        'propertyId': propertyId,
        'propertyTitle': property.title,
        'hostId': property.hostId,
        'inquirerId': inquirerId,
        'inquirerName': inquirerName,
        'inquirerImage': inquirerImage,
        'inquirerPhoneNumber': inquirerPhoneNumber,
        'message': message,
        'wasRedirectedToWhatsApp': wasRedirectedToWhatsApp,
        'inquiryDate': DateTime.now().toIso8601String(),
      };

      final response = await _httpClient.post('/properties/$propertyId/inquiries', body: inquiryData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final inquiryMap = responseData.containsKey('inquiry') ? responseData['inquiry'] : responseData;
        return PropertyInquiryModel.fromMap(inquiryMap);
      } else {
        throw PropertyRepositoryException('Failed to record property inquiry: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to record property inquiry: $e');
    }
  }

  @override
  Future<List<PropertyInquiryModel>> getHostInquiries(String hostId, {int limit = 50}) async {
    try {
      final response = await _httpClient.get('/properties/host/$hostId/inquiries?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> inquiriesData = responseData['inquiries'] ?? [];
        return inquiriesData
            .map((inquiryData) => PropertyInquiryModel.fromMap(inquiryData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get host inquiries: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get host inquiries: $e');
    }
  }

  @override
  Future<List<PropertyInquiryModel>> getPropertyInquiries(String propertyId, {int limit = 50}) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/inquiries?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> inquiriesData = responseData['inquiries'] ?? [];
        return inquiriesData
            .map((inquiryData) => PropertyInquiryModel.fromMap(inquiryData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get property inquiries: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property inquiries: $e');
    }
  }

  // ===============================
  // FILE OPERATIONS (R2 STORAGE)
  // ===============================

  @override
  Future<String> uploadPropertyVideo(File videoFile, String propertyId) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload/property-video',
        videoFile,
        'video',
        additionalFields: {
          'propertyId': propertyId,
          'type': 'property_video',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final videoUrl = responseData['url'] as String;
        return videoUrl;
      } else {
        throw PropertyRepositoryException('Failed to upload property video: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to upload property video: $e');
    }
  }

  @override
  Future<List<String>> uploadPropertyImages(List<File> imageFiles, String propertyId) async {
    try {
      final List<String> imageUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final response = await _httpClient.uploadFile(
          '/upload/property-image',
          imageFile,
          'image',
          additionalFields: {
            'propertyId': propertyId,
            'imageIndex': i.toString(),
            'type': 'property_image',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final imageUrl = responseData['url'] as String;
          imageUrls.add(imageUrl);
        } else {
          throw PropertyRepositoryException('Failed to upload property image $i: ${response.body}');
        }
      }
      
      return imageUrls;
    } catch (e) {
      throw PropertyRepositoryException('Failed to upload property images: $e');
    }
  }

  @override
  Future<String> uploadPropertyThumbnail(File thumbnailFile, String propertyId) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload/property-thumbnail',
        thumbnailFile,
        'thumbnail',
        additionalFields: {
          'propertyId': propertyId,
          'type': 'property_thumbnail',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final thumbnailUrl = responseData['url'] as String;
        return thumbnailUrl;
      } else {
        throw PropertyRepositoryException('Failed to upload property thumbnail: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to upload property thumbnail: $e');
    }
  }

  // ===============================
  // ANALYTICS
  // ===============================

  @override
  Future<Map<String, dynamic>> getPropertyAnalytics(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/analytics');
      
      if (response.statusCode == 200) {
        final analyticsData = jsonDecode(response.body) as Map<String, dynamic>;
        return analyticsData;
      } else {
        throw PropertyRepositoryException('Failed to get property analytics: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property analytics: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getHostAnalytics(String hostId) async {
    try {
      final response = await _httpClient.get('/properties/host/$hostId/analytics');
      
      if (response.statusCode == 200) {
        final analyticsData = jsonDecode(response.body) as Map<String, dynamic>;
        return analyticsData;
      } else {
        throw PropertyRepositoryException('Failed to get host analytics: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get host analytics: $e');
    }
  }

  // ===============================
  // ADDITIONAL UTILITY METHODS
  // ===============================

  @override
  Future<Map<String, dynamic>> getPropertyStats(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/stats');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property stats: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property stats: $e');
    }
  }

  @override
  Future<List<PropertyListingModel>> getTrendingProperties({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/properties/trending?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get trending properties: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get trending properties: $e');
    }
  }

  @override
  Future<List<PropertyListingModel>> getFeaturedProperties({int limit = 5}) async {
    try {
      final response = await _httpClient.get('/properties/featured?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get featured properties: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get featured properties: $e');
    }
  }

  @override
  Future<List<PropertyListingModel>> getPropertiesByCity(String city, {int limit = 20}) async {
    try {
      final response = await _httpClient.get('/properties/city/${Uri.encodeComponent(city)}?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> propertiesData = responseData['properties'] ?? [];
        return propertiesData
            .map((propertyData) => PropertyListingModel.fromMap(propertyData as Map<String, dynamic>))
            .toList();
      } else {
        throw PropertyRepositoryException('Failed to get properties by city: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get properties by city: $e');
    }
  }

  @override
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _httpClient.get('/properties/cities');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> citiesData = responseData['cities'] ?? [];
        return citiesData.map((city) => city.toString()).toList();
      } else {
        throw PropertyRepositoryException('Failed to get available cities: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get available cities: $e');
    }
  }

  @override
  Future<void> submitPropertyForReview(String propertyId, String hostId) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/submit-review', body: {
        'hostId': hostId,
      });
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PropertyRepositoryException('Failed to submit property for review: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to submit property for review: $e');
    }
  }

  @override
  Future<bool> isPropertyTitleAvailable(String title, String hostId, {String? excludePropertyId}) async {
    try {
      String endpoint = '/properties/check-title?title=${Uri.encodeComponent(title)}&hostId=$hostId';
      if (excludePropertyId != null) {
        endpoint += '&excludeId=$excludePropertyId';
      }
      
      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return responseData['available'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // ADVANCED ANALYTICS AND REPORTS
  // ===============================

  /// Get comprehensive property performance metrics
  Future<Map<String, dynamic>> getPropertyPerformanceMetrics(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/performance');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property performance metrics: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property performance metrics: $e');
    }
  }

  /// Get host dashboard summary
  Future<Map<String, dynamic>> getHostDashboardSummary(String hostId) async {
    try {
      final response = await _httpClient.get('/properties/host/$hostId/dashboard');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get host dashboard summary: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get host dashboard summary: $e');
    }
  }

  /// Get property revenue analytics
  Future<Map<String, dynamic>> getPropertyRevenueAnalytics(String propertyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String endpoint = '/properties/$propertyId/revenue';
      
      if (startDate != null) {
        endpoint += '?startDate=${startDate.toIso8601String()}';
      }
      if (endDate != null) {
        endpoint += startDate != null 
            ? '&endDate=${endDate.toIso8601String()}' 
            : '?endDate=${endDate.toIso8601String()}';
      }
      
      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property revenue analytics: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property revenue analytics: $e');
    }
  }

  /// Get property engagement trends
  Future<Map<String, dynamic>> getPropertyEngagementTrends(String propertyId, {
    int days = 30,
  }) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/engagement-trends?days=$days');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property engagement trends: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property engagement trends: $e');
    }
  }

  /// Get competitive analysis for a property
  Future<Map<String, dynamic>> getPropertyCompetitiveAnalysis(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/competitive-analysis');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property competitive analysis: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property competitive analysis: $e');
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Batch update property availability
  Future<void> batchUpdateAvailability(List<Map<String, dynamic>> availabilityUpdates) async {
    try {
      final response = await _httpClient.post('/properties/batch/availability', body: {
        'updates': availabilityUpdates,
      });

      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to batch update availability: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to batch update availability: $e');
    }
  }

  /// Batch update property rates
  Future<void> batchUpdateRates(List<Map<String, dynamic>> rateUpdates) async {
    try {
      final response = await _httpClient.post('/properties/batch/rates', body: {
        'updates': rateUpdates,
      });

      if (response.statusCode != 200) {
        throw PropertyRepositoryException('Failed to batch update rates: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to batch update rates: $e');
    }
  }

  // ===============================
  // SUBSCRIPTION AND BILLING
  // ===============================

  /// Get property subscription status
  Future<Map<String, dynamic>> getPropertySubscriptionStatus(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/subscription');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property subscription status: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property subscription status: $e');
    }
  }

  /// Renew property subscription
  Future<Map<String, dynamic>> renewPropertySubscription(String propertyId, {
    required String paymentReference,
    required double amountPaid,
  }) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/renew-subscription', body: {
        'paymentReference': paymentReference,
        'amountPaid': amountPaid,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to renew property subscription: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to renew property subscription: $e');
    }
  }

  /// Get host billing history
  Future<List<Map<String, dynamic>>> getHostBillingHistory(String hostId, {int limit = 50}) async {
    try {
      final response = await _httpClient.get('/properties/host/$hostId/billing?limit=$limit');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> billingData = responseData['billing'] ?? [];
        return billingData.cast<Map<String, dynamic>>();
      } else {
        throw PropertyRepositoryException('Failed to get host billing history: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get host billing history: $e');
    }
  }

  // ===============================
  // CONTENT MODERATION
  // ===============================

  /// Report property for inappropriate content
  Future<void> reportProperty(String propertyId, {
    required String reporterId,
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/report', body: {
        'reporterId': reporterId,
        'reason': reason,
        'additionalDetails': additionalDetails,
        'reportedAt': DateTime.now().toIso8601String(),
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw PropertyRepositoryException('Failed to report property: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to report property: $e');
    }
  }

  /// Get property reports (admin only)
  Future<List<Map<String, dynamic>>> getPropertyReports(String propertyId) async {
    try {
      final response = await _httpClient.get('/properties/$propertyId/reports');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> reportsData = responseData['reports'] ?? [];
        return reportsData.cast<Map<String, dynamic>>();
      } else {
        throw PropertyRepositoryException('Failed to get property reports: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property reports: $e');
    }
  }

  // ===============================
  // CACHING AND OPTIMIZATION
  // ===============================

  /// Invalidate property cache
  Future<void> invalidatePropertyCache(String propertyId) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/invalidate-cache', body: {});

      if (response.statusCode != 200) {
        // Non-critical operation
        print('Warning: Failed to invalidate property cache: ${response.body}');
      }
    } catch (e) {
      // Non-critical operation
      print('Warning: Failed to invalidate property cache: $e');
    }
  }

  /// Warm up property cache
  Future<void> warmUpPropertyCache(String propertyId) async {
    try {
      final response = await _httpClient.post('/properties/$propertyId/warm-cache', body: {});

      if (response.statusCode != 200) {
        // Non-critical operation
        print('Warning: Failed to warm up property cache: ${response.body}');
      }
    } catch (e) {
      // Non-critical operation
      print('Warning: Failed to warm up property cache: $e');
    }
  }

  // ===============================
  // HEALTH CHECK AND DIAGNOSTICS
  // ===============================

  /// Test property service connectivity
  Future<bool> testPropertyServiceConnection() async {
    try {
      final response = await _httpClient.get('/properties/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get property service status
  Future<Map<String, dynamic>> getPropertyServiceStatus() async {
    try {
      final response = await _httpClient.get('/properties/status');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw PropertyRepositoryException('Failed to get property service status: ${response.body}');
      }
    } catch (e) {
      throw PropertyRepositoryException('Failed to get property service status: $e');
    }
  }
}

// Exception class for property repository errors
class PropertyRepositoryException implements Exception {
  final String message;
  const PropertyRepositoryException(this.message);
  
  @override
  String toString() => 'PropertyRepositoryException: $message';
}