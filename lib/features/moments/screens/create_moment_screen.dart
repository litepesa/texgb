// ===============================
// Create Moment Screen
// Create and post new moments with media, text, and privacy
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/models/moment_constants.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_media_service.dart';
import 'package:textgb/features/moments/services/moments_upload_service.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/features/moments/widgets/privacy_selector.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final TextEditingController _contentController = TextEditingController();
  final MomentsMediaService _mediaService = MomentsMediaService();
  final MomentsUploadService _uploadService = MomentsUploadService();

  List<File> _selectedMedia = [];
  MomentMediaType _mediaType = MomentMediaType.text;
  MomentVisibility _visibility = MomentVisibility.all;
  String? _location;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // Pick images
  Future<void> _pickImages() async {
    try {
      final images = await _mediaService.pickImages();
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia = images;
          _mediaType = MomentMediaType.images;
        });
      }
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  // Take photo
  Future<void> _takePhoto() async {
    try {
      final photo = await _mediaService.takePhoto();
      if (photo != null) {
        setState(() {
          _selectedMedia = [photo];
          _mediaType = MomentMediaType.images;
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  // Pick video
  Future<void> _pickVideo() async {
    try {
      final video = await _mediaService.pickVideo();
      if (video != null) {
        // Validate video
        final validation = await _mediaService.validateVideo(video);
        if (!validation.isValid) {
          _showError(validation.error ?? 'Invalid video');
          return;
        }

        setState(() {
          _selectedMedia = [video];
          _mediaType = MomentMediaType.video;
        });
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  // Record video
  Future<void> _recordVideo() async {
    try {
      final video = await _mediaService.recordVideo();
      if (video != null) {
        // Validate video
        final validation = await _mediaService.validateVideo(video);
        if (!validation.isValid) {
          _showError(validation.error ?? 'Invalid video');
          return;
        }

        setState(() {
          _selectedMedia = [video];
          _mediaType = MomentMediaType.video;
        });
      }
    } catch (e) {
      _showError('Failed to record video: $e');
    }
  }

  // Remove media
  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
      if (_selectedMedia.isEmpty) {
        _mediaType = MomentMediaType.text;
      }
    });
  }

  // Clear all media
  void _clearAllMedia() {
    setState(() {
      _selectedMedia.clear();
      _mediaType = MomentMediaType.text;
    });
  }

  // Select location
  void _selectLocation() {
    // TODO: Implement location picker
    setState(() {
      _location = 'Nairobi, Kenya'; // Placeholder
    });
  }

  // Select privacy
  Future<void> _selectPrivacy() async {
    final selected = await showModalBottomSheet<MomentVisibility>(
      context: context,
      builder: (context) => PrivacySelector(
        currentVisibility: _visibility,
      ),
    );

    if (selected != null) {
      setState(() {
        _visibility = selected;
      });
    }
  }

  // Validate and post
  Future<void> _postMoment() async {
    // Validate content
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      _showError('Please add some content or media');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload media files
      List<String> mediaUrls = [];
      if (_selectedMedia.isNotEmpty) {
        mediaUrls = await _uploadMedia();
      }

      // Create moment request
      final request = CreateMomentRequest(
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        mediaUrls: mediaUrls,
        mediaType: _mediaType,
        location: _location,
        visibility: _visibility,
        visibleTo: [], // TODO: Implement custom privacy lists
        hiddenFrom: [], // TODO: Implement custom privacy lists
      );

      // Post moment
      await ref.read(createMomentProvider.notifier).create(request);

      // Success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moment posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to post moment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // Upload media files
  Future<List<String>> _uploadMedia() async {
    if (_mediaType == MomentMediaType.images) {
      // Upload images
      return await _uploadService.uploadImages(
        _selectedMedia,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
    } else if (_mediaType == MomentMediaType.video) {
      // Upload video
      final url = await _uploadService.uploadVideo(
        _selectedMedia.first,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );
      return [url];
    }

    return [];
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Moment'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Post button
          TextButton(
            onPressed: _isUploading ? null : _postMoment,
            child: Text(
              'Post',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isUploading
                    ? Colors.grey
                    : MomentsTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      body: _isUploading ? _buildUploadingState() : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text input
          TextField(
            controller: _contentController,
            maxLines: 5,
            maxLength: 1000,
            decoration: const InputDecoration(
              hintText: 'Share your moment...',
              border: InputBorder.none,
              counterText: '',
            ),
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),

          // Media preview
          if (_selectedMedia.isNotEmpty) _buildMediaPreview(),

          const SizedBox(height: 16),

          // Location
          if (_location != null) _buildLocationTag(),

          const SizedBox(height: 24),

          // Options
          _buildOptions(),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _mediaType == MomentMediaType.video
                  ? 'Video'
                  : 'Images (${_selectedMedia.length}/${MomentConstants.maxImages})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _clearAllMedia,
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _mediaType == MomentMediaType.video
            ? _buildVideoPreview()
            : _buildImagesPreview(),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, size: 64),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            onPressed: () => _removeMedia(0),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesPreview() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedMedia.length +
          (_selectedMedia.length < MomentConstants.maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _selectedMedia.length) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedMedia[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // Add more button
          return GestureDetector(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: const Icon(Icons.add, size: 32),
            ),
          );
        }
      },
    );
  }

  Widget _buildLocationTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 16),
          const SizedBox(width: 4),
          Text(_location!),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _location = null),
            child: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        _buildOptionTile(
          icon: Icons.photo_library_outlined,
          title: 'Photos',
          onTap: _showPhotoOptions,
        ),
        _buildOptionTile(
          icon: Icons.videocam_outlined,
          title: 'Video',
          onTap: _showVideoOptions,
        ),
        _buildOptionTile(
          icon: Icons.location_on_outlined,
          title: 'Location',
          onTap: _selectLocation,
        ),
        _buildOptionTile(
          icon: Icons.lock_outline,
          title: 'Privacy: ${_visibility.displayName}',
          onTap: _selectPrivacy,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: MomentsTheme.primaryBlue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record video'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Uploading... ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                MomentsTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
