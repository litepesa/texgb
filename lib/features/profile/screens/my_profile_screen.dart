import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  File? _profileImage;
  bool _isUpdating = false;
  late TextEditingController _aboutController;
  
  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _aboutController = TextEditingController(text: user?.aboutMe ?? '');
  }
  
  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _getImage(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _getImage(false);
              },
            ),
          ],
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
        imageUrl = await storeFileToStorage(
          file: _profileImage!,
          reference: '${Constants.userImages}/${user.uid}',
        );
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

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, Constants.editProfileScreen);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user, modernTheme),
            
            // Profile Information
            _buildProfileInfo(user, modernTheme),
            
            // Theme Selector
            _buildThemeSelector(modernTheme, isDarkMode),
            
            // Account Settings
            _buildAccountSettings(modernTheme),
            
            // Account management section
            _buildAccountManagementSection(modernTheme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: modernTheme.backgroundColor,
                  backgroundImage: _profileImage != null 
                    ? FileImage(_profileImage!) as ImageProvider
                    : user.image.isNotEmpty 
                      ? NetworkImage(user.image) as ImageProvider
                      : const AssetImage('assets/images/user_icon.png') as ImageProvider,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: modernTheme.backgroundColor!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Phone
          Text(
            user.phoneNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          // Account indicator
          GestureDetector(
            onTap: _showAccountSwitchDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Switch Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileInfo(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          // About Me Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About Me',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showAboutMeDialog(user.aboutMe);
                },
                icon: Icon(
                  Icons.edit,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.aboutMe.isEmpty ? 'No bio yet. Tap edit to add one!' : user.aboutMe,
            style: TextStyle(
              color: user.aboutMe.isEmpty 
                ? modernTheme.textSecondaryColor 
                : modernTheme.textColor,
              fontSize: 16,
            ),
          ),
          if (_profileImage != null || _aboutController.text != user.aboutMe) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateProfile,
                child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Appearance',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              showThemeSelector(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: modernTheme.primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 16,
                      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Account Settings',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            onTap: () {
              Navigator.pushNamed(context, Constants.privacySettingsScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.block,
            title: 'Blocked Contacts',
            onTap: () {
              Navigator.pushNamed(context, Constants.blockedContactsScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.info,
            title: 'About',
            onTap: () {
              Navigator.pushNamed(context, Constants.aboutScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.pushNamed(context, Constants.privacyPolicyScreen);
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.pushNamed(context, Constants.termsAndConditionsScreen);
            },
            modernTheme: modernTheme,
          ),
            
          // Debugging method to clear local storage - only for development
          if (false) // Set to false for production
            _buildSettingsItem(
              icon: Icons.delete_outline,
              title: 'Clear App Data (Dev Only)',
              onTap: () {
                // This is just for development purposes
              },
              modernTheme: modernTheme,
            ),
        ],
      ),
    );
  }
  
  // Account management section
  Widget _buildAccountManagementSection(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Account',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.swap_horiz,
            title: 'Switch Account',
            onTap: () {
              _showAccountSwitchDialog();
            },
            modernTheme: modernTheme,
          ),
          _buildSettingsItem(
            icon: Icons.add_circle_outline,
            title: 'Add Account',
            onTap: () {
              _addNewAccount();
            },
            modernTheme: modernTheme,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ModernThemeExtension modernTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: modernTheme.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                ),
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
          color: context.modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
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
                  child: const Text('Save'),
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
          color: context.modernTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                    leading: CircleAvatar(
                      backgroundImage: account.image.isNotEmpty
                          ? NetworkImage(account.image) as ImageProvider
                          : const AssetImage('assets/images/user_icon.png') as ImageProvider,
                    ),
                    title: Text(
                      account.name,
                      style: TextStyle(
                        color: context.modernTheme.textColor,
                        fontWeight: isCurrentAccount ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      account.phoneNumber,
                      style: TextStyle(
                        color: context.modernTheme.textSecondaryColor,
                      ),
                    ),
                    trailing: isCurrentAccount
                        ? Icon(
                            Icons.check_circle,
                            color: context.modernTheme.primaryColor,
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
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error switching account: $e');
      }
    }
  }
  
  void _addNewAccount() {
    // Set current user to offline
    ref.read(authenticationProvider.notifier).updateUserStatus(value: false);
    
    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(
      context, 
      Constants.landingScreen, 
      (route) => false,
    );
  }
}