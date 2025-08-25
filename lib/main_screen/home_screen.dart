// lib/main_screen/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/dramas/screens/discover_screen.dart';
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
    'Discover',
    'Wallet',
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    Icons.explore_rounded,
    Icons.account_balance_rounded,
    CupertinoIcons.person
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
    
    // Use standard system UI for all tabs
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
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
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false, // Don't extend for any tab
      backgroundColor: modernTheme.backgroundColor, // Standard background for all tabs
      
      // Show app bar for all tabs (index 0, 1, and 2)
      appBar: _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Discover tab (index 0) - Drama Discovery Screen
          Container(
            color: modernTheme.backgroundColor,
            child: const DiscoverScreen(),
          ),
          
          // Wallet tab (index 1) - Wallet Screen
          Container(
            color: modernTheme.backgroundColor,
            child: const WalletScreen(),
          ),
          
          // Profile tab (index 2) - Profile Screen
          Container(
            color: modernTheme.backgroundColor,
            child: const MyProfileScreen(),
          ),
        ],
      ),
      
      bottomNavigationBar: _buildCustomBottomNav(modernTheme),
      
      // Admin FAB - only show on Discover tab for admin users
      floatingActionButton: (_currentIndex == 0 && isAdmin) ? _buildAdminFab(modernTheme) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildAdminFab(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), // Above bottom nav
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Constants.adminDashboardScreen),
        backgroundColor: const Color(0xFFFE2C55),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.admin_panel_settings, size: 20),
        label: const Text(
          'Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        heroTag: "admin_fab",
      ),
    );
  }

  Widget _buildCustomBottomNav(ModernThemeExtension modernTheme) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use standard surface color for all tabs
    final bottomNavColor = isDarkMode 
        ? modernTheme.surfaceColor 
        : Colors.white;
            
    final dividerColor = modernTheme.dividerColor;
    
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
    
    return _buildDefaultBottomNavItem(index, isSelected, modernTheme);
  }

  Widget _buildDefaultBottomNavItem(
    int index, 
    bool isSelected, 
    ModernThemeExtension modernTheme
  ) {
    // Use standard theming for all tabs
    final iconColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;
    final textColor = isSelected ? modernTheme.primaryColor! : modernTheme.textSecondaryColor!;

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
  
  // Build consistent app bar with only main logo branding
  PreferredSizeWidget? _buildAppBar(ModernThemeExtension modernTheme, bool isDarkMode) {
    return AppBar(
      backgroundColor: modernTheme.surfaceColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: RichText(
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
      ),
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