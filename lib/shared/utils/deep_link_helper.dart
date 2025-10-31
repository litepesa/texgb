// lib/shared/utils/deep_link_helper.dart

import 'package:textgb/features/shops/routes/shop_routes.dart';
import 'package:textgb/features/live_streaming/routes/live_streaming_routes.dart';

/// Deep linking helper for generating shareable links
/// Perfect for e-commerce product sharing, order tracking, and live stream invites
class DeepLinkHelper {
  DeepLinkHelper._();

  // Base URL for your app (update with your actual domain)
  static const String baseUrl = 'https://textgb.app'; // TODO: Update with actual domain
  static const String appScheme = 'textgb://'; // Custom URL scheme

  // ==================== SHOP DEEP LINKS ====================

  /// Generate shareable product link
  /// Example: https://textgb.app/products/prod123?ref=user456
  static String productLink(String productId, {String? referrerId, String? campaignId}) {
    final path = ShopRoutePaths.productDetailPath(productId);
    final queryParams = <String, String>{};

    if (referrerId != null) queryParams['ref'] = referrerId;
    if (campaignId != null) queryParams['campaign'] = campaignId;

    return _buildLink(path, queryParams);
  }

  /// Generate shareable shop link
  /// Example: https://textgb.app/shops/shop123?ref=user456
  static String shopLink(String shopId, {String? referrerId}) {
    final path = ShopRoutePaths.shopDetailPath(shopId);
    final queryParams = <String, String>{};

    if (referrerId != null) queryParams['ref'] = referrerId;

    return _buildLink(path, queryParams);
  }

  /// Generate shareable order tracking link
  /// Example: https://textgb.app/orders/order123
  static String orderTrackingLink(String orderId) {
    final path = ShopRoutePaths.orderDetailPath(orderId);
    return _buildLink(path, {});
  }

  /// Generate product link from live stream
  /// Example: https://textgb.app/products/prod123?fromLive=true&streamId=stream123
  static String productFromLiveStreamLink(
    String productId,
    String liveStreamId, {
    String? referrerId,
  }) {
    final path = ShopRoutePaths.productDetailPath(productId);
    final queryParams = <String, String>{
      'fromLive': 'true',
      'streamId': liveStreamId,
    };

    if (referrerId != null) queryParams['ref'] = referrerId;

    return _buildLink(path, queryParams);
  }

  // ==================== LIVE STREAM DEEP LINKS ====================

  /// Generate shareable live stream link
  /// Example: https://textgb.app/live/stream123?ref=user456
  static String liveStreamLink(String streamId, {String? referrerId, bool autoJoin = false}) {
    final path = LiveStreamRoutePaths.liveStreamViewerPath(streamId);
    final queryParams = <String, String>{};

    if (referrerId != null) queryParams['ref'] = referrerId;
    if (autoJoin) queryParams['autoJoin'] = 'true';

    return _buildLink(path, queryParams);
  }

  /// Generate live stream invite link
  /// Example: https://textgb.app/live/stream123?ref=user456&invite=true
  static String liveStreamInviteLink(String streamId, String hostId) {
    final path = LiveStreamRoutePaths.liveStreamViewerPath(streamId);
    final queryParams = <String, String>{
      'ref': hostId,
      'invite': 'true',
      'autoJoin': 'true',
    };

    return _buildLink(path, queryParams);
  }

  // ==================== HELPER METHODS ====================

