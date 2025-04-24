import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/theme/modern_colors.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _selectedMedia;
  StatusType _selectedType = StatusType.image;
  bool _isProcessing = false;
  
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(bool fromCamera) async {
    try {
      final File? pickedImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (String message) {
          showSnackBar(context, message);
        },
      );
      
      if (pickedImage == null) return;
      
      // Crop the image
      await _cropImage(pickedImage.path);
    } catch (e) {
      showSnackBar(context, 'Error selecting image: $e');
    }
  }
  
  Future<void> _pickVideo() async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final File? pickedVideo = await pickVideo(
        onFail: (String message) {
          showSnackBar(context, message);
        },
        maxDuration: const Duration(seconds: 30), // Limit to 30 seconds for status
      );
      
      setState(() {
        _isProcessing = false;
      });
      
      if (pickedVideo == null) return;
      
      setState(() {
        _selectedMedia = pickedVideo;
        _selectedType = StatusType.video;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showSnackBar(context, 'Error selecting video: $e');
    }
  }
  
  Future<void> _cropImage(String filePath) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16), // Portrait aspect ratio for status
        compressQuality: 90,
        maxHeight: 1920,
        maxWidth: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      
      setState(() {
        _isProcessing = false;
      });
      
      if (croppedFile != null) {
        setState(() {
          _selectedMedia = File(croppedFile.path);
          _selectedType = StatusType.image;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      showSnackBar(context, 'Error cropping image: $e');
    }
  }
  
  void _createStatus() async {
    if (_selectedMedia == null) {
      showSnackBar(context, 'Please select an image or video');
      return;
    }
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();
    
    await statusProvider.createStatus(
      currentUser: currentUser,
      mediaFile: _selectedMedia!,
      type: _selectedType,
      caption: _captionController.text.trim(),
      onSuccess: () {
        Navigator.of(context).pop(); // Return to the status screen
        showSnackBar(context, 'Status created successfully');
      },
      onError: (error) {
        showSnackBar(context, 'Error creating status: $error');
      },
    );
  }
  
  void _showMediaPicker() {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: modernTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: modernTheme.textSecondaryColor!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Create Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
            ),
            
            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: ModernColors.primaryBlue),
              ),
              title: Text(
                'Take a photo',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(true);
              },
            ),
            
            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: ModernColors.success),
              ),
              title: Text(
                'Choose from gallery',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(false);
              },
            ),
            
            // Video option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam, color: ModernColors.error),
              ),
              title: Text(
                'Record or select video',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickVideo();
              },
            ),
            
            // Text option (placeholder for future implementation)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ModernColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.text_fields, color: ModernColors.primaryPurple),
              ),
              title: Text(
                'Text status',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                showSnackBar(context, 'Text status coming soon!');
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          TextButton(
            onPressed: _selectedMedia != null && !_isProcessing
                ? _createStatus
                : null,
            child: Text(
              'Post',
              style: TextStyle(
                color: _selectedMedia != null && !_isProcessing
                    ? primaryColor
                    : textSecondaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : _selectedMedia != null
              ? _buildPreviewView()
              : _buildInitialView(),
    );
  }
  
  Widget _buildLoadingView() {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: modernTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Processing media...',
            style: TextStyle(
              fontSize: 16,
              color: modernTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialView() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final textColor = modernTheme.textColor!;
    final textSecondaryColor = modernTheme.textSecondaryColor!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Share a moment with your contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your status will be visible for 24 hours',
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showMediaPicker,
            icon: const Icon(Icons.add),
            label: const Text('Add Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewView() {
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    final surfaceColor = modernTheme.surfaceColor!;
    
    return Column(
      children: [
        // Media preview
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Media preview
                if (_selectedType == StatusType.image)
                  Image.file(
                    _selectedMedia!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  )
                else if (_selectedType == StatusType.video)
                  Container(
                    height: 400,
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Video Preview',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Caption input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _captionController,
                    maxLength: 100,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      filled: true,
                      fillColor: modernTheme.surfaceVariantColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom toolbar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _showMediaPicker,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Media'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
              ElevatedButton(
                onPressed: _createStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Post Status'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}