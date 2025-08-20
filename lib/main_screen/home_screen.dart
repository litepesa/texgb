// lib/main_screen/home_screen.dart (Final Fix - Complete Null Safety)
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/channels/screens/channels_feed_screen.dart';
import 'package:textgb/features/channels/screens/channels_list_screen.dart';
import 'package:textgb/features/channels/screens/create_post_screen.dart';
import 'package:textgb/features/channels/screens/my_channel_screen.dart';
import 'package:textgb/features/channels/widgets/login_required_widget.dart';
import 'package:textgb/features/wallet/screens/wallet_screen.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/light_theme.dart';
import 'package:textgb/widgets/custom_icon_button.dart';

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
  
  final List<String> _tabNames = [
    'Home',      // Index 0 - Channels Feed (hidden app bar, black background)
    'Channels',  // Index 1 - Channels List
    '',          // Index 2 - Post (no label, special design)
    'Wallet',    // Index 3 - Wallet 
    'Profile'    // Index 4 - Profile
  ];
  
  final List<IconData> _tabIcons = [
    Icons.home,                        // Home
    Icons.radio_button_checked_rounded, // Channels
    Icons.add,                         // Post (will be styled specially)
    Icons.account_balance_rounded,     // Wallet
    Icons.person_2_outlined            // Me/Profile
  ];

  // Feed screen controller for lifecycle management
  final GlobalKey<ChannelsFeedScreenState> _feedScreenKey = GlobalKey<ChannelsFeedScreenState>();

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
    _videoProgressNotifier.dispose();
    super.dispose();
  }

  // Safe check if user is authenticated using the correct provider
  bool get _isAuthenticated {
    if (!mounted) return false;
    
    try {
      final authState = ref.read(authenticationProvider);
      return authState.value?.isSuccessful ?? false;
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
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
    
    // Handle special post button
    if (index == 2) {
      _navigateToCreatePost();
      return;
    }

    // Check authentication for certain tabs
    if (_requiresAuthentication(index)) {
      _showAuthenticationDialog(index);
      return;
    }

    // Store previous index for navigation management
    _previousIndex = _currentIndex;
    
    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Leaving feed screen
      try {
        _feedScreenKey.currentState?.onScreenBecameInactive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    // Special handling for Profile tab to prevent black bar
    if (index == 4 && mounted) {
      // Force update system UI for Profile tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
        }
      });
    } else if (mounted) {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Entering feed screen
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

  // Check if a tab requires authentication
  bool _requiresAuthentication(int index) {
    switch (index) {
      case 0: // Home - No authentication required
      case 1: // Channels - No authentication required
        return false;
      case 3: // Wallet - Requires authentication
      case 4: // Profile - Requires authentication
        return !_isAuthenticated;
      default:
        return false;
    }
  }

  // Show authentication dialog with proper context for each tab
  void _showAuthenticationDialog(int index) {
    if (!mounted) return;
    
    String title = 'Sign In Required';
    String subtitle = 'Sign in to access this feature and unlock the full WeiBao experience.';
    IconData icon = Icons.login;

    switch (index) {
      case 3: // Wallet
        title = 'Access Your Wallet';
        subtitle = 'Sign in to manage your earnings, transactions, and virtual gifts.';
        icon = Icons.account_balance_wallet;
        break;
      case 4: // Profile
        title = 'Join WeiBao';
        subtitle = 'Sign in and create your channel to start sharing content and connecting with others.';
        icon = Icons.login;
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: LoginRequiredWidget(
            title: title,
            subtitle: subtitle,
            actionText: 'Sign In',
            icon: icon,
            showContinueBrowsing: true,
            onContinueBrowsing: () {
              Navigator.of(context).pop();
              // Navigate back to home tab
              if (mounted) {
                _onTabTapped(0);
              }
            },
          ),
        ),
      ),
    );
  }
  
  void _updateSystemUI() {
    if (!mounted) return;
    
    try {
      if (_currentIndex == 0) {
        // Home/Feed screen - black background with light status bar
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
    } catch (e) {
      debugPrint('System UI update error: $e');
    }
  }
  
  void _onPageChanged(int index) {
    if (!mounted || _isPageAnimating) return;
    
    // Handle feed screen lifecycle
    if (_currentIndex == 0) {
      // Leaving feed screen
      try {
        _feedScreenKey.currentState?.onScreenBecameInactive();
      } catch (e) {
        debugPrint('Feed screen lifecycle error: $e');
      }
    }
    
    // Store previous index before updating
    _previousIndex = _currentIndex;
    
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    // Special handling for Profile tab
    if (index == 4 && mounted) {
      // Force update system UI for Profile tab with multiple attempts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
        }
      });
    } else if (mounted) {
      // Normal system UI update for other tabs
      _updateSystemUI();
    }

    // Handle feed screen lifecycle
    if (_currentIndex == 0 && mounted) {
      // Entering feed screen
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

  void _navigateToCreatePost() async {
    if (!mounted) return;
    
    // Use the LoginRequiredWidget's utility function for create content
    final hasAccess = await requireLogin(
      context,
      ref,
      customTitle: 'Create Content',
      customSubtitle: 'Sign in and create a channel to start sharing your content.',
      customActionText: 'Sign In',
      customIcon: Icons.video_call,
      showContinueBrowsing: true,
      onContinueBrowsing: () => Navigator.of(context).pop(),
    );

    if (!hasAccess || !mounted) return;

    // Pause feed if active
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

    // Resume feed if returning to it
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
    if (!mounted) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Watch the authentication state using the correct provider with safe handling
    bool isAuthenticated = false;
    try {
      final authState = ref.watch(authenticationProvider);
      isAuthenticated = authState.value?.isSuccessful ?? false;
    } catch (e) {
      debugPrint('Auth state watch error: $e');
      isAuthenticated = false;
    }
    
    final modernTheme = _getModernTheme();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isHomeTab = _currentIndex == 0;
    final isProfileTab = _currentIndex == 4;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isHomeTab || isProfileTab,
      backgroundColor: isHomeTab ? Colors.black : modernTheme.backgroundColor,
      
      // Hide AppBar for home and profile tabs
      appBar: (isHomeTab || isProfileTab) ? null : _buildAppBar(modernTheme, isDarkMode),
      
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: [
          // Home tab (index 0) - Channels Feed with black background (accessible to all)
          Container(
            color: Colors.black,
            child: ChannelsFeedScreen(
              key: _feedScreenKey,
            ),
          ),
          // Channels tab (index 1) - Uses current theme (accessible to all)
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
          // Wallet tab (index 3) - Uses LoginRequiredWidget if not authenticated
          Container(
            color: modernTheme.backgroundColor,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: isAuthenticated 
                ? const WalletScreen()
                : const LoginRequiredWidget(
                    title: 'Access Your Wallet',
                    subtitle: 'Sign in to manage your earnings, transactions, and virtual gifts.',
                    actionText: 'Sign In',
                    icon: Icons.account_balance_wallet,
                    showContinueBrowsing: true,
                  ),
          ),
          // Profile tab (index 4) - Uses LoginRequiredWidget if not authenticated
          isAuthenticated
              ? const MyChannelScreen()
              : const LoginRequiredWidget(
                  title: 'Join WeiBao',
                  subtitle: 'Sign in and create your channel to start sharing content and connecting with others.',
                  actionText: 'Sign In',
                  icon: Icons.login,
                  showContinueBrowsing: true,
                ),
        ],
      ),
      
      bottomNavigationBar: _buildTikTokBottomNav(modernTheme, isAuthenticated),
      
      // Remove FAB since we have dedicated post button
      floatingActionButton: null,
    );
  }

  // TikTok-style bottom navigation with video progress indicator
  Widget _buildTikTokBottomNav(ModernThemeExtension modernTheme, bool isAuthenticated) {
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
                    isAuthenticated,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
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
    bool isAuthenticated,
  ) {
    final isSelected = _currentIndex == index;
    final requiresAuth = _requiresAuthentication(index);
    
    Color iconColor;
    Color textColor;
    
    if (isHomeTab) {
      // Home tab colors
      if (requiresAuth && !isAuthenticated) {
        // Dimmed colors for auth-required tabs when not authenticated
        iconColor = Colors.white.withOpacity(0.4);
        textColor = Colors.white.withOpacity(0.4);
      } else {
        iconColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
        textColor = isSelected ? Colors.white : Colors.white.withOpacity(0.6);
      }
    } else {
      // Other tabs - use current theme with safe fallbacks
      if (requiresAuth && !isAuthenticated) {
        // Dimmed colors for auth-required tabs when not authenticated
        iconColor = (modernTheme.textSecondaryColor ?? Colors.grey[600]!).withOpacity(0.5);
        textColor = (modernTheme.textSecondaryColor ?? Colors.grey[600]!).withOpacity(0.5);
      } else {
        iconColor = isSelected 
            ? (modernTheme.primaryColor ?? Colors.blue) 
            : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
        textColor = isSelected 
            ? (modernTheme.primaryColor ?? Colors.blue) 
            : (modernTheme.textSecondaryColor ?? Colors.grey[600]!);
      }
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.translucent,
      child: Container(
        // Expand the tap area while keeping the content centered
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  _tabIcons[index],
                  color: iconColor,
                  size: 24,
                ),
                // Show lock icon for auth-required tabs when not authenticated
                if (requiresAuth && !isAuthenticated)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isHomeTab 
                            ? Colors.black 
                            : (modernTheme.surfaceColor ?? Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: isHomeTab 
                            ? Colors.white.withOpacity(0.7) 
                            : (modernTheme.textSecondaryColor ?? Colors.grey[600]),
                        size: 8,
                      ),
                    ),
                  ),
              ],
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
    String title = 'WeiBao';
    
    // Set title based on current tab
    switch (_currentIndex) {
      case 1:
        title = 'WeiBao'; // Show main app name for Channels tab
        break;
      case 3:
        title = 'Wallet';
        break;
      default:
        title = 'WeiBao';
    }

    Color appBarColor = modernTheme.surfaceColor ?? (isDarkMode ? Colors.grey[900]! : Colors.white);
    Color textColor = modernTheme.textColor ?? (isDarkMode ? Colors.white : Colors.black);
    Color iconColor = modernTheme.primaryColor ?? Colors.blue;

    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: iconColor),
      title: _currentIndex == 3
          ? Text(
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
      // Remove sign in button from app bar
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