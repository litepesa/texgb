// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/core/router/route_guards.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

// Import all your screens
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/profile_setup_screen.dart';

import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/main_screen/discover_screen.dart';

import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/users/screens/edit_profile_screen.dart';
import 'package:textgb/features/users/screens/user_profile_screen.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/users/screens/live_users_screen.dart';
import 'package:textgb/features/users/models/user_model.dart';

import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/features/videos/screens/single_video_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/videos/screens/my_post_screen.dart';
import 'package:textgb/features/videos/screens/recommended_posts_screen.dart';
import 'package:textgb/features/videos/screens/manage_posts_screen.dart';
import 'package:textgb/features/videos/screens/featured_videos_screen.dart';

import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';

import 'package:textgb/features/wallet/screens/wallet_screen_v2.dart';

// Payment screens
import 'package:textgb/features/payment/screens/wallet_topup_screen.dart';
import 'package:textgb/features/payment/screens/payment_status_screen.dart';

// Channels screens
import 'package:textgb/features/channels/screens/channels_home_screen.dart';
import 'package:textgb/features/channels/screens/channel_detail_screen.dart';
import 'package:textgb/features/channels/screens/post_detail_screen.dart';
import 'package:textgb/features/channels/screens/create_channel_screen.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';
import 'package:textgb/features/channels/screens/channel_settings_screen.dart';
import 'package:textgb/features/channels/screens/members_management_screen.dart';

// Chat screens
import 'package:textgb/features/chat/screens/chat_list_screen.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';

// Call screens
import 'package:textgb/features/calls/screens/incoming_call_screen.dart';
import 'package:textgb/features/calls/screens/outgoing_call_screen.dart';
import 'package:textgb/features/calls/screens/active_call_screen.dart';


// Moments screens
import 'package:textgb/features/moments/screens/moments_feed_screen.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/user_moments_screen.dart';
import 'package:textgb/features/moments/widgets/media_viewer_screen.dart';
import 'package:textgb/features/moments/widgets/video_viewer_screen.dart';
import 'package:textgb/features/moments/models/moment_model.dart';

