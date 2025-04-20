// lib/main_screen/home_screen.dart
// Final implementation with centered camera button

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/moments/screens/moments_screen.dart';
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

  void _navigateToCreateMoment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateMomentScreen(),
      ),
    ).then((_) {
      // Refresh moments after creating a new one
      if (currentIndex == 2) { // Only refresh if we're on the Moments tab
        context.read<MomentsProvider>().fetchMoments(
          currentUserId: context.read<AuthenticationProvider>().userModel!.uid,
          contactIds: context.read<AuthenticationProvider>().userModel!.contactsUIDs,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;
    final accentColor = const Color(0xFF09BB07); // WeChat green
    
    return Scaffold(
      appBar: currentIndex != 2 && currentIndex != 3 ? AppBar(
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
                text: 'Tex',
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
        index: currentIndex,
        children: [
          const MyChatsScreen(),
          const GroupsScreen(),
          const MomentsScreen(),
          const EnhancedProfileScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: currentIndex == 2 
          ? _navigateToCreateMoment // For Moments tab, navigate to CreateMomentScreen
          : null, // Disable FAB for other tabs (will be hidden)
        backgroundColor: accentColor,
        child: const Icon(
          CupertinoIcons.camera,
          color: Colors.white,
          size: 28,
        ),
        // Hide FAB for non-Moments tabs
        // This will make the FAB disappear on other tabs
        elevation: currentIndex == 2 ? 6.0 : 0.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isLightMode ? Colors.white : const Color(0xFF121212),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side items
              Row(
                children: [
                  _buildNavItem(0, CupertinoIcons.chat_bubble_2, 'Chats', accentColor),
                  const SizedBox(width: 32),
                  _buildNavItem(1, CupertinoIcons.group, 'Groups', accentColor),
                ],
              ),
              
              // Right side items
              Row(
                children: [
                  _buildNavItem(2, CupertinoIcons.photo, 'Moments', accentColor),
                  const SizedBox(width: 32),
                  _buildNavItem(3, CupertinoIcons.person, 'Profile', accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color accentColor) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? accentColor : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 12 : 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? accentColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}