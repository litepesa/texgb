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
import 'package:textgb/shared/theme/system_ui_updater.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/dark_theme.dart';
import 'package:textgb/shared/theme/light_theme.dart';
import 'dart:async';

// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Force edge-to-edge mode for better control of system bars
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Get the platform brightness to set initial theme
  final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  
  // Initial setup of system UI based on platform brightness
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,  // Set to transparent
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false, // Prevent Android from overriding colors
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
  Timer? _uiUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Schedule periodic updates to ensure the navigation bar stays the correct color
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _forceUpdateSystemUI();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _forceUpdateSystemUI() {
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final themeState = ref.read(themeManagerNotifierProvider);
    
    // Default to platform brightness if theme state is not available yet
    bool isDarkMode = isPlatformDark;
    
    // Only use theme state if it's available
    if (themeState.hasValue) {
      isDarkMode = themeState.value!.isDarkMode;
    }
    
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent, // Set to transparent
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
    _forceUpdateSystemUI();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeState = ref.watch(themeManagerNotifierProvider);
    
    // Force update system UI every time the theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceUpdateSystemUI();
    });
    
    // Get platform brightness for fallback
    final isPlatformDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final fallbackTheme = isPlatformDark ? modernDarkTheme() : modernLightTheme();
    
    // Show loading indicator while theme is initializing
    if (themeState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: fallbackTheme,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Handle error
    if (themeState.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: fallbackTheme,
        home: Scaffold(
          body: Center(
            child: Text('Error loading theme: ${themeState.error}'),
          ),
        ),
      );
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TexGB',
      theme: themeState.hasValue ? themeState.value!.activeTheme : fallbackTheme,
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
      // Wrap the app with SystemUIUpdater to handle navigation bar colors
      builder: (context, child) {
        return SystemUIUpdater(child: child ?? const SizedBox.shrink());
      },
    );
  }
}