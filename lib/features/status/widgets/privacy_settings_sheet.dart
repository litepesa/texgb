import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class PrivacySettingsSheet extends ConsumerStatefulWidget {
  const PrivacySettingsSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends ConsumerState<PrivacySettingsSheet> {
  StatusPrivacyType _selectedPrivacyType = StatusPrivacyType.all_contacts;
  final List<UserModel> _selectedContacts = [];
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final contactsState = ref.watch(contactsNotifierProvider);
    
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Privacy Settings',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Privacy options
          ..._buildPrivacyOptions(modernTheme),
          
          const SizedBox(height: 20),
          
          // Contacts selection (if needed)
          if (_selectedPrivacyType != StatusPrivacyType.all_contacts)
            _buildContactsSelection(contactsState, modernTheme),
            
          const SizedBox(height: 20),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading 
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrivacyOptions(ModernThemeExtension modernTheme) {
    return [
      _buildPrivacyOption(
        modernTheme,
        StatusPrivacyType.all_contacts,
        'My contacts',
        'Share with all your contacts',
        Icons.people,
      ),
      const SizedBox(height: 8),
      _buildPrivacyOption(
        modernTheme,
        StatusPrivacyType.except,
        'My contacts except...',
        'Don\'t share with specific contacts',
        Icons.person_remove,
      ),
      const SizedBox(height: 8),
      _buildPrivacyOption(
        modernTheme,
        StatusPrivacyType.only,
        'Only share with...',
        'Only share with specific contacts',
        Icons.person_add,
      ),
    ];
  }

  Widget _buildPrivacyOption(
    ModernThemeExtension modernTheme,
    StatusPrivacyType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPrivacyType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPrivacyType = type;
          // Clear selected contacts when switching types
          if (type == StatusPrivacyType.all_contacts) {
            _selectedContacts.clear();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor!.withOpacity(0.1) : modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? modernTheme.primaryColor! : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? modernTheme.primaryColor : modernTheme.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : modernTheme.textSecondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: modernTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSelection(
    AsyncValue<ContactsState> contactsState,
    ModernThemeExtension modernTheme,
  ) {
    if (contactsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (contactsState.hasError) {
      return Center(
        child: Text(
          'Error loading contacts',
          style: TextStyle(color: Colors.red[400]),
        ),
      );
    }
    
    if (!contactsState.hasValue || contactsState.value!.registeredContacts.isEmpty) {
      return Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: modernTheme.textSecondaryColor),
        ),
      );
    }
    
    final contacts = contactsState.value!.registeredContacts;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedPrivacyType == StatusPrivacyType.except
              ? 'Select contacts to exclude'
              : 'Select contacts to include',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          decoration: BoxDecoration(
            color: modernTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = _selectedContacts.contains(contact);
              
              return ListTile(
                leading: userImageWidget(
                  imageUrl: contact.image,
                  radius: 20,
                  onTap: () {},
                ),
                title: Text(
                  contact.name,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Checkbox(
                  value: isSelected,
                  activeColor: modernTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedContacts.contains(contact)) {
                          _selectedContacts.add(contact);
                        }
                      } else {
                        _selectedContacts.remove(contact);
                      }
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    if (_selectedContacts.contains(contact)) {
                      _selectedContacts.remove(contact);
                    } else {
                      _selectedContacts.add(contact);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    // Return the selected settings to the parent
    Navigator.pop(context, {
      'privacyType': _selectedPrivacyType,
      'selectedContacts': _selectedPrivacyType != StatusPrivacyType.all_contacts
          ? _selectedContacts
          : [],
    });
  }
}