// lib/features/moments/widgets/privacy_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/models/user_model.dart';

class PrivacySelector extends ConsumerWidget {
  final MomentPrivacy selectedPrivacy;
  final List<String> selectedContacts;
  final Function(MomentPrivacy) onPrivacyChanged;
  final Function(List<String>) onContactsChanged;

  const PrivacySelector({
    super.key,
    required this.selectedPrivacy,
    required this.selectedContacts,
    required this.onPrivacyChanged,
    required this.onContactsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Privacy options
        ...MomentPrivacy.values.map((privacy) => _PrivacyOption(
          privacy: privacy,
          isSelected: selectedPrivacy == privacy,
          selectedContactsCount: selectedContacts.length,
          onTap: () => onPrivacyChanged(privacy),
        )),

        // Contact selection for specific privacy types
        if (_needsContactSelection(selectedPrivacy)) ...[
          const SizedBox(height: 16),
          _buildContactSelection(context, ref),
        ],
      ],
    );
  }

  bool _needsContactSelection(MomentPrivacy privacy) {
    return privacy == MomentPrivacy.selectedContacts || 
           privacy == MomentPrivacy.exceptSelected;
  }

  Widget _buildContactSelection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.modernTheme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.modernTheme.borderColor!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getContactSelectionTitle(),
                style: TextStyle(
                  color: context.modernTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _selectContacts(context, currentUser),
                child: Text(
                  selectedContacts.isEmpty ? 'Select' : 'Edit',
                  style: TextStyle(
                    color: context.modernTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedContacts.isEmpty 
                ? 'No contacts selected'
                : '${selectedContacts.length} contact${selectedContacts.length == 1 ? '' : 's'} selected',
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getContactSelectionTitle() {
    switch (selectedPrivacy) {
      case MomentPrivacy.selectedContacts:
        return 'Select contacts who can see this moment';
      case MomentPrivacy.exceptSelected:
        return 'Select contacts to hide this moment from';
      default:
        return '';
    }
  }

  Future<void> _selectContacts(BuildContext context, UserModel currentUser) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsSelectionScreen(
          title: _getContactSelectionTitle(),
          userContacts: currentUser.contactsUIDs,
          initialSelectedContacts: selectedContacts,
          multiSelect: true,
        ),
      ),
    );

    if (result != null) {
      onContactsChanged(result);
    }
  }
}

class _PrivacyOption extends StatelessWidget {
  final MomentPrivacy privacy;
  final bool isSelected;
  final int selectedContactsCount;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.privacy,
    required this.isSelected,
    required this.selectedContactsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.modernTheme.primaryColor?.withOpacity(0.1)
              : context.modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? context.modernTheme.primaryColor!
                : context.modernTheme.borderColor!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getPrivacyIcon(),
              color: isSelected 
                  ? context.modernTheme.primaryColor
                  : context.modernTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    privacy.displayName,
                    style: TextStyle(
                      color: isSelected 
                          ? context.modernTheme.primaryColor
                          : context.modernTheme.textColor,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(),
                    style: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.modernTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon() {
    switch (privacy) {
      case MomentPrivacy.public:
        return Icons.public;
      case MomentPrivacy.contacts:
        return Icons.contacts;
      case MomentPrivacy.selectedContacts:
        return Icons.people;
      case MomentPrivacy.exceptSelected:
        return Icons.people_outline;
    }
  }

  String _getDescription() {
    switch (privacy) {
      case MomentPrivacy.public:
        return privacy.description;
      case MomentPrivacy.contacts:
        return privacy.description;
      case MomentPrivacy.selectedContacts:
        return selectedContactsCount > 0 
            ? '$selectedContactsCount contact${selectedContactsCount == 1 ? '' : 's'} selected'
            : privacy.description;
      case MomentPrivacy.exceptSelected:
        return selectedContactsCount > 0 
            ? 'Hidden from $selectedContactsCount contact${selectedContactsCount == 1 ? '' : 's'}'
            : privacy.description;
    }
  }
}

// Contact Selection Screen for Moments
class ContactsSelectionScreen extends ConsumerStatefulWidget {
  final String title;
  final List<String> userContacts;
  final List<String> initialSelectedContacts;
  final bool multiSelect;

  const ContactsSelectionScreen({
    super.key,
    required this.title,
    required this.userContacts,
    required this.initialSelectedContacts,
    this.multiSelect = true,
  });

  @override
  ConsumerState<ContactsSelectionScreen> createState() => _ContactsSelectionScreenState();
}

class _ContactsSelectionScreenState extends ConsumerState<ContactsSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _selectedContacts;
  List<UserModel> _contacts = [];
  List<UserModel> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedContacts = List.from(widget.initialSelectedContacts);
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final contacts = await ref
          .read(authenticationProvider.notifier)
          .getContactsList(currentUser.uid, []);

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
               contact.phoneNumber.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.modernTheme.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Contacts',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _selectedContacts.isEmpty ? null : () {
              Navigator.pop(context, _selectedContacts);
            },
            child: Text(
              'Done${_selectedContacts.isNotEmpty ? ' (${_selectedContacts.length})' : ''}',
              style: TextStyle(
                color: _selectedContacts.isEmpty 
                    ? context.modernTheme.textSecondaryColor
                    : context.modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: context.modernTheme.textSecondaryColor),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.modernTheme.textSecondaryColor,
                ),
                filled: true,
                fillColor: context.modernTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: context.modernTheme.textColor),
            ),
          ),

          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final isSelected = _selectedContacts.contains(contact.uid);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: contact.image.isNotEmpty
                                  ? NetworkImage(contact.image)
                                  : null,
                              backgroundColor: context.modernTheme.surfaceVariantColor,
                              child: contact.image.isEmpty
                                  ? Text(
                                      contact.name.isNotEmpty 
                                          ? contact.name[0].toUpperCase()
                                          : "U",
                                      style: TextStyle(
                                        color: context.modernTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              contact.name,
                              style: TextStyle(
                                color: context.modernTheme.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              contact.phoneNumber,
                              style: TextStyle(
                                color: context.modernTheme.textSecondaryColor,
                              ),
                            ),
                            trailing: widget.multiSelect
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (value) => _toggleContact(contact.uid),
                                    activeColor: context.modernTheme.primaryColor,
                                  )
                                : isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: context.modernTheme.primaryColor,
                                      )
                                    : null,
                            onTap: () => _toggleContact(contact.uid),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: context.modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'No contacts found'
                : 'No contacts available',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try searching with a different term'
                : 'Add some contacts to get started',
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleContact(String contactId) {
    setState(() {
      if (_selectedContacts.contains(contactId)) {
        _selectedContacts.remove(contactId);
      } else {
        if (widget.multiSelect) {
          _selectedContacts.add(contactId);
        } else {
          _selectedContacts = [contactId];
          Navigator.pop(context, _selectedContacts);
        }
      }
    });
  }
}