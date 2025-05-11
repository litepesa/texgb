import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? _profileImage;
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  
  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _aboutController = TextEditingController(text: user?.aboutMe ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
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

    // Validate fields
    final name = _nameController.text.trim();
    final about = _aboutController.text.trim();
    
    if (name.isEmpty) {
      showSnackBar(context, 'Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
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
        name: name,
        aboutMe: about,
        image: imageUrl,
      );

      // Save to Firebase
      await ref.read(authenticationProvider.notifier).updateUserProfile(updatedUser);
      
      if (mounted) {
        showSnackBar(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            Center(
              child: Stack(
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
                          color: modernTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: modernTheme.backgroundColor!,
                            width: 2,
                          ),
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
            ),
            
            const SizedBox(height: 32),
            
            // Name Field
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(
                        color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: modernTheme.surfaceVariantColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // About Field
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Me',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _aboutController,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                    ),
                    maxLines: 4,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Tell us a bit about yourself...',
                      hintStyle: TextStyle(
                        color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: modernTheme.surfaceVariantColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
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
            
            const SizedBox(height: 16),
            
            // Phone Number Info
            Container(
              width: double.infinity,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.phoneNumber,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone number cannot be changed',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
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
}