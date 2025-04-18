import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:textgb/utilities/assets_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen> {
  final TextEditingController _aboutMeController = TextEditingController();
  bool _isEditingAboutMe = false;
  bool _isUpdatingProfile = false;
  File? _selectedImage;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the about me text controller with current value when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<AuthenticationProvider>().userModel;
      if (currentUser != null) {
        _aboutMeController.text = currentUser.aboutMe;
      }
      
      // Set theme state AFTER widgets are built
      setState(() {
        isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    super.dispose();
  }

  // Select and crop new profile image
  Future<void> _selectImage({required bool fromCamera}) async {
    try {
      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          showSnackBar(context, message);
        },
      );
      
      if (pickedImage == null) return;
      
      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        maxHeight: 800,
        maxWidth: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
        
        // Upload the new image immediately
        _updateProfileImage();
      }
      
      Navigator.pop(context); // Close bottom sheet
    } catch (e) {
      showSnackBar(context, 'Error selecting image: $e');
    }
  }

  // Show bottom sheet for image selection options
  void _showImagePickerOptions() {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: themeExtension?.appBarColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
            const Divider(height: 0.5),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: themeExtension?.accentColor?.withOpacity(0.1),
                child: Icon(
                  Icons.camera_alt,
                  color: themeExtension?.accentColor,
                ),
              ),
              title: Text('Take Photo'),
              onTap: () => _selectImage(fromCamera: true),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: themeExtension?.accentColor?.withOpacity(0.1),
                child: Icon(
                  Icons.photo_library,
                  color: themeExtension?.accentColor,
                ),
              ),
              title: Text('Choose from Gallery'),
              onTap: () => _selectImage(fromCamera: false),
            ),
            if (context.read<AuthenticationProvider>().userModel!.image.isNotEmpty)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Remove Current Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemovePhotoConfirmation();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for removing profile photo
  void _showRemovePhotoConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _removeProfileImage();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Upload new profile image and delete old one
  Future<void> _updateProfileImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isUpdatingProfile = true;
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      final String oldImageUrl = currentUser.image;
      
      // Upload new image to Firebase Storage
      final storage = FirebaseStorage.instance;
      final String imagePath = '${Constants.userImages}/${currentUser.uid}';
      final reference = storage.ref().child(imagePath);
      
      // Upload new image
      await reference.putFile(_selectedImage!);
      final String newImageUrl = await reference.getDownloadURL();
      
      // Update user model with new image URL
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: currentUser.name,
        phoneNumber: currentUser.phoneNumber,
        image: newImageUrl,
        token: currentUser.token,
        aboutMe: currentUser.aboutMe,
        lastSeen: currentUser.lastSeen,
        createdAt: currentUser.createdAt,
        isOnline: currentUser.isOnline,
        contactsUIDs: currentUser.contactsUIDs,
        blockedUIDs: currentUser.blockedUIDs,
      );
      
      // Save updated user to Firestore
      await authProvider.updateUserProfile(updatedUser);
      
      // If there was a previous image, delete it
      if (oldImageUrl.isNotEmpty && oldImageUrl != newImageUrl) {
        try {
          // Extract the old image path from the URL
          final oldImageRef = storage.refFromURL(oldImageUrl);
          await oldImageRef.delete();
        } catch (e) {
          // Handle error but don't stop execution
          print('Error deleting old image: $e');
        }
      }
      
      setState(() {
        _selectedImage = null;
      });
      
      showSnackBar(context, 'Profile photo updated successfully');
    } catch (e) {
      showSnackBar(context, 'Failed to update profile photo: $e');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  // Remove profile image
  Future<void> _removeProfileImage() async {
    setState(() {
      _isUpdatingProfile = true;
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      final String oldImageUrl = currentUser.image;
      
      if (oldImageUrl.isEmpty) {
        // No image to remove
        setState(() {
          _isUpdatingProfile = false;
        });
        return;
      }
      
      // Update user model with empty image URL
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: currentUser.name,
        phoneNumber: currentUser.phoneNumber,
        image: '', // Empty image URL
        token: currentUser.token,
        aboutMe: currentUser.aboutMe,
        lastSeen: currentUser.lastSeen,
        createdAt: currentUser.createdAt,
        isOnline: currentUser.isOnline,
        contactsUIDs: currentUser.contactsUIDs,
        blockedUIDs: currentUser.blockedUIDs,
      );
      
      // Save updated user to Firestore
      await authProvider.updateUserProfile(updatedUser);
      
      // Delete image from storage
      try {
        final storage = FirebaseStorage.instance;
        final oldImageRef = storage.refFromURL(oldImageUrl);
        await oldImageRef.delete();
      } catch (e) {
        // Handle error but don't stop execution
        print('Error deleting old image: $e');
      }
      
      showSnackBar(context, 'Profile photo removed');
    } catch (e) {
      showSnackBar(context, 'Failed to remove profile photo: $e');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  // Update about me text
  Future<void> _updateAboutMe() async {
    final newAboutMe = _aboutMeController.text.trim();
    if (newAboutMe.isEmpty) {
      showSnackBar(context, 'About me cannot be empty');
      return;
    }
    
    setState(() {
      _isUpdatingProfile = true;
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      
      // Only update if the text has changed
      if (newAboutMe == currentUser.aboutMe) {
        setState(() {
          _isEditingAboutMe = false;
          _isUpdatingProfile = false;
        });
        return;
      }
      
      // Update user model with new about me
      final updatedUser = UserModel(
        uid: currentUser.uid,
        name: currentUser.name,
        phoneNumber: currentUser.phoneNumber,
        image: currentUser.image,
        token: currentUser.token,
        aboutMe: newAboutMe,
        lastSeen: currentUser.lastSeen,
        createdAt: currentUser.createdAt,
        isOnline: currentUser.isOnline,
        contactsUIDs: currentUser.contactsUIDs,
        blockedUIDs: currentUser.blockedUIDs,
      );
      
      // Save updated user to Firestore
      await authProvider.updateUserProfile(updatedUser);
      
      showSnackBar(context, 'About me updated successfully');
    } catch (e) {
      showSnackBar(context, 'Failed to update about me: $e');
    } finally {
      setState(() {
        _isEditingAboutMe = false;
        _isUpdatingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme information in the build method
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? Theme.of(context).primaryColor;
    final appBarColor = themeExtension?.appBarColor ?? Theme.of(context).appBarTheme.backgroundColor;
    final backgroundColor = themeExtension?.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    
    // Check the current theme in the build method (more reliable)
    final currentTheme = Theme.of(context).brightness;
    isDarkMode = currentTheme == Brightness.dark;
    
    final currentUser = context.watch<AuthenticationProvider>().userModel;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Profile header with background
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: appBarColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // User image with edit button
                        Stack(
                          children: [
                            // Profile image
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Hero(
                                tag: 'profile-image',
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (currentUser.image.isNotEmpty
                                          ? CachedNetworkImageProvider(currentUser.image) as ImageProvider
                                          : const AssetImage(AssetsManager.userImage)),
                                ),
                              ),
                            ),
                            
                            // Edit button
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: backgroundColor,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User name
                        Text(
                          currentUser.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        
                        // User phone number
                        Text(
                          currentUser.phoneNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: themeExtension?.greyColor ?? Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Profile sections
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  
                  // About Me section
                  _buildProfileSection(
                    title: 'About Me',
                    trailing: _isEditingAboutMe
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _aboutMeController.text = currentUser.aboutMe;
                                    _isEditingAboutMe = false;
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: _updateAboutMe,
                                child: const Text('Save'),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _isEditingAboutMe = true;
                              });
                            },
                          ),
                    child: _isEditingAboutMe
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: TextField(
                              controller: _aboutMeController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tell us something about yourself...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              currentUser.aboutMe,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Privacy section
                  _buildProfileSection(
                    title: 'Privacy',
                    child: Column(
                      children: [
                        // Blocked Contacts
                        _buildListTile(
                          icon: Icons.block,
                          title: 'Blocked Contacts',
                          subtitle: 'Manage your blocked contacts',
                          iconColor: Colors.red,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Constants.blockedContactsScreen,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Account section
                  _buildProfileSection(
                    title: 'Account',
                    child: Column(
                      children: [
                        // Contacts
                        _buildListTile(
                          icon: Icons.people,
                          title: 'Contacts',
                          subtitle: 'Manage your contacts',
                          iconColor: Colors.blue,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Constants.contactsScreen,
                            );
                          },
                        ),
                        
                        // Appearance
                        _buildListTile(
                          icon: isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                          title: 'Appearance',
                          subtitle: isDarkMode ? 'Dark Mode' : 'Light Mode',
                          iconColor: isDarkMode ? Colors.indigo : Colors.amber,
                          trailing: Switch(
                            value: isDarkMode,
                            activeColor: accentColor,
                            onChanged: (value) {
                              setState(() {
                                isDarkMode = value;
                              });
                              // Check if the value is true
                              if (value) {
                                // Set the theme mode to dark
                                AdaptiveTheme.of(context).setDark();
                              } else {
                                // Set the theme mode to light
                                AdaptiveTheme.of(context).setLight();
                              }
                            },
                          ),
                          onTap: () {
                            setState(() {
                              isDarkMode = !isDarkMode;
                            });
                            // Toggle theme
                            if (isDarkMode) {
                              AdaptiveTheme.of(context).setDark();
                            } else {
                              AdaptiveTheme.of(context).setLight();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ]),
              ),
            ],
          ),
          
          // Loading overlay
          if (_isUpdatingProfile)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for profile sections
  Widget _buildProfileSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final sectionBgColor = themeExtension?.receiverBubbleColor ?? Theme.of(context).cardColor;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: sectionBgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: Colors.grey.withOpacity(0.2),
            thickness: 1,
          ),
          
          // Section content
          child,
        ],
      ),
    );
  }

  // Helper widget for list tiles
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}