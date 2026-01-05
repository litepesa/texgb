import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/payment/models/mpesa_transaction.dart';
import 'package:textgb/features/payment/services/payment_service.dart';

part 'payment_providers.g.dart';

/// Provider for PaymentService instance
@riverpod
PaymentService paymentService(PaymentServiceRef ref) {
  return PaymentService();
}

/// Payment state class
class PaymentState {
  final List<MpesaTransaction> transactions;
  final MpesaTransaction? currentTransaction;
  final bool isLoading;
  final String? error;

  PaymentState({
    this.transactions = const [],
    this.currentTransaction,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<MpesaTransaction>? transactions,
    MpesaTransaction? currentTransaction,
    bool? isLoading,
    String? error,
    bool clearCurrentTransaction = false,
    bool clearError = false,
  }) {
    return PaymentState(
      transactions: transactions ?? this.transactions,
      currentTransaction: clearCurrentTransaction
          ? null
          : (currentTransaction ?? this.currentTransaction),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Payment provider for managing M-Pesa payment operations
@riverpod
class Payment extends _$Payment {
  @override
  PaymentState build() {
    return PaymentState();
  }

  PaymentService get _service => ref.read(paymentServiceProvider);

  /// Initiate activation payment (KES 99) with M-Pesa STK Push
  /// Returns the checkout request ID for polling, or null if failed
  Future<String?> initiateActivation({
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.initiateActivationPayment(
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        currentTransaction: response.transaction,
        isLoading: false,
      );

      return response.transaction.checkoutRequestId;
    } on PaymentException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initiate activation payment: $e',
      );
      return null;
    }
  }

  /// Initiate wallet top-up with M-Pesa STK Push
  /// Returns the checkout request ID for polling, or null if failed
  Future<String?> initiateTopUp({
    required double amount,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.initiateWalletTopUp(
        amount: amount,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        currentTransaction: response.transaction,
        isLoading: false,
      );

      return response.transaction.checkoutRequestId;
    } on PaymentException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initiate payment: $e',
      );
      return null;
    }
  }

  /// Poll payment status for a checkout request ID
  /// Returns the updated transaction
  Future<MpesaTransaction?> pollPaymentStatus(String checkoutRequestId) async {
    try {
      final transaction = await _service.queryPaymentStatus(checkoutRequestId);

      // Update current transaction if it matches
      if (state.currentTransaction?.checkoutRequestId == checkoutRequestId) {
        state = state.copyWith(currentTransaction: transaction);
      }

      // Update transaction in list if present
      final updatedTransactions = state.transactions.map((t) {
        if (t.checkoutRequestId == checkoutRequestId) {
          return transaction;
        }
        return t;
      }).toList();

      state = state.copyWith(transactions: updatedTransactions);

      return transaction;
    } on PaymentException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to query payment status: $e');
      return null;
    }
  }

  /// Load user's payment transaction history
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final transactions = await _service.getUserTransactions();

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
      );
    } on PaymentException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions: $e',
      );
    }
  }

  /// Clear current transaction
  void clearCurrentTransaction() {
    state = state.copyWith(clearCurrentTransaction: true);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
