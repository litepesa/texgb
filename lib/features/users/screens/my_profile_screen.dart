// lib/features/users/screens/my_profile_screen.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // CRITICAL FIX: Keep state alive to prevent blank screen issues
  @override
  bool get wantKeepAlive => true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isRefreshing = false;
  UserModel? _user;
  String? _error;
  bool _hasNoProfile = false;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('MyProfileScreen: initState called');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    // CRITICAL FIX: Immediate initialization without waiting for post-frame callback
    _initializeScreenImmediate();
    
    // Also schedule a post-frame callback as backup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _initializeScreen();
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    debugPrint('MyProfileScreen: dispose called');
    super.dispose();
  }

  // CRITICAL FIX: Immediate initialization to prevent blank screen
  void _initializeScreenImmediate() {
    if (_isDisposed || !mounted) return;
    
    try {
      debugPrint('MyProfileScreen: Immediate initialization started');
      
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final authState = ref.read(authStateProvider);

      debugPrint('MyProfileScreen: Auth state: $authState, User: ${currentUser?.name}, Authenticated: $isAuthenticated');

      if (!isAuthenticated || currentUser == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _hasNoProfile = true;
            _isInitialized = true;
            _user = null;
            _error = null;
          });
        }
        debugPrint('MyProfileScreen: User not authenticated, showing login required');
        return;
      }

      // Use cached data immediately
      if (mounted && !_isDisposed) {
        setState(() {
          _user = currentUser;
          _isInitialized = true;
          _hasNoProfile = false;
          _error = null;
        });
      }
      
      debugPrint('MyProfileScreen: Immediate initialization completed with user: ${currentUser.name}');
    } catch (e) {
      debugPrint('MyProfileScreen: Error in immediate initialization: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  // Initialize screen with cached data first
  void _initializeScreen() {
    if (_isDisposed || !mounted) return;
    
    try {
      debugPrint('MyProfileScreen: Post-frame initialization started');
      
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _hasNoProfile = true;
            _isInitialized = true;
          });
        }
        return;
      }

      // Use cached data immediately if not already set
      if (_user == null && mounted && !_isDisposed) {
        setState(() {
          _user = currentUser;
          _isInitialized = true;
        });
      }
      
      debugPrint('MyProfileScreen: Post-frame initialization completed');
    } catch (e) {
      debugPrint('MyProfileScreen: Error in post-frame initialization: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  // Refresh user data
  Future<void> _refreshUserData() async {
    if (_isRefreshing || _isDisposed || !mounted) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Check if user is authenticated
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _hasNoProfile = true;
            _isRefreshing = false;
          });
        }
        return;
      }

      // Get fresh user profile from backend
      final authNotifier = ref.read(authenticationProvider.notifier);
      final freshUserProfile = await authNotifier.getUserProfile();

      if (freshUserProfile == null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _hasNoProfile = true;
            _isRefreshing = false;
          });
        }
        return;
      }

      if (mounted && !_isDisposed) {
        setState(() {
          _user = freshUserProfile;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  void _editProfile() {
    if (_user == null || _isDisposed) return;

    Navigator.pushNamed(
      context,
      Constants.editProfileScreen,
      arguments: _user,
    ).then((_) {
      if (mounted && !_isDisposed) {
        _refreshUserData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    // CRITICAL FIX: Prevent build during disposal
    if (_isDisposed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final modernTheme = Theme.of(context).extension<ModernThemeExtension>() ?? 
        ModernThemeExtension(
          primaryColor: const Color(0xFFFE2C55),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          textSecondaryColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
          dividerColor: Theme.of(context).dividerColor,
          textTertiaryColor: Colors.grey[400],
          surfaceVariantColor: Colors.grey[100],
        );

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: modernTheme.surfaceColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasNoProfile) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        body: const LoginRequiredWidget(
          title: 'Sign In Required',
          subtitle: 'Please sign in to view your profile and manage your content.',
          actionText: 'Sign In',
          icon: Icons.person,
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: modernTheme.surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
              const SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18, color: modernTheme.textColor)),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: modernTheme.textSecondaryColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshUserData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user;
    if (user == null) {
      return Scaffold(
        backgroundColor: modernTheme.surfaceColor,
        body: const Center(child: Text('Profile not found')),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 64;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
          color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
          backgroundColor: modernTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 20),
                
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildFloatingProfileCard(user, modernTheme),
                ),
                
                const SizedBox(height: 24),
                
                _buildThemeSettingsTile(modernTheme),
                
                const SizedBox(height: 16),
                
                _buildEditProfileTile(modernTheme),
                
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingProfileCard(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFE2C55),
            const Color(0xFFFE2C55).withOpacity(0.9),
            const Color(0xFFFE2C55).withOpacity(0.7),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE2C55).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImageContent(user),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                height: 1.1,
                shadows: [
                  Shadow(
                    color: Colors.black38,
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // User role display with exact same styling as drama app
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoleIcon(user.role),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getRoleDisplayText(user.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),            
          ],
        ),
      ),
    );
  }

  // Helper methods for role display
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.host:
        return CupertinoIcons.star_circle_fill;
      case UserRole.guest:
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.host:
        return 'AirBnB Host';
      case UserRole.guest:
      default:
        return 'Guest';
    }
  }

  Widget _buildImageContent(UserModel user) {
    if (user.profileImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.profileImage,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.white.withOpacity(0.2),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.8),
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Profile image load error for $url: $error');
          return Container(
            color: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, size: 55, color: Colors.white),
          );
        },
        memCacheWidth: 145,
        memCacheHeight: 145,
        maxWidthDiskCache: 290,
        maxHeightDiskCache: 290,
        httpHeaders: const {
          'User-Agent': 'WeiBao-App/1.0',
        },
        cacheKey: user.profileImage,
      );
    }
    
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person, size: 55, color: Colors.white),
    );
  }


  
  Widget _buildThemeSettingsTile(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (modernTheme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            showThemeSelector(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Enhanced Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (modernTheme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.brightness_6_rounded,
                      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 22,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Theme Settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: modernTheme.textColor ?? Colors.black,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'Customize your app appearance',
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Theme indicator chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.palette_rounded,
                              size: 10,
                              color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Personalize',
                              style: TextStyle(
                                fontSize: 10,
                                color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Enhanced Arrow Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileTile(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (modernTheme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _editProfile();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Enhanced Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (modernTheme.dividerColor ?? Colors.grey[300]!).withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 22,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Enhanced Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: modernTheme.textColor ?? Colors.black,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'Update your profile information',
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Edit indicator chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 10,
                              color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Customize',
                              style: TextStyle(
                                fontSize: 10,
                                color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Enhanced Arrow Button
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (modernTheme.primaryColor ?? const Color(0xFFFE2C55)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}