// lib/features/groups/screens/group_settings_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupSettingsScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late GroupModel _group;
  
  File? _newGroupImage;
  bool _isPrivate = false;
  bool _editSettings = true;
  bool _approveMembers = false;
  bool _lockMessages = false;
  bool _requestToJoin = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _nameController = TextEditingController(text: _group.groupName);
    _descriptionController = TextEditingController(text: _group.groupDescription);
    
    // Initialize settings
    _isPrivate = _group.isPrivate;
    _editSettings = _group.editSettings;
    _approveMembers = _group.approveMembers;
    _lockMessages = _group.lockMessages;
    _requestToJoin = _group.requestToJoin;
    
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
    final hasNameChanged = _nameController.text != _group.groupName;
    final hasDescriptionChanged = _descriptionController.text != _group.groupDescription;
    final hasSettingsChanged = _isPrivate != _group.isPrivate ||
        _editSettings != _group.editSettings ||
        _approveMembers != _group.approveMembers ||
        _lockMessages != _group.lockMessages ||
        _requestToJoin != _group.requestToJoin;
    
    final newHasChanges = hasNameChanged || hasDescriptionChanged || hasSettingsChanged || _newGroupImage != null;
    
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
      final updatedGroup = _group.copyWith(
        groupName: name,
        groupDescription: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
        editSettings: _editSettings,
        approveMembers: _approveMembers,
        lockMessages: _lockMessages,
        requestToJoin: _requestToJoin,
      );
      
      // Save changes
      await ref.read(groupProvider.notifier).updateGroup(
        updatedGroup: updatedGroup,
        newGroupImage: _newGroupImage,
      );
      
      if (mounted) {
        showSnackBar(context, 'Group settings updated');
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: theme.primaryColor!.withOpacity(0.2),
                    backgroundImage: _newGroupImage != null
                        ? FileImage(_newGroupImage!)
                        : (_group.groupImage.isNotEmpty
                            ? NetworkImage(_group.groupImage)
                            : null),
                    child: (_newGroupImage == null && _group.groupImage.isEmpty)
                        ? Icon(
                            Icons.group,
                            size: 64,
                            color: theme.primaryColor,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      radius: 20,
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
            const SizedBox(height: 24),
            
            // Group name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.group,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Group description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Group Description',
                hintText: 'Enter group description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(
                  Icons.description,
                  color: theme.primaryColor,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Group settings
            Card(
              elevation: 0,
              color: theme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.borderColor!.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Settings',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Private/Public switch
                    SwitchListTile(
                      title: Text(
                        'Private Group',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        _isPrivate
                            ? 'Only invited members can join'
                            : 'Anyone can find and join the group',
                        style: TextStyle(color: theme.textSecondaryColor),
                      ),
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value;
                          _hasChanges = true;
                        });
                      },
                      activeColor: theme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    
                    // Admin-only settings switch
                    SwitchListTile(
                      title: Text(
                        'Admin-only Settings',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        _editSettings
                            ? 'Only admins can edit group settings'
                            : 'All members can edit group settings',
                        style: TextStyle(color: theme.textSecondaryColor),
                      ),
                      value: _editSettings,
                      onChanged: (value) {
                        setState(() {
                          _editSettings = value;
                          _hasChanges = true;
                        });
                      },
                      activeColor: theme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    
                    // Approve members switch (only if private)
                    if (_isPrivate)
                      SwitchListTile(
                        title: Text(
                          'Approve Members',
                          style: TextStyle(color: theme.textColor),
                        ),
                        subtitle: Text(
                          _approveMembers
                              ? 'Admins must approve join requests'
                              : 'Members can join without approval',
                          style: TextStyle(color: theme.textSecondaryColor),
                        ),
                        value: _approveMembers,
                        onChanged: (value) {
                          setState(() {
                            _approveMembers = value;
                            _hasChanges = true;
                          });
                        },
                        activeColor: theme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    
                    // Lock messages switch
                    SwitchListTile(
                      title: Text(
                        'Lock Messages',
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        _lockMessages
                            ? 'Only admins can send messages'
                            : 'All members can send messages',
                        style: TextStyle(color: theme.textSecondaryColor),
                      ),
                      value: _lockMessages,
                      onChanged: (value) {
                        setState(() {
                          _lockMessages = value;
                          _hasChanges = true;
                        });
                      },
                      activeColor: theme.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    // Request to join switch (only if public)
                    if (!_isPrivate)
                      SwitchListTile(
                        title: Text(
                          'Request to Join',
                          style: TextStyle(color: theme.textColor),
                        ),
                        subtitle: Text(
                          _requestToJoin
                              ? 'Users must request to join the group'
                              : 'Users can join without requesting',
                          style: TextStyle(color: theme.textSecondaryColor),
                        ),
                        value: _requestToJoin,
                        onChanged: (value) {
                          setState(() {
                            _requestToJoin = value;
                            _hasChanges = true;
                          });
                        },
                        activeColor: theme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}