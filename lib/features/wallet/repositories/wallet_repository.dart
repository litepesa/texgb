// lib/features/wallet/repositories/wallet_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';

// Abstract wallet repository interface - READ-ONLY for frontend
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
  
  // Streams (READ-ONLY)
  Stream<WalletModel?> walletStream(String userId);
  Stream<List<WalletTransaction>> transactionsStream(String userId);
}

// Firebase implementation
class FirebaseWalletRepository implements WalletRepository {
  final FirebaseFirestore _firestore;
  final String _walletsCollection;
  final String _transactionsCollection;

  FirebaseWalletRepository({
    FirebaseFirestore? firestore,
    String walletsCollection = 'wallets',
    String transactionsCollection = 'wallet_transactions',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _walletsCollection = walletsCollection,
       _transactionsCollection = transactionsCollection;

  @override
  Future<WalletModel?> getUserWallet(String userId) async {
    try {
      // Check if wallet exists
      DocumentSnapshot walletDoc = await _firestore
          .collection(_walletsCollection)
          .doc(userId)
          .get();

      if (!walletDoc.exists) {
        // Get user info to create wallet
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userPhoneNumber = userData['phoneNumber'] ?? '';
          final userName = userData['name'] ?? '';
          
          // Create wallet if it doesn't exist
          await createWallet(userId, userPhoneNumber, userName);
          walletDoc = await _firestore
              .collection(_walletsCollection)
              .doc(userId)
              .get();
        }
      }

      if (walletDoc.exists) {
        return WalletModel.fromMap(walletDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      throw WalletRepositoryException('Failed to get user wallet: $e');
    }
  }

  @override
  Future<void> createWallet(String userId, String userPhoneNumber, String userName) async {
    try {
      final now = DateTime.now().microsecondsSinceEpoch.toString();
      final walletModel = WalletModel(
        walletId: userId, // Use userId as walletId for simplicity
        userId: userId,
        userPhoneNumber: userPhoneNumber,
        userName: userName,
        coinsBalance: 0, // Start with 0 coins
        lastUpdated: now,
        createdAt: now,
      );

      await _firestore
          .collection(_walletsCollection)
          .doc(userId)
          .set(walletModel.toMap());
    } catch (e) {
      throw WalletRepositoryException('Failed to create wallet: $e');
    }
  }

  // Request episode unlock - backend AUTOMATICALLY processes this
  @override
  Future<bool> requestEpisodeUnlock(String userId, String episodeId, int coinAmount, String description) async {
    try {
      // This calls a backend Cloud Function or API that:
      // 1. Verifies user has enough coins
      // 2. Deducts coins atomically  
      // 3. Grants episode access immediately
      // 4. Logs transaction
      // NO ADMIN INTERVENTION REQUIRED!
      
      // In Firebase, this would be a Cloud Function call
      // For now, simulating with a direct request that backend processes automatically
      final unlockRequest = {
        'userId': userId,
        'episodeId': episodeId,
        'coinAmount': coinAmount,
        'description': description,
        'status': 'processing', // Backend will process this automatically
        'requestedAt': DateTime.now().microsecondsSinceEpoch.toString(),
        'type': 'episode_unlock', // Automatic processing
      };
      
      await _firestore
          .collection('episode_unlock_requests')
          .add(unlockRequest);
      
      // In production, this would be a Cloud Function HTTP call like:
      // final response = await http.post('/unlockEpisode', body: unlockRequest);
      // return response.statusCode == 200;
      
      return true;
    } catch (e) {
      throw WalletRepositoryException('Failed to request episode unlock: $e');
    }
  }

  // Submit coin purchase request - admin MANUALLY verifies payment
  @override
  Future<bool> submitCoinPurchaseRequest(String userId, CoinPackage package, String paymentReference) async {
    try {
      // This creates a purchase request that admin manually verifies
      // because M-Pesa payments need human verification for security
      final purchaseRequest = {
        'userId': userId,
        'packageId': package.packageId,
        'coinAmount': package.coins,
        'paidAmount': package.priceKES,
        'paymentReference': paymentReference,
        'paymentMethod': 'mpesa',
        'status': 'pending_admin_verification', // Needs admin verification
        'requestedAt': DateTime.now().microsecondsSinceEpoch.toString(),
        'type': 'coin_purchase', // Manual admin processing
        'packageDetails': {
          'name': package.displayName,
          'coins': package.coins,
          'price': package.priceKES,
        }
      };
      
      await _firestore
          .collection('coin_purchase_requests')
          .add(purchaseRequest);
      
      return true;
    } catch (e) {
      throw WalletRepositoryException('Failed to submit coin purchase request: $e');
    }
  }

  @override
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  }) async {
    try {
      Query query = _firestore
          .collection(_transactionsCollection)
          .where('walletId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastTransactionId != null) {
        DocumentSnapshot lastDoc = await _firestore
            .collection(_transactionsCollection)
            .doc(lastTransactionId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      QuerySnapshot querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => WalletTransaction.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet transactions: $e');
    }
  }

  @override
  Stream<WalletModel?> walletStream(String userId) {
    return _firestore
        .collection(_walletsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return WalletModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  @override
  Stream<List<WalletTransaction>> transactionsStream(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('walletId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletTransaction.fromMap(
                doc.data()))
            .toList());
  }

  // Additional utility methods

  /// Get total coins spent by user
  Future<int> getTotalCoinsSpent(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('walletId', isEqualTo: userId)
          .where('type', isEqualTo: 'episode_unlock')
          .get();
      
      int totalSpent = 0;
      for (var doc in querySnapshot.docs) {
        final transaction = WalletTransaction.fromMap(doc.data() as Map<String, dynamic>);
        totalSpent += transaction.coinAmount;
      }
      
      return totalSpent;
    } catch (e) {
      throw WalletRepositoryException('Failed to get total coins spent: $e');
    }
  }

  /// Get total coins purchased by user
  Future<int> getTotalCoinsPurchased(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('walletId', isEqualTo: userId)
          .where('type', whereIn: ['coin_purchase', 'admin_credit'])
          .get();
      
      int totalPurchased = 0;
      for (var doc in querySnapshot.docs) {
        final transaction = WalletTransaction.fromMap(doc.data() as Map<String, dynamic>);
        totalPurchased += transaction.coinAmount;
      }
      
      return totalPurchased;
    } catch (e) {
      throw WalletRepositoryException('Failed to get total coins purchased: $e');
    }
  }

  /// Get transactions by type
  Future<List<WalletTransaction>> getTransactionsByType(String userId, String type, {
    int limit = 50,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('walletId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => WalletTransaction.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();
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

  /// Get user's coin purchase history with KES amounts
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

  /// Get wallet statistics for a user
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final wallet = await getUserWallet(userId);
      final totalSpent = await getTotalCoinsSpent(userId);
      final totalPurchased = await getTotalCoinsPurchased(userId);
      final purchaseHistory = await getCoinPurchaseHistory(userId);
      final unlockHistory = await getEpisodeUnlockHistory(userId);
      
      // Calculate total KES spent
      double totalKESSpent = 0;
      for (var transaction in purchaseHistory) {
        totalKESSpent += transaction.paidAmount ?? 0;
      }

      return {
        'currentBalance': wallet?.coinsBalance ?? 0,
        'totalCoinsSpent': totalSpent,
        'totalCoinsPurchased': totalPurchased,
        'totalKESSpent': totalKESSpent,
        'totalPurchases': purchaseHistory.length,
        'totalUnlocks': unlockHistory.length,
        'equivalentKESValue': wallet?.equivalentKESValue ?? 0,
      };
    } catch (e) {
      throw WalletRepositoryException('Failed to get wallet stats: $e');
    }
  }

  /// Admin method: Get all pending coin purchases (for manual processing)
  Future<List<Map<String, dynamic>>> getPendingCoinPurchases() async {
    try {
      // This would be used if we track payment requests separately
      // For now, admin manually adds coins after M-Pesa verification
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('type', isEqualTo: 'coin_purchase')
          .where('paymentMethod', isEqualTo: 'mpesa')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw WalletRepositoryException('Failed to get pending purchases: $e');
    }
  }

  /// Batch update wallet balances (admin utility)
  Future<void> batchUpdateWallets(List<Map<String, dynamic>> updates) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var update in updates) {
        final userId = update['userId'] as String;
        final coinAmount = update['coinAmount'] as int;
        final description = update['description'] as String;
        
        DocumentReference walletRef = _firestore
            .collection(_walletsCollection)
            .doc(userId);
        
        // Note: This is a simplified batch update
        // In production, you'd want to read current balances first
        batch.update(walletRef, {
          'coinsBalance': FieldValue.increment(coinAmount),
          'lastUpdated': DateTime.now().microsecondsSinceEpoch.toString(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw WalletRepositoryException('Failed to batch update wallets: $e');
    }
  }
}

// Exception class for wallet repository errors
class WalletRepositoryException implements Exception {
  final String message;
  const WalletRepositoryException(this.message);
  
  @override
  String toString() => 'WalletRepositoryException: $message';
}