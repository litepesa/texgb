import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/main_screen/add_contact_screen.dart';
import 'package:textgb/main_screen/create_group_screen.dart';
import 'package:textgb/main_screen/groups_screen.dart';
import 'package:textgb/main_screen/my_chats_screen.dart';
import 'package:textgb/main_screen/people_screen.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    pages = const [
      MyChatsScreen(),
      GroupsScreen(),
      StatusScreen(),
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

  void _navigateToProfile() {
    final authProvider = context.read<AuthenticationProvider>();
    Navigator.pushNamed(
      context,
      Constants.profileScreen,
      arguments: authProvider.userModel!.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;
    
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: IndexedStack(
        index: currentIndex,
        children: [
          const MyChatsScreen(),
          const GroupsScreen(),
          const StatusScreen(),
          const SizedBox(), // Empty placeholder for profile tab
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
          if (index == 3) {
            // Profile tab - directly navigate to profile screen
            _navigateToProfile();
          } else {
            // For other tabs, update the currentIndex
            setState(() {
              currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Keep the original FAB functionality based on the current tab
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
    }
    return null; // No FAB for Status and Profile tabs
  }
}