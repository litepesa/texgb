# TextGB Routing & Deep Linking Guide

## Overview

TextGB uses **go_router** for navigation with comprehensive deep linking support. This is crucial for the e-commerce features, allowing users to share products, shops, orders, and live streams.

## Table of Contents

1. [Shop Routes](#shop-routes)
2. [Live Streaming Routes](#live-streaming-routes)
3. [Deep Linking](#deep-linking)
4. [Navigation Examples](#navigation-examples)
5. [Shareable Links](#shareable-links)

---

## Shop Routes

### Route Paths

| Route | Path | Deep Linkable | Description |
|-------|------|---------------|-------------|
| Shops Home | `/shops` | ✅ | Browse all shops |
| Shop Detail | `/shops/:shopId` | ✅ | View shop details (shareable) |
| Shop Products | `/shops/:shopId/products` | ✅ | View shop's products |
| Product Detail | `/products/:productId` | ✅ | View product (shareable) |
| Create Shop | `/shops/create` | ❌ | Create new shop |
| My Shop | `/my-shop` | ❌ | Manage your shop |
| Edit Shop | `/my-shop/edit` | ❌ | Edit shop details |
| Add Product | `/my-shop/products/add` | ❌ | Add product to shop |
| Edit Product | `/my-shop/products/:productId/edit` | ❌ | Edit product |
| Inventory | `/my-shop/inventory` | ❌ | Manage inventory |
| Earnings | `/my-shop/earnings` | ❌ | View earnings |
| Payout | `/my-shop/payout` | ❌ | Request payout |
| Seller Orders | `/my-shop/orders` | ❌ | View seller orders |
| Cart | `/cart` | ❌ | Shopping cart |
| Checkout | `/checkout` | ❌ | Checkout page |
| My Orders | `/orders` | ❌ | View my orders |
| Order Detail | `/orders/:orderId` | ✅ | Track order (shareable) |

### Usage Examples

```dart
// Navigate to shops
context.goToShopsHome();

// Navigate to specific shop (shareable)
context.goToShopDetail('shop123');

// Navigate to product with live stream context
context.goToProductDetail(
  'product123',
  fromLiveStream: true,
  liveStreamId: 'stream456',
);

// Navigate to cart
context.pushToCart(); // Use push to maintain back stack

// Navigate to order tracking (shareable)
context.goToOrderDetail('order789');
```

---

## Live Streaming Routes

### Route Paths

| Route | Path | Deep Linkable | Description |
|-------|------|---------------|-------------|
| Live Streams Home | `/live` | ✅ | Browse live streams |
| View Stream | `/live/:streamId` | ✅ | Watch live stream (shareable) |
| Create Stream | `/live/create` | ❌ | Create new stream |
| Stream Setup | `/live/setup` | ❌ | Configure stream settings |
| Host Stream | `/live/host/:streamId` | ❌ | Host streaming screen |
| My Streams | `/my-live-streams` | ❌ | View my stream history |
| Stream Analytics | `/my-live-streams/:streamId/analytics` | ❌ | View stream analytics |
| Gift Shop | `/gifts` | ❌ | Purchase virtual gifts |

### Query Parameters

#### Live Streams Home
- `?type=gift` - Filter gift streams only
- `?type=shop` - Filter shop streams only

#### View Stream
- `?ref=userId` - Referrer tracking
- `?autoJoin=true` - Auto-join stream

#### Create Stream
- `?type=gift` - Pre-select gift stream
- `?type=shop` - Pre-select shop stream
- `?shopId=shop123` - Pre-select shop for shop stream

### Usage Examples

```dart
// Browse all live streams
context.goToLiveStreamsHome();

// Browse only shop streams
context.goToLiveStreamsHome(filterType: LiveStreamType.shop);

// Watch a live stream (shareable link)
context.goToLiveStreamViewer(
  'stream123',
  referrerId: 'user456',
  autoJoin: true,
);

// Create shop live from your shop
context.goToCreateShopLiveFromShop('myShopId');

// Generate shareable stream link
final shareLink = context.getShareableLiveStreamLink(
  'stream123',
  userId: currentUserId,
);
```

---

## Deep Linking

### Shareable Links

Deep links are crucial for e-commerce sharing. The app supports these shareable link types:

#### Product Links
```
https://textgb.app/products/prod123?ref=user456
```

Generate:
```dart
final link = DeepLinkHelper.productLink(
  'prod123',
  referrerId: 'user456',
  campaignId: 'summer_sale',
);

// Share text
final shareText = DeepLinkHelper.productShareText(
  'Awesome Product',
  999.99,
  link,
);
```

#### Shop Links
```
https://textgb.app/shops/shop123?ref=user456
```

Generate:
```dart
final link = DeepLinkHelper.shopLink(
  'shop123',
  referrerId: 'user456',
);
```

#### Order Tracking Links
```
https://textgb.app/orders/order123
```

Generate:
```dart
final link = DeepLinkHelper.orderTrackingLink('order123');
```

#### Live Stream Links
```
https://textgb.app/live/stream123?ref=user456&autoJoin=true
```

Generate:
```dart
final link = DeepLinkHelper.liveStreamLink(
  'stream123',
  referrerId: 'user456',
  autoJoin: true,
);

// Or invite link
final inviteLink = DeepLinkHelper.liveStreamInviteLink(
  'stream123',
  'host123',
);
```

#### Product from Live Stream
```
https://textgb.app/products/prod123?fromLive=true&streamId=stream456
```

Generate:
```dart
final link = DeepLinkHelper.productFromLiveStreamLink(
  'prod123',
  'stream456',
  referrerId: 'user456',
);
```

### Marketing Campaign Links

Track marketing campaigns with UTM parameters:

```dart
final link = DeepLinkHelper.productCampaignLink(
  'prod123',
  campaignId: 'summer_sale',
  source: 'instagram',
  medium: 'social',
);
// https://textgb.app/products/prod123?campaign=summer_sale&utm_source=instagram&utm_medium=social
```

### QR Codes

Generate QR code data for physical marketing:

```dart
// Product QR code
final qrData = DeepLinkHelper.productQRData('prod123');

// Shop QR code
final qrData = DeepLinkHelper.shopQRData('shop123');

// Live stream QR code
final qrData = DeepLinkHelper.liveStreamQRData('stream123', 'host123');
```

### Link Validation & Extraction

```dart
// Check if valid TextGB link
if (url.isTextGBDeepLink) {
  // Extract IDs
  final productId = url.productId;
  final shopId = url.shopId;
  final streamId = url.streamId;
  final orderId = url.orderId;
  final referrerId = url.referrerId;

  // Navigate accordingly
  if (productId != null) {
    context.goToProductDetail(productId);
  }
}
```

---

## Navigation Examples

### Basic Navigation

```dart
// Replace current route (no back button)
context.goToShopsHome();

// Push route (with back button)
await context.pushToShopsHome();

// Push and wait for result
final result = await context.pushToProductDetail<bool>('prod123');
if (result == true) {
  // Product was added to cart
}
```

### Product Navigation

```dart
// From anywhere
context.goToProductDetail('prod123');

// From live stream
context.goToProductDetail(
  'prod123',
  fromLiveStream: true,
  liveStreamId: 'stream456',
);

// Push and refresh after
await context.pushToProductDetail('prod123');
_refreshData();
```

### Shop Management Flow

```dart
// Create shop
await context.pushToCreateShop();

// Navigate to my shop
context.goToMyShop();

// Add product
await context.pushToAddProduct();

// Edit product
await context.pushToEditProduct('prod123');

// View inventory
context.goToInventory();

// View earnings
context.goToEarnings();
```

### Shopping Flow

```dart
// Browse products
context.goToShopProducts('shop123');

// View product
await context.pushToProductDetail('prod123');

// Go to cart
context.pushToCart();

// Checkout
context.pushToCheckout();

// View orders
context.goToMyOrders();

// Track specific order
context.goToOrderDetail('order123');
```

### Live Streaming Flow

```dart
// Browse streams
context.goToLiveStreamsHome();

// Filter by type
context.goToLiveStreamsHome(filterType: LiveStreamType.shop);

// Create stream
await context.pushToCreateLiveStream(
  preselectedType: LiveStreamType.shop,
  shopId: 'myShop123',
);

// Setup stream
context.goToLiveStreamSetup();

// Start hosting
context.goToLiveStreamHost('stream123');

// View as audience
context.goToLiveStreamViewer('stream123');

// View my streams
context.goToMyLiveStreams();

// View analytics
context.goToLiveStreamAnalytics('stream123');
```

---

## Route Configuration

### Adding Routes to App Router

```dart
// In lib/core/router/app_router.dart

import 'package:textgb/features/shops/routes/shop_routes.dart';
import 'package:textgb/features/live_streaming/routes/live_streaming_routes.dart';

final router = GoRouter(
  routes: [
    // Existing routes...

    // Add shop routes
    ...shopRoutes,

    // Add live streaming routes
    ...liveStreamingRoutes,
  ],
);
```

### Deep Link Handling

The app automatically handles deep links through go_router. When a user clicks a share link:

1. Link is parsed by go_router
2. Route parameters are extracted
3. Appropriate screen is displayed
4. Referrer/campaign tracking is preserved

Example flow:
```
User clicks: https://textgb.app/products/prod123?ref=user456
↓
go_router parses URL
↓
ProductDetailScreen(productId: 'prod123')
↓
Track referrer: user456
```

---

## Best Practices

### 1. Use Push for Modal Screens
```dart
// ✅ Good - Can go back
await context.pushToProductDetail('prod123');

// ❌ Bad - Replaces route
context.goToProductDetail('prod123');
```

### 2. Always Include Referrer in Shares
```dart
// ✅ Good - Track who shared
final link = DeepLinkHelper.productLink(
  'prod123',
  referrerId: currentUserId,
);

// ❌ Bad - No attribution
final link = DeepLinkHelper.productLink('prod123');
```

### 3. Use Campaign Tracking for Marketing
```dart
// ✅ Good - Track campaign performance
final link = DeepLinkHelper.productCampaignLink(
  'prod123',
  campaignId: 'summer_sale',
  source: 'instagram',
  medium: 'story',
);
```

### 4. Generate Share Text with Links
```dart
// ✅ Good - Complete share experience
final shareText = DeepLinkHelper.productShareText(
  product.name,
  product.price,
  productLink,
);
await Share.share(shareText);
```

---

## Testing Deep Links

### iOS Simulator
```bash
xcrun simctl openurl booted "https://textgb.app/products/prod123"
```

### Android Emulator
```bash
adb shell am start -a android.intent.action.VIEW -d "https://textgb.app/products/prod123"
```

### Testing in App
```dart
// Test deep link handling
final testLink = 'https://textgb.app/products/prod123?ref=user456';

if (testLink.isTextGBDeepLink) {
  print('Product ID: ${testLink.productId}');
  print('Referrer: ${testLink.referrerId}');
}
```

---

## Configuration Checklist

- [ ] Update base URL in `DeepLinkHelper.baseUrl`
- [ ] Configure universal links (iOS: Associated Domains)
- [ ] Configure App Links (Android: assetlinks.json)
- [ ] Test all shareable routes
- [ ] Implement analytics tracking for deep links
- [ ] Add deep link attribution to backend
- [ ] Test QR code generation and scanning
- [ ] Verify campaign tracking parameters

---

## Summary

The routing system provides:
- ✅ Type-safe navigation with extensions
- ✅ Comprehensive deep linking for e-commerce
- ✅ Shareable product, shop, and order links
- ✅ Live stream invite links
- ✅ Marketing campaign tracking
- ✅ QR code support
- ✅ Referral attribution
- ✅ Easy link generation and validation

All routes follow REST-like patterns and support clean, shareable URLs perfect for social media sharing and marketing campaigns.
