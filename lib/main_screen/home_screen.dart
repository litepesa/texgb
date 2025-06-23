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
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/main_screen/discover_screen.dart';
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
    'Discover',
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_text,
    Icons.group_outlined,
    CupertinoIcons.compass,
    Icons.person_outline
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
    final isProfileTab = _currentIndex == 3; // Profile tab at index 3
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isProfileTab,
      backgroundColor: modernTheme.backgroundColor,
      
      // Hide AppBar for profile tab only
      appBar: isProfileTab ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Chats tab (index 0)
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          // Groups tab (index 1) - moved from index 3
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const GroupsTab(),
          ),
          // Discover tab (index 2) - new discover screen instead of channels feed
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const DiscoverScreen(),
          ),
          // Profile tab (index 3) - moved from dropdown menu
          const MyProfileScreen(),
        ],
      ),
      
      bottomNavigationBar: Container(
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
              bottom: false,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: modernTheme.primaryColor,
                  unselectedItemColor: modernTheme.textSecondaryColor,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  items: List.generate(
                    _tabNames.length,
                    (index) => _buildBottomNavItem(index, modernTheme, chatsAsyncValue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }
  
  BottomNavigationBarItem _buildBottomNavItem(
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
    
    // For other tabs (Discover, Profile), no badge needed
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }
  
  BottomNavigationBarItem _buildNavItemWithBadge(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    int unreadCount,
  ) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                ? modernTheme.primaryColor!.withOpacity(0.2) 
                : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(_tabIcons[index]),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor,
                  shape: unreadCount > 99 
                      ? BoxShape.rectangle 
                      : BoxShape.circle,
                  borderRadius: unreadCount > 99 
                      ? BorderRadius.circular(10) 
                      : null,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: _tabNames[index],
    );
  }
  
  BottomNavigationBarItem _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
            ? modernTheme.primaryColor!.withOpacity(0.2) 
            : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(_tabIcons[index]),
      ),
      label: _tabNames[index],
    );
  }
  
  // Show FAB on Chats and Groups tabs only
  bool _shouldShowFab() {
    return _currentIndex == 0 || _currentIndex == 1;
  }
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      backgroundColor: _currentIndex == 2 ? modernTheme.surfaceColor : modernTheme.backgroundColor,
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
    // Dynamic title based on current tab
    if (_currentIndex == 2) {
      // Discover tab
      return Text(
        'Discover',
        style: TextStyle(
          color: modernTheme.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: -0.3,
        ),
      );
    }
    
    // Default WeiBao title for other tabs
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
        if (value == 'post') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
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
          value: 'post',
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
                  Icons.add_box_outlined,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Post',
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
    }
    
    return const SizedBox.shrink();
  }
}