/// Provider for the GoRouter instance
/// This is the main router for the entire app
final appRouterProvider = Provider<GoRouter>((ref) {
  final routeGuard = ref.watch(routeGuardProvider);
  
  return GoRouter(
    // Initial location when app starts
    initialLocation: RoutePaths.home,

    // Enable debug logging (disable in production)
    debugLogDiagnostics: false,
    
    // Route guard - handles authentication redirects
    redirect: (context, state) => routeGuard.redirect(context, state),
    
    // Refresh router when authentication state changes
    refreshListenable: GoRouterRefreshStream(ref),
    
    // Error handling
    errorBuilder: (context, state) => NavigationErrorHandler.handleError(context, state) as Widget,
    
    // Navigation observers for analytics/debugging
    observers: [
      AppRouteObserver(),
    ],
    
    // ==================== ROUTE DEFINITIONS ====================
    routes: [
      // ==================== AUTH ROUTES ====================
      
      GoRoute(
        path: RoutePaths.root,
        name: RouteNames.root,
        builder: (context, state) => const HomeScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.landing,
        name: RouteNames.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.otp,
        name: RouteNames.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.createProfile,
        name: RouteNames.createProfile,
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ==================== MAIN APP ROUTES ====================
      
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.discover,
        name: RouteNames.discover,
        builder: (context, state) => const DiscoverScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.explore,
        name: RouteNames.explore,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Explore Screen - To be implemented'),
          ),
        ),
      ),
      
      // ==================== USER PROFILE ROUTES ====================
      
      GoRoute(
        path: RoutePaths.myProfile,
        name: RouteNames.myProfile,
        builder: (context, state) => const MyProfileScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.editProfile,
        name: RouteNames.editProfile,
        builder: (context, state) {
          final user = state.extra as UserModel?;
          if (user == null) {
            // Redirect to profile if no user data
            return const MyProfileScreen();
          }
          return EditProfileScreen(user: user);
        },
      ),
      
      GoRoute(
        path: RoutePaths.userProfilePattern,
        name: RouteNames.userProfile,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserProfileScreen(userId: userId);
        },
      ),
      
      GoRoute(
        path: RoutePaths.usersList,
        name: RouteNames.usersList,
        builder: (context, state) => const UsersListScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.liveUsers,
        name: RouteNames.liveUsers,
        builder: (context, state) => const LiveUsersScreen(),
      ),
      
      // ==================== VIDEO ROUTES ====================
      
      GoRoute(
        path: RoutePaths.videosFeed,
        name: RouteNames.videosFeed,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VideosFeedScreen(
            startVideoId: extra?['startVideoId'] as String?,
            userId: extra?['userId'] as String?,
          );
        },
      ),
      
      GoRoute(
        path: RoutePaths.singleVideoPattern,
        name: RouteNames.singleVideo,
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return SingleVideoScreen(
            videoId: videoId,
            userId: extra?['userId'] as String?,
          );
        },
      ),
      
      GoRoute(
        path: RoutePaths.createPost,
        name: RouteNames.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.myPostPattern,
        name: RouteNames.myPost,
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          return MyPostScreen(videoId: videoId);
        },
      ),
      
      GoRoute(
        path: RoutePaths.postDetailPattern,
        name: RouteNames.postDetail,
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          return MyPostScreen(videoId: videoId);
        },
      ),
      
      GoRoute(
        path: RoutePaths.recommendedPosts,
        name: RouteNames.recommendedPosts,
        builder: (context, state) => const RecommendedPostsScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.managePosts,
        name: RouteNames.managePosts,
        builder: (context, state) => const ManagePostsScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.featuredVideos,
        name: RouteNames.featuredVideos,
        builder: (context, state) => const FeaturedVideosScreen(),
      ),
      
      // ==================== CONTACTS ROUTES ====================
      
      GoRoute(
        path: RoutePaths.contacts,
        name: RouteNames.contacts,
        builder: (context, state) => const ContactsScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.addContact,
        name: RouteNames.addContact,
        builder: (context, state) => const AddContactScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.blockedContacts,
        name: RouteNames.blockedContacts,
        builder: (context, state) => const BlockedContactsScreen(),
      ),
      
      GoRoute(
        path: RoutePaths.contactProfilePattern,
        name: RouteNames.contactProfile,
        builder: (context, state) {
          final user = state.extra as UserModel?;
          if (user == null) {
            // Redirect to contacts if no user data
            return const ContactsScreen();
          }
          return ContactProfileScreen(contact: user);
        },
      ),

      // ==================== MOMENTS ROUTES ====================

      GoRoute(
        path: RoutePaths.momentsFeed,
        name: RouteNames.momentsFeed,
        builder: (context, state) => const MomentsFeedScreen(),
      ),

      GoRoute(
        path: RoutePaths.createMoment,
        name: RouteNames.createMoment,
        builder: (context, state) => const CreateMomentScreen(),
      ),

      GoRoute(
        path: RoutePaths.userMomentsPattern,
        name: RouteNames.userMoments,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return UserMomentsScreen(
            userId: userId,
            userName: extra?['userName'] ?? '',
            userAvatar: extra?['userAvatar'] ?? '',
          );
        },
      ),

      GoRoute(
        path: RoutePaths.momentMediaViewerPattern,
        name: RouteNames.momentMediaViewer,
        builder: (context, state) {
          final indexStr = state.pathParameters['index']!;
          final index = int.tryParse(indexStr) ?? 0;
          final extra = state.extra as Map<String, dynamic>?;
          final imageUrls = extra?['imageUrls'] as List<String>? ?? [];
          return MediaViewerScreen(
            imageUrls: imageUrls,
            initialIndex: index,
          );
        },
      ),

      GoRoute(
        path: RoutePaths.momentVideoViewerPattern,
        name: RouteNames.momentVideoViewer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final videoUrl = extra?['videoUrl'] as String? ?? '';
          final moment = extra?['moment'] as MomentModel?;
          return VideoViewerScreen(
            videoUrl: videoUrl,
            moment: moment!,
          );
        },
      ),

      // ==================== CHAT ROUTES ====================

      GoRoute(
        path: RoutePaths.chats,
        name: RouteNames.chats,
        builder: (context, state) => const ChatListScreen(),
      ),

      GoRoute(
        path: RoutePaths.chatPattern,
        name: RouteNames.chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final contact = extra?['contact'] as UserModel?;

          // Require contact to be passed via extra
          if (contact == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Contact information is required'),
              ),
            );
          }

          return ChatScreen(
            chatId: chatId,
            contact: contact,
          );
        },
      ),

      // ==================== CALL ROUTES ====================

      GoRoute(
        path: RoutePaths.incomingCall,
        name: RouteNames.incomingCall,
        builder: (context, state) {
          // IncomingCallScreen reads state from callProvider
          return const IncomingCallScreen();
        },
      ),

      GoRoute(
        path: RoutePaths.outgoingCall,
        name: RouteNames.outgoingCall,
        builder: (context, state) {
          // OutgoingCallScreen reads state from callProvider
          return const OutgoingCallScreen();
        },
      ),

      GoRoute(
        path: RoutePaths.activeCall,
        name: RouteNames.activeCall,
        builder: (context, state) {
          // ActiveCallScreen reads state from callProvider
          return const ActiveCallScreen();
        },
      ),

      // ==================== WALLET ROUTES ====================

      GoRoute(
        path: RoutePaths.wallet,
        name: RouteNames.wallet,
        builder: (context, state) => const WalletScreenV2(),
      ),

      // ==================== PAYMENT ROUTES ====================

      GoRoute(
        path: '/wallet-topup',
        name: 'walletTopup',
        builder: (context, state) => const WalletTopUpScreen(),
      ),

      GoRoute(
        path: '/payment-status/:checkoutRequestId',
        name: 'paymentStatus',
        builder: (context, state) {
          final checkoutRequestId = state.pathParameters['checkoutRequestId']!;
          final isActivation = state.uri.queryParameters['isActivation'] == 'true';
          return PaymentStatusScreen(
            checkoutRequestId: checkoutRequestId,
            isActivation: isActivation,
          );
        },
      ),

      // ==================== CHANNELS ROUTES ====================

      GoRoute(
        path: RoutePaths.channelsHome,
        name: RouteNames.channelsHome,
        builder: (context, state) => const ChannelsHomeScreen(),
      ),

      GoRoute(
        path: RoutePaths.channelDetailPattern,
        name: RouteNames.channelDetail,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return ChannelDetailScreen(channelId: channelId);
        },
      ),

      GoRoute(
        path: RoutePaths.channelPostPattern,
        name: RouteNames.channelPost,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final channelId = extra?['channelId'] as String? ?? '';
          return PostDetailScreen(
            postId: postId,
            channelId: channelId,
          );
        },
      ),

      GoRoute(
        path: RoutePaths.createChannel,
        name: RouteNames.createChannel,
        builder: (context, state) => const CreateChannelScreen(),
      ),

      GoRoute(
        path: RoutePaths.createChannelPostPattern,
        name: RouteNames.createChannelPost,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return CreateChannelPostScreen(channelId: channelId);
        },
      ),

      GoRoute(
        path: '/channel/:channelId/settings',
        name: 'channelSettings',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return ChannelSettingsScreen(channelId: channelId);
        },
      ),

      GoRoute(
        path: '/channel/:channelId/members',
        name: 'channelMembers',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return MembersManagementScreen(channelId: channelId);
        },
      ),

      // ==================== SEARCH ROUTES ====================
      // Add these when you implement search screens
      
      // GoRoute(
      //   path: RoutePaths.search,
      //   name: RouteNames.search,
      //   builder: (context, state) => const SearchScreen(),
      // ),
    ],
  );
});

