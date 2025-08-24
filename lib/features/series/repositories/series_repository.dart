// lib/features/series/repositories/series_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/series/models/cloud_firestore.dart';
import '../models/series_model.dart';
import '../models/series_episode_model.dart';


// Abstract repository interface
abstract class SeriesRepository {
  // Series operations
  Future<List<SeriesModel>> getPublishedSeries({bool forceRefresh = false});
  Future<List<SeriesModel>> getUserSeries(String userId, {bool forceRefresh = false});
  Future<SeriesModel?> getSeriesById(String seriesId);
  Future<SeriesModel> createSeries({
    required String userId,
    required String title,
    required String description,
    required String thumbnailImageUrl,
    required String coverImageUrl,
    required List<String> tags,
    required int freeEpisodeCount,
    required double seriesPrice,
    required bool hasPaywall,
  });
  Future<SeriesModel> updateSeries({
    required SeriesModel series,
    required String thumbnailImageUrl,
    required String coverImageUrl,
  });
  Future<void> deleteSeries(String seriesId, String userId);
  Future<void> subscribeSeries(String seriesId, String userId);
  Future<void> unsubscribeSeries(String seriesId, String userId);
  Future<List<String>> getSubscribedSeries(String userId);

  // Episode operations
  Future<List<SeriesEpisodeModel>> getFeaturedEpisodes({bool forceRefresh = false});
  Future<List<SeriesEpisodeModel>> getSeriesEpisodes(String seriesId, {bool forceRefresh = false});
  Future<SeriesEpisodeModel?> getEpisodeById(String episodeId);
  Future<SeriesEpisodeModel> createEpisode({
    required String seriesId,
    required String seriesTitle,
    required String seriesImage,
    required String userId,
    required String episodeTitle,
    required String description,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationSeconds,
    required bool isFeatured,
    required List<String> tags,
  });
  Future<void> deleteEpisode(String episodeId, String userId);
  Future<void> likeEpisode(String episodeId, String userId);
  Future<void> unlikeEpisode(String episodeId, String userId);
  Future<List<String>> getLikedEpisodes(String userId);
  Future<void> incrementEpisodeViews(String episodeId);

  // Purchase operations
  Future<bool> hasUserPurchasedSeries(String userId, String seriesId);
  Future<SeriesPurchaseModel> purchaseSeries({
    required String userId,
    required String seriesId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
  });
  Future<List<String>> getUserPurchasedSeries(String userId);

  // File upload operations
  Future<String> uploadImage(File imageFile, String path);
  Future<String> uploadVideo(File videoFile, String path, {Function(double)? onProgress});
  
  // Access control
  bool canUserAccessEpisode(SeriesModel series, int episodeNumber, bool hasPurchased);
}

