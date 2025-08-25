// lib/features/dramas/providers/drama_actions_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';

part 'drama_actions_provider.g.dart';

// Drama actions state
class DramaActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const DramaActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  DramaActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return DramaActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

@riverpod
class DramaActions extends _$DramaActions {
  @override
  DramaActionState build() {
    return const DramaActionState();
  }

  // Toggle favorite status of a drama
  Future<void> toggleFavorite(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final repository = ref.read(dramaRepositoryProvider);
      
      final isFavorited = user.hasFavorited(dramaId);
      
      if (isFavorited) {
        // Remove from favorites
        await authNotifier.removeFromFavorites(dramaId: dramaId);
        await repository.incrementDramaFavorites(dramaId, false);
        state = state.copyWith(
          isLoading: false, 
          successMessage: Constants.favoriteRemoved
        );
      } else {
        // Add to favorites
        await authNotifier.addToFavorites(dramaId: dramaId);
        await repository.incrementDramaFavorites(dramaId, true);
        state = state.copyWith(
          isLoading: false, 
          successMessage: Constants.favoriteAdded
        );
      }

      // Refresh relevant providers
      ref.invalidate(userFavoriteDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update favorites: $e',
      );
    }
  }

  // Request drama unlock (backend handles the actual deduction)
  Future<bool> unlockDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    // Check if user has enough coins (read-only check)
    final coinsBalance = ref.read(coinsBalanceProvider);
    final unlockCost = Constants.dramaUnlockCost;
    
    if (coinsBalance == null || coinsBalance < unlockCost) {
      state = state.copyWith(
        error: 'Insufficient coins. You need $unlockCost coins to unlock this drama.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletNotifier = ref.read(walletProvider.notifier);
      
      // Get drama info for transaction description
      final drama = await ref.read(dramaProvider(dramaId).future);
      final dramaTitle = drama?.title ?? 'Premium Drama';
      
      // Send unlock request to backend - backend will handle the actual deduction
      final success = await walletNotifier.requestEpisodeUnlock(
        coinAmount: unlockCost,
        episodeId: dramaId, // Using dramaId as reference for drama unlock
        episodeTitle: 'Drama: $dramaTitle',
      );

      if (success) {
        // Drama unlock is processed automatically by backend!
        // User gets immediate access to all premium episodes
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Drama unlocked! All premium episodes are now available.',
        );

        // Add drama to user's unlocked dramas (backend would normally handle this too)
        final authNotifier = ref.read(authenticationProvider.notifier);
        await authNotifier.unlockDrama(dramaId: dramaId);

        // Refresh wallet to get updated balance from backend
        await ref.read(walletProvider.notifier).refresh();
        
        // Refresh relevant providers
        ref.invalidate(continueWatchingDramasProvider);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to submit unlock request. Please try again.',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlock drama: $e',
      );
      return false;
    }
  }

  // Request episode unlock (backend handles the actual deduction)
  Future<bool> unlockEpisode({
    required String episodeId,
    required String dramaId,
    required int episodeNumber,
    required String episodeTitle,
    int? customCost,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    // Default episode unlock cost (can be customized per drama/episode)
    final unlockCost = customCost ?? Constants.episodeUnlockCost;
    
    // Check if user has enough coins (read-only check)
    final coinsBalance = ref.read(coinsBalanceProvider);
    if (coinsBalance == null || coinsBalance < unlockCost) {
      state = state.copyWith(
        error: 'Insufficient coins. You need $unlockCost coins to unlock this episode.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final walletNotifier = ref.read(walletProvider.notifier);
      
      // Send unlock request to backend - backend will handle the actual deduction
      final success = await walletNotifier.requestEpisodeUnlock(
        coinAmount: unlockCost,
        episodeId: episodeId,
        episodeTitle: 'Episode $episodeNumber: $episodeTitle',
      );

      if (success) {
        // Episode unlock is processed automatically by backend!
        // No waiting - user can watch immediately
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Episode unlocked successfully! Enjoy watching.',
        );

        // Mark episode as watched since unlocking grants immediate access
        await markEpisodeWatched(episodeId, dramaId, episodeNumber);
        
        // Refresh wallet to get updated balance from backend
        await ref.read(walletProvider.notifier).refresh();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to submit unlock request. Please try again.',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlock episode: $e',
      );
      return false;
    }
  }

  // Mark episode as watched
  Future<void> markEpisodeWatched(String episodeId, String dramaId, int episodeNumber) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      
      // Add to watch history if not already there
      if (!user.hasWatched(episodeId)) {
        await authNotifier.addToWatchHistory(episodeId: episodeId);
      }
      
      // Update drama progress (highest episode watched)
      final currentProgress = user.getDramaProgress(dramaId);
      if (episodeNumber > currentProgress) {
        await authNotifier.updateDramaProgress(
          dramaId: dramaId, 
          episodeNumber: episodeNumber
        );
      }

      // Refresh continue watching
      ref.invalidate(continueWatchingDramasProvider);
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to update watch history: $e');
    }
  }

  // Check if user can afford to unlock drama/episode
  bool canAffordUnlock({int? customCost}) {
    final coinsBalance = ref.read(coinsBalanceProvider);
    final cost = customCost ?? Constants.dramaUnlockCost;
    return coinsBalance != null && coinsBalance >= cost;
  }

  // Get user's coin balance for display
  int? getUserCoinsBalance() {
    return ref.read(coinsBalanceProvider);
  }

  // Clear any messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// ADMIN ACTION PROVIDERS (only for admin users)

