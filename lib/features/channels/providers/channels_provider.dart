// lib/features/channels/providers/channels_provider.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/channel_model.dart';
import '../repositories/channel_repository.dart';

// Provider for the repository
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return FirebaseChannelRepository();
});

// Define the channels state
class ChannelsState {
  final bool isLoading;
  final List<ChannelModel> channels;
  final List<String> followedChannels;
  final ChannelModel? userChannel;
  final String? error;
  final bool isCreatingChannel;
  final double uploadProgress;
  final bool isEnsuring; // NEW: For auto-creation loading state

  const ChannelsState({
    this.isLoading = false,
    this.channels = const [],
    this.followedChannels = const [],
    this.userChannel,
    this.error,
    this.isCreatingChannel = false,
    this.uploadProgress = 0.0,
    this.isEnsuring = false,
  });

  ChannelsState copyWith({
    bool? isLoading,
    List<ChannelModel>? channels,
    List<String>? followedChannels,
    ChannelModel? userChannel,
    String? error,
    bool? isCreatingChannel,
    double? uploadProgress,
    bool? isEnsuring,
  }) {
    return ChannelsState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      followedChannels: followedChannels ?? this.followedChannels,
      userChannel: userChannel ?? this.userChannel,
      error: error,
      isCreatingChannel: isCreatingChannel ?? this.isCreatingChannel,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isEnsuring: isEnsuring ?? this.isEnsuring,
    );
  }
}

// Create the channels provider
class ChannelsNotifier extends StateNotifier<ChannelsState> {
  final ChannelRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChannelsNotifier(this._repository) : super(const ChannelsState()) {
    // Initialize with empty state and load data
    loadChannels();
    loadUserChannel();
    loadFollowedChannels();
  }

  // Load channels from repository
  Future<void> loadChannels({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have channels, just return
    if (!forceRefresh && state.channels.isNotEmpty) {
      return;
    }
    
    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      final channels = await _repository.getChannels(forceRefresh: forceRefresh);
      
      // Update state with channels
      state = state.copyWith(
        channels: channels,
        isLoading: false,
      );
    } on RepositoryException catch (e) {
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Load user's channel if they have one
  Future<void> loadUserChannel() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final userChannel = await _repository.getUserChannel(uid);
      state = state.copyWith(userChannel: userChannel);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // NEW: Ensure user has a channel (auto-create if needed)
  Future<ChannelModel?> ensureUserHasChannel() async {
    if (_auth.currentUser == null) return null;
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Check if user already has a channel
      if (state.userChannel != null) {
        debugPrint('DEBUG: User already has channel: ${state.userChannel!.id}');
        return state.userChannel;
      }

      // Show "Setting up your channel..." message
      state = state.copyWith(isEnsuring: true);
      debugPrint('DEBUG: Auto-creating channel for user $uid');

      // Let repository handle the auto-creation with proper safeguards
      final channel = await _repository.ensureUserHasChannel(uid);
      
      // Update state with the channel
      state = state.copyWith(
        userChannel: channel,
        isEnsuring: false,
        channels: [channel, ...state.channels], // Add to channels list
      );

      debugPrint('DEBUG: Channel ensured successfully: ${channel.id}');
      return channel;
    } on RepositoryException catch (e) {
      debugPrint('ERROR: Failed to ensure channel: ${e.message}');
      state = state.copyWith(
        error: e.message,
        isEnsuring: false,
      );
      return null;
    } catch (e) {
      debugPrint('ERROR: Failed to ensure channel: $e');
      state = state.copyWith(
        error: e.toString(),
        isEnsuring: false,
      );
      return null;
    }
  }

  // Load channels followed by the user
  Future<void> loadFollowedChannels() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final followedChannels = await _repository.getFollowedChannels(uid);
      state = state.copyWith(followedChannels: followedChannels);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // REMOVED: Manual createChannel method - replaced with auto-creation

  // Follow or unfollow a channel
  Future<void> toggleFollowChannel(String channelId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Get current followed channels
      List<String> followedChannels = List.from(state.followedChannels);
      bool isCurrentlyFollowed = followedChannels.contains(channelId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyFollowed) {
        followedChannels.remove(channelId);
        await _repository.unfollowChannel(channelId, uid);
      } else {
        followedChannels.add(channelId);
        await _repository.followChannel(channelId, uid);
      }
      
      // Update channels list with new follow status
      final updatedChannels = state.channels.map((channel) {
        if (channel.id == channelId) {
          return channel.copyWith(
            followers: isCurrentlyFollowed ? channel.followers - 1 : channel.followers + 1,
            followerUIDs: isCurrentlyFollowed
                ? (channel.followerUIDs..remove(uid))
                : (channel.followerUIDs..add(uid)),
          );
        }
        return channel;
      }).toList();
      
      state = state.copyWith(
        channels: updatedChannels,
        followedChannels: followedChannels,
      );
      
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
      // Revert the optimistic update on error
      loadChannels();
      loadFollowedChannels();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Revert the optimistic update on error
      loadChannels();
      loadFollowedChannels();
    }
  }

  // Get a specific channel by ID
  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      return await _repository.getChannelById(channelId);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update a channel
  Future<void> updateChannel({
    required ChannelModel channel,
    File? profileImage,
    File? coverImage,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (channel.ownerId != _auth.currentUser!.uid) {
      onError('You can only update your own channel');
      return;
    }
    
    state = state.copyWith(isCreatingChannel: true, uploadProgress: 0.0);
    
    try {
      String profileImageUrl = channel.profileImage;
      String coverImageUrl = channel.coverImage;
      
      // Upload new profile image if provided
      if (profileImage != null) {
        profileImageUrl = await _repository.uploadImage(
          profileImage, 
          'channelImages/${channel.id}/profile.jpg'
        );
        state = state.copyWith(uploadProgress: 0.5);
      }
      
      // Upload new cover image if provided
      if (coverImage != null) {
        coverImageUrl = await _repository.uploadImage(
          coverImage, 
          'channelImages/${channel.id}/cover.jpg'
        );
        state = state.copyWith(uploadProgress: 1.0);
      }
      
      // Update channel
      final updatedChannel = await _repository.updateChannel(
        channel: channel,
        profileImageUrl: profileImageUrl,
        coverImageUrl: coverImageUrl,
      );
      
      // Update channels list
      final updatedChannels = state.channels.map((c) {
        if (c.id == channel.id) {
          return updatedChannel;
        }
        return c;
      }).toList();
      
      state = state.copyWith(
        userChannel: updatedChannel,
        channels: updatedChannels,
        isCreatingChannel: false,
        uploadProgress: 0.0,
      );
      
      onSuccess('Channel updated successfully');
    } on RepositoryException catch (e) {
      state = state.copyWith(
        isCreatingChannel: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
    } catch (e) {
      state = state.copyWith(
        isCreatingChannel: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }

  // Delete a channel (mark as inactive)
  Future<void> deleteChannel(String channelId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      await _repository.deleteChannel(channelId, uid);
      
      // Update local state
      final updatedChannels = state.channels.where((c) => c.id != channelId).toList();
      
      state = state.copyWith(
        userChannel: null,
        channels: updatedChannels,
      );
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Get user's following count
  int get followingCount => state.followedChannels.length;
}

// Provider definition
final channelsProvider = StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  final repository = ref.watch(channelRepositoryProvider);
  return ChannelsNotifier(repository);
});