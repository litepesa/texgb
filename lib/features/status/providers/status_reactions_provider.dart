// lib/features/status/providers/status_reactions_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';

part 'status_reactions_provider.g.dart';

// Available emoji reactions for status
class StatusReactions {
  static const List<String> availableReactions = [
    '❤️', '😂', '😮', '😢', '😡', '👍', '👎', '🔥', '💯', '👏'
  ];
  
  static const Map<String, String> reactionNames = {
    '❤️': 'Love',
    '😂': 'Laugh',
    '😮': 'Wow',
    '😢': 'Sad',
    '😡': 'Angry',
    '👍': 'Like',
    '👎': 'Dislike',
    '🔥': 'Fire',
    '💯': 'Perfect',
    '👏': 'Clap',
  };
}

// Status reaction model is now in status_model.dart to avoid circular imports

// Status reactions state
class StatusReactionsState {
  final Map<String, List<StatusReaction>> reactions; // statusUpdateId -> reactions
  final bool isLoading;
  final String? error;

  const StatusReactionsState({
    this.reactions = const {},
    this.isLoading = false,
    this.error,
  });

  StatusReactionsState copyWith({
    Map<String, List<StatusReaction>>? reactions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return StatusReactionsState(
      reactions: reactions ?? this.reactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Helper methods
  List<StatusReaction> getReactionsForUpdate(String statusUpdateId) {
    return reactions[statusUpdateId] ?? [];
  }

  Map<String, int> getReactionCounts(String statusUpdateId) {
    final updateReactions = getReactionsForUpdate(statusUpdateId);
    final counts = <String, int>{};
    
    for (final reaction in updateReactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    
    return counts;
  }

  String? getUserReaction(String statusUpdateId, String userId) {
    final updateReactions = getReactionsForUpdate(statusUpdateId);
    try {
      final userReaction = updateReactions.firstWhere(
        (reaction) => reaction.userId == userId,
      );
      return userReaction.emoji;
    } catch (e) {
      return null;
    }
  }

  bool hasUserReacted(String statusUpdateId, String userId) {
    return getUserReaction(statusUpdateId, userId) != null;
  }

  int getTotalReactionsCount(String statusUpdateId) {
    return getReactionsForUpdate(statusUpdateId).length;
  }

  List<String> getTopReactions(String statusUpdateId, {int limit = 3}) {
    final counts = getReactionCounts(statusUpdateId);
    final sortedReactions = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedReactions
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
}

@riverpod
class StatusReactionsNotifier extends _$StatusReactionsNotifier {
  StatusRepository get _repository => ref.read(statusRepositoryProvider);

  @override
  StatusReactionsState build() {
    return const StatusReactionsState();
  }

  // Add or update reaction to status
  Future<void> addReaction({
    required String statusId,
    required String statusUpdateId,
    required String emoji,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // Remove existing reaction from this user for this status update
      await removeReaction(
        statusId: statusId,
        statusUpdateId: statusUpdateId,
      );

      // Add new reaction
      final reaction = StatusReaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        statusId: statusId,
        statusUpdateId: statusUpdateId,
        userId: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        emoji: emoji,
        timestamp: DateTime.now(),
      );

      await _repository.addStatusReaction(reaction);

      // Update local state
      final currentReactions = Map<String, List<StatusReaction>>.from(state.reactions);
      final updateReactions = List<StatusReaction>.from(
        currentReactions[statusUpdateId] ?? []
      );
      
      // Remove any existing reaction from this user
      updateReactions.removeWhere((r) => r.userId == currentUser.uid);
      
      // Add new reaction
      updateReactions.add(reaction);
      currentReactions[statusUpdateId] = updateReactions;

      state = state.copyWith(
        reactions: currentReactions,
        isLoading: false,
      );

      debugPrint('Reaction added: $emoji for status update: $statusUpdateId');
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add reaction: $e',
      );
    }
  }

  // Remove user's reaction from status
  Future<void> removeReaction({
    required String statusId,
    required String statusUpdateId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.removeStatusReaction(
        statusId: statusId,
        statusUpdateId: statusUpdateId,
        userId: currentUser.uid,
      );

      // Update local state
      final currentReactions = Map<String, List<StatusReaction>>.from(state.reactions);
      final updateReactions = List<StatusReaction>.from(
        currentReactions[statusUpdateId] ?? []
      );
      
      updateReactions.removeWhere((r) => r.userId == currentUser.uid);
      currentReactions[statusUpdateId] = updateReactions;

      state = state.copyWith(reactions: currentReactions);

      debugPrint('Reaction removed for status update: $statusUpdateId');
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      state = state.copyWith(error: 'Failed to remove reaction: $e');
    }
  }

  // Load reactions for multiple status updates
  Future<void> loadReactions(List<String> statusUpdateIds) async {
    if (statusUpdateIds.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final allReactions = <String, List<StatusReaction>>{};

      for (final updateId in statusUpdateIds) {
        final reactions = await _repository.getStatusReactions(updateId);
        allReactions[updateId] = reactions;
      }

      state = state.copyWith(
        reactions: allReactions,
        isLoading: false,
      );

      debugPrint('Loaded reactions for ${statusUpdateIds.length} status updates');
    } catch (e) {
      debugPrint('Error loading reactions: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load reactions: $e',
      );
    }
  }

  // Load reactions for a single status update
  Future<void> loadReactionsForUpdate(String statusUpdateId) async {
    try {
      final reactions = await _repository.getStatusReactions(statusUpdateId);
      
      final currentReactions = Map<String, List<StatusReaction>>.from(state.reactions);
      currentReactions[statusUpdateId] = reactions;

      state = state.copyWith(reactions: currentReactions);

      debugPrint('Loaded ${reactions.length} reactions for update: $statusUpdateId');
    } catch (e) {
      debugPrint('Error loading reactions for update: $e');
      state = state.copyWith(error: 'Failed to load reactions: $e');
    }
  }

  // Stream reactions for real-time updates
  void streamReactions(List<String> statusUpdateIds) {
    for (final updateId in statusUpdateIds) {
      _repository.getStatusReactionsStream(updateId).listen(
        (reactions) {
          final currentReactions = Map<String, List<StatusReaction>>.from(state.reactions);
          currentReactions[updateId] = reactions;
          
          state = state.copyWith(reactions: currentReactions);
        },
        onError: (error) {
          debugPrint('Error streaming reactions for $updateId: $error');
        },
      );
    }
  }

  // Get reaction summary for display
  Map<String, dynamic> getReactionSummary(String statusUpdateId) {
    final reactions = state.getReactionsForUpdate(statusUpdateId);
    final counts = state.getReactionCounts(statusUpdateId);
    final topReactions = state.getTopReactions(statusUpdateId);
    
    return {
      'totalCount': reactions.length,
      'counts': counts,
      'topReactions': topReactions,
      'hasReactions': reactions.isNotEmpty,
    };
  }

  // Toggle reaction (add if not present, remove if present, or change if different)
  Future<void> toggleReaction({
    required String statusId,
    required String statusUpdateId,
    required String emoji,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentUserReaction = state.getUserReaction(statusUpdateId, currentUser.uid);

    if (currentUserReaction == emoji) {
      // Same reaction - remove it
      await removeReaction(
        statusId: statusId,
        statusUpdateId: statusUpdateId,
      );
    } else {
      // Different reaction or no reaction - add/change it
      await addReaction(
        statusId: statusId,
        statusUpdateId: statusUpdateId,
        emoji: emoji,
      );
    }
  }

  // Get users who reacted with specific emoji
  List<StatusReaction> getUsersWithReaction(String statusUpdateId, String emoji) {
    final reactions = state.getReactionsForUpdate(statusUpdateId);
    return reactions.where((reaction) => reaction.emoji == emoji).toList();
  }

  // Clear reactions cache
  void clearReactions() {
    state = const StatusReactionsState();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Get all reactions for a status update
  List<StatusReaction> getAllReactions(String statusUpdateId) {
    return state.getReactionsForUpdate(statusUpdateId);
  }

  // Check if current user has reacted
  bool hasCurrentUserReacted(String statusUpdateId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    return state.hasUserReacted(statusUpdateId, currentUser.uid);
  }

  // Get current user's reaction
  String? getCurrentUserReaction(String statusUpdateId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;
    
    return state.getUserReaction(statusUpdateId, currentUser.uid);
  }

  // Bulk load reactions for status model
  Future<void> loadReactionsForStatus(StatusModel status) async {
    final updateIds = status.activeUpdates.map((update) => update.id).toList();
    await loadReactions(updateIds);
  }

  // Get reaction statistics
  Map<String, dynamic> getReactionStats(String statusUpdateId) {
    final reactions = state.getReactionsForUpdate(statusUpdateId);
    final counts = state.getReactionCounts(statusUpdateId);
    
    return {
      'totalReactions': reactions.length,
      'uniqueEmojis': counts.length,
      'mostPopular': counts.isNotEmpty 
          ? counts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'reactionCounts': counts,
      'recentReactions': reactions
          .take(5)
          .map((r) => {
            'userName': r.userName,
            'emoji': r.emoji,
            'timestamp': r.timestamp,
          })
          .toList(),
    };
  }
}