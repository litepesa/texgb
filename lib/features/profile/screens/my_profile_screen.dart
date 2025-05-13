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
    
    // Remove the system UI mode change to prevent issues with the home screen
  }
  
  @override
  void dispose() {
    // Remove the system UI mode change to prevent issues with the home screen
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header - Full Width Design with Title and Edit Button
              _buildImmersiveProfileHeader(user, modernTheme),
              
              // Profile Information
              _buildProfileInfo(user, modernTheme),
              
              // Theme Selector
              _buildThemeSelector(modernTheme, isDarkMode),
              
              // Account Settings
              _buildAccountSettings(modernTheme),
              
              // Account management section
              _buildAccountManagementSection(modernTheme),
              
              // Add extra padding at the bottom for the bottom nav bar
              SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
            ],
          ),
        ),
      ),
    );
  }
  
  // Immersive profile header with integrated title and edit button
  Widget _buildImmersiveProfileHeader(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
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
          // Title Row with My Profile text and Edit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, Constants.editProfileScreen);
                  },
                ),
              ],
            ),
          ),
          
          // Profile Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null 
                          ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : user.image.isNotEmpty 
                            ? Image.network(
                                user.image,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                
                // Name and Phone - Center Aligned
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Switch Account Button - Better Styling
                GestureDetector(
                  onTap: _showAccountSwitchDialog,
                  child: Container(
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
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Switch Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
  
  Widget _buildProfileInfo(UserModel user, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor!,
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
        color: modernTheme.surfaceColor!,
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
        color: modernTheme.surfaceColor!,
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
        color: modernTheme.surfaceColor!,
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
          color: context.modernTheme.surfaceColor!,
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
          color: context.modernTheme.surfaceColor!,
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