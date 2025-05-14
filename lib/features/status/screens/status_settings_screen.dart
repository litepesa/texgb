import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class StatusSettingsScreen extends ConsumerStatefulWidget {
  const StatusSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StatusSettingsScreen> createState() => _StatusSettingsScreenState();
}

class _StatusSettingsScreenState extends ConsumerState<StatusSettingsScreen> {
  late StatusPrivacyType _defaultPrivacyType;
  List<String> _privacyUIDs = [];
  List<UserModel> _selectedContacts = [];
  bool _readReceiptsEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoDownloadMedia = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Get current settings from provider
    final statusState = ref.read(statusProvider).valueOrNull;
    if (statusState != null) {
      _defaultPrivacyType = statusState.defaultPrivacy;
      _privacyUIDs = List.from(statusState.privacyUIDs);
      
      // Load selected contacts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSelectedContacts();
      });
    } else {
      _defaultPrivacyType = StatusPrivacyType.all_contacts;
    }
  }
  
  Future<void> _loadSelectedContacts() async {
    if (_privacyUIDs.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get contacts information for the selected UIDs
      final contactsNotifier = ref.read(contactsNotifierProvider);
      _selectedContacts = [];
      
      // Load from registered contacts
      final contactsState = contactsNotifier.valueOrNull;
      if (contactsState != null) {
        for (final uid in _privacyUIDs) {
          // Find matching contact in registered contacts list
          final contact = contactsState.registeredContacts
              .where((c) => c.uid == uid)
              .firstOrNull;
          
          if (contact != null) {
            _selectedContacts.add(contact);
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, 'Error loading contacts: $e');
      }
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update default privacy settings
      ref.read(statusProvider.notifier).updateDefaultPrivacy(
        privacyType: _defaultPrivacyType,
        privacyUIDs: _privacyUIDs,
      );
      
      // TODO: In a real app, save other settings to user preferences
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Settings saved');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        showSnackBar(context, 'Error saving settings: $e');
      }
    }
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
        title: const Text('Status Settings'),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _saveSettings,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: ListView(
        children: [
          // Default privacy section
          _buildSectionHeader(modernTheme, 'Default Privacy'),
          
          RadioListTile<StatusPrivacyType>(
            title: Text(
              StatusPrivacyType.all_contacts.displayName,
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'All your contacts will be able to see your status updates',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: StatusPrivacyType.all_contacts,
            groupValue: _defaultPrivacyType,
            onChanged: (value) {
              setState(() {
                _defaultPrivacyType = value!;
                _privacyUIDs = [];
                _selectedContacts = [];
              });
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          RadioListTile<StatusPrivacyType>(
            title: Text(
              StatusPrivacyType.except.displayName,
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'All your contacts except those you exclude will see your status',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: StatusPrivacyType.except,
            groupValue: _defaultPrivacyType,
            onChanged: (value) {
              setState(() {
                _defaultPrivacyType = value!;
              });
              _showContactSelection(
                title: 'Hide from...',
                isExcluding: true,
              );
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          RadioListTile<StatusPrivacyType>(
            title: Text(
              StatusPrivacyType.only.displayName,
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Only specific contacts will see your status updates',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: StatusPrivacyType.only,
            groupValue: _defaultPrivacyType,
            onChanged: (value) {
              setState(() {
                _defaultPrivacyType = value!;
              });
              _showContactSelection(
                title: 'Share with...',
                isExcluding: false,
              );
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          // Selected contacts for except/only mode
          if (_defaultPrivacyType != StatusPrivacyType.all_contacts && _selectedContacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _defaultPrivacyType == StatusPrivacyType.except
                        ? 'Hidden from:'
                        : 'Shared with:',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedContacts.map((contact) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: contact.image.isNotEmpty
                              ? NetworkImage(contact.image)
                              : null,
                          child: contact.image.isEmpty
                              ? Text(contact.name.isNotEmpty ? contact.name[0] : '?')
                              : null,
                        ),
                        label: Text(contact.name),
                        onDeleted: () {
                          setState(() {
                            _selectedContacts.remove(contact);
                            _privacyUIDs.remove(contact.uid);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      _showContactSelection(
                        title: _defaultPrivacyType == StatusPrivacyType.except
                            ? 'Hide from...'
                            : 'Share with...',
                        isExcluding: _defaultPrivacyType == StatusPrivacyType.except,
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ),
          
          const Divider(),
          
          // Other settings
          _buildSectionHeader(modernTheme, 'Notifications & Media'),
          
          SwitchListTile(
            title: Text(
              'Read Receipts',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Let others know when you\'ve viewed their status',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: _readReceiptsEnabled,
            onChanged: (value) {
              setState(() {
                _readReceiptsEnabled = value;
              });
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          SwitchListTile(
            title: Text(
              'Status Notifications',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Get notified when contacts post new status updates',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          SwitchListTile(
            title: Text(
              'Auto-Download Media',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Automatically download photos and videos in status updates',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            value: _autoDownloadMedia,
            onChanged: (value) {
              setState(() {
                _autoDownloadMedia = value;
              });
            },
            activeColor: modernTheme.primaryColor,
          ),
          
          const SizedBox(height: 16),
          
          // Status management options
          _buildSectionHeader(modernTheme, 'Status Management'),
          
          ListTile(
            leading: Icon(
              Icons.people_alt,
              color: modernTheme.primaryColor!,
            ),
            title: Text(
              'Muted Contacts',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Manage contacts whose status updates you want to hide',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
            onTap: () {
              // TODO: Navigate to muted contacts screen
              showSnackBar(context, 'Muted contacts feature coming soon');
            },
          ),
          
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            title: const Text(
              'Delete All My Status Updates',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              _showDeleteAllConfirmation(context);
            },
          ),
          
          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Status updates are automatically deleted after 24 hours.',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(ModernThemeExtension modernTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: modernTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Status Updates'),
        content: const Text(
          'Are you sure you want to delete all your status updates? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete all statuses functionality
              Navigator.pop(context);
              showSnackBar(context, 'Delete all feature coming soon');
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}