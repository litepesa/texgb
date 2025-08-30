import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({super.key});

  @override
  ConsumerState<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  File? finalFileImage;
  bool isImageProcessing = false;
  bool isSubmitting = false;
  bool _hasInteractedWithName = false;
  bool _hasInteractedWithBio = false;

  @override
  void initState() {
    super.initState();
    _bioController.text = "New to WeiBao, excited to watch amazing dramas!";
    
    // Add listener for focus changes to track user interaction
    _nameFocusNode.addListener(_onNameFocusChange);
    _bioFocusNode.addListener(_onBioFocusChange);
    
    // Listen to keyboard changes to handle scrolling
    _bioFocusNode.addListener(_handleBioFocusChange);
    
    // Auto-focus name field after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus && !_hasInteractedWithName) {
      setState(() {
        _hasInteractedWithName = true;
      });
    }
  }

  void _onBioFocusChange() {
    if (!_bioFocusNode.hasFocus && !_hasInteractedWithBio) {
      setState(() {
        _hasInteractedWithBio = true;
      });
    }
  }

  void _handleBioFocusChange() {
    if (_bioFocusNode.hasFocus) {
      // Scroll to show the bio field when keyboard appears
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _bioFocusNode.hasFocus) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _nameFocusNode.removeListener(_onNameFocusChange);
    _bioFocusNode.removeListener(_onBioFocusChange);
    _nameFocusNode.removeListener(_handleBioFocusChange);
    _nameFocusNode.dispose();
    _bioFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> selectImageFromGallery() async {
    if (!mounted) return;
    
    // Ensure keyboard is dismissed when selecting an image
    FocusScope.of(context).unfocus();
    
    // Close the dialog first
    Navigator.pop(context);
    
    setState(() => isImageProcessing = true);
    
    try {
      final image = await pickImage(
        fromCamera: false,
        onFail: (message) => showSnackBar(context, message),
      );

      if (image != null) {
        await cropImage(image.path);
      } else {
        if (mounted) {
          showSnackBar(context, 'No image selected');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error processing image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isImageProcessing = false);
      }
    }
  }

  Future<void> selectImageFromCamera() async {
    if (!mounted) return;
    
    // Ensure keyboard is dismissed when selecting an image
    FocusScope.of(context).unfocus();
    
    // Close the dialog first
    Navigator.pop(context);
    
    setState(() => isImageProcessing = true);
    
    try {
      final image = await pickImage(
        fromCamera: true,
        onFail: (message) => showSnackBar(context, message),
      );

      if (image != null) {
        await cropImage(image.path);
      } else {
        if (mounted) {
          showSnackBar(context, 'No image captured');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error processing image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => isImageProcessing = false);
      }
    }
  }

  Future<void> cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      maxHeight: 800,
      maxWidth: 800,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Photo',
          toolbarColor: Colors.white,
          toolbarWidgetColor: const Color(0xFFFE2C55),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          statusBarColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFFE2C55),
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
          aspectRatioLockEnabled: true,
          title: 'Crop Image',
        ),
      ],
    );

    if (mounted && croppedFile != null) {
      setState(() => finalFileImage = File(croppedFile.path));
    } else if (mounted) {
      showSnackBar(context, 'Image cropping cancelled');
    }
  }

  void showImagePickerSheet() {
    // Ensure keyboard is dismissed when showing sheet
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFFFE2C55)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Choose Profile Photo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              _PickerOptionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Take a Photo',
                onTap: selectImageFromCamera,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              _PickerOptionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                onTap: selectImageFromGallery,
              ),
              if (finalFileImage != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _PickerOptionTile(
                  icon: Icons.delete_outline,
                  title: 'Remove Photo',
                  iconColor: Colors.red.shade400,
                  textColor: Colors.red.shade400,
                  onTap: () {
                    setState(() => finalFileImage = null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveUserDataToBackend() async {
    // Validate form and ensure mounted
    if (!_formKey.currentState!.validate() || !mounted) return;
    
    setState(() => isSubmitting = true);

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final authState = ref.read(authenticationProvider).value;

      if (authState == null || authState.uid == null) {
        throw Exception('Authentication data is missing. Please try signing in again.');
      }

      // Get the current Firebase user to ensure we have the phone number
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Firebase user not found. Please sign in again.');
      }

      // Get existing user from backend if it exists
      final existingUser = await authNotifier.getUserDataFromBackend();
      
      // Create updated user model - either from existing or create new
      final UserModel userModel;
      if (existingUser != null) {
        // Update existing user with complete profile info
        userModel = existingUser.copyWith(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      } else {
        // Create new user with complete profile info
        userModel = UserModel.create(
          uid: authState.uid!,
          name: _nameController.text.trim(),
          email: currentUser.email ?? '',
          phoneNumber: currentUser.phoneNumber ?? '',
          bio: _bioController.text.trim(),
          userType: UserType.viewer,
        );
      }

      debugPrint('Attempting to save user: ${userModel.toMap()}');

      // Save user data to backend
      await authNotifier.saveUserDataToBackend(
        userModel: userModel,
        fileImage: finalFileImage,
        onSuccess: () async {
          debugPrint('User data saved successfully');
          // Save to shared preferences and navigate
          await authNotifier.saveUserDataToSharedPreferences();
          if (mounted) {
            navigateToHomeScreen();
          }
        },
        onFail: () {
          debugPrint('Failed to save user data');
          if (mounted) {
            showSnackBar(context, 'Failed to create profile. Please check your connection and try again.');
            setState(() => isSubmitting = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error in saveUserDataToBackend: $e');
      if (mounted) {
        setState(() => isSubmitting = false);
        showSnackBar(context, 'Error: ${e.toString()}');
      }
    }
  }

  void navigateToHomeScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Constants.homeScreen,
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isEmpty && finalFileImage == null) return true;
    
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Discard changes?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'You have unsaved changes. Are you sure you want to go back?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch only what's needed from the auth state
    final isLoading = ref.watch(authenticationProvider.select(
      (state) => state.maybeWhen(
        data: (data) => data.isLoading || isSubmitting,
        orElse: () => false,
      ),
    ));

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
          ),
          leading: AppBarBackButton(
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: Text(
            'Create Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Main scrollable content
              SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: isKeyboardVisible 
                    ? keyboardHeight + 80 // Extra space when keyboard is visible
                    : 100, // Normal bottom padding
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile image with optimized spacing
                      _ProfileImageSelector(
                        finalFileImage: finalFileImage,
                        onTap: showImagePickerSheet,
                        isProcessing: isImageProcessing,
                      ),
                      
                      SizedBox(height: isKeyboardVisible ? 20 : 40),
                      
                      // Name field with improved validation
                      _CustomTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return 'Please enter at least 3 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Name must be less than 50 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _bioFocusNode.requestFocus(),
                        onChanged: (text) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bio field with smart keyboard handling
                      _CustomTextField(
                        controller: _bioController,
                        focusNode: _bioFocusNode,
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icons.description_outlined,
                        maxLines: isKeyboardVisible ? 2 : 3, // Reduce lines when keyboard is visible
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value != null && value.trim().length > 150) {
                            return 'Bio must be less than 150 characters';
                          }
                          return null;
                        },
                        onChanged: (text) => setState(() {}),
                        suffixIcon: _bioController.text.isNotEmpty && 
                              _bioController.text != "New to WeiBao, excited to watch amazing dramas!"
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _bioController.text = "New to WeiBao, excited to watch amazing dramas!";
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Fixed bottom action button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24, 
                    12, 
                    24, 
                    isKeyboardVisible 
                      ? 12 // Reduced padding when keyboard is visible
                      : MediaQuery.of(context).padding.bottom + 12
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _ActionButton(
                    isLoading: isLoading,
                    onPressed: isLoading ? null : saveUserDataToBackend,
                  ),
                ),
              ),
              
              // Loading overlay
              if (isImageProcessing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFFFE2C55),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Processing image...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced profile image selector component
class _ProfileImageSelector extends StatelessWidget {
  final File? finalFileImage;
  final VoidCallback onTap;
  final bool isProcessing;

  const _ProfileImageSelector({
    required this.finalFileImage, 
    required this.onTap,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profile_image',
      child: GestureDetector(
        onTap: isProcessing ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade50,
            border: Border.all(
              color: finalFileImage != null 
                  ? const Color(0xFFFE2C55) 
                  : Colors.grey.shade300,
              width: finalFileImage != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: finalFileImage != null
                    ? const Color(0xFFFE2C55).withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              children: [
                Center(
                  child: finalFileImage != null
                      ? Image.file(
                          finalFileImage!,
                          fit: BoxFit.cover,
                          width: 140,
                          height: 140,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 45,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),

                // Edit icon overlay
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFE2C55),
                            ),
                          )
                        : const Icon(
                            Icons.edit,
                            color: Color(0xFFFE2C55),
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom text field component with enhanced styling
class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final int maxLines;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;

  const _CustomTextField({
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.maxLines = 1,
    required this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      textCapitalization: maxLines > 1 
          ? TextCapitalization.sentences 
          : TextCapitalization.words,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 16,
        ),
        labelText: labelText,
        labelStyle: TextStyle(
          color: focusNode.hasFocus
              ? const Color(0xFFFE2C55)
              : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
          child: Icon(
            prefixIcon,
            color: focusNode.hasFocus || controller.text.isNotEmpty
                ? const Color(0xFFFE2C55)
                : Colors.grey.shade600,
          ),
        ),
        suffixIcon: suffixIcon != null 
            ? Padding(
                padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
                child: suffixIcon,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFFE2C55),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}

// Picker option tile component
class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;

  const _PickerOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFFFE2C55),
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Enhanced action button component
class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: isLoading 
                ? Colors.grey.withOpacity(0.1) 
                : const Color(0xFFFE2C55).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
                  child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
    );
  }
}