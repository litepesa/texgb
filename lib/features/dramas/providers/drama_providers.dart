// lib/features/dramas/providers/drama_providers.dart - SIMPLIFIED UNIFIED
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/dramas/models/drama_model.dart';
import 'package:textgb/features/dramas/repositories/drama_repository.dart';


part 'drama_providers.g.dart';

// Repository provider (unchanged)
@riverpod
DramaRepository dramaRepository(DramaRepositoryRef ref) {
  return HttpDramaRepository();
}

// Drama list state (unchanged)
class DramaListState {
  final List<DramaModel> dramas;
  final bool isLoading;
  final bool hasMore;
  final int currentOffset;
  final String? error;

  const DramaListState({
    this.dramas = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentOffset = 0,
    this.error,
  });

  DramaListState copyWith({
    List<DramaModel>? dramas,
    bool? isLoading,
    bool? hasMore,
    int? currentOffset,
    String? error,
  }) {
    return DramaListState(
      dramas: dramas ?? this.dramas,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
      error: error,
    );
  }
}

// ===============================
// CORE DRAMA PROVIDERS (simplified - no episodes)
// ===============================

@riverpod
class FeaturedDramas extends _$FeaturedDramas {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getFeaturedDramas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getFeaturedDramas();
    });
  }
}

@riverpod
class TrendingDramas extends _$TrendingDramas {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getTrendingDramas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getTrendingDramas();
    });
  }
}

@riverpod
class AllDramas extends _$AllDramas {
  @override
  Future<DramaListState> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    try {
      final dramas = await repository.getAllDramas(limit: 20, offset: 0);
      return DramaListState(
        dramas: dramas,
        hasMore: dramas.length >= 20,
        currentOffset: dramas.length,
      );
    } catch (e) {
      return DramaListState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoading || !currentState.hasMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));

    try {
      final repository = ref.read(dramaRepositoryProvider);
      final newDramas = await repository.getAllDramas(
        limit: 20,
        offset: currentState.currentOffset,
      );

      state = AsyncValue.data(currentState.copyWith(
        dramas: [...currentState.dramas, ...newDramas],
        isLoading: false,
        hasMore: newDramas.length >= 20,
        currentOffset: currentState.currentOffset + newDramas.length,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      final dramas = await repository.getAllDramas(limit: 20, offset: 0);
      return DramaListState(
        dramas: dramas,
        hasMore: dramas.length >= 20,
        currentOffset: dramas.length,
      );
    });
  }
}

@riverpod
class FreeDramas extends _$FreeDramas {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getFreeDramas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getFreeDramas();
    });
  }
}

@riverpod
class PremiumDramas extends _$PremiumDramas {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getPremiumDramas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getPremiumDramas();
    });
  }
}

@riverpod
class Drama extends _$Drama {
  @override
  Future<DramaModel?> build(String dramaId) async {
    final repository = ref.read(dramaRepositoryProvider);
    final drama = await repository.getDramaById(dramaId);
    
    // Increment view count when drama is loaded
    if (drama != null) {
      repository.incrementDramaViews(dramaId);
    }
    
    return drama;
  }

  Future<void> refresh() async {
    final dramaId = this.dramaId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getDramaById(dramaId);
    });
  }
}

@riverpod
class SearchDramas extends _$SearchDramas {
  @override
  Future<List<DramaModel>> build(String query) async {
    if (query.trim().isEmpty) return [];
    
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.searchDramas(query);
  }

  Future<void> search(String newQuery) async {
    if (newQuery.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.searchDramas(newQuery);
    });
  }
}

// ===============================
// USER INTERACTION PROVIDERS (simplified)
// ===============================

