// lib/features/groups/screens/create_group_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _groupImage;
  bool _isPrivate = false;
  bool _editSettings = true;
  bool _approveMembers = false;
  bool _lockMessages = false;
  bool _requestToJoin = false;
  
  List<UserModel> _selectedContacts = [];
  List<UserModel> _selectedAdmins = [];
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load contacts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  Future<void> _loadContacts() async {
    final contactsState = ref.read(contactsNotifierProvider);
    
    if (contactsState.value == null || contactsState.value!.registeredContacts.isEmpty) {
      // If contacts aren't loaded yet, load them
      await ref.read(contactsNotifierProvider.notifier).syncContacts();
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
        _groupImage = image;
      });
    }
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    
    // Ensure at least one member is selected
    if (_selectedContacts.isEmpty) {
      showSnackBar(context, 'Please select at least one member');
      return;
    }
    
    // Ensure name is not empty and has reasonable length
    if (name.isEmpty) {
      showSnackBar(context, 'Please enter a group name');
      return;
    }
    
    if (name.length < 3) {
      showSnackBar(context, 'Group name must be at least 3 characters');
      return;
    }
    
    // Get current user
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      showSnackBar(context, 'User not authenticated');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Prepare member IDs
      final memberUIDs = _selectedContacts.map((contact) => contact.uid).toList();
      
      // Always add current user as member
      if (!memberUIDs.contains(currentUser.uid)) {
        memberUIDs.add(currentUser.uid);
      }
      
      // Prepare admin IDs
      final adminUIDs = _selectedAdmins.map((admin) => admin.uid).toList();
      
      // Always add current user as admin
      if (!adminUIDs.contains(currentUser.uid)) {
        adminUIDs.add(currentUser.uid);
      }
      
      // Create group
      await ref.read(groupProvider.notifier).createGroup(
        groupName: name,
        groupDescription: description,
        membersUIDs: memberUIDs,
        adminsUIDs: adminUIDs,
        groupImage: _groupImage,
        isPrivate: _isPrivate,
        editSettings: _editSettings,
        approveMembers: _approveMembers,
        lockMessages: _lockMessages,
        requestToJoin: _requestToJoin,
      );
      
      if (mounted) {
        showSnackBar(context, 'Group created successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      showSnackBar(context, 'Error creating group: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectContacts() async {
    // Show modal with contact selection
    final selectedContacts = await showModalBottomSheet<List<UserModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modernTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ContactSelectionBottomSheet(
        initialSelection: _selectedContacts,
      ),
    );
    
    if (selectedContacts != null) {
      setState(() {
        _selectedContacts = selectedContacts;
      });
    }
  }

  void _selectAdmins() async {
    // Can only select admins from selected contacts
    if (_selectedContacts.isEmpty) {
      showSnackBar(context, 'Please select members first');
      return;
    }
    
    // Show modal with admin selection
    final selectedAdmins = await showModalBottomSheet<List<UserModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.modernTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AdminSelectionBottomSheet(
        contacts: _selectedContacts,
        initialSelection: _selectedAdmins,
      ),
    );
    
    if (selectedAdmins != null) {
      setState(() {
        _selectedAdmins = selectedAdmins;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        // lib/features/groups/screens/create_group_screen.dart (continued)
        backgroundColor: theme.backgroundColor,
        title: Text(
          'Create Group',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Group image
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: theme.primaryColor!.withOpacity(0.2),
                          backgroundImage: _groupImage != null
                              ? FileImage(_groupImage!)
                              : null,
                          child: _groupImage == null
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
                  TextFormField(
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
                  
                  // Members selection
                  ListTile(
                    title: Text(
                      'Members',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _selectedContacts.isEmpty
                          ? 'No members selected'
                          : '${_selectedContacts.length} members selected',
                      style: TextStyle(
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Select'),
                      onPressed: _selectContacts,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_selectedContacts.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _selectedContacts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: contact.image.isNotEmpty
                                      ? NetworkImage(contact.image)
                                      : null,
                                  backgroundColor: theme.primaryColor!.withOpacity(0.2),
                                  child: contact.image.isEmpty
                                      ? Text(
                                          contact.name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  contact.name.length > 10
                                      ? '${contact.name.substring(0, 8)}...'
                                      : contact.name,
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Admins selection
                  ListTile(
                    title: Text(
                      'Admins',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _selectedAdmins.isEmpty
                          ? 'No admins selected (you will be admin)'
                          : '${_selectedAdmins.length} admins selected',
                      style: TextStyle(
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Select'),
                      onPressed: _selectAdmins,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_selectedAdmins.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedAdmins.length,
                        itemBuilder: (context, index) {
                          final admin = _selectedAdmins[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: admin.image.isNotEmpty
                                          ? NetworkImage(admin.image)
                                          : null,
                                      backgroundColor: theme.primaryColor!.withOpacity(0.2),
                                      child: admin.image.isEmpty
                                          ? Text(
                                              admin.name[0].toUpperCase(),
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 8,
                                        backgroundColor: theme.primaryColor,
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  admin.name.length > 10
                                      ? '${admin.name.substring(0, 8)}...'
                                      : admin.name,
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                                });
                              },
                              activeColor: theme.primaryColor,
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Create button
                  ElevatedButton(
                    onPressed: _createGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Bottom sheet for selecting contacts
class ContactSelectionBottomSheet extends ConsumerStatefulWidget {
  final List<UserModel> initialSelection;

  const ContactSelectionBottomSheet({
    super.key,
    required this.initialSelection,
  });

  @override
  ConsumerState<ContactSelectionBottomSheet> createState() =>
      _ContactSelectionBottomSheetState();
}

class _ContactSelectionBottomSheetState
    extends ConsumerState<ContactSelectionBottomSheet> {
  late List<UserModel> _selectedContacts;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedContacts = List.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsNotifierProvider);
    final theme = context.modernTheme;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Select Members',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedContacts);
                  },
                  child: Text(
                    'Done (${_selectedContacts.length})',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                filled: true,
                fillColor: theme.surfaceVariantColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Contact list
          Flexible(
            child: contactsAsync.when(
              data: (state) {
                final contacts = state.registeredContacts
                    .where((contact) =>
                        contact.name.toLowerCase().contains(_searchQuery) ||
                        contact.phoneNumber.contains(_searchQuery))
                    .toList();
                
                if (contacts.isEmpty) {
                  return Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: theme.textSecondaryColor),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = _selectedContacts.any(
                      (c) => c.uid == contact.uid,
                    );
                    
                    return CheckboxListTile(
                      title: Text(
                        contact.name,
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        contact.phoneNumber,
                        style: TextStyle(color: theme.textSecondaryColor),
                      ),
                      secondary: CircleAvatar(
                        backgroundImage: contact.image.isNotEmpty
                            ? NetworkImage(contact.image)
                            : null,
                        backgroundColor: theme.primaryColor!.withOpacity(0.2),
                        child: contact.image.isEmpty
                            ? Text(
                                contact.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      value: isSelected,
                      activeColor: theme.primaryColor,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedContacts.add(contact);
                          } else {
                            _selectedContacts.removeWhere(
                              (c) => c.uid == contact.uid,
                            );
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Error loading contacts',
                  style: TextStyle(color: theme.textSecondaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet for selecting admins
class AdminSelectionBottomSheet extends StatefulWidget {
  final List<UserModel> contacts;
  final List<UserModel> initialSelection;

  const AdminSelectionBottomSheet({
    super.key,
    required this.contacts,
    required this.initialSelection,
  });

  @override
  State<AdminSelectionBottomSheet> createState() =>
      _AdminSelectionBottomSheetState();
}

class _AdminSelectionBottomSheetState extends State<AdminSelectionBottomSheet> {
  late List<UserModel> _selectedAdmins;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedAdmins = List.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    // Filter contacts based on search query
    final filteredContacts = widget.contacts
        .where((contact) =>
            contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            contact.phoneNumber.contains(_searchQuery))
        .toList();
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  'Select Admins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedAdmins);
                  },
                  child: Text(
                    'Done (${_selectedAdmins.length})',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                filled: true,
                fillColor: theme.surfaceVariantColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Admin selection
          Flexible(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: theme.textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final isSelected = _selectedAdmins.any(
                        (c) => c.uid == contact.uid,
                      );
                      
                      return CheckboxListTile(
                        title: Text(
                          contact.name,
                          style: TextStyle(color: theme.textColor),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              contact.phoneNumber,
                              style: TextStyle(color: theme.textSecondaryColor),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.star,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ],
                          ],
                        ),
                        secondary: CircleAvatar(
                          backgroundImage: contact.image.isNotEmpty
                              ? NetworkImage(contact.image)
                              : null,
                          backgroundColor: theme.primaryColor!.withOpacity(0.2),
                          child: contact.image.isEmpty
                              ? Text(
                                  contact.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        value: isSelected,
                        activeColor: theme.primaryColor,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedAdmins.add(contact);
                            } else {
                              _selectedAdmins.removeWhere(
                                (c) => c.uid == contact.uid,
                              );
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}