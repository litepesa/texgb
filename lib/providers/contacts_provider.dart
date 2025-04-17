import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';
import 'package:textgb/widgets/contact_widget.dart';

class ContactsProvider extends ChangeNotifier {
  List<Contact> _deviceContacts = [];
  List<UserModel> _appContacts = [];
  List<UserModel> _registeredContacts = [];
  bool _isLoading = false;
  bool _hasPermission = false;

  List<Contact> get deviceContacts => _deviceContacts;
  List<UserModel> get appContacts => _appContacts;
  List<UserModel> get registeredContacts => _registeredContacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;

  Future<void> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    _hasPermission = status.isGranted;
    notifyListeners();
  }

  Future<void> loadContacts(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final authProvider = context.read<AuthenticationProvider>();
    
    try {
      // Load app contacts (users already in contact list)
      _appContacts = await authProvider.getContactsList(
        authProvider.uid!,
        [],
      );

      // Check if we have permission to access device contacts
      if (await Permission.contacts.isGranted) {
        _hasPermission = true;
        
        // Load device contacts
        _deviceContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: true,
        );
        
        // Match device contacts with app users
        await _matchContactsWithAppUsers(authProvider);
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _matchContactsWithAppUsers(AuthenticationProvider authProvider) async {
    _registeredContacts = [];
    
    for (var contact in _deviceContacts) {
      if (contact.phones.isEmpty) continue;
      
      for (var phone in contact.phones) {
        // Try different phone number formats
        final phoneFormats = _generatePhoneFormats(phone.number);
        
        for (var formattedPhone in phoneFormats) {
          final user = await authProvider.searchUserByPhoneNumber(
            phoneNumber: formattedPhone,
          );
          
          if (user != null && 
              !_registeredContacts.any((c) => c.uid == user.uid) &&
              !_appContacts.any((c) => c.uid == user.uid)) {
            _registeredContacts.add(user);
            break;
          }
        }
      }
    }
  }

  List<String> _generatePhoneFormats(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Generate different possible formats for the phone number
    final formats = <String>[];
    
    // Original number
    formats.add(phoneNumber);
    
    // With country code (example: +1 for US)
    if (!digitsOnly.startsWith('+')) {
      formats.add('+1$digitsOnly'); // Adding US code as example
    }
    
    // Without any formatting
    formats.add(digitsOnly);
    
    return formats;
  }
  
  Future<void> addRegisteredContact(UserModel user, BuildContext context) async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      await authProvider.addContact(contactID: user.uid);
      
      // Update local lists
      _appContacts.add(user);
      _registeredContacts.removeWhere((contact) => contact.uid == user.uid);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }
}

class DeviceContactsScreen extends StatefulWidget {
  const DeviceContactsScreen({Key? key}) : super(key: key);

  @override
  State<DeviceContactsScreen> createState() => _DeviceContactsScreenState();
}

class _DeviceContactsScreenState extends State<DeviceContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize the contacts provider when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contactsProvider = Provider.of<ContactsProvider>(context, listen: false);
      contactsProvider.loadContacts(context);
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contacts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'APP CONTACTS'),
            Tab(text: 'PHONE CONTACTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, Constants.addContactScreen);
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'blocked',
                child: Text('Blocked contacts'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
            ],
            onSelected: (value) {
              if (value == 'blocked') {
                Navigator.pushNamed(context, Constants.blockedContactsScreen);
              } else if (value == 'refresh') {
                Provider.of<ContactsProvider>(context, listen: false)
                    .loadContacts(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // App Contacts Tab
                _buildAppContactsTab(),
                
                // Phone Contacts Tab
                _buildPhoneContactsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, Constants.addContactScreen)
              .then((_) {
                // Refresh contacts after returning from add screen
                Provider.of<ContactsProvider>(context, listen: false)
                    .loadContacts(context);
              });
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildAppContactsTab() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final filteredContacts = provider.appContacts
            .where((contact) => 
                contact.name.toLowerCase().contains(_searchQuery) ||
                contact.phoneNumber.toLowerCase().contains(_searchQuery))
            .toList();
        
        if (filteredContacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
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
                  'Add contacts to start chatting',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, Constants.addContactScreen);
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add New Contact'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = filteredContacts[index];
            return ContactWidget(
              contact: contact,
              viewType: ContactViewType.contacts,
            );
          },
        );
      },
    );
  }
  
  Widget _buildPhoneContactsTab() {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!provider.hasPermission) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.perm_contact_cal,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Contact permission needed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We need access to your contacts to find your friends',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await provider.requestContactsPermission();
                    if (provider.hasPermission) {
                      provider.loadContacts(context);
                    }
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }
        
        // Filter registered contacts based on search
        final filteredRegisteredContacts = provider.registeredContacts
            .where((contact) => 
                contact.name.toLowerCase().contains(_searchQuery) ||
                contact.phoneNumber.toLowerCase().contains(_searchQuery))
            .toList();
        
        if (filteredRegisteredContacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No contacts found on the app',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We couldn\'t find any of your contacts using the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: filteredRegisteredContacts.length,
          itemBuilder: (context, index) {
            final contact = filteredRegisteredContacts[index];
            return ListTile(
              leading: userImageWidget(
                imageUrl: contact.image,
                radius: 24,
                onTap: () {},
              ),
              title: Text(contact.name),
              subtitle: Text(contact.phoneNumber),
              trailing: ElevatedButton(
                onPressed: () {
                  provider.addRegisteredContact(contact, context);
                },
                child: const Text('Add'),
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Constants.profileScreen,
                  arguments: contact.uid,
                );
              },
            );
          },
        );
      },
    );
  }
}

// Update your main.dart to include the ContactsProvider
// MultiProvider(
//   providers: [
//     ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
//     ChangeNotifierProvider(create: (_) => ChatProvider()),
//     ChangeNotifierProvider(create: (_) => GroupProvider()),
//     ChangeNotifierProvider(create: (_) => StatusProvider()),
//     ChangeNotifierProvider(create: (_) => ContactsProvider()),  // Add this line
//   ],
//   child: MyApp(savedThemeMode: savedThemeMode),
// ),