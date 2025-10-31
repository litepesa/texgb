// lib/features/live_streaming/providers/live_streaming_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/live_streaming/repositories/live_stream_repository.dart';
import 'package:textgb/features/live_streaming/services/agora_service.dart';
import 'package:textgb/features/live_streaming/models/refined_live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';
import 'package:textgb/features/live_streaming/models/live_stream_model.dart';
import 'package:textgb/features/live_streaming/models/gift_transaction_model.dart';

part 'live_streaming_providers.g.dart';

// ==================== REPOSITORY PROVIDER ====================

@riverpod
LiveStreamRepository liveStreamRepository(LiveStreamRepositoryRef ref) {
  return LiveStreamRepository();
}

// ==================== AGORA SERVICE PROVIDER ====================

@riverpod
class AgoraServiceProvider extends _$AgoraServiceProvider {
  @override
  AgoraService build() {
    final service = AgoraService();

    // Dispose when provider is disposed
    ref.onDispose(() {
      service.dispose();
    });

    return service;
  }

  /// Initialize Agora with app ID
  Future<void> initialize(String appId) async {
    await state.initialize(appId: appId);
  }

  /// Start broadcasting as host
  Future<void> startBroadcasting({
    required String channelName,
    required String token,
    int uid = 0,
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    await state.startBroadcasting(
      channelName: channelName,
      token: token,
      uid: uid,
      enableVideo: enableVideo,
      enableAudio: enableAudio,
    );
  }

  /// Join as audience
  Future<void> joinAsAudience({
    required String channelName,
    required String token,
    int uid = 0,
  }) async {
    await state.joinAsAudience(
      channelName: channelName,
      token: token,
      uid: uid,
    );
  }

  /// Stop broadcasting
  Future<void> stopBroadcasting() async {
    await state.stopBroadcasting();
  }

  /// Leave channel
  Future<void> leaveChannel() async {
    await state.leaveChannel();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    await state.switchCamera();
  }

  /// Toggle video
  Future<void> toggleVideo(bool enable) async {
    await state.toggleVideo(enable);
  }

  /// Toggle audio
  Future<void> toggleAudio(bool enable) async {
    await state.toggleAudio(enable);
  }

  /// Set video quality
  Future<void> setVideoQuality(VideoQualityPreset preset) async {
    await state.setVideoQuality(preset);
  }

  /// Renew token
  Future<void> renewToken(String newToken) async {
    await state.renewToken(newToken);
  }
}

// ==================== LIVE STREAM PROVIDERS ====================

/// Get specific live stream
@riverpod
Future<RefinedLiveStreamModel> liveStream(
  LiveStreamRef ref,
  String streamId,
) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getLiveStream(streamId);
}

/// Get all live streams
@riverpod
Future<List<RefinedLiveStreamModel>> liveStreams(
  LiveStreamsRef ref, {
  int limit = 20,
  int offset = 0,
  LiveStreamType? type,
  LiveStreamCategory? category,
}) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getLiveStreams(
    limit: limit,
    offset: offset,
    type: type,
    category: category,
  );
}

/// Get gift live streams
@riverpod
Future<List<RefinedLiveStreamModel>> giftLiveStreams(
  GiftLiveStreamsRef ref, {
  int limit = 20,
}) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getGiftLiveStreams(limit: limit);
}

/// Get shop live streams
@riverpod
Future<List<RefinedLiveStreamModel>> shopLiveStreams(
  ShopLiveStreamsRef ref, {
  int limit = 20,
}) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getShopLiveStreams(limit: limit);
}

/// Get user's live stream history (as host)
@riverpod
Future<List<RefinedLiveStreamModel>> userLiveStreams(
  UserLiveStreamsRef ref,
  String userId,
) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getUserLiveStreams(userId);
}

/// Get shop's live stream history
@riverpod
Future<List<RefinedLiveStreamModel>> shopLiveStreamHistory(
  ShopLiveStreamHistoryRef ref,
  String shopId,
) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getShopLiveStreamHistory(shopId);
}

// ==================== GIFT PROVIDERS ====================

/// Get gift transactions for a stream
@riverpod
Future<List<GiftTransactionModel>> streamGifts(
  StreamGiftsRef ref,
  String streamId, {
  int limit = 50,
}) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getStreamGifts(streamId: streamId, limit: limit);
}

/// Get gift leaderboard
@riverpod
Future<List<GiftLeaderboardEntry>> giftLeaderboard(
  GiftLeaderboardRef ref,
  String streamId, {
  int limit = 10,
}) async {
  final repository = ref.watch(liveStreamRepositoryProvider);
  return repository.getGiftLeaderboard(streamId: streamId, limit: limit);
}

// ==================== LIVE STREAM STATE MANAGEMENT ====================

/// Current live stream state (for hosts)
@riverpod
class CurrentLiveStream extends _$CurrentLiveStream {
  @override
  RefinedLiveStreamModel? build() {
    return null;
  }

