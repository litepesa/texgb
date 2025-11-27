// ===============================
// Status Providers with Riverpod
// Comprehensive state management for status feature
// ===============================

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/features/status/repositories/http_status_repository.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/features/status/services/status_upload_service.dart';
import 'package:image_picker/image_picker.dart';

part 'status_providers.g.dart';

// ===============================
// REPOSITORY PROVIDERS
// ===============================

@riverpod
StatusRepository statusRepository(Ref ref) {
  return HttpStatusRepository();
}

// ===============================
// SERVICE PROVIDERS (for media picking)
// ===============================

@riverpod
ImagePicker imagePicker(Ref ref) {
  return ImagePicker();
}

@riverpod
StatusUploadService statusUploadService(Ref ref) {
  return StatusUploadService();
}

// ===============================
// STATUS FEED STATE
// ===============================

class StatusFeedState {
  final List<StatusGroup> statusGroups;
  final List<StatusModel> myStatuses;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastFetchTime;

  const StatusFeedState({
    this.statusGroups = const [],
    this.myStatuses = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastFetchTime,
  });

  StatusFeedState copyWith({
    List<StatusGroup>? statusGroups,
    List<StatusModel>? myStatuses,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastFetchTime,
  }) {
    return StatusFeedState(
      statusGroups: statusGroups ?? this.statusGroups,
      myStatuses: myStatuses ?? this.myStatuses,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  // Filter active groups
  List<StatusGroup> get activeGroups {
    return StatusTimeService.filterActiveGroups(statusGroups);
  }

  // Get my status group
  StatusGroup? get myStatusGroup {
    if (myStatuses.isEmpty) return null;
    final activeMyStatuses = StatusTimeService.filterActive(myStatuses);
    if (activeMyStatuses.isEmpty) return null;

    // Construct StatusGroup from my statuses
    final firstStatus = activeMyStatuses.first;
    return StatusGroup(
      userId: firstStatus.userId,
      userName: firstStatus.userName,
      userAvatar: firstStatus.userAvatar,
      statuses: activeMyStatuses,
      isMyStatus: true,
    );
  }

  bool get shouldRefresh {
    if (lastFetchTime == null) return true;
    final diff = DateTime.now().difference(lastFetchTime!);
    return diff > StatusConstants.cacheDuration;
  }
}

// ===============================
// STATUS FEED PROVIDER (Main Feed)
// ===============================

@riverpod
class StatusFeed extends _$StatusFeed {
  StatusRepository get _repository => ref.read(statusRepositoryProvider);
  SharedPreferences? _prefs;

  static const String _cacheKey = 'status_feed_cache';
  static const String _myStatusCacheKey = 'my_status_cache';

  @override
  Future<StatusFeedState> build() async {
    _prefs = await SharedPreferences.getInstance();

    // Load from cache first
    final cachedState = await _loadFromCache();
    if (cachedState != null && !cachedState.shouldRefresh) {
      // Return cached data and refresh in background
      _refreshInBackground();
      return cachedState;
    }

    // Fetch fresh data
    return await _fetchStatuses(isRefresh: true);
  }

  // ===============================
  // FETCH STATUSES
  // ===============================

  Future<StatusFeedState> _fetchStatuses({bool isRefresh = false}) async {
    try {
      print('🔄 Fetching statuses (isRefresh: $isRefresh)...');

      // Fetch both all statuses and my statuses
      final results = await Future.wait([
        _repository.getAllStatuses(),
        _repository.getMyStatuses(),
      ]);

      final statusGroups = results[0] as List<StatusGroup>;
      final myStatuses = results[1] as List<StatusModel>;

      print('📥 Fetched ${myStatuses.length} my statuses, ${statusGroups.length} status groups');

      // Filter expired statuses
      final activeGroups = StatusTimeService.filterActiveGroups(statusGroups);
      final activeMyStatuses = StatusTimeService.filterActive(myStatuses);

      print('✅ Active: ${activeMyStatuses.length} my statuses, ${activeGroups.length} groups');

      // Sort groups by latest status
      final sortedGroups = StatusTimeService.sortGroupsByLatest(activeGroups);

      final newState = StatusFeedState(
        statusGroups: sortedGroups,
        myStatuses: activeMyStatuses,
        isLoading: false,
        lastFetchTime: DateTime.now(),
      );

      // Save to cache
      await _saveToCache(newState);

      return newState;
    } catch (e) {
      print('❌ Error fetching statuses: $e');
      return StatusFeedState(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // ===============================
  // REFRESH
  // ===============================

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStatuses(isRefresh: true));
  }

  void _refreshInBackground() async {
    try {
      final newState = await _fetchStatuses(isRefresh: true);
      state = AsyncValue.data(newState);
    } catch (e) {
      // Silent fail - keep showing cached data
      print('Background refresh failed: $e');
    }
  }

  // ===============================
  // INTERACTIONS
  // ===============================

  /// View a status (increment view count)
  Future<void> viewStatus(String statusId) async {
    try {
      await _repository.viewStatus(statusId);

      // Update local state
      state.whenData((currentState) {
        final updatedGroups = currentState.statusGroups.map((group) {
          final updatedStatuses = group.statuses.map((status) {
            if (status.id == statusId) {
              return status.copyWith(
                isViewedByMe: true,
                viewsCount: status.viewsCount + 1,
              );
            }
            return status;
          }).toList();

          return StatusGroup(
            userId: group.userId,
            userName: group.userName,
            userAvatar: group.userAvatar,
            statuses: updatedStatuses,
            isMyStatus: group.isMyStatus,
          );
        }).toList();

        state = AsyncValue.data(currentState.copyWith(statusGroups: updatedGroups));
      });
    } catch (e) {
      print('Error viewing status: $e');
    }
  }

  /// Like a status
  Future<void> toggleLike(String statusId, bool currentlyLiked) async {
    try {
      if (currentlyLiked) {
        await _repository.unlikeStatus(statusId);
      } else {
        await _repository.likeStatus(statusId);
      }

      // Update local state
      state.whenData((currentState) {
        final updatedGroups = currentState.statusGroups.map((group) {
          final updatedStatuses = group.statuses.map((status) {
            if (status.id == statusId) {
              return status.copyWith(
                isLikedByMe: !currentlyLiked,
                likesCount: currentlyLiked ? status.likesCount - 1 : status.likesCount + 1,
              );
            }
            return status;
          }).toList();

          return StatusGroup(
            userId: group.userId,
            userName: group.userName,
            userAvatar: group.userAvatar,
            statuses: updatedStatuses,
            isMyStatus: group.isMyStatus,
          );
        }).toList();

        // Also update my statuses if it's my status
        final updatedMyStatuses = currentState.myStatuses.map((status) {
          if (status.id == statusId) {
            return status.copyWith(
              isLikedByMe: !currentlyLiked,
              likesCount: currentlyLiked ? status.likesCount - 1 : status.likesCount + 1,
            );
          }
          return status;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(
          statusGroups: updatedGroups,
          myStatuses: updatedMyStatuses,
        ));
      });
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  /// Send gift to status owner
  Future<void> sendGift({
    required String statusId,
    required String recipientId,
    required String giftId,
  }) async {
    try {
      final success = await _repository.sendGift(
        statusId: statusId,
        recipientId: recipientId,
        giftId: giftId,
      );

      if (success) {
        // Update gift count
        state.whenData((currentState) {
          final updatedGroups = currentState.statusGroups.map((group) {
            final updatedStatuses = group.statuses.map((status) {
              if (status.id == statusId) {
                return status.copyWith(
                  giftsCount: status.giftsCount + 1,
                );
              }
              return status;
            }).toList();

            return StatusGroup(
              userId: group.userId,
              userName: group.userName,
              userAvatar: group.userAvatar,
              statuses: updatedStatuses,
              isMyStatus: group.isMyStatus,
            );
          }).toList();

          state = AsyncValue.data(currentState.copyWith(statusGroups: updatedGroups));
        });
      }
    } catch (e) {
      print('Error sending gift: $e');
      rethrow;
    }
  }

  /// Delete a status (my status only)
  Future<void> deleteStatus(String statusId) async {
    try {
      final success = await _repository.deleteStatus(statusId);

      if (success) {
        // Remove from local state
        state.whenData((currentState) {
          final updatedMyStatuses = currentState.myStatuses
              .where((s) => s.id != statusId)
              .toList();

          state = AsyncValue.data(currentState.copyWith(
            myStatuses: updatedMyStatuses,
          ));
        });

        // Refresh to get updated data
        await refresh();
      }
    } catch (e) {
      print('Error deleting status: $e');
      rethrow;
    }
  }

  // ===============================
  // CACHE MANAGEMENT
  // ===============================

  Future<StatusFeedState?> _loadFromCache() async {
    if (_prefs == null) return null;

    try {
      final groupsJson = _prefs!.getString(_cacheKey);
      final myStatusJson = _prefs!.getString(_myStatusCacheKey);

      if (groupsJson == null) return null;

      final groupsList = jsonDecode(groupsJson) as List<dynamic>;
      final statusGroups = groupsList
          .map((json) => StatusGroup.fromJson(json as Map<String, dynamic>))
          .toList();

      List<StatusModel> myStatuses = [];
      if (myStatusJson != null) {
        final myStatusList = jsonDecode(myStatusJson) as List<dynamic>;
        myStatuses = myStatusList
            .map((json) => StatusModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return StatusFeedState(
        statusGroups: statusGroups,
        myStatuses: myStatuses,
        lastFetchTime: DateTime.now(),
      );
    } catch (e) {
      print('Error loading from cache: $e');
      return null;
    }
  }

  Future<void> _saveToCache(StatusFeedState state) async {
    if (_prefs == null) return;

    try {
      final groupsJson = jsonEncode(
        state.statusGroups.map((g) => g.toJson()).toList(),
      );
      final myStatusJson = jsonEncode(
        state.myStatuses.map((s) => s.toJson()).toList(),
      );

      await _prefs!.setString(_cacheKey, groupsJson);
      await _prefs!.setString(_myStatusCacheKey, myStatusJson);
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<void> clearCache() async {
    if (_prefs == null) return;
    await _prefs!.remove(_cacheKey);
    await _prefs!.remove(_myStatusCacheKey);
  }
}

// ===============================
// STATUS CREATION PROVIDER
// ===============================

@riverpod
class StatusCreation extends _$StatusCreation {
  StatusRepository get _repository => ref.read(statusRepositoryProvider);

  @override
  FutureOr<void> build() {
    return null;
  }

  /// Create a new status
  Future<StatusModel> createStatus(CreateStatusRequest request) async {
    try {
      final status = await _repository.createStatus(request);

      // Force immediate refresh (bypass cache)
      ref.read(statusFeedProvider.notifier).refresh();

      return status;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload and create image status
  Future<StatusModel> createImageStatus({
    required String imagePath,
    required CreateStatusRequest request,
  }) async {
    try {
      // Upload image using repository
      final uploadResult = await _repository.uploadImageStatus(
        File(imagePath),
      );

      print('📦 Upload result: $uploadResult');

      // Extract URL with null safety
      final mediaUrl = uploadResult['mediaUrl'];

      if (mediaUrl == null) {
        throw Exception('Upload failed: Media URL is null');
      }

      // Create status with media URL
      final statusRequest = CreateStatusRequest(
        content: request.content,
        mediaUrl: mediaUrl,
        mediaType: StatusMediaType.image,
        visibility: request.visibility,
        visibleTo: request.visibleTo,
        hiddenFrom: request.hiddenFrom,
      );

      final status = await _repository.createStatus(statusRequest);

      // Force immediate refresh (bypass cache)
      ref.read(statusFeedProvider.notifier).refresh();

      return status;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload and create video status
  Future<StatusModel> createVideoStatus({
    required String videoPath,
    int? durationSeconds,
    required CreateStatusRequest request,
  }) async {
    try {
      // Upload video and thumbnail using repository
      final uploadResult = await _repository.uploadVideoStatus(
        File(videoPath),
      );

      print('📦 Upload result: $uploadResult');

      // Extract URLs with null safety
      final mediaUrl = uploadResult['mediaUrl'];
      final thumbnailUrl = uploadResult['thumbnailUrl']; // Can be null

      if (mediaUrl == null) {
        throw Exception('Upload failed: Media URL is null');
      }

      // Create status with media URL and thumbnail
      final statusRequest = CreateStatusRequest(
        content: request.content,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl, // Nullable, that's ok
        mediaType: StatusMediaType.video,
        durationSeconds: durationSeconds,
        visibility: request.visibility,
        visibleTo: request.visibleTo,
        hiddenFrom: request.hiddenFrom,
      );

      final status = await _repository.createStatus(statusRequest);

      // Force immediate refresh (bypass cache)
      ref.read(statusFeedProvider.notifier).refresh();

      return status;
    } catch (e) {
      rethrow;
    }
  }
}
