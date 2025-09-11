// lib/features/dramas/providers/drama_actions_provider.dart - FIXED VERSION
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/dramas/providers/drama_providers.dart';
import 'package:textgb/features/wallet/providers/wallet_providers.dart';

part 'drama_actions_provider.g.dart';

// Custom exceptions for better error handling (unchanged)
class DramaUnlockException implements Exception {
  final String message;
  final String code;
  
  const DramaUnlockException(this.message, this.code);
  
  @override
  String toString() => message;
}

class InsufficientFundsException extends DramaUnlockException {
  const InsufficientFundsException() : super(
    'Insufficient coins to unlock this drama',
    'INSUFFICIENT_FUNDS'
  );
}

class DramaAlreadyUnlockedException extends DramaUnlockException {
  const DramaAlreadyUnlockedException() : super(
    'This drama is already unlocked',
    'ALREADY_UNLOCKED'
  );
}

class DramaNotFoundException extends DramaUnlockException {
  const DramaNotFoundException() : super(
    'Drama not found or unavailable',
    'DRAMA_NOT_FOUND'
  );
}

class UserNotAuthenticatedException extends DramaUnlockException {
  const UserNotAuthenticatedException() : super(
    'User not authenticated',
    'USER_NOT_AUTHENTICATED'
  );
}

// Enhanced drama actions state with recently unlocked tracking
class DramaActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Set<String> recentlyUnlockedDramas;
  final DateTime? lastUnlockTime;

  const DramaActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.recentlyUnlockedDramas = const {},
    this.lastUnlockTime,
  });

  DramaActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Set<String>? recentlyUnlockedDramas,
    DateTime? lastUnlockTime,
  }) {
    return DramaActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      recentlyUnlockedDramas: recentlyUnlockedDramas ?? this.recentlyUnlockedDramas,
      lastUnlockTime: lastUnlockTime ?? this.lastUnlockTime,
    );
  }

  // Helper method to check if drama was recently unlocked
  bool wasRecentlyUnlocked(String dramaId) {
    return recentlyUnlockedDramas.contains(dramaId);
  }
}

@riverpod
class DramaActions extends _$DramaActions {
  @override
  DramaActionState build() {
    return const DramaActionState();
  }

