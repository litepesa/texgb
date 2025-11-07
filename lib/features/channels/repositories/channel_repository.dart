// ===============================
// Channel Repository
// Backend-ready API integration for channels
// Handles: Channel CRUD, Follow/Unfollow, Videos
// ===============================

import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'dart:convert';

/// Abstract repository interface
abstract class ChannelRepository {
  // Channel CRUD
  Future<ChannelModel> createChannel(CreateChannelRequest request);
  Future<ChannelModel> getChannel(String channelId);
  Future<ChannelModel?> getUserChannel(String userId);
  Future<ChannelModel> updateChannel(String channelId, UpdateChannelRequest request);
  Future<bool> deleteChannel(String channelId);

  // Follow system
  Future<void> followChannel(String channelId);
  Future<void> unfollowChannel(String channelId);
  Future<List<ChannelModel>> getFollowers(String channelId, {int page = 1, int limit = 20});
  Future<bool> isFollowing(String channelId);

  // Videos
  Future<List<VideoModel>> getChannelVideos(String channelId, {int page = 1, int limit = 20});
  Future<List<VideoModel>> getFeed({int page = 1, int limit = 20});
  Future<List<VideoModel>> getDiscoverFeed({int page = 1, int limit = 20});
}

/// HTTP implementation
class HttpChannelRepository implements ChannelRepository {
  final HttpClientService _httpClient;

  HttpChannelRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // Channel CRUD
  // ===============================

  @override
  Future<ChannelModel> createChannel(CreateChannelRequest request) async {
    try {
      final response = await _httpClient.post(
        '/channels',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      } else {
        throw ChannelRepositoryException('Failed to create channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to create channel: $e');
    }
  }

  @override
  Future<ChannelModel> getChannel(String channelId) async {
    try {
      final response = await _httpClient.get('/channels/$channelId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      } else {
        throw ChannelRepositoryException('Failed to get channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get channel: $e');
    }
  }

  @override
  Future<ChannelModel?> getUserChannel(String userId) async {
    try {
      final response = await _httpClient.get('/channels/user/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // User hasn't created a channel yet
      } else {
        throw ChannelRepositoryException('Failed to get user channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get user channel: $e');
    }
  }

  @override
  Future<ChannelModel> updateChannel(
    String channelId,
    UpdateChannelRequest request,
  ) async {
    try {
      final response = await _httpClient.put(
        '/channels/$channelId',
        body: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelModel.fromJson(data);
      } else {
        throw ChannelRepositoryException('Failed to update channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to update channel: $e');
    }
  }

  @override
  Future<bool> deleteChannel(String channelId) async {
    try {
      final response = await _httpClient.delete('/channels/$channelId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw ChannelRepositoryException('Failed to delete channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to delete channel: $e');
    }
  }

  // ===============================
  // Follow System
  // ===============================

  @override
  Future<void> followChannel(String channelId) async {
    try {
      final response = await _httpClient.post(
        '/channels/$channelId/follow',
        body: {},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ChannelRepositoryException('Failed to follow channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to follow channel: $e');
    }
  }

  @override
  Future<void> unfollowChannel(String channelId) async {
    try {
      final response = await _httpClient.delete('/channels/$channelId/follow');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ChannelRepositoryException('Failed to unfollow channel: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to unfollow channel: $e');
    }
  }

  @override
  Future<List<ChannelModel>> getFollowers(
    String channelId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/channels/$channelId/followers?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => ChannelModel.fromJson(json)).toList();
      } else {
        throw ChannelRepositoryException('Failed to get followers: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get followers: $e');
    }
  }

  @override
  Future<bool> isFollowing(String channelId) async {
    try {
      final response = await _httpClient.get('/channels/$channelId/following');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isFollowing'] as bool? ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // Videos
  // ===============================

  @override
  Future<List<VideoModel>> getChannelVideos(
    String channelId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _httpClient.get(
        '/channels/$channelId/videos?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw ChannelRepositoryException('Failed to get channel videos: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get channel videos: $e');
    }
  }

  @override
  Future<List<VideoModel>> getFeed({int page = 1, int limit = 20}) async {
    try {
      final response = await _httpClient.get(
        '/channels/videos/feed?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw ChannelRepositoryException('Failed to get feed: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get feed: $e');
    }
  }

  @override
  Future<List<VideoModel>> getDiscoverFeed({int page = 1, int limit = 20}) async {
    try {
      final response = await _httpClient.get(
        '/channels/videos/discover?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw ChannelRepositoryException('Failed to get discover feed: ${response.body}');
      }
    } catch (e) {
      throw ChannelRepositoryException('Failed to get discover feed: $e');
    }
  }
}

// ===============================
// Exceptions
// ===============================

class ChannelRepositoryException implements Exception {
  final String message;
  ChannelRepositoryException(this.message);

  @override
  String toString() => 'ChannelRepositoryException: $message';
}