// Firebase implementation
class FirebaseSeriesRepository implements SeriesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _seriesCollection;
  final String _episodesCollection;
  final String _purchasesCollection;
  final String _usersCollection;

  FirebaseSeriesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    String seriesCollection = 'series',
    String episodesCollection = 'seriesEpisodes',
    String purchasesCollection = 'seriesPurchases',
    String usersCollection = 'users',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _seriesCollection = seriesCollection,
       _episodesCollection = episodesCollection,
       _purchasesCollection = purchasesCollection,
       _usersCollection = usersCollection;

  @override
  Future<List<SeriesModel>> getPublishedSeries({bool forceRefresh = false}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_seriesCollection)
          .where('isActive', isEqualTo: true)
          .where('isPublished', isEqualTo: true) // Only published series
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SeriesModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch published series: $e');
    }
  }

  @override
  Future<List<SeriesModel>> getUserSeries(String userId, {bool forceRefresh = false}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_seriesCollection)
          .where('creatorId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SeriesModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch user series: $e');
    }
  }

  @override
  Future<SeriesModel?> getSeriesById(String seriesId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .get();

      if (!docSnapshot.exists) return null;
      return SeriesModel.fromMap(docSnapshot.data()!, seriesId);
    } catch (e) {
      throw RepositoryException('Failed to fetch series: $e');
    }
  }

  @override
  Future<SeriesModel> createSeries({
    required String userId,
    required String title,
    required String description,
    required String thumbnailImageUrl,
    required String coverImageUrl,
    required List<String> tags,
    required int freeEpisodeCount,
    required double seriesPrice,
    required bool hasPaywall,
  }) async {
    try {
      debugPrint('DEBUG: Creating series for user $userId');

      // Get user data
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) {
        throw RepositoryException('User data not found');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'User';
      final userPhoneNumber = userData['phoneNumber'] ?? '';
      final userImage = userData['image'] ?? '';

      final seriesRef = _firestore.collection(_seriesCollection).doc();
      final seriesId = seriesRef.id;

      return await _firestore.runTransaction<SeriesModel>((transaction) async {
        final series = SeriesModel(
          id: seriesId,
          creatorId: userId,
          creatorName: userName,
          creatorPhoneNumber: userPhoneNumber,
          creatorImage: userImage,
          title: title,
          description: description,
          thumbnailImage: thumbnailImageUrl,
          coverImage: coverImageUrl,
          subscribers: 0,
          episodeCount: 0,
          totalDurationSeconds: 0,
          likesCount: 0,
          isVerified: false,
          isPublished: false, // Default to unpublished - admin must approve
          tags: tags,
          subscriberUIDs: [],
          createdAt: Timestamp.now(),
          lastEpisodeAt: null,
          isActive: true,
          isFeatured: false,          // Default to non-featured - admin must approve
          freeEpisodeCount: freeEpisodeCount,
          seriesPrice: seriesPrice,
          hasPaywall: hasPaywall,
        );

        // Set series data
        transaction.set(seriesRef, series.toMap());

        // Update user's owned series
        transaction.update(_firestore.collection(_usersCollection).doc(userId), {
          'ownedSeriesUIDs': FieldValue.arrayUnion([seriesId]),
        });

        debugPrint('DEBUG: Created unpublished series $seriesId');
        return series;
      });
    } catch (e) {
      debugPrint('ERROR: Failed to create series: $e');
      throw RepositoryException('Failed to create series: $e');
    }
  }

  @override
  Future<SeriesModel> updateSeries({
    required SeriesModel series,
    required String thumbnailImageUrl,
    required String coverImageUrl,
  }) async {
    try {
      final updates = series.toMap();
      updates['thumbnailImage'] = thumbnailImageUrl;
      updates['coverImage'] = coverImageUrl;

      await _firestore
          .collection(_seriesCollection)
          .doc(series.id)
          .update(updates);

      return series.copyWith(
        thumbnailImage: thumbnailImageUrl,
        coverImage: coverImageUrl,
      );
    } catch (e) {
      throw RepositoryException('Failed to update series: $e');
    }
  }

  @override
  Future<void> deleteSeries(String seriesId, String userId) async {
    try {
      // Verify ownership
      final series = await getSeriesById(seriesId);
      if (series?.creatorId != userId) {
        throw RepositoryException('Unauthorized: Cannot delete series');
      }

      await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .update({'isActive': false});

      // Remove from user's owned series
      await _firestore.collection(_usersCollection).doc(userId).update({
        'ownedSeriesUIDs': FieldValue.arrayRemove([seriesId]),
      });
    } catch (e) {
      throw RepositoryException('Failed to delete series: $e');
    }
  }

  @override
  Future<void> subscribeSeries(String seriesId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's subscribed series
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'subscribedSeriesUIDs': FieldValue.arrayUnion([seriesId]),
        },
      );

      // Update series subscriber count
      batch.update(
        _firestore.collection(_seriesCollection).doc(seriesId),
        {
          'subscribers': FieldValue.increment(1),
          'subscriberUIDs': FieldValue.arrayUnion([userId]),
        },
      );

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to subscribe to series: $e');
    }
  }

  @override
  Future<void> unsubscribeSeries(String seriesId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's subscribed series
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'subscribedSeriesUIDs': FieldValue.arrayRemove([seriesId]),
        },
      );

      // Update series subscriber count
      batch.update(
        _firestore.collection(_seriesCollection).doc(seriesId),
        {
          'subscribers': FieldValue.increment(-1),
          'subscriberUIDs': FieldValue.arrayRemove([userId]),
        },
      );

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to unsubscribe from series: $e');
    }
  }

  @override
  Future<List<String>> getSubscribedSeries(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['subscribedSeriesUIDs'] ?? []);
    } catch (e) {
      throw RepositoryException('Failed to fetch subscribed series: $e');
    }
  }

  @override
  Future<List<SeriesEpisodeModel>> getFeaturedEpisodes({bool forceRefresh = false}) async {
    try {
      // Get episodes that are featured AND from published series
      final episodesQuery = await _firestore
          .collection(_episodesCollection)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Filter episodes from published series
      List<SeriesEpisodeModel> featuredEpisodes = [];
      
      for (final episodeDoc in episodesQuery.docs) {
        final episode = SeriesEpisodeModel.fromMap(episodeDoc.data(), id: episodeDoc.id);
        
        // Check if the series is published
        final series = await getSeriesById(episode.seriesId);
        if (series != null && series.isPublished) {
          featuredEpisodes.add(episode);
        }
      }

      return featuredEpisodes;
    } catch (e) {
      throw RepositoryException('Failed to fetch featured episodes: $e');
    }
  }

  @override
  Future<List<SeriesEpisodeModel>> getSeriesEpisodes(String seriesId, {bool forceRefresh = false}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_episodesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('isActive', isEqualTo: true)
          .orderBy('episodeNumber', descending: false) // Order by episode number
          .get();

      return querySnapshot.docs
          .map((doc) => SeriesEpisodeModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to fetch series episodes: $e');
    }
  }

  @override
  Future<SeriesEpisodeModel?> getEpisodeById(String episodeId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .get();

      if (!docSnapshot.exists) return null;
      return SeriesEpisodeModel.fromMap(docSnapshot.data()!, id: episodeId);
    } catch (e) {
      throw RepositoryException('Failed to fetch episode: $e');
    }
  }

  @override
  Future<SeriesEpisodeModel> createEpisode({
    required String seriesId,
    required String seriesTitle,
    required String seriesImage,
    required String userId,
    required String episodeTitle,
    required String description,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationSeconds,
    required bool isFeatured,
    required List<String> tags,
  }) async {
    try {
      // Get series to determine next episode number
      final series = await getSeriesById(seriesId);
      if (series == null) {
        throw RepositoryException('Series not found');
      }

      // Verify user owns the series
      if (series.creatorId != userId) {
        throw RepositoryException('Unauthorized: Cannot add episode to this series');
      }

      // Check episode limits
      if (series.episodeCount >= series.maxEpisodes) {
        throw RepositoryException('Maximum episodes reached for this series');
      }

      if (durationSeconds > 120) { // 2 minutes
        throw RepositoryException('Episode duration cannot exceed 2 minutes');
      }

      // Check featured episode limit
      if (isFeatured && series.featuredEpisodeCount >= 5) {
        throw RepositoryException('Maximum 5 featured episodes allowed per series');
      }

      final episodeId = _generateId();
      final now = Timestamp.now();
      final episodeNumber = series.nextEpisodeNumber;
      
      final episode = SeriesEpisodeModel(
        id: episodeId,
        seriesId: seriesId,
        seriesTitle: seriesTitle,
        seriesImage: seriesImage,
        episodeNumber: episodeNumber,
        title: episodeTitle,
        description: description,
        creatorId: userId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        isFeatured: isFeatured,
        likes: 0,
        comments: 0,
        views: 0,
        shares: 0,
        isLiked: false,
        tags: tags,
        createdAt: now,
        isActive: true,
      );

      // Use transaction to ensure consistency
      return await _firestore.runTransaction<SeriesEpisodeModel>((transaction) async {
        // Create episode
        transaction.set(
          _firestore.collection(_episodesCollection).doc(episodeId),
          episode.toMap(),
        );

        // Update series with new episode info
        transaction.update(
          _firestore.collection(_seriesCollection).doc(seriesId),
          {
            'episodeCount': FieldValue.increment(1),
            'totalDurationSeconds': FieldValue.increment(durationSeconds),
            'nextEpisodeNumber': episodeNumber + 1,
            'lastEpisodeAt': now,
            if (isFeatured) 'featuredEpisodeCount': FieldValue.increment(1),
          },
        );

        return episode;
      });
    } catch (e) {
      throw RepositoryException('Failed to create episode: $e');
    }
  }

  @override
  Future<void> deleteEpisode(String episodeId, String userId) async {
    try {
      // Get episode to verify ownership and get series info
      final episode = await getEpisodeById(episodeId);
      if (episode == null) {
        throw RepositoryException('Episode not found');
      }

      // Verify series ownership
      final series = await getSeriesById(episode.seriesId);
      if (series?.creatorId != userId) {
        throw RepositoryException('Unauthorized: Cannot delete episode');
      }

      await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .update({'isActive': false});

      // Update series episode count and duration
      await _firestore.collection(_seriesCollection).doc(episode.seriesId).update({
        'episodeCount': FieldValue.increment(-1),
        'totalDurationSeconds': FieldValue.increment(-episode.durationSeconds),
        if (episode.isFeatured) 'featuredEpisodeCount': FieldValue.increment(-1),
      });

      // Update lastEpisodeAt to the most recent remaining episode
      await _updateSeriesLastEpisodeAt(episode.seriesId);
      
    } catch (e) {
      throw RepositoryException('Failed to delete episode: $e');
    }
  }

  // Helper method to update lastEpisodeAt after episode deletion
  Future<void> _updateSeriesLastEpisodeAt(String seriesId) async {
    try {
      // Get the most recent active episode for this series
      final querySnapshot = await _firestore
          .collection(_episodesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final latestEpisodeTimestamp = querySnapshot.docs.first.data()['createdAt'];
        await _firestore.collection(_seriesCollection).doc(seriesId).update({
          'lastEpisodeAt': latestEpisodeTimestamp,
        });
      } else {
        // No episodes left, set lastEpisodeAt to null
        await _firestore.collection(_seriesCollection).doc(seriesId).update({
          'lastEpisodeAt': null,
        });
      }
    } catch (e) {
      debugPrint('Failed to update lastEpisodeAt after deletion: $e');
    }
  }

  @override
  Future<void> likeEpisode(String episodeId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's liked episodes
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'likedEpisodesUIDs': FieldValue.arrayUnion([episodeId]),
        },
      );

      // Update episode's like count
      batch.update(
        _firestore.collection(_episodesCollection).doc(episodeId),
        {
          'likes': FieldValue.increment(1),
        },
      );

      // Update series total likes
      final episode = await getEpisodeById(episodeId);
      if (episode != null) {
        batch.update(
          _firestore.collection(_seriesCollection).doc(episode.seriesId),
          {
            'likesCount': FieldValue.increment(1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to like episode: $e');
    }
  }

  @override
  Future<void> unlikeEpisode(String episodeId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Update user's liked episodes
      batch.update(
        _firestore.collection(_usersCollection).doc(userId),
        {
          'likedEpisodesUIDs': FieldValue.arrayRemove([episodeId]),
        },
      );

      // Update episode's like count
      batch.update(
        _firestore.collection(_episodesCollection).doc(episodeId),
        {
          'likes': FieldValue.increment(-1),
        },
      );

      // Update series total likes
      final episode = await getEpisodeById(episodeId);
      if (episode != null) {
        batch.update(
          _firestore.collection(_seriesCollection).doc(episode.seriesId),
          {
            'likesCount': FieldValue.increment(-1),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to unlike episode: $e');
    }
  }

  @override
  Future<List<String>> getLikedEpisodes(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['likedEpisodesUIDs'] ?? []);
    } catch (e) {
      throw RepositoryException('Failed to fetch liked episodes: $e');
    }
  }

  @override
  Future<void> incrementEpisodeViews(String episodeId) async {
    try {
      await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      throw RepositoryException('Failed to increment episode views: $e');
    }
  }

  @override
  Future<bool> hasUserPurchasedSeries(String userId, String seriesId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_purchasesCollection)
          .where('userId', isEqualTo: userId)
          .where('seriesId', isEqualTo: seriesId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw RepositoryException('Failed to check series purchase: $e');
    }
  }

  @override
  Future<SeriesPurchaseModel> purchaseSeries({
    required String userId,
    required String seriesId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      // Get series info
      final series = await getSeriesById(seriesId);
      if (series == null) {
        throw RepositoryException('Series not found');
      }

      if (!series.isPublished) {
        throw RepositoryException('Series is not published');
      }

      // Check if user already purchased
      final alreadyPurchased = await hasUserPurchasedSeries(userId, seriesId);
      if (alreadyPurchased) {
        throw RepositoryException('Series already purchased');
      }

      final purchaseId = _generateId();
      final purchase = SeriesPurchaseModel(
        id: purchaseId,
        userId: userId,
        seriesId: seriesId,
        seriesTitle: series.title,
        amountPaid: amount,
        purchaseDate: Timestamp.now(),
        isActive: true,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      // Use transaction to ensure consistency
      return await _firestore.runTransaction<SeriesPurchaseModel>((transaction) async {
        // Create purchase record
        transaction.set(
          _firestore.collection(_purchasesCollection).doc(purchaseId),
          purchase.toMap(),
        );

        // Update user's purchased series
        transaction.update(
          _firestore.collection(_usersCollection).doc(userId),
          {
            'purchasedSeriesUIDs': FieldValue.arrayUnion([seriesId]),
          },
        );

        return purchase;
      });
    } catch (e) {
      throw RepositoryException('Failed to purchase series: $e');
    }
  }

  @override
  Future<List<String>> getUserPurchasedSeries(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];
      
      final data = userDoc.data()!;
      return List<String>.from(data['purchasedSeriesUIDs'] ?? []);
    } catch (e) {
      throw RepositoryException('Failed to fetch purchased series: $e');
    }
  }

  @override
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw RepositoryException('Failed to upload image: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String path, {Function(double)? onProgress}) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw RepositoryException('Failed to upload video: $e');
    }
  }

  @override
  bool canUserAccessEpisode(SeriesModel series, int episodeNumber, bool hasPurchased) {
    // If series has no paywall, all episodes are free
    if (!series.hasPaywall) {
      return true;
    }

    // If episode is within free range, user can access
    if (episodeNumber <= series.freeEpisodeCount) {
      return true;
    }

    // If episode is paid, user needs to have purchased the series
    return hasPurchased;
  }

  String _generateId() {
    return _firestore.collection('temp').doc().id;
  }
}

// Exception class for repository errors
class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);
  
  @override
  String toString() => 'RepositoryException: $message';
}