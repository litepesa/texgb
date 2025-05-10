import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({super.key});

  @override
  ConsumerState<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? finalFileImage;
  bool isImageProcessing = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _aboutMeController.text = "Hey there, I'm using WeiBao";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> selectImage(bool fromCamera) async {
    if (!mounted) return;
    
    // Close the bottom sheet first
    Navigator.pop(context);
    
    setState(() => isImageProcessing = true);
    
    try {
      final image = await pickImage(
        fromCamera: fromCamera,
        onFail: (message) => showSnackBar(context, message),
      );

      if (image != null) {
        await cropImage(image.path);
      } else {
        showSnackBar(context, 'No image selected');
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
          toolbarWidgetColor: const Color(0xFF09BB07),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          statusBarColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF09BB07),
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

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
              child: Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              onTap: () => selectImage(true),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF09BB07).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF09BB07)),
              ),
              title: const Text('Take Photo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const Divider(),
            ListTile(
              onTap: () => selectImage(false),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF09BB07).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image, color: Color(0xFF09BB07)),
              ),
              title: const Text('Choose from Gallery'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveUserDataToFireStore() async {
    if (!_formKey.currentState!.validate() || !mounted) return;
    
    setState(() => isSubmitting = true);

    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final authState = ref.read(authenticationProvider).value;

      if (authState == null || authState.uid == null || authState.phoneNumber == null) {
        throw Exception('Authentication data is missing');
      }

      final userModel = UserModel(
        uid: authState.uid!,
        name: _nameController.text.trim(),
        phoneNumber: authState.phoneNumber!,
        image: '',
        token: '',
        aboutMe: _aboutMeController.text.trim(),
        lastSeen: '',
        createdAt: '',
        isOnline: true,
        contactsUIDs: [],
        blockedUIDs: [],
      );

      await authNotifier.saveUserDataToFireStore(
        userModel: userModel,
        fileImage: finalFileImage,
        onSuccess: () async {
          await authNotifier.saveUserDataToSharedPreferences();
          if (mounted) navigateToHomeScreen();
        },
        onFail: () {
          if (mounted) {
            showSnackBar(context, 'Failed to save user data');
            setState(() => isSubmitting = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => isSubmitting = false);
        showSnackBar(context, 'An error occurred: ${e.toString()}');
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
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to go back?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authenticationProvider.select(
      (state) => state.maybeWhen(
        data: (data) => data.isLoading || isSubmitting,
        orElse: () => false,
      ),
    ));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: AppBarBackButton(
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: const Text(
            'Set Up Your Profile',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile image selector
                          Tooltip(
                            message: 'Tap to select image',
                            child: GestureDetector(
                              onTap: showBottomSheet,
                              child: Center(
                                child: Stack(
                                  children: [
                                    // Profile image
                                    Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                        border: Border.all(
                                          color: const Color(0xFF09BB07).withOpacity(0.4),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: finalFileImage != null
                                            ? Image.file(
                                                finalFileImage!,
                                                fit: BoxFit.cover,
                                                width: 130,
                                                height: 130,
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    // Camera icon
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF09BB07),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              spreadRadius: 1,
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Helper text
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0, bottom: 36.0),
                            child: Text(
                              'Add a profile photo to personalize your account',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          // Name field
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().length < 3) {
                                return 'Please enter at least 3 characters';
                              }
                              return null;
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black, // Ensuring text is visible
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              labelText: 'Your Name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF09BB07), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              // Add a clear button when text is entered
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _nameController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (text) {
                              // Force refresh to show/hide clear button
                              setState(() {});
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // About me field
                          TextFormField(
                            controller: _aboutMeController,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black, // Ensuring text is visible
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tell us about yourself',
                              labelText: 'About Me',
                              prefixIcon: Icon(
                                Icons.description_outlined,
                                color: Colors.grey.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF09BB07), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Continue button
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF09BB07).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 0,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF09BB07),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : saveUserDataToFireStore,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Get Started',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isImageProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF09BB07),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}