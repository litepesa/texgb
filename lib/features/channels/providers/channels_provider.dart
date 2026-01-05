// lib/features/channels/providers/channels_provider.dart
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/repositories/channel_repository.dart';

part 'channels_provider.g.dart';

// Repository provider
@riverpod
ChannelRepository channelRepository(ChannelRepositoryRef ref) {
  return ChannelRepository();
}

// ============================
// CHANNELS LIST PROVIDERS
// ============================

/// Get all channels (discovery/browse)
@riverpod
class ChannelsList extends _$ChannelsList {
  @override
  Future<List<ChannelModel>> build({
    int page = 1,
    String? type,
    String? search,
  }) async {
    final repository = ref.read(channelRepositoryProvider);
    return repository.getChannels(
      page: page,
      perPage: 20,
      type: type,
      search: search,
    );
  }

  /// Load more channels (pagination)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    final repository = ref.read(channelRepositoryProvider);
    final nextPage = (currentState.length ~/ 20) + 1;

    final newChannels = await repository.getChannels(
      page: nextPage,
      perPage: 20,
    );

    state = AsyncValue.data([...currentState, ...newChannels]);
  }

  /// Refresh channels list
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Get trending channels
@riverpod
Future<List<ChannelModel>> trendingChannels(TrendingChannelsRef ref) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getTrendingChannels(limit: 10);
}

/// Get popular channels
@riverpod
Future<List<ChannelModel>> popularChannels(PopularChannelsRef ref) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getPopularChannels(limit: 10);
}

/// Get user's subscribed channels
@riverpod
Future<List<ChannelModel>> subscribedChannels(SubscribedChannelsRef ref) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getSubscribedChannels();
}

// ============================
// SINGLE CHANNEL PROVIDER
// ============================

/// Get channel by ID
@riverpod
Future<ChannelModel?> channel(ChannelRef ref, String channelId) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getChannelById(channelId);
}

// ============================
// CHANNEL ACTIONS
// ============================

/// Channel actions notifier (create, update, delete, subscribe)
@riverpod
class ChannelActions extends _$ChannelActions {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Create new channel
  /// Returns a Map with either 'channel' (ChannelModel) or 'error' (String) key
  Future<Map<String, dynamic>> createChannel({
    required String name,
    required String description,
    required ChannelType type,
    int? subscriptionPriceCoins,
    File? avatar,
  }) async {
    try {
      final repository = ref.read(channelRepositoryProvider);
      final result = await repository.createChannel(
        name: name,
        description: description,
        type: type,
        subscriptionPriceCoins: subscriptionPriceCoins,
        avatar: avatar,
      );

      if (result['channel'] != null) {
        // Invalidate channels list to refresh
        ref.invalidate(channelsListProvider);
        ref.invalidate(subscribedChannelsProvider);
      }

      return result;
    } catch (e) {
      return {
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Check if a channel name is available
  Future<Map<String, dynamic>> checkNameAvailability(String name) async {
    try {
      final repository = ref.read(channelRepositoryProvider);
      return await repository.checkNameAvailability(name);
    } catch (e) {
      return {
        'available': false,
        'message': 'Error checking availability',
      };
    }
  }

  /// Update channel
  Future<bool> updateChannel(
      String channelId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.updateChannel(channelId, updates);

      if (success) {
        // Invalidate channel to refresh
        ref.invalidate(channelProvider(channelId));
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Delete channel
  Future<bool> deleteChannel(String channelId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.deleteChannel(channelId);

      if (success) {
        // Invalidate all channel lists
        ref.invalidate(channelsListProvider);
        ref.invalidate(subscribedChannelsProvider);
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Subscribe to channel
  Future<bool> subscribe(String channelId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.subscribeToChannel(channelId);

      if (success) {
        // Invalidate channel and subscribed list
        ref.invalidate(channelProvider(channelId));
        ref.invalidate(subscribedChannelsProvider);
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Unsubscribe from channel
  Future<bool> unsubscribe(String channelId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.unsubscribeFromChannel(channelId);

      if (success) {
        // Invalidate channel and subscribed list
        ref.invalidate(channelProvider(channelId));
        ref.invalidate(subscribedChannelsProvider);
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// ============================
// CHANNEL MEMBERS PROVIDER
// ============================

/// Get channel members (admins/moderators)
@riverpod
Future<List<ChannelMember>> channelMembers(
  ChannelMembersRef ref,
  String channelId,
) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getChannelMembers(channelId);
}

/// Channel member actions (add/remove admins/mods)
@riverpod
class ChannelMemberActions extends _$ChannelMemberActions {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Add admin or moderator
  Future<bool> addMember({
    required String channelId,
    required String userId,
    required MemberRole role,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.addChannelMember(
        channelId: channelId,
        userId: userId,
        role: role,
      );

      if (success) {
        ref.invalidate(channelMembersProvider(channelId));
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Remove member
  Future<bool> removeMember({
    required String channelId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.removeChannelMember(
        channelId: channelId,
        userId: userId,
      );

      if (success) {
        ref.invalidate(channelMembersProvider(channelId));
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}
