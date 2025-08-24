// lib/features/series/providers/series_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/series_model.dart';
import '../repositories/series_repository.dart';

// Provider for the repository
final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return FirebaseSeriesRepository();
});

// Define the series state
class SeriesState {
  final bool isLoading;
  final List<SeriesModel> publishedSeries;        // Published series for discovery
  final List<SeriesModel> userSeries;             // User's created series
  final List<String> subscribedSeriesIds;         // Series user subscribed to
  final List<String> purchasedSeriesIds;          // Series user purchased
  final String? error;
  final bool isCreatingSeries;
  final double uploadProgress;

  const SeriesState({
    this.isLoading = false,
    this.publishedSeries = const [],
    this.userSeries = const [],
    this.subscribedSeriesIds = const [],
    this.purchasedSeriesIds = const [],
    this.error,
    this.isCreatingSeries = false,
    this.uploadProgress = 0.0,
  });

  SeriesState copyWith({
    bool? isLoading,
    List<SeriesModel>? publishedSeries,
    List<SeriesModel>? userSeries,
    List<String>? subscribedSeriesIds,
    List<String>? purchasedSeriesIds,
    String? error,
    bool? isCreatingSeries,
    double? uploadProgress,
  }) {
    return SeriesState(
      isLoading: isLoading ?? this.isLoading,
      publishedSeries: publishedSeries ?? this.publishedSeries,
      userSeries: userSeries ?? this.userSeries,
      subscribedSeriesIds: subscribedSeriesIds ?? this.subscribedSeriesIds,
      purchasedSeriesIds: purchasedSeriesIds ?? this.purchasedSeriesIds,
      error: error,
      isCreatingSeries: isCreatingSeries ?? this.isCreatingSeries,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

// Series provider
class SeriesNotifier extends StateNotifier<SeriesState> {
  final SeriesRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SeriesNotifier(this._repository) : super(const SeriesState()) {
    // Initialize with empty state and load data
    loadPublishedSeries();
    loadUserSeries();
    loadSubscribedSeries();
    loadPurchasedSeries();
  }

  // Load published series (for discovery)
  Future<void> loadPublishedSeries({bool forceRefresh = false}) async {
    if (!forceRefresh && state.publishedSeries.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final series = await _repository.getPublishedSeries(forceRefresh: forceRefresh);
      
      state = state.copyWith(
        publishedSeries: series,
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

  // Load user's created series
  Future<void> loadUserSeries() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final userSeries = await _repository.getUserSeries(uid);
      state = state.copyWith(userSeries: userSeries);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Load subscribed series
  Future<void> loadSubscribedSeries() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final subscribedIds = await _repository.getSubscribedSeries(uid);
      state = state.copyWith(subscribedSeriesIds: subscribedIds);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Load purchased series
  Future<void> loadPurchasedSeries() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final purchasedIds = await _repository.getUserPurchasedSeries(uid);
      state = state.copyWith(purchasedSeriesIds: purchasedIds);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Create a new series
  Future<void> createSeries({
    required String title,
    required String description,
    required File? thumbnailImage,
    File? coverImage,
    List<String>? tags,
    required int freeEpisodeCount,
    required double seriesPrice,
    required bool hasPaywall,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (thumbnailImage == null) {
      onError('Thumbnail image is required');
      return;
    }
    
    state = state.copyWith(isCreatingSeries: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Upload thumbnail image
      final thumbnailImageUrl = await _repository.uploadImage(
        thumbnailImage, 
        'seriesImages/${const Uuid().v4()}/thumbnail.jpg'
      );
      state = state.copyWith(uploadProgress: 0.5);
      
      // Upload cover image if provided
      String coverImageUrl = '';
      if (coverImage != null) {
        coverImageUrl = await _repository.uploadImage(
          coverImage, 
          'seriesImages/${const Uuid().v4()}/cover.jpg'
        );
        state = state.copyWith(uploadProgress: 0.8);
      }
      
      // Create series
      final series = await _repository.createSeries(
        userId: uid,
        title: title,
        description: description,
        thumbnailImageUrl: thumbnailImageUrl,
        coverImageUrl: coverImageUrl,
        tags: tags ?? [],
        freeEpisodeCount: freeEpisodeCount,
        seriesPrice: seriesPrice,
        hasPaywall: hasPaywall,
      );
      
      state = state.copyWith(uploadProgress: 1.0);
      
      // Update user series list
      final updatedUserSeries = [series, ...state.userSeries];
      
      state = state.copyWith(
        userSeries: updatedUserSeries,
        isCreatingSeries: false,
        uploadProgress: 0.0,
      );
      
      onSuccess('Series created successfully! It will be published after review.');
    } on RepositoryException catch (e) {
      state = state.copyWith(
        isCreatingSeries: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
    } catch (e) {
      state = state.copyWith(
        isCreatingSeries: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }

  // Subscribe/unsubscribe to series
  Future<void> toggleSubscribeSeries(String seriesId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      
      List<String> subscribedIds = List.from(state.subscribedSeriesIds);
      bool isCurrentlySubscribed = subscribedIds.contains(seriesId);
      
      // Optimistic update
      if (isCurrentlySubscribed) {
        subscribedIds.remove(seriesId);
        await _repository.unsubscribeSeries(seriesId, uid);
      } else {
        subscribedIds.add(seriesId);
        await _repository.subscribeSeries(seriesId, uid);
      }
      
      // Update published series list with new subscriber count
      final updatedPublishedSeries = state.publishedSeries.map((series) {
        if (series.id == seriesId) {
          return series.copyWith(
            subscribers: isCurrentlySubscribed ? series.subscribers - 1 : series.subscribers + 1,
            subscriberUIDs: isCurrentlySubscribed
                ? (series.subscriberUIDs..remove(uid))
                : (series.subscriberUIDs..add(uid)),
          );
        }
        return series;
      }).toList();
      
      state = state.copyWith(
        publishedSeries: updatedPublishedSeries,
        subscribedSeriesIds: subscribedIds,
      );
      
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
      // Revert optimistic update on error
      loadPublishedSeries();
      loadSubscribedSeries();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Revert optimistic update on error
      loadPublishedSeries();
      loadSubscribedSeries();
    }
  }

  // Purchase a series
  Future<void> purchaseSeries({
    required String seriesId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      final uid = _auth.currentUser!.uid;
      
      await _repository.purchaseSeries(
        userId: uid,
        seriesId: seriesId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );
      
      // Update purchased series list
      final updatedPurchasedIds = [...state.purchasedSeriesIds, seriesId];
      state = state.copyWith(purchasedSeriesIds: updatedPurchasedIds);
      
      onSuccess('Series purchased successfully!');
    } on RepositoryException catch (e) {
      onError(e.message);
    } catch (e) {
      onError(e.toString());
    }
  }

  // Get a specific series by ID
  Future<SeriesModel?> getSeriesById(String seriesId) async {
    try {
      return await _repository.getSeriesById(seriesId);
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update a series
  Future<void> updateSeries({
    required SeriesModel series,
    File? thumbnailImage,
    File? coverImage,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    if (series.creatorId != _auth.currentUser!.uid) {
      onError('You can only update your own series');
      return;
    }
    
    state = state.copyWith(isCreatingSeries: true, uploadProgress: 0.0);
    
    try {
      String thumbnailImageUrl = series.thumbnailImage;
      String coverImageUrl = series.coverImage;
      
      // Upload new thumbnail image if provided
      if (thumbnailImage != null) {
        thumbnailImageUrl = await _repository.uploadImage(
          thumbnailImage, 
          'seriesImages/${series.id}/thumbnail.jpg'
        );
        state = state.copyWith(uploadProgress: 0.5);
      }
      
      // Upload new cover image if provided
      if (coverImage != null) {
        coverImageUrl = await _repository.uploadImage(
          coverImage, 
          'seriesImages/${series.id}/cover.jpg'
        );
        state = state.copyWith(uploadProgress: 1.0);
      }
      
      // Update series
      final updatedSeries = await _repository.updateSeries(
        series: series,
        thumbnailImageUrl: thumbnailImageUrl,
        coverImageUrl: coverImageUrl,
      );
      
      // Update user series list
      final updatedUserSeries = state.userSeries.map((s) {
        if (s.id == series.id) {
          return updatedSeries;
        }
        return s;
      }).toList();
      
      // Update published series list if this series is published
      final updatedPublishedSeries = state.publishedSeries.map((s) {
        if (s.id == series.id) {
          return updatedSeries;
        }
        return s;
      }).toList();
      
      state = state.copyWith(
        userSeries: updatedUserSeries,
        publishedSeries: updatedPublishedSeries,
        isCreatingSeries: false,
        uploadProgress: 0.0,
      );
      
      onSuccess('Series updated successfully');
    } on RepositoryException catch (e) {
      state = state.copyWith(
        isCreatingSeries: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
    } catch (e) {
      state = state.copyWith(
        isCreatingSeries: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }

  // Delete a series
  Future<void> deleteSeries(String seriesId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      await _repository.deleteSeries(seriesId, uid);
      
      // Update local state
      final updatedUserSeries = state.userSeries.where((s) => s.id != seriesId).toList();
      final updatedPublishedSeries = state.publishedSeries.where((s) => s.id != seriesId).toList();
      
      state = state.copyWith(
        userSeries: updatedUserSeries,
        publishedSeries: updatedPublishedSeries,
      );
    } on RepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Helper methods
  bool isSeriesSubscribed(String seriesId) {
    return state.subscribedSeriesIds.contains(seriesId);
  }

  bool isSeriesPurchased(String seriesId) {
    return state.purchasedSeriesIds.contains(seriesId);
  }

  // Check if user can access an episode
  bool canAccessEpisode(SeriesModel series, int episodeNumber) {
    final hasPurchased = isSeriesPurchased(series.id);
    return _repository.canUserAccessEpisode(series, episodeNumber, hasPurchased);
  }
}

// Provider definition
final seriesProvider = StateNotifierProvider<SeriesNotifier, SeriesState>((ref) {
  final repository = ref.watch(seriesRepositoryProvider);
  return SeriesNotifier(repository);
});

