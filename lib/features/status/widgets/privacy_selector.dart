// lib/features/status/widgets/privacy_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class PrivacySelector extends StatefulWidget {
  final StatusPrivacyType initialPrivacyType;
  final List<String> includedContactUIDs;
  final List<String> excludedContactUIDs;
  final Function(
    StatusPrivacyType privacyType,
    List<String> includedContactUIDs,
    List<String> excludedContactUIDs,
  ) onSaved;

  const PrivacySelector({
    Key? key,
    required this.initialPrivacyType,
    required this.includedContactUIDs,
    required this.excludedContactUIDs,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<PrivacySelector> createState() => _PrivacySelectorState();
}

class _PrivacySelectorState extends State<PrivacySelector> {
  late StatusPrivacyType _selectedPrivacyType;
  late List<String> _includedContactUIDs;
  late List<String> _excludedContactUIDs;
  
  List<UserModel> _contacts = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _selectedPrivacyType = widget.initialPrivacyType;
    _includedContactUIDs = List.from(widget.includedContactUIDs);
    _excludedContactUIDs = List.from(widget.excludedContactUIDs);
    _loadContacts();
  }
  
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = Provider.of<AuthenticationProvider>(context, listen: false).userModel;
      if (currentUser == null) return;
      
      // Get all contacts for the current user
      _contacts = await Provider.of<AuthenticationProvider>(context, listen: false)
          .getContactsList(currentUser.uid, []);
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: Colors.red,
          ),
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
  
  void _save() {
    widget.onSaved(
      _selectedPrivacyType,
      _includedContactUIDs,
      _excludedContactUIDs,
    );
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        top: 16,
        left: 16, 
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Privacy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Privacy options
          const Text(
            'Who can see my status updates',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          RadioListTile<StatusPrivacyType>(
            title: const Text('My contacts'),
            value: StatusPrivacyType.all_contacts,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          RadioListTile<StatusPrivacyType>(
            title: const Text('My contacts except...'),
            value: StatusPrivacyType.except,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          RadioListTile<StatusPrivacyType>(
            title: const Text('Only share with...'),
            value: StatusPrivacyType.only,
            groupValue: _selectedPrivacyType,
            onChanged: (value) {
              setState(() {
                _selectedPrivacyType = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contacts list
          if (_selectedPrivacyType == StatusPrivacyType.except || _selectedPrivacyType == StatusPrivacyType.only)
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: modernTheme.primaryColor))
                  : _contacts.isEmpty
                      ? const Center(child: Text('No contacts found'))
                      : ListView.builder(
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final bool isSelected = _selectedPrivacyType == StatusPrivacyType.except
                                ? _excludedContactUIDs.contains(contact.uid)
                                : _includedContactUIDs.contains(contact.uid);
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                backgroundImage: contact.image.isNotEmpty
                                    ? CachedNetworkImageProvider(contact.image)
                                    : const AssetImage(AssetsManager.userImage) as ImageProvider,
                              ),
                              title: Text(contact.name),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  if (_selectedPrivacyType == StatusPrivacyType.except) {
                                    _toggleExcludedContact(contact.uid);
                                  } else {
                                    _toggleIncludedContact(contact.uid);
                                  }
                                },
                              ),
                              onTap: () {
                                if (_selectedPrivacyType == StatusPrivacyType.except) {
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
      ),
    );
  }
}