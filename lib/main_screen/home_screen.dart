import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/status/widgets/custom_icon.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/main_screen/create_group_screen.dart';
import 'package:textgb/main_screen/groups_screen.dart';
import 'package:textgb/main_screen/my_chats_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/main_screen/enhanced_profile_screen.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int pageIndex = 0;
  
  // Creating separate widget variables to ensure we're using the correct screens
  final Widget chatScreen = const MyChatsScreen();
  final Widget groupScreen = const GroupsScreen();
  final Widget cameraScreen = const CreateStatusScreen();
  final Widget statusScreen = const StatusScreen();  // Correctly referencing StatusScreen
  final Widget profileScreen = const EnhancedProfileScreen();
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize pages list to match the order of our bottom nav bar items
    pages = [
      chatScreen,        // Index 0 - Chats
      groupScreen,       // Index 1 - Groups
      cameraScreen,      // Index 2 - Camera (custom icon)
      statusScreen,      // Index 3 - Status Feed
      profileScreen,     // Index 4 - Profile
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
        context.read<AuthenticationProvider>().updateUserStatus(
              value: true,
            );
        // Refresh status feed when app is resumed
        if (pageIndex == 3) {
          _refreshStatusFeed();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // app is inactive, paused, detached or hidden
        // update user status to offline
        context.read<AuthenticationProvider>().updateUserStatus(
              value: false,
            );
        break;
      default:
        // handle other states
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  // Function to refresh status feed
  void _refreshStatusFeed() {
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    final contactIds = context.read<AuthenticationProvider>().userModel!.contactsUIDs;
    
    // Fetch statuses
    context.read<StatusProvider>().fetchStatuses(
      currentUserId: currentUserId,
      contactIds: contactIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExt = context.theme;
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    // Get all theme colors from WeChatThemeExtension
    final accentColor = themeExt.accentColor ?? const Color(0xFF09BB07);
    
    // Determine bottom nav bar color based on both theme and current tab
    final bottomNavColor = pageIndex == 3 
        ? Colors.black 
        : themeExt.appBarColor ?? (isLightMode ? Colors.white : const Color(0xFF121212));
    
    // Determine item colors based on current tab and theme
    final selectedItemColor = pageIndex == 3 
        ? Colors.white 
        : accentColor;
    
    // Unselected items should be more visible in dark mode
    final unselectedItemColor = pageIndex == 3
        ? Colors.grey
        : (themeExt.greyColor ?? Colors.grey);
    
    // Set elevation for better delineation
    final bottomNavElevation = isLightMode ? 2.0 : 1.0;
    
    return Scaffold(
      appBar: pageIndex != 2 && pageIndex != 3 && pageIndex != 4 ? AppBar(
        elevation: 2.0,
        toolbarHeight: 65.0,
        centerTitle: false,
        backgroundColor: themeExt.appBarColor ?? (isLightMode ? Colors.white : const Color(0xFF121212)),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: isLightMode ? const Color(0xFF181818) : Colors.white,
            ),
            children: [
              TextSpan(
                text: 'Tex',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'GB',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ) : null,
      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        // Add a top divider to better separate the content from navigation
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: themeExt.dividerColor ?? (isLightMode ? const Color(0xFFDBDBDB) : const Color(0xFF3D3D3D)),
              width: 0.5,
            ),
          ),
          // Add a subtle shadow for depth in light mode
          boxShadow: isLightMode && pageIndex != 3 ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ] : null,
        ),
        child: BottomNavigationBar(
          onTap: (index) {
            // If switching FROM status tab, ensure videos are paused
            if (pageIndex == 3 && index != 3) {
              // We don't need to explicitly pause videos here as we handle this in the StatusFeedItem widget
            }
            
            setState(() {
              pageIndex = index;
            });
            
            // If status tab is selected, refresh status data
            if (index == 3) {
              _refreshStatusFeed();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: bottomNavColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          showUnselectedLabels: true,
          showSelectedLabels: true,
          currentIndex: pageIndex,
          elevation: bottomNavElevation,
          // Improve padding for better touch targets
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2, size: 28),
              activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill, size: 28),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.group, size: 28),
              activeIcon: Icon(CupertinoIcons.group_solid, size: 28),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: CustomIcon(
                accentColor: accentColor,
                isDarkMode: !isLightMode,
              ),
              label: '',  // Intentionally empty for better design
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.camera, size: 28),
              activeIcon: Icon(CupertinoIcons.camera_fill, size: 28),
              label: 'Status',  // Renamed for clarity
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 28),
              activeIcon: Icon(CupertinoIcons.person_fill, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(accentColor),
    );
  }
  
  // Build context-specific floating action button
  Widget? _buildFloatingActionButton(Color accentColor) {
    // Chat button for Chats tab
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
        child: const Icon(CupertinoIcons.chat_bubble_text, size: 28),
      );
    }
    // Group button for Groups tab
    else if (pageIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          context
              .read<GroupProvider>()
              .clearGroupMembersList()
              .whenComplete(() {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );
          });
        },
        backgroundColor: accentColor,
        elevation: 4.0, // Increased elevation for better visibility
        child: const Icon(CupertinoIcons.add, size: 28),
      );
    }
    // Status creation button for Status tab
    else if (pageIndex == 3) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            Constants.createStatusScreen,
          ).then((_) {
            // Refresh status feed when returning from create status screen
            _refreshStatusFeed();
          });
        },
        backgroundColor: accentColor,
        elevation: 4.0,
        child: const Icon(CupertinoIcons.add, size: 28),
      );
    }
    // No FAB for other tabs
    return null;
  }
}