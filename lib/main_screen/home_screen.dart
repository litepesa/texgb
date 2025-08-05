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
import 'package:textgb/features/status/screens/status_screen.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/privacy_settings_sheet.dart';
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
  
  // Social tab switcher state (for Chats/Groups)
  int _socialTabIndex = 0; // 0 for Chats, 1 for Groups
  final PageController _socialPageController = PageController();
  
  // Updated tab configuration with 4 tabs
  final List<String> _tabNames = [
    'Social',     // Index 0 - Chats/Groups switcher
    'Status',     // Index 1 - Status
    'Series',     // Index 2 - Mini-Series (NEW)
    'Channels'    // Index 3 - Channels
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_2,       // Social (Chats/Groups)
    Icons.donut_large_rounded,          // Status
    CupertinoIcons.compass,             // Series
    Icons.radio_button_on_rounded       // Channels
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
    _socialPageController.dispose();
    super.dispose();
  }

  void _onSocialTabChanged(int index) {
    setState(() {
      _socialTabIndex = index;
    });
    _socialPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildSocialContent(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final chatsAsyncValue = ref.watch(chatStreamProvider);
    
    return Container(
      color: modernTheme.surfaceColor,
      child: Column(
        children: [
          // Enhanced tab bar for Chats/Groups switcher with individual unread badges
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
                    onTap: () => _onSocialTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _socialTabIndex == 0 ? Border(
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
                              color: _socialTabIndex == 0 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _socialTabIndex == 0 
                                ? CupertinoIcons.chat_bubble_2_fill
                                : CupertinoIcons.chat_bubble_2,
                              color: _socialTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _socialTabIndex == 0 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _socialTabIndex == 0 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Chats'),
                          ),
                          // Chats unread badge
                          chatsAsyncValue.when(
                            data: (chats) {
                              final directChats = chats.where((chat) => !chat.isGroup).toList();
                              final chatUnreadCount = directChats.fold<int>(
                                0, 
                                (sum, chat) => sum + chat.getDisplayUnreadCount()
                              );
                              
                              if (chatUnreadCount > 0) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: modernTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    chatUnreadCount > 99 ? '99+' : chatUnreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onSocialTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: _socialTabIndex == 1 ? Border(
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
                              color: _socialTabIndex == 1 
                                ? modernTheme.primaryColor!.withOpacity(0.15)
                                : modernTheme.primaryColor!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _socialTabIndex == 1 
                                ? Icons.group
                                : Icons.group_outlined,
                              color: _socialTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _socialTabIndex == 1 
                                ? modernTheme.primaryColor 
                                : modernTheme.textSecondaryColor,
                              fontWeight: _socialTabIndex == 1 
                                ? FontWeight.w700 
                                : FontWeight.w500,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                            child: const Text('Groups'),
                          ),
                          // Groups unread badge
                          chatsAsyncValue.when(
                            data: (chats) {
                              final groupChats = chats.where((chat) => chat.isGroup).toList();
                              final groupUnreadCount = groupChats.fold<int>(
                                0, 
                                (sum, chat) => sum + chat.getDisplayUnreadCount()
                              );
                              
                              if (groupUnreadCount > 0) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: modernTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    groupUnreadCount > 99 ? '99+' : groupUnreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
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
              controller: _socialPageController,
              onPageChanged: (index) {
                setState(() {
                  _socialTabIndex = index;
                });
              },
              children: [
                // Chats tab content
                Container(
                  color: modernTheme.surfaceColor,
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: const ChatsTab(),
                ),
                // Groups tab content
                Container(
                  color: modernTheme.surfaceColor,
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: const GroupsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesContent(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 80,
              color: modernTheme.primaryColor!.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Mini-Series Coming Soon!',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create and watch episodic content\nwith trailers and episodes',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: modernTheme.primaryColor!.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction,
                    color: modernTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Under Development',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    // Store previous index for navigation management
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
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

    _updateSystemUI();
  }

  void _navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final chatsAsyncValue = ref.watch(chatStreamProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: modernTheme.surfaceColor,
      
      // Show AppBar for all tabs
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Social tab (index 0) - Chats/Groups switcher
          _buildSocialContent(modernTheme),
          // Status tab (index 1)
          Container(
            color: modernTheme.backgroundColor,
            child: const StatusScreen(),
          ),
          // Series tab (index 2) - NEW
          _buildSeriesContent(modernTheme),
          // Channels tab (index 3)
          Container(
            color: modernTheme.surfaceColor,
            child: const RecommendedPostsScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme, chatsAsyncValue),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
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
    
    // Social tab is at index 0 - show combined unread count for both chats and groups
    if (index == 0) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate total unread count from all chats
          final totalUnreadCount = chats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme,
            totalUnreadCount
          );
        },
        loading: () => _buildDefaultNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultNavItem(index, isSelected, modernTheme),
      );
    }
    
    // Status tab is at index 1 - show green dot for unviewed statuses
    if (index == 1) {
      final currentUser = ref.watch(currentUserProvider);
      final statusStreamAsync = ref.watch(statusStreamProvider);
      
      return statusStreamAsync.when(
        data: (statusGroups) {
          if (currentUser == null) {
            return _buildDefaultNavItem(index, isSelected, modernTheme);
          }
          
          // Check if there are any unviewed statuses from other users
          final hasUnviewedStatuses = statusGroups
              .where((group) => !group.isMyStatus) // Exclude my own statuses
              .any((group) => group.hasUnviewedStatuses(currentUser.uid));
          
          return _buildNavItemWithStatusDot(
            index, 
            isSelected, 
            modernTheme, 
            hasUnviewedStatuses
          );
        },
        loading: () => _buildDefaultNavItem(index, isSelected, modernTheme),
        error: (_, __) => _buildDefaultNavItem(index, isSelected, modernTheme),
      );
    }
    
    // For Series (index 2) and Channels (index 3), no badge needed
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
        width: 80, // Width for 4 tabs
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

  Widget _buildNavItemWithStatusDot(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    bool hasUnviewedStatuses,
  ) {
    Color iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    Color textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 80,
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
                if (hasUnviewedStatuses)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor,
                        shape: BoxShape.circle,
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
        width: 80,
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
  
  // Show FAB on all tabs with different functions
  bool _shouldShowFab() {
    return true; // Show FAB on all tabs
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Social tab - Different FAB based on current sub-tab
      if (_socialTabIndex == 0) {
        // Chats sub-tab - New chat FAB
        return FloatingActionButton(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
          child: const Icon(CupertinoIcons.chat_bubble_text),
        );
      } else {
        // Groups sub-tab - Create group FAB
        return FloatingActionButton(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () => Navigator.pushNamed(context, Constants.createGroupScreen),
          child: const Icon(Icons.group_add),
        );
      }
    } else if (_currentIndex == 1) {
      // Status tab - Create status FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _createStatus(),
        child: const Icon(Icons.camera_alt),
      );
    } else if (_currentIndex == 2) {
      // Series tab - Create series FAB (placeholder for now)
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Series creation coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.video_call_outlined),
      );
    } else if (_currentIndex == 3) {
      // Channels tab - Create post FAB
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _navigateToCreatePost(),
        child: const Icon(CupertinoIcons.camera),
      );
    }
    
    return const SizedBox.shrink();
  }

  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBgColor = isDark 
      ? modernTheme.surfaceColor!.withOpacity(0.98)
      : modernTheme.surfaceColor!.withOpacity(0.96);

    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Snap",
              style: TextStyle(
                color: modernTheme.textColor,          
                fontWeight: FontWeight.w500,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            TextSpan(
              text: "reel",
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
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
            } else if (value == 'status_privacy') {
              _showStatusPrivacySettings();
            }
          },
          itemBuilder: (BuildContext context) => [
            // Status Privacy option - only show when on Status tab (index 1)
            if (_currentIndex == 1)
              PopupMenuItem<String>(
                value: 'status_privacy',
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
                        Icons.visibility,
                        color: modernTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Status Privacy',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Add divider after status privacy if it's shown
            if (_currentIndex == 1)
              PopupMenuItem<String>(
                enabled: false,
                height: 1,
                padding: EdgeInsets.zero,
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: modernTheme.dividerColor?.withOpacity(0.3),
                ),
              ),
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
        ),
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

  // Status creation method
  void _createStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStatusScreen(),
      ),
    );
  }

  // Status privacy settings method
  void _showStatusPrivacySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const StatusPrivacySettingsSheet(),
    );
  }
}