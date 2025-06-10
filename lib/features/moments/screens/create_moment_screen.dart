// lib/features/moments/screens/create_moment_screen.dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/enums/enums.dart';

class CreateMomentScreen extends ConsumerStatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  ConsumerState<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends ConsumerState<CreateMomentScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _selectedImages = [];
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;
  bool _isLoading = false;
  String? _initialType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _initialType = args?['type'];
    
    // Auto-open image picker if type is specified
    if (_initialType == 'photo' && _selectedImages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImages();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final image = await pickImage(
        fromCamera: false,
        onFail: (error) {
          showSnackBar(context, error);
        },
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error picking image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await pickImage(
        fromCamera: true,
        onFail: (error) {
          showSnackBar(context, error);
        },
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error taking photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _publishMoment() async {
    final authState = ref.read(authenticationProvider).value;
    if (authState?.userModel == null) {
      showSnackBar(context, 'User not found');
      return;
    }

    final content = _textController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      showSnackBar(context, 'Please add some content or images');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(momentsNotifierProvider.notifier).createMoment(
        user: authState!.userModel!,
        content: content,
        images: _selectedImages,
        privacyType: _privacyType,
        excludedUsers: [],
        onlyUsers: [],
      );

      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Moment published successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Failed to publish moment: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              RadioListTile<StatusPrivacyType>(
                title: const Text('All Contacts'),
                subtitle: const Text('All your contacts can see this moment'),
                value: StatusPrivacyType.all_contacts,
                groupValue: _privacyType,
                onChanged: (value) {
                  setState(() {
                    _privacyType = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              
              RadioListTile<StatusPrivacyType>(
                title: const Text('My contacts except...'),
                subtitle: const Text('Hide from specific contacts'),
                value: StatusPrivacyType.except,
                groupValue: _privacyType,
                onChanged: (value) {
                  setState(() {
                    _privacyType = value!;
                  });
                  Navigator.pop(context);
                  // TODO: Show contact selection screen
                },
              ),
              
              RadioListTile<StatusPrivacyType>(
                title: const Text('Only share with...'),
                subtitle: const Text('Only specific contacts can see this'),
                value: StatusPrivacyType.only,
                groupValue: _privacyType,
                onChanged: (value) {
                  setState(() {
                    _privacyType = value!;
                  });
                  Navigator.pop(context);
                  // TODO: Show contact selection screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authenticationProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1C1E21)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Moment',
          style: TextStyle(
            color: Color(0xFF1C1E21),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishMoment,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'POST',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
        data: (authData) {
          if (authData.userModel == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: authData.userModel!.image.isNotEmpty
                          ? CachedNetworkImageProvider(authData.userModel!.image)
                          : const AssetImage(AssetsManager.userImage) as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authData.userModel!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: _showPrivacyOptions,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPrivacyIcon(),
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _privacyType.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Text input
                TextField(
                  controller: _textController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Selected images
                if (_selectedImages.isNotEmpty) _buildImageGrid(),
                
                const SizedBox(height: 20),
                
                // Add media options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to your moment',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMediaOption(
                            icon: Icons.photo_library,
                            color: Colors.green,
                            label: 'Photos',
                            onTap: _pickImages,
                          ),
                          const SizedBox(width: 20),
                          _buildMediaOption(
                            icon: Icons.camera_alt,
                            color: Colors.blue,
                            label: 'Camera',
                            onTap: _pickImageFromCamera,
                          ),
                          const SizedBox(width: 20),
                          _buildMediaOption(
                            icon: Icons.location_on,
                            color: Colors.red,
                            label: 'Location',
                            onTap: () {
                              // TODO: Implement location picker
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _selectedImages.length == 1 ? 1 : 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon() {
    switch (_privacyType) {
      case StatusPrivacyType.all_contacts:
        return Icons.people;
      case StatusPrivacyType.except:
        return Icons.people_outline;
      case StatusPrivacyType.only:
        return Icons.person;
    }
  }
}