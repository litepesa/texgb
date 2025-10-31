// lib/features/live_streaming/routes/live_streaming_routes.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/live_streaming/screens/live_streams_home_screen.dart';
import 'package:textgb/features/live_streaming/screens/live_stream_viewer_screen.dart';
import 'package:textgb/features/live_streaming/screens/live_stream_host_screen.dart';
import 'package:textgb/features/live_streaming/screens/create_live_stream_screen.dart';
import 'package:textgb/features/live_streaming/screens/live_stream_setup_screen.dart';
import 'package:textgb/features/live_streaming/screens/my_live_streams_screen.dart';
import 'package:textgb/features/live_streaming/screens/live_stream_analytics_screen.dart';
import 'package:textgb/features/live_streaming/screens/gift_shop_screen.dart';
import 'package:textgb/features/live_streaming/models/live_stream_type_model.dart';

/// Live streaming route paths - designed for deep linking
class LiveStreamRoutePaths {
  LiveStreamRoutePaths._();

  // Live stream discovery
  static const String liveStreamsHome = '/live';
  static const String liveStreamViewer = '/live/:streamId';

  // Host streaming
  static const String createLiveStream = '/live/create';
  static const String liveStreamSetup = '/live/setup';
  static const String liveStreamHost = '/live/host/:streamId';

  // My streams
  static const String myLiveStreams = '/my-live-streams';
  static const String liveStreamAnalytics = '/my-live-streams/:streamId/analytics';

  // Gift shop
  static const String giftShop = '/gifts';

  // Deep linking helpers
  static String liveStreamViewerPath(String streamId) => '/live/$streamId';
  static String liveStreamHostPath(String streamId) => '/live/host/$streamId';
  static String liveStreamAnalyticsPath(String streamId) => '/my-live-streams/$streamId/analytics';

  // Shareable link with optional params
  static String shareLiveStreamLink(String streamId, {String? referrerId}) {
    final uri = Uri(
      path: '/live/$streamId',
      queryParameters: {
        if (referrerId != null) 'ref': referrerId,
      },
    );
    return uri.toString();
  }
}

/// Live streaming route names
class LiveStreamRouteNames {
  LiveStreamRouteNames._();

  static const String liveStreamsHome = 'live-streams-home';
  static const String liveStreamViewer = 'live-stream-viewer';
  static const String createLiveStream = 'create-live-stream';
  static const String liveStreamSetup = 'live-stream-setup';
  static const String liveStreamHost = 'live-stream-host';
  static const String myLiveStreams = 'my-live-streams';
  static const String liveStreamAnalytics = 'live-stream-analytics';
  static const String giftShop = 'gift-shop';
}

/// Live streaming routes configuration
List<RouteBase> liveStreamingRoutes = [
  // Live stream discovery
  GoRoute(
    path: LiveStreamRoutePaths.liveStreamsHome,
    name: LiveStreamRouteNames.liveStreamsHome,
    builder: (context, state) {
      // Support filtering by type via query params
      final typeParam = state.uri.queryParameters['type'];
      LiveStreamType? filterType;

      if (typeParam == 'gift') {
        filterType = LiveStreamType.gift;
      } else if (typeParam == 'shop') {
        filterType = LiveStreamType.shop;
      }

      return LiveStreamsHomeScreen(filterType: filterType);
    },
    routes: [
      // Live stream viewer (deep linkable - shareable stream links)
      GoRoute(
        path: ':streamId',
        name: LiveStreamRouteNames.liveStreamViewer,
        builder: (context, state) {
          final streamId = state.pathParameters['streamId']!;
          final referrerId = state.uri.queryParameters['ref'];
          final autoJoin = state.uri.queryParameters['autoJoin'] == 'true';

          return LiveStreamViewerScreen(
            streamId: streamId,
            referrerId: referrerId,
            autoJoin: autoJoin,
          );
        },
      ),
    ],
  ),

  // Create live stream
  GoRoute(
    path: LiveStreamRoutePaths.createLiveStream,
    name: LiveStreamRouteNames.createLiveStream,
    builder: (context, state) {
      // Support pre-selecting type via query params
      final typeParam = state.uri.queryParameters['type'];
      LiveStreamType? preselectedType;

      if (typeParam == 'gift') {
        preselectedType = LiveStreamType.gift;
      } else if (typeParam == 'shop') {
        preselectedType = LiveStreamType.shop;
      }

      // Support pre-selecting shop for shop streams
      final shopId = state.uri.queryParameters['shopId'];

      return CreateLiveStreamScreen(
        preselectedType: preselectedType,
        shopId: shopId,
      );
    },
  ),

  // Live stream setup (configure settings before going live)
  GoRoute(
    path: LiveStreamRoutePaths.liveStreamSetup,
    name: LiveStreamRouteNames.liveStreamSetup,
    builder: (context, state) => const LiveStreamSetupScreen(),
  ),

  // Host streaming screen
  GoRoute(
    path: '/live/host/:streamId',
    name: LiveStreamRouteNames.liveStreamHost,
    builder: (context, state) {
      final streamId = state.pathParameters['streamId']!;
      return LiveStreamHostScreen(streamId: streamId);
    },
  ),

  // My live streams
  GoRoute(
    path: LiveStreamRoutePaths.myLiveStreams,
    name: LiveStreamRouteNames.myLiveStreams,
    builder: (context, state) => const MyLiveStreamsScreen(),
  ),

  // Live stream analytics
  GoRoute(
    path: '/my-live-streams/:streamId/analytics',
    name: LiveStreamRouteNames.liveStreamAnalytics,
    builder: (context, state) {
      final streamId = state.pathParameters['streamId']!;
      return LiveStreamAnalyticsScreen(streamId: streamId);
    },
  ),

  // Gift shop
  GoRoute(
    path: LiveStreamRoutePaths.giftShop,
    name: LiveStreamRouteNames.giftShop,
    builder: (context, state) => const GiftShopScreen(),
  ),
];

