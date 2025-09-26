// lib/main_screen/home_screen.dart (FIXED VERSION)

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/main_screen/discover_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // CRITICAL FIX: Keep state alive to prevent rebuilds
  @override
  bool get wantKeepAlive => true;
  
  int _currentIndex = 0;
  // REMOVED: PageController - using IndexedStack instead
  
  final List<String> _tabNames = [
    'Home',
    'Wallet', 
    'Profile'
  ];
  
  final List<IconData> _tabIcons = [
    CupertinoIcons.qrcode_viewfinder,
    CupertinoIcons.creditcard,
    CupertinoIcons.person
  ];

  @override
  void initState() {
    super.initState();
    // REMOVED: PageController initialization - using IndexedStack instead
    
    // Set initial SystemUI once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setSystemUIOverlayStyle();
      }
    });
  }

  @override
  void dispose() {
    // REMOVED: PageController disposal - using IndexedStack instead
    super.dispose();
  }

  // SIMPLIFIED: Single SystemUI method without complex conditional logic
  void _setSystemUIOverlayStyle() {
    if (!mounted) return;
    
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

  // Safe method to get modern theme with comprehensive fallback
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

  // PROFESSIONAL FIX: Instant navigation without intermediate screens
  void _onTabTapped(int index) {
    if (!mounted || index == _currentIndex) return;
    
    debugPrint('HomeScreen: Navigating from $_currentIndex to $index');
    
    // INSTANT: No animation, no intermediate screens shown
    setState(() {
      _currentIndex = index;
    });
  }
  
  // REMOVED: Page change handler - not needed with IndexedStack

  void _navigateToCreatePost() async {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (!mounted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final modernTheme = _getModernTheme();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isProfileTab = _currentIndex == 2;
    
    // CRITICAL FIX: Watch authentication state to handle profile screen properly
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isAppInitializing = ref.watch(isAppInitializingProvider);

    // Show loading while app is initializing
    if (isAppInitializing) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isProfileTab,
      backgroundColor: modernTheme.backgroundColor,
      
      // Show AppBar for home and wallet tabs, hide for profile
      appBar: isProfileTab ? null : _buildAppBar(modernTheme, isDarkMode),
      
      // PROFESSIONAL FIX: IndexedStack prevents intermediate screen visibility
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home tab (index 0) - Users List
          _KeepAliveWrapper(child: const DiscoverScreen()),
          // Wallet tab (index 1) - Wallet Screen  
          _KeepAliveWrapper(child: const WalletScreen()),
          // Profile tab (index 2) - MyProfileScreen
          _KeepAliveWrapper(child: const MyProfileScreen()),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNav(modernTheme),
    );
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
        ? (modernTheme.primaryColor ?? const Color(0xFFFE2C55))
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
    Color textColor = isSelected 
        ? (modernTheme.primaryColor ?? const Color(0xFFFE2C55))
        : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: Container(
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
}

// CRITICAL FIX: Wrapper to keep screen states alive
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