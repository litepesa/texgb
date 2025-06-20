// lib/features/public_groups/screens/edit_public_group_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class EditPublicGroupScreen extends ConsumerStatefulWidget {
  final PublicGroupModel publicGroup;

  const EditPublicGroupScreen({
    super.key,
    required this.publicGroup,
  });

  @override
  ConsumerState<EditPublicGroupScreen> createState() => _EditPublicGroupScreenState();
}

class _EditPublicGroupScreenState extends ConsumerState<EditPublicGroupScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late PublicGroupModel _publicGroup;
  
  File? _newGroupImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _publicGroup = widget.publicGroup;
    _nameController = TextEditingController(text: _publicGroup.groupName);
    _descriptionController = TextEditingController(text: _publicGroup.groupDescription);
    
    // Listen for changes to track dirty state
    _nameController.addListener(_checkChanges);
    _descriptionController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkChanges);
    _descriptionController.removeListener(_checkChanges);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasNameChanged = _nameController.text != _publicGroup.groupName;
    final hasDescriptionChanged = _descriptionController.text != _publicGroup.groupDescription;
    
    final newHasChanges = hasNameChanged || hasDescriptionChanged || _newGroupImage != null;
    
    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  void _pickImage() async {
    final image = await pickImage(
      fromCamera: false,
      onFail: (error) {
        showSnackBar(context, error);
      },
    );

    if (image != null) {
      setState(() {
        _newGroupImage = image;
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() async {
    // Validate inputs
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackBar(context, 'Please enter a group name');
      return;
    }
    
    if (name.length < 3) {
      showSnackBar(context, 'Group name must be at least 3 characters');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create updated group model
      final updatedGroup = _publicGroup.copyWith(
        groupName: name,
        groupDescription: _descriptionController.text.trim(),
      );
      
      // Save changes
      await ref.read(publicGroupProvider.notifier).updatePublicGroup(
        updatedGroup: updatedGroup,
        newGroupImage: _newGroupImage,
      );
      
      if (mounted) {
        showSnackBar(context, 'Group updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error updating group: $e');
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
          'Edit Group',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group image
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.primaryColor!.withOpacity(0.1),
                    ),
                    child: _newGroupImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _newGroupImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (_publicGroup.groupImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _publicGroup.groupImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.campaign_outlined,
                                      size: 48,
                                      color: theme.primaryColor,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.campaign_outlined,
                                size: 48,
                                color: theme.primaryColor,
                              )),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Group name
            Text(
              'Group Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter group name',
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
                prefixIcon: Icon(
                  Icons.campaign_outlined,
                  color: theme.primaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Group description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'What is this group about?',
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
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: theme.primaryColor,
                ),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 32),
            
            // Group stats
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
                    'Group Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    icon: Icons.people_outline,
                    title: 'Followers',
                    value: _publicGroup.getSubscribersText(),
                    theme: theme,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Created',
                    value: _formatDate(_publicGroup.createdAt),
                    theme: theme,
                  ),
                  
                  if (_publicGroup.lastPostAt.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.post_add_outlined,
                      title: 'Last Post',
                      value: _formatDate(_publicGroup.lastPostAt),
                      theme: theme,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoRow(
                    icon: _publicGroup.isVerified ? Icons.verified : Icons.public,
                    title: 'Status',
                    value: _publicGroup.isVerified ? 'Verified' : 'Public',
                    theme: theme,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Warning about editing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Changes to your group will be visible to all followers. Make sure your updates reflect your group\'s purpose.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required ModernThemeExtension theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return 'Unknown';
    
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return 'Today';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}