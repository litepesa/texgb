//main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

// Authentication screens
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/user_information_screen.dart';

// Profile screens
import 'package:textgb/features/profile/screens/edit_profile_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';

// Wallet screens
import 'package:textgb/features/wallet/screens/wallet_screen.dart';


// Models

import 'package:textgb/models/user_model.dart';

// Constants and utilities
import 'package:textgb/constants.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/system_ui_updater.dart';

// Enums
import 'package:textgb/enums/enums.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';

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
        home: const Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: Center(
            child: CircularProgressIndicator(),
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
        // Start with a safe screen that handles navigation
        home: const SafeStartScreen(),
        // Define all your routes
        routes: {
          // Authentication routes
          Constants.landingScreen: (context) => const LandingScreen(),
          Constants.loginScreen: (context) => const LoginScreen(),
          Constants.otpScreen: (context) => const OtpScreen(),
          Constants.userInformationScreen: (context) => const UserInformationScreen(),
          
          // Main app routes
          Constants.homeScreen: (context) => const HomeScreen(),
          
          
          // Profile routes
          Constants.myProfileScreen: (context) => const MyProfileScreen(),
          Constants.editProfileScreen: (context) => const EditProfileScreen(),
          
          
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
 
          }
          
          // Return null to let the default route handling take over
          return null;
        },
      ),
    );
  }
}

// A safe starting screen that handles navigation properly
class SafeStartScreen extends StatefulWidget {
  const SafeStartScreen({super.key});

  @override
  State<SafeStartScreen> createState() => _SafeStartScreenState();
}

class _SafeStartScreenState extends State<SafeStartScreen> {
  bool _hasError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    // Schedule navigation after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToStartScreen();
    });
  }
  
  Future<void> _navigateToStartScreen() async {
    try {
      // Add a small delay to ensure the widget tree is fully built
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Try to show the HomeScreen directly
      // If there are authentication issues, fallback to LandingScreen
      try {
        // Check if user is already signed in
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null) {
          // User is signed in, navigate to HomeScreen
          if (mounted) {
            Navigator.pushReplacementNamed(context, Constants.homeScreen);
          }
        } else {
          // User is not signed in, navigate to LandingScreen
          if (mounted) {
            Navigator.pushReplacementNamed(context, Constants.landingScreen);
          }
        }
      } catch (e) {
        // If there's an authentication error, go to LandingScreen
        if (mounted) {
          Navigator.pushReplacementNamed(context, Constants.landingScreen);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error initializing app: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme's colors for safe display
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    
    return Scaffold(
      // Important for edge-to-edge UI
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: backgroundColor,
      body: _hasError 
        ? _buildErrorScreen(textColor)
        : _buildLoadingScreen(primaryColor, backgroundColor, textColor),
    );
  }
  
  Widget _buildErrorScreen(Color textColor) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom, 
        left: 24.0, 
        right: 24.0
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _navigateToStartScreen();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingScreen(Color primaryColor, Color backgroundColor, Color textColor) {
    return Padding(
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
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
