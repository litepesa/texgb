// lib/features/wallet/repositories/wallet_repository.dart
// FIXED FOR ELIXIR BACKEND

import 'dart:convert';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/shared/services/http_client.dart';

// Abstract wallet repository interface
abstract class WalletRepository {
  // Wallet operations
  Future<WalletModel?> getUserWallet(String userId);
  Future<void> createWallet(
      String userId, String userPhoneNumber, String userName);

  // Transaction operations
  Future<List<WalletTransaction>> getWalletTransactions(
    String userId, {
    int limit = 50,
    String? lastTransactionId,
  });

  // Streams (deprecated for HTTP backend)
  Stream<WalletModel?> walletStream(String userId);
  Stream<List<WalletTransaction>> transactionsStream(String userId);

  // Coin operations
  Future<bool> transferCoins(
      String fromUserId, String toUserId, int amount, String description);
  Future<bool> earnCoins(String userId, int amount, String description);
  Future<bool> spendCoins(String userId, int amount, String description);
}

// HTTP Backend implementation for Elixir
class HttpWalletRepository implements WalletRepository {
  final HttpClientService _httpClient;

  HttpWalletRepository({
    HttpClientService? httpClient,
  }) : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // WALLET OPERATIONS (ELIXIR BACKEND)
  // ===============================

  @override
  Future<WalletModel?> getUserWallet(String userId) async {
    try {
      // Elixir backend uses auth token to get current user's wallet
      // Endpoint: GET /api/v1/wallet (no user ID in path)
      final response = await _httpClient.get('/wallet');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        if (responseBody.isEmpty || responseBody == 'null') {
          return null;
        }

        final walletData = jsonDecode(responseBody);
        if (walletData == null) {
          return null;
        }

        // Convert Elixir backend format to Flutter model format
        return _convertElixirWalletToModel(walletData as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw WalletRepositoryException(
            'Failed to get user wallet: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw WalletRepositoryException('Failed to get user wallet: $e');
    }
  }

  @override
  Future<void> createWallet(
      String userId, String userPhoneNumber, String userName) async {
    // Elixir backend automatically creates wallet on first access via get_or_create_wallet
    // No manual creation needed
    return;
  }

  // ===============================
  // TRANSACTION OPERATIONS (ELIXIR BACKEND)
  // ===============================

  @override
  Future<List<WalletTransaction>> getWalletTransactions(
    String userId, {
    int limit = 50,
    String? lastTransactionId,
  }) async {
    try {
      // Elixir backend uses pagination: GET /api/v1/wallet/transactions?page=1&per_page=20
      final page = 1; // For now, always get first page
      final perPage = limit;

      final response = await _httpClient
          .get('/wallet/transactions?page=$page&per_page=$perPage');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();

        if (responseBody.isEmpty || responseBody == 'null') {
          return <WalletTransaction>[];
        }

        final decodedData = jsonDecode(responseBody);

        if (decodedData == null) {
          return <WalletTransaction>[];
        }

        // Elixir backend returns: {transactions: [...], page: 1, per_page: 20}
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('transactions')) {
          final transactionsData = decodedData['transactions'];
          if (transactionsData == null || transactionsData is! List) {
            return <WalletTransaction>[];
          }

          return (transactionsData)
              .where((item) => item != null)
              .map((data) => _convertElixirTransactionToModel(
                  data as Map<String, dynamic>))
              .toList();
        }

        return <WalletTransaction>[];
      } else if (response.statusCode == 404) {
        return <WalletTransaction>[];
      } else {
        throw WalletRepositoryException(
            'Failed to get wallet transactions: ${response.body}');
      }
    } catch (e) {
      if (e is FormatException || e.toString().contains('subtype')) {
        print('Warning: Failed to parse transactions data: $e');
        return <WalletTransaction>[];
      }
      throw WalletRepositoryException('Failed to get wallet transactions: $e');
    }
  }

  // ===============================
  // COIN OPERATIONS (ELIXIR BACKEND)
  // ===============================

