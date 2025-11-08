// lib/features/shops/routes/shop_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/shops/screens/shops_home_screen.dart';
import 'package:textgb/features/shops/screens/shop_detail_screen.dart';
import 'package:textgb/features/shops/screens/product_detail_screen.dart';
import 'package:textgb/features/shops/screens/create_shop_screen.dart';
import 'package:textgb/features/shops/screens/edit_shop_screen.dart';
import 'package:textgb/features/shops/screens/my_shop_screen.dart';
import 'package:textgb/features/shops/screens/shop_products_screen.dart';
import 'package:textgb/features/shops/screens/add_product_screen.dart';
import 'package:textgb/features/shops/screens/edit_product_screen.dart';
import 'package:textgb/features/shops/screens/cart_screen.dart';
import 'package:textgb/features/shops/screens/checkout_screen.dart';
import 'package:textgb/features/shops/screens/order_detail_screen.dart';
import 'package:textgb/features/shops/screens/my_orders_screen.dart';
import 'package:textgb/features/shops/screens/seller_orders_screen.dart';
import 'package:textgb/features/shops/screens/inventory_screen.dart';
import 'package:textgb/features/shops/screens/earnings_screen.dart';
import 'package:textgb/features/shops/screens/payout_screen.dart';

/// Shop route paths - designed for deep linking
class ShopRoutePaths {
  ShopRoutePaths._();

  // Shop discovery
  static const String shopsHome = '/shops';
  static const String shopDetail = '/shops/:shopId';
  static const String shopProducts = '/shops/:shopId/products';

  // Product pages (shareable links)
  static const String productDetail = '/products/:productId';

  // Shop management
  static const String createShop = '/shops/create';
  static const String myShop = '/my-shop';
  static const String editShop = '/my-shop/edit';
  static const String addProduct = '/my-shop/products/add';
  static const String editProduct = '/my-shop/products/:productId/edit';
  static const String inventory = '/my-shop/inventory';
  static const String earnings = '/my-shop/earnings';
  static const String payout = '/my-shop/payout';
  static const String sellerOrders = '/my-shop/orders';

  // Shopping cart & checkout
  static const String cart = '/cart';
  static const String checkout = '/checkout';

  // Orders (shareable order links)
  static const String myOrders = '/orders';
  static const String orderDetail = '/orders/:orderId';

  // Deep linking helpers
  static String shopDetailPath(String shopId) => '/shops/$shopId';
  static String productDetailPath(String productId) => '/products/$productId';
  static String orderDetailPath(String orderId) => '/orders/$orderId';
  static String editProductPath(String productId) => '/my-shop/products/$productId/edit';
  static String shopProductsPath(String shopId) => '/shops/$shopId/products';
}

/// Shop route names
class ShopRouteNames {
  ShopRouteNames._();

  static const String shopsHome = 'shops-home';
  static const String shopDetail = 'shop-detail';
  static const String shopProducts = 'shop-products';
  static const String productDetail = 'product-detail';
  static const String createShop = 'create-shop';
  static const String myShop = 'my-shop';
  static const String editShop = 'edit-shop';
  static const String addProduct = 'add-product';
  static const String editProduct = 'edit-product';
  static const String inventory = 'inventory';
  static const String earnings = 'earnings';
  static const String payout = 'payout';
  static const String sellerOrders = 'seller-orders';
  static const String cart = 'cart';
  static const String checkout = 'checkout';
  static const String myOrders = 'my-orders';
  static const String orderDetail = 'order-detail';
}

/// Shop routes configuration
List<RouteBase> shopRoutes = [
  // Shop discovery
  GoRoute(
    path: ShopRoutePaths.shopsHome,
    name: ShopRouteNames.shopsHome,
    builder: (context, state) => const ShopsHomeScreen(),
    routes: [
      // Shop detail (deep linkable)
      GoRoute(
        path: ':shopId',
        name: ShopRouteNames.shopDetail,
        builder: (context, state) {
          final shopId = state.pathParameters['shopId']!;
          return ShopDetailScreen(shopId: shopId);
        },
        routes: [
          // Shop products
          GoRoute(
            path: 'products',
            name: ShopRouteNames.shopProducts,
            builder: (context, state) {
              final shopId = state.pathParameters['shopId']!;
              return ShopProductsScreen(shopId: shopId);
            },
          ),
        ],
      ),
    ],
  ),

  // Product detail (deep linkable - shareable product links)
  GoRoute(
    path: '/products/:productId',
    name: ShopRouteNames.productDetail,
    builder: (context, state) {
      final productId = state.pathParameters['productId']!;
      final fromLiveStream = state.uri.queryParameters['fromLive'] == 'true';
      final liveStreamId = state.uri.queryParameters['streamId'];

      return ProductDetailScreen(
        productId: productId,
        fromLiveStream: fromLiveStream,
        liveStreamId: liveStreamId,
      );
    },
  ),

  // Shop management
  GoRoute(
    path: '/shops/create',
    name: ShopRouteNames.createShop,
    builder: (context, state) => const CreateShopScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.myShop,
    name: ShopRouteNames.myShop,
    builder: (context, state) => const MyShopScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.editShop,
    name: ShopRouteNames.editShop,
    builder: (context, state) => const EditShopScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.addProduct,
    name: ShopRouteNames.addProduct,
    builder: (context, state) => const AddProductScreen(),
  ),

  GoRoute(
    path: '/my-shop/products/:productId/edit',
    name: ShopRouteNames.editProduct,
    builder: (context, state) {
      final productId = state.pathParameters['productId']!;
      return EditProductScreen(productId: productId);
    },
  ),

  GoRoute(
    path: ShopRoutePaths.inventory,
    name: ShopRouteNames.inventory,
    builder: (context, state) => const InventoryScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.earnings,
    name: ShopRouteNames.earnings,
    builder: (context, state) => const EarningsScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.payout,
    name: ShopRouteNames.payout,
    builder: (context, state) => const PayoutScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.sellerOrders,
    name: ShopRouteNames.sellerOrders,
    builder: (context, state) => const SellerOrdersScreen(),
  ),

  // Shopping cart & checkout
  GoRoute(
    path: ShopRoutePaths.cart,
    name: ShopRouteNames.cart,
    builder: (context, state) => const CartScreen(),
  ),

  GoRoute(
    path: ShopRoutePaths.checkout,
    name: ShopRouteNames.checkout,
    builder: (context, state) => const CheckoutScreen(),
  ),

  // Orders (deep linkable - shareable order links)
  GoRoute(
    path: ShopRoutePaths.myOrders,
    name: ShopRouteNames.myOrders,
    builder: (context, state) => const MyOrdersScreen(),
  ),

  GoRoute(
    path: '/orders/:orderId',
    name: ShopRouteNames.orderDetail,
    builder: (context, state) {
      final orderId = state.pathParameters['orderId']!;
      return OrderDetailScreen(orderId: orderId);
    },
  ),
];

