// lib/features/wallet/repositories/wallet_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';


// Abstract wallet repository interface
abstract class WalletRepository {
  // Wallet operations
  Future<WalletModel?> getUserWallet(String userId);
  Future<void> createWallet(String userId, String userPhoneNumber, String userName);
  Future<bool> deductFromWallet(String userId, double amount, {
    required String description,
    String? referenceId,
  });
  
  // Transaction operations
  Future<List<WalletTransaction>> getWalletTransactions(String userId, {
    int limit = 50,
    String? lastTransactionId,
  });
  
  // Streams
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
    String transactionsCollection = 'transactions',
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
        balance: 0.0,
        currency: 'KES',
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

  @override
  Future<bool> deductFromWallet(String userId, double amount, {
    required String description,
    String? referenceId,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // Get wallet document
        DocumentReference walletRef = _firestore
            .collection(_walletsCollection)
            .doc(userId);
        
        DocumentSnapshot walletSnapshot = await transaction.get(walletRef);
        
        if (!walletSnapshot.exists) {
          throw WalletRepositoryException('Wallet not found');
        }

        final wallet = WalletModel.fromMap(
          walletSnapshot.data() as Map<String, dynamic>
        );

        // Check if user has sufficient balance
        if (wallet.balance < amount) {
          return false; // Insufficient funds
        }

        final newBalance = wallet.balance - amount;
        final now = DateTime.now().microsecondsSinceEpoch.toString();

        // Update wallet balance
        transaction.update(walletRef, {
          'balance': newBalance,
          'lastUpdated': now,
        });

        // Create transaction record
        final transactionDoc = _firestore
            .collection(_transactionsCollection)
            .doc();

        final walletTransaction = WalletTransaction(
          transactionId: transactionDoc.id,
          walletId: wallet.walletId,
          userId: wallet.userId,
          userPhoneNumber: wallet.userPhoneNumber,
          userName: wallet.userName,
          type: 'debit',
          amount: amount,
          balanceBefore: wallet.balance,
          balanceAfter: newBalance,
          description: description,
          referenceId: referenceId,
          createdAt: now,
        );

        transaction.set(transactionDoc, walletTransaction.toMap());

        return true; // Success
      });
    } catch (e) {
      throw WalletRepositoryException('Failed to deduct from wallet: $e');
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
                doc.data() as Map<String, dynamic>))
            .toList());
  }
}

// Exception class for wallet repository errors
class WalletRepositoryException implements Exception {
  final String message;
  const WalletRepositoryException(this.message);
  
  @override
  String toString() => 'WalletRepositoryException: $message';
}