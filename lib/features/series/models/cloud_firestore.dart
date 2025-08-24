// lib/features/series/models/series_purchase_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SeriesPurchaseModel {
  final String id;
  final String userId;
  final String seriesId;
  final String seriesTitle;
  final double amountPaid;
  final Timestamp purchaseDate;
  final bool isActive;
  final String paymentMethod;
  final String transactionId;

  SeriesPurchaseModel({
    required this.id,
    required this.userId,
    required this.seriesId,
    required this.seriesTitle,
    required this.amountPaid,
    required this.purchaseDate,
    required this.isActive,
    required this.paymentMethod,
    required this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'seriesId': seriesId,
      'seriesTitle': seriesTitle,
      'amountPaid': amountPaid,
      'purchaseDate': purchaseDate,
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }

  factory SeriesPurchaseModel.fromMap(Map<String, dynamic> map, String id) {
    return SeriesPurchaseModel(
      id: id,
      userId: map['userId'] ?? '',
      seriesId: map['seriesId'] ?? '',
      seriesTitle: map['seriesTitle'] ?? '',
      amountPaid: (map['amountPaid'] ?? 0.0).toDouble(),
      purchaseDate: map['purchaseDate'] ?? Timestamp.now(),
      isActive: map['isActive'] ?? true,
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'] ?? '',
    );
  }

  @override
  String toString() {
    return 'SeriesPurchaseModel(id: $id, series: $seriesTitle, amount: KES $amountPaid)';
  }
}