// ===============================
// Create Moment Screen
// Create and post new moments with media, text, and privacy
// Uses GoRouter for navigation
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/models/moment_constants.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_media_service.dart';
import 'package:textgb/features/moments/services/moments_upload_service.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/features/moments/widgets/privacy_selector.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

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
  final List<String> _visibleTo = [];
  final List<String> _hiddenFrom = [];
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
  Future<void> _selectLocation() async {
    final locations = [
      'Nairobi, Kenya',
      'Mombasa, Kenya',
      'Kisumu, Kenya',
      'Nakuru, Kenya',
      'Eldoret, Kenya',
      'Thika, Kenya',
      'Malindi, Kenya',
      'Kitale, Kenya',
      'Garissa, Kenya',
      'Kakamega, Kenya',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(locations[index]),
                leading: const Icon(Icons.location_on),
                onTap: () => context.pop(locations[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          if (_location != null)
            TextButton(
              onPressed: () {
                setState(() => _location = null);
                context.pop();
              },
              child: const Text('Remove'),
            ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _location = selected;
      });
    }
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
        visibleTo: _visibleTo,
        hiddenFrom: _hiddenFrom,
      );

      // Post moment
      await ref.read(createMomentProvider.notifier).create(request);

      // Success
      if (mounted) {
        context.pop();
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
      backgroundColor: MomentsTheme.lightSurface,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: MomentsTheme.lightSurface,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          color: MomentsTheme.lightTextPrimary,
        ),
        actions: [
          // Post button - Facebook style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _postMoment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isUploading
                    ? MomentsTheme.lightTextTertiary
                    : MomentsTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Post'),
            ),
          ),
        ],
      ),
      body: _isUploading ? _buildUploadingState() : _buildEditor(),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Main content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MomentsTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text input - Facebook "What's on your mind?" style
                Container(
                  decoration: BoxDecoration(
                    color: MomentsTheme.lightSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 3,
                    maxLength: 1000,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        fontSize: 17,
                        color: MomentsTheme.lightTextTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      filled: true,
                      fillColor: MomentsTheme.lightSurface,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      color: MomentsTheme.lightTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Media preview
                if (_selectedMedia.isNotEmpty) _buildMediaPreview(),

                // Location tag
                if (_location != null) ...[
                  const SizedBox(height: 12),
                  _buildLocationTag(),
                ],
              ],
            ),
          ),
        ),

        // Bottom action bar - Facebook style
        _buildBottomActionBar(),
      ],
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
    return InkWell(
      onTap: _selectLocation,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MomentsTheme.lightBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: MomentsTheme.lightDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: MomentsTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              _location!,
              style: TextStyle(
                fontSize: 15,
                color: MomentsTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _location = null),
              child: Icon(
                Icons.close,
                size: 18,
                color: MomentsTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Facebook-style bottom action bar
  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: MomentsTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: MomentsTheme.lightDivider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
        vertical: MomentsTheme.paddingMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add to your post section
          Container(
            padding: const EdgeInsets.all(MomentsTheme.paddingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: MomentsTheme.lightDivider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Add to your post',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MomentsTheme.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                // Photo/Video buttons
                _buildActionButton(
                  icon: Icons.photo_library,
                  color: const Color(0xFF45BD62),
                  onTap: _showPhotoOptions,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.videocam,
                  color: const Color(0xFFF3425F),
                  onTap: _showVideoOptions,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.location_on,
                  color: const Color(0xFFF5533D),
                  onTap: _selectLocation,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.lock_outline,
                  color: MomentsTheme.lightTextSecondary,
                  onTap: _selectPrivacy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
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
                context.pop();
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                context.pop();
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
                context.pop();
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record video'),
              onTap: () {
                context.pop();
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: MomentsTheme.primaryBlue,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Uploading your post',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: MomentsTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 15,
                color: MomentsTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: MomentsTheme.lightBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    MomentsTheme.primaryBlue,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
