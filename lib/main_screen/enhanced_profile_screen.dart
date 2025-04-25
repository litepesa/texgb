import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/shared/theme/modern_colors.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/theme_manager.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_selector.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

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
  ThemeOption _currentTheme = ThemeOption.system;

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
        
        // Get current theme option from theme manager if available
        final themeManager = Provider.of<ThemeManager>(context, listen: false);
        _currentTheme = themeManager.currentTheme;
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
            toolbarColor: Theme.of(context).colorScheme.primary,
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
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
            ),
            const Divider(height: 0.5),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: modernTheme.primaryColor!.withOpacity(0.1),
                child: Icon(
                  Icons.camera_alt,
                  color: modernTheme.primaryColor,
                ),
              ),
              title: Text('Take Photo'),
              onTap: () => _selectImage(fromCamera: true),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: modernTheme.primaryColor!.withOpacity(0.1),
                child: Icon(
                  Icons.photo_library,
                  color: modernTheme.primaryColor,
                ),
              ),
              title: Text('Choose from Gallery'),
              onTap: () => _selectImage(fromCamera: false),
            ),
            if (context.read<AuthenticationProvider>().userModel!.image.isNotEmpty)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: ModernColors.error.withOpacity(0.1),
                  child: const Icon(Icons.delete, color: ModernColors.error),
                ),
                title: const Text('Remove Current Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemovePhotoConfirmation();
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for removing profile photo
  void _showRemovePhotoConfirmation() {
    final modernTheme = context.modernTheme;
    
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
            style: TextButton.styleFrom(foregroundColor: ModernColors.error),
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
      // First verify the user is authenticated
      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser == null) {
        throw Exception("User not authenticated");
      }
      
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      final String oldImageUrl = currentUser.image;
      
      // Upload new image to Firebase Storage
      final storage = FirebaseStorage.instance;
      
      // Make sure this path exactly matches your rules structure
      // Using 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg' to ensure uniqueness
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String imagePath = 'userImages/${currentUser.uid}/$fileName';
      final reference = storage.ref().child(imagePath);
      
      // Add metadata to help with debugging and content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': currentUser.uid},
      );
      
      // Upload with progress monitoring
      final uploadTask = reference.putFile(_selectedImage!, metadata);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      }, onError: (e) {
        print('Upload error: $e');
      });
      
      // Wait for completion
      await uploadTask;
      
      // Get the download URL
      final String newImageUrl = await reference.getDownloadURL();
      
      // Debug print the new URL
      print('New image URL: $newImageUrl');
      
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
      
      // Keep the selected image until widget rebuilds with network image
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _selectedImage = null;
          });
        }
      });
      
      showSnackBar(context, 'Profile photo updated successfully');
    } catch (e) {
      print('Error updating profile photo: $e');
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

  // Set theme based on the selected theme option
  void _setTheme(ThemeOption option) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    themeManager.setTheme(option);
    setState(() {
      _currentTheme = option;
      isDarkMode = option == ThemeOption.dark || 
        (option == ThemeOption.system && Theme.of(context).brightness == Brightness.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get theme information using modern theme extensions
    final modernTheme = context.modernTheme;
    final animTheme = context.animationTheme;
    
    // Extract colors from modern theme
    final primaryColor = modernTheme.primaryColor!;
    final backgroundColor = modernTheme.backgroundColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    // Check the current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final currentUser = context.watch<AuthenticationProvider>().userModel;
    
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
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
                    color: surfaceColor,
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
                        // Add back button at the top
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: AppBarBackButton(
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // User image with edit button - ENHANCED VERSION
                        Stack(
                          children: [
                            // Profile image container
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Hero(
                                tag: 'profile-image',
                                child: Stack(
                                  children: [
                                    // Base CircleAvatar with default background
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[300],
                                    ),
                                    
                                    // Choose which image to display based on state
                                    if (_selectedImage != null)
                                      // Show local file image if selected
                                      ClipOval(
                                        child: Image.file(
                                          _selectedImage!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else if (currentUser.image.isNotEmpty)
                                      // Show network image with error handling
                                      ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: currentUser.image,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) {
                                            print('Error loading image: $error, URL: $url');
                                            return Image.asset(
                                              AssetsManager.userImage,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      // Show default user image
                                      ClipOval(
                                        child: Image.asset(
                                          AssetsManager.userImage,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                  ],
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
                                    color: primaryColor,
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
                            color: textColor,
                          ),
                        ),
                        
                        // User phone number
                        Text(
                          currentUser.phoneNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textSecondaryColor,
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                filled: true,
                                fillColor: modernTheme.surfaceVariantColor,
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
                                color: textColor,
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
                          iconColor: ModernColors.error,
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
                          iconColor: isDarkMode ? ModernColors.accentBlue : ModernColors.accentTealBlue,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Constants.contactsScreen,
                            );
                          },
                        ),
                        
                        // Theme section
                        _buildListTile(
                          icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          title: 'Appearance',
                          subtitle: _getThemeSubtitle(),
                          iconColor: isDarkMode ? ModernColors.primaryGreen : ModernColors.primaryTeal,
                          trailing: IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              // Show theme selector
                              showThemeSelector(context);
                            },
                          ),
                          onTap: () {
                            // Toggle between light and dark
                            setState(() {
                              if (isDarkMode) {
                                _setTheme(ThemeOption.light);
                              } else {
                                _setTheme(ThemeOption.dark);
                              }
                            });
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
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to get theme subtitle text
  String _getThemeSubtitle() {
    switch (_currentTheme) {
      case ThemeOption.light:
        return 'Light Mode';
      case ThemeOption.dark:
        return 'Dark Mode';
      case ThemeOption.system:
        return 'System Default';
      default:
        return 'System Default';
    }
  }

  // Helper widget for profile sections
  Widget _buildProfileSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final modernTheme = context.modernTheme;
    final sectionBgColor = modernTheme.surfaceColor!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: sectionBgColor,
        borderRadius: BorderRadius.circular(16),
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
                    color: modernTheme.textColor,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: modernTheme.dividerColor,
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
    final modernTheme = context.modernTheme;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: modernTheme.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: modernTheme.textSecondaryColor,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}