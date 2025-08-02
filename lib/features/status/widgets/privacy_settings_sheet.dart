// lib/features/status/widgets/privacy_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class StatusPrivacySettingsSheet extends ConsumerStatefulWidget {
  const StatusPrivacySettingsSheet({super.key});

  @override
  ConsumerState<StatusPrivacySettingsSheet> createState() => _StatusPrivacySettingsSheetState();
}

class _StatusPrivacySettingsSheetState extends ConsumerState<StatusPrivacySettingsSheet> {
  StatusPrivacyType _selectedPrivacy = StatusPrivacyType.all_contacts;
  List<String> _allowedViewers = [];
  List<String> _excludedViewers = [];
  List<String> _mutedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await ref.read(statusPrivacySettingsProvider.future);
      
      setState(() {
        _selectedPrivacy = StatusPrivacyTypeExtension.fromString(
          settings['defaultPrivacy'] ?? 'all_contacts'
        );
        _allowedViewers = List<String>.from(settings['allowedViewers'] ?? []);
        _excludedViewers = List<String>.from(settings['excludedViewers'] ?? []);
        _mutedUsers = List<String>.from(settings['mutedUsers'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showSnackBar(context, 'Failed to load privacy settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Status Privacy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _saveSettings,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who can see my status section
                  _buildSectionTitle('Who can see my status', theme),
                  const SizedBox(height: 12),
                  
                  // Privacy options
                  ...StatusPrivacyType.values.map((type) => 
                    _buildPrivacyOption(type, theme)
                  ).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Excluded/Allowed viewers section
                  if (_selectedPrivacy == StatusPrivacyType.except)
                    _buildContactsSection(
                      'Excluded from status',
                      'These contacts will not see your status updates',
                      _excludedViewers,
                      theme,
                    )
                  else if (_selectedPrivacy == StatusPrivacyType.only)
                    _buildContactsSection(
                      'Share status with',
                      'Only these contacts can see your status updates',
                      _allowedViewers,
                      theme,
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Muted statuses section
                  _buildMutedSection(theme),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ModernThemeExtension theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.textColor,
      ),
    );
  }

  Widget _buildPrivacyOption(StatusPrivacyType type, ModernThemeExtension theme) {
    final isSelected = _selectedPrivacy == type;
    
    return InkWell(
      onTap: () => setState(() => _selectedPrivacy = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Radio<StatusPrivacyType>(
              value: type,
              groupValue: _selectedPrivacy,
              activeColor: theme.primaryColor,
              onChanged: (value) => setState(() => _selectedPrivacy = value!),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getPrivacyDescription(type),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && (type == StatusPrivacyType.except || type == StatusPrivacyType.only))
              Text(
                '${type == StatusPrivacyType.except ? _excludedViewers.length : _allowedViewers.length} selected',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSection(
    String title,
    String description,
    List<String> selectedContacts,
    ModernThemeExtension theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, theme),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        
        // Add contacts button
        InkWell(
          onTap: () => _showContactSelector(
            title: title,
            selectedContacts: selectedContacts,
            onSelectionChanged: (contacts) {
              setState(() {
                if (_selectedPrivacy == StatusPrivacyType.except) {
                  _excludedViewers = contacts;
                } else {
                  _allowedViewers = contacts;
                }
              });
            },
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: theme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedContacts.isEmpty 
                      ? 'Add contacts'
                      : '${selectedContacts.length} contact${selectedContacts.length == 1 ? '' : 's'} selected',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: theme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        
        // Selected contacts preview
        if (selectedContacts.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedContacts.length,
              itemBuilder: (context, index) {
                return _buildSelectedContactChip(
                  selectedContacts[index],
                  () {
                    setState(() {
                      selectedContacts.removeAt(index);
                    });
                  },
                  theme,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedContactChip(String contactId, VoidCallback onRemove, ModernThemeExtension theme) {
    final contactsAsync = ref.watch(contactsNotifierProvider);
    
    return contactsAsync.when(
      data: (contactsState) {
        final contact = contactsState.contactsMap[contactId];
        if (contact == null) return const SizedBox();
        
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor!),
                    ),
                    child: ClipOval(
                      child: contact.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: contact.image,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 20),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 20),
                            ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 40,
                child: Text(
                  contact.name.split(' ').first,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(width: 40, height: 60),
      error: (_, __) => const SizedBox(width: 40, height: 60),
    );
  }

  Widget _buildMutedSection(ModernThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Muted status updates', theme),
        const SizedBox(height: 4),
        Text(
          'You won\'t see status updates from these contacts',
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_mutedUsers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceVariantColor?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.volume_off,
                  color: theme.textSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'No muted contacts',
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _mutedUsers.map((userId) => 
              _buildMutedUserItem(userId, theme)
            ).toList(),
          ),
      ],
    );
  }

  Widget _buildMutedUserItem(String userId, ModernThemeExtension theme) {
    final contactsAsync = ref.watch(contactsNotifierProvider);
    
    return contactsAsync.when(
      data: (contactsState) {
        final contact = contactsState.contactsMap[userId];
        if (contact == null) return const SizedBox();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: contact.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: contact.image,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 16),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 16),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contact.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _mutedUsers.remove(userId);
                  });
                },
                child: Text(
                  'Unmute',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _getPrivacyDescription(StatusPrivacyType type) {
    switch (type) {
      case StatusPrivacyType.all_contacts:
        return 'Share with all contacts in your address book';
      case StatusPrivacyType.except:
        return 'Share with all contacts except those you choose';
      case StatusPrivacyType.only:
        return 'Share with only the contacts you choose';
    }
  }

  void _showContactSelector({
    required String title,
    required List<String> selectedContacts,
    required Function(List<String>) onSelectionChanged,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSelectorScreen(
          title: title,
          selectedContacts: selectedContacts,
          onSelectionChanged: onSelectionChanged,
        ),
      ),
    );
  }

  void _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = {
        'defaultPrivacy': _selectedPrivacy.name,
        'allowedViewers': _allowedViewers,
        'excludedViewers': _excludedViewers,
        'mutedUsers': _mutedUsers,
      };
      
      await ref.read(statusNotifierProvider.notifier).updatePrivacySettings(settings);
      
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Privacy settings saved');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showSnackBar(context, 'Failed to save settings');
      }
    }
  }
}

// Contact selector screen for privacy settings
class ContactSelectorScreen extends ConsumerStatefulWidget {
  final String title;
  final List<String> selectedContacts;
  final Function(List<String>) onSelectionChanged;

  const ContactSelectorScreen({
    super.key,
    required this.title,
    required this.selectedContacts,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<ContactSelectorScreen> createState() => _ContactSelectorScreenState();
}

class _ContactSelectorScreenState extends ConsumerState<ContactSelectorScreen> {
  late List<String> _selectedContacts;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedContacts = List.from(widget.selectedContacts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final contactsAsync = ref.watch(contactsNotifierProvider);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        title: Text(widget.title, style: TextStyle(color: theme.textColor)),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSelectionChanged(_selectedContacts);
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: contactsAsync.when(
        data: (contactsState) {
          final contacts = contactsState.registeredContacts;
          final filteredContacts = _searchQuery.isEmpty
              ? contacts
              : contacts.where((contact) =>
                  contact.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: theme.textSecondaryColor),
                    prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: theme.dividerColor!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: theme.dividerColor!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: theme.primaryColor!),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              
              // Selected count
              if (_selectedContacts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_selectedContacts.length} contact${_selectedContacts.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // Contacts list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final isSelected = _selectedContacts.contains(contact.uid);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedContacts.add(contact.uid);
                          } else {
                            _selectedContacts.remove(contact.uid);
                          }
                        });
                      },
                      activeColor: theme.primaryColor,
                      secondary: CircleAvatar(
                        backgroundImage: contact.image.isNotEmpty
                            ? CachedNetworkImageProvider(contact.image)
                            : null,
                        child: contact.image.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        contact.name,
                        style: TextStyle(color: theme.textColor),
                      ),
                      subtitle: Text(
                        contact.phoneNumber,
                        style: TextStyle(color: theme.textSecondaryColor),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Failed to load contacts',
            style: TextStyle(color: theme.textSecondaryColor),
          ),
        ),
      ),
    );
  }
}