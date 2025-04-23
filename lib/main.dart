import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/authentication/screens/landing_screen.dart';
import 'package:textgb/features/authentication/screens/login_screen.dart';
import 'package:textgb/features/authentication/screens/otp_screen.dart';
import 'package:textgb/features/authentication/screens/user_information_screen.dart';
import 'package:textgb/constants.dart';
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
import 'package:textgb/shared/theme/dark_theme.dart';
import 'package:textgb/shared/theme/light_theme.dart';

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
        },
      ),
    );
  }
}