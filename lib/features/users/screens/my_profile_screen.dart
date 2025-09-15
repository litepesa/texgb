import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/users/widgets/verification_widget.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
  bool _isLoading = true;
  UserModel? _user;
  String? _error;
  bool _hasNoProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // 🔧 CRITICAL FIX: Load fresh user data from backend instead of cached data
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasNoProfile = false;
    });

    try {
      // Check if user is authenticated
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        // User is not authenticated
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isLoading = false;
          });
        }
        return;
      }

      // 🔧 CRITICAL FIX: Fetch fresh user data from backend instead of using cached data
      final authNotifier = ref.read(authenticationProvider.notifier);

      debugPrint('🔄 Loading fresh user profile data...');

      // Get fresh user profile from backend (includes latest R2 image URLs)
      final freshUserProfile = await authNotifier.getUserProfile();

      if (freshUserProfile == null) {
        debugPrint('❌ User profile not found in backend');
        // User profile not found in backend
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isLoading = false;
          });
        }
        return;
      }

      debugPrint('✅ Fresh user profile loaded: ${freshUserProfile.name}');
      debugPrint('📸 Profile image URL: ${freshUserProfile.profileImage}');

      if (mounted) {
        setState(() {
          _user = freshUserProfile; // ✅ Using fresh data with latest R2 URLs
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
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
    ).then((_) => _loadUserData());
  }

  // 🔧 FIXED: Enhanced profile creation callback with cache clearing
  void _onProfileCreated() async {
    debugPrint('🔄 Profile created, refreshing data...');

    // 🔧 FIX: Clear any cached network images
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(_user!.profileImage);
    }

    // 🔧 FIX: Force refresh authentication state to get latest user data
    final authNotifier = ref.read(authenticationProvider.notifier);
    await authNotifier.loadUserDataFromSharedPreferences();

    // Reload the screen data after profile creation
    await _loadUserData();

    debugPrint('✅ Profile data refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: _isLoading
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
            color: modernTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
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
        subtitle:
            'Please sign in to view your profile and manage your content.',
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
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
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

    return Column(
      children: [
        // Profile Header
        _buildProfileHeader(modernTheme),

        // Scrollable content below header
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                // Become Seller tile
                _buildBecomeSellerTile(modernTheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔧 FIXED: Enhanced profile header with better R2 image handling and curved bottom
  Widget _buildProfileHeader(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.8),
            modernTheme.primaryColor!.withOpacity(0.6),
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
                // 🔧 ENHANCED: Profile Image with better R2 handling
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
                                  // 🔧 DEBUG: Print R2 URL for debugging
                                  debugPrint(
                                      '❌ Failed to load profile image: ${_user!.profileImage}');
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
                                // Enhanced cache options for R2 images
                                memCacheWidth: 110,
                                memCacheHeight: 110,
                                maxWidthDiskCache: 220,
                                maxHeightDiskCache: 220,
                                // 🔧 FIX: Add headers for R2 images if needed
                                httpHeaders: const {
                                  'User-Agent': 'WeiBao-App/1.0',
                                },
                                // 🔧 FIX: Force reload if cached version fails
                                cacheKey: _user!.profileImage,
                                // Add loading success callback for debugging
                                imageBuilder: (context, imageProvider) {
                                  debugPrint(
                                      '✅ Profile image loaded successfully: ${_user!.profileImage}');
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

                // User name with enhanced styling
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

                // User description
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

                // Side-by-side buttons: Verification and Edit Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Verification status button - more prominent and bright
                    GestureDetector(
                      onTap: () => VerificationInfoWidget.show(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _user!.isVerified
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1565C0), // Deep blue
                                    Color(0xFF0D47A1), // Darker blue
                                    Color(0xFF0A1E3D), // Very dark blue
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2), // Material blue
                                    Color(0xFF1565C0), // Darker blue
                                    Color(0xFF0D47A1), // Deep blue
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
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Edit Profile Button - simplified without icon
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                            color: modernTheme.primaryColor,
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

  Widget _buildBecomeSellerTile(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            modernTheme.primaryColor!.withOpacity(0.08),
            modernTheme.primaryColor!.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: modernTheme.primaryColor!.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section with icon and title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                const SizedBox(width: 16),
              ],
            ),
          ),

          // Description and button section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Button - full width
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => VerificationInfoWidget.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            modernTheme.primaryColor!,
                            modernTheme.primaryColor!.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: modernTheme.primaryColor!.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Become a Seller Today',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
