// lib/main.dart (Updated with Video Caching)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/screens/profile_setup_screen.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/features/users/screens/edit_profile_screen.dart';
import 'package:textgb/features/users/screens/live_users_screen.dart';
import 'package:textgb/features/videos/screens/featured_videos_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/users/screens/user_profile_screen.dart';
import 'package:textgb/features/videos/screens/manage_posts_screen.dart';
import 'package:textgb/features/videos/screens/recommended_posts_screen.dart';
import 'package:textgb/features/videos/screens/single_video_screen.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/videos/screens/my_post_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/main_screen/discover_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/system_ui_updater.dart';
// NEW: Import video cache service
import 'package:textgb/features/videos/services/video_cache_service.dart';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // NEW: Initialize video caching service
  // This MUST be called before runApp() for caching to work
  await VideoCacheService().initialize(
    maxMemoryCacheMB: 600,        // 100MB memory cache
    maxStorageCacheMB: 2048,      // 1GB storage cache
    segmentSizeMB: 50,             // 2MB per segment
    maxConcurrentDownloads: 2,    // 8 concurrent downloads
    enableLogging: true,          // Enable for debugging (set false in production)
  );
  
  // Initial system UI setup - the SystemUIUpdater will handle ongoing updates
  // Setup edge-to-edge display
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Apply initial transparent system UI overlays
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
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
                      'SpaceDuka',
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
        title: 'SpaceDuka',
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
          Constants.discoverScreen: (context) => const DiscoverScreen(),

          Constants.contactsScreen: (context) => const ContactsScreen(),
          Constants.addContactScreen: (context) => const AddContactScreen(),
          Constants.blockedContactsScreen: (context) => const BlockedContactsScreen(),
          Constants.contactProfileScreen: (context) {
            final args = ModalRoute.of(context)!.settings.arguments as UserModel;
            return ContactProfileScreen(contact: args);
          },

          
          // User/Profile routes with enhanced navigation support
          Constants.createProfileScreen: (context) => const ProfileSetupScreen(),
          Constants.videosFeedScreen: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return VideosFeedScreen(
              startVideoId: args?[Constants.startVideoId] as String?,
              userId: args?[Constants.userId] as String?,
            );
          },
          Constants.myProfileScreen: (context) => const MyProfileScreen(),
          Constants.createPostScreen: (context) => const CreatePostScreen(),
          Constants.recommendedPostsScreen: (context) => const RecommendedPostsScreen(),
          Constants.managePostsScreen: (context) => const ManagePostsScreen(),
          
          // NEW: Featured Videos Screen Route
          Constants.featuredVideosScreen: (context) => const FeaturedVideosScreen(),
          Constants.liveUsersScreen: (context) => const LiveUsersScreen(),
          
          Constants.singleVideoScreen: (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is String) {
              // Single video ID argument
              return SingleVideoScreen(videoId: args);
            } else if (args is Map<String, dynamic>) {
              // Map with startVideoId and optional userId
              return SingleVideoScreen(
                videoId: args[Constants.startVideoId] as String,
                userId: args[Constants.userId] as String?,
              );
            }
            throw ArgumentError('Invalid arguments for SingleVideoScreen');
          },
          
          // Add the missing post detail/my post routes
          Constants.postDetailScreen: (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            final videoId = args[Constants.videoId] as String;
            return MyPostScreen(videoId: videoId);
          },
          
          Constants.myPostScreen: (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is String) {
              // Direct video ID
              return MyPostScreen(videoId: args);
            } else if (args is Map<String, dynamic>) {
              // Map with video ID
              final videoId = args[Constants.videoId] as String;
              return MyPostScreen(videoId: videoId);
            }
            throw ArgumentError('Invalid arguments for MyPostScreen');
          },
          
          Constants.userProfileScreen: (context) {
            final userId = ModalRoute.of(context)!.settings.arguments as String;
            return UserProfileScreen(userId: userId);
          },
          Constants.editProfileScreen: (context) {
            final user = ModalRoute.of(context)!.settings.arguments as UserModel;
            return EditProfileScreen(user: user);
          },
          
          // Users List Screen
          Constants.usersListScreen: (context) => const UsersListScreen(),
          
          Constants.exploreScreen: (context) => const Scaffold(
              body: Center(
                child: Text('Explore Screen - To be implemented'),
              ),
            ),
          
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
              
            case '/user-profile':
              // Handle user profile route
              final userId = settings.arguments as String?;
              if (userId != null) {
                return MaterialPageRoute(
                  builder: (context) => UserProfileScreen(userId: userId),
                  settings: settings,
                );
              }
              break;
            case '/video-feed':
              // Handle video feed route with flexible arguments
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => VideosFeedScreen(
                  startVideoId: args?[Constants.startVideoId] as String?,
                  userId: args?[Constants.userId] as String?,
                ),
                settings: settings,
              );
            case '/my-post':
              // Handle my post route dynamically
              final args = settings.arguments;
              if (args is String) {
                return MaterialPageRoute(
                  builder: (context) => MyPostScreen(videoId: args),
                  settings: settings,
                );
              } else if (args is Map<String, dynamic>) {
                final videoId = args[Constants.videoId] as String?;
                if (videoId != null) {
                  return MaterialPageRoute(
                    builder: (context) => MyPostScreen(videoId: videoId),
                    settings: settings,
                  );
                }
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

// Helper class for navigation utilities (updated with Featured Videos)
class UserNavigationHelper {
  // Navigate to user profile
  static void navigateToUserProfile(
    BuildContext context, {
    required String userId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.userProfileScreen,
      arguments: userId,
    );
  }

  // Navigate to videos feed
  static void navigateToVideosFeed(
    BuildContext context, {
    String? startVideoId,
    String? userId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.videosFeedScreen,
      arguments: {
        Constants.startVideoId: startVideoId,
        Constants.userId: userId,
      },
    );
  }

  // Navigate to live users screen
  static void navigateToLiveUsers(
    BuildContext context) {
    Navigator.pushNamed(
      context,
      Constants.liveUsersScreen);
  }

  // Navigate to single video
  static void navigateToSingleVideo(
    BuildContext context, {
    required String videoId,
    String? userId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.singleVideoScreen,
      arguments: {
        Constants.startVideoId: videoId,
        Constants.userId: userId,
      },
    );
  }

  // Navigate to create post (requires authentication)
  static void navigateToCreatePost(BuildContext context) {
    Navigator.pushNamed(context, Constants.createPostScreen);
  }

  // Navigate to my profile (requires authentication)
  static void navigateToMyProfile(BuildContext context) {
    Navigator.pushNamed(context, Constants.myProfileScreen);
  }

  // Navigate to edit profile (requires authentication)
  static void navigateToEditProfile(
    BuildContext context, {
    required UserModel user,
  }) {
    Navigator.pushNamed(
      context,
      Constants.editProfileScreen,
      arguments: user,
    );
  }

  // Navigate to users list
  static void navigateToUsersList(BuildContext context) {
    Navigator.pushNamed(context, Constants.usersListScreen);
  }

  // Navigate to post detail - UPDATED
  static void navigateToPostDetail(
    BuildContext context, {
    required String videoId,
    dynamic videoModel,
  }) {
    Navigator.pushNamed(
      context,
      Constants.postDetailScreen,
      arguments: {
        Constants.videoId: videoId,
        Constants.videoModel: videoModel,
      },
    );
  }

  // Navigate to my post - NEW METHOD
  static void navigateToMyPost(
    BuildContext context, {
    required String videoId,
  }) {
    Navigator.pushNamed(
      context,
      Constants.myPostScreen,
      arguments: videoId,
    );
  }

  // Navigate to explore screen
  static void navigateToExplore(BuildContext context) {
    Navigator.pushNamed(context, Constants.exploreScreen);
  }

  // Navigate to recommended posts
  static void navigateToRecommendedPosts(BuildContext context) {
    Navigator.pushNamed(context, Constants.recommendedPostsScreen);
  }

  // NEW: Navigate to featured videos
  static void navigateToFeaturedVideos(BuildContext context) {
    Navigator.pushNamed(context, Constants.featuredVideosScreen);
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

  // Navigate to wallet
  static void navigateToWallet(BuildContext context) {
    Navigator.pushNamed(context, Constants.walletScreen);
  }

  // Navigate to profile setup
  static void navigateToProfileSetup(BuildContext context) {
    Navigator.pushNamed(context, Constants.createProfileScreen);
  }

  // Navigate back with result
  static void navigateBack(BuildContext context, [dynamic result]) {
    Navigator.of(context).pop(result);
  }

  // Replace current route
  static void navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  // Clear stack and navigate to route
  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}