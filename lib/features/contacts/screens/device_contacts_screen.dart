import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class DeviceContactsScreen extends StatefulWidget {
  const DeviceContactsScreen({Key? key}) : super(key: key);

  @override
  State<DeviceContactsScreen> createState() => _DeviceContactsScreenState();
}

class _DeviceContactsScreenState extends State<DeviceContactsScreen> {
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
    
    // Check for permission and request if needed
    if (!contactsProvider.hasPermission) {
      await contactsProvider.requestContactsPermission();
    }
    
    // Sync contacts if we have permission
    if (contactsProvider.hasPermission) {
      await contactsProvider.syncContacts(context);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Phone Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeScreen,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(
              placeholder: 'Search contacts',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Add all button for suggested contacts
          Consumer<ContactsProvider>(
            builder: (context, provider, child) {
              if (provider.suggestedContacts.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Found ${provider.suggestedContacts.length} contacts on TexGB',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: provider.isLoading 
                        ? null 
                        : () => provider.addAllSuggestedContacts(context),
                      child: const Text('Add All'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Main content
          Expanded(
            child: Consumer<ContactsProvider>(
              builder: (context, provider, child) {
                if (_isLoading || provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!provider.hasPermission) {
                  return _buildPermissionRequest(context);
                }
                
                return _buildContactsList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Contact access required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'We need access to your contacts to help you find friends who are already using TexGB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<ContactsProvider>(context, listen: false);
              await provider.requestContactsPermission();
              if (provider.hasPermission) {
                await provider.syncContacts(context);
                setState(() {});
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactsList(ContactsProvider provider) {
    // If there are no device contacts to display
    if (provider.deviceContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No contacts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your contacts will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    // First display device contacts that have the app
    final suggestedContacts = provider.suggestedContacts;
    final filteredSuggestions = suggestedContacts
        .where((user) => 
            user.name.toLowerCase().contains(_searchQuery) || 
            user.phoneNumber.toLowerCase().contains(_searchQuery))
        .toList();
    
    // Then filter and show all device contacts
    final filteredDeviceContacts = provider.deviceContacts
        .where((contact) {
          // Skip if the contact is already added
          final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : '';
          final isAlreadyAdded = suggestedContacts.any((user) => 
              user.phoneNumber.contains(phoneNumber.replaceAll(RegExp(r'\D'), '')));
          
          if (isAlreadyAdded) {
            return false;
          }
          
          // Filter by search query
          final name = contact.displayName.toLowerCase();
          final phone = contact.phones.isNotEmpty 
              ? contact.phones.first.number.toLowerCase() 
              : '';
          
          return name.contains(_searchQuery) || phone.contains(_searchQuery);
        })
        .toList();
    
    return ListView(
      children: [
        // Header for suggested contacts
        if (filteredSuggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Contacts on TexGB',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // List of suggested contacts
          ...filteredSuggestions.map((contact) => ListTile(
            leading: userImageWidget(
              imageUrl: contact.image,
              radius: 24,
              onTap: () {},
            ),
            title: Text(contact.name),
            subtitle: Text(contact.phoneNumber),
            trailing: ElevatedButton(
              onPressed: provider.isLoading 
                ? null 
                : () => provider.addSuggestedContact(contact, context),
              child: const Text('Add'),
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                Constants.contactProfileScreen,
                arguments: contact.uid,
              );
            },
          )).toList(),
          
          const Divider(thickness: 1, height: 32),
        ],
        
        // Header for all device contacts
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'All Contacts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // List of all device contacts
        ...filteredDeviceContacts.map((contact) => ListTile(
          leading: CircleAvatar(
            child: Text(contact.displayName.isNotEmpty 
                ? contact.displayName[0].toUpperCase() 
                : '?'),
          ),
          title: Text(contact.displayName),
          subtitle: Text(
            contact.phones.isNotEmpty ? contact.phones.first.number : 'No phone number',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showSnackBar(context, 'Invite coming soon');
              // TODO: Implement invite functionality
            },
          ),
        )).toList(),
      ],
    );
  }
}