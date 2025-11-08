// lib/features/shops/repositories/shop_repository.dart

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/shops/models/shop_model.dart';
import 'package:textgb/features/shops/models/product_model.dart';

class ShopRepository {
  final HttpClientService _httpClient;

  ShopRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ==================== SHOP CRUD ====================

  /// Create a new shop
  Future<ShopModel> createShop({
    required String ownerId,
    required String shopName,
    required String about,
    required String shopBanner,
    required String location,
    required String phoneNumber,
    List<String>? tags,
  }) async {
    final response = await _httpClient.post('/shops', body: {
      'ownerId': ownerId,
      'shopName': shopName,
      'about': about,
      'shopBanner': shopBanner,
      'location': location,
      'phoneNumber': phoneNumber,
      'tags': tags ?? [],
    });

    final data = jsonDecode(response.body);
    return ShopModel.fromJson(data['shop'] ?? data);
  }

  /// Get shop by ID
  Future<ShopModel> getShop(String shopId) async {
    final response = await _httpClient.get('/shops/$shopId');
    final data = jsonDecode(response.body);
    return ShopModel.fromJson(data['shop'] ?? data);
  }

  /// Get shop by owner ID
  Future<ShopModel?> getShopByOwner(String ownerId) async {
    try {
      final response = await _httpClient.get('/shops/owner/$ownerId');
      final data = jsonDecode(response.body);
      return ShopModel.fromJson(data['shop'] ?? data);
    } on NotFoundException {
      return null; // No shop found
    }
  }

  /// Update shop
  Future<ShopModel> updateShop({
    required String shopId,
    String? shopName,
    String? about,
    String? shopBanner,
    String? location,
    String? phoneNumber,
    List<String>? tags,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (shopName != null) body['shopName'] = shopName;
    if (about != null) body['about'] = about;
    if (shopBanner != null) body['shopBanner'] = shopBanner;
    if (location != null) body['location'] = location;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (tags != null) body['tags'] = tags;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _httpClient.put('/shops/$shopId', body: body);
    final data = jsonDecode(response.body);
    return ShopModel.fromJson(data['shop'] ?? data);
  }

  /// Delete shop
  Future<void> deleteShop(String shopId) async {
    await _httpClient.delete('/shops/$shopId');
  }

  // ==================== SHOP DISCOVERY ====================

  /// Get all shops (with pagination and filters)
  Future<List<ShopModel>> getShops({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? tag,
    bool? isVerified,
    bool? isFeatured,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (searchQuery != null) queryParams['search'] = searchQuery;
    if (tag != null) queryParams['tag'] = tag;
    if (isVerified != null) queryParams['isVerified'] = isVerified.toString();
    if (isFeatured != null) queryParams['isFeatured'] = isFeatured.toString();
    if (sortBy != null) queryParams['sortBy'] = sortBy;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/shops?$queryString');

    final data = jsonDecode(response.body);
    final shops = data['shops'] as List;
    return shops.map((s) => ShopModel.fromJson(s)).toList();
  }

  /// Get featured shops
  Future<List<ShopModel>> getFeaturedShops({int limit = 10}) async {
    return getShops(limit: limit, isFeatured: true, sortBy: 'followers');
  }

  /// Get verified shops
  Future<List<ShopModel>> getVerifiedShops({int limit = 20}) async {
    return getShops(limit: limit, isVerified: true, sortBy: 'engagement');
  }

  // ==================== SHOP PRODUCTS ====================

  /// Get products for a shop
  Future<List<ProductModel>> getShopProducts({
    required String shopId,
    int limit = 20,
    int offset = 0,
    bool? isActive,
    bool? isFeatured,
    bool? flashSale,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (isFeatured != null) queryParams['isFeatured'] = isFeatured.toString();
    if (flashSale != null) queryParams['flashSale'] = flashSale.toString();

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _httpClient.get('/shops/$shopId/products?$queryString');

    final data = jsonDecode(response.body);
    final products = data['products'] as List;
    return products.map((p) => ProductModel.fromJson(p)).toList();
  }

  /// Add product to shop
  Future<ProductModel> addProduct({
    required String shopId,
    required String videoUrl,
    required String thumbnailUrl,
    required String description,
    required double price,
    List<String>? keywords,
    bool? isMultipleImages,
    List<String>? imageUrls,
    int? initialStock,
  }) async {
    final response = await _httpClient.post('/shops/$shopId/products', body: {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'price': price,
      'keywords': keywords ?? [],
      'isMultipleImages': isMultipleImages ?? false,
      'imageUrls': imageUrls ?? [],
      'initialStock': initialStock,
    });

    final data = jsonDecode(response.body);
    return ProductModel.fromJson(data['product'] ?? data);
  }

  /// Update product
  Future<ProductModel> updateProduct({
    required String productId,
    String? description,
    double? price,
    List<String>? keywords,
    bool? isActive,
    bool? flashSale,
    double? flashSalePrice,
    String? flashSaleEndsAt,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (keywords != null) body['keywords'] = keywords;
    if (isActive != null) body['isActive'] = isActive;
    if (flashSale != null) body['flashSale'] = flashSale;
    if (flashSalePrice != null) body['flashSalePrice'] = flashSalePrice;
    if (flashSaleEndsAt != null) body['flashSaleEndsAt'] = flashSaleEndsAt;

    final response = await _httpClient.put('/products/$productId', body: body);
    final data = jsonDecode(response.body);
    return ProductModel.fromJson(data['product'] ?? data);
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _httpClient.delete('/products/$productId');
  }

  // ==================== SHOP FOLLOWING ====================

  /// Follow shop
  Future<void> followShop({
    required String shopId,
    required String userId,
  }) async {
    await _httpClient.post('/shops/$shopId/follow', body: {'userId': userId});
  }

  /// Unfollow shop
  Future<void> unfollowShop({
    required String shopId,
    required String userId,
  }) async {
    await _httpClient.post('/shops/$shopId/unfollow', body: {'userId': userId});
  }

  /// Get shops followed by user
  Future<List<ShopModel>> getFollowedShops(String userId) async {
    final response = await _httpClient.get('/users/$userId/following/shops');
    final data = jsonDecode(response.body);
    final shops = data['shops'] as List;
    return shops.map((s) => ShopModel.fromJson(s)).toList();
  }

  // ==================== SHOP STATISTICS ====================

  /// Increment shop view count
  Future<void> incrementShopViews(String shopId) async {
    try {
      await _httpClient.post('/shops/$shopId/view');
    } catch (e) {
      // Silent fail for analytics
      print('Warning: Failed to increment shop views: $e');
    }
  }
}
