import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/user_information_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/profile/screens/edit_profile_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/settings/screens/privacy_settings_screen.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/shared/theme/system_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/shared/theme/theme_manager.dart';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use consolidated system UI setup
  await AppSystemUI.setupSystemUI();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Simplified MyApp that maintains your theme but handles navigation properly
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeObserver(
      child: const AppRoot(),
    );
  }
}

// Theme observer to handle system theme changes
class ThemeObserver extends ConsumerStatefulWidget {
  final Widget child;
  
  const ThemeObserver({super.key, required this.child});
  
  @override
  ConsumerState<ThemeObserver> createState() => _ThemeObserverState();
}

class _ThemeObserverState extends ConsumerState<ThemeObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangePlatformBrightness() {
    // Handle system theme changes
    final themeNotifier = ref.read(themeManagerNotifierProvider.notifier);
    themeNotifier.handleSystemThemeChange();
    super.didChangePlatformBrightness();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
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
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stackTrace) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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
          Constants.landingScreen: (context) => const LandingScreen(),
          Constants.loginScreen: (context) => const LoginScreen(),
          Constants.otpScreen: (context) => const OtpScreen(),
          Constants.userInformationScreen: (context) => const UserInformationScreen(),
          Constants.homeScreen: (context) => const HomeScreen(),
          Constants.myProfileScreen: (context) => const MyProfileScreen(),
          Constants.editProfileScreen: (context) => const EditProfileScreen(),
          Constants.privacySettingsScreen: (context) => const PrivacySettingsScreen(),
        },
        navigatorObservers: [routeObserver],
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
              ),
              body: const Center(
                child: Text('Route not found'),
              ),
            ),
          );
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
      body: SafeArea(
        child: Center(
          child: _hasError 
            ? _buildErrorScreen(textColor)
            : _buildLoadingScreen(primaryColor, backgroundColor, textColor),
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
    );
  }
  
  Widget _buildLoadingScreen(Color primaryColor, Color backgroundColor, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo or branding
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'TexGB',
            style: TextStyle(
              color: backgroundColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        CircularProgressIndicator(
          color: primaryColor,
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
    );
  }
}