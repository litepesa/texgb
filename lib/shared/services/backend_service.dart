// ===============================
// lib/shared/services/backend_service.dart - Service Layer
// ===============================

import 'dart:io';

import 'package:textgb/models/drama_model.dart';
import 'package:textgb/models/episode_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/services/api_service.dart';

class BackendService {
  // ===== USER ENDPOINTS =====
  
  static Future<void> createUser(UserModel user) async {
    await ApiService.post('/users', body: user.toMap());
  }
  
  static Future<UserModel> getUser(String uid) async {
    final data = await ApiService.get('/users/$uid');
    return UserModel.fromMap(data);
  }
  
  static Future<void> updateUser(UserModel user) async {
    await ApiService.put('/users/${user.uid}', body: user.toMap());
  }
  
  static Future<void> toggleFavorite(String uid, String dramaId, bool isFavorite) async {
    await ApiService.post('/users/$uid/favorites', body: {
      'dramaId': dramaId,
      'action': isFavorite ? 'add' : 'remove',
    });
  }
  
  static Future<void> addToWatchHistory(String uid, String episodeId) async {
    await ApiService.post('/users/$uid/watch-history', body: {
      'episodeId': episodeId,
    });
  }
  
  static Future<void> updateDramaProgress(String uid, String dramaId, int episodeNumber) async {
    await ApiService.post('/users/$uid/drama-progress', body: {
      'dramaId': dramaId,
      'episodeNumber': episodeNumber,
    });
  }
  
  static Future<List<DramaModel>> getUserFavorites(String uid) async {
    final data = await ApiService.get('/users/$uid/favorites');
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  static Future<List<DramaModel>> getContinueWatching(String uid) async {
    final data = await ApiService.get('/users/$uid/continue-watching');
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  // ===== DRAMA ENDPOINTS =====
  
  static Future<List<DramaModel>> getDramas({int limit = 20}) async {
    final data = await ApiService.get('/dramas?limit=$limit', requireAuth: false);
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  static Future<List<DramaModel>> getFeaturedDramas({int limit = 10}) async {
    final data = await ApiService.get('/dramas/featured?limit=$limit', requireAuth: false);
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  static Future<List<DramaModel>> getTrendingDramas({int limit = 10}) async {
    final data = await ApiService.get('/dramas/trending?limit=$limit', requireAuth: false);
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  static Future<List<DramaModel>> searchDramas(String query, {int limit = 20}) async {
    final data = await ApiService.get('/dramas/search?q=${Uri.encodeComponent(query)}&limit=$limit', requireAuth: false);
    return (data as List).map((item) => DramaModel.fromMap(item)).toList();
  }
  
  static Future<DramaModel> getDrama(String dramaId) async {
    final data = await ApiService.get('/dramas/$dramaId', requireAuth: false);
    return DramaModel.fromMap(data);
  }
  
  static Future<Map<String, dynamic>> unlockDrama(String dramaId) async {
    final data = await ApiService.post('/unlock-drama', body: {
      'dramaId': dramaId,
    });
    return data;
  }
  
  // ===== EPISODE ENDPOINTS =====
  
  static Future<List<EpisodeModel>> getDramaEpisodes(String dramaId) async {
    final data = await ApiService.get('/dramas/$dramaId/episodes', requireAuth: false);
    return (data as List).map((item) => EpisodeModel.fromMap(item)).toList();
  }
  
  static Future<EpisodeModel> getEpisode(String episodeId) async {
    final data = await ApiService.get('/episodes/$episodeId', requireAuth: false);
    return EpisodeModel.fromMap(data);
  }
  
  // ===== WALLET ENDPOINTS =====
  
  static Future<Map<String, dynamic>> getWallet(String userId) async {
    final data = await ApiService.get('/wallet/$userId');
    return data;
  }
  
  static Future<List<Map<String, dynamic>>> getWalletTransactions(String userId, {int limit = 50}) async {
    final data = await ApiService.get('/wallet/$userId/transactions?limit=$limit');
    return List<Map<String, dynamic>>.from(data);
  }
  
  static Future<Map<String, dynamic>> createPurchaseRequest(String userId, {
    required String packageId,
    required String paymentReference,
    String paymentMethod = 'mpesa',
  }) async {
    final data = await ApiService.post('/wallet/$userId/purchase-request', body: {
      'packageId': packageId,
      'paymentReference': paymentReference,
      'paymentMethod': paymentMethod,
    });
    return data;
  }
  
  // ===== FILE UPLOAD =====
  
  static Future<String> uploadFile(File file, String fileType) async {
    return await ApiService.uploadFile(file, fileType);
  }
  
  // ===== ADMIN ENDPOINTS =====
  
  static Future<String> createDrama(DramaModel drama) async {
    final data = await ApiService.post('/admin/dramas', body: drama.toMap());
    return data['dramaId'];
  }
  
  static Future<void> updateDrama(DramaModel drama) async {
    await ApiService.put('/admin/dramas/${drama.dramaId}', body: drama.toMap());
  }
  
  static Future<void> deleteDrama(String dramaId) async {
    await ApiService.delete('/admin/dramas/$dramaId');
  }
  
  static Future<String> createEpisode(String dramaId, EpisodeModel episode) async {
    final data = await ApiService.post('/admin/dramas/$dramaId/episodes', body: episode.toMap());
    return data['episodeId'];
  }
  
  static Future<void> updateEpisode(EpisodeModel episode) async {
    await ApiService.put('/admin/episodes/${episode.episodeId}', body: episode.toMap());
  }
  
  static Future<void> deleteEpisode(String episodeId) async {
    await ApiService.delete('/admin/episodes/$episodeId');
  }
  
  static Future<Map<String, dynamic>> getAdminStats() async {
    final data = await ApiService.get('/admin/stats');
    return data;
  }
  
  static Future<List<Map<String, dynamic>>> getPendingPurchases({int limit = 50}) async {
    final data = await ApiService.get('/admin/purchase-requests?limit=$limit');
    return List<Map<String, dynamic>>.from(data);
  }
  
  static Future<void> approvePurchase(String requestId, {String? adminNote}) async {
    await ApiService.post('/admin/purchase-requests/$requestId/approve', body: {
      if (adminNote != null) 'adminNote': adminNote,
    });
  }
  
  static Future<void> rejectPurchase(String requestId, String adminNote) async {
    await ApiService.post('/admin/purchase-requests/$requestId/reject', body: {
      'adminNote': adminNote,
    });
  }
}