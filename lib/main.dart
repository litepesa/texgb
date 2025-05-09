import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/user_information_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/features/contacts/screens/my_profile_screen.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/features/settings/screens/privacy_settings_screen.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/shared/theme/dark_theme.dart';
import 'package:textgb/shared/theme/light_theme.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/modern_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set edge-to-edge mode and transparent system bars
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Set initial system UI style based on platform brightness
  final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: isPlatformDark ? Brightness.light : Brightness.dark,
      statusBarIconBrightness: isPlatformDark ? Brightness.light : Brightness.dark,
    ),
  );
  
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
    // Get existing dark theme from your theme file
    final appTheme = modernDarkTheme();
    
    return MaterialApp(
      debugShowCheckedModeBanner: true, // Set to true for debugging
      title: 'TexGB',
      theme: appTheme,
      // Start with a safe screen that handles navigation
      home: const SafeStartScreen(),
      // Define all your routes
      routes: {
        Constants.landingScreen: (context) => const LandingScreen(),
        Constants.loginScreen: (context) => const LoginScreen(),
        Constants.otpScreen: (context) => const OtpScreen(),
        Constants.userInformationScreen: (context) => const UserInformationScreen(),
        Constants.homeScreen: (context) => const HomeScreen(),
        
        // Contact profile routes
        Constants.contactProfileScreen: (context) => const ContactProfileScreen(),
        Constants.myProfileScreen: (context) => const MyProfileScreen(),
        Constants.privacySettingsScreen: (context) => const PrivacySettingsScreen(),
        
        Constants.contactsScreen: (context) => const ContactsScreen(),
        Constants.addContactScreen: (context) => const AddContactScreen(),
        Constants.blockedContactsScreen: (context) => const BlockedContactsScreen(),
        Constants.chatScreen: (context) => const ChatScreen(),
        
        // Add video viewer screen explicitly
        '/videoViewerScreen': (context) {
          // Safely extract arguments with null checks and defaults
          final Map<String, dynamic> args = 
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final String videoUrl = args['videoUrl'] as String? ?? '';
          final String? videoTitle = args['videoTitle'] as String?;
          final Color accentColor = args['accentColor'] as Color? ?? const Color(0xFF2196F3);
          
          return VideoViewerScreen(
            videoUrl: videoUrl,
            videoTitle: videoTitle,
            accentColor: accentColor,
          );
        },
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
            'TExGB',
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