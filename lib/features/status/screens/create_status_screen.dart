import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/wechat_theme_extension.dart';
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
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Create Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(true);
              },
            ),
            
            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickImage(false);
              },
            ),
            
            // Video option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam, color: Colors.red),
              ),
              title: const Text('Record or select video'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                _pickVideo();
              },
            ),
            
            // Text option (placeholder for future implementation)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.text_fields, color: Colors.purple),
              ),
              title: const Text('Text status'),
              onTap: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                showSnackBar(context, 'Text status coming soon!');
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
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
                    ? accentColor
                    : Colors.grey,
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing media...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialView() {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF07C160);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 80,
            color: accentColor.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Share a moment with your contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your status will be visible for 24 hours',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showMediaPicker,
            icon: const Icon(Icons.add),
            label: const Text('Add Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewView() {
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
                    decoration: const InputDecoration(
                      hintText: 'Add a caption...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
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
            color: Theme.of(context).cardColor,
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
              ),
              ElevatedButton(
                onPressed: _createStatus,
                child: const Text('Post Status'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}