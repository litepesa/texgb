// ===============================
// Edit Channel Screen
// Update existing channel details
// Uses GoRouter for navigation
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_constants.dart';
import 'package:textgb/features/channels/providers/channel_provider.dart';

class EditChannelScreen extends ConsumerStatefulWidget {
  final String channelId;

  const EditChannelScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<EditChannelScreen> createState() => _EditChannelScreenState();
}

class _EditChannelScreenState extends ConsumerState<EditChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _channelNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = ChannelConstants.channelCategories.first;
  List<String> _tags = [];
  File? _newAvatarFile;
  String? _currentAvatarUrl;
  bool _isUpdating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannelData();
  }

  Future<void> _loadChannelData() async {
    try {
      final channel = await ref.read(channelProvider(widget.channelId).future);

      setState(() {
        _channelNameController.text = channel.channelName;
        _bioController.text = channel.bio;
        _selectedCategory = channel.category;
        _tags = List.from(channel.tags);
        _websiteController.text = channel.websiteUrl ?? '';
        _emailController.text = channel.contactEmail ?? '';
        _currentAvatarUrl = channel.channelAvatar;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showError('Failed to load channel: $e');
        context.pop();
      }
    }
  }

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
          _newAvatarFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _updateChannel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // TODO: Upload new avatar if selected and get URL
      // For now, keep current avatar or use placeholder
      String avatarUrl = _currentAvatarUrl ?? 'https://via.placeholder.com/150';
      if (_newAvatarFile != null) {
        // TODO: Upload _newAvatarFile and get new URL
        // avatarUrl = await uploadAvatar(_newAvatarFile!);
      }

      final request = UpdateChannelRequest(
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

      await ref.read(updateChannelProvider.notifier).updateChannel(widget.channelId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Channel updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back using GoRouter
        context.pop();
      }
    } catch (e) {
      _showError('Failed to update channel: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Channel'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), // GoRouter navigation
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _updateChannel,
            child: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
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
              // Avatar
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                              image: _newAvatarFile != null
                                  ? DecorationImage(
                                      image: FileImage(_newAvatarFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : _currentAvatarUrl != null
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(_currentAvatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _newAvatarFile == null && _currentAvatarUrl == null
                                ? const Icon(Icons.add_a_photo, size: 40)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
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
                    TextButton(
                      onPressed: _pickAvatar,
                      child: const Text('Change Channel Avatar'),
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

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
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
