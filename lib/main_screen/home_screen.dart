// lib/main_screen/home_screen.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/channels/screens/recommended_posts_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/duanju/screens/short_dramas_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/groups/screens/groups_tab.dart';
import 'package:textgb/features/shop/screens/shops_list_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/light_theme.dart';
import 'package:textgb/widgets/custom_icon_button.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, RouteAware {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final PageController _pageController = PageController();
  bool _isPageAnimating = false;
  
  // Inbox tab switcher state (for Chats/Wallet)
  int _inboxTabIndex = 0; // 0 for Chats, 1 for Wallet
  final PageController _inboxPageController = PageController();
  
  // Groups tab switcher state (for Groups/Shops)
  int _groupsTabIndex = 0; // 0 for Groups, 1 for Shops
  final PageController _groupsPageController = PageController();
  
  // Channels tab switcher state (for Posts/Dramas)
  int _channelsTabIndex = 0; // 0 for Posts, 1 for Dramas
  final PageController _channelsPageController = PageController();
  
  // Updated tab configuration with 4 tabs
  final List<String> _tabNames = [
    'Inbox',      // Index 0 - Chats/Wallet switcher
    'Groups',     // Index 1 - Groups/Shops switcher
    'Channels',   // Index 2 - Recommended Posts
    'Profile'     // Index 3 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_2,       // Inbox (Chats)
    Icons.group_outlined,                // Groups
    Icons.radio_button_on_rounded,      // Channels
    Icons.person_outline                // Me/Profile
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
    _inboxPageController.dispose();
    _groupsPageController.dispose();
    _channelsPageController.dispose();
    super.dispose();
  }

  void _onInboxTabChanged(int index) {
    setState(() {
      _inboxTabIndex = index;
    });
    _inboxPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildChannelsContent(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Column(
        children: [
          // Enhanced tab bar for Posts/Dramas switcher
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.dividerColor!.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onChannelsTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _channelsTabIndex == 0 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _channelsTabIndex == 0 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _channelsTabIndex == 0 
                                ? Icons.grid_view_rounded
                                : Icons.grid_view_outlined,
                              color: _channelsTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _channelsTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _channelsTabIndex == 0 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Posts'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onChannelsTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _channelsTabIndex == 1 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _channelsTabIndex == 1 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _channelsTabIndex == 1 
                                ? Icons.video_library
                                : Icons.video_library_outlined,
                              color: _channelsTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _channelsTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _channelsTabIndex == 1 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Dramas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: PageView(
              controller: _channelsPageController,
              onPageChanged: (index) {
                setState(() {
                  _channelsTabIndex = index;
                });
              },
              children: [
                // Posts tab content
                Container(
                  color: modernTheme.surfaceColor,
                  child: const RecommendedPostsScreen(),
                ),
                // Dramas tab content
                Container(
                  color: modernTheme.surfaceColor,
                  child: const ShortDramasScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onGroupsTabChanged(int index) {
    setState(() {
      _groupsTabIndex = index;
    });
    _groupsPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onChannelsTabChanged(int index) {
    setState(() {
      _channelsTabIndex = index;
    });
    _channelsPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onTabTapped(int index) {
    // Store previous index for navigation management
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });

    // Special handling for Profile tab to prevent black bar
    if (index == 3) {
      // Force update system UI for Profile tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
        
        // Apply additional times for Profile tab specifically
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _currentIndex == 3) {
            _updateSystemUI();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _currentIndex == 3) {
            _updateSystemUI();
          }
        });
      });
    } else {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Use jumpToPage to avoid showing intermediate pages
    _isPageAnimating = true;
    _pageController.jumpToPage(index);
    // Reset animation flag after a brief delay
    Future.delayed(const Duration(milliseconds: 50), () {
      _isPageAnimating = false;
    });
  }
  
  void _updateSystemUI() {
    // Use theme-appropriate colors for all screens
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
    });

    // Special handling for Profile tab
    if (index == 3) {
      // Force update system UI for Profile tab with multiple attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
        
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _currentIndex == 3) {
            _updateSystemUI();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _currentIndex == 3) {
            _updateSystemUI();
          }
        });
      });
    } else {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }
  }

  void _navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  Widget _buildInboxContent(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Column(
        children: [
          // Enhanced tab bar for Chats/Wallet switcher
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.dividerColor!.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onInboxTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _inboxTabIndex == 0 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _inboxTabIndex == 0 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _inboxTabIndex == 0 
                                ? CupertinoIcons.chat_bubble_2_fill
                                : CupertinoIcons.chat_bubble_2,
                              color: _inboxTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _inboxTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _inboxTabIndex == 0 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Chats'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onInboxTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _inboxTabIndex == 1 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _inboxTabIndex == 1 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _inboxTabIndex == 1 
                                ? CupertinoIcons.creditcard_fill
                                : CupertinoIcons.creditcard,
                              color: _inboxTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _inboxTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _inboxTabIndex == 1 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Wallet'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: PageView(
              controller: _inboxPageController,
              onPageChanged: (index) {
                setState(() {
                  _inboxTabIndex = index;
                });
              },
              children: [
                // Chats tab content
                Container(
                  color: modernTheme.surfaceColor,
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: const ChatsTab(),
                ),
                // Wallet tab content
                Container(
                  color: modernTheme.surfaceColor,
                  child: const WalletScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsContent(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Column(
        children: [
          // Enhanced tab bar for Groups/Shops switcher
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.dividerColor!.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: modernTheme.primaryColor!.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onGroupsTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _groupsTabIndex == 0 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _groupsTabIndex == 0 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _groupsTabIndex == 0 
                                ? Icons.group
                                : Icons.group_outlined,
                              color: _groupsTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _groupsTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _groupsTabIndex == 0 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Groups'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onGroupsTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _groupsTabIndex == 1 ? Border(
                          bottom: BorderSide(
                            color: modernTheme.primaryColor!,
                            width: 3,
                          ),
                        ) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _groupsTabIndex == 1 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _groupsTabIndex == 1 
                                ? Icons.storefront
                                : Icons.storefront_outlined,
                              color: _groupsTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _groupsTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _groupsTabIndex == 1 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Shops'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: PageView(
              controller: _groupsPageController,
              onPageChanged: (index) {
                setState(() {
                  _groupsTabIndex = index;
                });
              },
              children: [
                // Groups tab content
                Container(
                  color: modernTheme.surfaceColor,
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: const GroupsTab(),
                ),
                // Shops tab content
                Container(
                  color: modernTheme.surfaceColor,
                  child: const ShopsListScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isProfileTab = _currentIndex == 3;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final chatsAsyncValue = ref.watch(chatStreamProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isProfileTab,
      backgroundColor: modernTheme.surfaceColor,
      
      // Show AppBar for all tabs except profile
      appBar: isProfileTab ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Inbox tab (index 0) - Chats/Wallet switcher
          _buildInboxContent(modernTheme),
          // Groups tab (index 1) - Groups/Shops switcher
          _buildGroupsContent(modernTheme),
          // Channels tab (index 2) - Posts/Dramas switcher
          _buildChannelsContent(modernTheme),
          // Profile tab (index 3)
          const MyProfileScreen(),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme, chatsAsyncValue),
      
      floatingActionButton: null,
    );
  }

  // Updated bottom navigation with 4 tabs
  Widget _buildBottomNav(ModernThemeExtension modernTheme, AsyncValue<List<ChatModel>> chatsAsyncValue) {
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
        border: Border(
          top: BorderSide(
            color: modernTheme.dividerColor!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return _buildNavItem(
                index,
                modernTheme,
                chatsAsyncValue,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    ModernThemeExtension modernTheme,
    AsyncValue<List<ChatModel>> chatsAsyncValue,
  ) {
    final isSelected = _currentIndex == index;
    
    // Inbox tab is at index 0 - show unread count for direct chats only
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Only show unread count when on Chats sub-tab, not Wallet
          final shouldShowBadge = _inboxTabIndex == 0;
          
          // Calculate unread count from direct chats only (excluding groups)
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final chatUnreadCount = shouldShowBadge ? directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          ) : 0;
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme,
            chatUnreadCount
          );
        },
        loading: () => _buildDefaultNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultNavItem(index, isSelected, modernTheme),
      );
    }
    
    // Groups tab is at index 1 - show unread count for group chats only
    if (index == 1) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Only show unread count when on Groups sub-tab, not Shops
          final shouldShowBadge = _groupsTabIndex == 0;
          
          // Calculate unread count from group chats only
          final groupChats = chats.where((chat) => chat.isGroup).toList();
          final groupUnreadCount = shouldShowBadge ? groupChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          ) : 0;
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme,
            groupUnreadCount
          );
        },
        loading: () => _buildDefaultNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultNavItem(index, isSelected, modernTheme),
      );
    }
    
    // For other tabs, no badge needed
    return _buildDefaultNavItem(index, isSelected, modernTheme);
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
        width: 80, // Increased width for 4 tabs
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? modernTheme.primaryColor!.withOpacity(0.2)
                      : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _tabIcons[index],
                    color: iconColor,
                    size: 22,
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

  Widget _buildDefaultNavItem(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
  ) {
    Color iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    Color textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 80, // Increased width for 4 tabs
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected 
                  ? modernTheme.primaryColor!.withOpacity(0.2)
                  : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _tabIcons[index],
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
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
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    String title = 'WeiBao';
    final isGroupsTab = _currentIndex == 1;
    final isInboxTab = _currentIndex == 0;
    final isChannelsTab = _currentIndex == 2;
    
    // Set title based on current tab
    switch (_currentIndex) {
      case 0:
        title = _inboxTabIndex == 0 ? 'Inbox' : 'Wallet';
        break;
      case 1:
        title = _groupsTabIndex == 0 ? 'Groups' : 'Shops';
        break;
      case 2:
        title = _channelsTabIndex == 0 ? 'Channels' : 'Dramas';
        break;
      default:
        title = 'WeiBao';
    }

    return AppBar(
      backgroundColor: modernTheme.surfaceColor!,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: modernTheme.primaryColor!),
      title: _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2
          ? Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor!,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            )
          : RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Wei",
                    style: TextStyle(
                      color: modernTheme.textColor!,          
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: "Bao",
                    style: TextStyle(
                      color: modernTheme.primaryColor!,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
      actions: _currentIndex == 1 ? [
        // Groups/Shops tab actions
        if (_groupsTabIndex == 0) ...[
          // Groups sub-tab actions
          IconButton(
            icon: Icon(Icons.search, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search groups')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.group_add, color: modernTheme.primaryColor!),
            onPressed: () {
              Navigator.pushNamed(context, Constants.createGroupScreen);
            },
          ),
        ] else ...[
          // Shops sub-tab actions
          IconButton(
            icon: Icon(CupertinoIcons.search, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search shops')),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.cart, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shopping cart')),
              );
            },
          ),
        ],
        const SizedBox(width: 8),
      ] : isInboxTab ? [
        // Different actions based on the selected inbox tab
        if (_inboxTabIndex == 0) ...[
          // Chats tab actions
          IconButton(
            icon: Icon(Icons.search, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search chats')),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.chat_bubble_2, color: modernTheme.primaryColor!),
            onPressed: () {
              Navigator.pushNamed(context, Constants.contactsScreen);
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: modernTheme.primaryColor!),
            onSelected: (String value) {
              switch (value) {
                case 'new_group':
                  Navigator.pushNamed(context, Constants.createGroupScreen);
                  break;
                case 'new_broadcast':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New broadcast list')),
                  );
                  break;
                case 'starred':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Starred messages')),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat settings')),
                  );
                  break;
              }
            },
            color: modernTheme.surfaceColor,
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
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'new_group',
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
                        Icons.group_add,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'New Group',
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
                value: 'new_broadcast',
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
                        Icons.speaker_phone,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'New Broadcast',
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
                value: 'starred',
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
                        Icons.star_outline,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Starred Messages',
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
                value: 'settings',
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
                        Icons.settings_outlined,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
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
          ),
        ] else ...[
          // Wallet tab actions
          IconButton(
            icon: Icon(CupertinoIcons.bell, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet notifications')),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.chart_bar, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wallet analytics')),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: modernTheme.primaryColor!),
            onSelected: (String value) {
              switch (value) {
                case 'transaction_history':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction history')),
                  );
                  break;
                case 'payment_methods':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment methods')),
                  );
                  break;
                case 'security':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Security settings')),
                  );
                  break;
                case 'help':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wallet help')),
                  );
                  break;
              }
            },
            color: modernTheme.surfaceColor,
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
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'transaction_history',
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
                        Icons.history,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Transaction History',
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
                value: 'payment_methods',
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
                        Icons.payment,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Payment Methods',
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
                value: 'security',
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
                        Icons.security,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Security',
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
                value: 'help',
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
                        Icons.help_outline,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Help',
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
          ),
        ],
        const SizedBox(width: 8),
      ] : isChannelsTab ? [
        // Channels tab actions
        if (_channelsTabIndex == 0) ...[
          // Posts sub-tab actions
          IconButton(
            icon: Icon(CupertinoIcons.search, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search posts')),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.camera_on_rectangle, color: modernTheme.primaryColor!),
            onPressed: () => _navigateToCreatePost(),
          ),
        ] else ...[
          // Dramas sub-tab actions
          IconButton(
            icon: Icon(CupertinoIcons.search, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search dramas')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.download_outlined, color: modernTheme.primaryColor!),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloads')),
              );
            },
          ),
        ],
        const SizedBox(width: 8),
      ] : null,
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
}