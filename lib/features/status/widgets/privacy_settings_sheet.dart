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
  StatusPrivacyType _originalPrivacy = StatusPrivacyType.all_contacts; // Track original for changes
  List<String> _allowedViewers = [];
  List<String> _originalAllowedViewers = []; // Track original for changes
  List<String> _excludedViewers = [];
  List<String> _originalExcludedViewers = []; // Track original for changes
  List<String> _mutedUsers = [];
  List<String> _originalMutedUsers = []; // Track original for changes
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    
    try {
      final settings = await ref.read(statusPrivacySettingsProvider.future);
      
      if (mounted) {
        setState(() {
          // Load current settings
          _selectedPrivacy = StatusPrivacyTypeExtension.fromString(
            settings['defaultPrivacy']?.toString() ?? 'all_contacts'
          );
          _allowedViewers = List<String>.from(settings['allowedViewers'] ?? []);
          _excludedViewers = List<String>.from(settings['excludedViewers'] ?? []);
          _mutedUsers = List<String>.from(settings['mutedUsers'] ?? []);
          
          // Store original values for change detection
          _originalPrivacy = _selectedPrivacy;
          _originalAllowedViewers = List.from(_allowedViewers);
          _originalExcludedViewers = List.from(_excludedViewers);
          _originalMutedUsers = List.from(_mutedUsers);
          
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Failed to load privacy settings: ${e.toString()}';
        });
        
        // Show error to user
        showSnackBar(context, 'Failed to load privacy settings. Please try again.');
      }
    }
  }

  void _checkForChanges() {
    final hasChanges = _selectedPrivacy != _originalPrivacy ||
        !_listEquals(_allowedViewers, _originalAllowedViewers) ||
        !_listEquals(_excludedViewers, _originalExcludedViewers) ||
        !_listEquals(_mutedUsers, _originalMutedUsers);
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final theme = context.modernTheme;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Discard Changes?',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Editing',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9, // Fixed height for better UX
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
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
            
            // Header with better state management
            _buildHeader(theme),
            
            // Error state
            if (_loadError != null)
              _buildErrorState(theme)
            else if (_isLoading)
              _buildLoadingState(theme)
            else
              // Content
              Expanded(
                child: _buildContent(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Close button with unsaved changes warning
          IconButton(
            onPressed: _hasUnsavedChanges ? () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            } : () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: theme.textColor,
            ),
          ),
          
          Expanded(
            child: Column(
              children: [
                Text(
                  'Status Privacy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                if (_hasUnsavedChanges)
                  Text(
                    'Unsaved changes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          
          // Save button with better states
          if (_isSaving)
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
              onPressed: _hasUnsavedChanges ? _saveSettings : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _hasUnsavedChanges ? theme.primaryColor : theme.textSecondaryColor,
                  fontWeight: _hasUnsavedChanges ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension theme) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _loadError!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPrivacySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading privacy settings...',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ModernThemeExtension theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
      onTap: () {
        setState(() {
          _selectedPrivacy = type;
        });
        _checkForChanges();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Radio<StatusPrivacyType>(
              value: type,
              groupValue: _selectedPrivacy,
              activeColor: theme.primaryColor,
              onChanged: (value) {
                setState(() {
                  _selectedPrivacy = value!;
                });
                _checkForChanges();
              },
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${type == StatusPrivacyType.except ? _excludedViewers.length : _allowedViewers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
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
              _checkForChanges();
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
                Expanded(
                  child: Text(
                    selectedContacts.isEmpty 
                        ? 'Add contacts'
                        : '${selectedContacts.length} contact${selectedContacts.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
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
                    _checkForChanges();
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
                  _checkForChanges();
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
    if (_isSaving) return; // Prevent double-saving
    
    setState(() => _isSaving = true);
    
    try {
      final settings = {
        'defaultPrivacy': _selectedPrivacy.name,
        'allowedViewers': _allowedViewers,
        'excludedViewers': _excludedViewers,
        'mutedUsers': _mutedUsers,
      };
      
      await ref.read(statusNotifierProvider.notifier).updatePrivacySettings(settings);
      
      // Update original values after successful save
      setState(() {
        _originalPrivacy = _selectedPrivacy;
        _originalAllowedViewers = List.from(_allowedViewers);
        _originalExcludedViewers = List.from(_excludedViewers);
        _originalMutedUsers = List.from(_mutedUsers);
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(context, 'Privacy settings saved successfully');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        showSnackBar(context, 'Failed to save settings: ${e.toString()}');
        
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) {
            final theme = context.modernTheme;
            return AlertDialog(
              backgroundColor: theme.surfaceColor,
              title: Text(
                'Save Failed',
                style: TextStyle(color: theme.textColor),
              ),
              content: Text(
                'Your privacy settings could not be saved. Please try again.\n\nError: ${e.toString()}',
                style: TextStyle(color: theme.textSecondaryColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveSettings(); // Retry
                  },
                  child: Text(
                    'Retry',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ],
            );
          },
        );
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
  late List<String> _originalSelectedContacts; // Track original for changes
  String _searchQuery = '';
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedContacts = List.from(widget.selectedContacts);
    _originalSelectedContacts = List.from(widget.selectedContacts);
  }

  void _checkForChanges() {
    final hasChanges = !_listEquals(_selectedContacts, _originalSelectedContacts);
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    final sortedA = List<T>.from(a)..sort();
    final sortedB = List<T>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final theme = context.modernTheme;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Discard Changes?',
          style: TextStyle(color: theme.textColor),
        ),
        content: Text(
          'You have unsaved changes to your contact selection. Are you sure you want to discard them?',
          style: TextStyle(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Editing',
              style: TextStyle(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final contactsAsync = ref.watch(contactsNotifierProvider);
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          backgroundColor: theme.surfaceColor,
          title: Column(
            children: [
              Text(widget.title, style: TextStyle(color: theme.textColor)),
              if (_hasUnsavedChanges)
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.textColor),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _hasUnsavedChanges ? () {
                widget.onSelectionChanged(_selectedContacts);
                Navigator.pop(context);
              } : null,
              child: Text(
                'Done',
                style: TextStyle(
                  color: _hasUnsavedChanges ? theme.primaryColor : theme.textSecondaryColor,
                  fontWeight: _hasUnsavedChanges ? FontWeight.bold : FontWeight.normal,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor!, width: 0.5),
                    ),
                  ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                
                // Selected count and clear all
                if (_selectedContacts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor?.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor!, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedContacts.length} contact${_selectedContacts.length == 1 ? '' : 's'} selected',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedContacts.clear();
                            });
                            _checkForChanges();
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Contacts list
                Expanded(
                  child: filteredContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty ? Icons.contacts : Icons.search_off,
                                size: 64,
                                color: theme.textSecondaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty 
                                    ? 'No contacts available'
                                    : 'No contacts found for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                                _checkForChanges();
                              },
                              activeColor: theme.primaryColor,
                              secondary: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.dividerColor!, width: 1),
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
                              title: Text(
                                contact.name,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                contact.phoneNumber,
                                style: TextStyle(color: theme.textSecondaryColor),
                              ),
                              tileColor: isSelected ? theme.primaryColor?.withOpacity(0.05) : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                ),
                
                // Bottom action bar
                if (_hasUnsavedChanges)
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceColor,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor!, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedContacts = List.from(_originalSelectedContacts);
                                _hasUnsavedChanges = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.primaryColor!),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onSelectionChanged(_selectedContacts);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.textSecondaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load contacts',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Refresh contacts
                    ref.refresh(contactsNotifierProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}