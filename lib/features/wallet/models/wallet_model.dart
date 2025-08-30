// lib/features/wallet/models/wallet_model.dart
import 'package:textgb/constants.dart';

// Predefined coin packages
class CoinPackage {
  final int coins;
  final double priceKES;
  final String packageId;
  final String displayName;
  final bool isPopular;

  const CoinPackage({
    required this.coins,
    required this.priceKES,
    required this.packageId,
    required this.displayName,
    this.isPopular = false,
  });

  String get formattedPrice => 'KES ${priceKES.toStringAsFixed(0)}';
  
  // Get value per coin
  double get valuePerCoin => priceKES / coins;
  
  // Check if this is a better deal than another package
  bool isBetterDealThan(CoinPackage other) {
    return valuePerCoin < other.valuePerCoin;
  }
}

class CoinPackages {
  static const List<CoinPackage> available = [
    CoinPackage(
      coins: 99,
      priceKES: 100,
      packageId: 'coins_99',
      displayName: 'Starter Pack',
    ),
    CoinPackage(
      coins: 495,
      priceKES: 500,
      packageId: 'coins_495',
      displayName: 'Popular Pack',
      isPopular: true,
    ),
    CoinPackage(
      coins: 990,
      priceKES: 1000,
      packageId: 'coins_990',
      displayName: 'Value Pack',
    ),
  ];
  
  static CoinPackage? getByPackageId(String packageId) {
    try {
      return available.firstWhere((package) => package.packageId == packageId);
    } catch (e) {
      return null;
    }
  }
  
  static CoinPackage get starter => available[0];
  static CoinPackage get popular => available[1];
  static CoinPackage get value => available[2];
}

class WalletModel {
  final String walletId;
  final String userId;
  final String userPhoneNumber;
  final String userName;
  final int coinsBalance; // Changed from double balance to int coinsBalance
  final String lastUpdated;
  final String createdAt;
  final List<WalletTransaction> transactions;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.userPhoneNumber,
    required this.userName,
    required this.coinsBalance,
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
      coinsBalance: (map['coinsBalance'] ?? 0).toInt(), // Changed from balance to coinsBalance
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
      'coinsBalance': coinsBalance, // Changed from balance to coinsBalance
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
    int? coinsBalance, // Changed from double? balance
    String? lastUpdated,
    String? createdAt,
    List<WalletTransaction>? transactions,
  }) {
    return WalletModel(
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userName: userName ?? this.userName,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      transactions: transactions ?? this.transactions,
    );
  }

  // Helper methods
  String get formattedBalance => '$coinsBalance Coins'; // Updated formatting
  
  bool get hasBalance => coinsBalance > 0;
  
  bool canAfford(int coinAmount) => coinsBalance >= coinAmount; // Changed from double to int

  // Get equivalent KES value (approximate, based on starter pack rate)
  double get equivalentKESValue => coinsBalance * (100.0 / 99.0);
  String get formattedKESEquivalent => 'KES ${equivalentKESValue.toStringAsFixed(0)}';

  @override
  String toString() {
    return 'WalletModel(walletId: $walletId, userId: $userId, phoneNumber: $userPhoneNumber, coinsBalance: $coinsBalance)';
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
  final String type; // 'coin_purchase', 'episode_unlock', 'admin_credit'
  final int coinAmount; // Changed from double amount to int coinAmount
  final int balanceBefore; // Changed to int
  final int balanceAfter; // Changed to int
  final String description;
  final String? referenceId; // For episode unlocks, coin package purchases, etc.
  final String? adminNote; // For admin-added coins
  final String? paymentMethod; // 'mpesa', 'admin_credit'
  final String? paymentReference; // M-Pesa confirmation code, etc.
  final String? packageId; // For coin purchases (links to CoinPackage)
  final double? paidAmount; // KES amount paid (for purchases)
  final String createdAt;
  final Map<String, dynamic> metadata;

  const WalletTransaction({
    required this.transactionId,
    required this.walletId,
    required this.userId,
    required this.userPhoneNumber,
    required this.userName,
    required this.type,
    required this.coinAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceId,
    this.adminNote,
    this.paymentMethod,
    this.paymentReference,
    this.packageId,
    this.paidAmount,
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
      coinAmount: (map['coinAmount'] ?? 0).toInt(), // Changed from amount
      balanceBefore: (map['balanceBefore'] ?? 0).toInt(),
      balanceAfter: (map['balanceAfter'] ?? 0).toInt(),
      description: map['description']?.toString() ?? '',
      referenceId: map['referenceId']?.toString(),
      adminNote: map['adminNote']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      paymentReference: map['paymentReference']?.toString(),
      packageId: map['packageId']?.toString(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
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
      'coinAmount': coinAmount, // Changed from amount
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'description': description,
      'referenceId': referenceId,
      'adminNote': adminNote,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'packageId': packageId,
      'paidAmount': paidAmount,
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
    int? coinAmount, // Changed from double? amount
    int? balanceBefore,
    int? balanceAfter,
    String? description,
    String? referenceId,
    String? adminNote,
    String? paymentMethod,
    String? paymentReference,
    String? packageId,
    double? paidAmount,
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
      coinAmount: coinAmount ?? this.coinAmount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      adminNote: adminNote ?? this.adminNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      packageId: packageId ?? this.packageId,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isCoinPurchase => type == 'coin_purchase';
  bool get isEpisodeUnlock => type == 'episode_unlock';
  bool get isAdminCredit => type == 'admin_credit';
  bool get isCredit => isCoinPurchase || isAdminCredit;
  bool get isDebit => isEpisodeUnlock;
  
  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign$coinAmount Coins';
  }

  // Get the coin package if this is a purchase
  CoinPackage? get coinPackage {
    if (packageId != null) {
      return CoinPackages.getByPackageId(packageId!);
    }
    return null;
  }

  // Get display title for transaction
  String get displayTitle {
    switch (type) {
      case 'coin_purchase':
        final package = coinPackage;
        return package != null ? '${package.displayName} Purchase' : 'Coin Purchase';
      case 'episode_unlock':
        return 'Episode Unlock';
      case 'admin_credit':
        return 'Admin Credit';
      default:
        return 'Transaction';
    }
  }

  // Get transaction icon
  String get iconName {
    switch (type) {
      case 'coin_purchase':
        return 'add_circle_outline';
      case 'episode_unlock':
        return 'play_circle_outline';
      case 'admin_credit':
        return 'admin_panel_settings';
      default:
        return 'account_balance_wallet';
    }
  }

  @override
  String toString() {
    return 'WalletTransaction(transactionId: $transactionId, type: $type, coinAmount: $coinAmount, user: $userPhoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletTransaction && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}