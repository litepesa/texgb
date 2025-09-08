import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final TextEditingController _phoneController = TextEditingController();
  UserModel? _foundUser;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchContact() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a phone number';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _foundUser = null;
    });

    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      
      // Ensure phone number is in international format
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber'; // Add + if missing
      }
      
      final user = await contactsNotifier.searchUserByPhoneNumber(phoneNumber);
      
      setState(() {
        _isSearching = false;
        _foundUser = user;
        if (user == null) {
          _error = 'No user found with this phone number';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Error searching for user: ${e.toString()}';
      });
    }
  }

  Future<void> _addContact() async {
    if (_foundUser == null) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.addContact(_foundUser!);
      
      if (mounted) {
        showSnackBar(context, 'Contact added successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Error adding contact: ${e.toString()}';
      });
    }
  }

  // Navigate to contact profile
  void _viewContactProfile() {
    if (_foundUser == null) return;
    
    Navigator.pushNamed(
      context,
      Constants.contactProfileScreen,
      arguments: _foundUser!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone number input
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number with country code',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _phoneController.clear();
                            _foundUser = null;
                            _error = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  // Reset search when phone number changes
                  _foundUser = null;
                  _error = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Search button
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchContact,
              icon: _isSearching 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Searching...' : 'Search'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Found user
            if (_foundUser != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        userImageWidget(
                          imageUrl: _foundUser!.image,
                          radius: 50,
                          onTap: () {},
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _foundUser!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _foundUser!.phoneNumber,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        if (_foundUser!.aboutMe.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _foundUser!.aboutMe,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSearching ? null : _addContact,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Contact'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isSearching ? null : _viewContactProfile,
                                icon: const Icon(Icons.info_outline),
                                label: const Text('View Profile'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Information about adding contacts
            if (_foundUser == null && !_isSearching && _error == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.person_add,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter a phone number to find contacts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Phone numbers should include country code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}