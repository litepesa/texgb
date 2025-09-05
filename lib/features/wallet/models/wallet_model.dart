// lib/features/wallet/models/wallet_model.dart

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
  final int coinsBalance; // Coins for sending gifts
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
      coinsBalance: (map['coinsBalance'] ?? 0).toInt(),
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
      'coinsBalance': coinsBalance,
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
    int? coinsBalance,
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
  String get formattedBalance => '$coinsBalance Coins';
  
  bool get hasBalance => coinsBalance > 0;
  
  bool canAfford(int coinAmount) => coinsBalance >= coinAmount;

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
  final String type; // 'coin_purchase', 'gift_sent', 'gift_received', 'admin_credit'
  final int coinAmount;
  final int balanceBefore;
  final int balanceAfter;
  final String description;
  final String? referenceId; // For gifts, coin package purchases, etc.
  final String? adminNote; // For admin-added coins
  final String? paymentMethod; // 'mpesa', 'admin_credit'
  final String? paymentReference; // M-Pesa confirmation code, etc.
  final String? packageId; // For coin purchases (links to CoinPackage)
  final double? paidAmount; // KES amount paid (for purchases)
  final String? giftId; // For gift transactions
  final String? recipientId; // For sent gifts
  final String? senderId; // For received gifts
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
    this.giftId,
    this.recipientId,
    this.senderId,
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
      coinAmount: (map['coinAmount'] ?? 0).toInt(),
      balanceBefore: (map['balanceBefore'] ?? 0).toInt(),
      balanceAfter: (map['balanceAfter'] ?? 0).toInt(),
      description: map['description']?.toString() ?? '',
      referenceId: map['referenceId']?.toString(),
      adminNote: map['adminNote']?.toString(),
      paymentMethod: map['paymentMethod']?.toString(),
      paymentReference: map['paymentReference']?.toString(),
      packageId: map['packageId']?.toString(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      giftId: map['giftId']?.toString(),
      recipientId: map['recipientId']?.toString(),
      senderId: map['senderId']?.toString(),
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
      'coinAmount': coinAmount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'description': description,
      'referenceId': referenceId,
      'adminNote': adminNote,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'packageId': packageId,
      'paidAmount': paidAmount,
      'giftId': giftId,
      'recipientId': recipientId,
      'senderId': senderId,
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
    int? coinAmount,
    int? balanceBefore,
    int? balanceAfter,
    String? description,
    String? referenceId,
    String? adminNote,
    String? paymentMethod,
    String? paymentReference,
    String? packageId,
    double? paidAmount,
    String? giftId,
    String? recipientId,
    String? senderId,
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
      giftId: giftId ?? this.giftId,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isCoinPurchase => type == 'coin_purchase';
  bool get isGiftSent => type == 'gift_sent';
  bool get isGiftReceived => type == 'gift_received';
  bool get isAdminCredit => type == 'admin_credit';
  bool get isCredit => isCoinPurchase || isAdminCredit || isGiftReceived;
  bool get isDebit => isGiftSent;
  
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
      case 'gift_sent':
        return 'Gift Sent';
      case 'gift_received':
        return 'Gift Received';
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
      case 'gift_sent':
        return 'card_giftcard';
      case 'gift_received':
        return 'redeem';
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