/// Navigation extensions for live streaming
extension LiveStreamNavigation on BuildContext {
  // Live stream discovery
  void goToLiveStreamsHome({LiveStreamType? filterType}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.liveStreamsHome,
      queryParameters: {
        if (filterType != null) 'type': filterType.name,
      },
    );
    go(uri.toString());
  }

  Future<T?> pushToLiveStreamsHome<T>({LiveStreamType? filterType}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.liveStreamsHome,
      queryParameters: {
        if (filterType != null) 'type': filterType.name,
      },
    );
    return push<T>(uri.toString());
  }

  // View live stream (shareable)
  void goToLiveStreamViewer(String streamId, {String? referrerId, bool autoJoin = false}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.liveStreamViewerPath(streamId),
      queryParameters: {
        if (referrerId != null) 'ref': referrerId,
        if (autoJoin) 'autoJoin': 'true',
      },
    );
    go(uri.toString());
  }

  Future<T?> pushToLiveStreamViewer<T>(String streamId, {String? referrerId, bool autoJoin = false}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.liveStreamViewerPath(streamId),
      queryParameters: {
        if (referrerId != null) 'ref': referrerId,
        if (autoJoin) 'autoJoin': 'true',
      },
    );
    return push<T>(uri.toString());
  }

  // Create live stream
  void goToCreateLiveStream({LiveStreamType? preselectedType, String? shopId}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.createLiveStream,
      queryParameters: {
        if (preselectedType != null) 'type': preselectedType.name,
        if (shopId != null) 'shopId': shopId,
      },
    );
    go(uri.toString());
  }

  Future<T?> pushToCreateLiveStream<T>({LiveStreamType? preselectedType, String? shopId}) {
    final uri = Uri(
      path: LiveStreamRoutePaths.createLiveStream,
      queryParameters: {
        if (preselectedType != null) 'type': preselectedType.name,
        if (shopId != null) 'shopId': shopId,
      },
    );
    return push<T>(uri.toString());
  }

  // Live stream setup
  void goToLiveStreamSetup() => go(LiveStreamRoutePaths.liveStreamSetup);
  Future<T?> pushToLiveStreamSetup<T>() => push<T>(LiveStreamRoutePaths.liveStreamSetup);

  // Host streaming
  void goToLiveStreamHost(String streamId) => go(LiveStreamRoutePaths.liveStreamHostPath(streamId));
  Future<T?> pushToLiveStreamHost<T>(String streamId) => push<T>(LiveStreamRoutePaths.liveStreamHostPath(streamId));

  // My streams
  void goToMyLiveStreams() => go(LiveStreamRoutePaths.myLiveStreams);
  Future<T?> pushToMyLiveStreams<T>() => push<T>(LiveStreamRoutePaths.myLiveStreams);

  void goToLiveStreamAnalytics(String streamId) => go(LiveStreamRoutePaths.liveStreamAnalyticsPath(streamId));
  Future<T?> pushToLiveStreamAnalytics<T>(String streamId) => push<T>(LiveStreamRoutePaths.liveStreamAnalyticsPath(streamId));

  // Gift shop
  void goToGiftShop() => go(LiveStreamRoutePaths.giftShop);
  Future<T?> pushToGiftShop<T>() => push<T>(LiveStreamRoutePaths.giftShop);

  // Helper: Go to create live stream from shop
  void goToCreateShopLiveFromShop(String shopId) {
    goToCreateLiveStream(
      preselectedType: LiveStreamType.shop,
      shopId: shopId,
    );
  }

  // Helper: Share live stream link
  String getShareableLiveStreamLink(String streamId, {String? userId}) {
    return LiveStreamRoutePaths.shareLiveStreamLink(streamId, referrerId: userId);
  }
}
