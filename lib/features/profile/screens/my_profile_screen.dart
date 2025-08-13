// lib/features/profile/screens/my_profile_screen.dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

// Custom cache manager for profile images with longer cache duration
class ProfileImageCacheManager {
  static const key = 'profileImageCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Keep for 30 days
      maxNrOfCacheObjects: 100, // Max 100 cached profile images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
  
  // Preload multiple profile images
  static Future<void> preloadProfileImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await instance.downloadFile(url);
        } catch (e) {
          debugPrint('Failed to preload image: $url, Error: $e');
        }
      }
    }
  }
  
  // Clear specific user's cached profile image
  static Future<void> clearUserProfileImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      await instance.removeFile(imageUrl);
    }
  }
  
  // Get cached file info
  static Future<FileInfo?> getCachedImageInfo(String url) async {
    try {
      return await instance.getFileFromCache(url);
    } catch (e) {
      return null;
    }
  }
}

// App data cache manager for user data, stats, etc.
class AppDataCacheManager {
  static const key = 'appDataCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 6), // Refresh every 6 hours
      maxNrOfCacheObjects: 50,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

// Offline mode provider
final offlineModeProvider = StateProvider<bool>((ref) => false);

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> 
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  bool _isUpdating = false;
  late TextEditingController _aboutController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _aboutController = TextEditingController(text: user?.aboutMe ?? '');
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Preload user's profile image and related images in background
    _preloadCriticalImages();
  }
  
  @override
  void dispose() {
    _aboutController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Preload critical images for better UX - runs in background
  Future<void> _preloadCriticalImages() async {
    try {
      final user = ref.read(currentUserProvider);
      final authState = ref.read(authenticationProvider).value;
      
      List<String> imagesToPreload = [];
      
      // Add current user's image
      if (user?.image.isNotEmpty == true) {
        imagesToPreload.add(user!.image);
      }
      
      // Add saved accounts' images for quick switching
      if (authState?.savedAccounts != null) {
        for (var account in authState!.savedAccounts!) {
          if (account.image.isNotEmpty) {
            imagesToPreload.add(account.image);
          }
        }
      }
      
      // Preload in background without blocking UI
      if (imagesToPreload.isNotEmpty) {
        ProfileImageCacheManager.preloadProfileImages(imagesToPreload);
      }
      
    } catch (e) {
      debugPrint('Error preloading images: $e');
    }
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.modernTheme.textSecondaryColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: context.modernTheme.primaryColor,
                  ),
                ),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(true);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: context.modernTheme.primaryColor,
                  ),
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(bool fromCamera) async {
    final pickedImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (message) {
        showSnackBar(context, message);
      },
    );

    if (pickedImage != null) {
      setState(() {
        _profileImage = pickedImage;
      });
    }
  }

  Future<void> _updateProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Upload new image if selected
      String imageUrl = user.image;
      if (_profileImage != null) {
        // Clear old cached image first
        if (user.image.isNotEmpty) {
          await ProfileImageCacheManager.clearUserProfileImage(user.image);
        }
        
        imageUrl = await storeFileToStorage(
          file: _profileImage!,
          reference: '${Constants.userImages}/${user.uid}',
        );
        
        // Preload the new image to cache in background
        if (imageUrl.isNotEmpty) {
          ProfileImageCacheManager.instance.downloadFile(imageUrl);
        }
      }

      // Create updated user model
      final updatedUser = user.copyWith(
        aboutMe: _aboutController.text.trim(),
        image: imageUrl,
      );

      // Save to Firebase
      await ref.read(authenticationProvider.notifier).updateUserProfile(updatedUser);
      
      if (mounted) {
        showSnackBar(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final user = ref.watch(currentUserProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // The bottom padding needed for the bottom nav bar
    final bottomPadding = MediaQuery.of(context).padding.bottom + 64;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Enhanced Profile Header
              _buildEnhancedProfileHeader(user, modernTheme),
              
              // Wallet Navigation Feature (replaces My Posts)
              _buildWalletNavigationFeature(modernTheme),
              
              // Profile Information
              _buildProfileInfo(user, modernTheme),
              
              // Theme Selector
              _buildThemeSelector(modernTheme, isDarkMode),
              
              // Account Settings
              _buildAccountSettings(modernTheme),
              
              // Account management section
              _buildAccountManagementSection(modernTheme),
              
              // Add extra padding at the bottom for the bottom nav bar
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
  
  // Enhanced profile header with optimized image caching
  Widget _buildEnhancedProfileHeader(UserModel user, ModernThemeExtension modernTheme) {
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
      ),
      child: Column(
        children: [
          // Add safe area padding at the top
          SizedBox(height: MediaQuery.of(context).padding.top),
          
          // Profile Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                // Profile Image with enhanced caching
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
                        child: _profileImage != null 
                          ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            )
                          : user.image.isNotEmpty 
                            ? CachedNetworkImage(
                                imageUrl: user.image,
                                cacheManager: ProfileImageCacheManager.instance,
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
                                errorWidget: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                // Enhanced cache options for better performance
                                memCacheWidth: 110,
                                memCacheHeight: 110,
                                maxWidthDiskCache: 220,
                                maxHeightDiskCache: 220,
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                modernTheme.primaryColor!,
                                modernTheme.primaryColor!.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Name with enhanced styling
                Text(
                  user.name,
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
                ),
                const SizedBox(height: 8),
                // Phone number with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phone,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.phoneNumber,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Edit Profile Button with enhanced design
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Constants.editProfileScreen);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          color: modernTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: modernTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
  
  // New Wallet Navigation feature (replaces My Posts)
  Widget _buildWalletNavigationFeature(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, Constants.walletScreen);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.money_dollar_circle_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MY WALLET',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your earnings & payments',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick action buttons for wallet
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.plus_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Top Up',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.paperplane,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send Money',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              CupertinoIcons.chart_bar_fill,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Earnings',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileInfo(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me Section with better design
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: modernTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'About Me',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  _showAboutMeDialog(user.aboutMe);
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: modernTheme.primaryColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.aboutMe.isEmpty ? '✨ No bio yet. Tap edit to add one!' : user.aboutMe,
              style: TextStyle(
                color: user.aboutMe.isEmpty 
                  ? modernTheme.textSecondaryColor 
                  : modernTheme.textColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          if (_profileImage != null || _aboutController.text != user.aboutMe) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildThemeSelector(ModernThemeExtension modernTheme, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Appearance',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              showThemeSelector(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: modernTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: modernTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDarkMode ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change theme',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: modernTheme.textSecondaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountSettings(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              Navigator.pushNamed(context, Constants.privacySettingsScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.block,
            title: 'Blocked Contacts',
            subtitle: 'Manage blocked users',
            onTap: () {
              Navigator.pushNamed(context, Constants.blockedContactsScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information',
            onTap: () {
              Navigator.pushNamed(context, Constants.aboutScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              Navigator.pushNamed(context, Constants.privacyPolicyScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Read terms of service',
            onTap: () {
              Navigator.pushNamed(context, Constants.termsAndConditionsScreen);
            },
            modernTheme: modernTheme,
          ),
        ],
      ),
    );
  }
  
  // Account management section
  Widget _buildAccountManagementSection(ModernThemeExtension modernTheme) {
    final isOfflineMode = ref.watch(offlineModeProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Account',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.swap_horiz,
            title: 'Switch Account',
            subtitle: 'Use another account',
            onTap: () {
              _showAccountSwitchDialog();
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.add_circle_outline,
            title: 'Add Account',
            subtitle: 'Add a new account',
            onTap: () {
              _addNewAccount();
            },
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          // Offline Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: isOfflineMode 
                  ? Colors.orange.withOpacity(0.1) 
                  : modernTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOfflineMode 
                    ? Colors.orange.withOpacity(0.3) 
                    : Colors.transparent,
              ),
            ),
            child: SwitchListTile(
              value: isOfflineMode,
              onChanged: (value) {
                _toggleOfflineMode(value);
              },
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOfflineMode 
                          ? Colors.orange.withOpacity(0.2)
                          : modernTheme.primaryColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOfflineMode ? Icons.wifi_off : Icons.wifi,
                      color: isOfflineMode ? Colors.orange : modernTheme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOfflineMode 
                              ? 'Internet access disabled' 
                              : 'Toggle to disable internet',
                          style: TextStyle(
                            color: isOfflineMode 
                                ? Colors.orange 
                                : modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              activeColor: Colors.orange,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 8,
              ),
            ),
          ),
          if (isOfflineMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline mode is active. All network features are disabled.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1) 
                    : modernTheme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : modernTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAboutMeDialog(String currentAbout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor!,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.modernTheme.textSecondaryColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Edit About Me',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.modernTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aboutController,
              style: TextStyle(color: context.modernTheme.textColor),
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Tell us a bit about yourself...',
                hintStyle: TextStyle(
                  color: context.modernTheme.textSecondaryColor,
                ),
                filled: true,
                fillColor: context.modernTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.modernTheme.dividerColor!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.modernTheme.primaryColor!,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                    if (_aboutController.text != currentAbout) {
                      _updateProfile();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAccountSwitchDialog() async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    final authState = ref.read(authenticationProvider).value;
    
    if (authState == null || authState.savedAccounts == null || authState.savedAccounts!.isEmpty) {
      showSnackBar(context, 'No saved accounts found');
      return;
    }
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor!,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.modernTheme.textSecondaryColor!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Switch Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.modernTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: context.modernTheme.dividerColor),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: authState.savedAccounts!.length,
                itemBuilder: (context, index) {
                  final account = authState.savedAccounts![index];
                  final isCurrentAccount = account.uid == currentUser.uid;
                  
                  return ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isCurrentAccount 
                            ? Border.all(
                                color: context.modernTheme.primaryColor!,
                                width: 2,
                              )
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        child: ClipOval(
                          child: account.image.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: account.image,
                                  cacheManager: ProfileImageCacheManager.instance,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person),
                                  ),
                                  errorWidget: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person),
                                  ),
                                )
                              : const Icon(Icons.person),
                        ),
                      ),
                    ),
                    title: Text(
                      account.name,
                      style: TextStyle(
                        color: context.modernTheme.textColor,
                        fontWeight: isCurrentAccount ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      account.phoneNumber,
                      style: TextStyle(
                        color: context.modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isCurrentAccount
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: context.modernTheme.primaryColor!.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Current',
                              style: TextStyle(
                                color: context.modernTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      if (isCurrentAccount) {
                        Navigator.pop(context);
                        return;
                      }
                      
                      Navigator.pop(context);
                      _switchToAccount(account);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _switchToAccount(UserModel selectedAccount) async {
    try {
      await ref.read(authenticationProvider.notifier).switchAccount(selectedAccount);
      if (mounted) {
        showSnackBar(context, 'Switched to ${selectedAccount.name}\'s account');
        // Preload the new account's images in background
        _preloadCriticalImages();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error switching account: $e');
      }
    }
  }
  
  void _addNewAccount() {
    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(
      context, 
      Constants.landingScreen, 
      (route) => false,
    );
  }
  
  void _toggleOfflineMode(bool enable) {
    ref.read(offlineModeProvider.notifier).state = enable;
    
    if (enable) {
      // Show offline mode activation dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off,
              color: Colors.orange,
              size: 32,
            ),
          ),
          title: const Text('Offline Mode Activated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Internet access has been disabled. You can still use offline features of the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toggle off to restore internet',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      
      // Show snackbar
      showSnackBar(context, '📵 Offline mode enabled');
    } else {
      // Show online mode restoration
      showSnackBar(context, '📶 Internet access restored');
    }
  }
}