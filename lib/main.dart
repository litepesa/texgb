import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/features/groups/screens/group_information_screen.dart';
import 'package:textgb/features/groups/screens/group_member_requests_screen.dart';
import 'package:textgb/features/groups/screens/group_settings_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/main_screen/profile_screen.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/chat/chat_provider.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/theme/system_ui_updater.dart';
import 'package:textgb/shared/theme/theme_manager.dart';


// Create a route observer to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Create and initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeManager>.value(
          value: themeManager,
        ),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.handleSystemThemeChange();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeManager = Provider.of<ThemeManager>(context);
    
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
        Constants.profileScreen: (context) => const ProfileScreen(),
        Constants.contactsScreen: (context) => const ContactsScreen(),
        Constants.addContactScreen: (context) => const AddContactScreen(),
        Constants.blockedContactsScreen: (context) => const BlockedContactsScreen(),
        Constants.chatScreen: (context) => const ChatScreen(),
        Constants.groupMemberRequestsScreen: (context) =>
            const GroupMemberRequestsScreen(),
        Constants.groupSettingsScreen: (context) =>
            const GroupSettingsScreen(),
        Constants.groupInformationScreen: (context) =>
            const GroupInformationScreen(),
        Constants.statusScreen: (context) => const StatusScreen(),
        Constants.createStatusScreen: (context) => const CreateStatusScreen(),
        Constants.createChannelScreen: (context) => const CreateChannelScreen(),
        Constants.exploreChannelsScreen: (context) => const ExploreChannelsScreen(),
        Constants.myChannelsScreen: (context) => const MyChannelsScreen(),
      },
      // Use onGenerateRoute for routes that need parameters
      onGenerateRoute: (settings) {
        if (settings.name == Constants.channelDetailScreen) {
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