  /// Build full URL from path and query parameters
  static String _buildLink(String path, Map<String, String> queryParams) {
    final uri = Uri(
      scheme: 'https',
      host: baseUrl.replaceAll('https://', '').replaceAll('http://', ''),
      path: path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    return uri.toString();
  }

  /// Build custom scheme URL (for app-to-app navigation)
  static String _buildSchemeLink(String path, Map<String, String> queryParams) {
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$appScheme$path${queryString.isNotEmpty ? '?$queryString' : ''}';
  }

  // ==================== SHARE TEXT GENERATION ====================

  /// Generate share text for product
  static String productShareText(String productName, double price, String productLink) {
    return '''
Check out this amazing product on TextGB! 🛍️

$productName
KES ${price.toStringAsFixed(2)}

$productLink
''';
  }

  /// Generate share text for shop
  static String shopShareText(String shopName, String shopLink) {
    return '''
Visit $shopName on TextGB! 🏪

Discover great products and deals!

$shopLink
''';
  }

  /// Generate share text for live stream
  static String liveStreamShareText(String hostName, String title, String streamLink) {
    return '''
$hostName is LIVE now! 🔴

$title

Join the stream:
$streamLink
''';
  }

  /// Generate share text for order (for customer support)
  static String orderShareText(String orderId, String orderLink) {
    return '''
Order #$orderId

Track your order:
$orderLink
''';
  }

  // ==================== MARKETING CAMPAIGN LINKS ====================

  /// Generate product link with campaign tracking
  static String productCampaignLink(
    String productId, {
    required String campaignId,
    String? source,
    String? medium,
  }) {
    final path = ShopRoutePaths.productDetailPath(productId);
    final queryParams = <String, String>{
      'campaign': campaignId,
    };

    if (source != null) queryParams['utm_source'] = source;
    if (medium != null) queryParams['utm_medium'] = medium;

    return _buildLink(path, queryParams);
  }

  /// Generate shop link with campaign tracking
  static String shopCampaignLink(
    String shopId, {
    required String campaignId,
    String? source,
    String? medium,
  }) {
    final path = ShopRoutePaths.shopDetailPath(shopId);
    final queryParams = <String, String>{
      'campaign': campaignId,
    };

    if (source != null) queryParams['utm_source'] = source;
    if (medium != null) queryParams['utm_medium'] = medium;

    return _buildLink(path, queryParams);
  }

  // ==================== QR CODE DATA ====================

  /// Generate QR code data for product
  static String productQRData(String productId, {String? referrerId}) {
    return productLink(productId, referrerId: referrerId);
  }

  /// Generate QR code data for shop
  static String shopQRData(String shopId, {String? referrerId}) {
    return shopLink(shopId, referrerId: referrerId);
  }

  /// Generate QR code data for live stream
  static String liveStreamQRData(String streamId, String hostId) {
    return liveStreamLink(streamId, referrerId: hostId, autoJoin: true);
  }

  // ==================== VALIDATION ====================

  /// Check if a URL is a valid TextGB deep link
  static bool isValidDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('textgb') || url.startsWith(appScheme);
    } catch (e) {
      return false;
    }
  }

  /// Extract product ID from deep link
  static String? extractProductId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0] == 'products') {
        return segments[1];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extract shop ID from deep link
  static String? extractShopId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0] == 'shops') {
        return segments[1];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extract stream ID from deep link
  static String? extractStreamId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0] == 'live') {
        return segments[1];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extract order ID from deep link
  static String? extractOrderId(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0] == 'orders') {
        return segments[1];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Extract referrer ID from query parameters
  static String? extractReferrerId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['ref'];
    } catch (e) {
      return null;
    }
  }

  /// Extract campaign ID from query parameters
  static String? extractCampaignId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['campaign'];
    } catch (e) {
      return null;
    }
  }
}

/// Extension to make sharing easier
extension ShareHelpers on String {
  /// Check if this URL is a TextGB deep link
  bool get isTextGBDeepLink => DeepLinkHelper.isValidDeepLink(this);

  /// Extract product ID if this is a product link
  String? get productId => DeepLinkHelper.extractProductId(this);

  /// Extract shop ID if this is a shop link
  String? get shopId => DeepLinkHelper.extractShopId(this);

  /// Extract stream ID if this is a live stream link
  String? get streamId => DeepLinkHelper.extractStreamId(this);

  /// Extract order ID if this is an order link
  String? get orderId => DeepLinkHelper.extractOrderId(this);

  /// Extract referrer ID from query parameters
  String? get referrerId => DeepLinkHelper.extractReferrerId(this);
}