@riverpod
class AdminDramaActions extends _$AdminDramaActions {
  @override
  DramaActionState build() {
    return const DramaActionState();
  }

  // Toggle drama featured status
  Future<void> toggleFeatured(String dramaId, bool isFeatured) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      state = state.copyWith(error: Constants.adminOnly);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(dramaRepositoryProvider);
      await repository.toggleDramaFeatured(dramaId, isFeatured);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: isFeatured ? 'Drama featured' : 'Drama unfeatured',
      );

      // Refresh admin dramas and featured dramas
      ref.invalidate(adminDramasProvider);
      ref.invalidate(featuredDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle featured status: $e',
      );
    }
  }

  // Toggle drama active status
  Future<void> toggleActive(String dramaId, bool isActive) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      state = state.copyWith(error: Constants.adminOnly);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(dramaRepositoryProvider);
      await repository.toggleDramaActive(dramaId, isActive);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: isActive ? 'Drama activated' : 'Drama deactivated',
      );

      // Refresh relevant providers
      ref.invalidate(adminDramasProvider);
      ref.invalidate(allDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle active status: $e',
      );
    }
  }

  // Delete a drama (admin only)
  Future<void> deleteDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isAdmin) {
      state = state.copyWith(error: Constants.adminOnly);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(dramaRepositoryProvider);
      await repository.deleteDrama(dramaId);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Drama deleted successfully',
      );

      // Refresh all drama lists
      ref.invalidate(adminDramasProvider);
      ref.invalidate(allDramasProvider);
      ref.invalidate(featuredDramasProvider);
      ref.invalidate(trendingDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete drama: $e',
      );
    }
  }

  // Clear any messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// CONVENIENCE ACTION PROVIDERS

// Check if user can watch a specific drama episode
@riverpod
bool canWatchDramaEpisode(CanWatchDramaEpisodeRef ref, String dramaId, int episodeNumber) {
  final user = ref.watch(currentUserProvider);
  final drama = ref.watch(dramaProvider(dramaId));
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null || user == null) return false;
      return dramaModel.canWatchEpisode(episodeNumber, user.hasUnlocked(dramaId));
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// Check if user can afford to unlock an episode
@riverpod
bool canAffordEpisodeUnlock(CanAffordEpisodeUnlockRef ref, {int? customCost}) {
  final coinsBalance = ref.watch(coinsBalanceProvider);
  final cost = customCost ?? Constants.episodeUnlockCost;
  return coinsBalance != null && coinsBalance >= cost;
}

// Check if user can afford to unlock a drama
@riverpod
bool canAffordDramaUnlock(CanAffordDramaUnlockRef ref, {int? customCost}) {
  final coinsBalance = ref.watch(coinsBalanceProvider);
  final cost = customCost ?? Constants.dramaUnlockCost;
  return coinsBalance != null && coinsBalance >= cost;
}

// Get unlock cost for display in UI
@riverpod
int episodeUnlockCost(EpisodeUnlockCostRef ref, {int? customCost}) {
  return customCost ?? Constants.episodeUnlockCost;
}

@riverpod
int dramaUnlockCost(DramaUnlockCostRef ref, {int? customCost}) {
  return customCost ?? Constants.dramaUnlockCost;
}

// Quick action to get next episode to watch for a drama
@riverpod
int nextEpisodeToWatch(NextEpisodeToWatchRef ref, String dramaId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 1;
  
  final progress = user.getDramaProgress(dramaId);
  return progress + 1; // Next episode after last watched
}

// Check if episode requires unlock (premium episode that user hasn't unlocked)
@riverpod
bool episodeRequiresUnlock(EpisodeRequiresUnlockRef ref, String dramaId, int episodeNumber) {
  final user = ref.watch(currentUserProvider);
  final drama = ref.watch(dramaProvider(dramaId));
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null || user == null) return false;
      
      // If drama is not premium, no unlock needed
      if (!dramaModel.isPremium) return false;
      
      // If user has unlocked the entire drama, no unlock needed
      if (user.hasUnlocked(dramaId)) return false;
      
      // If episode is within free episodes count, no unlock needed
      if (episodeNumber <= dramaModel.freeEpisodesCount) return false;
      
      // Episode requires unlock
      return true;
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// Get remaining coins after potential unlock
@riverpod
int? coinsAfterUnlock(CoinsAfterUnlockRef ref, int unlockCost) {
  final currentBalance = ref.watch(coinsBalanceProvider);
  if (currentBalance == null) return null;
  
  final remaining = currentBalance - unlockCost;
  return remaining >= 0 ? remaining : null; // Return null if insufficient
}