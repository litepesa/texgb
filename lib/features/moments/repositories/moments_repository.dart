// ===============================
// Moments Repository
// Handles all API calls for moments feature
// ===============================

import 'dart:convert';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/services/http_client.dart';

/// Abstract repository interface
abstract class MomentsRepository {
  // Feed operations
  Future<List<MomentModel>> getFeed({int page = 1, int limit = 20});
  Future<List<MomentModel>> getUserMoments(String userId, {int page = 1, int limit = 30});
  Future<MomentModel?> getMoment(String momentId);

  // Create/Update/Delete
  Future<MomentModel> createMoment(CreateMomentRequest request);
  Future<bool> deleteMoment(String momentId);

  // Interactions
  Future<bool> likeMoment(String momentId);
  Future<bool> unlikeMoment(String momentId);
  Future<MomentCommentModel> commentOnMoment(String momentId, String content, {String? replyToUserId});
  Future<bool> deleteComment(String commentId);
  Future<List<MomentCommentModel>> getComments(String momentId, {int page = 1, int limit = 50});
  Future<List<MomentLikerModel>> getLikes(String momentId, {int page = 1, int limit = 50});

  // Privacy settings
  Future<MomentPrivacySettings?> getPrivacySettings(String userId);
  Future<MomentPrivacySettings> updatePrivacySettings(String userId, UpdatePrivacyRequest request);

  // Mutual contacts check (required for privacy)
  Future<bool> isMutualContact(String userId, String contactId);
  Future<List<String>> getMutualContacts(String userId);
}

/// HTTP Backend implementation
class HttpMomentsRepository implements MomentsRepository {
  final HttpClientService _httpClient;

  HttpMomentsRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // FEED OPERATIONS
  // ===============================

  @override
  Future<List<MomentModel>> getFeed({int page = 1, int limit = 20}) async {
    try {
      // Use discover feed (public, doesn't require following) - same as videos pattern
      final response = await _httpClient.get(
        '/posts/discover?page=$page&per_page=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final moments = (data['posts'] as List?)
            ?.map((json) => MomentModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return moments ?? [];
      } else {
        throw MomentsRepositoryException('Failed to get feed: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to get feed: $e');
    }
  }

  @override
  Future<List<MomentModel>> getUserMoments(
    String userId, {
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _httpClient.get(
        '/users/$userId/posts?page=$page&per_page=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final moments = (data['posts'] as List?)
            ?.map((json) => MomentModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return moments ?? [];
      } else {
        throw MomentsRepositoryException('Failed to get user moments: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to get user moments: $e');
    }
  }

  @override
  Future<MomentModel?> getMoment(String momentId) async {
    try {
      final response = await _httpClient.get('/posts/$momentId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MomentModel.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw MomentsRepositoryException('Failed to get moment: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw MomentsRepositoryException('Failed to get moment: $e');
    }
  }

  // ===============================
  // CREATE/UPDATE/DELETE
  // ===============================

  @override
  Future<MomentModel> createMoment(CreateMomentRequest request) async {
    try {
      final response = await _httpClient.post(
        '/posts',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MomentModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw MomentsRepositoryException('Failed to create moment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to create moment: $e');
    }
  }

  @override
  Future<bool> deleteMoment(String momentId) async {
    try {
      final response = await _httpClient.delete('/posts/$momentId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw MomentsRepositoryException('Failed to delete moment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to delete moment: $e');
    }
  }

  // ===============================
  // INTERACTIONS
  // ===============================

  @override
  Future<bool> likeMoment(String momentId) async {
    try {
      final response = await _httpClient.post(
        '/posts/$momentId/like',
        body: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw MomentsRepositoryException('Failed to like moment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to like moment: $e');
    }
  }

  @override
  Future<bool> unlikeMoment(String momentId) async {
    try {
      final response = await _httpClient.delete('/posts/$momentId/like');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw MomentsRepositoryException('Failed to unlike moment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to unlike moment: $e');
    }
  }

  @override
  Future<MomentCommentModel> commentOnMoment(
    String momentId,
    String content, {
    String? replyToUserId,
  }) async {
    try {
      final response = await _httpClient.post(
        '/posts/$momentId/comments',
        body: {
          'comment_text': content,
          if (replyToUserId != null) 'replyToUserId': replyToUserId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MomentCommentModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw MomentsRepositoryException('Failed to comment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to comment: $e');
    }
  }

  @override
  Future<bool> deleteComment(String commentId) async {
    try {
      final response = await _httpClient.delete('/posts/comments/$commentId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw MomentsRepositoryException('Failed to delete comment: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to delete comment: $e');
    }
  }

  @override
  Future<List<MomentCommentModel>> getComments(
    String momentId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _httpClient.get(
        '/posts/$momentId/comments?page=$page&per_page=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final comments = (data['comments'] as List?)
            ?.map((json) => MomentCommentModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return comments ?? [];
      } else {
        throw MomentsRepositoryException('Failed to get comments: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to get comments: $e');
    }
  }

  @override
  Future<List<MomentLikerModel>> getLikes(
    String momentId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _httpClient.get(
        '/posts/$momentId/likes?page=$page&per_page=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final likes = (data['likes'] as List?)
            ?.map((json) => MomentLikerModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return likes ?? [];
      } else {
        throw MomentsRepositoryException('Failed to get likes: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to get likes: $e');
    }
  }

  // ===============================
  // PRIVACY SETTINGS
  // ===============================

  @override
  Future<MomentPrivacySettings?> getPrivacySettings(String userId) async {
    try {
      final response = await _httpClient.get('/moments/privacy/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MomentPrivacySettings.fromJson(data['settings'] as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw MomentsRepositoryException('Failed to get privacy settings: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw MomentsRepositoryException('Failed to get privacy settings: $e');
    }
  }

  @override
  Future<MomentPrivacySettings> updatePrivacySettings(
    String userId,
    UpdatePrivacyRequest request,
  ) async {
    try {
      final response = await _httpClient.put(
        '/moments/privacy/$userId',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MomentPrivacySettings.fromJson(data['settings'] as Map<String, dynamic>);
      } else {
        throw MomentsRepositoryException('Failed to update privacy settings: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to update privacy settings: $e');
    }
  }

  // ===============================
  // MUTUAL CONTACTS
  // ===============================

  @override
  Future<bool> isMutualContact(String userId, String contactId) async {
    try {
      final response = await _httpClient.get(
        '/contacts/mutual/$userId/$contactId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isMutual'] == true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getMutualContacts(String userId) async {
    try {
      final response = await _httpClient.get('/contacts/mutual/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contacts = (data['contacts'] as List?)
            ?.map((json) => json['userId'] as String)
            .toList();
        return contacts ?? [];
      } else {
        throw MomentsRepositoryException('Failed to get mutual contacts: ${response.body}');
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to get mutual contacts: $e');
    }
  }
}

/// Custom exception for moments repository errors
class MomentsRepositoryException implements Exception {
  final String message;
  MomentsRepositoryException(this.message);

  @override
  String toString() => 'MomentsRepositoryException: $message';
}
