// lib/main_screen/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/screens/my_channel_screen.dart';
//import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/recommended_posts_screen.dart';
import 'package:textgb/features/chat/screens/chats_tab.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/moments/screens/moments_recommendations_screen.dart';
import 'package:textgb/features/moments/screens/my_moments_screen.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/features/profile/screens/my_profile_screen.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
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
    'Home',
    'Discover',
    'Wallet'
  ];
  
  final List<IconData> _tabIcons = [
    Icons.video_library_outlined,
    CupertinoIcons.compass,
    Icons.account_balance_rounded
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // For index 0 (Home/Channels Feed), use black system UI for TikTok-style experience
    if (_currentIndex == 0) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    } else {
      // For other tabs, use standard system UI
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ));
    }
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

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: _currentIndex == 0, // Only extend for Home tab
      backgroundColor: _currentIndex == 0 
          ? Colors.black // Black background for Home tab (TikTok-style)
          : _currentIndex == 1 
              ? modernTheme.backgroundColor // Standard background for Discover
              : modernTheme.backgroundColor, // Standard background for Profile
      
      // Only show app bar for index 1 (Discover tab) and index 2 (Wallet tab)
      appBar: (_currentIndex == 1 || _currentIndex == 2) ? _buildAppBar(modernTheme, isDarkMode) : null,
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Home tab (index 0) - Channels Feed Screen without app bar
          const ChannelsFeedScreen(),
          
          // Discover tab (index 1) - Channels List Screen with app bar (no dropdown)
          Container(
            color: modernTheme.backgroundColor,
            child: const RecommendedPostsScreen(),
          ),
          
          // Wallet tab (index 2) - Wallet Screen with app bar (no dropdown)
          Container(
            color: modernTheme.backgroundColor,
            child: const WalletScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildCustomBottomNav(modernTheme),
      
      floatingActionButton: _shouldShowFab() ? _buildFab(modernTheme) : null,
    );
  }

  Widget _buildCustomBottomNav(ModernThemeExtension modernTheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use black background for index 0 (Home), standard surface color for others
    final bottomNavColor = _currentIndex == 0 
        ? Colors.black
        : isDarkMode 
            ? modernTheme.surfaceColor 
            : Colors.white;
            
    final dividerColor = _currentIndex == 0 
        ? Colors.grey.withOpacity(0.3) // Subtle divider for black background
        : modernTheme.dividerColor;
    
    return Container(
      decoration: BoxDecoration(
        color: bottomNavColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            width: double.infinity,
            color: dividerColor,
          ),
          Container(
            height: 60 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) {
                return _buildBottomNavItem(index, modernTheme);
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNavItem(
    int index, 
    ModernThemeExtension modernTheme,
  ) {
    final isSelected = _currentIndex == index;
    
    // No badge functionality needed - just show default bottom nav items
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }

  Widget _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    // For index 0 (Home tab with black background), use white colors for better contrast
    final iconColor = _currentIndex == 0 
        ? (isSelected ? Colors.white : Colors.grey) // White/grey for black background
        : (isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!);
        
    final textColor = _currentIndex == 0 
        ? (isSelected ? Colors.white : Colors.grey) // White/grey for black background
        : (isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!);

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
                  ? (_currentIndex == 0 
                      ? Colors.white.withOpacity(0.2) // Semi-transparent white for black background
                      : modernTheme.primaryColor!.withOpacity(0.2))
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
  
  // Show FAB only on Wallet tab (index 2)
  bool _shouldShowFab() {
    return _currentIndex == 2;
  }
  
  // Only build app bar for index 1 (Discover tab) and index 2 (Wallet tab) - simplified without dropdown menu
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    // Different titles for different tabs
    String title = '';
    if (_currentIndex == 1) {
      // Discover tab - show brand name
      return AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: _buildAppBarTitle(modernTheme),
        // No actions - removed the three-dot menu completely
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            width: double.infinity,
            color: modernTheme.dividerColor,
          ),
        ),
      );
    } else if (_currentIndex == 2) {
      // Wallet tab - show brand name title
      return AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: _buildAppBarTitle(modernTheme),
        // No actions - removed the three-dot menu completely
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
    
    return null;
  }

  Widget _buildAppBarTitle(ModernThemeExtension modernTheme) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Wei",
            style: TextStyle(
              color: modernTheme.textColor,          
              fontWeight: FontWeight.bold,
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
    );
  }
  
  Widget _buildFab(ModernThemeExtension modernTheme) {
    if (_currentIndex == 2) {
      // Wallet tab - Navigate to Profile FAB
      return FloatingActionButton(
        heroTag: "profile_fab",
        backgroundColor: modernTheme.backgroundColor,
        foregroundColor: modernTheme.primaryColor,
        elevation: 4,
        onPressed: () => _navigateToProfile(),
        child: const Icon(CupertinoIcons.person),
      );
    }
    
    return const SizedBox.shrink();
  }

  // Channel post creation method
  void _createChannelPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  // Navigate to profile method
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProfileScreen(),
      ),
    );
  }
}