/// Navigation extensions for shops
extension ShopNavigation on BuildContext {
  // Shop discovery
  void goToShopsHome() => go(ShopRoutePaths.shopsHome);
  Future<T?> pushToShopsHome<T>() => push<T>(ShopRoutePaths.shopsHome);

  void goToShopDetail(String shopId) => go(ShopRoutePaths.shopDetailPath(shopId));
  Future<T?> pushToShopDetail<T>(String shopId) => push<T>(ShopRoutePaths.shopDetailPath(shopId));

  void goToShopProducts(String shopId) => go(ShopRoutePaths.shopProductsPath(shopId));
  Future<T?> pushToShopProducts<T>(String shopId) => push<T>(ShopRoutePaths.shopProductsPath(shopId));

  void goToProductDetail(String productId, {bool fromLiveStream = false, String? liveStreamId}) {
    final uri = Uri(
      path: ShopRoutePaths.productDetailPath(productId),
      queryParameters: {
        if (fromLiveStream) 'fromLive': 'true',
        if (liveStreamId != null) 'streamId': liveStreamId,
      },
    );
    go(uri.toString());
  }

  Future<T?> pushToProductDetail<T>(String productId, {bool fromLiveStream = false, String? liveStreamId}) {
    final uri = Uri(
      path: ShopRoutePaths.productDetailPath(productId),
      queryParameters: {
        if (fromLiveStream) 'fromLive': 'true',
        if (liveStreamId != null) 'streamId': liveStreamId,
      },
    );
    return push<T>(uri.toString());
  }

  // Shop management
  void goToCreateShop() => go(ShopRoutePaths.createShop);
  Future<T?> pushToCreateShop<T>() => push<T>(ShopRoutePaths.createShop);

  void goToMyShop() => go(ShopRoutePaths.myShop);
  Future<T?> pushToMyShop<T>() => push<T>(ShopRoutePaths.myShop);

  void goToEditShop() => go(ShopRoutePaths.editShop);
  Future<T?> pushToEditShop<T>() => push<T>(ShopRoutePaths.editShop);

  void goToAddProduct() => go(ShopRoutePaths.addProduct);
  Future<T?> pushToAddProduct<T>() => push<T>(ShopRoutePaths.addProduct);

  void goToEditProduct(String productId) => go(ShopRoutePaths.editProductPath(productId));
  Future<T?> pushToEditProduct<T>(String productId) => push<T>(ShopRoutePaths.editProductPath(productId));

  void goToInventory() => go(ShopRoutePaths.inventory);
  Future<T?> pushToInventory<T>() => push<T>(ShopRoutePaths.inventory);

  void goToEarnings() => go(ShopRoutePaths.earnings);
  Future<T?> pushToEarnings<T>() => push<T>(ShopRoutePaths.earnings);

  void goToPayout() => go(ShopRoutePaths.payout);
  Future<T?> pushToPayout<T>() => push<T>(ShopRoutePaths.payout);

  void goToSellerOrders() => go(ShopRoutePaths.sellerOrders);
  Future<T?> pushToSellerOrders<T>() => push<T>(ShopRoutePaths.sellerOrders);

  // Cart & checkout
  void goToCart() => go(ShopRoutePaths.cart);
  Future<T?> pushToCart<T>() => push<T>(ShopRoutePaths.cart);

  void goToCheckout() => go(ShopRoutePaths.checkout);
  Future<T?> pushToCheckout<T>() => push<T>(ShopRoutePaths.checkout);

  // Orders
  void goToMyOrders() => go(ShopRoutePaths.myOrders);
  Future<T?> pushToMyOrders<T>() => push<T>(ShopRoutePaths.myOrders);

  void goToOrderDetail(String orderId) => go(ShopRoutePaths.orderDetailPath(orderId));
  Future<T?> pushToOrderDetail<T>(String orderId) => push<T>(ShopRoutePaths.orderDetailPath(orderId));
}
