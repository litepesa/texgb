import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/moments_screen.dart';
import 'package:textgb/features/moments/widgets/custom_icon.dart';
import 'package:textgb/main_screen/create_group_screen.dart';
import 'package:textgb/main_screen/groups_screen.dart';
import 'package:textgb/main_screen/my_chats_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/main_screen/enhanced_profile_screen.dart';

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
  final Widget cameraScreen = const CreateMomentScreen();
  final Widget momentScreen = const MomentsScreen();
  final Widget profileScreen = const EnhancedProfileScreen();
  
  // We'll define these in initState to ensure they match our bottom nav bar
  late final List<Widget> pages;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // Initialize pages list to match the order of our bottom nav bar items
    pages = [
      chatScreen,     // Index 0 - Chats
      groupScreen,    // Index 1 - Groups
      cameraScreen,   // Index 2 - Camera (custom icon)
      momentScreen,   // Index 3 - Moments
      profileScreen,  // Index 4 - Profile
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;
    final accentColor = const Color(0xFF09BB07); // WeChat green
    
    return Scaffold(
      appBar: pageIndex != 2 && pageIndex != 3 && pageIndex != 4 ? AppBar(
        elevation: 2.0,
        toolbarHeight: 65.0,
        centerTitle: false,
        backgroundColor: isLightMode ? Colors.white : const Color(0xFF121212),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: isLightMode ? const Color(0xFF181818) : Colors.white,
            ),
            children: [
              const TextSpan(
                text: 'Bisha',
                style: TextStyle(
                  color: Color(0xFF09BB07),
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
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          // Debug info to verify which screen is shown
          print('Tapped on bottom nav index: $index');
          
          setState(() {
            pageIndex = index;
          });
          
          // If moments tab is selected, refresh moments data
          if (index == 3) {
            context.read<MomentsProvider>().fetchMoments(
              currentUserId: context.read<AuthenticationProvider>().userModel!.uid,
              contactIds: context.read<AuthenticationProvider>().userModel!.contactsUIDs,
            );
          }
          
          // Debug verification
          print('Now showing: ${pages[pageIndex].runtimeType}');
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isLightMode ? Colors.white : const Color(0xFF121212),
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        currentIndex: pageIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble, size: 30),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.group, size: 30),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: CustomIcon(), // Your custom camera icon
            label: '',  // Intentionally empty for better design
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.camera, size: 30),
            label: 'Moments',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: 30),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  // Build context-specific floating action button
  Widget? _buildFloatingActionButton() {
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
        backgroundColor: const Color(0xFF09BB07), // WeChat green
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
        backgroundColor: const Color(0xFF09BB07), // WeChat green
        child: const Icon(CupertinoIcons.add, size: 28),
      );
    }
    // No FAB for other tabs
    return null;
  }
}