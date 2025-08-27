// lib/features/dramas/providers/drama_providers.dart (Updated for Go Backend)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/dramas/repositories/drama_repository.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/models/user_model.dart';

part 'drama_providers.g.dart';

// Repository provider
@riverpod
DramaRepository dramaRepository(DramaRepositoryRef ref) {
  return HttpDramaRepository();
}

// Drama list state for different categories
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

// Featured dramas provider
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

// Trending dramas provider
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

// All dramas provider with pagination (updated for HTTP backend)
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

// Free dramas provider
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

// Premium dramas provider
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

// Single drama provider
@riverpod
class Drama extends _$Drama {
  @override
  Future<DramaModel?> build(String dramaId) async {
    final repository = ref.read(dramaRepositoryProvider);
    final drama = await repository.getDramaById(dramaId);
    
    // Increment view count when drama is loaded (fire and forget)
    if (drama != null) {
      repository.incrementDramaViews(dramaId);
    }
    
    return drama;
  }

  Future<void> refresh() async {
    final dramaId = this.dramaId; // Get the dramaId from the provider
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getDramaById(dramaId);
    });
  }
}

// Drama episodes provider
@riverpod
class DramaEpisodes extends _$DramaEpisodes {
  @override
  Future<List<EpisodeModel>> build(String dramaId) async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramaEpisodes(dramaId);
  }

  Future<void> refresh() async {
    final dramaId = this.dramaId; // Get the dramaId from the provider
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getDramaEpisodes(dramaId);
    });
  }
}

// Single episode provider
@riverpod
Future<EpisodeModel?> episode(EpisodeRef ref, String episodeId) async {
  final repository = ref.read(dramaRepositoryProvider);
  final episode = await repository.getEpisodeById(episodeId);
  
  // Increment view count when episode is loaded (fire and forget)
  if (episode != null) {
    repository.incrementEpisodeViews(episodeId);
  }
  
  return episode;
}

// Search dramas provider
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

// User's favorite dramas provider
@riverpod
Future<List<DramaModel>> userFavoriteDramas(UserFavoriteDramasRef ref) async {
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  
  if (user == null || user.favoriteDramas.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> favoriteDramas = [];

  // Fetch each favorite drama
  for (final dramaId in user.favoriteDramas) {
    try {
      final drama = await repository.getDramaById(dramaId);
      if (drama != null) {
        favoriteDramas.add(drama);
      }
    } catch (e) {
      // Skip dramas that can't be loaded
      continue;
    }
  }

  return favoriteDramas;
}

// Continue watching provider (dramas user has progress in)
@riverpod
Future<List<DramaModel>> continueWatchingDramas(ContinueWatchingDramasRef ref) async {
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  
  if (user == null || user.dramaProgress.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> continueWatchingDramas = [];

  // Fetch dramas that user has progress in
  for (final dramaId in user.dramaProgress.keys) {
    try {
      final drama = await repository.getDramaById(dramaId);
      if (drama != null) {
        continueWatchingDramas.add(drama);
      }
    } catch (e) {
      // Skip dramas that can't be loaded
      continue;
    }
  }

  // Sort by most recently watched (could be enhanced with timestamps)
  return continueWatchingDramas;
}

// ADMIN PROVIDERS (only accessible to admin users)

// Admin's dramas provider
@riverpod
class AdminDramas extends _$AdminDramas {
  @override
  Future<List<DramaModel>> build() async {
    final authState = ref.watch(authenticationProvider);
    final user = authState.valueOrNull?.userModel;
    
    if (user == null || !user.isAdmin) return [];

    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramasByAdmin(user.uid);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authenticationProvider);
      final user = authState.valueOrNull?.userModel;
      
      if (user == null || !user.isAdmin) return <DramaModel>[];

      final repository = ref.read(dramaRepositoryProvider);
      return await repository.getDramasByAdmin(user.uid);
    });
  }
}

// CONVENIENCE PROVIDERS

// Check if user has favorited a drama
@riverpod
bool isDramaFavorited(IsDramaFavoritedRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  return user?.hasFavorited(dramaId) ?? false;
}

// Check if user has unlocked a drama
@riverpod
bool isDramaUnlocked(IsDramaUnlockedRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  return user?.hasUnlocked(dramaId) ?? false;
}

// Get user's progress in a drama
@riverpod
int dramaUserProgress(DramaUserProgressRef ref, String dramaId) {
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  return user?.getDramaProgress(dramaId) ?? 0;
}

// Check if user can watch a specific episode
@riverpod
bool canWatchEpisode(CanWatchEpisodeRef ref, String dramaId, int episodeNumber) {
  final drama = ref.watch(dramaProvider(dramaId));
  final authState = ref.watch(authenticationProvider);
  final user = authState.valueOrNull?.userModel;
  
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

// PERIODIC REFRESH PROVIDERS (replace real-time streams)
// These providers can be refreshed periodically to simulate real-time updates

// Featured dramas with periodic refresh
@riverpod
class FeaturedDramasLive extends _$FeaturedDramasLive {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getFeaturedDramas();
  }

  // Call this method periodically from UI to refresh data
  Future<void> refreshPeriodically() async {
    final repository = ref.read(dramaRepositoryProvider);
    state = AsyncValue.data(await repository.getFeaturedDramas());
  }
}

// Trending dramas with periodic refresh
@riverpod
class TrendingDramasLive extends _$TrendingDramasLive {
  @override
  Future<List<DramaModel>> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getTrendingDramas();
  }

  // Call this method periodically from UI to refresh data
  Future<void> refreshPeriodically() async {
    final repository = ref.read(dramaRepositoryProvider);
    state = AsyncValue.data(await repository.getTrendingDramas());
  }
}

// Drama with periodic refresh
@riverpod
class DramaLive extends _$DramaLive {
  @override
  Future<DramaModel?> build(String dramaId) async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramaById(dramaId);
  }

  // Call this method periodically from UI to refresh data
  Future<void> refreshPeriodically() async {
    final dramaId = this.dramaId;
    final repository = ref.read(dramaRepositoryProvider);
    state = AsyncValue.data(await repository.getDramaById(dramaId));
  }
}

// Episodes with periodic refresh
@riverpod
class DramaEpisodesLive extends _$DramaEpisodesLive {
  @override
  Future<List<EpisodeModel>> build(String dramaId) async {
    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramaEpisodes(dramaId);
  }

  // Call this method periodically from UI to refresh data
  Future<void> refreshPeriodically() async {
    final dramaId = this.dramaId;
    final repository = ref.read(dramaRepositoryProvider);
    state = AsyncValue.data(await repository.getDramaEpisodes(dramaId));
  }
}