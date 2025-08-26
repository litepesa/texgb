// lib/features/wallet/repositories/wallet_repository.dart
import 'dart:convert';
import 'package:textgb/constants.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/services/http_client.dart';

// Abstract wallet repository interface (unchanged)
abstract class WalletRepository {
  // Wallet operations (READ-ONLY)
  Future<WalletModel?> getUserWallet(String userId);
  Future<void> createWallet(String userId, String userPhoneNumber, String userName);
  
  // Request operations (backend processes these)
  Future<bool> requestEpisodeUnlock(String userId, String episodeId, int coinAmount, String description);
  Future<bool> submitCoinPurchaseRequest(String userId, CoinPackage package, String paymentReference);
  
  // Transaction operations (READ-ONLY)
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  });
  
  // Streams (deprecated for HTTP backend)
  Stream<WalletModel?> walletStream(String userId);
  Stream<List<WalletTransaction>> transactionsStream(String userId);
}

// HTTP Backend implementation
class HttpWalletRepository implements WalletRepository {
  final HttpClientService _httpClient;

  HttpWalletRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // WALLET OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<WalletModel?> getUserWallet(String userId) async {
    try {
      final response = await _httpClient.get('/wallets/$userId');
      
      if (response.statusCode == 200) {
        final walletData = jsonDecode(response.body) as Map<String, dynamic>;
        return WalletModel.fromMap(walletData);
      } else if (response.statusCode == 404) {
        // Wallet doesn't exist, backend will create it automatically
        return null;
      } else {
        throw WalletRepositoryException('Failed to get user wallet: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw WalletRepositoryException('Failed to get user wallet: $e');
    }
  }

  @override
  Future<void> createWallet(String userId, String userPhoneNumber, String userName) async {
    try {
      final response = await _httpClient.post('/wallets', body: {
        'userId': userId,
        'userPhoneNumber': userPhoneNumber,
        'userName': userName,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw WalletRepositoryException('Failed to create wallet: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to create wallet: $e');
    }
  }

  // ===============================
  // REQUEST OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<bool> requestEpisodeUnlock(String userId, String episodeId, int coinAmount, String description) async {
    try {
      final response = await _httpClient.post('/wallets/$userId/unlock-episode', body: {
        'episodeId': episodeId,
        'coinAmount': coinAmount,
        'description': description,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Unknown error';
        
        // Handle specific errors
        switch (errorMessage) {
          case 'Insufficient coins':
          case 'insufficient_funds':
            return false; // Not enough coins
          default:
            throw WalletRepositoryException('Failed to request episode unlock: $errorMessage');
        }
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to request episode unlock: $e');
    }
  }

  @override
  Future<bool> submitCoinPurchaseRequest(String userId, CoinPackage package, String paymentReference) async {
    try {
      final response = await _httpClient.post('/wallets/$userId/purchase-request', body: {
        'packageId': package.packageId,
        'paymentReference': paymentReference,
        'paymentMethod': 'mpesa',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw WalletRepositoryException('Failed to submit coin purchase request: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to submit coin purchase request: $e');
    }
  }

  // ===============================
  // TRANSACTION OPERATIONS (HTTP BACKEND)
  // ===============================

  @override
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  }) async {
    try {
      String endpoint = '/wallets/$userId/transactions?limit=$limit';
      if (lastTransactionId != null) {
        endpoint += '&after=$lastTransactionId';
      }

      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> transactionsData = jsonDecode(response.body);
        return transactionsData
            .map((data) => WalletTransaction.fromMap(data as Map<String, dynamic>))
            .toList();
      } else {
        throw WalletRepositoryException('Failed to get wallet transactions: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet transactions: $e');
    }
  }

  // ===============================
  // DEPRECATED STREAM METHODS
  // ===============================

  @override
  Stream<WalletModel?> walletStream(String userId) {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  @override
  Stream<List<WalletTransaction>> transactionsStream(String userId) {
    throw UnsupportedError('Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  // ===============================
  // ADDITIONAL UTILITY METHODS (HTTP BACKEND)
  // ===============================

  /// Get total coins spent by user
  Future<int> getTotalCoinsSpent(String userId) async {
    try {
      final response = await _httpClient.get('/wallets/$userId/stats/spent');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['totalSpent'] as int;
      } else {
        throw WalletRepositoryException('Failed to get total coins spent: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get total coins spent: $e');
    }
  }

  /// Get total coins purchased by user
  Future<int> getTotalCoinsPurchased(String userId) async {
    try {
      final response = await _httpClient.get('/wallets/$userId/stats/purchased');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['totalPurchased'] as int;
      } else {
        throw WalletRepositoryException('Failed to get total coins purchased: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get total coins purchased: $e');
    }
  }

  /// Get transactions by type
  Future<List<WalletTransaction>> getTransactionsByType(String userId, String type, {
    int limit = 50,
  }) async {
    try {
      final response = await _httpClient.get('/wallets/$userId/transactions?type=$type&limit=$limit');
      
      if (response.statusCode == 200) {
        final List<dynamic> transactionsData = jsonDecode(response.body);
        return transactionsData
            .map((data) => WalletTransaction.fromMap(data as Map<String, dynamic>))
            .toList();
      } else {
        throw WalletRepositoryException('Failed to get transactions by type: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get transactions by type: $e');
    }
  }

  /// Check if user has enough coins for a purchase
  Future<bool> hasEnoughCoins(String userId, int requiredCoins) async {
    try {
      final wallet = await getUserWallet(userId);
      return wallet?.canAfford(requiredCoins) ?? false;
    } catch (e) {
      throw WalletRepositoryException('Failed to check coin balance: $e');
    }
  }

  /// Get user's coin purchase history
  Future<List<WalletTransaction>> getCoinPurchaseHistory(String userId) async {
    try {
      return await getTransactionsByType(userId, 'coin_purchase');
    } catch (e) {
      throw WalletRepositoryException('Failed to get coin purchase history: $e');
    }
  }

  /// Get user's episode unlock history
  Future<List<WalletTransaction>> getEpisodeUnlockHistory(String userId) async {
    try {
      return await getTransactionsByType(userId, 'episode_unlock');
    } catch (e) {
      throw WalletRepositoryException('Failed to get episode unlock history: $e');
    }
  }

  /// Get user's drama unlock history
  Future<List<WalletTransaction>> getDramaUnlockHistory(String userId) async {
    try {
      return await getTransactionsByType(userId, 'drama_unlock');
    } catch (e) {
      throw WalletRepositoryException('Failed to get drama unlock history: $e');
    }
  }

  /// Get wallet statistics for a user
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final response = await _httpClient.get('/wallets/$userId/stats');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw WalletRepositoryException('Failed to get wallet stats: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet stats: $e');
    }
  }

  /// Admin method: Get all pending coin purchases
  Future<List<Map<String, dynamic>>> getPendingCoinPurchases() async {
    try {
      final response = await _httpClient.get('/admin/wallets/pending-purchases');
      
      if (response.statusCode == 200) {
        final List<dynamic> purchasesData = jsonDecode(response.body);
        return purchasesData.map((data) => data as Map<String, dynamic>).toList();
      } else {
        throw WalletRepositoryException('Failed to get pending purchases: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get pending purchases: $e');
    }
  }

  /// Admin method: Approve coin purchase
  Future<void> approveCoinPurchase(String requestId, String adminNote) async {
    try {
      final response = await _httpClient.post('/admin/wallets/approve-purchase/$requestId', body: {
        'adminNote': adminNote,
      });

      if (response.statusCode != 200) {
        throw WalletRepositoryException('Failed to approve purchase: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to approve purchase: $e');
    }
  }

  /// Admin method: Reject coin purchase
  Future<void> rejectCoinPurchase(String requestId, String adminNote) async {
    try {
      final response = await _httpClient.post('/admin/wallets/reject-purchase/$requestId', body: {
        'adminNote': adminNote,
      });

      if (response.statusCode != 200) {
        throw WalletRepositoryException('Failed to reject purchase: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to reject purchase: $e');
    }
  }

  /// Admin method: Add coins manually
  Future<void> addCoinsManually(String userId, int coinAmount, String description, String adminNote) async {
    try {
      final response = await _httpClient.post('/admin/wallets/$userId/add-coins', body: {
        'coinAmount': coinAmount,
        'description': description,
        'adminNote': adminNote,
      });

      if (response.statusCode != 200) {
        throw WalletRepositoryException('Failed to add coins: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to add coins: $e');
    }
  }

  /// Batch update wallet balances (admin utility)
  Future<void> batchUpdateWallets(List<Map<String, dynamic>> updates) async {
    try {
      final response = await _httpClient.post('/admin/wallets/batch-update', body: {
        'updates': updates,
      });

      if (response.statusCode != 200) {
        throw WalletRepositoryException('Failed to batch update wallets: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to batch update wallets: $e');
    }
  }
}

// Keep existing Firebase implementation for backward compatibility
class FirebaseWalletRepository implements WalletRepository {
  // ... existing Firebase implementation remains for reference
  // This allows gradual migration if needed
  
  @override
  Future<WalletModel?> getUserWallet(String userId) async {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Future<void> createWallet(String userId, String userPhoneNumber, String userName) async {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Future<bool> requestEpisodeUnlock(String userId, String episodeId, int coinAmount, String description) async {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Future<bool> submitCoinPurchaseRequest(String userId, CoinPackage package, String paymentReference) async {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  }) async {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Stream<WalletModel?> walletStream(String userId) {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }

  @override
  Stream<List<WalletTransaction>> transactionsStream(String userId) {
    throw UnimplementedError('Use HttpWalletRepository for new backend');
  }
}

// Exception class for wallet repository errors (unchanged)
class WalletRepositoryException implements Exception {
  final String message;
  const WalletRepositoryException(this.message);
  
  @override
  String toString() => 'WalletRepositoryException: $message';
}