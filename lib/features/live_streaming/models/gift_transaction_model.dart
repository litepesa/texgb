// lib/features/live_streaming/models/gift_transaction_model.dart
// Gift transactions during live streams

/// Transaction record for a gift sent during live stream
class GiftTransactionModel {
  final String id;
  final String liveStreamId;
  final String streamHostId;

  // Gift details
  final String giftId;
  final String giftName;
  final String giftImage;
  final int giftValue;               // Value in coins
  final int quantity;                // Number of gifts sent
  final int totalValue;              // giftValue * quantity

  // Sender details
  final String senderId;
  final String senderName;
  final String senderImage;

  // Transaction details
  final String walletTransactionId;  // Link to wallet transaction
  final double amountInKES;          // Total amount in KES
  final String transactionStatus;    // completed, failed, pending

  // Metadata
  final bool isAnonymous;            // Send gift anonymously
  final String? message;             // Optional message with gift
  final Map<String, dynamic>? metadata;

  // Timestamps
  final String createdAt;

  const GiftTransactionModel({
    required this.id,
    required this.liveStreamId,
    required this.streamHostId,
    required this.giftId,
    required this.giftName,
    required this.giftImage,
    required this.giftValue,
    required this.quantity,
    required this.totalValue,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.walletTransactionId,
    required this.amountInKES,
    required this.transactionStatus,
    required this.isAnonymous,
    this.message,
    this.metadata,
    required this.createdAt,
  });

  factory GiftTransactionModel.fromJson(Map<String, dynamic> json) {
    return GiftTransactionModel(
      id: json['id'] ?? '',
      liveStreamId: json['liveStreamId'] ?? json['live_stream_id'] ?? '',
      streamHostId: json['streamHostId'] ?? json['stream_host_id'] ?? '',
      giftId: json['giftId'] ?? json['gift_id'] ?? '',
      giftName: json['giftName'] ?? json['gift_name'] ?? '',
      giftImage: json['giftImage'] ?? json['gift_image'] ?? '',
      giftValue: json['giftValue'] ?? json['gift_value'] ?? 0,
      quantity: json['quantity'] ?? 1,
      totalValue: json['totalValue'] ?? json['total_value'] ?? 0,
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      senderName: json['senderName'] ?? json['sender_name'] ?? '',
      senderImage: json['senderImage'] ?? json['sender_image'] ?? '',
      walletTransactionId: json['walletTransactionId'] ?? json['wallet_transaction_id'] ?? '',
      amountInKES: (json['amountInKES'] ?? json['amount_in_kes'] ?? 0).toDouble(),
      transactionStatus: json['transactionStatus'] ?? json['transaction_status'] ?? 'completed',
      isAnonymous: json['isAnonymous'] ?? json['is_anonymous'] ?? false,
      message: json['message'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'liveStreamId': liveStreamId,
      'streamHostId': streamHostId,
      'giftId': giftId,
      'giftName': giftName,
      'giftImage': giftImage,
      'giftValue': giftValue,
      'quantity': quantity,
      'totalValue': totalValue,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'walletTransactionId': walletTransactionId,
      'amountInKES': amountInKES,
      'transactionStatus': transactionStatus,
      'isAnonymous': isAnonymous,
      'message': message,
      'metadata': metadata,
      'createdAt': createdAt,
    };
  }

  GiftTransactionModel copyWith({
    String? id,
    String? transactionStatus,
    String? walletTransactionId,
    Map<String, dynamic>? metadata,
  }) {
    return GiftTransactionModel(
      id: id ?? this.id,
      liveStreamId: liveStreamId,
      streamHostId: streamHostId,
      giftId: giftId,
      giftName: giftName,
      giftImage: giftImage,
      giftValue: giftValue,
      quantity: quantity,
      totalValue: totalValue,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      walletTransactionId: walletTransactionId ?? this.walletTransactionId,
      amountInKES: amountInKES,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      isAnonymous: isAnonymous,
      message: message,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
    );
  }

  // Helper getters
  bool get isCompleted => transactionStatus == 'completed';
  bool get isFailed => transactionStatus == 'failed';
  bool get isPending => transactionStatus == 'pending';

  String get formattedAmount => 'KES ${amountInKES.toStringAsFixed(2)}';
  String get formattedCoins => '$totalValue coins';

  String get displaySenderName => isAnonymous ? 'Anonymous' : senderName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GiftTransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Gift leaderboard entry
class GiftLeaderboardEntry {
  final String userId;
  final String userName;
  final String userImage;
  final int totalGifts;              // Total coins gifted
  final double totalSpent;           // Total KES spent
  final int giftCount;               // Number of gifts sent
  final int rank;

  const GiftLeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.totalGifts,
    required this.totalSpent,
    required this.giftCount,
    required this.rank,
  });

  factory GiftLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GiftLeaderboardEntry(
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? '',
      userImage: json['userImage'] ?? json['user_image'] ?? '',
      totalGifts: json['totalGifts'] ?? json['total_gifts'] ?? 0,
      totalSpent: (json['totalSpent'] ?? json['total_spent'] ?? 0).toDouble(),
      giftCount: json['giftCount'] ?? json['gift_count'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'totalGifts': totalGifts,
      'totalSpent': totalSpent,
      'giftCount': giftCount,
      'rank': rank,
    };
  }

  String get formattedTotalSpent => 'KES ${totalSpent.toStringAsFixed(2)}';
  String get formattedTotalGifts => '$totalGifts coins';
  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
