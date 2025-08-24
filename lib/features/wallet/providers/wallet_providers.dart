// lib/features/wallet/providers/wallet_providers.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/wallet/models/wallet_model.dart';
import 'package:textgb/features/wallet/repositories/wallet_repository.dart';

part 'wallet_providers.g.dart';

// Repository provider
@riverpod
WalletRepository walletRepository(WalletRepositoryRef ref) {
  return FirebaseWalletRepository();
}

// Wallet state class
class WalletState {
  final WalletModel? wallet;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.wallet,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    WalletModel? wallet,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Main wallet provider
@riverpod
class Wallet extends _$Wallet {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  @override
  FutureOr<WalletState> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const WalletState();
    }

    try {
      // Get wallet and recent transactions
      final wallet = await _repository.getUserWallet(currentUser.uid);
      final transactions = await _repository.getWalletTransactions(
        currentUser.uid,
        limit: 10,
      );

      return WalletState(
        wallet: wallet,
        transactions: transactions,
      );
    } catch (e) {
      return WalletState(error: e.toString());
    }
  }

  // Load more transactions
  Future<void> loadMoreTransactions() async {
    final currentState = state.value;
    if (currentState == null || currentState.transactions.isEmpty) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final lastTransactionId = currentState.transactions.last.transactionId;
      final moreTransactions = await _repository.getWalletTransactions(
        currentUser.uid,
        limit: 20,
        lastTransactionId: lastTransactionId,
      );

      state = AsyncValue.data(currentState.copyWith(
        transactions: [...currentState.transactions, ...moreTransactions],
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Refresh wallet and transactions
  Future<void> refresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      state = AsyncValue.data(const WalletState(isLoading: true));

      final wallet = await _repository.getUserWallet(currentUser.uid);
      final transactions = await _repository.getWalletTransactions(
        currentUser.uid,
        limit: 10,
      );

      state = AsyncValue.data(WalletState(
        wallet: wallet,
        transactions: transactions,
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Make a purchase (deduct from wallet)
  Future<bool> makePurchase({
    required double amount,
    required String description,
    String? referenceId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    try {
      final success = await _repository.deductFromWallet(
        currentUser.uid,
        amount,
        description: description,
        referenceId: referenceId,
      );

      if (success) {
        // Refresh the wallet state
        await refresh();
      }

      return success;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

// Stream providers for real-time updates
@riverpod
Stream<WalletModel?> walletStream(WalletStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.walletStream(currentUser.uid);
}

@riverpod
Stream<List<WalletTransaction>> transactionsStream(TransactionsStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.transactionsStream(currentUser.uid);
}

// Convenience providers
@riverpod
double? walletBalance(WalletBalanceRef ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.value?.wallet?.balance;
}

@riverpod
bool hasWalletBalance(HasWalletBalanceRef ref) {
  final balance = ref.watch(walletBalanceProvider);
  return balance != null && balance > 0;
}

@riverpod
bool canAfford(CanAffordRef ref, double amount) {
  final balance = ref.watch(walletBalanceProvider);
  return balance != null && balance >= amount;
}