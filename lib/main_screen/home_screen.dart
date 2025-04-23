import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/screens/create_group_screen.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/features/groups/screens/groups_screen.dart';
import 'package:textgb/features/chat/screens/my_chats_screen.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/groups/group_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/main_screen/enhanced_profile_screen.dart';
import 'package:textgb/shared/theme/wechat_theme_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int pageIndex = 0;
  
  // Creating separate widget variables with 4 screens instead of 5
  final Widget chatScreen = const MyChatsScreen();
  final Widget groupScreen = const GroupsScreen();
  final Widget statusScreen = const StatusScreen();
  final Widget profileScreen = const EnhancedProfileScreen();
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize pages list to match our simplified bottom nav bar (4 tabs instead of 5)
    pages = [
      chatScreen,        // Index 0 - Chats
      groupScreen,       // Index 1 - Groups
      statusScreen,      // Index 2 - Status Feed (includes camera functionality)
      profileScreen,     // Index 3 - Profile
    ];
    
    // Set app in fresh start state on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StatusProvider>().setAppFreshStart(true);
      }
    });
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
        if (pageIndex == 2) { // Updated index (was 3 before)
          _refreshStatusFeed();
          // Set status tab visibility to true when app resumes on status tab
          context.read<StatusProvider>().setStatusTabVisible(true);
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
        // Set status tab visibility to false when app is in background
        if (pageIndex == 2) { // Updated index (was 3 before)
          context.read<StatusProvider>().setStatusTabVisible(false);
        }
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
    
    // Get accent color from WeChatThemeExtension
    final accentColor = themeExt.accentColor ?? const Color(0xFF09BB07);
    
    // Consistent color for both app bar and bottom nav bar
    final appBarColor = themeExt.appBarColor ?? (isLightMode ? Colors.white : const Color(0xFF121212));
    
    // Use same color for bottom nav - no special case for status tab
    final bottomNavColor = appBarColor;
    
    // Consistent selected item color - no special case for status tab
    final selectedItemColor = accentColor;
    
    // Unselected items should be more visible in dark mode
    final unselectedItemColor = themeExt.greyColor ?? Colors.grey;
    
    // Set elevation for better delineation - consistent between appBar and bottomNav
    final elevation = isLightMode ? 2.0 : 1.0;
    
    return Scaffold(
      appBar: pageIndex != 2 && pageIndex != 3 ? AppBar(
        elevation: elevation,
        toolbarHeight: 65.0,
        centerTitle: false,
        backgroundColor: appBarColor,
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
          boxShadow: isLightMode && pageIndex != 2 ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ] : null,
        ),
        child: BottomNavigationBar(
          onTap: (index) {
            // If switching FROM status tab, ensure videos are paused by setting visibility flag
            if (pageIndex == 2 && index != 2) {
              // We're switching away from status tab
              context.read<StatusProvider>().setStatusTabVisible(false);
            } else if (index == 2 && pageIndex != 2) {
              // We're switching TO status tab, set visibility to true
              context.read<StatusProvider>().setStatusTabVisible(true);
              
              // Set app as no longer in fresh start when user actively selects the status tab
              context.read<StatusProvider>().setAppFreshStart(false);
            }
            
            setState(() {
              pageIndex = index;
            });
            
            // If status tab is selected, refresh status data
            if (index == 2) {
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
          elevation: elevation, // Match app bar elevation
          // Improve padding for better touch targets
          selectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.6,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2, size: 30),
              activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill, size: 30),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.group, size: 30),
              activeIcon: Icon(CupertinoIcons.group_solid, size: 30),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.camera, size: 30),
              activeIcon: Icon(CupertinoIcons.camera_fill, size: 30),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person, size: 30),
              activeIcon: Icon(CupertinoIcons.person_fill, size: 30),
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
    // Status create button for Status tab
    else if (pageIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.createStatusScreen);
        },
        backgroundColor: accentColor,
        elevation: 4.0,
        child: const Icon(CupertinoIcons.camera, size: 28),
      );
    }
    
    // No FAB for other tabs
    return null;
  }
}