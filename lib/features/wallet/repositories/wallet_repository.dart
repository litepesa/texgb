// lib/features/wallet/repositories/wallet_repository.dart
// FIXED VERSION - Add null safety checks

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
      final response = await _httpClient.get('/wallet/$userId');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return null;
        }
        
        final walletData = jsonDecode(responseBody);
        // Add null check for wallet data
        if (walletData == null) {
          return null;
        }
        
        return WalletModel.fromMap(walletData as Map<String, dynamic>);
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
      final response = await _httpClient.post('/wallet', body: {
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
      final response = await _httpClient.post('/wallet/$userId/unlock-episode', body: {
        'episodeId': episodeId,
        'coinAmount': coinAmount,
        'description': description,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return false;
        }
        
        final errorData = jsonDecode(responseBody);
        if (errorData == null) {
          return false;
        }
        
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
      final response = await _httpClient.post('/wallet/$userId/purchase-request', body: {
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
  // TRANSACTION OPERATIONS (HTTP BACKEND) - FIXED
  // ===============================

  @override
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  }) async {
    try {
      String endpoint = '/wallet/$userId/transactions?limit=$limit';
      if (lastTransactionId != null) {
        endpoint += '&after=$lastTransactionId';
      }

      final response = await _httpClient.get(endpoint);
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        
        // Handle empty or null response
        if (responseBody.isEmpty || responseBody == 'null') {
          return <WalletTransaction>[];
        }
        
        final decodedData = jsonDecode(responseBody);
        
        // Handle null response data
        if (decodedData == null) {
          return <WalletTransaction>[];
        }
        
        // Handle case where response is not a list
        if (decodedData is! List) {
          // If it's a map with a transactions field
          if (decodedData is Map<String, dynamic> && decodedData.containsKey('transactions')) {
            final transactionsData = decodedData['transactions'];
            if (transactionsData == null) {
              return <WalletTransaction>[];
            }
            if (transactionsData is List) {
              return transactionsData
                  .where((item) => item != null)
                  .map((data) => WalletTransaction.fromMap(data as Map<String, dynamic>))
                  .toList();
            }
          }
          // If it's some other structure, return empty list
          return <WalletTransaction>[];
        }
        
        // Handle normal list response
        final List<dynamic> transactionsData = decodedData;
        return transactionsData
            .where((item) => item != null) // Filter out null items
            .map((data) => WalletTransaction.fromMap(data as Map<String, dynamic>))
            .toList();
            
      } else if (response.statusCode == 404) {
        // User has no transactions yet
        return <WalletTransaction>[];
      } else {
        throw WalletRepositoryException('Failed to get wallet transactions: ${response.body}');
      }
    } catch (e) {
      // If it's a parsing error, return empty list instead of throwing
      if (e is FormatException || e.toString().contains('subtype')) {
        print('Warning: Failed to parse transactions data: $e');
        return <WalletTransaction>[];
      }
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
  // ADDITIONAL UTILITY METHODS (HTTP BACKEND) - ALSO FIXED
  // ===============================

  /// Get total coins spent by user
  Future<int> getTotalCoinsSpent(String userId) async {
    try {
      final response = await _httpClient.get('/wallet/$userId/stats/spent');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return 0;
        }
        
        final data = jsonDecode(responseBody);
        if (data == null || data is! Map<String, dynamic>) {
          return 0;
        }
        
        return (data['totalSpent'] as int?) ?? 0;
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
      final response = await _httpClient.get('/wallet/$userId/stats/purchased');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return 0;
        }
        
        final data = jsonDecode(responseBody);
        if (data == null || data is! Map<String, dynamic>) {
          return 0;
        }
        
        return (data['totalPurchased'] as int?) ?? 0;
      } else {
        throw WalletRepositoryException('Failed to get total coins purchased: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get total coins purchased: $e');
    }
  }

  /// Get transactions by type - FIXED
  Future<List<WalletTransaction>> getTransactionsByType(String userId, String type, {
    int limit = 50,
  }) async {
    try {
      final response = await _httpClient.get('/wallet/$userId/transactions?type=$type&limit=$limit');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return <WalletTransaction>[];
        }
        
        final decodedData = jsonDecode(responseBody);
        if (decodedData == null || decodedData is! List) {
          return <WalletTransaction>[];
        }
        
        final List<dynamic> transactionsData = decodedData;
        return transactionsData
            .where((item) => item != null)
            .map((data) => WalletTransaction.fromMap(data as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return <WalletTransaction>[];
      } else {
        throw WalletRepositoryException('Failed to get transactions by type: ${response.body}');
      }
    } catch (e) {
      if (e is FormatException || e.toString().contains('subtype')) {
        print('Warning: Failed to parse transactions by type: $e');
        return <WalletTransaction>[];
      }
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

  /// Get wallet statistics for a user - FIXED
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final response = await _httpClient.get('/wallet/$userId/stats');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return <String, dynamic>{};
        }
        
        final data = jsonDecode(responseBody);
        if (data == null) {
          return <String, dynamic>{};
        }
        
        return data as Map<String, dynamic>;
      } else {
        throw WalletRepositoryException('Failed to get wallet stats: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet stats: $e');
    }
  }

  // ... rest of the admin methods remain the same with similar null safety checks
  
  /// Admin method: Get all pending coin purchases - FIXED
  Future<List<Map<String, dynamic>>> getPendingCoinPurchases() async {
    try {
      final response = await _httpClient.get('/admin/wallet/pending-purchases');
      
      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return <Map<String, dynamic>>[];
        }
        
        final decodedData = jsonDecode(responseBody);
        if (decodedData == null || decodedData is! List) {
          return <Map<String, dynamic>>[];
        }
        
        final List<dynamic> purchasesData = decodedData;
        return purchasesData
            .where((item) => item != null)
            .map((data) => data as Map<String, dynamic>)
            .toList();
      } else {
        throw WalletRepositoryException('Failed to get pending purchases: ${response.body}');
      }
    } catch (e) {
      if (e is FormatException || e.toString().contains('subtype')) {
        print('Warning: Failed to parse pending purchases: $e');
        return <Map<String, dynamic>>[];
      }
      throw WalletRepositoryException('Failed to get pending purchases: $e');
    }
  }

  /// Admin method: Approve coin purchase
  Future<void> approveCoinPurchase(String requestId, String adminNote) async {
    try {
      final response = await _httpClient.post('/admin/wallet/approve-purchase/$requestId', body: {
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
      final response = await _httpClient.post('/admin/wallet/reject-purchase/$requestId', body: {
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
      final response = await _httpClient.post('/admin/wallet/$userId/add-coins', body: {
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
  Future<void> batchUpdateWallet(List<Map<String, dynamic>> updates) async {
    try {
      final response = await _httpClient.post('/admin/wallet/batch-update', body: {
        'updates': updates,
      });

      if (response.statusCode != 200) {
        throw WalletRepositoryException('Failed to batch update wallet: ${response.body}');
      }
    } catch (e) {
      throw WalletRepositoryException('Failed to batch update wallet: $e');
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