// lib/main_screen/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/screens/my_channel_screen.dart';
import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/groups/screens/groups_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final PageController _pageController = PageController();
  bool _isPageAnimating = false;
  
  final List<String> _tabNames = [
    'Chats',
    'Groups',
    'Status',
    'Commerce'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.bubble_left_bubble_right,
    Icons.group,
    Icons.donut_large_rounded,
    Icons.radio_button_checked_rounded
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Store previous index for navigation management
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI(); // Force immediate update
    });

    // Use jumpToPage to avoid showing intermediate pages
    _isPageAnimating = true;
    _pageController.jumpToPage(index);
    // Reset animation flag after a brief delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _isPageAnimating = false;
    });
  }
  
  void _updateSystemUI() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }
  
  void _onPageChanged(int index) {
    // Only process page changes that aren't from programmatic jumps
    if (_isPageAnimating) return;
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
      _updateSystemUI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: _currentIndex == 0 ? modernTheme.surfaceColor : modernTheme.backgroundColor,
      
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Chats tab (index 0)
          Container(
            color: modernTheme.surfaceColor,
            child: const ChatsTab(),
          ),
          // Groups tab (index 1)
          Container(
            color: modernTheme.backgroundColor,
            child: const GroupsScreen(),
          ),
          // Status tab (index 2)
          Container(
            color: modernTheme.backgroundColor,
            child: const StatusScreen(),
          ),
          // Channels tab (index 3)
          Container(
            color: modernTheme.backgroundColor,
            child: const ChannelsListScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildCustomBottomNav(modernTheme),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }

  Widget _buildCustomBottomNav(ModernThemeExtension modernTheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use consistent surface color for bottom nav
    final bottomNavColor = isDarkMode ? modernTheme.surfaceColor : Colors.white;
    final dividerColor = modernTheme.dividerColor;
    
    return Container(
      decoration: BoxDecoration(
        color: bottomNavColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: dividerColor,
          ),
          Container(
            height: 60 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return _buildBottomNavItem(index, modernTheme);
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavItem(
    int index, 
    ModernThemeExtension modernTheme,
  ) {
    final isSelected = _currentIndex == index;
    
    // No badge functionality needed - just show default bottom nav items
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }

  Widget _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    final iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    final textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                  ? modernTheme.primaryColor!.withOpacity(0.2)
                  : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _tabIcons[index],
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            if (_tabNames[index].isNotEmpty)
              Text(
                _tabNames[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
  
  // Show FAB on Chats, Status and Channels tabs
  bool _shouldShowFab() {
    return _currentIndex == 0 || _currentIndex == 2 || _currentIndex == 3;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: _buildAppBarTitle(modernTheme),
      actions: [
        _buildThreeDotMenu(modernTheme),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: modernTheme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(ModernThemeExtension modernTheme) {
  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: "Wei",
          style: TextStyle(
            color: modernTheme.textColor,          
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        TextSpan(
          text: "Bao",
          style: TextStyle(
            color: modernTheme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.3,
          ),
        ),
        TextSpan(
          text: "微宝",
          style: TextStyle(
            color: const Color(0xFFFE2C55),
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildThreeDotMenu(ModernThemeExtension modernTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBgColor = isDark 
      ? modernTheme.surfaceColor!.withOpacity(0.98)
      : modernTheme.surfaceColor!.withOpacity(0.96);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: modernTheme.textColor,
      ),
      color: menuBgColor,
      elevation: 8,
      surfaceTintColor: modernTheme.primaryColor?.withOpacity(0.1),
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (String value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyProfileScreen(),
            ),
          );
        } else if (value == 'wallet') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletScreen(),
            ),
          );
        } else if (value == 'my_channel') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyChannelScreen(),
            ),
          );
        } else if (value == 'explore_channels') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChannelsListScreen(),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => _buildMenuItems(modernTheme),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(ModernThemeExtension modernTheme) {
    final List<PopupMenuEntry<String>> items = [];

    // Add conditional menu items based on current tab
    if (_currentIndex == 0) {
      // Chats tab - add "Profile" and "Wallet" options
      items.addAll([
        PopupMenuItem<String>(
          value: 'profile',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_2_outlined,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Profile',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'wallet',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Wallet',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ]);
    } else if (_currentIndex == 3) {
      // Channels tab - add "My Channel" and "Explore" options
      items.addAll([
        PopupMenuItem<String>(
          value: 'my_channel',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.video_library_outlined,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'My Channel',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'explore_channels',
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Explore Channels',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ]);
    }
    // Groups (index 1) and Status (index 2) tabs have empty dropdown menus as requested

    return items;
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Chats tab - Show New chat FAB
      return FloatingActionButton(
        heroTag: "chat_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
        child: const Icon(CupertinoIcons.bubble_left_bubble_right_fill),
      );
    } else if (_currentIndex == 2) {
      // Status tab - Create Status FAB
      return FloatingActionButton(
        heroTag: "status_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _createStatus(),
        child: const Icon(Icons.camera_alt),
      );
    } else if (_currentIndex == 3) {
      // Channels tab - Create Post FAB
      return FloatingActionButton(
        heroTag: "channels_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _createChannelPost(),
        child: const Icon(Icons.videocam),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Status creation method
  void _createStatus() {
    // TODO: Implement status creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create Status - To be implemented'),
        backgroundColor: context.modernTheme.primaryColor,
      ),
    );
  }

  // Channel post creation method
  void _createChannelPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }
}