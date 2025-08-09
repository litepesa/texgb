// lib/features/moments/screens/create_moment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/moments/widgets/privacy_selector.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  MomentType _selectedType = MomentType.images;
  MomentPrivacy _selectedPrivacy = MomentPrivacy.public;
  List<String> _selectedContacts = [];
  
  File? _videoFile;
  List<File> _imageFiles = [];
  VideoPlayerController? _videoController;
  
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.modernTheme.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Moment',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasContent())
            TextButton(
              onPressed: _isUploading ? null : _createMoment,
              child: _isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.modernTheme.primaryColor,
                      ),
                    )
                  : Text(
                      'Share',
                      style: TextStyle(
                        color: context.modernTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content type selector
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // Media content area
                  _buildMediaContent(),
                  const SizedBox(height: 24),

                  // Caption input
                  _buildCaptionInput(),
                  const SizedBox(height: 24),

                  // Privacy settings
                  _buildPrivacySettings(),
                ],
              ),
            ),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeOption(
                icon: Icons.photo_library,
                label: 'Photos',
                isSelected: _selectedType == MomentType.images,
                onTap: () => setState(() => _selectedType = MomentType.images),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeOption(
                icon: Icons.videocam,
                label: 'Video',
                isSelected: _selectedType == MomentType.video,
                onTap: () => setState(() => _selectedType = MomentType.video),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaContent() {
    if (_selectedType == MomentType.video) {
      return _buildVideoContent();
    } else {
      return _buildImageContent();
    }
  }

  Widget _buildVideoContent() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.modernTheme.borderColor!,
          width: 1,
        ),
      ),
      child: _videoFile == null
          ? _buildMediaPlaceholder(
              icon: Icons.videocam,
              title: 'Add Video',
              subtitle: 'Tap to select a video (max 1 minute)',
              onTap: _selectVideo,
            )
          : _buildVideoPreview(),
    );
  }

  Widget _buildImageContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.modernTheme.borderColor!,
          width: 1,
        ),
      ),
      child: _imageFiles.isEmpty
          ? _buildMediaPlaceholder(
              icon: Icons.photo_library,
              title: 'Add Photos',
              subtitle: 'Tap to select photos (max 9)',
              onTap: _selectImages,
            )
          : _buildImageGrid(),
    );
  }

  Widget _buildMediaPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: context.modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: context.modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Controls overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
        ),

        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeVideo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Play/pause button
        Positioned.fill(
          child: Center(
            child: GestureDetector(
              onTap: _toggleVideoPlayback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController?.value.isPlaying == true
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imageFiles.length + (_imageFiles.length < 9 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageFiles.length) {
                return _buildAddImageTile();
              }
              return _buildImageTile(_imageFiles[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: _selectImages,
      child: Container(
        decoration: BoxDecoration(
          color: context.modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.modernTheme.borderColor!,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.add,
          color: context.modernTheme.textSecondaryColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(imageFile),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
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
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caption',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _captionController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Write a caption...',
            hintStyle: TextStyle(color: context.modernTheme.textSecondaryColor),
            filled: true,
            fillColor: context.modernTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modernTheme.borderColor!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.modernTheme.primaryColor!),
            ),
          ),
          style: TextStyle(color: context.modernTheme.textColor),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        PrivacySelector(
          selectedPrivacy: _selectedPrivacy,
          selectedContacts: _selectedContacts,
          onPrivacyChanged: (privacy) {
            setState(() {
              _selectedPrivacy = privacy;
              if (privacy == MomentPrivacy.public || privacy == MomentPrivacy.contacts) {
                _selectedContacts.clear();
              }
            });
          },
          onContactsChanged: (contacts) {
            setState(() {
              _selectedContacts = contacts;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.modernTheme.borderColor!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectedType == MomentType.video ? _selectVideo : _selectImages,
              icon: Icon(_selectedType == MomentType.video ? Icons.videocam : Icons.photo_library),
              label: Text(_selectedType == MomentType.video ? 'Select Video' : 'Select Photos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.modernTheme.textColor,
                side: BorderSide(color: context.modernTheme.borderColor!),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_hasContent()) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _createMoment,
                icon: _isUploading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_isUploading ? 'Sharing...' : 'Share Moment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasContent() {
    return (_selectedType == MomentType.video && _videoFile != null) ||
           (_selectedType == MomentType.images && _imageFiles.isNotEmpty) ||
           _captionController.text.trim().isNotEmpty;
  }

  Future<void> _selectVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );

      if (video != null) {
        setState(() {
          _videoFile = File(video.path);
          _selectedType = MomentType.video;
        });
        _initializeVideoController();
      }
    } catch (e) {
      showSnackBar(context, 'Failed to select video: ${e.toString()}');
    }
  }

  Future<void> _selectImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final totalImages = _imageFiles.length + images.length;
        if (totalImages > 9) {
          showSnackBar(context, 'You can only select up to 9 images');
          return;
        }

        setState(() {
          _imageFiles.addAll(images.map((image) => File(image.path)));
          _selectedType = MomentType.images;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Failed to select images: ${e.toString()}');
    }
  }

  void _initializeVideoController() {
    if (_videoFile == null) return;

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_videoFile!);
    _videoController!.initialize().then((_) {
      setState(() {});
      _videoController!.setLooping(true);
    });
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  void _removeVideo() {
    setState(() {
      _videoFile = null;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _createMoment() async {
    if (!_hasContent()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final momentId = await ref.read(momentsProvider.notifier).createMoment(
        content: _captionController.text.trim(),
        type: _selectedType,
        privacy: _selectedPrivacy,
        selectedContacts: _selectedContacts,
        videoFile: _videoFile,
        imageFiles: _imageFiles.isNotEmpty ? _imageFiles : null,
      );

      if (momentId != null) {
        showSnackBar(context, 'Moment created successfully!');
        Navigator.pop(context);
      } else {
        final momentsState = ref.read(momentsProvider);
        showSnackBar(context, momentsState.error ?? 'Failed to create moment');
      }
    } catch (e) {
      showSnackBar(context, 'Failed to create moment: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.modernTheme.primaryColor?.withOpacity(0.1)
              : context.modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? context.modernTheme.primaryColor!
                : context.modernTheme.borderColor!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? context.modernTheme.primaryColor
                  : context.modernTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? context.modernTheme.primaryColor
                    : context.modernTheme.textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}