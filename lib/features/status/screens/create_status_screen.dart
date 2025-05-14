import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  final StatusType? initialType;
  
  const CreateStatusScreen({Key? key, this.initialType}) : super(key: key);

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  late StatusType _selectedType;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  File? _mediaFile;
  bool _isLoading = false;
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;
  List<String> _privacyUIDs = [];
  List<UserModel> _selectedContacts = [];
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? StatusType.text;
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    _linkController.dispose();
    super.dispose();
  }
  
  void _pickImage({required bool fromCamera}) async {
    final image = await pickImage(
      fromCamera: fromCamera,
      onFail: (error) => showSnackBar(context, error),
    );
    
    if (image != null) {
      setState(() {
        _mediaFile = image;
        _selectedType = StatusType.image;
      });
    }
  }
  
  void _pickVideo({required bool fromCamera}) async {
    final video = fromCamera 
        ? await pickVideoFromCamera(onFail: (error) => showSnackBar(context, error))
        : await pickVideo(onFail: (error) => showSnackBar(context, error));
    
    if (video != null) {
      setState(() {
        _mediaFile = video;
        _selectedType = StatusType.video;
      });
    }
  }
  
  Future<void> _createStatus() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    // Validate input based on type
    String content = '';
    String? caption;
    
    switch (_selectedType) {
      case StatusType.text:
        if (_textController.text.trim().isEmpty) {
          showSnackBar(context, 'Please enter some text');
          return;
        }
        content = _textController.text.trim();
        break;
        
      case StatusType.image:
        if (_mediaFile == null) {
          showSnackBar(context, 'Please select an image');
          return;
        }
        content = '';  // Will be replaced with the uploaded image URL
        caption = _captionController.text.trim();
        break;
        
      case StatusType.video:
        if (_mediaFile == null) {
          showSnackBar(context, 'Please select a video');
          return;
        }
        content = '';  // Will be replaced with the uploaded video URL
        caption = _captionController.text.trim();
        break;
        
      case StatusType.link:
        if (_linkController.text.trim().isEmpty) {
          showSnackBar(context, 'Please enter a valid URL');
          return;
        }
        content = _linkController.text.trim();
        caption = _captionController.text.trim();
        break;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(statusProvider.notifier).createStatus(
        type: _selectedType,
        content: content,
        mediaFile: _mediaFile,
        caption: caption,
        privacyType: _privacyType,
        privacyUIDs: _privacyUIDs,
      );
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error creating status: $e');
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: context.modernTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Status Privacy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.modernTheme.textColor,
                    ),
                  ),
                ),
                
                const Divider(),
                
                // Privacy options
                RadioListTile<StatusPrivacyType>(
                  title: Text(
                    StatusPrivacyType.all_contacts.displayName,
                    style: TextStyle(color: context.modernTheme.textColor),
                  ),
                  value: StatusPrivacyType.all_contacts,
                  groupValue: _privacyType,
                  onChanged: (value) {
                    setModalState(() {
                      _privacyType = value!;
                      _privacyUIDs = [];
                      _selectedContacts = [];
                    });
                  },
                ),
                
                RadioListTile<StatusPrivacyType>(
                  title: Text(
                    StatusPrivacyType.except.displayName,
                    style: TextStyle(color: context.modernTheme.textColor),
                  ),
                  value: StatusPrivacyType.except,
                  groupValue: _privacyType,
                  onChanged: (value) {
                    setModalState(() {
                      _privacyType = value!;
                    });
                    // Show contact selection
                    Navigator.pop(context);
                    _showContactSelection(
                      title: 'Hide from...',
                      isExcluding: true,
                    );
                  },
                ),
                
                RadioListTile<StatusPrivacyType>(
                  title: Text(
                    StatusPrivacyType.only.displayName,
                    style: TextStyle(color: context.modernTheme.textColor),
                  ),
                  value: StatusPrivacyType.only,
                  groupValue: _privacyType,
                  onChanged: (value) {
                    setModalState(() {
                      _privacyType = value!;
                    });
                    // Show contact selection
                    Navigator.pop(context);
                    _showContactSelection(
                      title: 'Share with...',
                      isExcluding: false,
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Display selected contacts if applicable
                if (_privacyType != StatusPrivacyType.all_contacts && _selectedContacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _privacyType == StatusPrivacyType.except
                              ? 'Hidden from:'
                              : 'Shared with:',
                          style: TextStyle(
                            color: context.modernTheme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _selectedContacts.map((contact) {
                            return Chip(
                              label: Text(contact.name),
                              onDeleted: () {
                                setModalState(() {
                                  _selectedContacts.remove(contact);
                                  _privacyUIDs.remove(contact.uid);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Update the main state with the modal's state
                      _privacyType = _privacyType;
                      _privacyUIDs = _privacyUIDs;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showContactSelection({required String title, required bool isExcluding}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: context.modernTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle indicator
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.modernTheme.textColor,
                    ),
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    // TODO: Implement search
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Contact list
                Expanded(
                  child: _buildContactSelectionList(isExcluding),
                ),
                
                // Done button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContactSelectionList(bool isExcluding) {
    return Consumer(
      builder: (context, ref, child) {
        final contactsState = ref.watch(contactsNotifierProvider);
        
        return contactsState.when(
          data: (state) {
            if (state.registeredContacts.isEmpty) {
              return Center(
                child: Text(
                  'No contacts found',
                  style: TextStyle(color: context.modernTheme.textSecondaryColor),
                ),
              );
            }
            
            return ListView.builder(
              itemCount: state.registeredContacts.length,
              itemBuilder: (context, index) {
                final contact = state.registeredContacts[index];
                final isSelected = _privacyUIDs.contains(contact.uid);
                
                return CheckboxListTile(
                  title: Text(
                    contact.name,
                    style: TextStyle(color: context.modernTheme.textColor),
                  ),
                  subtitle: Text(
                    contact.phoneNumber,
                    style: TextStyle(color: context.modernTheme.textSecondaryColor),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: contact.image.isNotEmpty
                        ? NetworkImage(contact.image)
                        : null,
                    child: contact.image.isEmpty
                        ? Text(contact.name.isNotEmpty ? contact.name[0] : '?')
                        : null,
                  ),
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _privacyUIDs.add(contact.uid);
                        _selectedContacts.add(contact);
                      } else {
                        _privacyUIDs.remove(contact.uid);
                        _selectedContacts.removeWhere((c) => c.uid == contact.uid);
                      }
                    });
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Status'),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip),
            onPressed: _showPrivacyOptions,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector tabs
                  _buildTypeSelectorTabs(modernTheme),
                  
                  const SizedBox(height: 16),
                  
                  // Content input based on selected type
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildContentInput(modernTheme),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createStatus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: modernTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Post Status',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildTypeSelectorTabs(ModernThemeExtension modernTheme) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildTypeTab(
            modernTheme,
            type: StatusType.text,
            icon: Icons.text_fields,
            label: 'Text',
          ),
          _buildTypeTab(
            modernTheme,
            type: StatusType.image,
            icon: Icons.image,
            label: 'Photo',
          ),
          _buildTypeTab(
            modernTheme,
            type: StatusType.video,
            icon: Icons.videocam,
            label: 'Video',
          ),
          _buildTypeTab(
            modernTheme,
            type: StatusType.link,
            icon: Icons.link,
            label: 'Link',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeTab(
    ModernThemeExtension modernTheme, {
    required StatusType type,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? modernTheme.primaryColor
              : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : modernTheme.textSecondaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : modernTheme.textColor,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContentInput(ModernThemeExtension modernTheme) {
    switch (_selectedType) {
      case StatusType.text:
        return _buildTextInput(modernTheme);
      case StatusType.image:
        return _buildImageInput(modernTheme);
      case StatusType.video:
        return _buildVideoInput(modernTheme);
      case StatusType.link:
        return _buildLinkInput(modernTheme);
    }
  }
  
  Widget _buildTextInput(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your thoughts',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _textController,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
            ),
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'What\'s on your mind?',
              hintStyle: TextStyle(
                color: modernTheme.textSecondaryColor?.withOpacity(0.7),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImageInput(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a photo',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _mediaFile == null
            ? _buildMediaPicker(
                modernTheme,
                onCameraTap: () => _pickImage(fromCamera: true),
                onGalleryTap: () => _pickImage(fromCamera: false),
                icon: Icons.photo_camera,
                title: 'Add Photo',
                subtitle: 'Choose from gallery or take a new photo',
              )
            : _buildSelectedMedia(modernTheme),
        const SizedBox(height: 16),
        if (_mediaFile != null)
          TextField(
            controller: _captionController,
            style: TextStyle(color: modernTheme.textColor),
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(
                color: modernTheme.textSecondaryColor?.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVideoInput(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a video',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _mediaFile == null
            ? _buildMediaPicker(
                modernTheme,
                onCameraTap: () => _pickVideo(fromCamera: true),
                onGalleryTap: () => _pickVideo(fromCamera: false),
                icon: Icons.videocam,
                title: 'Add Video',
                subtitle: 'Choose from gallery or record a new video',
              )
            : _buildSelectedMedia(modernTheme),
        const SizedBox(height: 16),
        if (_mediaFile != null)
          TextField(
            controller: _captionController,
            style: TextStyle(color: modernTheme.textColor),
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: TextStyle(
                color: modernTheme.textSecondaryColor?.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildLinkInput(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a link',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _linkController,
          style: TextStyle(color: modernTheme.textColor),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'Enter URL',
            hintStyle: TextStyle(
              color: modernTheme.textSecondaryColor?.withOpacity(0.7),
            ),
            prefixIcon: const Icon(Icons.link),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _captionController,
          style: TextStyle(color: modernTheme.textColor),
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add a description...',
            hintStyle: TextStyle(
              color: modernTheme.textSecondaryColor?.withOpacity(0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMediaPicker(
    ModernThemeExtension modernTheme, {
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.dividerColor ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(
            icon,
            size: 48,
            color: modernTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: onCameraTap,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: modernTheme.primaryColor,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onGalleryTap,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: modernTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSelectedMedia(ModernThemeExtension modernTheme) {
    if (_mediaFile == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                image: _selectedType == StatusType.image
                    ? DecorationImage(
                        image: FileImage(_mediaFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedType == StatusType.video
                  ? const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 64,
                      ),
                    )
                  : null,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _mediaFile = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
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
          ],
        ),
      ],
    );
  }
}