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
import 'package:textgb/features/contacts/providers/contacts_providers.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/features/settings/screens/privacy_settings_screen.dart';
import 'package:textgb/shared/theme/dark_theme.dart';
import 'package:textgb/shared/theme/light_theme.dart';
import 'package:textgb/shared/theme/theme_manager.dart';

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
  
  // Get platform brightness for initial theme
  final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  
  // Set initial system UI style
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // Timer to periodically update system UI
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Make sure to initialize the app after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
      _updateSystemUI();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Update system UI based on current theme
  void _updateSystemUI() {
    if (!mounted) return;
    
    // Get platform brightness for fallback
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    
    // Get theme state with safety check
    final themeState = ref.read(themeManagerNotifierProvider);
    bool isDarkMode = isPlatformDark; // Default to platform
    
    // Use theme state if available
    if (themeState.hasValue && themeState.value != null) {
      isDarkMode = themeState.value!.isDarkMode;
    }
    
    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void didChangePlatformBrightness() {
    // Handle system theme changes
    final themeNotifier = ref.read(themeManagerNotifierProvider.notifier);
    themeNotifier.handleSystemThemeChange();
    _updateSystemUI();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes, but with safety
    final themeStateAsync = ref.watch(themeManagerNotifierProvider);
    
    // Get platform brightness for fallback
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final fallbackTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
    
    // Use fallback theme if not initialized or theme is loading
    if (!_initialized || themeStateAsync.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: fallbackTheme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Handle error case
    if (themeStateAsync.hasError) {
      debugPrint('Theme error: ${themeStateAsync.error}');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: fallbackTheme,
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: ${themeStateAsync.error}'),
          ),
        ),
      );
    }
    
    // Get actual theme with safety check
    final themeState = themeStateAsync.valueOrNull;
    final appTheme = themeState?.activeTheme ?? fallbackTheme;
    
    // Schedule system UI update when theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TexGB',
      theme: appTheme,
      initialRoute: Constants.landingScreen,
      routes: {
        Constants.landingScreen: (context) => const LandingScreen(),
        Constants.loginScreen: (context) => const LoginScreen(),
        Constants.otpScreen: (context) => const OtpScreen(),
        Constants.userInformationScreen: (context) => 
            const UserInformationScreen(),
        Constants.homeScreen: (context) => const HomeScreen(),
        
        // Contact profile routes
        Constants.contactProfileScreen: (context) => const ContactProfileScreen(),
        Constants.myProfileScreen: (context) => const MyProfileScreen(),
        Constants.privacySettingsScreen: (context) => const PrivacySettingsScreen(),
        
        Constants.contactsScreen: (context) => const ContactsScreen(),
        Constants.addContactScreen: (context) => const AddContactScreen(),
        Constants.blockedContactsScreen: (context) => const BlockedContactsScreen(),
        Constants.chatScreen: (context) => const ChatScreen(),
      },
      // Add the route observer
      navigatorObservers: [routeObserver],
    );
  }
}