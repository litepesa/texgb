// lib/core/router/route_guards.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

/// Route guard that handles authentication and authorization
/// 
/// This class manages:
/// - Login redirects (unauthenticated users → login)
/// - Profile completion checks (no profile → create profile)
/// - Post-login redirects (logged in on auth pages → home)
class RouteGuard {
  final Ref ref;
  
  RouteGuard(this.ref);
  
  /// Main redirect logic for go_router
  /// 
  /// Returns:
  /// - null: Allow navigation to requested route
  /// - String: Redirect to this route instead
  String? redirect(BuildContext context, GoRouterState state) {
    final currentPath = state.matchedLocation;
    
    debugPrint('🔒 Route Guard Check:');
    debugPrint('   - Current Path: $currentPath');
    debugPrint('   - Full Location: ${state.uri}');
    
    // Get authentication status
    final isAuthenticated = _isUserAuthenticated();
    final hasProfile = _hasCompleteProfile();
    
    debugPrint('   - Authenticated: $isAuthenticated');
    debugPrint('   - Has Profile: $hasProfile');
    
    // ==================== AUTHENTICATION FLOW ====================
    
    // 1. User is NOT authenticated
    if (!isAuthenticated) {
      debugPrint('   ❌ User not authenticated');
      
      // Allow access to auth routes
      if (RoutePaths.isAuthRoute(currentPath) || currentPath == RoutePaths.root) {
        debugPrint('   ✅ Allowing access to auth route');
        return null;
      }
      
      // Redirect to landing for all other routes
      debugPrint('   ↩️  Redirecting to landing');
      return RoutePaths.landing;
    }
    
    // 2. User IS authenticated but has NO profile
    if (isAuthenticated && !hasProfile) {
      debugPrint('   ⚠️  User authenticated but no profile');
      
      // Allow access to profile creation
      if (currentPath == RoutePaths.createProfile) {
        debugPrint('   ✅ Allowing access to profile creation');
        return null;
      }
      
      // Allow logout routes
      if (currentPath == RoutePaths.landing || currentPath == RoutePaths.login) {
        debugPrint('   ✅ Allowing access to auth routes (logout flow)');
        return null;
      }
      
      // Redirect to profile creation for all other routes
      debugPrint('   ↩️  Redirecting to profile creation');
      return RoutePaths.createProfile;
    }
    
    // 3. User IS authenticated AND has complete profile
    if (isAuthenticated && hasProfile) {
      debugPrint('   ✅ User fully authenticated with profile');

      // Check if user has paid activation fee
      final hasPaid = _hasUserPaid();
      debugPrint('   - Has Paid: $hasPaid');

      // 3a. User authenticated with profile but hasn't paid
      if (!hasPaid) {
        debugPrint('   ⚠️  User has not paid activation fee');

        // Allow access to activation payment screen
        if (currentPath == '/activation-payment') {
          debugPrint('   ✅ Allowing access to activation payment screen');
          return null;
        }

        // Allow access to payment status screen
        if (currentPath.startsWith('/payment-status/')) {
          debugPrint('   ✅ Allowing access to payment status screen');
          return null;
        }

        // Allow logout routes
        if (currentPath == RoutePaths.landing || currentPath == RoutePaths.login) {
          debugPrint('   ✅ Allowing access to auth routes (logout flow)');
          return null;
        }

        // Redirect to activation payment for all other routes
        debugPrint('   ↩️  Redirecting to activation payment');
        return '/activation-payment';
      }

      // 3b. User authenticated, has profile, and has paid
      debugPrint('   ✅ User fully authenticated, has profile, and has paid');

      // Prevent authenticated users from accessing auth screens
      if (RoutePaths.isAuthRoute(currentPath)) {
        debugPrint('   ↩️  Redirecting authenticated user away from auth screens');
        return RoutePaths.home;
      }

      // Prevent paid users from accessing activation payment screen
      if (currentPath == '/activation-payment') {
        debugPrint('   ↩️  Redirecting paid user away from activation payment');
        return RoutePaths.home;
      }

      // Allow access to all other routes
      debugPrint('   ✅ Allowing access to protected route');
      return null;
    }
    
    // Default: allow navigation
    debugPrint('   ✅ Default: allowing navigation');
    return null;
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Check if user is authenticated with Firebase
  bool _isUserAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
  
  /// Check if user has completed their profile
  bool _hasCompleteProfile() {
    try {
      // Get the authentication repository which has user data
      final repository = ref.read(authenticationRepositoryProvider);

      // Check if user exists in backend
      // You can also check shared preferences for cached user data
      final currentUserId = repository.currentUserId;

      if (currentUserId == null) {
        debugPrint('   - No current user ID');
        return false;
      }

      // Try to get user model from repository or state
      // This depends on your authentication provider implementation
      // For now, we'll use a simple check

      // Option 1: Check if repository has user data loaded
      // final hasUserData = repository.currentUser != null;

      // Option 2: Check authentication state for profile completion
      final authState = ref.read(authenticationProvider);

      final hasProfile = authState.maybeWhen(
        data: (state) {
          // Check if the state indicates profile is complete
          // Adjust this based on your AuthenticationState structure

          // If you have a userModel in state, check it
          // If you have a isProfileComplete flag, check that
          // For now, we'll assume if user is authenticated and no error, profile exists

          return state.isSuccessful;
        },
        orElse: () => false,
      );

      debugPrint('   - Profile Complete Check: $hasProfile');

      return hasProfile;
    } catch (e) {
      debugPrint('   ⚠️  Error checking profile: $e');
      // If there's an error, assume profile needs to be created
      return false;
    }
  }

  /// Check if user has paid activation fee
  bool _hasUserPaid() {
    try {
      // Get user from authentication state
      final authState = ref.read(authenticationProvider);

      final hasPaid = authState.maybeWhen(
        data: (state) {
          // Try to get current user from state
          // This will depend on your AuthenticationState structure
          // You might need to adjust this based on how you store the current user

          // If you have a currentUser method or property
          final currentUser = ref.read(currentUserProvider);

          if (currentUser == null) {
            return false;
          }

          return currentUser.hasPaid;
        },
        orElse: () => false,
      );

      debugPrint('   - User Has Paid Check: $hasPaid');

      return hasPaid;
    } catch (e) {
      debugPrint('   ⚠️  Error checking payment status: $e');
      // If there's an error, assume user hasn't paid (safer to redirect to payment)
      return false;
    }
  }
}

// ==================== ROUTE GUARD PROVIDER ====================

/// Provider for the route guard
/// This allows the guard to access Riverpod state
final routeGuardProvider = Provider<RouteGuard>((ref) {
  return RouteGuard(ref);
});

// ==================== REDIRECT STRATEGIES ====================

/// Different redirect strategies for various use cases
class RedirectStrategies {
  RedirectStrategies._();
  