/// Helper class to refresh router when auth state changes
/// This makes the router reactive to Riverpod state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    // Listen to authentication state changes
    ref.listen(
      authenticationProvider,
      (_, __) {
        // Notify router to re-evaluate routes when auth state changes
        notifyListeners();
      },
    );
  }

  final Ref ref;

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}

// ==================== NAVIGATION EXTENSIONS ====================

/// Extension on BuildContext for easier navigation
/// 
/// Usage:
/// - context.goToHome()
/// - context.goToUserProfile(userId)
/// - context.goToVideo(videoId)
extension AppNavigationExtension on BuildContext {
  // ==================== AUTH NAVIGATION ====================
  
  void goToLanding() => go(RoutePaths.landing);
  void goToLogin() => go(RoutePaths.login);
  void goToOtp({Map<String, dynamic>? extra}) => go(RoutePaths.otp, extra: extra);
  void goToCreateProfile() => go(RoutePaths.createProfile);
  
  // ==================== MAIN APP NAVIGATION ====================
  
  void goToHome() => go(RoutePaths.home);
  void goToDiscover() => go(RoutePaths.discover);
  void goToExplore() => go(RoutePaths.explore);
  
  // ==================== USER PROFILE NAVIGATION ====================
  
  void goToMyProfile() => go(RoutePaths.myProfile);
  void goToEditProfile(UserModel user) => go(RoutePaths.editProfile, extra: user);
  void goToUserProfile(String userId) => go(RoutePaths.userProfile(userId));
  void goToUsersList() => go(RoutePaths.usersList);
  void goToLiveUsers() => go(RoutePaths.liveUsers);
  
  // ==================== VIDEO NAVIGATION ====================
  
  void goToVideosFeed({String? startVideoId, String? userId}) {
    go(RoutePaths.videosFeed, extra: {
      'startVideoId': startVideoId,
      'userId': userId,
    });
  }
  
  void goToVideo(String videoId, {String? userId}) {
    go(RoutePaths.singleVideo(videoId), extra: {'userId': userId});
  }
  
