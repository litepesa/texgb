// lib/features/moments/widgets/privacy_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
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
    required this.onContactsChanged, required bool enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Privacy options
        ...MomentPrivacy.values.map((privacy) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PrivacyOption(
            privacy: privacy,
            isSelected: selectedPrivacy == privacy,
            selectedContactsCount: selectedContacts.length,
            onTap: () => _handlePrivacyChange(privacy),
          ),
        )),

        // Contact selection for specific privacy types
        if (_needsContactSelection(selectedPrivacy)) ...[
          const SizedBox(height: 8),
          _buildContactSelection(context, ref),
        ],
      ],
    );
  }

  void _handlePrivacyChange(MomentPrivacy newPrivacy) {
    onPrivacyChanged(newPrivacy);
    
    // Clear contacts when switching to privacy types that don't need them
    if (!_needsContactSelection(newPrivacy)) {
      onContactsChanged([]);
    }
  }

  bool _needsContactSelection(MomentPrivacy privacy) {
    return privacy == MomentPrivacy.selectedContacts || 
           privacy == MomentPrivacy.exceptSelected;
  }

  Widget _buildContactSelection(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
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
              Expanded(
                child: Text(
                  _getContactSelectionTitle(),
                  style: TextStyle(
                    color: context.modernTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: currentUser != null ? () => _selectContacts(context, currentUser) : null,
                child: Text(
                  selectedContacts.isEmpty ? 'Select' : 'Edit',
                  style: TextStyle(
                    color: currentUser != null 
                        ? context.modernTheme.primaryColor
                        : context.modernTheme.textSecondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildContactsSummary(context),
          
          // Warning for contact-dependent privacy options
          if (selectedContacts.isEmpty && _needsContactSelection(selectedPrivacy)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWarningMessage(),
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactsSummary(BuildContext context) {
    if (selectedContacts.isEmpty) {
      return Text(
        'No contacts selected',
        style: TextStyle(
          color: context.modernTheme.textSecondaryColor,
          fontSize: 12,
        ),
      );
    }

    final contactCount = selectedContacts.length;
    final contactText = contactCount == 1 ? 'contact' : 'contacts';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$contactCount $contactText selected',
          style: TextStyle(
            color: context.modernTheme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (contactCount <= 3) ...[
          const SizedBox(height: 4),
          Consumer(
            builder: (context, ref, child) {
              return FutureBuilder<List<UserModel>>(
                future: _loadSelectedContactNames(ref),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final names = snapshot.data!.map((user) => user.name).join(', ');
                    return Text(
                      names,
                      style: TextStyle(
                        color: context.modernTheme.textSecondaryColor,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Future<List<UserModel>> _loadSelectedContactNames(WidgetRef ref) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || selectedContacts.isEmpty) return [];

      final allContacts = await ref
          .read(authenticationProvider.notifier)
          .getContactsList(currentUser.uid, []);

      return allContacts.where((contact) => selectedContacts.contains(contact.uid)).toList();
    } catch (e) {
      return [];
    }
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

  String _getWarningMessage() {
    switch (selectedPrivacy) {
      case MomentPrivacy.selectedContacts:
        return 'Select at least one contact, or your moment won\'t be visible to anyone.';
      case MomentPrivacy.exceptSelected:
        return 'No contacts selected. Your moment will be visible to all contacts.';
      default:
        return '';
    }
  }

  Future<void> _selectContacts(BuildContext context, UserModel currentUser) async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (context) => ContactsSelectionScreen(
            title: _getContactSelectionTitle(),
            userContacts: currentUser.contactsUIDs,
            initialSelectedContacts: selectedContacts,
            multiSelect: true,
            privacyType: selectedPrivacy,
          ),
        ),
      );

      if (result != null) {
        onContactsChanged(result);
      }
    } catch (e) {
      showSnackBar(context, 'Error loading contacts: ${e.toString()}');
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                size: 22,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDescription(),
                      style: TextStyle(
                        color: context.modernTheme.textSecondaryColor,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: context.modernTheme.primaryColor,
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
        return Icons.group;
      case MomentPrivacy.exceptSelected:
        return Icons.group_remove;
    }
  }

  String _getDescription() {
    switch (privacy) {
      case MomentPrivacy.public:
        return privacy.description;
      case MomentPrivacy.contacts:
        return privacy.description;
      case MomentPrivacy.selectedContacts:
        if (selectedContactsCount > 0) {
          return '$selectedContactsCount contact${selectedContactsCount == 1 ? '' : 's'} selected';
        }
        return 'Select specific contacts to share with';
      case MomentPrivacy.exceptSelected:
        if (selectedContactsCount > 0) {
          return 'Hidden from $selectedContactsCount contact${selectedContactsCount == 1 ? '' : 's'}';
        }
        return 'Hide from specific contacts';
    }
  }
}

// Enhanced Contact Selection Screen for Moments
class ContactsSelectionScreen extends ConsumerStatefulWidget {
  final String title;
  final List<String> userContacts;
  final List<String> initialSelectedContacts;
  final bool multiSelect;
  final MomentPrivacy privacyType;

  const ContactsSelectionScreen({
    super.key,
    required this.title,
    required this.userContacts,
    required this.initialSelectedContacts,
    this.multiSelect = true,
    required this.privacyType,
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
  String? _errorMessage;

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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User not found';
          _isLoading = false;
        });
        return;
      }

      if (currentUser.contactsUIDs.isEmpty) {
        setState(() {
          _contacts = [];
          _filteredContacts = [];
          _isLoading = false;
        });
        return;
      }

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
        _errorMessage = 'Failed to load contacts: ${e.toString()}';
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
            onPressed: _canProceed() ? () {
              Navigator.pop(context, _selectedContacts);
            } : null,
            child: Text(
              'Done${_selectedContacts.isNotEmpty ? ' (${_selectedContacts.length})' : ''}',
              style: TextStyle(
                color: _canProceed()
                    ? context.modernTheme.primaryColor
                    : context.modernTheme.textSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Help text
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.modernTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getHelpText(),
                    style: TextStyle(
                      color: context.modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          if (_contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(color: context.modernTheme.textColor),
              ),
            ),

          // Selection controls
          if (_contacts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _selectedContacts.length == _contacts.length ? null : _selectAll,
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Select All'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.modernTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _selectedContacts.isEmpty ? null : _clearAll,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contacts list
          Expanded(
            child: _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState();
    }

    if (_filteredContacts.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
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
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: context.modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Contacts',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadContacts,
            child: const Text('Retry'),
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
            'No Contacts Available',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some contacts to get started',
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: context.modernTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts found',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different term',
            style: TextStyle(
              color: context.modernTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getHelpText() {
    switch (widget.privacyType) {
      case MomentPrivacy.selectedContacts:
        return 'Only selected contacts will be able to see your moment.';
      case MomentPrivacy.exceptSelected:
        return 'All contacts except selected ones will be able to see your moment.';
      default:
        return '';
    }
  }

  bool _canProceed() {
    // For "selected contacts" privacy, at least one contact must be selected
    if (widget.privacyType == MomentPrivacy.selectedContacts) {
      return _selectedContacts.isNotEmpty;
    }
    // For "except selected" privacy, it's okay to have no selections (means visible to all)
    return true;
  }

  void _selectAll() {
    setState(() {
      _selectedContacts = _contacts.map((contact) => contact.uid).toList();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedContacts.clear();
    });
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