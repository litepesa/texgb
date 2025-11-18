// lib/main_screen/home_screen.dart (UPDATED VERSION WITH FAB)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/channels/screens/channels_home_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/contacts/screens/contacts_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/videos/screens/recommended_posts_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen_v2.dart';
import 'package:textgb/main_screen/discover_screen.dart';
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
  
  final List<String> _tabNames = [  
    'Chats',        // Index 0 - Chats Tab (label)
    'Contacts',     // Index 1 - Contacts Screen
    '',             // Index 2 - Post (no label, special design)
    'Discover',     // Index 3 - Discover Screen
    'Profile'       // Index 4 - Profile
  ];
  
  final List<String> _appBarTitles = [
    'WemaChat',     // Index 0 - App name for Chats tab
    'Contacts',     // Index 1 - Contacts Screen
    '',             // Index 2 - Post (not used)
    'Discover',     // Index 3 - Discover Screen
    'My Profile'    // Index 4 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.chat_bubble_2,                 // Chats
    CupertinoIcons.person_2_square_stack,         // Contacts
    Icons.add,                                    // Post 
    CupertinoIcons.compass,                       // Discover
    CupertinoIcons.person                         // Profile
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

  Widget _buildProfileTab(ModernThemeExtension modernTheme) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isLoading = ref.watch(isAuthLoadingProvider);
    
    if (isLoading) {
      return Container(
        color: modernTheme.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: modernTheme.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!isAuthenticated || currentUser == null) {
      return Container(
        color: modernTheme.backgroundColor,
        child: const LoginRequiredWidget(
          title: 'Sign In Required',
          subtitle: 'Please sign in to view your profile and manage your content.',
          actionText: 'Sign In',
          icon: Icons.person,
        ),
      );
    }
    
    return _KeepAliveWrapper(child: const MyProfileScreen());
  }

  void _onTabTapped(int index) {
    if (!mounted || index == _currentIndex) return;
    
    if (index == 2) {
      _showPostOptions();
      return;
    }

    debugPrint('HomeScreen: Navigating from $_currentIndex to $index');
    
    if (index == 4) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final currentUser = ref.read(currentUserProvider);
      final isLoading = ref.read(isAuthLoadingProvider);
      
      debugPrint('HomeScreen: Profile Tab Access - Auth: $isAuthenticated, User: ${currentUser?.uid}, Loading: $isLoading');
      
      if (!isAuthenticated && !isLoading) {
        debugPrint('HomeScreen: Triggering auth check for profile tab');
        final authNotifier = ref.read(authenticationProvider.notifier);
        authNotifier.loadUserDataFromSharedPreferences();
      }
    }
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
    });
    
    _setSystemUIOverlayStyle();
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

  void _showPostOptions() {
    HapticFeedback.lightImpact();
    final modernTheme = _getModernTheme();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: modernTheme.textSecondaryColor?.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Create Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: modernTheme.textColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Channels Post option
              _buildPostOptionTile(
                icon: CupertinoIcons.play_rectangle_fill,
                title: 'Channels Post',
                subtitle: 'Share a video on your channel',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  context.push(RoutePaths.createPost);
                },
                modernTheme: modernTheme,
              ),
              
              // Moments Post option
              _buildPostOptionTile(
                icon: CupertinoIcons.camera_fill,
                title: 'Moments Post',
                subtitle: 'Share photos or videos with friends',
                color: const Color(0xFF007AFF),
                onTap: () {
                  Navigator.pop(context);
                  context.push(RoutePaths.createMoment);
                },
                modernTheme: modernTheme,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: modernTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: modernTheme.textSecondaryColor?.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
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
                'WemaChat',
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
      
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Chats tab (index 0)
          _KeepAliveWrapper(
            child: const ChatsTab(),
          ),
          // Contacts Screen (index 1)
          _KeepAliveWrapper(
            child: const ContactsScreen(),
          ),
          // Post tab (index 2) - Never shown (navigates directly)
          _KeepAliveWrapper(
            child: Container(
              color: modernTheme.backgroundColor,
              child: const Center(
                child: Text('Create Post'),
              ),
            ),
          ),
          // Status tab (index 3)
          _KeepAliveWrapper(
            child: const DiscoverScreen(),
          ),
          // Profile tab (index 4)
          _KeepAliveWrapper(
            child: const MyProfileScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme),
    );
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    Color appBarColor = modernTheme.surfaceColor ?? (isDarkMode ? Colors.grey[900]! : Colors.grey[50]!);
    Color textColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);

    // Get the AppBar title - use _appBarTitles instead of _tabNames
    String title = _appBarTitles[_currentIndex];

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        // Three-dot menu for tabs 0, 1, 3, 4
        if (_currentIndex != 2)
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

    // Different menu options based on current tab
    List<PopupMenuItem<String>> menuItems = [];
    
    if (_currentIndex == 0) {
      // Chats tab menu
      menuItems = [
        _buildMenuItem(
          icon: CupertinoIcons.chat_bubble_2,
          title: 'New Chat',
          value: 'new_chat',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.group,
          title: 'Create Group',
          value: 'create_group',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.person_add,
          title: 'Add Contact',
          value: 'add_contact',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.qrcode,
          title: 'Scan QR Code',
          value: 'scan_qr',
          modernTheme: modernTheme,
        ),
      ];
    } else if (_currentIndex == 1) {
      // Contacts tab menu
      menuItems = [
        _buildMenuItem(
          icon: CupertinoIcons.person_add,
          title: 'Add Contact',
          value: 'add_contact',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: Icons.sync_rounded,
          title: 'Sync Contacts',
          value: 'sync_contacts',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: Icons.block_rounded,
          title: 'Blocked Contacts',
          value: 'blocked_contacts',
          modernTheme: modernTheme,
        ),
      ];
    } else if (_currentIndex == 3) {
      // Discover tab menu
      menuItems = [
        _buildMenuItem(
          icon: CupertinoIcons.search,
          title: 'Search',
          value: 'search',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.money_dollar_circle,
          title: 'Wallet',
          value: 'wallet',
          modernTheme: modernTheme,
        ),
      ];
    } else if (_currentIndex == 4) {
      // Profile tab menu
      menuItems = [
        _buildMenuItem(
          icon: CupertinoIcons.pencil,
          title: 'Edit Profile',
          value: 'edit_profile',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.money_dollar_circle,
          title: 'Wallet',
          value: 'wallet',
          modernTheme: modernTheme,
        ),
        _buildMenuItem(
          icon: CupertinoIcons.settings,
          title: 'Settings',
          value: 'settings',
          modernTheme: modernTheme,
        ),
      ];
    }

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
        _handleMenuAction(value, modernTheme);
      },
      itemBuilder: (BuildContext context) => menuItems,
    );
  }

  void _handleMenuAction(String value, ModernThemeExtension modernTheme) {
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
        context.push(RoutePaths.addContact);
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
      case 'sync_contacts':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Syncing Contacts...'),
            backgroundColor: modernTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'blocked_contacts':
        context.push(RoutePaths.blockedContacts);
        break;
      case 'search':
        context.push(RoutePaths.search);
        break;
      case 'wallet':
        context.push(RoutePaths.wallet);
        break;
      case 'edit_profile':
        context.push(RoutePaths.editProfile);
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings - Coming Soon'),
            backgroundColor: modernTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
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
            children: List.generate(5, (index) {
              if (index == 2) {
                return _buildPostButton(modernTheme);
              }
              return _buildNavItem(index, modernTheme);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPostButton(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _showPostOptions(),
      child: Container(
        width: 45,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              modernTheme.primaryColor ?? const Color(0xFF07C160),
              (modernTheme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (modernTheme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
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

    // Dummy unread counts
    int unreadCount = 0;
    if (index == 0) unreadCount = 5; // Chats
    if (index == 3) unreadCount = 2; // Discover

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
              if (_tabNames[index].isNotEmpty)
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