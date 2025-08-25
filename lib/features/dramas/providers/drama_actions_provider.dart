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

  // Unlock a premium drama
  Future<bool> unlockDrama(String dramaId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    // Check if user has enough coins
    if (!user.canAfford(Constants.dramaUnlockCost)) {
      state = state.copyWith(
        error: Constants.insufficientCoins,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final walletNotifier = ref.read(walletProvider.notifier);
      
      // Deduct coins from wallet
      final purchaseSuccess = await walletNotifier.makePurchase(
        amount: Constants.dramaUnlockCost.toDouble(),
        description: 'Unlock Drama',
        referenceId: dramaId,
      );

      if (!purchaseSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: 'Payment failed. Please try again.',
        );
        return false;
      }

      // Add drama to user's unlocked dramas
      await authNotifier.unlockDrama(dramaId: dramaId);

      state = state.copyWith(
        isLoading: false,
        successMessage: Constants.dramaUnlocked,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to unlock drama: $e',
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

// Quick action to check if drama can be watched
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

// Quick action to get next episode to watch for a drama
@riverpod
int nextEpisodeToWatch(NextEpisodeToWatchRef ref, String dramaId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 1;
  
  final progress = user.getDramaProgress(dramaId);
  return progress + 1; // Next episode after last watched
}