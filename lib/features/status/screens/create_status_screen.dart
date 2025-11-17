// ===============================
// Create Status Screen
// Create text, image, or video status
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_enums.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/theme/status_theme.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  StatusMediaType _selectedType = StatusMediaType.text;
  File? _selectedMedia;
  final TextEditingController _textController = TextEditingController();
  TextStatusBackground _selectedBackground = TextStatusBackground.gradient1;
  StatusVisibility _visibility = StatusVisibility.all;
  bool _isCreating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Status'),
        actions: [
          if (!_isCreating)
            TextButton(
              onPressed: _canCreate ? _handleCreate : null,
              child: Text(
                'Create',
                style: TextStyle(
                  color: _canCreate ? StatusTheme.primaryBlue : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            _buildTypeSelector(),

            const SizedBox(height: 24),

            // Content input based on type
            if (_selectedType == StatusMediaType.text) _buildTextInput(),
            if (_selectedType == StatusMediaType.image) _buildImageInput(),
            if (_selectedType == StatusMediaType.video) _buildVideoInput(),

            const SizedBox(height: 24),

            // Privacy selector
            _buildPrivacySelector(),

            const SizedBox(height: 24),

            // Info card
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  // ===============================
  // TYPE SELECTOR
  // ===============================

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TypeOption(
                icon: Icons.text_fields,
                label: 'Text',
                isSelected: _selectedType == StatusMediaType.text,
                onTap: () => setState(() {
                  _selectedType = StatusMediaType.text;
                  _selectedMedia = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeOption(
                icon: Icons.image,
                label: 'Image',
                isSelected: _selectedType == StatusMediaType.image,
                onTap: () => setState(() {
                  _selectedType = StatusMediaType.image;
                  _textController.clear();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeOption(
                icon: Icons.videocam,
                label: 'Video',
                isSelected: _selectedType == StatusMediaType.video,
                onTap: () => setState(() {
                  _selectedType = StatusMediaType.video;
                  _textController.clear();
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===============================
  // TEXT INPUT
  // ===============================

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Message',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Text preview with background
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: StatusTheme.getTextBackgroundGradient(
              _selectedBackground.colors,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _textController,
                maxLength: StatusConstants.textStatusMaxLength,
                maxLines: null,
                textAlign: TextAlign.center,
                style: StatusTheme.textStatusStyle,
                decoration: const InputDecoration(
                  hintText: 'Type your status...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Background selector
        const Text(
          'Background',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: TextStatusBackground.values.length,
            itemBuilder: (context, index) {
              final bg = TextStatusBackground.values[index];
              return GestureDetector(
                onTap: () => setState(() => _selectedBackground = bg),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: StatusTheme.getTextBackgroundGradient(bg.colors),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedBackground == bg
                          ? StatusTheme.primaryBlue
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===============================
  // IMAGE INPUT
  // ===============================

  Widget _buildImageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedMedia != null)
          // Image preview
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedMedia!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _selectedMedia = null),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          )
        else
          // Image picker buttons
          Row(
            children: [
              Expanded(
                child: _MediaPickerButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: _pickImageFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MediaPickerButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _pickImageFromGallery,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ===============================
  // VIDEO INPUT
  // ===============================

  Widget _buildVideoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Video',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_selectedMedia != null)
          // Video preview placeholder
          Stack(
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _selectedMedia = null),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          )
        else
          // Video picker buttons
          Row(
            children: [
              Expanded(
                child: _MediaPickerButton(
                  icon: Icons.videocam,
                  label: 'Record',
                  onTap: _pickVideoFromCamera,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MediaPickerButton(
                  icon: Icons.video_library,
                  label: 'Gallery',
                  onTap: _pickVideoFromGallery,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ===============================
  // PRIVACY SELECTOR
  // ===============================

  Widget _buildPrivacySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: StatusVisibility.values.map((visibility) {
              return RadioListTile<StatusVisibility>(
                title: Text(visibility.displayName),
                subtitle: Text(
                  visibility.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: visibility,
                groupValue: _visibility,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _visibility = value);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===============================
  // INFO CARD
  // ===============================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your status will disappear after 24 hours. Only view count will be visible, not viewer names.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // MEDIA PICKING
  // ===============================

  Future<void> _pickImageFromCamera() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickImageFromCamera();
    if (file != null) {
      setState(() => _selectedMedia = file);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickImageFromGallery();
    if (file != null) {
      setState(() => _selectedMedia = file);
    }
  }

  Future<void> _pickVideoFromCamera() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickVideoFromCamera();
    if (file != null) {
      setState(() => _selectedMedia = file);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final uploadService = ref.read(statusUploadServiceProvider);
    final file = await uploadService.pickVideoFromGallery();
    if (file != null) {
      setState(() => _selectedMedia = file);
    }
  }

  // ===============================
  // CREATE STATUS
  // ===============================

  bool get _canCreate {
    if (_selectedType == StatusMediaType.text) {
      return _textController.text.trim().isNotEmpty;
    } else {
      return _selectedMedia != null;
    }
  }

  Future<void> _handleCreate() async {
    if (!_canCreate || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final creationProvider = ref.read(statusCreationProvider.notifier);

      if (_selectedType == StatusMediaType.text) {
        // Create text status
        await creationProvider.createStatus(
          CreateStatusRequest(
            content: _textController.text.trim(),
            mediaType: StatusMediaType.text,
            textBackground: _selectedBackground,
            visibility: _visibility,
          ),
        );
      } else if (_selectedType == StatusMediaType.image) {
        // Create image status
        await creationProvider.createImageStatus(
          imagePath: _selectedMedia!.path,
          request: CreateStatusRequest(
            mediaType: StatusMediaType.image,
            visibility: _visibility,
          ),
        );
      } else if (_selectedType == StatusMediaType.video) {
        // Create video status
        await creationProvider.createVideoStatus(
          videoPath: _selectedMedia!.path,
          request: CreateStatusRequest(
            mediaType: StatusMediaType.video,
            visibility: _visibility,
          ),
        );
      }

      if (mounted) {
        _showSnackBar(StatusConstants.successUploaded);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create status: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ===============================
// HELPER WIDGETS
// ===============================

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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? StatusTheme.primaryBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaPickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: StatusTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
