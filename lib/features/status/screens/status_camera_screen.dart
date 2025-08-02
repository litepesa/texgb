// lib/features/status/screens/status_camera_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusCameraScreen extends ConsumerStatefulWidget {
  const StatusCameraScreen({super.key});

  @override
  ConsumerState<StatusCameraScreen> createState() => _StatusCameraScreenState();
}

class _StatusCameraScreenState extends ConsumerState<StatusCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMediaOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        title: const Text('Add Status'),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Capture or select media for your status',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildMediaOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo or video',
              onTap: () => _openCamera(),
            ),
            const SizedBox(height: 16),
            _buildMediaOption(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () => _openGallery(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _buildMediaOptionsBottomSheet(),
    );
  }

  Widget _buildMediaOptionsBottomSheet() {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Add to Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              title: 'Camera',
              subtitle: 'Take a photo or video',
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            
            _buildBottomSheetOption(
              icon: Icons.photo,
              title: 'Photo',
              subtitle: 'Choose a photo from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            
            _buildBottomSheetOption(
              icon: Icons.videocam,
              title: 'Video',
              subtitle: 'Choose a video from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = context.modernTheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDialog('Camera');
        return;
      }

      // Show camera options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Capture'),
          content: const Text('What would you like to capture?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _captureImage();
              },
              child: const Text('Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _captureVideo();
              },
              child: const Text('Video'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open camera: $e');
    }
  }

  Future<void> _openGallery() async {
    try {
      // Check storage permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        _showPermissionDialog('Storage');
        return;
      }

      // Show gallery options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select from Gallery'),
          content: const Text('What would you like to select?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text('Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickVideo();
              },
              child: const Text('Video'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open gallery: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _createMediaStatus(image, Constants.statusTypeImage);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _captureVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        await _createMediaStatus(video, Constants.statusTypeVideo);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture video: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _createMediaStatus(image, Constants.statusTypeImage);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        await _createMediaStatus(video, Constants.statusTypeVideo);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick video: $e');
    }
  }

  Future<void> _createMediaStatus(XFile mediaFile, String statusType) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await ref.read(statusNotifierProvider.notifier).createMediaStatus(
        mediaFile: mediaFile,
        statusType: statusType,
        content: '', // Could add caption input later
        privacyLevel: Constants.statusPrivacyContacts,
      );

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close camera screen
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status posted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        _showErrorSnackBar('Failed to post status: $e');
      }
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'This app needs $permission permission to capture photos and videos for your status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}