import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/user_information_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/channels/screens/channel_detail_screen.dart';
import 'package:textgb/features/channels/screens/create_channel_post_screen.dart';
import 'package:textgb/features/channels/screens/create_channel_screen.dart';
import 'package:textgb/features/channels/screens/explore_channels_screen.dart';
import 'package:textgb/features/channels/screens/my_channels_screen.dart';
import 'package:textgb/features/contacts/screens/contact_profile_screen.dart';
import 'package:textgb/features/contacts/screens/my_profile_screen.dart';

// WeChat Moments-like status imports
import 'package:textgb/features/status/presentation/screens/status_feed_screen.dart';
import 'package:textgb/features/status/presentation/screens/create_status_screen.dart';
import 'package:textgb/features/status/presentation/screens/status_detail_screen.dart';
import 'package:textgb/features/status/presentation/widgets/status_settings_screen.dart';
import 'package:textgb/features/status/core/status_module.dart';

import 'package:textgb/firebase_options.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/features/settings/screens/privacy_settings_screen.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/shared/theme/system_ui_updater.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
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
  
  // Initialize Status module
  StatusModule.initialize();
  
  // Create and initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.initialize();
  
  runApp(
    // Use ProviderScope for Riverpod
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeManager>.value(
            value: themeManager,
          ),
          ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ContactsProvider()),
          ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _uiUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Apply direct system navigation bar fix with a short delay to ensure it's applied after everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceUpdateSystemUI();
    });
    
    // Schedule periodic updates to ensure the navigation bar stays the correct color
    // This helps on certain Android versions that might reset the navigation bar
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
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final isDarkMode = themeManager.isDarkMode;
    
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
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.handleSystemThemeChange();
    _forceUpdateSystemUI();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeManager = Provider.of<ThemeManager>(context);
    
    // Force update system UI every time the theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceUpdateSystemUI();
    });
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TexGB',
      theme: themeManager.activeTheme,
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
        
        // WeChat Moments-like status routes
        Constants.statusFeedScreen: (context) => const StatusFeedScreen(),
        Constants.createStatusScreen: (context) => const CreateStatusScreen(),
        Constants.statusSettingsScreen: (context) => const StatusSettingsScreen(),
        
        // Channel routes
        Constants.createChannelScreen: (context) => const CreateChannelScreen(),
        Constants.exploreChannelsScreen: (context) => const ExploreChannelsScreen(),
        Constants.myChannelsScreen: (context) => const MyChannelsScreen(),
      },
      // Use onGenerateRoute for routes that need parameters
      onGenerateRoute: (settings) {
        // Status routes that need parameters
        if (settings.name == Constants.statusDetailScreen) {
          final String postId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => StatusDetailScreen(postId: postId),
          );
        }
        // Channel routes
        else if (settings.name == Constants.channelDetailScreen) {
          final String channelId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ChannelDetailScreen(channelId: channelId),
          );
        } else if (settings.name == Constants.createChannelPostScreen) {
          final String channelId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => CreateChannelPostScreen(channelId: channelId),
          );
        }
        
        // Use Status module's route generator for any unhandled status routes
        if (settings.name?.startsWith('/status') == true) {
          return StatusModule.generateRoute(settings);
        }
        
        return null;
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