
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_selector.dart';

class ProfileImageCacheManager {
  static const key = 'profileImageCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
  
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
  
  static Future<void> clearUserProfileImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      await instance.removeFile(imageUrl);
    }
  }
  
  static Future<FileInfo?> getCachedImageInfo(String url) async {
    try {
      return await instance.getFileFromCache(url);
    } catch (e) {
      return null;
    }
  }
}

class AppDataCacheManager {
  static const key = 'appDataCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 6),
      maxNrOfCacheObjects: 50,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

final offlineModeProvider = StateProvider<bool>((ref) => false);

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
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
    _animationController.forward();
    
    _preloadCriticalImages();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _preloadCriticalImages() async {
    try {
      final user = ref.read(currentUserProvider);
      final authState = ref.read(authenticationProvider).value;
      
      List<String> imagesToPreload = [];
      
      if (user?.profileImage.isNotEmpty == true) {
        imagesToPreload.add(user!.profileImage);
      }
      
      if (authState?.savedAccounts != null) {
        for (var account in authState!.savedAccounts!) {
          if (account.profileImage.isNotEmpty) {
            imagesToPreload.add(account.profileImage);
          }
        }
      }
      
      if (imagesToPreload.isNotEmpty) {
        ProfileImageCacheManager.preloadProfileImages(imagesToPreload);
      }
      
    } catch (e) {
      debugPrint('Error preloading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 64;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              
              SlideTransition(
                position: _slideAnimation,
                child: _buildFloatingProfileCard(user, modernTheme),
              ),
              
              const SizedBox(height: 24),
              
              _buildDramaStatsCard(user, modernTheme),
              
              const SizedBox(height: 16),
              
              _buildThemeSettingsTile(modernTheme),
              
              SizedBox(height: bottomPadding),
            ],
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
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isAdmin ? 'Administrator' : 'Drama Fan',
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

  Widget _buildImageContent(UserModel user) {
    if (user.profileImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.profileImage,
        cacheManager: ProfileImageCacheManager.instance,
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
      );
    }
    
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person, size: 55, color: Colors.white),
    );
  }

  Widget _buildDramaStatsCard(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE2C55).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tv,
                    color: Color(0xFFFE2C55),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'My Drama Stats',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Favorites',
                    user.favoriteDramas.length.toString(),
                    Icons.favorite,
                    Colors.red.shade400,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Watched',
                    user.watchHistory.length.toString(),
                    Icons.play_circle,
                    Colors.green.shade400,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Unlocked',
                    user.unlockedDramas.length.toString(),
                    Icons.lock_open,
                    Colors.blue.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildThemeSettingsTile(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showThemeSelector(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.brightness_6,
                    color: modernTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Settings',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize your app appearance',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
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
      ),
    );
  }
}