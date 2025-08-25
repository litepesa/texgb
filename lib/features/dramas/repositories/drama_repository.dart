// lib/features/dramas/repositories/drama_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';

// Import custom exceptions
import 'package:textgb/features/dramas/providers/drama_actions_provider.dart';

// Abstract repository interface
abstract class DramaRepository {
  // Drama CRUD operations
  Future<List<DramaModel>> getAllDramas({int limit = 20, DocumentSnapshot? lastDocument});
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10});
  Future<List<DramaModel>> getTrendingDramas({int limit = 10});
  Future<List<DramaModel>> getFreeDramas({int limit = 20});
  Future<List<DramaModel>> getPremiumDramas({int limit = 20});
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20});
  Future<DramaModel?> getDramaById(String dramaId);
  
  // ATOMIC DRAMA UNLOCK - Main method
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  });
  
  // Admin drama operations
  Future<String> createDrama(DramaModel drama, {File? bannerImage});
  Future<void> updateDrama(DramaModel drama, {File? bannerImage});
  Future<void> deleteDrama(String dramaId);
  Future<List<DramaModel>> getDramasByAdmin(String adminId);
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured);
  Future<void> toggleDramaActive(String dramaId, bool isActive);
  
  // Episode CRUD operations
  Future<List<EpisodeModel>> getDramaEpisodes(String dramaId);
  Future<EpisodeModel?> getEpisodeById(String episodeId);
  Future<String> addEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile});
  Future<void> updateEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile});
  Future<void> deleteEpisode(String episodeId, String dramaId);
  
  // User interaction operations
  Future<void> incrementDramaViews(String dramaId);
  Future<void> incrementEpisodeViews(String episodeId);
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding);
  
  // Streams for real-time updates
  Stream<List<DramaModel>> featuredDramasStream();
  Stream<List<DramaModel>> trendingDramasStream();
  Stream<DramaModel> dramaStream(String dramaId);
  Stream<List<EpisodeModel>> dramaEpisodesStream(String dramaId);
  
  // File upload operations
  Future<String> uploadBannerImage(File imageFile, String dramaId);
  Future<String> uploadThumbnail(File imageFile, String episodeId);
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress});
}

