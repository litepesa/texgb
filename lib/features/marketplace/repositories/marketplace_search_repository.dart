// ===============================
// lib/features/marketplace/repositories/marketplace_search_repository.dart
// SIMPLIFIED Marketplace Search Repository - Direct Backend Integration
// ===============================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:textgb/features/marketplace/models/marketplace_item_model.dart';
import 'package:textgb/shared/services/http_client.dart';

// ===============================
// SIMPLIFIED SEARCH REPOSITORY
// ===============================

class MarketplaceSearchRepository {
  final HttpClientService _httpClient;

  MarketplaceSearchRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  /// Simple marketplace search - matches backend /marketplace/search endpoint
  Future<SearchResponse> searchVideos({
    required String query,
    bool usernameOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 Searching: "$query" (usernameOnly: $usernameOnly)');

      // Build query parameters exactly as backend expects
      final queryParams = {
        'q': query.trim(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (usernameOnly) {
        queryParams['usernameOnly'] = 'true';
      }

      // Make API request
      final uri = Uri.parse('/marketplace/search').replace(queryParameters: queryParams);
      final response = await _httpClient.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ Found ${data['total']} results');
        
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw SearchException(errorData['error'] as String? ?? 'Invalid search');
      } else if (response.statusCode == 429) {
        throw SearchException('Too many requests. Please wait a moment.');
      } else {
        throw SearchException('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      
      if (e is SearchException) rethrow;
      
      if (e.toString().contains('SocketException')) {
        throw SearchException('No internet connection');
      }
      
      throw SearchException('Search failed: $e');
    }
  }

  /// Get popular search terms (optional - for trending display)
  Future<List<String>> getPopularTerms({int limit = 10}) async {
    try {
      final uri = Uri.parse('/marketplace/search/popular').replace(
        queryParameters: {'limit': limit.toString()},
      );
      
      final response = await _httpClient.get(uri.toString());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final terms = data['terms'] as List<dynamic>? ?? [];
        return terms.map((t) => t.toString()).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('⚠️ Failed to get popular terms: $e');
      return [];
    }
  }
}

// ===============================
// SIMPLIFIED RESPONSE MODEL
// ===============================

class SearchResponse {
  final List<MarketplaceItemModel> marketplaceItems;
  final int total;
  final String query;
  final bool usernameOnly;
  final int page;
  final int limit;
  final bool hasMore;

  const SearchResponse({
    required this.marketplaceItems,
    required this.total,
    required this.query,
    required this.usernameOnly,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final marketplaceItemsJson = json['videos'] as List<dynamic>? ?? [];
    final marketplaceItems = marketplaceItemsJson
        .map((v) => MarketplaceItemModel.fromJson(v as Map<String, dynamic>))
        .toList();

    return SearchResponse(
      marketplaceItems: marketplaceItems,
      total: json['total'] as int? ?? 0,
      query: json['query'] as String? ?? '',
      usernameOnly: json['usernameOnly'] as bool? ?? false,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  bool get isEmpty => marketplaceItems.isEmpty;
  bool get isNotEmpty => marketplaceItems.isNotEmpty;
}

// ===============================
// SIMPLE EXCEPTION
// ===============================

class SearchException implements Exception {
  final String message;
  const SearchException(this.message);

  @override
  String toString() => message;
}