// lib/features/public_groups/screens/edit_public_group_post_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class EditPublicGroupPostScreen extends ConsumerStatefulWidget {
  final PublicGroupPostModel post;
  final PublicGroupModel publicGroup;

  const EditPublicGroupPostScreen({
    super.key,
    required this.post,
    required this.publicGroup,
  });

  @override
  ConsumerState<EditPublicGroupPostScreen> createState() => _EditPublicGroupPostScreenState();
}

class _EditPublicGroupPostScreenState extends ConsumerState<EditPublicGroupPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasChanges = false;
  List<File> _newMediaFiles = [];
  List<String> _removedMediaUrls = [];

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
    _contentController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _contentController.removeListener(_checkChanges);
    _contentController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasContentChanged = _contentController.text != widget.post.content;
    final hasMediaChanged = _newMediaFiles.isNotEmpty || _removedMediaUrls.isNotEmpty;
    
    final newHasChanges = hasContentChanged || hasMediaChanged;
    
    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  void _addMedia() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMediaPickerSheet(),
    );
  }

  Widget _buildMediaPickerSheet() {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textTertiaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Add Media',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMediaOption(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () => _pickMedia(fromCamera: false, isVideo: false),
                    color: Colors.purple,
                  ),
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickMedia(fromCamera: true, isVideo: false),
                    color: Colors.red,
                  ),
                  _buildMediaOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    onTap: () => _pickMedia(fromCamera: false, isVideo: true),
                    color: Colors.blue,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMedia({required bool fromCamera, required bool isVideo}) async {
    try {
      File? file;
      
      if (isVideo) {
        file = fromCamera 
            ? await pickVideoFromCamera(onFail: (error) => showSnackBar(context, error))
            : await pickVideo(onFail: (error) => showSnackBar(context, error));
      } else {
        file = await pickImage(
          fromCamera: fromCamera,
          onFail: (error) => showSnackBar(context, error),
        );
      }

      if (file != null) {
        setState(() {
          _newMediaFiles.add(file!);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error selecting media: $e');
      }
    }
  }

  void _removeExistingMedia(String mediaUrl) {
    setState(() {
      _removedMediaUrls.add(mediaUrl);
      _hasChanges = true;
    });
  }

  void _removeNewMedia(int index) {
    setState(() {
      _newMediaFiles.removeAt(index);
      _hasChanges = true;
    });
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Note: This is a simplified implementation
      // In a real app, you'd need to implement updatePost in the repository
      // and handle media file uploads/deletions properly
      
      showSnackBar(context, 'Post editing functionality will be implemented in the repository');
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating post: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Edit Post',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Post content
            Text(
              'Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor!),
                ),
                filled: true,
                fillColor: theme.surfaceColor,
              ),
              maxLines: 8,
              maxLength: 2000,
              validator: (value) {
                if ((value == null || value.trim().isEmpty) && 
                    widget.post.mediaUrls.isEmpty && _newMediaFiles.isEmpty) {
                  return 'Please add content or media';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Media section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMedia,
                  icon: Icon(Icons.add, color: theme.primaryColor),
                  label: Text(
                    'Add Media',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Existing media (not removed)
            if (widget.post.mediaUrls.isNotEmpty)
              ...widget.post.mediaUrls
                  .where((url) => !_removedMediaUrls.contains(url))
                  .map((url) => _buildExistingMediaItem(url, theme)),
            
            // New media
            if (_newMediaFiles.isNotEmpty)
              ..._newMediaFiles.asMap().entries.map((entry) => 
                  _buildNewMediaItem(entry.key, entry.value, theme)),
            
            if (widget.post.mediaUrls.isEmpty && _newMediaFiles.isEmpty)
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: theme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor!.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No media added',
                        style: TextStyle(
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Post settings
            if (widget.publicGroup.canPost(widget.post.authorUID))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.borderColor!.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Post Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          widget.post.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.post.isPinned ? 'Pinned Post' : 'Regular Post',
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingMediaItem(String mediaUrl, ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              mediaUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: theme.surfaceVariantColor,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withOpacity(0.6),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => _removeExistingMedia(mediaUrl),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMediaItem(int index, File file, ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor!.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black.withOpacity(0.6),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => _removeNewMedia(index),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}