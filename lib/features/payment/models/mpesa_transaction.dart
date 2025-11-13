class MpesaTransaction {
  final String id;
  final String userId;
  final String phoneNumber;
  final double amount;
  final String? merchantRequestId;
  final String? checkoutRequestId;
  final String? mpesaReceiptNumber;
  final DateTime? transactionDate;
  final int? resultCode;
  final String? resultDesc;
  final String status; // pending, completed, failed, cancelled, timeout
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  MpesaTransaction({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.amount,
    this.merchantRequestId,
    this.checkoutRequestId,
    this.mpesaReceiptNumber,
    this.transactionDate,
    this.resultCode,
    this.resultDesc,
    required this.status,
    required this.initiatedAt,
    this.completedAt,
    this.metadata,
  });

  factory MpesaTransaction.fromJson(Map<String, dynamic> json) {
    return MpesaTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      phoneNumber: json['phone_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      merchantRequestId: json['merchant_request_id'] as String?,
      checkoutRequestId: json['checkout_request_id'] as String?,
      mpesaReceiptNumber: json['mpesa_receipt_number'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : null,
      resultCode: json['result_code'] as int?,
      resultDesc: json['result_desc'] as String?,
      status: json['status'] as String,
      initiatedAt: DateTime.parse(json['initiated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'amount': amount,
      'merchant_request_id': merchantRequestId,
      'checkout_request_id': checkoutRequestId,
      'mpesa_receipt_number': mpesaReceiptNumber,
      'transaction_date': transactionDate?.toIso8601String(),
      'result_code': resultCode,
      'result_desc': resultDesc,
      'status': status,
      'initiated_at': initiatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PaymentInitiationResponse {
  final MpesaTransaction transaction;
  final StkPushResponse stkResponse;

  PaymentInitiationResponse({
    required this.transaction,
    required this.stkResponse,
  });

  factory PaymentInitiationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResponse(
      transaction: MpesaTransaction.fromJson(json['transaction'] as Map<String, dynamic>),
      stkResponse: StkPushResponse.fromJson(json['stk_response'] as Map<String, dynamic>),
    );
  }
}

class StkPushResponse {
  final String merchantRequestId;
  final String checkoutRequestId;
  final String responseCode;
  final String responseDescription;
  final String customerMessage;

  StkPushResponse({
    required this.merchantRequestId,
    required this.checkoutRequestId,
    required this.responseCode,
    required this.responseDescription,
    required this.customerMessage,
  });

  factory StkPushResponse.fromJson(Map<String, dynamic> json) {
    return StkPushResponse(
      merchantRequestId: json['merchant_request_id'] as String,
      checkoutRequestId: json['checkout_request_id'] as String,
      responseCode: json['response_code'] as String,
      responseDescription: json['response_description'] as String,
      customerMessage: json['customer_message'] as String,
    );
  }
}