@riverpod
Future<List<DramaModel>> userFavoriteDramas(UserFavoriteDramasRef ref) async {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  
  if (user == null || user.favoriteDramas.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> favoriteDramas = [];

  for (final dramaId in user.favoriteDramas) {
    try {
      final drama = await repository.getDramaById(dramaId);
      if (drama != null) {
        favoriteDramas.add(drama);
      }
    } catch (e) {
      continue;
    }
  }

  return favoriteDramas;
}

@riverpod
Future<List<DramaModel>> continueWatchingDramas(ContinueWatchingDramasRef ref) async {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  
  if (user == null || user.dramaProgress.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> continueWatchingDramas = [];

  for (final dramaId in user.dramaProgress.keys) {
    try {
      final drama = await repository.getDramaById(dramaId);
      if (drama != null) {
        continueWatchingDramas.add(drama);
      }
    } catch (e) {
      continue;
    }
  }

  return continueWatchingDramas;
}

@riverpod
class AdminDramas extends _$AdminDramas {
  @override
  Future<List<DramaModel>> build() async {
    final authState = ref.watch(authenticationProvider);
    final user = authState.value?.currentUser;
    
    if (user == null || !user.isVerified) return [];

    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramasByAdmin(user.uid);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authenticationProvider);
      final user = authState.value?.currentUser;
      
      if (user == null || !user.isVerified) return <DramaModel>[];

      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getDramasByAdmin(user.uid);
    });
  }
}

// ===============================
// CONVENIENCE PROVIDERS (simplified - no episode complexity)
// ===============================

@riverpod
bool isDramaFavorited(IsDramaFavoritedRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  return user?.hasFavorited(dramaId) ?? false;
}

@riverpod
bool isDramaUnlocked(IsDramaUnlockedRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  return user?.hasUnlocked(dramaId) ?? false;
}

@riverpod
int dramaUserProgress(DramaUserProgressRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  return user?.getDramaProgress(dramaId) ?? 0;
}

// Check if user can watch specific episode (simplified logic)
@riverpod
bool canWatchEpisode(CanWatchEpisodeRef ref, String dramaId, int episodeNumber) {
  final drama = ref.watch(dramaProvider(dramaId));
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null) return false;
      return dramaModel.canWatchEpisode(
        episodeNumber, 
        user?.hasUnlocked(dramaId) ?? false
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// Get episode info for a specific drama episode (convenience)
@riverpod
Episode? dramaEpisode(DramaEpisodeRef ref, String dramaId, int episodeNumber) {
  final drama = ref.watch(dramaProvider(dramaId));
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null) return null;
      
      final videoUrl = dramaModel.getEpisodeVideo(episodeNumber);
      if (videoUrl == null) return null;
      
      return Episode.fromDrama(dramaModel, episodeNumber);
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

// Get all episodes for a drama (as Episode objects for UI convenience)
@riverpod
List<Episode> dramaEpisodeList(DramaEpisodeListRef ref, String dramaId) {
  final drama = ref.watch(dramaProvider(dramaId));
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null) return [];
      
      return List.generate(
        dramaModel.totalEpisodes,
        (index) => Episode.fromDrama(dramaModel, index + 1),
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
}

// Next episode to watch for continue watching feature
@riverpod
int nextEpisodeToWatch(NextEpisodeToWatchRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  
  if (user == null) return 1;
  
  final progress = user.getDramaProgress(dramaId);
  return progress + 1; // Next episode after last watched
}

// Check if episode requires unlock (simplified)
@riverpod
bool episodeRequiresUnlock(EpisodeRequiresUnlockRef ref, String dramaId, int episodeNumber) {
  final drama = ref.watch(dramaProvider(dramaId));
  final authState = ref.watch(authenticationProvider);
  final user = authState.value?.currentUser;
  
  return drama.when(
    data: (dramaModel) {
      if (dramaModel == null) return false;
      
      // If drama is not premium, no unlock needed
      if (!dramaModel.isPremium) return false;
      
      // If user has unlocked the drama, no unlock needed
      if (user?.hasUnlocked(dramaId) ?? false) return false;
      
      // If episode is within free episodes count, no unlock needed
      if (episodeNumber <= dramaModel.freeEpisodesCount) return false;
      
      // Episode requires unlock
      return true;
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

// REMOVED PROVIDERS:
// - DramaEpisodes (no longer needed - episodes are in drama model)
// - Episode (episodes are just numbered videos now)
// - SearchDramasProvider complex episode logic
// - EpisodeRequiresUnlock complex logic
// - All episode-specific state management
// - Episode view counting providers
// - Episode thumbnail/metadata providers

// What remains is MUCH simpler:
// 1. Drama providers (list, single, search)
// 2. User interaction providers (favorites, progress, unlock status)
// 3. Simple episode convenience providers that work off drama data
// 4. No complex episode state management or separate episode entities