  @override
  Future<bool> transferCoins(String fromUserId, String toUserId, int amount,
      String description) async {
    try {
      // POST /api/v1/wallet/transfer
      final response = await _httpClient.post('/wallet/transfer', body: {
        'to_user_id': toUserId,
        'amount': amount,
        'description': description,
      });

      return response.statusCode == 200;
    } catch (e) {
      print('Transfer coins error: $e');
      return false;
    }
  }

  @override
  Future<bool> earnCoins(String userId, int amount, String description) async {
    try {
      // POST /api/v1/wallet/earn
      final response = await _httpClient.post('/wallet/earn', body: {
        'amount': amount,
        'description': description,
      });

      return response.statusCode == 200;
    } catch (e) {
      print('Earn coins error: $e');
      return false;
    }
  }

  @override
  Future<bool> spendCoins(String userId, int amount, String description) async {
    try {
      // POST /api/v1/wallet/spend
      final response = await _httpClient.post('/wallet/spend', body: {
        'amount': amount,
        'description': description,
      });

      return response.statusCode == 200;
    } catch (e) {
      print('Spend coins error: $e');
      return false;
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  /// Convert Elixir backend wallet format to Flutter model format
  WalletModel _convertElixirWalletToModel(Map<String, dynamic> data) {
    return WalletModel(
      walletId: data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? data['user_id']?.toString() ?? '',
      userPhoneNumber: '', // Not provided by Elixir backend
      userName: '', // Not provided by Elixir backend
      coinsBalance: (data['balance'] ?? 0) as int,
      lastUpdated:
          data['updatedAt']?.toString() ?? data['updated_at']?.toString() ?? '',
      createdAt:
          data['createdAt']?.toString() ?? data['created_at']?.toString() ?? '',
      transactions: const [],
    );
  }

  /// Convert Elixir backend transaction format to Flutter model format
  WalletTransaction _convertElixirTransactionToModel(
      Map<String, dynamic> data) {
    // Determine transaction type based on backend transaction_type
    String flutterType = data['transactionType']?.toString() ??
        data['transaction_type']?.toString() ??
        'unknown';

    // Map Elixir types to Flutter types
    switch (flutterType) {
      case 'earn':
        flutterType = 'coin_purchase'; // or 'admin_credit' depending on context
        break;
      case 'spend':
        flutterType = 'gift_sent'; // or other spend type
        break;
      case 'transfer_out':
        flutterType = 'gift_sent';
        break;
      case 'transfer_in':
        flutterType = 'gift_received';
        break;
    }

    final amount = (data['amount'] ?? 0) as int;

    return WalletTransaction(
      transactionId: data['id']?.toString() ?? '',
      walletId:
          data['walletId']?.toString() ?? data['wallet_id']?.toString() ?? '',
      userId: '', // Not directly provided
      userPhoneNumber: '', // Not provided by Elixir backend
      userName: '', // Not provided by Elixir backend
      type: flutterType,
      coinAmount: amount.abs(),
      balanceBefore:
          (data['balanceBefore'] ?? data['balance_before'] ?? 0) as int,
      balanceAfter: (data['balanceAfter'] ?? data['balance_after'] ?? 0) as int,
      description: data['description']?.toString() ?? '',
      referenceId:
          data['relatedId']?.toString() ?? data['related_id']?.toString(),
      createdAt:
          data['createdAt']?.toString() ?? data['created_at']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // ===============================
  // DEPRECATED STREAM METHODS
  // ===============================

  @override
  Stream<WalletModel?> walletStream(String userId) {
    throw UnsupportedError(
        'Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }

  @override
  Stream<List<WalletTransaction>> transactionsStream(String userId) {
    throw UnsupportedError(
        'Streams are deprecated with HTTP backend. Use provider refresh methods instead.');
  }
}

// Exception class for wallet repository errors
class WalletRepositoryException implements Exception {
  final String message;
  const WalletRepositoryException(this.message);

  @override
  String toString() => 'WalletRepositoryException: $message';
}
