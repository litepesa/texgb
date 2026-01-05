// lib/features/groups/services/group_api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/models/group_member_model.dart';
import 'package:textgb/features/groups/models/group_message_model.dart';

class GroupApiService {
  final HttpClientService _httpClient;

  GroupApiService({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== GROUP ENDPOINTS ====================

  /// GET /api/v1/groups - List user's groups
  Future<List<GroupModel>> getUserGroups({int? limit, int? offset}) async {
    try {
      String endpoint = '/groups';
      final queryParams = <String>[];
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _httpClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => GroupModel.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => GroupModel.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw HttpException('Failed to fetch groups: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user groups: $e');
      rethrow;
    }
  }

  /// GET /api/v1/groups/search - Search groups
  Future<List<GroupModel>> searchGroups(String query,
      {int? limit, int? offset}) async {
    try {
      String endpoint = '/groups/search?q=$query';
      if (limit != null) endpoint += '&limit=$limit';
      if (offset != null) endpoint += '&offset=$offset';

      final response = await _httpClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => GroupModel.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => GroupModel.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw HttpException('Failed to search groups: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching groups: $e');
      rethrow;
    }
  }

  /// POST /api/v1/groups - Create group
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    String? groupImageUrl,
    int maxMembers = 256,
  }) async {
    try {
      final response = await _httpClient.post('/groups', body: {
        'name': name,
        'description': description,
        if (groupImageUrl != null) 'group_image_url': groupImageUrl,
        'max_members': maxMembers,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GroupModel.fromJson(data['data'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw HttpException(
            error['error'] ?? 'Failed to create group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      rethrow;
    }
  }

  /// GET /api/v1/groups/:id - Get group details
  Future<GroupModel> getGroupDetails(String groupId) async {
    try {
      final response = await _httpClient.get('/groups/$groupId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GroupModel.fromJson(data['data'] ?? data);
      } else {
        throw HttpException(
            'Failed to fetch group details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching group details: $e');
      rethrow;
    }
  }

  /// PUT /api/v1/groups/:id - Update group
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? groupImageUrl,
    int? maxMembers,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (groupImageUrl != null) body['group_image_url'] = groupImageUrl;
      if (maxMembers != null) body['max_members'] = maxMembers;

      final response = await _httpClient.put('/groups/$groupId', body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GroupModel.fromJson(data['data'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw HttpException(
            error['error'] ?? 'Failed to update group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
      rethrow;
    }
  }

  /// DELETE /api/v1/groups/:id - Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      final response = await _httpClient.delete('/groups/$groupId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw HttpException(
            error['error'] ?? 'Failed to delete group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }

  // ==================== MEMBER ENDPOINTS ====================

  /// GET /api/v1/groups/:id/members - List members
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      final response = await _httpClient.get('/groups/$groupId/members');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => GroupMemberModel.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => GroupMemberModel.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw HttpException(
            'Failed to fetch group members: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching group members: $e');
      rethrow;
    }
  }

  /// POST /api/v1/groups/:id/members - Add members
  Future<void> addMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    try {
      final response = await _httpClient.post(
        '/groups/$groupId/members',
        body: {'user_ids': userIds},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw HttpException(
            error['error'] ?? 'Failed to add members: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding members: $e');
      rethrow;
    }
  }

  /// DELETE /api/v1/groups/:id/members/:user_id - Remove member
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response =
          await _httpClient.delete('/groups/$groupId/members/$userId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw HttpException(error['error'] ??
            'Failed to remove member: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  /// POST /api/v1/groups/:id/members/:user_id/promote - Promote to admin
  Future<void> promoteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response =
          await _httpClient.post('/groups/$groupId/members/$userId/promote');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw HttpException(error['error'] ??
            'Failed to promote member: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error promoting member: $e');
      rethrow;
    }
  }

  /// POST /api/v1/groups/:id/members/:user_id/demote - Demote from admin
  Future<void> demoteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response =
          await _httpClient.post('/groups/$groupId/members/$userId/demote');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw HttpException(error['error'] ??
            'Failed to demote member: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error demoting member: $e');
      rethrow;
    }
  }

  // ==================== MESSAGE ENDPOINTS ====================

  /// GET /api/v1/groups/:id/messages - List messages
  Future<List<GroupMessageModel>> getGroupMessages(String groupId,
      {int? limit, int? offset}) async {
    try {
      String endpoint = '/groups/$groupId/messages';
      final queryParams = <String>[];
      if (limit != null) queryParams.add('limit=$limit');
      if (offset != null) queryParams.add('offset=$offset');
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await _httpClient.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => GroupMessageModel.fromJson(json)).toList();
        } else if (data is Map && data['data'] is List) {
          return (data['data'] as List)
              .map((json) => GroupMessageModel.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw HttpException(
            'Failed to fetch group messages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching group messages: $e');
      rethrow;
    }
  }

  /// POST /api/v1/groups/:id/messages - Send message
  Future<GroupMessageModel> sendMessage({
    required String groupId,
    required String messageText,
    String? mediaUrl,
    MessageMediaType mediaType = MessageMediaType.text,
  }) async {
    try {
      final response = await _httpClient.post(
        '/groups/$groupId/messages',
        body: {
          'message_text': messageText,
          if (mediaUrl != null) 'media_url': mediaUrl,
          'media_type': mediaType.name,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GroupMessageModel.fromJson(data['data'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw HttpException(
            error['error'] ?? 'Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// DELETE /api/v1/groups/:group_id/messages/:message_id - Delete message
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    try {
      final response =
          await _httpClient.delete('/groups/$groupId/messages/$messageId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw HttpException(error['error'] ??
            'Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Leave group (remove self)
  Future<void> leaveGroup(String groupId, String userId) async {
    return removeMember(groupId: groupId, userId: userId);
  }

  /// Check if user is group member
  Future<bool> isMember(String groupId, String userId) async {
    try {
      final members = await getGroupMembers(groupId);
      return members.any((member) => member.userId == userId);
    } catch (e) {
      debugPrint('Error checking membership: $e');
      return false;
    }
  }

  /// Check if user is group admin
  Future<bool> isAdmin(String groupId, String userId) async {
    try {
      final members = await getGroupMembers(groupId);
      final member = members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => throw Exception('User not a member'),
      );
      return member.isAdmin;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
}
