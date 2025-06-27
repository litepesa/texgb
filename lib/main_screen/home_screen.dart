// lib/main_screen/home_screen.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/groups/screens/groups_tab.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/live/screens/go_live_screen';
import 'package:textgb/features/live/screens/live_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/features/status/screens/status_overview_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/widgets/custom_icon_button.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';

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
    '',         // Empty label for custom post button
    'Status',
    'Live'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_text,
    Icons.group_outlined,
    Icons.add,  // This will be replaced with custom design
    Icons.donut_large,
    Icons.radio_button_checked
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
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
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
          // Chats tab (index 0) - Use surfaceColor for seamless look
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          // Groups tab (index 1)
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GroupsTab(),
          ),
          // Go Live tab (index 2) - Use surfaceColor for seamless look
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GoLiveScreen(),
          ),
          // Status tab (index 3) - Use surfaceColor for seamless look with appbar
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const StatusOverviewScreen(),
          ),
          // Live tab (index 4)
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const LiveScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildCustomBottomNav(modernTheme, chatsAsyncValue),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }

  Widget _buildCustomBottomNav(ModernThemeExtension modernTheme, AsyncValue<List<ChatModel>> chatsAsyncValue) {
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: modernTheme.dividerColor,
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) {
                    // Special post button at index 2
                    return _buildPostButton(modernTheme);
                  }
                  
                  return _buildBottomNavItem(index, modernTheme, chatsAsyncValue);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _onTabTapped(2), // Navigate to Go Live screen
      child: Container(
        width: 45,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.red.shade400,
              Colors.pink.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left background icon
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
            // Right background icon
            Positioned(
              right: 6,
              top: 10,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomNavItem(
    int index, 
    ModernThemeExtension modernTheme,
    AsyncValue<List<ChatModel>> chatsAsyncValue,
  ) {
    final isSelected = _currentIndex == index;
    
    // Chats tab is at index 0 - show unread count for direct chats only
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate unread count from direct chats only
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final chatUnreadCount = directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            chatUnreadCount
          );
        },
        loading: () => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
      );
    }
    
    // Groups tab is at index 1 - show unread count for group chats only
    if (index == 1) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate unread count from group chats only
          final groupChats = chats.where((chat) => chat.isGroup).toList();
          final groupUnreadCount = groupChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            groupUnreadCount
          );
        },
        loading: () => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultBottomNavItem(index, isSelected, modernTheme),
      );
    }
    
    // For other tabs (Go Live, Status, Live), no badge needed
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }

  Widget _buildNavItemWithBadge(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    int unreadCount,
  ) {
    Color iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    Color textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
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
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        shape: unreadCount > 99 
                            ? BoxShape.rectangle 
                            : BoxShape.circle,
                        borderRadius: unreadCount > 99 
                            ? BorderRadius.circular(8) 
                            : null,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
  
  Widget _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    Color iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    Color textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

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
  
  // Show FAB on Chats, Groups, and Status tabs
  bool _shouldShowFab() {
    return _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 3;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Use surfaceColor for all tabs for consistency
    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true, // Center the title
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
    // Always show WeiBao title consistently across all tabs
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Wei",
            style: TextStyle(
              color: modernTheme.textColor,          
              fontWeight: FontWeight.w500,
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
        }
      },
      itemBuilder: (BuildContext context) => [
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
                  Icons.person_outline,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'My Profile',
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
                  Icons.account_balance_wallet_outlined,
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
      ],
    );
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Chats tab - New chat FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
        child: const Icon(CupertinoIcons.chat_bubble_text),
      );
    } else if (_currentIndex == 1) {
      // Groups tab - Create group FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
        child: const Icon(Icons.group_add),
      );
    } else if (_currentIndex == 3) {
      // Status tab - Create status FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.createStatusScreen),
        child: const Icon(Icons.add),
      );
    }
    
    return const SizedBox.shrink();
  }
}