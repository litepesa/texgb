// lib/main_screen/home_screen.dart (Updated for TikTok-style authentication system)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
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
    'Home', // Index 0 - List
    'Inbox', // Index 1 - Inbox
    'Profile' // Index 2 - Profile
  ];

  final List<IconData> _tabIcons = [
    CupertinoIcons.qrcode_viewfinder,
    CupertinoIcons.bubble_left_bubble_right, // Inbox
    CupertinoIcons.person // Me/Profile
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSystemUI();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Safe method to get modern theme with fallback
  ModernThemeExtension _getModernTheme() {
    if (!mounted) {
      // Provide a fallback theme when not mounted
      return _getFallbackTheme();
    }

    try {
      return context.modernTheme;
    } catch (e) {
      debugPrint('Modern theme error: $e');
      return _getFallbackTheme();
    }
  }

  // Fallback theme when extension fails
  ModernThemeExtension _getFallbackTheme() {
    final isDark =
        mounted ? Theme.of(context).brightness == Brightness.dark : false;

    return ModernThemeExtension(
      primaryColor: Colors.blue,
      backgroundColor: isDark ? Colors.black : Colors.white,
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
    );
  }

  void _onTabTapped(int index) {
    if (!mounted) return;

    // Store previous index for navigation management
    _previousIndex = _currentIndex;

    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    // Special handling for Profile tab to prevent black bar
    if (index == 2 && mounted) {
      // Force update system UI for Profile tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSystemUI();

          // Apply additional times for Profile tab specifically
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _currentIndex == 2) {
              _updateSystemUI();
            }
          });

          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _currentIndex == 2) {
              _updateSystemUI();
            }
          });
        }
      });
    } else if (mounted) {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Use jumpToPage to avoid showing intermediate pages
    if (mounted) {
      _isPageAnimating = true;
      try {
        _pageController.jumpToPage(index);
      } catch (e) {
        // Fallback to animateToPage if jumpToPage fails
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      // Reset animation flag after a brief delay
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _isPageAnimating = false;
        }
      });
    }
  }

  void _updateSystemUI() {
    if (!mounted) return;

    try {
      if (_currentIndex == 2) {
        // Profile screen - special handling to prevent black bar
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Force transparent navigation bar for Profile tab
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent, // Force transparent
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));

        // Apply multiple times to ensure it sticks for Profile tab
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _currentIndex == 2) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarContrastEnforced: false,
            ));
          }
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _currentIndex == 2) {
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
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
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));
      }
    } catch (e) {
      debugPrint('System UI update error: $e');
    }
  }

  void _onPageChanged(int index) {
    if (!mounted || _isPageAnimating) return;

    // Store previous index before updating
    _previousIndex = _currentIndex;

    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    // Special handling for Profile tab
    if (index == 2 && mounted) {
      // Force update system UI for Profile tab with multiple attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSystemUI();

          // Apply additional times for Profile tab specifically
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && _currentIndex == 2) {
              _updateSystemUI();
            }
          });

          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && _currentIndex == 2) {
              _updateSystemUI();
            }
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _currentIndex == 2) {
              _updateSystemUI();
            }
          });
        }
      });
    } else if (mounted) {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final modernTheme = _getModernTheme();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isProfileTab = _currentIndex == 2;
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
          // Channels tab (index 0) - Uses current theme (Users List)
          Container(
            color: modernTheme.backgroundColor,
            child: const UsersListScreen(),
          ),
          // Inbox tab (index 1) - Shows app bar and uses normal theme
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: const ChatsTab(),
          ),
          // Profile tab (index 2) - Let MyProfileScreen handle its own authentication
          const MyProfileScreen(),
        ],
      ),

      bottomNavigationBar: _buildBottomNav(modernTheme),

      // FAB for each tab with different functionality
      floatingActionButton: _buildFab(modernTheme),
    );
  }

  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Index 0 - Videos Feed FAB
      return FloatingActionButton(
        heroTag: "videos_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _navigateToVideosFeed(),
        child: const Icon(Icons.video_library_outlined),
      );
    } else if (_currentIndex == 1) {
      // Index 1 - Contacts FAB
      return FloatingActionButton(
        heroTag: "contacts_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _navigateToContacts(),
        child: const Icon(CupertinoIcons.person_add),
      );
    } else if (_currentIndex == 2) {
      // Index 2 - Create Post FAB
      return FloatingActionButton(
        heroTag: "create_post_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _navigateToCreatePost(),
        child: const Icon(Icons.add_box_outlined),
      );
    }

    return const SizedBox.shrink();
  }

  // Navigation methods for FABs
  void _navigateToVideosFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideosFeedScreen(),
      ),
    );
  }

  void _navigateToContacts() {
    Navigator.pushNamed(context, Constants.contactsScreen);
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  // Simple bottom navigation
  Widget _buildBottomNav(ModernThemeExtension modernTheme) {
    Color backgroundColor = modernTheme.surfaceColor ?? Colors.grey[100]!;
    Color? borderColor = modernTheme.dividerColor ?? Colors.grey[300];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: borderColor!,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              return _buildNavItem(
                index,
                modernTheme,
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
  ) {
    final isSelected = _currentIndex == index;

    Color iconColor = isSelected
        ? (modernTheme.primaryColor ?? Colors.blue)
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
    Color textColor = isSelected
        ? (modernTheme.primaryColor ?? Colors.blue)
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: Container(
        // Expand the tap area while keeping the content centered
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _tabIcons[index],
              color: iconColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              _tabNames[index],
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(
      ModernThemeExtension modernTheme, bool isDarkMode) {
    Color appBarColor = modernTheme.surfaceColor ??
        (isDarkMode ? Colors.grey[900]! : Colors.white);
    Color textColor =
        modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.primaryColor ?? Colors.blue;

    // Always show the main WeiBao微宝 branding for all tabs with app bar
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
}
