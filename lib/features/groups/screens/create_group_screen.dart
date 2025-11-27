// lib/features/groups/screens/create_group_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/groups/providers/groups_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;
  bool _isUploadingImage = false;

  File? _selectedImageFile;
  String? _groupImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _isUploadingImage = true;
        });

        // Upload image to Cloudflare R2
        final authNotifier = ref.read(authenticationProvider.notifier);
        final uploadedUrl = await authNotifier.storeFileToStorage(
          file: _selectedImageFile!,
          reference: 'groups/group_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (mounted) {
          setState(() {
            _groupImageUrl = uploadedUrl;
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group image uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final group = await ref.read(groupsListProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            groupImageUrl: _groupImageUrl,
          );

      if (group != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group image
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickGroupImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[400]!, width: 2),
                      ),
                      child: _isUploadingImage
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : _selectedImageFile != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _groupImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _groupImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                    ),
                  ),
                  if (!_isUploadingImage && _selectedImageFile == null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
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
            const SizedBox(height: 8),
            Text(
              'Tap to select group image',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Group name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              maxLength: 50,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.trim().length < 3) {
                  return 'Group name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Group description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter group description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Info: Members can be added after group creation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can add members after creating the group',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create button
            ElevatedButton(
              onPressed: _isCreating ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Group',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
