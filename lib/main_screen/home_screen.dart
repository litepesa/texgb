import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/profile/screens/profile_screens.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/modern_bottomnav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int pageIndex = 0;
  
  // Creating screen widgets
  late final Widget homeScreen;
  late final Widget chatScreen;
  late final Widget statusScreen;
  late final Widget profileScreen;
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize screens
    chatScreen = _PlaceholderScreen(title: "Chats");
    homeScreen = _PlaceholderScreen(title: "Groups");
    statusScreen = _PlaceholderScreen(title: "Status");
    profileScreen = const MyProfileScreen(); // Using our actual profile screen
    
    // Initialize pages list with 4 tabs
    pages = [
      chatScreen,        // Index 0 - Chats
      homeScreen,        // Index 1 - Groups
      statusScreen,      // Index 2 - Status
      profileScreen,     // Index 3 - Profile
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(authenticationProvider.notifier).updateUserStatus(
              value: true,
            );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        ref.read(authenticationProvider.notifier).updateUserStatus(
              value: false,
            );
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final accentColor = modernTheme.primaryColor!;
    final appBarColor = modernTheme.appBarColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    final selectedItemColor = accentColor;
    final unselectedItemColor = textSecondaryColor;
    final elevation = isDarkMode ? 1.0 : 2.0;
    
    // Background color for "Profile" tab (index 3 now)
    final scaffoldBackgroundColor = pageIndex == 3 
        ? modernTheme.backgroundColor 
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: pageIndex != 3 ? AppBar(
        elevation: elevation,
        toolbarHeight: 65.0,
        centerTitle: true,
        backgroundColor: appBarColor,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            children: [
              TextSpan(
                text: 'Tex',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'GB',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.wifi, color: textColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('WiFi feature is under development'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8), // Reduced bottom padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 0.5,
              color: modernTheme.dividerColor,
            ),
            Container(
              color: pageIndex == 3 ? modernTheme.backgroundColor : null,
              child: ModernBottomNavBar(
                currentIndex: pageIndex,
                onTap: (index) {
                  setState(() {
                    pageIndex = index;
                  });
                },
                backgroundColor: surfaceColor,
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chat_bubble_text, size: 24),
                    label: 'Chats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person_2, size: 24),
                    label: 'Groups',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.rays, size: 24),
                    label: 'Status',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person, size: 24),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(accentColor),
    );
  }
  
  Widget? _buildFloatingActionButton(Color accentColor) {
    if (pageIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This feature is under development'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: accentColor,
        elevation: 4.0,
        child: const Icon(CupertinoIcons.chat_bubble_text, size: 26),
      );
    }
    return null;
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    Color textColor;
    Color iconColor;
    
    if (title == "Groups") {
      textColor = modernTheme.textColor!;
      iconColor = accentColor;
    } else if (title == "Status") {
      textColor = modernTheme.textColor!;
      iconColor = accentColor;
    } else {
      textColor = modernTheme.textColor!;
      iconColor = accentColor;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == "Chats" ? CupertinoIcons.chat_bubble_text : 
            title == "Groups" ? CupertinoIcons.person_2 :
            title == "Status" ? CupertinoIcons.rays : CupertinoIcons.gear,
            size: 80,
            color: iconColor,
          ),
          const SizedBox(height: 20),
          Text(
            '$title Tab',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'This feature is currently under development. Please check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}