  // Toggle favorite status of a drama (unchanged)
  Future<void> toggleFavorite(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final repository = ref.read(dramaRepositoryProvider);
      
      final isFavorited = user.hasFavorited(dramaId);
      
      if (isFavorited) {
        await authNotifier.removeFromFavorites(dramaId: dramaId);
        await repository.incrementDramaFavorites(dramaId, false);
        state = state.copyWith(
          isLoading: false, 
          successMessage: Constants.favoriteRemoved
        );
      } else {
        await authNotifier.addToFavorites(dramaId: dramaId);
        await repository.incrementDramaFavorites(dramaId, true);
        state = state.copyWith(
          isLoading: false, 
          successMessage: Constants.favoriteAdded
        );
      }

      ref.invalidate(userFavoriteDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update favorites: $e',
      );
    }
  }

  // ENHANCED ATOMIC DRAMA UNLOCK WITH COMPREHENSIVE REFRESH
  Future<bool> unlockDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(error: 'Please log in to unlock dramas');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final drama = await ref.read(dramaProvider(dramaId).future);
      final dramaTitle = drama?.title ?? 'Premium Drama';
      
      final repository = ref.read(dramaRepositoryProvider);
      final success = await repository.unlockDramaAtomic(
        userId: user.uid,
        dramaId: dramaId,
        unlockCost: Constants.dramaUnlockCost,
        dramaTitle: dramaTitle,
      );

      if (success) {
        // Add to recently unlocked set for immediate UI feedback
        final updatedUnlockedSet = Set<String>.from(state.recentlyUnlockedDramas)..add(dramaId);
        
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Drama unlocked! All episodes are now available.',
          recentlyUnlockedDramas: updatedUnlockedSet,
          lastUnlockTime: DateTime.now(),
        );

        // 🔥 COMPREHENSIVE PROVIDER REFRESH STRATEGY
        await _performComprehensiveRefresh(dramaId);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to unlock drama. Please try again.',
        );
        return false;
      }
    } on InsufficientFundsException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on DramaAlreadyUnlockedException catch (e) {
      state = state.copyWith(isLoading: false, successMessage: 'Drama is already unlocked!');
      return true;
    } on DramaNotFoundException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on UserNotAuthenticatedException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to unlock drama: $e');
      return false;
    }
  }

  // 🔥 COMPREHENSIVE REFRESH STRATEGY
  Future<void> _performComprehensiveRefresh(String dramaId) async {
    try {
      // 1. Refresh authentication state FIRST (most important)
      ref.invalidate(authenticationProvider);
      
      // Wait a moment for auth state to propagate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 2. Refresh wallet/coins providers
      ref.invalidate(walletProvider);
      ref.invalidate(coinsBalanceProvider);
      
      // 3. Refresh user-specific providers
      ref.invalidate(currentUserProvider);
      
      // 4. Refresh specific drama data
      ref.invalidate(dramaProvider(dramaId));
      
      // 5. Refresh drama lists that might contain this drama
      ref.invalidate(allDramasProvider);
      ref.invalidate(featuredDramasProvider);
      ref.invalidate(trendingDramasProvider);
      ref.invalidate(premiumDramasProvider);
      ref.invalidate(continueWatchingDramasProvider);
      ref.invalidate(userFavoriteDramasProvider);
      
      // 6. Refresh unlock status providers specifically
      ref.invalidate(isDramaUnlockedProvider(dramaId));
      ref.invalidate(canAffordDramaUnlockProvider());
      
      // 7. Wait a bit more and do another auth refresh to be absolutely sure
      await Future.delayed(const Duration(milliseconds: 200));
      ref.invalidate(authenticationProvider);
      
    } catch (e) {
      print('Error during comprehensive refresh: $e');
    }
  }

  // Mark episode as watched (unchanged)
  Future<void> markEpisodeWatched(String episodeId, String dramaId, int episodeNumber) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      
      if (!user.hasWatched(episodeId)) {
        await authNotifier.addToWatchHistory(episodeId: episodeId);
      }
      
      final currentProgress = user.getDramaProgress(dramaId);
      if (episodeNumber > currentProgress) {
        await authNotifier.updateDramaProgress(
          dramaId: dramaId, 
          episodeNumber: episodeNumber
        );
      }

      ref.invalidate(continueWatchingDramasProvider);
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to update watch history: $e');
    }
  }

  // Check if user can afford to unlock drama
  bool canAffordUnlock({int? customCost}) {
    final coinsBalance = ref.read(coinsBalanceProvider);
    final cost = customCost ?? Constants.dramaUnlockCost;
    return coinsBalance != null && coinsBalance >= cost;
  }

  // Get user's coin balance for display
  int? getUserCoinsBalance() {
    return ref.read(coinsBalanceProvider);
  }

  // Check if drama was recently unlocked (for immediate UI feedback)
  bool wasRecentlyUnlocked(String dramaId) {
    return state.recentlyUnlockedDramas.contains(dramaId);
  }

  // Clear recently unlocked status (call this when navigating away or after some time)
  void clearRecentlyUnlocked(String dramaId) {
    final updatedSet = Set<String>.from(state.recentlyUnlockedDramas)..remove(dramaId);
    state = state.copyWith(recentlyUnlockedDramas: updatedSet);
  }

  // Clear any messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  // Force refresh all drama-related data (useful for pull-to-refresh)
  Future<void> forceRefreshAll() async {
    ref.invalidate(authenticationProvider);
    ref.invalidate(currentUserProvider);
    ref.invalidate(walletProvider);
    ref.invalidate(coinsBalanceProvider);
    ref.invalidate(allDramasProvider);
    ref.invalidate(featuredDramasProvider);
    ref.invalidate(trendingDramasProvider);
    ref.invalidate(freeDramasProvider);
    ref.invalidate(premiumDramasProvider);
    ref.invalidate(continueWatchingDramasProvider);
    ref.invalidate(userFavoriteDramasProvider);
    
    state = state.copyWith(recentlyUnlockedDramas: {});
  }
}

// ADMIN ACTION PROVIDERS (unchanged)
@riverpod
class AdminDramaActions extends _$AdminDramaActions {
  @override
  DramaActionState build() {
    return const DramaActionState();
  }

