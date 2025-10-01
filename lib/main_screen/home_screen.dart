// lib/main_screen/home_screen.dart (OPTIMIZED VERSION)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/users/screens/live_users_screen.dart';
import 'package:textgb/features/videos/screens/videos_feed_screen.dart';
import 'package:textgb/features/users/screens/users_list_screen.dart';
import 'package:textgb/features/videos/screens/create_post_screen.dart';
import 'package:textgb/features/users/screens/my_profile_screen.dart';
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
  
  final ValueNotifier<double> _videoProgressNotifier = ValueNotifier<double>(0.0);
  
  final List<String> _tabNames = [
    'Home',      // Index 0 - Videos Feed (hidden app bar, black background)
    'Sellers',  // Index 1 - Users List
    '',          // Index 2 - Post (no label, special design)
    'Live',     // Index 3 - Featured Screen
    'Profile'    // Index 4 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    Icons.home_rounded,                    // Home
    Icons.radio_button_checked_rounded,   // Users
    Icons.add,                           // Post 
    CupertinoIcons.dot_radiowaves_left_right,               // Trending
    Icons.person_2_outlined            // Profile
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
      _navigateToCreatePost();
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
    
    if (_currentIndex == 0) {
      try {
        _feedScreenKey.currentState?.onScreenBecameInactive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    _setSystemUIOverlayStyle();
    
    if (_currentIndex == 0) {
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
      if (_currentIndex == 0) {
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

  void _navigateToCreatePost() async {
    if (!mounted) return;
    
    HapticFeedback.lightImpact();
    
    if (_currentIndex == 0) {
      try {
        _feedScreenKey.currentState?.onScreenBecameInactive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );

    if (result == true && _currentIndex == 0 && mounted) {
      try {
        _feedScreenKey.currentState?.onScreenBecameActive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }
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
    final isHomeTab = _currentIndex == 0;
    final isProfileTab = _currentIndex == 4;
    
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
      extendBodyBehindAppBar: isHomeTab || isProfileTab,
      backgroundColor: isHomeTab ? Colors.black : modernTheme.backgroundColor,
      
      appBar: (isHomeTab || isProfileTab) ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home tab (index 0) - Videos Feed
          _KeepAliveWrapper(
            child: Container(
              color: Colors.black,
              child: VideosFeedScreen(
                key: _feedScreenKey,
              ),
            ),
          ),
          // Sellers tab (index 1) - Users List
          _KeepAliveWrapper(
            child: Container(
              color: modernTheme.backgroundColor,
              child: const UsersListScreen(),
            ),
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
          // Live tab (index 3)
          _KeepAliveWrapper(
            child: Container(
              color: modernTheme.backgroundColor,
              child: const LiveUsersScreen(),
            ),
          ),
          // Profile tab (index 4)
          _buildProfileTab(modernTheme),
        ],
      ),
      
      bottomNavigationBar: _buildTikTokBottomNav(modernTheme),
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

  Widget _buildTikTokBottomNav(ModernThemeExtension modernTheme) {
    final isHomeTab = _currentIndex == 0;
    
    Color backgroundColor;
    Color? borderColor;
    
    if (isHomeTab) {
      backgroundColor = Colors.black;
      borderColor = null;
    } else {
      backgroundColor = modernTheme.surfaceColor ?? Colors.grey[100]!;
      borderColor = modernTheme.dividerColor ?? Colors.grey[300];
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
          if (isHomeTab)
            _buildVideoProgressIndicator(),
          
          SafeArea(
            top: false,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  if (index == 2) {
                    return _buildPostButton(modernTheme, isHomeTab);
                  }
                  
                  return _buildNavItem(
                    index,
                    modernTheme,
                    isHomeTab,
                  );
                }),
              ),
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
  ) {
    final isSelected = _currentIndex == index;
    
    Color iconColor;
    Color textColor;
    
    if (isHomeTab) {
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