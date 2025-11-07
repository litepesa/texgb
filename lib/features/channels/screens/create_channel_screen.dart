// ===============================
// Create Channel Screen
// One-time channel creation (WeChat Channels style)
// Uses GoRouter for navigation
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_constants.dart';
import 'package:textgb/features/channels/providers/channel_provider.dart';
import 'package:textgb/core/router/route_paths.dart';

class CreateChannelScreen extends ConsumerStatefulWidget {
  const CreateChannelScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends ConsumerState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _channelNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = ChannelConstants.channelCategories.first;
  List<String> _tags = [];
  File? _avatarFile;
  bool _isCreating = false;

  @override
  void dispose() {
    _channelNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) return;

    if (_avatarFile == null) {
      _showError('Please select a channel avatar');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // TODO: Upload avatar first and get URL
      // For now, using placeholder
      final avatarUrl = 'https://via.placeholder.com/150';

      final request = CreateChannelRequest(
        channelName: _channelNameController.text.trim(),
        channelAvatar: avatarUrl,
        bio: _bioController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
        websiteUrl: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
      );

      await ref.read(createChannelProvider.notifier).create(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Channel created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to channel feed using GoRouter
        context.go(RoutePaths.channelsFeed);
      }
    } catch (e) {
      _showError('Failed to create channel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addTag() {
    if (_tags.length >= ChannelConstants.maxTagsCount) {
      _showError('Maximum ${ChannelConstants.maxTagsCount} tags allowed');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final tagController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(
              hintText: 'Enter tag',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final tag = tagController.text.trim();
                if (tag.isNotEmpty) {
                  setState(() {
                    _tags.add(tag);
                  });
                  context.pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Channel'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), // GoRouter navigation
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createChannel,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can create ONE channel per account',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Avatar
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          image: _avatarFile != null
                              ? DecorationImage(
                                  image: FileImage(_avatarFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _avatarFile == null
                            ? const Icon(Icons.add_a_photo, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickAvatar,
                      child: const Text('Select Channel Avatar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Channel Name
              TextFormField(
                controller: _channelNameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name *',
                  hintText: 'Enter your channel name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Channel name is required';
                  }
                  if (value.trim().length < ChannelConstants.minChannelNameLength) {
                    return 'Minimum ${ChannelConstants.minChannelNameLength} characters';
                  }
                  if (value.trim().length > ChannelConstants.maxChannelNameLength) {
                    return 'Maximum ${ChannelConstants.maxChannelNameLength} characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio *',
                  hintText: 'Describe your channel',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: ChannelConstants.maxBioLength,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bio is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: ChannelConstants.channelCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Tags
              const Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _tags.remove(tag);
                        });
                      },
                    );
                  }),
                  ActionChip(
                    label: const Text('+ Add Tag'),
                    onPressed: _addTag,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Website (optional)
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  hintText: 'https://yourwebsite.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 16),

              // Contact Email (optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email (Optional)',
                  hintText: 'contact@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Channel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
