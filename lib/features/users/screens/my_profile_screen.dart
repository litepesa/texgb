// lib/features/users/screens/my_profile_screen.dart (WeChat Style)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isRefreshing = false;
  UserModel? _user;
  String? _error;
  bool _hasNoProfile = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

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

    setState(() {
      _user = currentUser;
      _isInitialized = true;
    });
  }

  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
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

      final authNotifier = ref.read(authenticationProvider.notifier);
      final freshUserProfile = await authNotifier.forceRefreshUserProfile();

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
      debugPrint('❌ Error refreshing user data: $e');
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
    ).then((_) => _refreshUserData());
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor,
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
      child: CircularProgressIndicator(
        color: modernTheme.primaryColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildProfileRequiredView(ModernThemeExtension modernTheme) {
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: const LoginRequiredWidget(
        title: 'Sign In Required',
        subtitle: 'Please sign in to view your profile.',
        actionText: 'Sign In',
        icon: CupertinoIcons.person_circle,
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
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.red.shade600,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _refreshUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Try Again'),
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
      color: modernTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          _buildProfileHeader(modernTheme),
          const SizedBox(height: 20),
          _buildMenuSection(modernTheme),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: _editProfile,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: modernTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: modernTheme.dividerColor ?? Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _user!.profileImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _user!.profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                        errorWidget: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            CupertinoIcons.person_fill,
                            size: 35,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 35,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Name and WeChat ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.name,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'WeiBao ID: ',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _user!.uid.substring(0, 8),
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // QR Code Icon
            Icon(
              CupertinoIcons.qrcode,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            
            // Arrow
            Icon(
              CupertinoIcons.right_chevron,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        _buildMenuGroup(modernTheme, [
          _MenuItem(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'Services',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Services - Coming Soon'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ]),
        
        const SizedBox(height: 10),
        
        _buildMenuGroup(modernTheme, [
          _MenuItem(
            icon: CupertinoIcons.collections,
            title: 'Favorites',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Favorites - Coming Soon'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuItem(
            icon: CupertinoIcons.photo_on_rectangle,
            title: 'Moments',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Moments - Coming Soon'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuItem(
            icon: CupertinoIcons.creditcard,
            title: 'Cards & Offers',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cards & Offers - Coming Soon'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _MenuItem(
            icon: CupertinoIcons.smiley,
            title: 'Stickers',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Stickers - Coming Soon'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ]),
        
        const SizedBox(height: 10),
        
        _buildMenuGroup(modernTheme, [
          _MenuItem(
            icon: CupertinoIcons.settings,
            title: 'Settings',
            onTap: () => _showSettingsSheet(modernTheme),
          ),
        ]),
      ],
    );
  }

  Widget _buildMenuGroup(ModernThemeExtension modernTheme, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _buildMenuItem(
                icon: item.icon,
                title: item.title,
                onTap: item.onTap,
                modernTheme: modernTheme,
              ),
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: modernTheme.dividerColor,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: modernTheme.textColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(ModernThemeExtension modernTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildSettingsItem(
                icon: CupertinoIcons.person_circle,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.pop(context);
                  _editProfile();
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.paintbrush,
                title: 'Theme',
                onTap: () {
                  Navigator.pop(context);
                  showThemeSelector(context);
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.lock_shield,
                title: 'Privacy',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Privacy Settings - Coming Soon'),
                      backgroundColor: modernTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.bell,
                title: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification Settings - Coming Soon'),
                      backgroundColor: modernTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.info_circle,
                title: 'About',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(modernTheme);
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.arrow_2_squarepath,
                title: 'Switch Account',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Switch Account - Coming Soon'),
                      backgroundColor: modernTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                modernTheme: modernTheme,
              ),
              
              _buildSettingsItem(
                icon: CupertinoIcons.wifi_slash,
                title: 'Go Offline',
                subtitle: 'Disconnect from messages and calls',
                onTap: () {
                  Navigator.pop(context);
                  _showOfflineConfirmation(modernTheme);
                },
                modernTheme: modernTheme,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: modernTheme.textColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(ModernThemeExtension modernTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF07C160),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'WeiBao',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WeiBao is a social marketplace connecting buyers and sellers through chat.',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineConfirmation(ModernThemeExtension modernTheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: modernTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.wifi_slash,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Go Offline',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When offline, you will:',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildOfflineFeature(
              '• Not receive new messages or calls',
              modernTheme,
            ),
            const SizedBox(height: 6),
            _buildOfflineFeature(
              '• Appear offline to your contacts',
              modernTheme,
            ),
            const SizedBox(height: 6),
            _buildOfflineFeature(
              '• Still browse saved content',
              modernTheme,
            ),
            const SizedBox(height: 16),
            Text(
              'You can go back online anytime from settings.',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(CupertinoIcons.wifi_slash, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Offline Mode - Coming Soon'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Go Offline',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineFeature(String text, ModernThemeExtension modernTheme) {
    return Text(
      text,
      style: TextStyle(
        color: modernTheme.textColor,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}