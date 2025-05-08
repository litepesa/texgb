import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/screens/my_profile_screen.dart';
import 'package:textgb/features/chat/screens/my_chats_screen.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/widgets/modern_bottomnav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int pageIndex = 0;
  
  // Creating separate widget variables with our screens
  final Widget homeScreen = const _PlaceholderScreen(title: "Home");
  final Widget chatScreen = const MyChatsScreen();
  final Widget cartScreen = const _PlaceholderScreen(title: "Cart");
  final Widget profileScreen = const MyProfileScreen();
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize pages list to match our bottom nav bar (now 4 tabs in new order)
    pages = [
      chatScreen,        // Index 0 - Chats
      homeScreen,        // Index 1 - Home
      cartScreen,        // Index 2 - Cart
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
        // user comes back to the app
        // update user status to online
        ref.read(authenticationProvider.notifier).updateUserStatus(
              value: true,
            );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is inactive, paused, detached or hidden
        // update user status to offline
        ref.read(authenticationProvider.notifier).updateUserStatus(
              value: false,
            );
        break;
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    // Use the new theme extensions
    final modernTheme = context.modernTheme;
    final animationTheme = context.animationTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get accent color from ModernThemeExtension
    final accentColor = modernTheme.primaryColor!;
    
    // Get app bar and surface colors
    final appBarColor = modernTheme.appBarColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    // Set scaffold background color based on selected tab
    Color scaffoldBackgroundColor;
    if (pageIndex == 1) {
      // Black background for Home tab
      scaffoldBackgroundColor = Colors.black;
    } else if (pageIndex == 2) {
      // White background for Cart tab
      scaffoldBackgroundColor = Colors.white;
    } else {
      // Default background for other tabs
      scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    }
    
    // Use the surface color for bottom nav regardless of selected tab
    final bottomNavColor = surfaceColor;
    
    // Get text colors
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    // Consistent selected item color
    final selectedItemColor = accentColor;
    
    // Unselected items color
    final unselectedItemColor = textSecondaryColor;
    
    // Set elevation for better delineation
    final elevation = isDarkMode ? 1.0 : 2.0;

    return Scaffold(
      // Only show AppBar in chats tab (index 0)
      appBar: pageIndex == 0 ? AppBar(
        elevation: elevation,
        toolbarHeight: 65.0,
        centerTitle: true,  // Set centerTitle to true
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
                text: 'Snap',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Reel',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Added WiFi button
          IconButton(
            icon: Icon(Icons.wifi, color: textColor),
            onPressed: () {
              // Show a snackbar when WiFi button is pressed
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
      body: Container(
        color: scaffoldBackgroundColor, // Apply consistent background color
        child: IndexedStack(
          index: pageIndex,
          children: pages,
        ),
      ),
      // Custom bottom nav bar that extends into system nav area
      bottomNavigationBar: Container(
        // Use appropriate color based on tab for bottom nav container
        color: pageIndex == 1 ? Colors.black : 
               pageIndex == 2 ? Colors.white : 
               Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top divider for the bottom nav
              Divider(
                height: 1,
                thickness: 0.5,
                color: modernTheme.dividerColor,
              ),
              // Modern navigation bar with 4 tabs in the new order
              ModernBottomNavBar(
                currentIndex: pageIndex,
                onTap: (index) {
                  setState(() {
                    pageIndex = index;
                  });
                },
                // Use surfaceColor for all tabs
                backgroundColor: surfaceColor,
                // Use consistent colors for all tabs
                selectedItemColor: selectedItemColor,
                unselectedItemColor: unselectedItemColor,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chat_bubble_text, size: 24),
                    label: 'Chats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.house, size: 24),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.cart, size: 24),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.person, size: 24),
                    label: 'Profile',
                  ),
                ],
              ),
              // Make the bottom bar transparent
              MediaQuery.of(context).padding.bottom > 0
                ? Container(
                    height: MediaQuery.of(context).padding.bottom,
                    color: Colors.transparent,
                  )
                : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(accentColor),
    );
  }
  
  // Build context-specific floating action button
  Widget? _buildFloatingActionButton(Color accentColor) {
    // Only show FAB for Chats tab
    if (pageIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          // Navigate to Contacts screen
          Navigator.pushNamed(
            context,
            Constants.contactsScreen,
          );
        },
        backgroundColor: accentColor,
        elevation: 4.0, // Increased elevation for better visibility
        child: const Icon(CupertinoIcons.chat_bubble_text, size: 26),
      );
    }
    
    // No FAB for other tabs
    return null;
  }
}

// Simple placeholder screen for tabs under development
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    // Determine text color based on the tab/background
    Color textColor;
    Color iconColor;
    
    if (title == "Home") {
      // For Home tab with black background, use white text
      textColor = Colors.white;
      iconColor = Colors.white;
    } else if (title == "Cart") {
      // For Cart tab with white background, use darker text
      textColor = Colors.black87;
      iconColor = accentColor;
    } else {
      // For other tabs, use theme colors
      textColor = modernTheme.textColor!;
      iconColor = accentColor;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.gear,
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
