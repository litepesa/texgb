// lib/features/users/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/constants.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel? user;
  
  const EditProfileScreen({
    super.key, 
    this.user,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  File? _profileImage;
  File? _coverImage;
  bool _isProfileImageChanged = false;
  bool _isCoverImageChanged = false;
  
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _mpesaController;
  
  UserModel? get currentUser => widget.user ?? ref.read(currentUserProvider);
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _aboutController = TextEditingController(text: currentUser?.bio ?? '');
    // Format M-Pesa number for display (remove 254 prefix if present)
    String mpesaDisplay = '';
    if (currentUser?.mpesaNumber != null && currentUser!.mpesaNumber!.isNotEmpty) {
      final mpesa = currentUser!.mpesaNumber!;
      if (mpesa.startsWith('254') && mpesa.length == 12) {
        mpesaDisplay = '0${mpesa.substring(3)}';
      } else {
        mpesaDisplay = mpesa;
      }
    }
    _mpesaController = TextEditingController(text: mpesaDisplay);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _mpesaController.dispose();
    super.dispose();
  }

  // Validate and format M-Pesa number to 254XXXXXXXXX format
  String? _validateAndFormatMpesa(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    String cleaned = value.replaceAll(RegExp(r'\D'), '');
    
    // If starts with 0 and has 10 digits (0712345678), convert to international format
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      String withoutZero = cleaned.substring(1); // Remove leading 0
      // Validate it's a valid Kenyan mobile number (7XX, 1XX)
      if (withoutZero.startsWith('7') || withoutZero.startsWith('1')) {
        return '254$withoutZero';
      }
    }
    
    // If has 9 digits (712345678), assume missing country code
    if (cleaned.length == 9) {
      // Validate it's a valid Kenyan mobile number (7XX, 1XX)
      if (cleaned.startsWith('7') || cleaned.startsWith('1')) {
        return '254$cleaned';
      }
    }
    
    // If already in international format (254712345678)
    if (cleaned.length == 12 && cleaned.startsWith('254')) {
      String localPart = cleaned.substring(3);
      // Validate the local part is valid Kenyan mobile (7XX, 1XX)
      if (localPart.startsWith('7') || localPart.startsWith('1')) {
        return cleaned;
      }
    }
    
    return null; // Invalid format
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
        _isProfileImageChanged = true;
      });
    }
  }

  // Pick cover image
  Future<void> _pickCoverImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 600,
    );
    
    if (pickedImage != null) {
      setState(() {
        _coverImage = File(pickedImage.path);
        _isCoverImageChanged = true;
      });
    }
  }

  // Show image picker options
  Future<void> _showImagePickerOptions(bool isProfileImage) async {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isProfileImage ? 'Profile Image' : 'Cover Image',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    isProfileImage ? _pickProfileImage() : _pickCoverImage();
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera(isProfileImage);
                  },
                ),
                if ((isProfileImage && (currentUser?.profileImage.isNotEmpty == true || _isProfileImageChanged)) ||
                    (!isProfileImage && (currentUser?.coverImage.isNotEmpty == true || _isCoverImageChanged)))
                  _buildImageOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage(isProfileImage);
                    },
                    isDestructive: true,
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDestructive 
                  ? Colors.red.withOpacity(0.1)
                  : modernTheme.primaryColor?.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive 
                  ? Colors.red
                  : modernTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDestructive 
                  ? Colors.red
                  : modernTheme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera(bool isProfileImage) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: isProfileImage ? 800 : 1200,
      maxHeight: isProfileImage ? 800 : 600,
    );
    
    if (pickedImage != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = File(pickedImage.path);
          _isProfileImageChanged = true;
        } else {
          _coverImage = File(pickedImage.path);
          _isCoverImageChanged = true;
        }
      });
    }
  }

  void _removeImage(bool isProfileImage) {
    setState(() {
      if (isProfileImage) {
        _profileImage = null;
        _isProfileImageChanged = true;
      } else {
        _coverImage = null;
        _isCoverImageChanged = true;
      }
    });
  }

  // Submit form to update profile
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (currentUser == null) {
        showSnackBar(context, 'User not found');
        return;
      }

      // Validate name length
      if (_nameController.text.trim().length < Constants.minNameLength) {
        showSnackBar(context, Constants.nameTooShort);
        return;
      }
      
      if (_nameController.text.trim().length > Constants.maxNameLength) {
        showSnackBar(context, Constants.nameTooLong);
        return;
      }

      // Validate about length
      if (_aboutController.text.trim().length < Constants.minAboutLength) {
        showSnackBar(context, Constants.aboutTooShort);
        return;
      }
      
      if (_aboutController.text.trim().length > Constants.maxAboutLength) {
        showSnackBar(context, Constants.aboutTooLong);
        return;
      }
      
      // Validate and format M-Pesa number to ensure 254XXXXXXXXX format
      String? formattedMpesa;
      if (_mpesaController.text.trim().isNotEmpty) {
        formattedMpesa = _validateAndFormatMpesa(_mpesaController.text.trim());
        if (formattedMpesa == null) {
          showSnackBar(context, 'Please enter a valid Kenyan mobile number (e.g., 0712345678 or 0112345678)');
          return;
        }
      }

      // Create updated user model
      final updatedUser = currentUser!.copyWith(
        name: _nameController.text.trim(),
        bio: _aboutController.text.trim(),
        mpesaNumber: formattedMpesa,
      );
      
      try {
        await ref.read(authenticationProvider.notifier).updateUserProfile(
          user: updatedUser,
          profileImage: _isProfileImageChanged ? _profileImage : null,
          coverImage: _isCoverImageChanged ? _coverImage : null,
        );
        
        if (mounted) {
          showSnackBar(context, Constants.profileUpdated);
          
          // Wait a moment before navigating back
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context, true); // Return true to indicate success
            }
          });
        }
      } catch (error) {
        if (mounted) {
          showSnackBar(context, error.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    final isLoading = ref.watch(isAuthLoadingProvider);
    final modernTheme = context.modernTheme;
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: modernTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: modernTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: modernTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submitForm,
            child: Text(
              'Save',
              style: TextStyle(
                color: isLoading 
                    ? modernTheme.textSecondaryColor?.withOpacity(0.5)
                    : modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image picker
              Text(
                'Cover Image',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isLoading ? null : () => _showImagePickerOptions(false),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: modernTheme.surfaceColor?.withOpacity(0.5) ?? Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.grey,
                      width: 1,
                    ),
                    image: _getCoverImageProvider(),
                  ),
                  child: _buildCoverImageContent(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Profile image picker
              Text(
                'Profile Image *',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : () => _showImagePickerOptions(true),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceColor?.withOpacity(0.5) ?? Colors.grey[800],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.grey,
                        width: 2,
                      ),
                      image: _getProfileImageProvider(),
                    ),
                    child: _buildProfileImageContent(),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading indicator
              if (isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: modernTheme.surfaceColor?.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Updating profile...',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                  helperText: '${_nameController.text.length}/${Constants.maxNameLength}',
                  helperStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                style: TextStyle(color: modernTheme.textColor),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Constants.requiredField;
                  }
                  if (value.trim().length < Constants.minNameLength) {
                    return Constants.nameTooShort;
                  }
                  if (value.trim().length > Constants.maxNameLength) {
                    return Constants.nameTooLong;
                  }
                  return null;
                },
                enabled: !isLoading,
                maxLength: Constants.maxNameLength,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                onChanged: (value) => setState(() {}), // Update character count
              ),
              
              const SizedBox(height: 16),
              
              // About field
              TextFormField(
                controller: _aboutController,
                decoration: InputDecoration(
                  labelText: 'About *',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                  helperText: '${_aboutController.text.length}/${Constants.maxAboutLength}',
                  helperStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                style: TextStyle(color: modernTheme.textColor),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return Constants.requiredField;
                  }
                  if (value.trim().length < Constants.minAboutLength) {
                    return Constants.aboutTooShort;
                  }
                  if (value.trim().length > Constants.maxAboutLength) {
                    return Constants.aboutTooLong;
                  }
                  return null;
                },
                enabled: !isLoading,
                maxLength: Constants.maxAboutLength,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                onChanged: (value) => setState(() {}), // Update character count
              ),
              
              const SizedBox(height: 16),
              
              // M-Pesa number field
              TextFormField(
                controller: _mpesaController,
                decoration: InputDecoration(
                  labelText: 'M-Pesa Number (Optional)',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: modernTheme.surfaceColor?.withOpacity(0.3),
                  hintText: 'e.g. 0712345678 or 0112345678',
                  hintStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.5),
                  ),
                  helperText: 'Your M-Pesa number for receiving payments (254XXXXXXXXX format)',
                  helperStyle: TextStyle(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.account_balance_wallet,
                    color: modernTheme.primaryColor,
                  ),
                  suffixIcon: _mpesaController.text.isNotEmpty
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      : null,
                ),
                style: TextStyle(color: modernTheme.textColor),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10), // Limit to 10 digits for local format
                ],
                enabled: !isLoading,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final formatted = _validateAndFormatMpesa(value.trim());
                    if (formatted == null) {
                      return 'Enter a valid Kenyan mobile number (0712345678 or 0112345678)';
                    }
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Update suffix icon
              ),
              
              const SizedBox(height: 32),
              
              // Save button (alternative to header button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: modernTheme.primaryColor?.withOpacity(0.5),
                  ),
                  child: isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  DecorationImage? _getCoverImageProvider() {
    if (_isCoverImageChanged && _coverImage != null) {
      return DecorationImage(
        image: FileImage(_coverImage!),
        fit: BoxFit.cover,
      );
    } else if (!_isCoverImageChanged && currentUser?.coverImage.isNotEmpty == true) {
      return DecorationImage(
        image: NetworkImage(currentUser!.coverImage),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildCoverImageContent() {
    final modernTheme = context.modernTheme;
    final hasImage = (_isCoverImageChanged && _coverImage != null) || 
                    (!_isCoverImageChanged && currentUser?.coverImage.isNotEmpty == true);

    if (!hasImage) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            color: modernTheme.primaryColor,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Add Cover Image',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  DecorationImage? _getProfileImageProvider() {
    if (_isProfileImageChanged && _profileImage != null) {
      return DecorationImage(
        image: FileImage(_profileImage!),
        fit: BoxFit.cover,
      );
    } else if (!_isProfileImageChanged && currentUser?.profileImage.isNotEmpty == true) {
      return DecorationImage(
        image: NetworkImage(currentUser!.profileImage),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget? _buildProfileImageContent() {
    final modernTheme = context.modernTheme;
    final hasImage = (_isProfileImageChanged && _profileImage != null) || 
                    (!_isProfileImageChanged && currentUser?.profileImage.isNotEmpty == true);

    if (!hasImage) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            color: modernTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Add Photo',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: modernTheme.backgroundColor ?? Colors.white,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}