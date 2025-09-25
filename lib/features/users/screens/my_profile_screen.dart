// lib/features/users/screens/my_profile_screen.dart
// FOCUSED: Profile header only with core profile functions
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/users/widgets/verification_widget.dart';
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

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isRefreshing = false;
  UserModel? _user;
  String? _error;
  bool _hasNoProfile = false;
  bool _isInitialized = false;

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme(BuildContext context) {
    return Theme.of(context).extension<ModernThemeExtension>() ?? 
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
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  // Initialize screen with cached data first
  void _initializeScreen() {
    final currentUser = ref.read(currentUserProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!isAuthenticated || currentUser == null) {
      setState(() {
        _hasNoProfile = true;
        _isInitialized = true;
      });
      return;
    }

    // Use cached data immediately
    setState(() {
      _user = currentUser;
      _isInitialized = true;
    });
  }

  // Refresh user data
  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Check if user is authenticated
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted) {
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
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isRefreshing = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _user = freshUserProfile;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  void _editProfile() {
    if (_user == null) return;

    Navigator.pushNamed(
      context,
      Constants.editProfileScreen,
      arguments: _user,
    ).then((_) => _refreshUserData()); // Refresh after edit
  }

  // Profile creation callback with cache clearing
  void _onProfileCreated() async {
    debugPrint('Profile created, refreshing data...');

    // Clear any cached network images
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(_user!.profileImage);
    }

    // Force refresh authentication state to get latest user data
    final authNotifier = ref.read(authenticationProvider.notifier);
    await authNotifier.loadUserDataFromSharedPreferences();

    // Reload the screen data after profile creation
    await _refreshUserData();

    debugPrint('Profile data refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = _getSafeTheme(context);

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: !_isInitialized
          ? _buildLoadingView(modernTheme)
          : _hasNoProfile
              ? _buildProfileRequiredView(modernTheme)
              : _error != null
                  ? _buildErrorView(modernTheme)
                  : _buildProfileView(modernTheme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor ?? Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRequiredView(ModernThemeExtension modernTheme) {
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

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: modernTheme.textColor ?? Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(ModernThemeExtension modernTheme) {
    if (_user == null) {
      return const Center(child: Text('Profile not found'));
    }

    return RefreshIndicator(
      onRefresh: _refreshUserData,
      color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
      backgroundColor: modernTheme.surfaceColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
        child: Column(
          children: [
            // Profile Header - Main focus
            _buildProfileHeader(modernTheme),
            
            // Add some bottom spacing
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFE2C55),
            Color(0xFFFE2C55).withOpacity(0.8),
            Color(0xFFFE2C55).withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Add safe area padding at the top
          SizedBox(height: MediaQuery.of(context).padding.top),

          // App bar with theme switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - placeholder for symmetry
                const SizedBox(width: 40),

                // Center - Profile title
                const Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                // Right side - Theme switcher
                GestureDetector(
                  onTap: () => showThemeSelector(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.brightness_6,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              children: [
                // Profile Image with enhanced R2 handling
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow effect
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _user!.profileImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _user!.profileImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, error, stackTrace) {
                                  debugPrint('Failed to load profile image: ${_user!.profileImage}');
                                  debugPrint('Error: $error');
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                memCacheWidth: 110,
                                memCacheHeight: 110,
                                maxWidthDiskCache: 220,
                                maxHeightDiskCache: 220,
                                httpHeaders: const {
                                  'User-Agent': 'WeiBao-App/1.0',
                                },
                                cacheKey: _user!.profileImage,
                                imageBuilder: (context, imageProvider) {
                                  debugPrint('Profile image loaded successfully: ${_user!.profileImage}');
                                  return Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // User name
                Text(
                  _user!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // User bio
                if (_user!.bio.isNotEmpty)
                  Text(
                    _user!.bio,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 20),

                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Verification status button
                    GestureDetector(
                      onTap: () => VerificationInfoWidget.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _user!.isVerified
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0),
                                    Color(0xFF0D47A1),
                                    Color(0xFF0A1E3D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF1565C0),
                                    Color(0xFF0D47A1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: _user!.isVerified
                                  ? const Color(0xFF1565C0).withOpacity(0.4)
                                  : const Color(0xFF1976D2).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _user!.isVerified
                                  ? Icons.verified_rounded
                                  : Icons.star_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _user!.isVerified ? 'Verified' : 'Get Verified',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Edit Profile Button
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: modernTheme.primaryColor ?? const Color(0xFFFE2C55),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}