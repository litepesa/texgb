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
  DateTime? _lastDataFetch;
  
  // 🚀 PERFORMANCE: Custom cache manager for user data with longer cache duration
  static final CacheManager _userDataCacheManager = CacheManager(
    Config(
      'user_data_cache',
      stalePeriod: const Duration(minutes: 30), // Cache for 30 minutes
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'user_data_cache'),
      fileService: HttpFileService(),
    ),
  );

  // 🚀 PERFORMANCE: Cache duration - only fetch fresh data if older than this
  static const Duration _cacheValidDuration = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataSmart();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 🚀 PERFORMANCE: Smart loading - use cached data when available and valid
  Future<void> _loadUserDataSmart({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasNoProfile = false;
    });

    try {
      // Check if user is authenticated first (this is usually cached in Riverpod)
      final currentUser = ref.read(currentUserProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!isAuthenticated || currentUser == null) {
        if (mounted) {
          setState(() {
            _hasNoProfile = true;
            _isLoading = false;
          });
        }
        return;
      }

      // 🚀 PERFORMANCE: Check if we have valid cached data first
      final now = DateTime.now();
      final shouldUseCachedData = !forceRefresh && 
          _user != null && 
          _lastDataFetch != null &&
          now.difference(_lastDataFetch!) < _cacheValidDuration;

      if (shouldUseCachedData) {
        debugPrint('📦 Using cached user profile data (${_lastDataFetch})');
        setState(() {
          _isLoading = false;
        });
        
        // 🚀 PERFORMANCE: Preload profile image in background if needed
        _preloadProfileImageIfNeeded();
        return;
      }

      debugPrint('🔄 Loading fresh user profile data...');
      
      // Fetch fresh user data from backend
      final authNotifier = ref.read(authenticationProvider.notifier);
      final freshUserProfile = await authNotifier.getUserProfile();

      if (freshUserProfile == null) {
        debugPrint('❌ User profile not found in backend');
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
          _user = freshUserProfile;
          _lastDataFetch = now;
          _isLoading = false;
        });
      }

      // 🚀 PERFORMANCE: Preload profile image after setting user data
      _preloadProfileImageIfNeeded();

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

  // 🚀 PERFORMANCE: Preload profile image for instant display
  Future<void> _preloadProfileImageIfNeeded() async {
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      try {
        // Preload the image silently in the background
        await precacheImage(
          CachedNetworkImageProvider(
            _user!.profileImage,
            cacheManager: DefaultCacheManager(),
            cacheKey: 'profile_${_user!.id}_${_user!.profileImage.hashCode}',
          ), 
          context,
        );
        debugPrint('✅ Profile image preloaded successfully');
      } catch (e) {
        debugPrint('⚠️ Could not preload profile image: $e');
        // Not a critical error, just means image will load when displayed
      }
    }
  }

  // 🚀 PERFORMANCE: Force refresh method for pull-to-refresh or manual refresh
  Future<void> _forceRefresh() async {
    // Clear image cache for this user to ensure fresh image
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(
        _user!.profileImage,
        cacheKey: 'profile_${_user!.id}_${_user!.profileImage.hashCode}',
      );
    }
    
    await _loadUserDataSmart(forceRefresh: true);
  }

  void _editProfile() {
    if (_user == null) return;

    Navigator.pushNamed(
      context,
      Constants.editProfileScreen,
      arguments: _user,
    ).then((_) => _forceRefresh()); // Force refresh after editing
  }

  // 🚀 PERFORMANCE: Optimized profile creation callback
  void _onProfileCreated() async {
    debugPrint('🔄 Profile created, refreshing data...');

    // Clear cached data to ensure fresh load
    _lastDataFetch = null;
    
    // Clear image cache
    if (_user?.profileImage != null && _user!.profileImage.isNotEmpty) {
      await CachedNetworkImage.evictFromCache(
        _user!.profileImage,
        cacheKey: 'profile_${_user!.id}_${_user!.profileImage.hashCode}',
      );
    }

    // Force refresh authentication state and reload
    final authNotifier = ref.read(authenticationProvider.notifier);
    await authNotifier.loadUserDataFromSharedPreferences();

    await _forceRefresh();
    debugPrint('✅ Profile data refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: RefreshIndicator(
        // 🚀 PERFORMANCE: Add pull-to-refresh functionality
        onRefresh: _forceRefresh,
        color: modernTheme.primaryColor,
        child: _isLoading
            ? _buildLoadingView(modernTheme)
            : _hasNoProfile
                ? _buildProfileRequiredView(modernTheme)
                : _error != null
                    ? _buildErrorView(modernTheme)
                    : _buildProfileView(modernTheme),
      ),
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
              onPressed: () => _loadUserDataSmart(forceRefresh: true),
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
            physics: const AlwaysScrollableScrollPhysics(), // Enable refresh indicator
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

  // 🚀 PERFORMANCE: Optimized profile header with smart image caching
  Widget _buildProfileHeader(ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFE2C55).withOpacity(0.4),
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
                // 🚀 PERFORMANCE: Optimized profile image with smart caching
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
                                // 🚀 PERFORMANCE: Use unique cache key with user ID and URL hash
                                cacheKey: 'profile_${_user!.id}_${_user!.profileImage.hashCode}',
                                fit: BoxFit.cover,
                                // 🚀 PERFORMANCE: Optimize cache sizes
                                memCacheWidth: 220, // 2x for high DPI
                                memCacheHeight: 220,
                                maxWidthDiskCache: 440, // 4x for future use
                                maxHeightDiskCache: 440,
                                // 🚀 PERFORMANCE: Use default cache manager with optimized settings
                                cacheManager: DefaultCacheManager(),
                                // 🚀 PERFORMANCE: Optimize placeholder
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                // 🚀 PERFORMANCE: Improved error handling with retry mechanism
                                errorWidget: (context, error, stackTrace) {
                                  debugPrint('❌ Failed to load profile image: ${_user!.profileImage}');
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
                                // 🚀 PERFORMANCE: Add headers for better caching
                                httpHeaders: const {
                                  'User-Agent': 'WeiBao-App/1.0',
                                  'Cache-Control': 'max-age=86400', // Cache for 24 hours
                                },
                                // 🚀 PERFORMANCE: Success callback for debugging
                                imageBuilder: (context, imageProvider) {
                                  debugPrint('✅ Profile image loaded from cache/network: ${_user!.profileImage}');
                                  return Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                                // 🚀 PERFORMANCE: Configure cache duration
                                fadeInDuration: const Duration(milliseconds: 300),
                                fadeOutDuration: const Duration(milliseconds: 300),
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
            Color(0xFFFE2C55).withOpacity(0.08),
            Color(0xFFFE2C55).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFFFE2C55).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFE2C55).withOpacity(0.08),
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
                            Color(0xFFFE2C55),
                            Color(0xFFFE2C55).withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFE2C55).withOpacity(0.3),
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