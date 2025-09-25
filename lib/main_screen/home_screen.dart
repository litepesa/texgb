// lib/main_screen/home_screen.dart (Updated Version - Consistent AppBar Across All Tabs)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/main_screen/discover_screen.dart';
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
    'Home',              // Index 0 - Users List
    'Escrow',           // Index 1 - Wallet Screen (changed from Video Reactions)
    'Profile'          // Index 2 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.qrcode_viewfinder,            // Home
    Icons.account_balance_rounded,              // Wallet (changed from bubble icons)
    CupertinoIcons.person                      // Profile
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
    final isDark = mounted ? Theme.of(context).brightness == Brightness.dark : false;
    
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

    // Standard system UI update for all tabs
    if (mounted) {
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
      // Consistent system UI for all tabs
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
    if (!mounted || _isPageAnimating) return;
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    // Standard system UI update for all tabs
    if (mounted) {
      _updateSystemUI();
    }
  }

  void _navigateToCreatePost() async {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
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

    return Scaffold(
      extendBody: true,
      backgroundColor: modernTheme.backgroundColor,
      
      // Show AppBar for all tabs consistently
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Home tab (index 0) - Users List
          const DiscoverScreen(),
          // Wallet tab (index 1) - Wallet Screen
          const WalletScreen(),
          // Profile tab (index 2) - MyProfileScreen
          const MyProfileScreen(),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme),
      
      // Independent FAB implementation
      //floatingActionButton: _buildFab(modernTheme),
    );
  }

  // Independent FAB implementation
  /*Widget? _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 0) {
      // Home tab - Create post FAB (changed from no FAB)
      return FloatingActionButton(
        heroTag: "create_post_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: _navigateToCreatePost,
        child: const Icon(Icons.camera_alt_rounded),
      );
    }
    
    // Wallet tab (index 1) and Profile tab (index 2) - No FAB
    return null;
  }*/

  // Bottom navigation with 3 tabs
  Widget _buildBottomNav(ModernThemeExtension modernTheme) {
    Color backgroundColor = modernTheme.surfaceColor ?? Colors.grey[100]!;
    Color? borderColor = modernTheme.dividerColor ?? Colors.grey[300];
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor == null ? null : Border(
          top: BorderSide(
            color: borderColor,
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
    
    // All tabs use default nav item
    return _buildDefaultNavItem(index, isSelected, modernTheme);
  }

  Widget _buildDefaultNavItem(
    int index,
    bool isSelected,
    ModernThemeExtension modernTheme,
  ) {
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
            if (_tabNames[index].isNotEmpty)
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
  
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    Color appBarColor = modernTheme.surfaceColor ?? (isDarkMode ? Colors.grey[900]! : Colors.white);
    Color textColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.primaryColor ?? Colors.blue;

    // Show the main WeiBao branding for all tabs
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