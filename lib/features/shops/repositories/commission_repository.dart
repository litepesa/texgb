// lib/features/shops/repositories/commission_repository.dart

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/shops/models/commission_model.dart';

class CommissionRepository {
  final HttpClientService _httpClient;

  CommissionRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== COMMISSION RECORDS ====================

  /// Get commission record by ID
  Future<CommissionModel> getCommission(String commissionId) async {
    final response = await _httpClient.get('/commissions/$commissionId');
    final data = jsonDecode(response.body);
    return CommissionModel.fromJson(data['commission'] ?? data);
  }

  /// Get commission record for specific order
  Future<CommissionModel> getOrderCommission(String orderId) async {
    final response = await _httpClient.get('/orders/$orderId/commission');
    final data = jsonDecode(response.body);
    return CommissionModel.fromJson(data['commission'] ?? data);
  }

  /// Get all commissions for seller
  Future<List<CommissionModel>> getSellerCommissions({
    required String sellerId,
    int limit = 20,
    int offset = 0,
    CommissionType? type,
    PayoutStatus? payoutStatus,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (type != null) queryParams['type'] = type.name;
    if (payoutStatus != null) queryParams['payoutStatus'] = payoutStatus.name;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/users/$sellerId/commissions?$queryString');

    final data = jsonDecode(response.body);
    final commissions = data['commissions'] as List;
    return commissions.map((c) => CommissionModel.fromJson(c)).toList();
  }

  /// Get commissions for specific shop
  Future<List<CommissionModel>> getShopCommissions({
    required String shopId,
    int limit = 20,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/shops/$shopId/commissions?$queryString');

    final data = jsonDecode(response.body);
    final commissions = data['commissions'] as List;
    return commissions.map((c) => CommissionModel.fromJson(c)).toList();
  }

  /// Get commissions from specific live stream
  Future<List<CommissionModel>> getLiveStreamCommissions(String liveStreamId) async {
    final response = await _httpClient.get('/live-streams/$liveStreamId/commissions');
    final data = jsonDecode(response.body);
    final commissions = data['commissions'] as List;
    return commissions.map((c) => CommissionModel.fromJson(c)).toList();
  }

  // ==================== EARNINGS SUMMARY ====================

  /// Get seller's total earnings summary
  Future<SellerEarningsSummary> getSellerEarnings({
    required String sellerId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _httpClient.get('/users/$sellerId/earnings$queryString');
    final data = jsonDecode(response.body);
    return SellerEarningsSummary.fromJson(data['earnings'] ?? data);
  }

  /// Get shop's total earnings summary
  Future<SellerEarningsSummary> getShopEarnings({
    required String shopId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _httpClient.get('/shops/$shopId/earnings$queryString');
    final data = jsonDecode(response.body);
    return SellerEarningsSummary.fromJson(data['earnings'] ?? data);
  }

  /// Get earnings breakdown by commission type
  Future<Map<CommissionType, double>> getEarningsBreakdown({
    required String sellerId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _httpClient.get('/users/$sellerId/earnings/breakdown$queryString');
    final data = jsonDecode(response.body);

    final breakdown = <CommissionType, double>{};
    final breakdownData = data['breakdown'] as Map<String, dynamic>;

    for (var entry in breakdownData.entries) {
      final type = CommissionType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => CommissionType.shopSale,
      );
      breakdown[type] = (entry.value as num).toDouble();
    }

    return breakdown;
  }

  // ==================== PAYOUT MANAGEMENT ====================

  /// Request payout for pending commissions
  Future<PayoutRequest> requestPayout({
    required String sellerId,
    required double amount,
    required String payoutMethod,
    String? payoutDetails,
  }) async {
    final response = await _httpClient.post('/users/$sellerId/payouts/request', body: {
      'amount': amount,
      'payoutMethod': payoutMethod,
      'payoutDetails': payoutDetails,
    });

    final data = jsonDecode(response.body);
    return PayoutRequest.fromJson(data['payout'] ?? data);
  }

  /// Get payout request history
  Future<List<PayoutRequest>> getPayoutHistory({
    required String sellerId,
    int limit = 20,
    int offset = 0,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/users/$sellerId/payouts?$queryString');

    final data = jsonDecode(response.body);
    final payouts = data['payouts'] as List;
    return payouts.map((p) => PayoutRequest.fromJson(p)).toList();
  }

  /// Get specific payout request
  Future<PayoutRequest> getPayoutRequest(String payoutId) async {
    final response = await _httpClient.get('/payouts/$payoutId');
    final data = jsonDecode(response.body);
    return PayoutRequest.fromJson(data['payout'] ?? data);
  }

  /// Cancel pending payout request
  Future<PayoutRequest> cancelPayoutRequest(String payoutId) async {
    final response = await _httpClient.post('/payouts/$payoutId/cancel');
    final data = jsonDecode(response.body);
    return PayoutRequest.fromJson(data['payout'] ?? data);
  }

  // ==================== COMMISSION FILTERS ====================

  /// Get pending commissions (awaiting payout)
  Future<List<CommissionModel>> getPendingCommissions(String sellerId) async {
    return getSellerCommissions(
      sellerId: sellerId,
      payoutStatus: PayoutStatus.pending,
    );
  }

  /// Get paid commissions
  Future<List<CommissionModel>> getPaidCommissions(String sellerId) async {
    return getSellerCommissions(
      sellerId: sellerId,
      payoutStatus: PayoutStatus.completed,
    );
  }

  /// Get live stream commissions only
  Future<List<CommissionModel>> getLiveStreamCommissionsForSeller(String sellerId) async {
    return getSellerCommissions(
      sellerId: sellerId,
      type: CommissionType.liveStreamSale,
    );
  }

  /// Get flash sale commissions only
  Future<List<CommissionModel>> getFlashSaleCommissions(String sellerId) async {
    return getSellerCommissions(
      sellerId: sellerId,
      type: CommissionType.flashSale,
    );
  }

  // ==================== ANALYTICS ====================

  /// Get commission analytics for date range
  Future<CommissionAnalytics> getCommissionAnalytics({
    required String sellerId,
    required String startDate,
    required String endDate,
  }) async {
    final queryString = 'startDate=$startDate&endDate=$endDate';
    final response = await _httpClient.get('/users/$sellerId/commissions/analytics?$queryString');
    final data = jsonDecode(response.body);
    return CommissionAnalytics.fromJson(data['analytics'] ?? data);
  }

  /// Get top performing products by commission
  Future<List<ProductCommissionStats>> getTopProducts({
    required String sellerId,
    int limit = 10,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/users/$sellerId/commissions/top-products?$queryString');

    final data = jsonDecode(response.body);
    final products = data['products'] as List;
    return products.map((p) => ProductCommissionStats.fromJson(p)).toList();
  }
}
