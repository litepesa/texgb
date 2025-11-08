// lib/features/shops/repositories/inventory_repository.dart

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/shops/models/inventory_model.dart';

class InventoryRepository {
  final HttpClientService _httpClient;

  InventoryRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== INVENTORY CRUD ====================

  /// Create inventory record for product
  Future<InventoryModel> createInventory({
    required String productId,
    required String shopId,
    required int initialStock,
    required double sellingPrice,
    double? costPrice,
    int lowStockThreshold = 10,
  }) async {
    final response = await _httpClient.post('/inventory', body: {
      'productId': productId,
      'shopId': shopId,
      'initialStock': initialStock,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice ?? 0.0,
      'lowStockThreshold': lowStockThreshold,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Get inventory for product
  Future<InventoryModel> getInventory(String productId) async {
    final response = await _httpClient.get('/products/$productId/inventory');
    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Get all inventory for shop
  Future<List<InventoryModel>> getShopInventory({
    required String shopId,
    StockStatus? status,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status.name;

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _httpClient.get('/shops/$shopId/inventory$queryString');
    final data = jsonDecode(response.body);
    final inventory = data['inventory'] as List;
    return inventory.map((i) => InventoryModel.fromJson(i)).toList();
  }

  // ==================== STOCK OPERATIONS ====================

  /// Add stock (restock)
  Future<InventoryModel> addStock({
    required String productId,
    required int quantity,
    String? notes,
    String? performedBy,
  }) async {
    final response = await _httpClient.post('/products/$productId/inventory/add', body: {
      'quantity': quantity,
      'notes': notes,
      'performedBy': performedBy,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Remove stock (manual removal, damage, etc.)
  Future<InventoryModel> removeStock({
    required String productId,
    required int quantity,
    required StockMovementType reason,
    String? notes,
    String? performedBy,
  }) async {
    final response = await _httpClient.post('/products/$productId/inventory/remove', body: {
      'quantity': quantity,
      'reason': reason.name,
      'notes': notes,
      'performedBy': performedBy,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Reserve stock (for pending order)
  Future<InventoryModel> reserveStock({
    required String productId,
    required int quantity,
    required String orderId,
  }) async {
    final response = await _httpClient.post('/products/$productId/inventory/reserve', body: {
      'quantity': quantity,
      'orderId': orderId,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Release reserved stock (order cancelled)
  Future<InventoryModel> releaseStock({
    required String productId,
    required int quantity,
    required String orderId,
  }) async {
    final response = await _httpClient.post('/products/$productId/inventory/release', body: {
      'quantity': quantity,
      'orderId': orderId,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  /// Confirm sale (convert reserved to sold)
  Future<InventoryModel> confirmSale({
    required String productId,
    required int quantity,
    required String orderId,
  }) async {
    final response = await _httpClient.post('/products/$productId/inventory/sell', body: {
      'quantity': quantity,
      'orderId': orderId,
    });

    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  // ==================== INVENTORY SETTINGS ====================

  /// Update inventory settings
  Future<InventoryModel> updateInventory({
    required String productId,
    int? lowStockThreshold,
    int? maxStock,
    bool? trackInventory,
    bool? allowBackorder,
    double? costPrice,
    double? sellingPrice,
    double? salePrice,
  }) async {
    final body = <String, dynamic>{};
    if (lowStockThreshold != null) body['lowStockThreshold'] = lowStockThreshold;
    if (maxStock != null) body['maxStock'] = maxStock;
    if (trackInventory != null) body['trackInventory'] = trackInventory;
    if (allowBackorder != null) body['allowBackorder'] = allowBackorder;
    if (costPrice != null) body['costPrice'] = costPrice;
    if (sellingPrice != null) body['sellingPrice'] = sellingPrice;
    if (salePrice != null) body['salePrice'] = salePrice;

    final response = await _httpClient.put('/products/$productId/inventory', body: body);
    final data = jsonDecode(response.body);
    return InventoryModel.fromJson(data['inventory'] ?? data);
  }

  // ==================== STOCK MOVEMENTS ====================

  /// Get stock movement history
  Future<List<StockMovement>> getStockMovements({
    required String productId,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryString = 'limit=$limit&offset=$offset';
    final response = await _httpClient.get('/products/$productId/inventory/movements?$queryString');

    final data = jsonDecode(response.body);
    final movements = data['movements'] as List;
    return movements.map((m) => StockMovement.fromJson(m)).toList();
  }

  // ==================== INVENTORY ALERTS ====================

  /// Get low stock products for shop
  Future<List<InventoryModel>> getLowStockProducts(String shopId) async {
    return getShopInventory(shopId: shopId, status: StockStatus.lowStock);
  }

  /// Get out of stock products for shop
  Future<List<InventoryModel>> getOutOfStockProducts(String shopId) async {
    return getShopInventory(shopId: shopId, status: StockStatus.outOfStock);
  }
}
