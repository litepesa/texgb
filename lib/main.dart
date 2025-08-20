// lib/main.dart (Updated for unauthenticated access)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/screens/create_channel_screen.dart';
import 'package:textgb/features/channels/screens/edit_channel_screen.dart';
import 'package:textgb/features/channels/screens/my_channel_screen.dart';
import 'package:textgb/features/channels/screens/my_post_screen.dart';
import 'package:textgb/features/channels/screens/recommended_posts_screen.dart';
import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/screens/channel_profile_screen.dart';
import 'package:textgb/features/channels/screens/channel_feed_screen.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/system_ui_updater.dart';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initial system UI setup - the SystemUIUpdater will handle ongoing updates
  // Setup edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Apply initial transparent system UI overlays
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Updated MyApp to use SystemUIUpdater
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SystemUIUpdater(
      child: const AppRoot(),
    );
  }
}

// Main app builder with theme support
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme state to rebuild on theme changes
    final themeState = ref.watch(themeManagerNotifierProvider);
    
    return themeState.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo or branding
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '微宝 WeiBao',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: const Color(0xFFFE2C55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Center(
            child: Text('Error loading theme: $error'),
          ),
        ),
      ),
      data: (themeData) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WeiBao',
        theme: themeData.activeTheme,
        // Start directly with HomeScreen - no authentication required
        home: const HomeScreen(),
        // Define all your routes
        routes: {
          // Authentication routes
          Constants.landingScreen: (context) => const LandingScreen(),
          Constants.loginScreen: (context) => const LoginScreen(),
          Constants.otpScreen: (context) => const OtpScreen(),
          
          // Main app routes
          Constants.homeScreen: (context) => const HomeScreen(),
          
          // Channel routes with enhanced navigation support
          Constants.createChannelScreen: (context) => const CreateChannelScreen(),
          Constants.channelsFeedScreen: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return ChannelsFeedScreen(
              startVideoId: args?['startVideoId'] as String?,
              channelId: args?['channelId'] as String?,
            );
          },
          Constants.recommendedPostsScreen: (context) => const RecommendedPostsScreen(),
          Constants.myChannelScreen: (context) => const MyChannelScreen(),
          Constants.createChannelPostScreen: (context) => const CreatePostScreen(),
          Constants.channelFeedScreen: (context) {
            final videoId = ModalRoute.of(context)!.settings.arguments as String;
            return ChannelFeedScreen(videoId: videoId);
          },
          
          Constants.channelProfileScreen: (context) {
            final channelId = ModalRoute.of(context)!.settings.arguments as String;
            return ChannelProfileScreen(channelId: channelId);
          },
          Constants.editChannelScreen: (context) {
            final channel = ModalRoute.of(context)!.settings.arguments as ChannelModel;
            return EditChannelScreen(channel: channel);
          },
          
          // Channels List Screen
          Constants.channelsListScreen: (context) => const ChannelsListScreen(),
          
          Constants.exploreChannelsScreen: (context) => const Scaffold(
              body: Center(
                child: Text('Explore Channels Screen - To be implemented'),
              ),
            ),
          // My Post Screen route
          Constants.myPostScreen: (context) {
            final videoId = ModalRoute.of(context)!.settings.arguments as String;
            return MyPostScreen(videoId: videoId);
          },
          
          // Wallet routes
          Constants.walletScreen: (context) => const WalletScreen(),
        },
        navigatorObservers: [routeObserver],
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              extendBodyBehindAppBar: true,
              extendBody: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Route not found'),
              ),
            ),
          );
        },
        onGenerateRoute: (settings) {
          // Handle dynamic routes that need custom logic
          switch (settings.name) {
            case '/channel-profile':
              // Handle channel profile route
              final channelId = settings.arguments as String?;
              if (channelId != null) {
                return MaterialPageRoute(
                  builder: (context) => ChannelProfileScreen(channelId: channelId),
                  settings: settings,
                );
              }
              break;
          }
          
          // Return null to let the default route handling take over
          return null;
        },
      ),
    );
  }
}

// Helper class for navigation utilities
class ChannelNavigationHelper {
  // Navigate to channel profile
  static void navigateToChannelProfile(
    BuildContext context, {
    required String channelId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.channelProfileScreen,
      arguments: channelId,
    );
  }

  // Navigate to channel feed
  static void navigateToChannelFeed(
    BuildContext context, {
    String? startVideoId,
    String? channelId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.channelsFeedScreen,
      arguments: {
        'startVideoId': startVideoId,
        'channelId': channelId,
      },
    );
  }

  // Navigate to create post (requires authentication)
  static void navigateToCreatePost(BuildContext context) {
    Navigator.pushNamed(context, Constants.createChannelPostScreen);
  }

  // Navigate to my channel (requires authentication)
  static void navigateToMyChannel(BuildContext context) {
    Navigator.pushNamed(context, Constants.myChannelScreen);
  }

  // Navigate to edit channel (requires authentication)
  static void navigateToEditChannel(
    BuildContext context, {
    required ChannelModel channel,
  }) {
    Navigator.pushNamed(
      context,
      Constants.editChannelScreen,
      arguments: channel,
    );
  }

  // Helper method to check if user needs to authenticate for an action
  static bool requiresAuthentication(BuildContext context) {
    // You can add your authentication check logic here
    // For now, we'll assume Firebase Auth
    return FirebaseAuth.instance.currentUser == null;
  }

  // Navigate to authentication if required
  static void navigateToAuthIfRequired(BuildContext context, VoidCallback onAuthenticated) {
    if (requiresAuthentication(context)) {
      Navigator.pushNamed(context, Constants.landingScreen).then((_) {
        // Check if user is now authenticated
        if (!requiresAuthentication(context)) {
          onAuthenticated();
        }
      });
    } else {
      onAuthenticated();
    }
  }
}