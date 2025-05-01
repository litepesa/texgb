// lib/features/status/presentation/screens/create_status_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _mediaFiles = [];
  StatusType _selectedType = StatusType.text;
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(true);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _getImage(bool fromCamera) async {
    final file = await pickImage(
      fromCamera: fromCamera,
      onFail: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );
    
    if (file != null) {
      setState(() {
        _mediaFiles.add(file);
        _selectedType = StatusType.image;
      });
    }
  }
  
  Future<void> _pickVideo() async {
    final file = await pickVideo(
      onFail: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      maxDuration: const Duration(seconds: 30),
    );
    
    if (file != null) {
      setState(() {
        _mediaFiles.clear(); // Only allow one video
        _mediaFiles.add(file);
        _selectedType = StatusType.video;
      });
    }
  }
  
  Future<void> _createStatus() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or media')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = context.read<AuthenticationProvider>();
    final statusProvider = context.read<StatusProvider>();
    final currentUser = authProvider.userModel;
    
    if (currentUser != null) {
      final success = await statusProvider.createStatusPost(
        userId: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        content: content,
        type: _selectedType,
        privacyType: _privacyType,
        mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create status')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final currentUser = context.watch<AuthenticationProvider>().userModel;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Status'),
        backgroundColor: modernTheme.appBarColor,
        elevation: 0.5,
        actions: [
          // Post button
          TextButton(
            onPressed: _isLoading ? null : _createStatus,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User info
            ListTile(
              leading: CircleAvatar(
                backgroundImage: currentUser?.image != null && currentUser!.image.isNotEmpty
                    ? NetworkImage(currentUser.image) as ImageProvider
                    : const AssetImage('assets/images/user_placeholder.png'),
              ),
              title: Text(
                currentUser?.name ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: _buildPrivacySelector(),
            ),
            
            // Content input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                ),
                maxLines: 5,
                minLines: 2,
              ),
            ),
            
            // Media preview
            if (_mediaFiles.isNotEmpty)
              _buildMediaPreview(),
              
            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: modernTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: modernTheme.dividerColor!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Photo button
                      IconButton(
                        icon: const Icon(CupertinoIcons.photo),
                        onPressed: _pickImage,
                        tooltip: 'Add Photo',
                        color: modernTheme.primaryColor,
                      ),
                      
                      // Video button
                      IconButton(
                        icon: const Icon(CupertinoIcons.videocam),
                        onPressed: _pickVideo,
                        tooltip: 'Add Video',
                        color: modernTheme.primaryColor,
                      ),
                      
                      // Link button
                      IconButton(
                        icon: const Icon(CupertinoIcons.link),
                        onPressed: () {
                          setState(() {
                            _selectedType = StatusType.link;
                          });
                          // Show link input dialog
                        },
                        tooltip: 'Add Link',
                        color: modernTheme.primaryColor,
                      ),
                      
                      // Location button
                      IconButton(
                        icon: const Icon(CupertinoIcons.location),
                        onPressed: () {
                          // Add location
                        },
                        tooltip: 'Add Location',
                        color: modernTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivacySelector() {
    final modernTheme = context.modernTheme;
    
    return DropdownButton<StatusPrivacyType>(
      value: _privacyType,
      underline: const SizedBox(),
      icon: const Icon(CupertinoIcons.chevron_down, size: 14),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _privacyType = value;
          });
        }
      },
      items: StatusPrivacyType.values.map((type) {
        return DropdownMenuItem<StatusPrivacyType>(
          value: type,
          child: Row(
            children: [
              Icon(
                _getPrivacyIcon(type),
                size: 16,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _getPrivacyName(type),
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  IconData _getPrivacyIcon(StatusPrivacyType type) {
    switch (type) {
      case StatusPrivacyType.all_contacts:
        return CupertinoIcons.person_2_fill;
      case StatusPrivacyType.except:
        return CupertinoIcons.person_badge_minus;
      case StatusPrivacyType.only:
        return CupertinoIcons.person_badge_plus;
    }
  }
  
  String _getPrivacyName(StatusPrivacyType type) {
    switch (type) {
      case StatusPrivacyType.all_contacts:
        return 'All Contacts';
      case StatusPrivacyType.except:
        return 'All Except...';
      case StatusPrivacyType.only:
        return 'Only Share With...';
    }
  }
  
  Widget _buildMediaPreview() {
    if (_mediaFiles.isEmpty) return const SizedBox();
    
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          // Media preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedType == StatusType.video
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.file(
                        _mediaFiles[0],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  )
                : _mediaFiles.length == 1
                    ? Image.file(
                        _mediaFiles[0],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _mediaFiles.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            _mediaFiles[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
          ),
          
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mediaFiles.clear();
                  if (_contentController.text.isNotEmpty) {
                    _selectedType = StatusType.text;
                  }
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
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}