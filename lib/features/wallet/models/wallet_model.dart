// lib/models/wallet_model.dart
import 'package:textgb/constants.dart';

class WalletModel {
  final String walletId;
  final String userId;
  final String userPhoneNumber;
  final String userName;
  final double balance;
  final String currency;
  final String lastUpdated;
  final String createdAt;
  final List<WalletTransaction> transactions;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.userPhoneNumber,
    required this.userName,
    required this.balance,
    this.currency = 'KES',
    required this.lastUpdated,
    required this.createdAt,
    this.transactions = const [],
  });

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      walletId: map['walletId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userPhoneNumber: map['userPhoneNumber']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency']?.toString() ?? 'KES',
      lastUpdated: map['lastUpdated']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      transactions: (map['transactions'] as List?)
          ?.map((t) => WalletTransaction.fromMap(t as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walletId': walletId,
      'userId': userId,
      'userPhoneNumber': userPhoneNumber,
      'userName': userName,
      'balance': balance,
      'currency': currency,
      'lastUpdated': lastUpdated,
      'createdAt': createdAt,
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }

  WalletModel copyWith({
    String? walletId,
    String? userId,
    String? userPhoneNumber,
    String? userName,
    double? balance,
    String? currency,
    String? lastUpdated,
    String? createdAt,
    List<WalletTransaction>? transactions,
  }) {
    return WalletModel(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userName: userName ?? this.userName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      transactions: transactions ?? this.transactions,
    );
  }

  // Helper methods
  String get formattedBalance => '$currency ${balance.toStringAsFixed(2)}';
  
  bool get hasBalance => balance > 0;
  
  bool canAfford(double amount) => balance >= amount;

  @override
  String toString() {
    return 'WalletModel(walletId: $walletId, userId: $userId, phoneNumber: $userPhoneNumber, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletModel && other.walletId == walletId;
  }

  @override
  int get hashCode => walletId.hashCode;
}

class WalletTransaction {
  final String transactionId;
  final String walletId;
  final String userId;
  final String userPhoneNumber;
  final String userName;
  final String type; // 'credit', 'debit', 'purchase', 'refund'
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String? referenceId; // For purchases, subscriptions, etc.
  final String? adminNote; // For admin-added funds
  final String? paymentMethod; // 'mpesa', 'bank_transfer', 'card', etc.
  final String? paymentReference; // M-Pesa confirmation code, bank reference, etc.
  final String createdAt;
  final Map<String, dynamic> metadata;

  const WalletTransaction({
    required this.transactionId,
    required this.walletId,
    required this.userId,
    required this.userPhoneNumber,
    required this.userName,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    this.adminNote,
    this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
    this.metadata = const {},
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      transactionId: map['transactionId']?.toString() ?? '',
      walletId: map['walletId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userPhoneNumber: map['userPhoneNumber']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      balanceBefore: (map['balanceBefore'] ?? 0.0).toDouble(),
      balanceAfter: (map['balanceAfter'] ?? 0.0).toDouble(),
      description: map['description']?.toString() ?? '',
      referenceId: map['referenceId']?.toString(),
      adminNote: map['adminNote']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      paymentReference: map['paymentReference']?.toString(),
      createdAt: map['createdAt']?.toString() ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'walletId': walletId,
      'userId': userId,
      'userPhoneNumber': userPhoneNumber,
      'userName': userName,
      'type': type,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'description': description,
      'referenceId': referenceId,
      'adminNote': adminNote,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }

  WalletTransaction copyWith({
    String? transactionId,
    String? walletId,
    String? userId,
    String? userPhoneNumber,
    String? userName,
    String? type,
    double? amount,
    double? balanceBefore,
    double? balanceAfter,
    String? description,
    String? referenceId,
    String? adminNote,
    String? paymentMethod,
    String? paymentReference,
    String? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return WalletTransaction(
      transactionId: transactionId ?? this.transactionId,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      adminNote: adminNote ?? this.adminNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
  bool get isPurchase => type == 'purchase';
  bool get isRefund => type == 'refund';
  
  String get formattedAmount {
    final sign = isCredit || isRefund ? '+' : '-';
    return '$sign KES ${amount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'WalletTransaction(transactionId: $transactionId, type: $type, amount: $amount, user: $userPhoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}