// lib/features/dramas/providers/drama_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/repositories/drama_repository.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/models/user_model.dart';

part 'drama_providers.g.dart';

// Repository provider
@riverpod
DramaRepository dramaRepository(DramaRepositoryRef ref) {
  return FirebaseDramaRepository();
}

// Drama list state for different categories
class DramaListState {
  final List<DramaModel> dramas;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const DramaListState({
    this.dramas = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  DramaListState copyWith({
    List<DramaModel>? dramas,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return DramaListState(
      dramas: dramas ?? this.dramas,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
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

// All dramas provider with pagination
@riverpod
class AllDramas extends _$AllDramas {
  @override
  Future<DramaListState> build() async {
    final repository = ref.read(dramaRepositoryProvider);
    try {
      final dramas = await repository.getAllDramas(limit: 20);
      return DramaListState(
        dramas: dramas,
        hasMore: dramas.length >= 20,
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
        // Note: For pagination, you'd need to pass the last document
        // This is simplified - in real implementation, store last document
      );

      state = AsyncValue.data(currentState.copyWith(
        dramas: [...currentState.dramas, ...newDramas],
        isLoading: false,
        hasMore: newDramas.length >= 20,
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
      final dramas = await repository.getAllDramas(limit: 20);
      return DramaListState(
        dramas: dramas,
        hasMore: dramas.length >= 20,
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
    
    // Increment view count when drama is loaded
    if (drama != null) {
      repository.incrementDramaViews(dramaId);
    }
    
    return drama;
  }

  Future<void> refresh() async {
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
  
  // Increment view count when episode is loaded
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
  final user = ref.watch(currentUserProvider);
  if (user == null || user.favoriteDramas.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> favoriteDramas = [];

  // Fetch each favorite drama
  for (final dramaId in user.favoriteDramas) {
    final drama = await repository.getDramaById(dramaId);
    if (drama != null) {
      favoriteDramas.add(drama);
    }
  }

  return favoriteDramas;
}

// Continue watching provider (dramas user has progress in)
@riverpod
Future<List<DramaModel>> continueWatchingDramas(ContinueWatchingDramasRef ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.dramaProgress.isEmpty) return [];

  final repository = ref.read(dramaRepositoryProvider);
  final List<DramaModel> continueWatchingDramas = [];

  // Fetch dramas that user has progress in
  for (final dramaId in user.dramaProgress.keys) {
    final drama = await repository.getDramaById(dramaId);
    if (drama != null) {
      continueWatchingDramas.add(drama);
    }
  }

  // Sort by most recently watched (this would need timestamp in real app)
  return continueWatchingDramas;
}

// ADMIN PROVIDERS (only accessible to admin users)

// Admin's dramas provider
@riverpod
class AdminDramas extends _$AdminDramas {
  @override
  Future<List<DramaModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isAdmin) return [];

    final repository = ref.read(dramaRepositoryProvider);
    return await repository.getDramasByAdmin(user.uid);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
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
  final user = ref.watch(currentUserProvider);
  return user?.hasFavorited(dramaId) ?? false;
}

// Check if user has unlocked a drama
@riverpod
bool isDramaUnlocked(IsDramaUnlockedRef ref, String dramaId) {
  final user = ref.watch(currentUserProvider);
  return user?.hasUnlocked(dramaId) ?? false;
}

// Get user's progress in a drama
@riverpod
int dramaUserProgress(DramaUserProgressRef ref, String dramaId) {
  final user = ref.watch(currentUserProvider);
  return user?.getDramaProgress(dramaId) ?? 0;
}

// Check if user can watch a specific episode
@riverpod
bool canWatchEpisode(CanWatchEpisodeRef ref, String dramaId, int episodeNumber) {
  final drama = ref.watch(dramaProvider(dramaId));
  final user = ref.watch(currentUserProvider);
  
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

// STREAM PROVIDERS (for real-time updates)

@riverpod
Stream<List<DramaModel>> featuredDramasStream(FeaturedDramasStreamRef ref) {
  final repository = ref.read(dramaRepositoryProvider);
  return repository.featuredDramasStream();
}

@riverpod
Stream<List<DramaModel>> trendingDramasStream(TrendingDramasStreamRef ref) {
  final repository = ref.read(dramaRepositoryProvider);
  return repository.trendingDramasStream();
}

@riverpod
Stream<DramaModel> dramaStream(DramaStreamRef ref, String dramaId) {
  final repository = ref.read(dramaRepositoryProvider);
  return repository.dramaStream(dramaId);
}

@riverpod
Stream<List<EpisodeModel>> dramaEpisodesStream(DramaEpisodesStreamRef ref, String dramaId) {
  final repository = ref.read(dramaRepositoryProvider);
  return repository.dramaEpisodesStream(dramaId);
}