import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/authentication/landing_screen.dart';
import 'package:textgb/authentication/login_screen.dart';
import 'package:textgb/authentication/otp_screen.dart';
import 'package:textgb/authentication/user_information_screen.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/my_status_screen.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/status/screens/video_viewer_screen.dart';
import 'package:textgb/firebase_options.dart';
import 'package:textgb/main_screen/add_contact_screen.dart';
import 'package:textgb/main_screen/blocked_contacts_screen.dart';
import 'package:textgb/main_screen/chat_screen.dart';
import 'package:textgb/main_screen/contacts_screen.dart';
import 'package:textgb/main_screen/group_information_screen.dart';
import 'package:textgb/main_screen/group_member_requests_screen.dart';
import 'package:textgb/main_screen/group_settings_screen.dart';
import 'package:textgb/main_screen/home_screen.dart';
import 'package:textgb/main_screen/profile_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/chat_provider.dart';
import 'package:textgb/providers/contacts_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/theme/dark_theme.dart';
import 'package:textgb/theme/light_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => StatusProvider()),
      ],
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.savedThemeMode});

  final AdaptiveThemeMode? savedThemeMode;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: wechatLightTheme(), // Using imported light theme
      dark: wechatDarkTheme(),   // Using imported dark theme
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TexGB',
        theme: theme,
        darkTheme: darkTheme,
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
          //Constants.statusDetailScreen: (context) => const StatusDetailScreen(),
          Constants.myStatusScreen: (context) => const MyStatusScreen(isPrivate: true),
          //Constants.userStatusScreen: (context) => const StatusDetailScreen(),
          Constants.mediaViewScreen: (context) => const ImageViewerScreen(imageUrl: ''),
        },
      ),
    );
  }
}