  /// Create and set current live stream
  Future<void> create({
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
    final repository = ref.read(liveStreamRepositoryProvider);

    final stream = await repository.createLiveStream(
      hostId: hostId,
      title: title,
      type: type,
      description: description,
      category: category,
      tags: tags,
      isPrivate: isPrivate,
      shopId: shopId,
      featuredProductIds: featuredProductIds,
      commissionRate: commissionRate,
      giftConfig: giftConfig,
    );

    state = stream;
  }

  /// Start the current live stream
  Future<void> start() async {
    if (state == null) {
      throw Exception('No live stream to start');
    }

    final repository = ref.read(liveStreamRepositoryProvider);
    final updatedStream = await repository.startLiveStream(state!.id);
    state = updatedStream;
  }

  /// End the current live stream
  Future<void> end() async {
    if (state == null) {
      throw Exception('No live stream to end');
    }

    final repository = ref.read(liveStreamRepositoryProvider);
    await repository.endLiveStream(state!.id);
    state = null;
  }

  /// Update stream details
  Future<void> update({
    String? title,
    String? description,
  }) async {
    if (state == null) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    final updatedStream = await repository.updateLiveStream(
      streamId: state!.id,
      title: title,
      description: description,
    );
    state = updatedStream;
  }

  /// Pin product (for shop streams)
  Future<void> pinProduct(String productId) async {
    if (state == null || state!.type != LiveStreamType.shop) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    final updatedStream = await repository.pinProduct(
      streamId: state!.id,
      productId: productId,
    );
    state = updatedStream;
  }

  /// Unpin product
  Future<void> unpinProduct() async {
    if (state == null || state!.type != LiveStreamType.shop) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    final updatedStream = await repository.unpinProduct(state!.id);
    state = updatedStream;
  }

  /// Start flash sale
  Future<void> startFlashSale({
    required String productId,
    required double salePrice,
    required int durationMinutes,
  }) async {
    if (state == null || state!.type != LiveStreamType.shop) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    await repository.startFlashSale(
      streamId: state!.id,
      productId: productId,
      salePrice: salePrice,
      durationMinutes: durationMinutes,
    );

    // Refresh stream data
    final updatedStream = await repository.getLiveStream(state!.id);
    state = updatedStream;
  }

  /// Clear current stream
  void clear() {
    state = null;
  }
}

/// Joined live stream state (for viewers)
@riverpod
class JoinedLiveStream extends _$JoinedLiveStream {
  @override
  RefinedLiveStreamModel? build() {
    return null;
  }

  /// Join a live stream as viewer
  Future<Map<String, dynamic>> join(String streamId, String userId) async {
    final repository = ref.read(liveStreamRepositoryProvider);

    final result = await repository.joinLiveStream(streamId, userId);
    state = result['stream'] as RefinedLiveStreamModel;

    return {
      'agoraToken': result['agoraToken'],
      'agoraUid': result['agoraUid'],
    };
  }

  /// Leave current live stream
  Future<void> leave(String userId) async {
    if (state == null) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    await repository.leaveLiveStream(state!.id, userId);
    state = null;
  }

  /// Send gift (for gift streams)
  Future<GiftTransactionModel> sendGift({
    required String senderId,
    required String giftId,
    int quantity = 1,
    String? message,
    bool isAnonymous = false,
  }) async {
    if (state == null || state!.type != LiveStreamType.gift) {
      throw Exception('Not in a gift live stream');
    }

    final repository = ref.read(liveStreamRepositoryProvider);
    return repository.sendGift(
      streamId: state!.id,
      senderId: senderId,
      giftId: giftId,
      quantity: quantity,
      message: message,
      isAnonymous: isAnonymous,
    );
  }

  /// Refresh stream data
  Future<void> refresh() async {
    if (state == null) return;

    final repository = ref.read(liveStreamRepositoryProvider);
    final updatedStream = await repository.getLiveStream(state!.id);
    state = updatedStream;
  }

  /// Clear joined stream
  void clear() {
    state = null;
  }
}

// ==================== VIEWER COUNT PROVIDER ====================

/// Stream viewer count (real-time)
@riverpod
class StreamViewerCount extends _$StreamViewerCount {
  @override
  int build(String streamId) {
    // Initial value, will be updated via real-time updates
    return 0;
  }

  void update(int count) {
    state = count;
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }
}

// ==================== LIVE STREAMING SETTINGS ====================

/// Live streaming settings (video quality, etc.)
@riverpod
class LiveStreamSettings extends _$LiveStreamSettings {
  @override
  LiveStreamSettingsState build() {
    return const LiveStreamSettingsState(
      videoQuality: VideoQualityPreset.high,
      isCameraOn: true,
      isMicOn: true,
      isFrontCamera: true,
    );
  }

  void setVideoQuality(VideoQualityPreset quality) {
    state = state.copyWith(videoQuality: quality);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOn: !state.isCameraOn);
  }

  void toggleMic() {
    state = state.copyWith(isMicOn: !state.isMicOn);
  }

  void switchCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }
}

// ==================== SETTINGS STATE ====================

class LiveStreamSettingsState {
  final VideoQualityPreset videoQuality;
  final bool isCameraOn;
  final bool isMicOn;
  final bool isFrontCamera;

  const LiveStreamSettingsState({
    required this.videoQuality,
    required this.isCameraOn,
    required this.isMicOn,
    required this.isFrontCamera,
  });

  LiveStreamSettingsState copyWith({
    VideoQualityPreset? videoQuality,
    bool? isCameraOn,
    bool? isMicOn,
    bool? isFrontCamera,
  }) {
    return LiveStreamSettingsState(
      videoQuality: videoQuality ?? this.videoQuality,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isMicOn: isMicOn ?? this.isMicOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }
}
