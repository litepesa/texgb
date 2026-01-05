import 'dart:convert';
import 'package:textgb/features/payment/models/mpesa_transaction.dart';
import 'package:textgb/shared/services/http_client.dart';

class PaymentService {
  final HttpClientService _httpClient;

  PaymentService({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  /// Initiate M-Pesa STK Push for activation payment (KES 99)
  /// [phoneNumber] - User's M-Pesa phone number (format: 254XXXXXXXXX)
  Future<PaymentInitiationResponse> initiateActivationPayment({
    required String phoneNumber,
  }) async {
    try {
      final response = await _httpClient.post(
        '/payment/initiate',
        body: {
          'amount': 99.0,
          'phone_number': phoneNumber,
          'transaction_type': 'activation',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return PaymentInitiationResponse.fromJson(
            responseData as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw PaymentException(
            error['error'] ?? 'Failed to initiate activation payment');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to initiate activation payment: $e');
    }
  }

  /// Initiate M-Pesa STK Push for wallet top-up
  /// [amount] - Amount in KES to top up (e.g., 100 = 100 coins)
  /// [phoneNumber] - User's M-Pesa phone number (format: 254XXXXXXXXX)
  Future<PaymentInitiationResponse> initiateWalletTopUp({
    required double amount,
    required String phoneNumber,
  }) async {
    try {
      final response = await _httpClient.post(
        '/payment/initiate',
        body: {
          'amount': amount,
          'phone_number': phoneNumber,
          'transaction_type': 'wallet_topup',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return PaymentInitiationResponse.fromJson(
            responseData as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw PaymentException(error['error'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to initiate payment: $e');
    }
  }

  /// Query payment status
  /// [checkoutRequestId] - The checkout request ID from STK push response
  Future<MpesaTransaction> queryPaymentStatus(String checkoutRequestId) async {
    try {
      final response =
          await _httpClient.get('/payment/status/$checkoutRequestId');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return MpesaTransaction.fromJson(responseData as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw PaymentException(
            error['error'] ?? 'Failed to query payment status');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to query payment status: $e');
    }
  }

  /// Get user's transaction history
  Future<List<MpesaTransaction>> getUserTransactions() async {
    try {
      final response = await _httpClient.get('/payment/transactions');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final transactionsList = responseData['transactions'] as List;
        return transactionsList
            .map((t) => MpesaTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
      } else {
        final error = jsonDecode(response.body);
        throw PaymentException(error['error'] ?? 'Failed to get transactions');
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to get transactions: $e');
    }
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}
