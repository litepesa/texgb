// lib/features/live_streaming/repositories/live_stream_repository.dart

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/live_streaming/models/refined_live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';
import 'package:textgb/features/live_streaming/models/gift_transaction_model.dart';

class LiveStreamRepository {
  final HttpClientService _httpClient;

  LiveStreamRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== LIVE STREAM CRUD ====================

  /// Create a new live stream session (Gift or Shop)
  /// Backend will generate Agora token and channel
  Future<RefinedLiveStreamModel> createLiveStream({
    required String hostId,
    required String title,
    required LiveStreamType type,
    String? description,
    String? category,
    List<String> tags = const [],
    bool isPrivate = false,
    // For Shop streams
    String? shopId,
    List<String>? featuredProductIds,
    double? commissionRate,
    // For Gift streams
    Map<String, dynamic>? giftConfig,
  }) async {
    final response = await _httpClient.post('/live-streams', body: {
      'hostId': hostId,
      'title': title,
      'type': type.name,
      'description': description ?? '',
      'category': category ?? 'other',
      'tags': tags,
      'isPrivate': isPrivate,
      // Shop-specific
      if (type == LiveStreamType.shop) ...{
        'shopId': shopId,
        'featuredProductIds': featuredProductIds ?? [],
        'commissionRate': commissionRate ?? 10.0,
      },
      // Gift-specific
      if (type == LiveStreamType.gift && giftConfig != null)
        'giftConfig': giftConfig,
    });

    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }

  /// Start broadcasting (update stream status to live)
  Future<RefinedLiveStreamModel> startLiveStream(String streamId) async {
    final response = await _httpClient.post('/live-streams/$streamId/start');
    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }

  /// End the live stream
  Future<void> endLiveStream(String streamId) async {
    await _httpClient.post('/live-streams/$streamId/end');
  }

  /// Get live stream details
  Future<RefinedLiveStreamModel> getLiveStream(String streamId) async {
    final response = await _httpClient.get('/live-streams/$streamId');
    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }

