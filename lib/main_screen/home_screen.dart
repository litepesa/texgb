// lib/main_screen/home_screen.dart (RESTRUCTURED VERSION)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/groups/screens/groups_tab.dart';
import 'package:textgb/features/status/screens/status_tab.dart';
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
  int _previousIndex = 0;
  final PageController _pageController = PageController();
  bool _isPageAnimating = false;
  
  final ValueNotifier<double> _videoProgressNotifier = ValueNotifier<double>(0.0);
  
  final List<String> _tabNames = [
    'Chats',      // Index 0 - Chats (Coming Soon)
    'Groups',     // Index 1 - Groups (Coming Soon)
    'Status',     // Index 2 - Status (Coming Soon)
    'Shops',      // Index 3 - Marketplace Feed
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.bubble_left_bubble_right,           // Chats
    Icons.group_outlined,                             // Groups
    Icons.donut_large_rounded,                       // Status
    Icons.store_mall_directory_outlined,            // Shops
  ];

  final GlobalKey<VideosFeedScreenState> _feedScreenKey = GlobalKey<VideosFeedScreenState>();

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
    _videoProgressNotifier.dispose();
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
      primaryColor: const Color(0xFFFE2C55),
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
              Icons.construction_outlined,
              size: 80,
              color: modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
    
    // Store previous index
    _previousIndex = _currentIndex;
    
    HapticFeedback.lightImpact();
    
    if (_currentIndex == 3) {
      try {
        _feedScreenKey.currentState?.onScreenBecameInactive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }
    
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
    
    if (_currentIndex == 3) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            _feedScreenKey.currentState?.onScreenBecameActive();
          } catch (e) {
            debugPrint('Feed screen lifecycle error: $e');
          }
        }
      });
    }
  }

  void _setSystemUIOverlayStyle() {
    if (!mounted) return;
    
    try {
      if (_currentIndex == 3) {
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));
      } else {
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
    } catch (e) {
      debugPrint('System UI update error: $e');
    }
  }

  void _onPageChanged(int index) {
    // Only process page changes that aren't from programmatic jumps
    if (_isPageAnimating) return;
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
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
    final isVideosTab = _currentIndex == 3;
    
    // ✅ Check if app is still initializing
    final isAppInitializing = ref.watch(isAppInitializingProvider);

    // ✅ Show branded loading screen ONLY during initial app startup
    if (isAppInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/branding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '微宝 WeiBao',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Color(0xFFFE2C55),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isVideosTab,
      backgroundColor: isVideosTab ? Colors.black : modernTheme.backgroundColor,
      
      appBar: isVideosTab ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Chats tab (index 0)
          _KeepAliveWrapper(
            child: const ChatsTab(),
          ),
          // Groups tab (index 1)
          _KeepAliveWrapper(
            child: const GroupsTab(),
          ),
          // Status tab (index 2)
          _KeepAliveWrapper(
            child: const StatusTab(),
          ),
          // Videos tab (index 3) - Videos Feed (original functionality)
          _KeepAliveWrapper(
            child: Container(
              color: Colors.black,
              child: VideosFeedScreen(
                key: _feedScreenKey,
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }

  // Show FAB on Chats, Groups, and Status tabs only (NOT on Videos tab)
  bool _shouldShowFab() {
    return _currentIndex == 0 || _currentIndex == 1 || _currentIndex == 2;
  }

  PreferredSizeWidget _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    Color appBarColor = modernTheme.surfaceColor ?? (isDarkMode ? Colors.grey[900]! : Colors.white);
    Color textColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.primaryColor ?? const Color(0xFFFE2C55);

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Wei",
              style: TextStyle(
                color: textColor,          
                fontWeight: FontWeight.bold,
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
      ),
      actions: [
        _buildThreeDotMenu(modernTheme),
        const SizedBox(width: 16),
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
      ],
    );
  }

  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Chats tab - Single FAB that does nothing for now
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => Navigator.pushNamed(context, Constants.contactsScreen),
        child: const Icon(CupertinoIcons.bubble_left_bubble_right),
      );
    } else if (_currentIndex == 1) {
      // Groups tab - Single FAB that does nothing for now
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () {
          // Does nothing for now
          debugPrint('Groups FAB pressed - Coming soon');
        },
        child: const Icon(Icons.group_add),
      );
    } else if (_currentIndex == 2) {
      // Status tab - Single FAB that does nothing for now
      return FloatingActionButton(
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () {
          // Does nothing for now
          debugPrint('Status FAB pressed - Coming soon');
        },
        child: const Icon(Icons.camera_alt),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildBottomNav(ModernThemeExtension modernTheme) {
    final isVideosTab = _currentIndex == 3;
    
    Color backgroundColor;
    Color? borderColor;
    
    if (isVideosTab) {
      backgroundColor = Colors.black;
      borderColor = null;
    } else {
      backgroundColor = modernTheme.surfaceColor ?? Colors.grey[100]!;
      borderColor = modernTheme.dividerColor ?? Colors.grey[300];
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isVideosTab && borderColor != null)
            Container(
              height: 1,
              width: double.infinity,
              color: borderColor,
            ),
          if (isVideosTab)
            _buildVideoProgressIndicator(),
          
          Container(
            height: 60 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return _buildNavItem(
                  index,
                  modernTheme,
                  isVideosTab,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoProgressIndicator() {
    return ValueListenableBuilder<double>(
      valueListenable: _videoProgressNotifier,
      builder: (context, progress, child) {
        return Container(
          height: 1,
          width: double.infinity,
          color: Colors.grey.withOpacity(0.3),
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

  Widget _buildNavItem(
    int index,
    ModernThemeExtension modernTheme,
    bool isVideosTab,
  ) {
    final isSelected = _currentIndex == index;
    
    Color iconColor;
    Color textColor;
    
    if (isVideosTab) {
      iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
      textColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
    } else {
      iconColor = isSelected 
          ? (modernTheme.primaryColor ?? const Color(0xFFFE2C55)) 
          : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
      textColor = isSelected 
          ? (modernTheme.primaryColor ?? const Color(0xFFFE2C55)) 
          : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
    }

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
                color: isSelected && !isVideosTab
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