  void goToCreatePost() => go(RoutePaths.createPost);
  void goToMyPost(String videoId) => go(RoutePaths.myPost(videoId));
  void goToPostDetail(String videoId) => go(RoutePaths.postDetail(videoId));
  void goToRecommendedPosts() => go(RoutePaths.recommendedPosts);
  void goToManagePosts() => go(RoutePaths.managePosts);
  void goToFeaturedVideos() => go(RoutePaths.featuredVideos);
  
  // ==================== CONTACTS NAVIGATION ====================
  
  void goToContacts() => go(RoutePaths.contacts);
  void goToAddContact() => go(RoutePaths.addContact);
  void goToBlockedContacts() => go(RoutePaths.blockedContacts);
  void goToContactProfile(UserModel user) => go(
    RoutePaths.contactProfile(user.uid),
    extra: user,
  );
  
  // ==================== WALLET NAVIGATION ====================

  void goToWallet() => go(RoutePaths.wallet);

  // ==================== CHANNELS NAVIGATION ====================

  void goToChannels() => go(RoutePaths.channelsHome);
  void goToChannelsHome() => go(RoutePaths.channelsHome);
  void goToChannelsFeed() => go(RoutePaths.channelsFeed);
  void goToDiscoverChannels() => go(RoutePaths.discoverChannels);
  void goToCreateChannel() => go(RoutePaths.createChannel);
  void goToEditChannel({String? channelId}) => go(RoutePaths.editChannel, extra: channelId);
  void goToMyChannel() => go(RoutePaths.myChannel);
  void goToChannelDetail(String channelId) => go(RoutePaths.channelDetail(channelId));
  void goToChannelProfile(String channelId) => go(RoutePaths.channelProfile(channelId));
  void goToChannelPost(String postId, String channelId) => go(
    RoutePaths.channelPost(postId),
    extra: {'channelId': channelId},
  );
  void goToChannelVideo(String videoId) => go(RoutePaths.channelVideo(videoId));

  // ==================== MOMENTS NAVIGATION ====================

  void goToMomentsFeed() => go(RoutePaths.momentsFeed);
  void goToCreateMoment() => go(RoutePaths.createMoment);
  void goToUserMoments(String userId, {String? userName, String? userAvatar}) {
    go(
      RoutePaths.userMoments(userId),
      extra: {
        'userName': userName,
        'userAvatar': userAvatar,
      },
    );
  }
  void goToMomentDetail(String momentId) => go(RoutePaths.momentDetail(momentId));
  void goToMomentMediaViewer(String momentId, int index, List<String> imageUrls) {
    go(
      RoutePaths.momentMediaViewer(momentId, index),
      extra: {'imageUrls': imageUrls},
    );
  }
  void goToMomentVideoViewer(String momentId, String videoUrl, dynamic moment) {
    go(
      RoutePaths.momentVideoViewer(momentId),
      extra: {'videoUrl': videoUrl, 'moment': moment},
    );
  }

  // ==================== PUSH VARIANTS (for modal navigation) ====================

  void pushToUserProfile(String userId) => push(RoutePaths.userProfile(userId));
  void pushToVideo(String videoId, {String? userId}) {
    push(RoutePaths.singleVideo(videoId), extra: {'userId': userId});
  }
  void pushToEditProfile(UserModel user) => push(RoutePaths.editProfile, extra: user);
  void pushToWallet() => push(RoutePaths.wallet);
  void pushToManagePosts() => push(RoutePaths.managePosts);
  void pushToMyPost(String videoId) => push(RoutePaths.myPost(videoId));
}

// ==================== ROUTER HELPERS ====================

/// Helper class for common navigation patterns
class AppNavigation {
  AppNavigation._();
  
  /// Navigate and clear all previous routes (e.g., after login)
  static void goAndClearStack(BuildContext context, String path) {
    while (context.canPop()) {
      context.pop();
    }
    context.go(path);
  }
  
  /// Navigate to home and clear stack
  static void goToHomeAndClearStack(BuildContext context) {
    goAndClearStack(context, RoutePaths.home);
  }
  
  /// Navigate to landing and clear stack (logout)
  static void goToLandingAndClearStack(BuildContext context) {
    goAndClearStack(context, RoutePaths.landing);
  }
  
  /// Check if user can pop (has previous route)
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }
  
  /// Safe pop with fallback to home
  static void popOrGoHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }
}

// ==================== DEBUG HELPERS ====================

/// Debug helper to print current route information
void debugCurrentRoute(BuildContext context) {
  final router = GoRouter.of(context);
  debugPrint('📍 Current Route Information:');
  debugPrint('   - Location: ${router.routerDelegate.currentConfiguration.uri}');
  debugPrint('   - Can Pop: ${context.canPop()}');
}