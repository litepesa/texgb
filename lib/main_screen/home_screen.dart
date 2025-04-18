import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/main_screen/create_group_screen.dart';
import 'package:textgb/main_screen/groups_screen.dart';
import 'package:textgb/main_screen/my_chats_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

// Import the enhanced profile screen
import 'package:textgb/main_screen/enhanced_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
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
    
    return Scaffold(
      appBar: currentIndex != 3 ? AppBar(
        elevation: 0.5,
        centerTitle: false,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: isLightMode ? const Color(0xFF181818) : Colors.white,
            ),
            children: [
              TextSpan(
                text: 'Tex',
                style: TextStyle(
                  color: const Color(0xFF09BB07), // WeChat green color
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
        index: currentIndex,
        children: [
          const MyChatsScreen(),
          const GroupsScreen(),
          const StatusScreen(),
          const EnhancedProfileScreen(), // New enhanced profile screen
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2, size: 28),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.group, size: 28),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.rays, size: 28),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person, size: 28),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed, // Ensures all 4 items are visible
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show FAB only on specific tabs
    if (currentIndex == 1) {
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
        child: const Icon(CupertinoIcons.add),
      );
    } else if (currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          // Navigate to Contacts screen
          Navigator.pushNamed(
            context,
            Constants.contactsScreen,
          );
        },
        child: const Icon(CupertinoIcons.chat_bubble_text),
      );
    } else if (currentIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            Constants.statusCreateScreen,
          );
        },
        child: const Icon(CupertinoIcons.camera),
      );
    }
    return null; // No FAB for Profile tab
  }
}