  Future<void> toggleFeatured(String dramaId, bool isFeatured) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isVerified) {
      state = state.copyWith(error: Constants.verifiedOnly);
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

      ref.invalidate(userDramasProvider);
      ref.invalidate(featuredDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle featured status: $e',
      );
    }
  }

  Future<void> toggleActive(String dramaId, bool isActive) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isVerified) {
      state = state.copyWith(error: Constants.verifiedOnly);
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

      ref.invalidate(userDramasProvider);
      ref.invalidate(allDramasProvider);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle active status: $e',
      );
    }
  }

  Future<void> deleteDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isVerified) {
      state = state.copyWith(error: Constants.verifiedOnly);
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

      ref.invalidate(userDramasProvider);
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

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

// ENHANCED PROVIDERS WITH BETTER UNLOCK STATUS CHECKING

// Enhanced unlock status provider that checks recently unlocked dramas
@riverpod
bool isDramaUnlockedEnhanced(IsDramaUnlockedEnhancedRef ref, String dramaId) {
  // First check if it was recently unlocked for immediate UI feedback
  final actionState = ref.watch(dramaActionsProvider);
  if (actionState.wasRecentlyUnlocked(dramaId)) {
    return true;
  }
  
  // Then check the actual user state
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  return user?.hasUnlocked(dramaId) ?? false;
}

// Enhanced can watch episode provider
@riverpod
bool canWatchDramaEpisodeEnhanced(CanWatchDramaEpisodeEnhancedRef ref, String dramaId, int episodeNumber) {
  final user = ref.watch(currentUserProvider);
  final drama = ref.watch(dramaProvider(dramaId));
  
  // Check if recently unlocked for immediate UI feedback
  final actionState = ref.watch(dramaActionsProvider);
  final recentlyUnlocked = actionState.wasRecentlyUnlocked(dramaId);
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null || user == null) return false;
      
      // If recently unlocked, allow watching all episodes
      if (recentlyUnlocked) return true;
      
      return dramaModel.canWatchEpisode(episodeNumber, user.hasUnlocked(dramaId));
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// CONVENIENCE ACTION PROVIDERS (using existing providers where possible)

@riverpod
bool canWatchDramaEpisode(CanWatchDramaEpisodeRef ref, String dramaId, int episodeNumber) {
  return ref.watch(canWatchDramaEpisodeEnhancedProvider(dramaId, episodeNumber));
}

@riverpod
bool canAffordDramaUnlock(CanAffordDramaUnlockRef ref, {int? customCost}) {
  final coinsBalance = ref.watch(coinsBalanceProvider);
  final cost = customCost ?? Constants.dramaUnlockCost;
  return coinsBalance != null && coinsBalance >= cost;
}

@riverpod
int dramaUnlockCost(DramaUnlockCostRef ref, {int? customCost}) {
  return customCost ?? Constants.dramaUnlockCost;
}

@riverpod
int nextEpisodeToWatch(NextEpisodeToWatchRef ref, String dramaId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 1;
  
  final progress = user.getDramaProgress(dramaId);
  return progress + 1;
}

// Fixed episode requires unlock provider
@riverpod
bool episodeRequiresUnlock(EpisodeRequiresUnlockRef ref, String dramaId, int episodeNumber) {
  final user = ref.watch(currentUserProvider);
  final drama = ref.watch(dramaProvider(dramaId));
  
  // Check if recently unlocked for immediate UI feedback
  final actionState = ref.watch(dramaActionsProvider);
  if (actionState.wasRecentlyUnlocked(dramaId)) {
    return false; // No unlock required if recently unlocked
  }
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null || user == null) return false;
      
      if (!dramaModel.isPremium) return false;
      if (user.hasUnlocked(dramaId)) return false;
      if (episodeNumber <= dramaModel.freeEpisodesCount) return false;
      
      return true;
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

@riverpod
int? coinsAfterUnlock(CoinsAfterUnlockRef ref, int unlockCost) {
  final currentBalance = ref.watch(coinsBalanceProvider);
  if (currentBalance == null) return null;
  
  final remaining = currentBalance - unlockCost;
  return remaining >= 0 ? remaining : null;
}