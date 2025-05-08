import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  UserModel? _foundUser;
  bool _isSearching = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchContact() async {
    if (_phoneController.text.isEmpty) {
      showSnackBar(context, 'Please enter a phone number');
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUser = null;
    });

    final authProvider = context.read<AuthenticationProvider>();
    final phoneNumber = _phoneController.text.startsWith('+') 
        ? _phoneController.text 
        : '+${_phoneController.text}';

    final user = await authProvider.searchUserByPhoneNumber(
      phoneNumber: phoneNumber,
    );

    setState(() {
      _isSearching = false;
      _foundUser = user;
      if (user != null) {
        _nameController.text = user.name;
      }
    });

    if (_foundUser == null) {
      showSnackBar(context, 'No user found with this phone number');
    }
  }

  Future<void> _addContact() async {
    if (_foundUser == null) {
      showSnackBar(context, 'No contact found to add');
      return;
    }

    if (_nameController.text.isEmpty) {
      showSnackBar(context, 'Please enter a name for this contact');
      return;
    }

    final authProvider = context.read<AuthenticationProvider>();
    
    // Check if user is trying to add themselves
    if (_foundUser!.uid == authProvider.uid) {
      showSnackBar(context, 'You cannot add yourself as a contact');
      return;
    }

    // Check if user is already in contacts
    if (authProvider.userModel!.contactsUIDs.contains(_foundUser!.uid)) {
      showSnackBar(context, 'This user is already in your contacts');
      return;
    }

    // Add the contact
    await authProvider.addContact(contactID: _foundUser!.uid);
    
    // Show success and go back
    showSnackBar(context, 'Contact added successfully');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('Add New Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone number field
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+1234567890',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchContact,
                  child: _isSearching 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ) 
                      : Icon(Icons.search),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Contact information section
            if (_foundUser != null) ...[
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              // Profile information
              Row(
                children: [
                  // Contact image
                  userImageWidget(
                    imageUrl: _foundUser!.image,
                    radius: 40,
                    onTap: () {},
                  ),
                  SizedBox(width: 16),
                  
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _foundUser!.phoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _foundUser!.aboutMe,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Contact name field
              Text(
                'Save as (Name)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter contact name',
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addContact,
                  child: Text('Save Contact'),
                ),
              ),
            ],
            
            // No user found state
            if (_foundUser == null && _isSearching == false && _phoneController.text.isNotEmpty) ...[
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    Icon(
                      Icons.person_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No user found with this phone number',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Make sure the phone number is in the correct format (+1234567890)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}