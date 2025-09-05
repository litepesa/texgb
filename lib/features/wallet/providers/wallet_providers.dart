// lib/features/wallet/providers/wallet_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
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

// Main wallet provider (simplified - no episode unlock method)
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
      final wallet = await _repository.getUserWallet(currentUser.id);
      final transactions = await _repository.getWalletTransactions(
        currentUser.id,
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
        currentUser.id,
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

      final wallet = await _repository.getUserWallet(currentUser.id);
      final transactions = await _repository.getWalletTransactions(
        currentUser.id,
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

  // REMOVED: requestEpisodeUnlock method (drama unlocking is handled in drama repository now)
}

// Stream providers for real-time updates
@riverpod
Stream<WalletModel?> walletStream(WalletStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.walletStream(currentUser.id);
}

@riverpod
Stream<List<WalletTransaction>> transactionsStream(TransactionsStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(walletRepositoryProvider);
  return repository.transactionsStream(currentUser.id);
}

// Convenience providers
@riverpod
int? coinsBalance(CoinsBalanceRef ref) {
  final walletState = ref.watch(walletProvider);
  return walletState.value?.wallet?.coinsBalance;
}

@riverpod
bool hasCoins(HasCoinsRef ref) {
  final balance = ref.watch(coinsBalanceProvider);
  return balance != null && balance > 0;
}

@riverpod
bool canAffordCoins(CanAffordCoinsRef ref, int coinAmount) {
  final balance = ref.watch(coinsBalanceProvider);
  return balance != null && balance >= coinAmount;
}

// Coin packages provider
@riverpod
List<CoinPackage> availableCoinPackages(AvailableCoinPackagesRef ref) {
  return CoinPackages.available;
}