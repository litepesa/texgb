import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/payment_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/services/mpesa_service.dart';

part 'payment_provider.g.dart';

class PaymentState {
  final bool isLoading;
  final bool isPaymentSuccessful;
  final String? error;
  final PaymentModel? currentPayment;

  const PaymentState({
    this.isLoading = false,
    this.isPaymentSuccessful = false,
    this.error,
    this.currentPayment,
  });

  PaymentState copyWith({
    bool? isLoading,
    bool? isPaymentSuccessful,
    String? error,
    PaymentModel? currentPayment,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isPaymentSuccessful: isPaymentSuccessful ?? this.isPaymentSuccessful,
      error: error,
      currentPayment: currentPayment ?? this.currentPayment,
    );
  }
}

@riverpod
class Payment extends _$Payment {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MpesaService _mpesaService = MpesaService();

  @override
  FutureOr<PaymentState> build() async {
    return const PaymentState();
  }

  // Initiate payment process
  Future<void> initiatePayment({
    required UserModel user,
    required BuildContext context,
  }) async {
    state = AsyncValue.data(const PaymentState(isLoading: true));

    try {
      // Create payment record
      final paymentId = _firestore.collection(Constants.payments).doc().id;
      final payment = PaymentModel(
        paymentId: paymentId,
        userId: user.uid,
        phoneNumber: user.phoneNumber,
        amount: Constants.activationFee,
        currency: Constants.currency,
        status: 'pending',
        createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Save payment to Firestore
      await _firestore
          .collection(Constants.payments)
          .doc(paymentId)
          .set(payment.toMap());

      // Initiate M-Pesa STK Push
      final stkResponse = await _mpesaService.initiateSTKPush(
        phoneNumber: user.phoneNumber,
        amount: Constants.activationFee,
        accountReference: user.uid,
        transactionDesc: 'WeiBao App Activation Fee',
      );

      if (stkResponse != null && stkResponse['ResponseCode'] == '0') {
        // STK Push initiated successfully
        final updatedPayment = payment.copyWith(
          checkoutRequestId: stkResponse['CheckoutRequestID'],
        );

        // Update payment with checkout request ID
        await _firestore
            .collection(Constants.payments)
            .doc(paymentId)
            .update(updatedPayment.toMap());

        state = AsyncValue.data(PaymentState(
          isLoading: false,
          currentPayment: updatedPayment,
        ));

        // Start monitoring payment status
        _monitorPaymentStatus(updatedPayment);
      } else {
        throw Exception('Failed to initiate payment: ${stkResponse?['errorMessage'] ?? 'Unknown error'}');
      }
    } catch (e) {
      state = AsyncValue.data(PaymentState(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Monitor payment status
  void _monitorPaymentStatus(PaymentModel payment) async {
    if (payment.checkoutRequestId == null) return;

    // Poll for payment status every 5 seconds for up to 2 minutes
    for (int i = 0; i < 24; i++) {
      await Future.delayed(const Duration(seconds: 5));

      try {
        final statusResponse = await _mpesaService.querySTKPushStatus(
          checkoutRequestId: payment.checkoutRequestId!,
        );

        if (statusResponse != null) {
          if (statusResponse['ResultCode'] == '0') {
            // Payment successful
            await _handleSuccessfulPayment(payment, statusResponse);
            break;
          } else if (statusResponse['ResultCode'] != '1032') {
            // Payment failed (1032 means still pending)
            await _handleFailedPayment(payment, statusResponse['ResultDesc']);
            break;
          }
        }
      } catch (e) {
        print('Error monitoring payment: $e');
      }
    }
  }

  // Handle successful payment
  Future<void> _handleSuccessfulPayment(
    PaymentModel payment,
    Map<String, dynamic> statusResponse,
  ) async {
    try {
      final transactionId = statusResponse['MpesaReceiptNumber'];
      final completedAt = DateTime.now().millisecondsSinceEpoch.toString();

      // Update payment record
      final updatedPayment = payment.copyWith(
        status: 'completed',
        transactionId: transactionId,
        completedAt: completedAt,
      );

      await _firestore
          .collection(Constants.payments)
          .doc(payment.paymentId)
          .update(updatedPayment.toMap());

      // Activate user account
      await _firestore
          .collection(Constants.users)
          .doc(payment.userId)
          .update({
        Constants.isAccountActivated: true,
        Constants.paymentTransactionId: transactionId,
        Constants.paymentDate: completedAt,
        Constants.amountPaid: payment.amount,
      });

      state = AsyncValue.data(PaymentState(
        isLoading: false,
        isPaymentSuccessful: true,
        currentPayment: updatedPayment,
      ));
    } catch (e) {
      state = AsyncValue.data(PaymentState(
        isLoading: false,
        error: 'Failed to process successful payment: $e',
      ));
    }
  }

  // Handle failed payment
  Future<void> _handleFailedPayment(
    PaymentModel payment,
    String? failureReason,
  ) async {
    try {
      final updatedPayment = payment.copyWith(
        status: 'failed',
        failureReason: failureReason ?? 'Payment failed',
      );

      await _firestore
          .collection(Constants.payments)
          .doc(payment.paymentId)
          .update(updatedPayment.toMap());

      state = AsyncValue.data(PaymentState(
        isLoading: false,
        error: failureReason ?? 'Payment failed',
        currentPayment: updatedPayment,
      ));
    } catch (e) {
      state = AsyncValue.data(PaymentState(
        isLoading: false,
        error: 'Failed to process failed payment: $e',
      ));
    }
  }

  // Reset payment state
  void resetPaymentState() {
    state = const AsyncValue.data(PaymentState());
  }

  // Check if user has paid
  Future<bool> checkUserPaymentStatus(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData[Constants.isAccountActivated] ?? false;
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
    return false;
  }
}