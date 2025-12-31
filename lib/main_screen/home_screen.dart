// lib/main_screen/home_screen.dart (WeChat-style Interface)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/features/groups/screens/groups_list_screen.dart';
import 'package:textgb/features/groups/screens/create_group_screen.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/marketplace/screens/create_listing_screen.dart';
import 'package:textgb/features/status/screens/status_list_screen.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/videos/screens/recommended_posts_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen_v2.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isPageAnimating = false;

  // For index 1 tab: track which view to show (0=Groups, 1=Moments, 2=Channels)
  int _tab1Selection = 0;

  final List<String> _tabNames = [
    'Chats',          // Index 0 - Chats Screen
    'Groups',         // Index 1 - Groups / Moments / Channels (Switchable)
    'Marketplace',    // Index 2 - Marketplace Home Screen
    'Status',         // Index 3 - Status List Screen
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_2,                // Chats
    Icons.group_outlined,                        // Groups
    Icons.store_outlined,                        // Marketplace
    Icons.donut_large_rounded,                   // Status
  ];

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setSystemUIOverlayStyle();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ModernThemeExtension _getModernTheme() {
    if (!mounted) {
      return _getFallbackTheme();
    }
    
    try {
      final extension = Theme.of(context).extension<ModernThemeExtension>();
      return extension ?? _getFallbackTheme();
    } catch (e) {
      debugPrint('Modern theme error: $e');
      return _getFallbackTheme();
    }
  }

  ModernThemeExtension _getFallbackTheme() {
    final isDark = mounted ? Theme.of(context).brightness == Brightness.dark : false;
    
    return ModernThemeExtension(
      primaryColor: const Color(0xFF07C160), // WeChat green
      backgroundColor: isDark ? Colors.black : Colors.white,
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      textTertiaryColor: isDark ? Colors.grey[500] : Colors.grey[400],
      surfaceVariantColor: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Widget _buildComingSoonScreen(String title, ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == 'Groups' ? Icons.group : Icons.donut_large_rounded,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (!mounted || index == _currentIndex) return;

    debugPrint('HomeScreen: Navigating from $_currentIndex to $index');
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
      _setSystemUIOverlayStyle();
    });
    
    // Use jumpToPage to avoid showing intermediate pages
    _isPageAnimating = true;
    _pageController.jumpToPage(index);
    
    // Reset animation flag after a brief delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _isPageAnimating = false;
      }
    });
  }

  void _setSystemUIOverlayStyle() {
    if (!mounted) return;
    
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    } catch (e) {
      debugPrint('System UI update error: $e');
    }
  }

  void _onPageChanged(int index) {
    // Only process page changes that aren't from programmatic jumps
    if (_isPageAnimating) return;
    
    setState(() {
      _currentIndex = index;
      _setSystemUIOverlayStyle();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!mounted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final modernTheme = _getModernTheme();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Check if app is still initializing
    final isAppInitializing = ref.watch(isAppInitializingProvider);

    // Show branded loading screen ONLY during initial app startup
    if (isAppInitializing) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/branding - WeChat style
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Wema',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Color(0xFF07C160),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Chats tab (index 0) - Chats Screen
          _KeepAliveWrapper(
            child: const ChatsTab(),
          ),
          // Groups/Moments/Channels tab (index 1) - Switchable between three views
          _KeepAliveWrapper(
            child: _tab1Selection == 0
                ? const GroupsListScreen()
                : _tab1Selection == 1
                    ? const RecommendedPostsScreen()
                    : const ChannelsListScreen(),
          ),
          // Marketplace Tab (index 2) - Sellers List Screen
          _KeepAliveWrapper(
            child: const UsersListScreen(),
          ),
          // Status tab (index 3) - Status List Screen
          _KeepAliveWrapper(
            child: const StatusListScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme),
      floatingActionButton: _currentIndex == 0 ? _buildMultipleFabs(modernTheme) : _buildFab(modernTheme),
    );
  }

  Widget _buildMultipleFabs(ModernThemeExtension modernTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Wallet FAB
        FloatingActionButton(
          heroTag: 'wallet_fab',
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WalletScreen(),
              ),
            );
          },
          child: const Icon(Icons.monetization_on_outlined),
        ),
        const SizedBox(height: 16),
        // Contacts FAB
        FloatingActionButton(
          heroTag: 'contacts_fab',
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContactsScreen(),
              ),
            );
          },
          child: const Icon(CupertinoIcons.chat_bubble_2_fill),
        ),
      ],
    );
  }

  Widget _buildGroupsChannelsSwitcher(ModernThemeExtension modernTheme, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Groups tab
          GestureDetector(
            onTap: () {
              if (_tab1Selection != 0) {
                setState(() {
                  _tab1Selection = 0;
                });
                HapticFeedback.lightImpact();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _tab1Selection == 0
                    ? modernTheme.backgroundColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Groups',
                style: TextStyle(
                  color: _tab1Selection == 0
                      ? textColor
                      : modernTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: _tab1Selection == 0
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          // Moments tab
          GestureDetector(
            onTap: () {
              if (_tab1Selection != 1) {
                setState(() {
                  _tab1Selection = 1;
                });
                HapticFeedback.lightImpact();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _tab1Selection == 1
                    ? modernTheme.backgroundColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Moments',
                style: TextStyle(
                  color: _tab1Selection == 1
                      ? textColor
                      : modernTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: _tab1Selection == 1
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          // Channels tab
          GestureDetector(
            onTap: () {
              if (_tab1Selection != 2) {
                setState(() {
                  _tab1Selection = 2;
                });
                HapticFeedback.lightImpact();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _tab1Selection == 2
                    ? modernTheme.backgroundColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Channels',
                style: TextStyle(
                  color: _tab1Selection == 2
                      ? textColor
                      : modernTheme.textSecondaryColor,
                  fontSize: 14,
                  fontWeight: _tab1Selection == 2
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 1) {
      // Groups/Moments/Channels tab - Show appropriate FAB based on current view
      if (_tab1Selection == 0) {
        // Groups view - Create new group
        return FloatingActionButton(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );

            // Refresh groups list if group was created
            if (result == true && mounted) {
              ref.invalidate(groupsListProvider);
            }
          },
          child: const Icon(Icons.group_add),
        );
      } else if (_tab1Selection == 1) {
        // Moments view - Create new post
        return FloatingActionButton(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () {
            context.push(RoutePaths.createPost);
          },
          child: const Icon(Icons.add),
        );
      } else {
        // Channels view - Create new channel
        return FloatingActionButton(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.primaryColor,
          elevation: 4,
          onPressed: () {
            context.push(RoutePaths.createChannel);
          },
          child: const Icon(CupertinoIcons.add),
        );
      }
    } else if (_currentIndex == 2) {
      // Marketplace tab - Create new listing
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateListingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      );
    } else if (_currentIndex == 3) {
      // Status tab - Navigate to create status screen
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () {
          context.push(RoutePaths.createStatus);
        },
        child: const Icon(Icons.camera_alt),
      );
    }

    return const SizedBox.shrink();
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    Color appBarColor = modernTheme.surfaceColor ?? (isDarkMode ? Colors.grey[900]! : Colors.grey[50]!);
    Color textColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);

    // Get the title based on current tab
    // For Chats tab (index 0), show "WemaChat" instead of "Chats"
    String title = _currentIndex == 0 ? 'WemaChat' : _tabNames[_currentIndex];

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      // For index 1, show Groups/Channels switcher instead of title
      title: _currentIndex == 1
          ? _buildGroupsChannelsSwitcher(modernTheme, textColor)
          : Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
      actions: [
        // Profile button (visible on Chats tab only)
        if (_currentIndex == 0)
          IconButton(
            icon: Icon(
              CupertinoIcons.person_circle,
              color: iconColor,
              size: 26,
            ),
            onPressed: () {
              context.push(RoutePaths.myProfile);
            },
          ),
        // Three-dot menu
        _buildThreeDotMenu(modernTheme, iconColor),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          width: double.infinity,
          color: modernTheme.dividerColor ?? Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildThreeDotMenu(ModernThemeExtension modernTheme, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBgColor = isDark 
      ? modernTheme.surfaceColor!.withOpacity(0.98)
      : modernTheme.surfaceColor!.withOpacity(0.96);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: iconColor,
        size: 26,
      ),
      color: menuBgColor,
      elevation: 8,
      surfaceTintColor: modernTheme.primaryColor?.withOpacity(0.1),
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: modernTheme.dividerColor?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      onSelected: (String value) {
        switch (value) {
          case 'new_chat':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('New Chat - Coming Soon'),
                backgroundColor: modernTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'add_contact':
            Navigator.pushNamed(context, Constants.addContactScreen);
            break;
          case 'create_group':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Create Group - Coming Soon'),
                backgroundColor: modernTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'scan_qr':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Scan QR Code - Coming Soon'),
                backgroundColor: modernTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            break;
          case 'payment':
            Navigator.pushNamed(context, Constants.walletScreen);
            break;
          case 'my_profile':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyProfileScreen(),
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        _buildMenuItem(
          icon: CupertinoIcons.chat_bubble_2,
          title: 'New Chat',
          value: 'new_chat',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.person_add,
          title: 'Add Contact',
          value: 'add_contact',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.group,
          title: 'Create Group',
          value: 'create_group',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.qrcode,
          title: 'Scan QR Code',
          value: 'scan_qr',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.money_dollar_circle,
          title: 'Payment',
          value: 'payment',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.person_fill,
          title: 'My Profile',
          value: 'my_profile',
          modernTheme: modernTheme,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required ModernThemeExtension modernTheme,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: modernTheme.textColor,
            size: 22,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ModernThemeExtension modernTheme) {
    Color backgroundColor = modernTheme.surfaceColor ?? Colors.grey[100]!;
    Color borderColor = modernTheme.dividerColor ?? Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return _buildNavItem(index, modernTheme);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, ModernThemeExtension modernTheme) {
    final isSelected = _currentIndex == index;

    Color iconColor = isSelected
        ? (modernTheme.primaryColor ?? const Color(0xFF07C160))
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
    Color textColor = isSelected
        ? (modernTheme.textColor ?? Colors.black)
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);

    // Real unread count for Chats (index 0) and Groups (index 1)
    int unreadCount = 0;
    if (index == 0) {
      // Chats tab - get real unread count from chat provider
      final chatListState = ref.watch(chatListProvider);
      unreadCount = chatListState.when(
        data: (state) {
          final chatNotifier = ref.read(chatListProvider.notifier);
          return chatNotifier.getTotalUnreadMessagesCount();
        },
        loading: () => 0,
        error: (_, __) => 0,
      );
    } else if (index == 1) {
      // Groups tab - no unread tracking yet, set to 0
      unreadCount = 0;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.translucent,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    _tabIcons[index],
                    color: iconColor,
                    size: 26,
                  ),
                  // Unread badge
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFA5151), // WeChat red
                          borderRadius: BorderRadius.circular(9),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
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
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  const _KeepAliveWrapper({required this.child});
  
  final Widget child;

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}