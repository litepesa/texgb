class PaymentModel {
  final String paymentId;
  final String userId;
  final String phoneNumber;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed
  final String? transactionId;
  final String? checkoutRequestId;
  final String createdAt;
  final String? completedAt;
  final String? failureReason;

  PaymentModel({
    required this.paymentId,
    required this.userId,
    required this.phoneNumber,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    this.checkoutRequestId,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] ?? '',
      userId: map['userId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'KES',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      checkoutRequestId: map['checkoutRequestId'],
      createdAt: map['createdAt'] ?? '',
      completedAt: map['completedAt'],
      failureReason: map['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'userId': userId,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transactionId': transactionId,
      'checkoutRequestId': checkoutRequestId,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'failureReason': failureReason,
    };
  }

  PaymentModel copyWith({
    String? paymentId,
    String? userId,
    String? phoneNumber,
    double? amount,
    String? currency,
    String? status,
    String? transactionId,
    String? checkoutRequestId,
    String? createdAt,
    String? completedAt,
    String? failureReason,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}