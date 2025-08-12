// lib/main_screen/home_screen.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/features/moments/screens/moments_feed_screen.dart';
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
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final PageController _pageController = PageController();
  bool _isPageAnimating = false;
  
  // Video progress tracking
  final ValueNotifier<double> _videoProgressNotifier = ValueNotifier<double>(0.0);
  
  // Updated tab configuration
  final List<String> _tabNames = [
    'Home',      // Index 0 - Moments Feed (hidden app bar, black background)
    'Channels',  // Index 1 - Channels List
    '',          // Index 2 - Post (no label, special design)
    'Chats',     // Index 3 - Chats only
    'Profile'    // Index 4 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    Icons.home_rounded,                  // Home - Moments
    Icons.radio_button_on_rounded,       // Channels
    Icons.add,                           // Post (will be styled specially)
    CupertinoIcons.chat_bubble_2,        // Chats
    Icons.person_outline                 // Me/Profile
  ];

  // Feed screen controller for lifecycle management
  final GlobalKey<MomentsFeedScreenState> _feedScreenKey = GlobalKey<MomentsFeedScreenState>();

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
    _videoProgressNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Handle special post button
    if (index == 2) {
      _navigateToCreatePost();
      return;
    }

    // Store previous index for navigation management
    _previousIndex = _currentIndex;
    
    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Leaving feed screen
      _feedScreenKey.currentState?.onScreenBecameInactive();
    }
    
    setState(() {
      _currentIndex = index;
    });

    // Special handling for Profile tab to prevent black bar
    if (index == 4) {
      // Force update system UI for Profile tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
        
        // Apply additional times for Profile tab specifically
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _currentIndex == 4) {
            _updateSystemUI();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _currentIndex == 4) {
            _updateSystemUI();
          }
        });
      });
    } else {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Entering feed screen
      Future.delayed(const Duration(milliseconds: 100), () {
        _feedScreenKey.currentState?.onScreenBecameActive();
      });
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
    if (_currentIndex == 0) {
      // Home/Moments screen - black background with light status bar
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    } else if (_currentIndex == 4) {
      // Profile screen - special handling to prevent black bar
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      // Force transparent navigation bar for Profile tab
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent, // Force transparent
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
      
      // Apply multiple times to ensure it sticks for Profile tab
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _currentIndex == 4) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ));
        }
      });
      
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _currentIndex == 4) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          ));
        }
      });
    } else {
      // Other screens - use theme-appropriate colors
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
  }
  
  void _onPageChanged(int index) {
    // Only process page changes that aren't from programmatic jumps
    if (_isPageAnimating) return;
    
    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Leaving feed screen
      _feedScreenKey.currentState?.onScreenBecameInactive();
    }
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });

    // Special handling for Profile tab
    if (index == 4) {
      // Force update system UI for Profile tab with multiple attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
        
        // Apply additional times for Profile tab specifically
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _currentIndex == 4) {
            _updateSystemUI();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _currentIndex == 4) {
            _updateSystemUI();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _currentIndex == 4) {
            _updateSystemUI();
          }
        });
      });
    } else {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Entering feed screen
      Future.delayed(const Duration(milliseconds: 100), () {
        _feedScreenKey.currentState?.onScreenBecameActive();
      });
    }
  }

  void _navigateToCreatePost() async {
    // Pause feed if active
    if (_currentIndex == 0) {
      _feedScreenKey.currentState?.onScreenBecameInactive();
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    // Resume feed if returning to it
    if (result == true && _currentIndex == 0) {
      _feedScreenKey.currentState?.onScreenBecameActive();
    }
  }

  void _navigateToWallet() async {
    // Pause feed if active
    if (_currentIndex == 0) {
      _feedScreenKey.currentState?.onScreenBecameInactive();
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WalletScreen(),
      ),
    );

    // Resume feed if returning to it
    if (_currentIndex == 0) {
      _feedScreenKey.currentState?.onScreenBecameActive();
    }
  }

  // Handle channels dropdown menu actions
  void _handleChannelsMenuAction(String action) {
    switch (action) {
      case 'search':
        // Navigate to channel search
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search Channels')),
        );
        break;
      case 'my_channels':
        // Navigate to my channels
        Navigator.pushNamed(context, Constants.myChannelScreen);
        break;
      case 'following':
        // Show following channels
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Following Channels')),
        );
        break;
      case 'create':
        // Navigate to create channel
        Navigator.pushNamed(context, Constants.createChannelScreen);
        break;
      case 'settings':
        // Navigate to channel settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Channel Settings')),
        );
        break;
    }
  }

  // Video progress indicator widget
  Widget _buildVideoProgressIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: _videoProgressNotifier,
      builder: (context, progress, child) {
        return Container(
          height: 1, // Thin progress bar
          width: double.infinity,
          color: Colors.grey.withOpacity(0.3), // Background track
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 2,
              width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isHomeTab = _currentIndex == 0;
    final isProfileTab = _currentIndex == 4;
    final isChannelsTab = _currentIndex == 1;
    final isChatsTab = _currentIndex == 3;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final chatsAsyncValue = ref.watch(chatStreamProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isHomeTab || isChannelsTab || isProfileTab,
      backgroundColor: isHomeTab ? Colors.black : modernTheme.backgroundColor,
      
      // Hide AppBar for home, channels, and profile tabs
      appBar: (isHomeTab || isChannelsTab || isProfileTab) ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Home tab (index 0) - Moments Feed with black background
          Container(
            color: Colors.black,
            child: MomentsFeedScreen(
              key: _feedScreenKey,
            ),
          ),
          // Channels tab (index 1) - Channels List
          Container(
            color: modernTheme.backgroundColor,
            child: const ChannelsListScreen(),
          ),
          // Post tab (index 2) - This should never be shown as we navigate directly
          Container(
            color: modernTheme.backgroundColor,
            child: const Center(
              child: Text('Create Post'),
            ),
          ),
          // Chats tab (index 3) - Chats only
          Container(
            color: modernTheme.surfaceColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          // Profile tab (index 4)
          const MyProfileScreen(),
        ],
      ),
      
      bottomNavigationBar: _buildTikTokBottomNav(modernTheme, chatsAsyncValue),
      
      // FAB for wallet access
      floatingActionButton: _currentIndex == 3 ? FloatingActionButton(
        onPressed: _navigateToWallet,
        backgroundColor: modernTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(CupertinoIcons.creditcard),
        tooltip: 'Wallet',
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // TikTok-style bottom navigation with video progress indicator
  Widget _buildTikTokBottomNav(ModernThemeExtension modernTheme, AsyncValue<List<ChatModel>> chatsAsyncValue) {
    final isHomeTab = _currentIndex == 0;
    
    Color backgroundColor;
    Color? borderColor;
    
    if (isHomeTab) {
      backgroundColor = Colors.black;
      borderColor = null;
    } else {
      backgroundColor = modernTheme.surfaceColor!;
      borderColor = modernTheme.dividerColor;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: (isHomeTab || borderColor == null) ? null : Border(
          top: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video progress indicator for home tab only
          if (isHomeTab)
            _buildVideoProgressIndicator(),
          
          // Bottom navigation content
          SafeArea(
            top: false,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) {
                    // Special post button
                    return _buildPostButton(modernTheme, isHomeTab);
                  }
                  
                  return _buildNavItem(
                    index,
                    modernTheme,
                    isHomeTab,
                    chatsAsyncValue,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton(ModernThemeExtension modernTheme, bool isHomeTab) {
    return GestureDetector(
      onTap: () => _navigateToCreatePost(),
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

  Widget _buildNavItem(
    int index,
    ModernThemeExtension modernTheme,
    bool isHomeTab,
    AsyncValue<List<ChatModel>> chatsAsyncValue,
  ) {
    final isSelected = _currentIndex == index;
    
    // Chats tab is at index 3 - show unread count for direct chats only
    if (index == 3) {
      return chatsAsyncValue.when(
        data: (chats) {
          // Calculate unread count from direct chats only (excluding groups)
          final directChats = chats.where((chat) => !chat.isGroup).toList();
          final chatUnreadCount = directChats.fold<int>(
            0, 
            (sum, chat) => sum + chat.getDisplayUnreadCount()
          );
          
          return _buildNavItemWithBadge(
            index, 
            isSelected, 
            modernTheme, 
            isHomeTab,
            chatUnreadCount
          );
        },
        loading: () => _buildDefaultNavItem(index, isSelected, modernTheme, isHomeTab),
        error: (_, __) => _buildDefaultNavItem(index, isSelected, modernTheme, isHomeTab),
      );
    }
    
    // For other tabs, no badge needed
    return _buildDefaultNavItem(index, isSelected, modernTheme, isHomeTab);
  }

  Widget _buildNavItemWithBadge(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    bool isHomeTab,
    int unreadCount,
  ) {
    Color iconColor;
    Color textColor;
    
    if (isHomeTab) {
      // Home tab colors
      iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
      textColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
    } else {
      // Other tabs - use current theme
      iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
      textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 60, // Fixed width to prevent overflow
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

  Widget _buildDefaultNavItem(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
    bool isHomeTab,
  ) {
    Color iconColor;
    Color textColor;
    
    if (isHomeTab) {
      // Home tab colors
      iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
      textColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
    } else {
      // Other tabs - use current theme
      iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
      textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 60, // Fixed width to prevent overflow
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
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    String title = 'WeiBao';
    final isChannelsTab = _currentIndex == 1;
    final isChatsTab = _currentIndex == 3;
    
    // Set title based on current tab
    switch (_currentIndex) {
      case 1:
        title = 'Channels';
        break;
      case 3:
        title = 'Chats';
        break;
      default:
        title = 'WeiBao';
    }

    Color appBarColor = modernTheme.surfaceColor!;
    Color textColor = modernTheme.textColor!;
    Color iconColor = modernTheme.primaryColor!;

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      title: _currentIndex == 1 || _currentIndex == 3
          ? _currentIndex == 1
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A884), Color(0xFF00C49A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00A884).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              : Text(
                  title,
                  style: TextStyle(
                    color: textColor,
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
                      color: textColor,          
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: "Bao",
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
      actions: _currentIndex == 1 ? [
        // Search icon for channels tab
        IconButton(
          icon: Icon(CupertinoIcons.search, color: iconColor),
          onPressed: () {
            // Handle search action
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search channels')),
            );
          },
        ),
        // Create channel icon
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: iconColor),
          onPressed: () {
            Navigator.pushNamed(context, Constants.createChannelScreen);
          },
        ),
        // Dropdown menu with 3 dots
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: iconColor),
          onSelected: _handleChannelsMenuAction,
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
              value: 'search',
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
                      Icons.search_outlined,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Search Channels',
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
              value: 'my_channels',
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
                    'My Channels',
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
              value: 'following',
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
                      Icons.favorite_outline,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Following',
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
              value: 'create',
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
                      Icons.add_circle_outline,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Create Channel',
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
        const SizedBox(width: 8),
      ] : isChatsTab ? [
        // Chats tab actions
        // Search icon for chats tab
        IconButton(
          icon: Icon(Icons.search, color: iconColor),
          onPressed: () {
            // Handle search action for chats
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search chats')),
            );
          },
        ),
        // New chat icon
        IconButton(
          icon: Icon(CupertinoIcons.chat_bubble_2, color: iconColor),
          onPressed: () {
            Navigator.pushNamed(context, Constants.contactsScreen);
          },
        ),
        // Dropdown menu for chats
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: iconColor),
          onSelected: (String value) {
            switch (value) {
              case 'new_group':
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create new group')),
                );
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