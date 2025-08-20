// lib/features/authentication/providers/auth_providers.dart (Updated for Channel-based)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';

part 'auth_providers.g.dart';

// Convenience provider to get current channel model
@riverpod
ChannelModel? currentChannel(CurrentChannelRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.channelModel;
}

// Convenience provider to check if user is logged in
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.channelModel != null;
}

// Convenience provider to check loading state
@riverpod
bool isAuthLoading(IsAuthLoadingRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.isLoading ?? false;
}

// Convenience provider to get current channel ID
@riverpod
String? currentChannelId(CurrentChannelIdRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.channelModel?.id;
}

// Convenience provider to get current channel owner ID (equivalent to user ID)
@riverpod
String? currentOwnerId(CurrentOwnerIdRef ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.value?.channelModel?.ownerId;
}