// Firebase implementation
class FirebaseDramaRepository implements DramaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseDramaRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // ATOMIC DRAMA UNLOCK IMPLEMENTATION
  @override
  Future<bool> unlockDramaAtomic({
    required String userId,
    required String dramaId,
    required int unlockCost,
    required String dramaTitle,
  }) async {
    try {
      // Run as a single atomic transaction
      return await _firestore.runTransaction<bool>((transaction) async {
        
        // 1. READ PHASE - Get all required documents
        final userRef = _firestore.collection(Constants.users).doc(userId);
        final walletRef = _firestore.collection('wallets').doc(userId);
        final dramaRef = _firestore.collection(Constants.dramas).doc(dramaId);
        
        final userDoc = await transaction.get(userRef);
        final walletDoc = await transaction.get(walletRef);
        final dramaDoc = await transaction.get(dramaRef);
        
        // 2. VALIDATION PHASE - Check all conditions
        
        // Check if user exists
        if (!userDoc.exists) {
          throw const UserNotAuthenticatedException();
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final userUnlockedDramas = List<String>.from(userData['unlockedDramas'] ?? []);
        
        // Check if drama already unlocked
        if (userUnlockedDramas.contains(dramaId)) {
          throw const DramaAlreadyUnlockedException();
        }
        
        // Check if drama exists and is active
        if (!dramaDoc.exists) {
          throw const DramaNotFoundException();
        }
        
        final dramaData = dramaDoc.data() as Map<String, dynamic>;
        final isActive = dramaData['isActive'] ?? false;
        final isPremium = dramaData['isPremium'] ?? false;
        
        if (!isActive) {
          throw const DramaNotFoundException();
        }
        
        // Check if drama is actually premium (free dramas don't need unlocking)
        if (!isPremium) {
          throw const DramaUnlockException('This drama is free to watch', 'DRAMA_FREE');
        }
        
        // Check wallet and balance
        if (!walletDoc.exists) {
          // Create wallet if it doesn't exist (with 0 balance)
          final now = DateTime.now().microsecondsSinceEpoch.toString();
          transaction.set(walletRef, {
            'walletId': userId,
            'userId': userId,
            'userPhoneNumber': userData['phoneNumber'] ?? '',
            'userName': userData['name'] ?? '',
            'coinsBalance': 0,
            'lastUpdated': now,
            'createdAt': now,
          });
          throw const InsufficientFundsException();
        }
        
        final walletData = walletDoc.data() as Map<String, dynamic>;
        final currentBalance = (walletData['coinsBalance'] ?? 0) as int;
        
        // Check if user has enough coins
        if (currentBalance < unlockCost) {
          throw const InsufficientFundsException();
        }
        
        // 3. WRITE PHASE - Update all documents atomically
        
        final now = DateTime.now().microsecondsSinceEpoch.toString();
        final transactionId = _firestore.collection('wallet_transactions').doc().id;
        
        // Update wallet balance
        transaction.update(walletRef, {
          'coinsBalance': currentBalance - unlockCost,
          'lastUpdated': now,
        });
        
        // Add drama to user's unlocked dramas
        transaction.update(userRef, {
          'unlockedDramas': [...userUnlockedDramas, dramaId],
          'updatedAt': now,
        });
        
        // Create transaction record
        final transactionRef = _firestore.collection('wallet_transactions').doc(transactionId);
        transaction.set(transactionRef, {
          'transactionId': transactionId,
          'walletId': userId,
          'userId': userId,
          'userPhoneNumber': walletData['userPhoneNumber'] ?? '',
          'userName': walletData['userName'] ?? '',
          'type': 'drama_unlock',
          'coinAmount': unlockCost,
          'balanceBefore': currentBalance,
          'balanceAfter': currentBalance - unlockCost,
          'description': 'Unlocked: $dramaTitle',
          'referenceId': dramaId,
          'paymentMethod': null,
          'paymentReference': null,
          'packageId': null,
          'paidAmount': null,
          'createdAt': now,
          'metadata': {
            'dramaId': dramaId,
            'dramaTitle': dramaTitle,
            'unlockType': 'full_drama',
          },
        });
        
        // Optional: Update drama statistics (non-critical)
        try {
          transaction.update(dramaRef, {
            'unlockCount': FieldValue.increment(1),
            'revenue': FieldValue.increment(unlockCost),
            'updatedAt': now,
          });
        } catch (e) {
          // Don't fail the transaction if stats update fails
          print('Failed to update drama stats: $e');
        }
        
        return true;
      });
    } on DramaUnlockException {
      // Re-throw our custom exceptions
      rethrow;
    } catch (e) {
      // Wrap any other errors
      throw DramaUnlockException('Transaction failed: $e', 'TRANSACTION_FAILED');
    }
  }

  // EXISTING DRAMA OPERATIONS (unchanged)

  @override
  Future<List<DramaModel>> getAllDramas({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .orderBy(Constants.createdAt, descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFeaturedDramas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .where(Constants.isFeatured, isEqualTo: true)
          .orderBy(Constants.createdAt, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get featured dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getTrendingDramas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .orderBy(Constants.viewCount, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get trending dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getFreeDramas({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .where(Constants.isPremium, isEqualTo: false)
          .orderBy(Constants.createdAt, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get free dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> getPremiumDramas({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .where(Constants.isPremium, isEqualTo: true)
          .orderBy(Constants.createdAt, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get premium dramas: $e');
    }
  }

  @override
  Future<List<DramaModel>> searchDramas(String query, {int limit = 20}) async {
    try {
      // Simple title search - for better search, consider using Algolia or similar
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.isActive, isEqualTo: true)
          .orderBy(Constants.title)
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to search dramas: $e');
    }
  }

  @override
  Future<DramaModel?> getDramaById(String dramaId) async {
    try {
      final doc = await _firestore.collection(Constants.dramas).doc(dramaId).get();
      if (!doc.exists) return null;
      return DramaModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw DramaRepositoryException('Failed to get drama: $e');
    }
  }

  // ADMIN DRAMA OPERATIONS (unchanged)

  @override
  Future<String> createDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      final docRef = _firestore.collection(Constants.dramas).doc();
      final dramaId = docRef.id;

      String bannerUrl = '';
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, dramaId);
      }

      final now = DateTime.now().microsecondsSinceEpoch.toString();
      final finalDrama = drama.copyWith(
        dramaId: dramaId,
        bannerImage: bannerUrl,
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      );

      await docRef.set(finalDrama.toMap());
      return dramaId;
    } catch (e) {
      throw DramaRepositoryException('Failed to create drama: $e');
    }
  }

  @override
  Future<void> updateDrama(DramaModel drama, {File? bannerImage}) async {
    try {
      String bannerUrl = drama.bannerImage;
      if (bannerImage != null) {
        bannerUrl = await uploadBannerImage(bannerImage, drama.dramaId);
      }

      final updatedDrama = drama.copyWith(
        bannerImage: bannerUrl,
        updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
      );

      await _firestore
          .collection(Constants.dramas)
          .doc(drama.dramaId)
          .update(updatedDrama.toMap());
    } catch (e) {
      throw DramaRepositoryException('Failed to update drama: $e');
    }
  }

  @override
  Future<void> deleteDrama(String dramaId) async {
    try {
      // Delete all episodes first
      final episodes = await getDramaEpisodes(dramaId);
      for (final episode in episodes) {
        await deleteEpisode(episode.episodeId, dramaId);
      }

      // Delete drama
      await _firestore.collection(Constants.dramas).doc(dramaId).delete();
    } catch (e) {
      throw DramaRepositoryException('Failed to delete drama: $e');
    }
  }

  @override
  Future<List<DramaModel>> getDramasByAdmin(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.dramas)
          .where(Constants.createdBy, isEqualTo: adminId)
          .orderBy(Constants.createdAt, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get admin dramas: $e');
    }
  }

  @override
  Future<void> toggleDramaFeatured(String dramaId, bool isFeatured) async {
    try {
      await _firestore
          .collection(Constants.dramas)
          .doc(dramaId)
          .update({
            Constants.isFeatured: isFeatured,
            Constants.updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
          });
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle featured status: $e');
    }
  }

  @override
  Future<void> toggleDramaActive(String dramaId, bool isActive) async {
    try {
      await _firestore
          .collection(Constants.dramas)
          .doc(dramaId)
          .update({
            Constants.isActive: isActive,
            Constants.updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
          });
    } catch (e) {
      throw DramaRepositoryException('Failed to toggle active status: $e');
    }
  }

  // EPISODE OPERATIONS (unchanged)

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String dramaId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.episodes)
          .where(Constants.dramaId, isEqualTo: dramaId)
          .orderBy(Constants.episodeNumber)
          .get();

      return snapshot.docs
          .map((doc) => EpisodeModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DramaRepositoryException('Failed to get episodes: $e');
    }
  }

  @override
  Future<EpisodeModel?> getEpisodeById(String episodeId) async {
    try {
      final doc = await _firestore.collection(Constants.episodes).doc(episodeId).get();
      if (!doc.exists) return null;
      return EpisodeModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw DramaRepositoryException('Failed to get episode: $e');
    }
  }

  @override
  Future<String> addEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    try {
      final docRef = _firestore.collection(Constants.episodes).doc();
      final episodeId = docRef.id;

      String thumbnailUrl = '';
      String videoUrl = '';

      // Upload files
      if (thumbnailImage != null) {
        thumbnailUrl = await uploadThumbnail(thumbnailImage, episodeId);
      }
      if (videoFile != null) {
        videoUrl = await uploadVideo(videoFile, episodeId);
      }

      final now = DateTime.now().microsecondsSinceEpoch.toString();
      final finalEpisode = episode.copyWith(
        episodeId: episodeId,
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        createdAt: now,
        updatedAt: now,
        releasedAt: now,
      );

      await docRef.set(finalEpisode.toMap());

      // Update drama's total episodes count
      await _updateDramaTotalEpisodes(episode.dramaId);

      return episodeId;
    } catch (e) {
      throw DramaRepositoryException('Failed to add episode: $e');
    }
  }

  @override
  Future<void> updateEpisode(EpisodeModel episode, {File? thumbnailImage, File? videoFile}) async {
    try {
      String thumbnailUrl = episode.thumbnailUrl;
      String videoUrl = episode.videoUrl;

      // Upload new files if provided
      if (thumbnailImage != null) {
        thumbnailUrl = await uploadThumbnail(thumbnailImage, episode.episodeId);
      }
      if (videoFile != null) {
        videoUrl = await uploadVideo(videoFile, episode.episodeId);
      }

      final updatedEpisode = episode.copyWith(
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
      );

      await _firestore
          .collection(Constants.episodes)
          .doc(episode.episodeId)
          .update(updatedEpisode.toMap());
    } catch (e) {
      throw DramaRepositoryException('Failed to update episode: $e');
    }
  }

  @override
  Future<void> deleteEpisode(String episodeId, String dramaId) async {
    try {
      await _firestore.collection(Constants.episodes).doc(episodeId).delete();
      await _updateDramaTotalEpisodes(dramaId);
    } catch (e) {
      throw DramaRepositoryException('Failed to delete episode: $e');
    }
  }

  // USER INTERACTION OPERATIONS (unchanged)

  @override
  Future<void> incrementDramaViews(String dramaId) async {
    try {
      await _firestore.collection(Constants.dramas).doc(dramaId).update({
        Constants.viewCount: FieldValue.increment(1),
      });
    } catch (e) {
      // Don't throw error for view counting
      print('Failed to increment drama views: $e');
    }
  }

  @override
  Future<void> incrementEpisodeViews(String episodeId) async {
    try {
      await _firestore.collection(Constants.episodes).doc(episodeId).update({
        Constants.episodeViewCount: FieldValue.increment(1),
      });
    } catch (e) {
      // Don't throw error for view counting
      print('Failed to increment episode views: $e');
    }
  }

  @override
  Future<void> incrementDramaFavorites(String dramaId, bool isAdding) async {
    try {
      await _firestore.collection(Constants.dramas).doc(dramaId).update({
        Constants.favoriteCount: FieldValue.increment(isAdding ? 1 : -1),
      });
    } catch (e) {
      // Don't throw error for favorite counting
      print('Failed to update drama favorites: $e');
    }
  }

  // STREAMS (unchanged)

  @override
  Stream<List<DramaModel>> featuredDramasStream() {
    return _firestore
        .collection(Constants.dramas)
        .where(Constants.isActive, isEqualTo: true)
        .where(Constants.isFeatured, isEqualTo: true)
        .orderBy(Constants.createdAt, descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Stream<List<DramaModel>> trendingDramasStream() {
    return _firestore
        .collection(Constants.dramas)
        .where(Constants.isActive, isEqualTo: true)
        .orderBy(Constants.viewCount, descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  @override
  Stream<DramaModel> dramaStream(String dramaId) {
    return _firestore
        .collection(Constants.dramas)
        .doc(dramaId)
        .snapshots()
        .map((doc) => DramaModel.fromMap(doc.data() as Map<String, dynamic>));
  }

  @override
  Stream<List<EpisodeModel>> dramaEpisodesStream(String dramaId) {
    return _firestore
        .collection(Constants.episodes)
        .where(Constants.dramaId, isEqualTo: dramaId)
        .orderBy(Constants.episodeNumber)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EpisodeModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // FILE UPLOAD OPERATIONS (unchanged)

  @override
  Future<String> uploadBannerImage(File imageFile, String dramaId) async {
    try {
      final ref = _storage.ref().child('${Constants.dramaBanners}/$dramaId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw DramaRepositoryException('Failed to upload banner: $e');
    }
  }

  @override
  Future<String> uploadThumbnail(File imageFile, String episodeId) async {
    try {
      final ref = _storage.ref().child('${Constants.episodeThumbnails}/$episodeId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw DramaRepositoryException('Failed to upload thumbnail: $e');
    }
  }

  @override
  Future<String> uploadVideo(File videoFile, String episodeId, {Function(double)? onProgress}) async {
    try {
      final ref = _storage.ref().child('${Constants.episodeVideos}/$episodeId.mp4');
      final uploadTask = ref.putFile(videoFile);

      // Listen to progress if callback provided
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw DramaRepositoryException('Failed to upload video: $e');
    }
  }

  // HELPER METHODS

  Future<void> _updateDramaTotalEpisodes(String dramaId) async {
    try {
      final episodes = await getDramaEpisodes(dramaId);
      await _firestore.collection(Constants.dramas).doc(dramaId).update({
        Constants.totalEpisodes: episodes.length,
        Constants.updatedAt: DateTime.now().microsecondsSinceEpoch.toString(),
      });
    } catch (e) {
      print('Failed to update drama total episodes: $e');
    }
  }
}

// Exception class for drama repository errors
class DramaRepositoryException implements Exception {
  final String message;
  const DramaRepositoryException(this.message);
  
  @override
  String toString() => 'DramaRepositoryException: $message';
}