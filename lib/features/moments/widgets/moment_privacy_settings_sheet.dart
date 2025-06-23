// lib/features/moments/widgets/moment_privacy_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

// Using the same privacy types as status
enum MomentPrivacyType {
  all_contacts,
  except,
  only,
}

extension MomentPrivacyTypeExtension on MomentPrivacyType {
  String get name {
    switch (this) {
      case MomentPrivacyType.all_contacts:
        return 'all_contacts';
      case MomentPrivacyType.except:
        return 'except';
      case MomentPrivacyType.only:
        return 'only';
    }
  }

  static MomentPrivacyType fromString(String value) {
    switch (value) {
      case 'except':
        return MomentPrivacyType.except;
      case 'only':
        return MomentPrivacyType.only;
      case 'all_contacts':
      default:
        return MomentPrivacyType.all_contacts;
    }
  }
}

class MomentPrivacySettingsSheet extends ConsumerStatefulWidget {
  const MomentPrivacySettingsSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<MomentPrivacySettingsSheet> createState() => _MomentPrivacySettingsSheetState();
}

class _MomentPrivacySettingsSheetState extends ConsumerState<MomentPrivacySettingsSheet> {
  MomentPrivacyType _selectedPrivacyType = MomentPrivacyType.all_contacts;
  final List<UserModel> _selectedContacts = [];
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsNotifierProvider);
    
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              const Text(
                'Privacy Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Privacy options
          ..._buildPrivacyOptions(),
          
          const SizedBox(height: 24),
          
          // Contacts selection (if needed)
          if (_selectedPrivacyType != MomentPrivacyType.all_contacts)
            _buildContactsSelection(contactsState),
            
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isLoading ? null : _saveSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrivacyOptions() {
    return [
      _buildPrivacyOption(
        MomentPrivacyType.all_contacts,
        'My contacts',
        'Share with all your contacts',
        Icons.people,
        const Color(0xFF25D366),
      ),
      const SizedBox(height: 12),
      _buildPrivacyOption(
        MomentPrivacyType.except,
        'My contacts except...',
        'Don\'t share with specific contacts',
        Icons.person_remove,
        const Color(0xFF007AFF),
      ),
      const SizedBox(height: 12),
      _buildPrivacyOption(
        MomentPrivacyType.only,
        'Only share with...',
        'Only share with specific contacts',
        Icons.person_add,
        const Color(0xFFFF6B6B),
      ),
    ];
  }

  Widget _buildPrivacyOption(
    MomentPrivacyType type,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    final isSelected = _selectedPrivacyType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPrivacyType = type;
          // Clear selected contacts when switching types
          if (type == MomentPrivacyType.all_contacts) {
            _selectedContacts.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? accentColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? accentColor
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsSelection(AsyncValue<ContactsState> contactsState) {
    if (contactsState.isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF25D366),
          ),
        ),
      );
    }
    
    if (contactsState.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Error loading contacts',
              style: TextStyle(
                color: Colors.red[300],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (!contactsState.hasValue || contactsState.value!.registeredContacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'No contacts found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    final contacts = contactsState.value!.registeredContacts;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedPrivacyType == MomentPrivacyType.except
                  ? 'Select contacts to exclude'
                  : 'Select contacts to include',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (_selectedContacts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedContacts.length} selected',
                  style: const TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = _selectedContacts.contains(contact);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF25D366).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: userImageWidget(
                    imageUrl: contact.image,
                    radius: 20,
                    onTap: () {},
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF25D366)
                          : Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: !isSelected 
                          ? Border.all(color: Colors.white.withOpacity(0.5))
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedContacts.remove(contact);
                      } else {
                        _selectedContacts.add(contact);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveSettings() {
    setState(() => _isLoading = true);

    // Return the selected settings to the parent (same format as status screen)
    Navigator.pop(context, {
      'privacyType': _selectedPrivacyType,
      'selectedContacts': _selectedPrivacyType != MomentPrivacyType.all_contacts
          ? _selectedContacts
          : [],
    });
  }
}