// lib/features/channels/repositories/channel_repository.dart
import 'dart:io';
import 'dart:convert';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/models/channel_comment_model.dart';
import 'package:textgb/shared/services/http_client.dart';

/// Repository for channel-related API calls
class ChannelRepository {
  final HttpClientService _httpClient;

  ChannelRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ============================
  // CHANNEL CRUD OPERATIONS
  // ============================

  /// Get all channels (discovery/list)
  Future<List<ChannelModel>> getChannels({
    int page = 1,
    int perPage = 20,
    String? type, // public, private, premium
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (type != null) 'type': type,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final query = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _httpClient.get('/channels?$query');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final channels = (data['channels'] as List? ?? [])
            .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return channels;
      }

      return [];
    } catch (e) {
      print('Error getting channels: $e');
      return [];
    }
  }

  /// Get trending channels
  Future<List<ChannelModel>> getTrendingChannels({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/channels/trending?limit=$limit');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['channels'] as List? ?? [])
            .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting trending channels: $e');
      return [];
    }
  }

  /// Get popular channels
  Future<List<ChannelModel>> getPopularChannels({int limit = 10}) async {
    try {
      final response = await _httpClient.get('/channels/popular?limit=$limit');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['channels'] as List? ?? [])
            .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting popular channels: $e');
      return [];
    }
  }

  /// Get channel by ID
  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      final response = await _httpClient.get('/channels/$channelId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error getting channel: $e');
      return null;
    }
  }

  /// Create new channel
  Future<ChannelModel?> createChannel({
    required String name,
    required String description,
    required ChannelType type,
    int? subscriptionPriceCoins,
    File? avatar,
    File? banner,
  }) async {
    try {
      final body = {
        'name': name,
        'description': description,
        'type': type.name,
        if (subscriptionPriceCoins != null)
          'subscription_price_coins': subscriptionPriceCoins,
      };

      final response = await _httpClient.post('/channels', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error creating channel: $e');
      return null;
    }
  }

  /// Update channel
  Future<bool> updateChannel(String channelId, Map<String, dynamic> updates) async {
    try {
      final response = await _httpClient.put('/channels/$channelId', body: updates);
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating channel: $e');
      return false;
    }
  }

  /// Delete channel
  Future<bool> deleteChannel(String channelId) async {
    try {
      final response = await _httpClient.delete('/channels/$channelId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting channel: $e');
      return false;
    }
  }

  // ============================
  // CHANNEL SUBSCRIPTION
  // ============================

  /// Subscribe to channel
  Future<bool> subscribeToChannel(String channelId) async {
    try {
      final response = await _httpClient.post('/channels/$channelId/subscribe');
      return response.statusCode == 200;
    } catch (e) {
      print('Error subscribing: $e');
      return false;
    }
  }

  /// Unsubscribe from channel
  Future<bool> unsubscribeFromChannel(String channelId) async {
    try {
      final response = await _httpClient.delete('/channels/$channelId/subscribe');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unsubscribing: $e');
      return false;
    }
  }

  /// Get user's subscribed channels
  Future<List<ChannelModel>> getSubscribedChannels() async {
    try {
      final response = await _httpClient.get('/channels/subscribed');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['channels'] as List? ?? [])
            .map((json) => ChannelModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting subscribed channels: $e');
      return [];
    }
  }

  // ============================
  // CHANNEL POSTS
  // ============================

  /// Get posts for a channel
  Future<List<ChannelPost>> getChannelPosts(
    String channelId, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/channels/$channelId/posts?page=$page&per_page=$perPage',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['posts'] as List? ?? [])
            .map((json) => ChannelPost.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting channel posts: $e');
      return [];
    }
  }

  /// Get single post
  Future<ChannelPost?> getPost(String postId) async {
    try {
      final response = await _httpClient.get('/channels/posts/$postId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelPost.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  /// Create post (with chunked upload for large files)
  Future<ChannelPost?> createPost({
    required String channelId,
    required PostContentType contentType,
    String? text,
    File? mediaFile,
    List<File>? imageFiles,
    bool isPremium = false,
    int? priceCoins,
    int? previewDuration,
    Function(double)? onUploadProgress,
  }) async {
    try {
      // TODO: Implement chunked upload for large files (>100MB)
      // For now, simple upload

      final body = {
        'channel_id': channelId,
        'content_type': contentType.name,
        if (text != null) 'text': text,
        'is_premium': isPremium,
        if (priceCoins != null) 'price_coins': priceCoins,
        if (previewDuration != null) 'preview_duration': previewDuration,
      };

      final response = await _httpClient.post('/channels/posts', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelPost.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Delete post
  Future<bool> deletePost(String postId) async {
    try {
      final response = await _httpClient.delete('/channels/posts/$postId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// Like post
  Future<bool> likePost(String postId) async {
    try {
      final response = await _httpClient.post('/channels/posts/$postId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId) async {
    try {
      final response = await _httpClient.delete('/channels/posts/$postId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  /// Unlock premium post
  Future<bool> unlockPost(String postId) async {
    try {
      final response = await _httpClient.post('/channels/posts/$postId/unlock');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unlocking post: $e');
      return false;
    }
  }

  // ============================
  // COMMENTS (Multi-threaded)
  // ============================

  /// Get comments for a post
  Future<List<ChannelComment>> getPostComments(
    String postId, {
    String? parentCommentId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final query = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (parentCommentId != null) 'parent_id': parentCommentId,
      };

      final queryString = query.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _httpClient.get(
        '/channels/posts/$postId/comments?$queryString',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['comments'] as List? ?? [])
            .map((json) => ChannelComment.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  /// Create comment
  Future<ChannelComment?> createComment({
    required String postId,
    required String text,
    String? parentCommentId,
    File? mediaFile,
  }) async {
    try {
      final body = {
        'post_id': postId,
        'text': text,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      };

      final response = await _httpClient.post('/channels/comments', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelComment.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error creating comment: $e');
      return null;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final response = await _httpClient.delete('/channels/comments/$commentId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Like comment
  Future<bool> likeComment(String commentId) async {
    try {
      final response = await _httpClient.post('/channels/comments/$commentId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  /// Pin comment (admin/mod only)
  Future<bool> pinComment(String commentId) async {
    try {
      final response = await _httpClient.post('/channels/comments/$commentId/pin');
      return response.statusCode == 200;
    } catch (e) {
      print('Error pinning comment: $e');
      return false;
    }
  }

  // ============================
  // CHANNEL MEMBERS & ADMIN
  // ============================

  /// Get channel members
  Future<List<ChannelMember>> getChannelMembers(String channelId) async {
    try {
      final response = await _httpClient.get('/channels/$channelId/members');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['members'] as List? ?? [])
            .map((json) => ChannelMember.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting members: $e');
      return [];
    }
  }

  /// Add admin/moderator
  Future<bool> addChannelMember({
    required String channelId,
    required String userId,
    required MemberRole role,
  }) async {
    try {
      final response = await _httpClient.post(
        '/channels/$channelId/members',
        body: {'user_id': userId, 'role': role.name},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding member: $e');
      return false;
    }
  }

  /// Remove member
  Future<bool> removeChannelMember({
    required String channelId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.delete(
        '/channels/$channelId/members/$userId',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }
}
