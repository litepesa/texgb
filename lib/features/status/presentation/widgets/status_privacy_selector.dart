import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import '../../domain/models/status_privacy.dart';
import '../../application/providers/status_providers.dart';
import '../../application/providers/app_providers.dart';
import '../../../../models/user_model.dart';

class StatusPrivacySelector extends ConsumerStatefulWidget {
  const StatusPrivacySelector({Key? key}) : super(key: key);
  
  @override
  ConsumerState<StatusPrivacySelector> createState() => _StatusPrivacySelectorState();
}

class _StatusPrivacySelectorState extends ConsumerState<StatusPrivacySelector> {
  late PrivacyType _selectedPrivacyType;
  late List<String> _includedContactUIDs;
  late List<String> _excludedContactUIDs;
  bool _hideViewCount = false;
  
  List<UserModel> _contacts = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Get current privacy settings
    final currentPrivacy = ref.read(statusPrivacyProvider);
    _selectedPrivacyType = currentPrivacy.type;
    _includedContactUIDs = List.from(currentPrivacy.includedUserIds);
    _excludedContactUIDs = List.from(currentPrivacy.excludedUserIds);
    _hideViewCount = currentPrivacy.hideViewCount;
    
    _loadContacts();
  }
  
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = getCurrentUser(context);
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get the AuthenticationProvider to load contacts
      final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
      
      // Load all user contacts using existing provider
      _contacts = await authProvider.getContactsList(currentUser.uid, []);
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleIncludedContact(String uid) {
    setState(() {
      if (_includedContactUIDs.contains(uid)) {
        _includedContactUIDs.remove(uid);
      } else {
        _includedContactUIDs.add(uid);
      }
    });
  }
  
  void _toggleExcludedContact(String uid) {
    setState(() {
      if (_excludedContactUIDs.contains(uid)) {
        _excludedContactUIDs.remove(uid);
      } else {
        _excludedContactUIDs.add(uid);
      }
    });
  }
  
  void _savePrivacySettings() {
    // Create new privacy settings
    final newPrivacy = StatusPrivacy(
      type: _selectedPrivacyType,
      includedUserIds: _includedContactUIDs,
      excludedUserIds: _excludedContactUIDs,
      hideViewCount: _hideViewCount,
    );
    
    // Update provider
    ref.read(statusPrivacyProvider.notifier).state = newPrivacy;
    
    // Close modal
    Navigator.pop(context);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings updated')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Privacy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Privacy options
          Text(
            'Who can see this status?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          RadioListTile<PrivacyType>(
            title: const Text('All Contacts'),
            subtitle: const Text('Anyone in your contacts list can see your status'),
            value: PrivacyType.allContacts,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          RadioListTile<PrivacyType>(
            title: const Text('All Contacts Except...'),
            subtitle: const Text('Hide from specific contacts'),
            value: PrivacyType.except,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          RadioListTile<PrivacyType>(
            title: const Text('Only Share With...'),
            subtitle: const Text('Only specific contacts can see your status'),
            value: PrivacyType.onlySpecific,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          const Divider(),
          
          // Additional privacy options
          SwitchListTile(
            title: const Text('Hide view count'),
            subtitle: const Text('Others won\'t see how many people viewed your status'),
            value: _hideViewCount,
            onChanged: (value) {
              setState(() {
                _hideViewCount = value;
              });
            },
          ),
          
          const Divider(),
          
          // Contacts list for specific privacy settings
          if (_selectedPrivacyType == PrivacyType.except || _selectedPrivacyType == PrivacyType.onlySpecific) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _selectedPrivacyType == PrivacyType.except
                    ? 'Select contacts to exclude'
                    : 'Select contacts to include',
                style: theme.textTheme.titleSmall,
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No contacts found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadContacts,
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final bool isSelected = _selectedPrivacyType == PrivacyType.except
                                ? _excludedContactUIDs.contains(contact.uid)
                                : _includedContactUIDs.contains(contact.uid);
                            
                            return CheckboxListTile(
                              title: Text(contact.name),
                              secondary: CircleAvatar(
                                backgroundImage: contact.image.isNotEmpty
                                    ? CachedNetworkImageProvider(contact.image)
                                    : null,
                                child: contact.image.isEmpty
                                    ? Text(contact.name[0].toUpperCase())
                                    : null,
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                if (_selectedPrivacyType == PrivacyType.except) {
                                  _toggleExcludedContact(contact.uid);
                                } else {
                                  _toggleIncludedContact(contact.uid);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
          
          // Save button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePrivacySettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}