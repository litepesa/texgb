import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:image_picker/image_picker.dart';

class CreateChannelScreen extends ConsumerStatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  ConsumerState<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends ConsumerState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  
  File? _profileImage;
  File? _coverImage;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  // Pick cover image
  Future<void> _pickCoverImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedImage != null) {
      setState(() {
        _coverImage = File(pickedImage.path);
      });
    }
  }

  // Submit the form to create channel
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_profileImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a profile image')),
        );
        return;
      }
      
      final channelsNotifier = ref.read(channelsProvider.notifier);
      
      // Parse tags from comma-separated string
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }
      
      channelsNotifier.createChannel(
        name: _nameController.text,
        description: _descriptionController.text,
        profileImage: _profileImage,
        coverImage: _coverImage,
        tags: tags,
        onSuccess: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          
          // Wait a moment before navigating back
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.of(context).pop(true); // Return true to indicate success
          });
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsState = ref.watch(channelsProvider);
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Create Channel',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: channelsState.isCreatingChannel ? null : _submitForm,
            child: Text(
              'Create',
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
              // Cover image picker
              Text(
                'Cover Image (Optional)',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: channelsState.isCreatingChannel ? null : _pickCoverImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    image: _coverImage != null
                        ? DecorationImage(
                            image: FileImage(_coverImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: modernTheme.primaryColor,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover Image',
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _coverImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
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
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Profile image picker
              Text(
                'Profile Image *',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: channelsState.isCreatingChannel ? null : _pickProfileImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                      image: _profileImage != null
                          ? DecorationImage(
                              image: FileImage(_profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profileImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: modernTheme.primaryColor,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: modernTheme.textColor,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Upload progress indicator
              if (channelsState.isCreatingChannel)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: channelsState.uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creating channel: ${(channelsState.uploadProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Channel Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Channel Name *',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.textSecondaryColor!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a channel name';
                  }
                  return null;
                },
                enabled: !channelsState.isCreatingChannel,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.textSecondaryColor!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                enabled: !channelsState.isCreatingChannel,
              ),
              
              const SizedBox(height: 16),
              
              // Tags (Optional)
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tags (Comma separated, Optional)',
                  labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.textSecondaryColor!.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: modernTheme.primaryColor!),
                  ),
                  hintText: 'e.g. news, entertainment, technology',
                ),
                enabled: !channelsState.isCreatingChannel,
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: channelsState.isCreatingChannel ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: modernTheme.primaryColor!.withOpacity(0.5),
                  ),
                  child: channelsState.isCreatingChannel
                      ? const Text('Creating...')
                      : const Text('Create Channel'),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}