// lib/features/shops/repositories/order_repository.dart

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/shops/models/order_model.dart';

class OrderRepository {
  final HttpClientService _httpClient;

  OrderRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== ORDER CRUD ====================

  /// Create order (purchase)
  Future<OrderModel> createOrder({
    required String buyerId,
    required String sellerId,
    required String shopId,
    required List<OrderItem> items,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    String? deliveryNotes,
    String? liveStreamId,
    double shippingCost = 0.0,
    double commissionRate = 10.0,
  }) async {
    final response = await _httpClient.post('/orders', body: {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'shopId': shopId,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryPhone': deliveryPhone,
      'deliveryNotes': deliveryNotes,
      'liveStreamId': liveStreamId,
      'shippingCost': shippingCost,
      'commissionRate': commissionRate,
    });

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Get order by ID
  Future<OrderModel> getOrder(String orderId) async {
    final response = await _httpClient.get('/orders/$orderId');
    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Get buyer's orders
  Future<List<OrderModel>> getBuyerOrders({
    required String buyerId,
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status.name;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/users/$buyerId/orders/buyer?$queryString');

    final data = jsonDecode(response.body);
    final orders = data['orders'] as List;
    return orders.map((o) => OrderModel.fromJson(o)).toList();
  }

  /// Get seller's orders
  Future<List<OrderModel>> getSellerOrders({
    required String sellerId,
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status.name;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/users/$sellerId/orders/seller?$queryString');

    final data = jsonDecode(response.body);
    final orders = data['orders'] as List;
    return orders.map((o) => OrderModel.fromJson(o)).toList();
  }

  /// Get shop's orders
  Future<List<OrderModel>> getShopOrders({
    required String shopId,
    int limit = 20,
    int offset = 0,
    OrderStatus? status,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status.name;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/shops/$shopId/orders?$queryString');

    final data = jsonDecode(response.body);
    final orders = data['orders'] as List;
    return orders.map((o) => OrderModel.fromJson(o)).toList();
  }

  // ==================== ORDER STATUS UPDATES ====================

  /// Mark order as paid (after wallet transaction)
  Future<OrderModel> markOrderPaid({
    required String orderId,
    required String transactionId,
  }) async {
    final response = await _httpClient.post('/orders/$orderId/pay',
      body: {'transactionId': transactionId}
    );

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Update order status
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final response = await _httpClient.put('/orders/$orderId/status',
      body: {'status': status.name}
    );

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Cancel order
  Future<OrderModel> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final response = await _httpClient.post('/orders/$orderId/cancel',
      body: {'reason': reason}
    );

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Request refund
  Future<OrderModel> requestRefund({
    required String orderId,
    required String reason,
  }) async {
    final response = await _httpClient.post('/orders/$orderId/refund',
      body: {'reason': reason}
    );

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Mark order as shipped
  Future<OrderModel> markOrderShipped({
    required String orderId,
    String? trackingNumber,
  }) async {
    final response = await _httpClient.post('/orders/$orderId/ship',
      body: {'trackingNumber': trackingNumber}
    );

    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  /// Mark order as delivered
  Future<OrderModel> markOrderDelivered(String orderId) async {
    final response = await _httpClient.post('/orders/$orderId/deliver');
    final data = jsonDecode(response.body);
    return OrderModel.fromJson(data['order'] ?? data);
  }

  // ==================== ORDER ANALYTICS ====================

  /// Get order statistics for seller
  Future<Map<String, dynamic>> getSellerOrderStats(String sellerId) async {
    final response = await _httpClient.get('/users/$sellerId/orders/stats');
    return jsonDecode(response.body);
  }

  /// Get live stream orders (orders made during a specific live stream)
  Future<List<OrderModel>> getLiveStreamOrders(String liveStreamId) async {
    final response = await _httpClient.get('/live-streams/$liveStreamId/orders');
    final data = jsonDecode(response.body);
    final orders = data['orders'] as List;
    return orders.map((o) => OrderModel.fromJson(o)).toList();
  }
}
