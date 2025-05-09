import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize and sync contacts when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContacts();
    });
  }
  
  Future<void> _initializeContacts() async {
    final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
    
    // Check permission status
    if (!ref.read(hasContactsPermissionProvider)) {
      await contactsNotifier.requestContactsPermission();
    }
    
    // Load contacts if we have permission
    if (ref.read(hasContactsPermissionProvider)) {
      await contactsNotifier.loadContacts();
    }
  }
  
  Future<void> _refreshContacts() async {
    final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
    await contactsNotifier.syncContacts();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the background color of the scaffold
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final isRefreshing = ref.watch(isContactsSyncingProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : _refreshContacts,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'blocked',
                child: Text('Blocked contacts'),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Text('Sync all contacts'),
              ),
            ],
            onSelected: (value) {
              if (value == 'blocked') {
                Navigator.pushNamed(context, Constants.blockedContactsScreen);
              } else if (value == 'sync') {
                _showSyncConfirmation(context);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CONTACTS'),
            Tab(text: 'SUGGESTIONS'),
          ],
        ),
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
          
          // Contact synchronization status
          Consumer(
            builder: (context, ref, child) {
              final isSyncing = ref.watch(isContactsSyncingProvider);
              
              if (isSyncing) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Syncing contacts...'),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Contacts Tab
                _buildContactsTab(),
                
                // Suggestions Tab
                _buildSuggestionsTab(),
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
                ref.read(contactsNotifierProvider.notifier).loadContacts();
              });
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildContactsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(isContactsLoadingProvider);
        final hasPermission = ref.watch(hasContactsPermissionProvider);
        final appContacts = ref.watch(appContactsProvider);
        
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!hasPermission) {
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
                const Text(
                  'Please allow access to your contacts to see\nwho is on TexGB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(contactsNotifierProvider.notifier).requestContactsPermission();
                    if (ref.read(hasContactsPermissionProvider)) {
                      await ref.read(contactsNotifierProvider.notifier).loadContacts();
                    }
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }
        
        final filteredContacts = appContacts
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
                  'No contacts yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty
                      ? 'Check the Suggestions tab to see\nwho from your contacts is using TexGB'
                      : 'No contacts matching "$_searchQuery"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = filteredContacts[index];
            return _buildContactTile(contact);
          },
        );
      },
    );
  }
  
  Widget _buildSuggestionsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(isContactsLoadingProvider);
        final hasPermission = ref.watch(hasContactsPermissionProvider);
        final suggestedContacts = ref.watch(suggestedContactsProvider);
        
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!hasPermission) {
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
                const Text(
                  'Please allow access to your contacts to see\nsuggestions based on your address book',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(contactsNotifierProvider.notifier).requestContactsPermission();
                    if (ref.read(hasContactsPermissionProvider)) {
                      await ref.read(contactsNotifierProvider.notifier).loadContacts();
                    }
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }
        
        final filteredSuggestions = suggestedContacts
            .where((contact) => 
                contact.name.toLowerCase().contains(_searchQuery) ||
                contact.phoneNumber.toLowerCase().contains(_searchQuery))
            .toList();
        
        if (filteredSuggestions.isEmpty) {
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
                  'No suggestions found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We couldn\'t find any of your contacts\nusing TexGB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _refreshContacts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // Add All button
            if (filteredSuggestions.length > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: ref.watch(isContactsLoadingProvider) 
                    ? null 
                    : () => _addAllSuggestedContacts(context),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add All Contacts'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            
            // List of suggested contacts
            Expanded(
              child: ListView.builder(
                itemCount: filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final contact = filteredSuggestions[index];
                  return _buildSuggestionTile(contact);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildContactTile(UserModel contact) {
    // Use a container with the background color matching the scaffold
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: userImageWidget(
          imageUrl: contact.image,
          radius: 24,
          onTap: () {},
        ),
        title: Text(contact.name),
        subtitle: Text(
          contact.phoneNumber,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        // Remove trailing elements (message icon)
        // But keep the original onTap behavior
        onTap: () {
          // Navigate to chat screen on tap (original functionality)
          Navigator.pushNamed(
            context,
            Constants.chatScreen,
            arguments: {
              Constants.contactUID: contact.uid,
              Constants.contactName: contact.name,
              Constants.contactImage: contact.image,
              Constants.groupId: '',
            },
          );
        },
      ),
    );
  }
  
  Widget _buildSuggestionTile(UserModel contact) {
    // Use a container with the background color matching the scaffold
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: userImageWidget(
          imageUrl: contact.image,
          radius: 24,
          onTap: () {},
        ),
        title: Text(contact.name),
        subtitle: Text(
          contact.phoneNumber,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: () => _addSuggestedContact(context, contact),
        ),
        // Original behavior - navigate to profile
        onTap: () {
          Navigator.pushNamed(
            context,
            Constants.contactProfileScreen,
            arguments: contact.uid,
          );
        },
      ),
    );
  }
  
  Future<void> _addSuggestedContact(BuildContext context, UserModel contact) async {
    await ref.read(contactsNotifierProvider.notifier).addSuggestedContact(contact);
    showSnackBar(context, '${contact.name} added to your contacts');
  }
  
  Future<void> _addAllSuggestedContacts(BuildContext context) async {
    await ref.read(contactsNotifierProvider.notifier).addAllSuggestedContacts();
    showSnackBar(context, 'All contacts synchronized successfully');
  }
  
  void _showSyncConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync All Contacts'),
        content: const Text(
          'This will add all suggested contacts from your phone to your TexGB contacts list. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addAllSuggestedContacts(context);
            },
            child: const Text('Sync All'),
          ),
        ],
      ),
    );
  }}