  /// Get all currently live streams
  Future<List<RefinedLiveStreamModel>> getLiveStreams({
    int limit = 20,
    int offset = 0,
    LiveStreamType? type,
    LiveStreamCategory? category,
  }) async {
    final queryParams = <String, String>{
      'status': 'live',
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (type != null) queryParams['type'] = type.name;
    if (category != null) queryParams['category'] = category.name;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/live-streams?$queryString');

    final data = jsonDecode(response.body);
    final streams = data['streams'] as List;
    return streams.map((s) => RefinedLiveStreamModel.fromJson(s)).toList();
  }

  /// Get gift live streams only
  Future<List<RefinedLiveStreamModel>> getGiftLiveStreams({
    int limit = 20,
  }) async {
    return getLiveStreams(limit: limit, type: LiveStreamType.gift);
  }

  /// Get shop live streams only
  Future<List<RefinedLiveStreamModel>> getShopLiveStreams({
    int limit = 20,
  }) async {
    return getLiveStreams(limit: limit, type: LiveStreamType.shop);
  }

  // ==================== JOIN/LEAVE ====================

  /// Join a live stream as viewer (get Agora token)
  Future<Map<String, dynamic>> joinLiveStream(String streamId, String userId) async {
    final response = await _httpClient.post('/live-streams/$streamId/join',
      body: {'userId': userId}
    );

    final data = jsonDecode(response.body);
    return {
      'stream': RefinedLiveStreamModel.fromJson(data['stream']),
      'agoraToken': data['agoraToken'],
      'agoraUid': data['agoraUid'],
    };
  }

  /// Leave a live stream
  Future<void> leaveLiveStream(String streamId, String userId) async {
    await _httpClient.post('/live-streams/$streamId/leave',
      body: {'userId': userId}
    );
  }

  // ==================== GIFT OPERATIONS (Gift Live) ====================

  /// Send a gift during gift live stream
  Future<GiftTransactionModel> sendGift({
    required String streamId,
    required String senderId,
    required String giftId,
    int quantity = 1,
    String? message,
    bool isAnonymous = false,
  }) async {
    final response = await _httpClient.post('/live-streams/$streamId/gifts', body: {
      'senderId': senderId,
      'giftId': giftId,
      'quantity': quantity,
      'message': message,
      'isAnonymous': isAnonymous,
    });

    final data = jsonDecode(response.body);
    return GiftTransactionModel.fromJson(data['transaction'] ?? data);
  }

  /// Get gift transactions for a stream
  Future<List<GiftTransactionModel>> getStreamGifts({
    required String streamId,
    int limit = 50,
  }) async {
    final response = await _httpClient.get('/live-streams/$streamId/gifts?limit=$limit');
    final data = jsonDecode(response.body);
    final gifts = data['gifts'] as List;
    return gifts.map((g) => GiftTransactionModel.fromJson(g)).toList();
  }

  /// Get gift leaderboard for stream
  Future<List<GiftLeaderboardEntry>> getGiftLeaderboard({
    required String streamId,
    int limit = 10,
  }) async {
    final response = await _httpClient.get('/live-streams/$streamId/gifts/leaderboard?limit=$limit');
    final data = jsonDecode(response.body);
    final leaderboard = data['leaderboard'] as List;
    return leaderboard.map((e) => GiftLeaderboardEntry.fromJson(e)).toList();
  }

  // ==================== SHOP OPERATIONS (Shop Live) ====================

  /// Pin product during shop live
  Future<RefinedLiveStreamModel> pinProduct({
    required String streamId,
    required String productId,
  }) async {
    final response = await _httpClient.post('/live-streams/$streamId/pin-product',
      body: {'productId': productId}
    );

    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }

  /// Unpin product
  Future<RefinedLiveStreamModel> unpinProduct(String streamId) async {
    final response = await _httpClient.post('/live-streams/$streamId/unpin-product');
    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }

  /// Start flash sale during live
  Future<void> startFlashSale({
    required String streamId,
    required String productId,
    required double salePrice,
    required int durationMinutes,
  }) async {
    await _httpClient.post('/live-streams/$streamId/flash-sale/start', body: {
      'productId': productId,
      'salePrice': salePrice,
      'durationMinutes': durationMinutes,
    });
  }

  // ==================== MODERATION ====================

  /// Report a live stream
  Future<void> reportLiveStream({
    required String streamId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    await _httpClient.post('/live-streams/$streamId/report', body: {
      'reporterId': reporterId,
      'reason': reason,
      'details': details,
    });
  }

  /// Block user from stream
  Future<void> blockUser({
    required String streamId,
    required String userId,
  }) async {
    await _httpClient.post('/live-streams/$streamId/block', body: {
      'userId': userId,
    });
  }

  /// Unblock user from stream
  Future<void> unblockUser({
    required String streamId,
    required String userId,
  }) async {
    await _httpClient.post('/live-streams/$streamId/unblock', body: {
      'userId': userId,
    });
  }

  // ==================== STREAM HISTORY ====================

  /// Get user's live stream history (as host)
  Future<List<RefinedLiveStreamModel>> getUserLiveStreams(String userId) async {
    final response = await _httpClient.get('/users/$userId/live-streams');
    final data = jsonDecode(response.body);
    final streams = data['streams'] as List;
    return streams.map((s) => RefinedLiveStreamModel.fromJson(s)).toList();
  }

  /// Get shop's live stream history
  Future<List<RefinedLiveStreamModel>> getShopLiveStreamHistory(String shopId) async {
    final response = await _httpClient.get('/shops/$shopId/live-streams');
    final data = jsonDecode(response.body);
    final streams = data['streams'] as List;
    return streams.map((s) => RefinedLiveStreamModel.fromJson(s)).toList();
  }

  // ==================== STREAM UPDATES ====================

  /// Update live stream (title, description, etc.)
  Future<RefinedLiveStreamModel> updateLiveStream({
    required String streamId,
    String? title,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;

    final response = await _httpClient.put('/live-streams/$streamId', body: body);
    final data = jsonDecode(response.body);
    return RefinedLiveStreamModel.fromJson(data['stream'] ?? data);
  }
}