  /// Strategy for guest mode (allow browsing without auth)
  static String? guestModeRedirect(
    BuildContext context,
    GoRouterState state,
    Ref ref,
  ) {
    final currentPath = state.matchedLocation;
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    
    // Allow guest access to main screens
    final guestAllowedRoutes = [
      RoutePaths.home,
      RoutePaths.discover,
      RoutePaths.explore,
      RoutePaths.videosFeed,
      RoutePaths.search,
    ];
    
    // Check if current route allows guest access
    if (guestAllowedRoutes.contains(currentPath)) {
      return null; // Allow access
    }
    
    // For protected routes, check authentication
    if (!isAuthenticated && RoutePaths.requiresAuth(currentPath)) {
      return RoutePaths.landing;
    }
    
    return null;
  }
  
  /// Strategy for strict auth (no guest browsing)
  static String? strictAuthRedirect(
    BuildContext context,
    GoRouterState state,
    Ref ref,
  ) {
    final routeGuard = RouteGuard(ref);
    return routeGuard.redirect(context, state);
  }
  
  /// Strategy for onboarding flow
  static String? onboardingRedirect(
    BuildContext context,
    GoRouterState state,
    Ref ref,
  ) {
    final currentPath = state.matchedLocation;
    
    // Check if onboarding is completed (you can store this in SharedPreferences)
    final onboardingCompleted = true; // TODO: Get from storage
    
    if (!onboardingCompleted && currentPath != '/onboarding') {
      return '/onboarding';
    }
    
    // Otherwise use normal auth redirect
    final routeGuard = RouteGuard(ref);
    return routeGuard.redirect(context, state);
  }
}

// ==================== ROUTE OBSERVERS ====================

/// Observer for tracking navigation events
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('📍 Navigation: didPush');
    debugPrint('   - New Route: ${route.settings.name}');
    debugPrint('   - Previous Route: ${previousRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('📍 Navigation: didPop');
    debugPrint('   - Popped Route: ${route.settings.name}');
    debugPrint('   - Back to: ${previousRoute?.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugPrint('📍 Navigation: didReplace');
    debugPrint('   - Old Route: ${oldRoute?.settings.name}');
    debugPrint('   - New Route: ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('📍 Navigation: didRemove');
    debugPrint('   - Removed Route: ${route.settings.name}');
  }
}

// ==================== UTILITY FUNCTIONS ====================

/// Check if user can access a specific route
bool canAccessRoute(String path, Ref ref) {
  final isAuthenticated = FirebaseAuth.instance.currentUser != null;
  
  // Auth routes can be accessed by anyone
  if (RoutePaths.isAuthRoute(path)) {
    return true;
  }
  
  // Protected routes require authentication
  if (RoutePaths.requiresAuth(path)) {
    return isAuthenticated;
  }
  
  return true;
}

/// Get redirect path for unauthenticated access attempt
String getAuthRedirectPath(String attemptedPath) {
  // Store attempted path for redirect after login
  // You can save this to SharedPreferences or state management
  debugPrint('🔐 Saving redirect path: $attemptedPath');
  
  return RoutePaths.landing;
}

/// Get post-login redirect path
String getPostLoginRedirectPath() {
  // Check if there's a stored redirect path
  // Otherwise go to home
  // TODO: Implement redirect path storage/retrieval
  
  return RoutePaths.home;
}

// ==================== AUTH STATE LISTENER ====================

/// Listen to auth state changes and trigger navigation
/// This can be used in combination with route guards
class AuthStateListener {
  final Ref ref;
  
  AuthStateListener(this.ref);
  
  /// Set up listener for authentication state changes
  void listen(void Function(bool isAuthenticated) onAuthChanged) {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      final isAuthenticated = user != null;
      debugPrint('🔐 Auth state changed: ${isAuthenticated ? "Logged in" : "Logged out"}');
      onAuthChanged(isAuthenticated);
    });
  }
}

