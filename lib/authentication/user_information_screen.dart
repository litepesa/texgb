import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';
import 'package:textgb/widgets/display_user_image.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? finalFileImage;
  bool isImageProcessing = false;

  @override
  void initState() {
    super.initState();
    _aboutMeController.text = "Hey there, I'm using TexGB";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> selectImage(bool fromCamera) async {
    setState(() {
      isImageProcessing = true;
    });

    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        showSnackBar(context, message);
      },
    );

    if (finalFileImage != null) {
      await cropImage(finalFileImage?.path);
    } else {
      showSnackBar(context, 'No image selected');
    }

    setState(() {
      isImageProcessing = false;
    });

    if (mounted) Navigator.pop(context);
  }

  Future<void> cropImage(filePath) async {
    if (filePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      } else {
        showSnackBar(context, 'Image cropping cancelled');
      }
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () => selectImage(true),
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () => selectImage(false),
              leading: const Icon(Icons.image),
              title: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  void saveUserDataToFireStore() async {
    final authProvider = context.read<AuthenticationProvider>();

    UserModel userModel = UserModel(
      uid: authProvider.uid!,
      name: _nameController.text.trim(),
      phoneNumber: authProvider.phoneNumber!,
      image: '',
      token: '',
      aboutMe: _aboutMeController.text.trim(),
      lastSeen: '',
      createdAt: '',
      isOnline: true,
      contactsUIDs: [],
      blockedUIDs: [],
    );

    authProvider.saveUserDataToFireStore(
      userModel: userModel,
      fileImage: finalFileImage,
      onSuccess: () async {
        await authProvider.saveUserDataToSharedPreferences();
        navigateToHomeScreen();
      },
      onFail: () async {
        showSnackBar(context, 'Failed to save user data');
      },
    );
  }

  void navigateToHomeScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Constants.homeScreen,
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty || finalFileImage != null) {
      return await showDialog(
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
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthenticationProvider>().isLoading;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          title: const Text('User Information'),
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
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
                        Tooltip(
                          message: 'Tap to select image',
                          child: DisplayUserImage(
                            finalFileImage: finalFileImage,
                            radius: 60,
                            onPressed: showBottomSheet,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: _nameController,
                          autofocus: true,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Enter at least 3 characters';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: 'Enter your name',
                            labelText: 'Enter your name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _aboutMeController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'About me',
                            labelText: 'About me',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      saveUserDataToFireStore();
                                    }
                                  },
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.orangeAccent,
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.5,
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
                      child: CircularProgressIndicator(),
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
