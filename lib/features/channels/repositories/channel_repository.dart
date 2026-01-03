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
        // Backend returns {"channel": {...}, "isOwner": bool, "isAdmin": bool, ...}
        // Merge the user relationship fields into the channel data
        final channelData = Map<String, dynamic>.from(data['channel'] ?? data);

        // Add user relationship fields from the response
        if (data.containsKey('isOwner')) channelData['is_owner'] = data['isOwner'];
        if (data.containsKey('is_owner')) channelData['is_owner'] = data['is_owner'];
        if (data.containsKey('isAdmin')) channelData['is_admin'] = data['isAdmin'];
        if (data.containsKey('is_admin')) channelData['is_admin'] = data['is_admin'];
        if (data.containsKey('isSubscribed')) channelData['is_subscribed'] = data['isSubscribed'];
        if (data.containsKey('is_subscribed')) channelData['is_subscribed'] = data['is_subscribed'];
        if (data.containsKey('unreadCount')) channelData['unread_count'] = data['unreadCount'];
        if (data.containsKey('unread_count')) channelData['unread_count'] = data['unread_count'];

        return ChannelModel.fromJson(channelData);
      }

      return null;
    } catch (e) {
      print('Error getting channel: $e');
      return null;
    }
  }

  /// Check if a channel name is available
  Future<Map<String, dynamic>> checkNameAvailability(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name.trim());
      final response = await _httpClient.get('/channels/check-name?name=$encodedName');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'available': data['available'] ?? false,
          'message': data['message'] ?? '',
        };
      }

      return {
        'available': false,
        'message': 'Unable to check name availability',
      };
    } catch (e) {
      print('[CHANNEL] Error checking name availability: $e');
      return {
        'available': false,
        'message': 'Error checking availability',
      };
    }
  }

  /// Create new channel
  /// Returns a Map with either 'channel' or 'error' key
  Future<Map<String, dynamic>> createChannel({
    required String name,
    required String description,
    required ChannelType type,
    int? subscriptionPriceCoins,
    File? avatar,
  }) async {
    try {
      // Step 1: Upload avatar if provided
      String? avatarUrl;
      if (avatar != null) {
        try {
          print('[CHANNEL] Uploading avatar: ${avatar.path}');
          final uploadResponse = await _httpClient.uploadFile(
            '/upload',
            avatar,
            'file',
            additionalFields: {'type': 'channel_avatar'},
          );

          if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
            final uploadData = jsonDecode(uploadResponse.body);
            avatarUrl = uploadData['url'] as String?;
            print('[CHANNEL] Avatar uploaded successfully: $avatarUrl');
          } else {
            print('[CHANNEL] Avatar upload failed with status ${uploadResponse.statusCode}');
          }
        } catch (e) {
          print('[CHANNEL] Error uploading avatar: $e');
          // Continue without avatar
        }
      }

      // Step 2: Create channel with avatar URL
      final body = {
        'name': name,
        'description': description,
        'type': type.name,
        if (subscriptionPriceCoins != null)
          'subscription_price_coins': subscriptionPriceCoins,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      print('[CHANNEL] Creating channel with data: $body');
      final response = await _httpClient.post('/channels', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('[CHANNEL] Channel created successfully');
        // Backend returns {"channel": {...}}, extract the channel object
        final channelData = data['channel'] ?? data;
        return {
          'channel': ChannelModel.fromJson(channelData),
        };
      }

      // Handle error response
      print('[CHANNEL] Channel creation failed with status ${response.statusCode}');
      final errorData = jsonDecode(response.body);
      String errorMessage = 'Failed to create channel';

      // Extract specific error message from backend
      if (errorData['errors'] != null) {
        final errors = errorData['errors'] as Map<String, dynamic>;
        if (errors['name'] != null) {
          // Get the first error message for the name field
          final nameErrors = errors['name'];
          if (nameErrors is List && nameErrors.isNotEmpty) {
            errorMessage = nameErrors[0];
          } else if (nameErrors is String) {
            errorMessage = nameErrors;
          }
        } else {
          // Get the first error message from any field
          final firstError = errors.values.firstOrNull;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError[0];
          } else if (firstError is String) {
            errorMessage = firstError;
          }
        }
      } else if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }

      return {
        'error': errorMessage,
      };
    } catch (e) {
      print('[CHANNEL] Error creating channel: $e');
      return {
        'error': 'An error occurred while creating the channel',
      };
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
      final response = await _httpClient.get('/channel-posts/$postId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChannelPost.fromJson(data['post'] ?? data);
      }

      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  /// Create post (with media upload support)
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
      String? mediaUrl;
      List<String>? mediaUrls;
      String? thumbnailUrl;
      int? mediaSizeBytes;
      int? mediaDurationSeconds;

      // Step 1: Upload media files if provided
      if (mediaFile != null) {
        // Upload single media file (video, audio, document)
        onUploadProgress?.call(0.2);

        final uploadResponse = await _httpClient.uploadFile(
          '/upload',
          mediaFile,
          'file',
          additionalFields: {'type': 'channel_post'},
        );

        if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
          final uploadData = jsonDecode(uploadResponse.body);
          mediaUrl = uploadData['url'];
          mediaSizeBytes = await mediaFile.length();

          // If it's a video, generate thumbnail
          if (contentType == PostContentType.video) {
            onUploadProgress?.call(0.5);
            // TODO: Generate and upload thumbnail
            // For now, use the same URL as placeholder
          }
        } else {
          print('Media upload failed: ${uploadResponse.statusCode}');
          return null;
        }
      } else if (imageFiles != null && imageFiles.isNotEmpty) {
        // Upload multiple images
        onUploadProgress?.call(0.2);

        mediaUrls = [];
        for (int i = 0; i < imageFiles.length; i++) {
          final uploadResponse = await _httpClient.uploadFile(
            '/upload',
            imageFiles[i],
            'file',
            additionalFields: {'type': 'channel_post'},
          );

          if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
            final uploadData = jsonDecode(uploadResponse.body);
            mediaUrls.add(uploadData['url']);
          }

          // Update progress
          final uploadProgress = 0.2 + (0.6 * (i + 1) / imageFiles.length);
          onUploadProgress?.call(uploadProgress);
        }

        if (mediaUrls.isEmpty) {
          print('All image uploads failed');
          return null;
        }
      }

      onUploadProgress?.call(0.8);

      // Step 2: Map content type to backend format
      String backendContentType;
      switch (contentType) {
        case PostContentType.text:
          backendContentType = 'text';
          break;
        case PostContentType.image:
        case PostContentType.textImage:
          backendContentType = 'image';
          break;
        case PostContentType.video:
        case PostContentType.textVideo:
          backendContentType = 'video';
          break;
      }

      // Step 3: Create post with uploaded media URLs
      final body = {
        'channel_id': channelId,
        'content_type': backendContentType,
        if (text != null && text.isNotEmpty) 'text': text,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (mediaUrls != null && mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
        if (thumbnailUrl != null) 'media_thumbnail_url': thumbnailUrl,
        if (mediaSizeBytes != null) 'media_size_bytes': mediaSizeBytes,
        if (mediaDurationSeconds != null) 'media_duration_seconds': mediaDurationSeconds,
        'is_premium': isPremium,
        if (priceCoins != null) 'price_coins': priceCoins,
        if (previewDuration != null) 'preview_duration_seconds': previewDuration,
      };

      final response = await _httpClient.post('/channel-posts', body: body);

      onUploadProgress?.call(1.0);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelPost.fromJson(data['post'] ?? data);
      }

      print('Create channel post failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e, stackTrace) {
      print('Error creating post: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete post
  Future<bool> deletePost(String postId) async {
    try {
      final response = await _httpClient.delete('/channel-posts/$postId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// Like post
  Future<bool> likePost(String postId) async {
    try {
      final response = await _httpClient.post('/channel-posts/$postId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking post: $e');
      return false;
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId) async {
    try {
      final response = await _httpClient.delete('/channel-posts/$postId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unliking post: $e');
      return false;
    }
  }

  /// Unlock premium post
  Future<bool> unlockPost(String postId) async {
    try {
      final response = await _httpClient.post('/channel-posts/$postId/unlock');
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
        '/channel-posts/$postId/comments?$queryString',
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

      final response = await _httpClient.post('/comments', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ChannelComment.fromJson(data['comment'] ?? data);
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
      final response = await _httpClient.delete('/comments/$commentId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// Like comment
  Future<bool> likeComment(String commentId) async {
    try {
      final response = await _httpClient.post('/comments/$commentId/like');
      return response.statusCode == 200;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  /// Pin comment (admin/mod only)
  Future<bool> pinComment(String commentId) async {
    try {
      final response = await _httpClient.post('/comments/$commentId/pin');
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