// ==================== ERROR HANDLING ====================

/// Handle navigation errors gracefully
class NavigationErrorHandler {
  static String handleError(BuildContext context, GoRouterState state) {
    debugPrint('❌ Navigation Error:');
    debugPrint('   - Path: ${state.uri}');
    debugPrint('   - Error: ${state.error}');
    
    // For production, you might want to log this to analytics
    // FirebaseAnalytics.instance.logEvent(name: 'navigation_error', parameters: {...});
    
    // Redirect to home or show error page
    return RoutePaths.home;
  }
}

// ==================== SIMPLE PROFILE CHECK (ALTERNATIVE) ====================

/// Alternative simpler approach to check if user has profile
/// Use this if the above _hasCompleteProfile is too complex
/// 
/// This checks:
/// 1. Firebase Auth user exists
/// 2. User has displayName or phoneNumber (indicating profile setup)
bool hasUserCompletedProfile() {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) return false;
  
  // Simple check: if user has displayName, profile is complete
  // Adjust this based on your app's requirements
  final hasDisplayName = user.displayName != null && user.displayName!.isNotEmpty;
  
  debugPrint('   - Simple Profile Check:');
  debugPrint('     - Display Name: ${user.displayName}');
  debugPrint('     - Has Profile: $hasDisplayName');
  
  return hasDisplayName;
}