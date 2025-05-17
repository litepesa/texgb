// lib/features/contacts/screens/contacts_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/contacts/screens/add_contact_screen.dart';
import 'package:textgb/features/contacts/screens/blocked_contacts_screen.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize contacts data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeContacts();
    });
  }

  // Load contacts with smart sync logic
  Future<void> _initializeContacts() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      
      // First try to load cached contacts - this will be fast
      await ref.read(contactsNotifierProvider.future);
      
      // Check if we need to sync
      final syncNeeded = await contactsNotifier.checkSyncStatus();
      
      if (syncNeeded) {
        // Only sync if needed
        await contactsNotifier.syncContacts(forceSync: false);
      }
      
      // Always load blocked contacts
      await contactsNotifier.loadBlockedContacts();
    } catch (e) {
      // Error handling
      debugPrint('Error initializing contacts: $e');
      if (mounted) {
        showSnackBar(context, 'Error loading contacts: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  // Force sync contacts with server
  Future<void> _forceSyncContacts() async {
    if (mounted) {
      showSnackBar(context, 'Syncing contacts...');
    }
    
    try {
      final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
      await contactsNotifier.syncContacts(forceSync: true);
      
      if (mounted) {
        showSnackBar(context, 'Contacts synced successfully');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error syncing contacts: $e');
      }
    }
  }
  
  // Start a chat with a contact
  void _startChatWithContact(UserModel contact) async {
    try {
      // Get the chat ID for this contact
      final chatNotifier = ref.read(chatProvider.notifier);
      final chatId = chatNotifier.getChatIdForContact(contact.uid);
      
      // Create a new chat or open existing chat
      await chatNotifier.createChat(contact);
      
      // Navigate to chat screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          Constants.chatScreen,
          arguments: {
            'chatId': chatId,
            'contact': contact,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error starting chat: $e');
      }
    }
  }

  // Build sync status indicator
  Widget _buildSyncStatus(DateTime? lastSyncTime, SyncStatus syncStatus) {
    if (lastSyncTime != null) {
      final formatter = DateFormat('MMM d, h:mm a');
      final syncTime = formatter.format(lastSyncTime);
      
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync, 
              size: 12, 
              color: syncStatus == SyncStatus.upToDate 
                  ? Colors.green 
                  : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              'Last synced: $syncTime',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? _buildSearchField()
          : const Text('Contacts'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _forceSyncContacts();
                  break;
                case 'blocked':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedContactsScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact settings coming soon'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: const [
                    Icon(Icons.sync),
                    SizedBox(width: 10),
                    Text('Sync contacts'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'blocked',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 10),
                    Text('Blocked contacts'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 10),
                    Text('Contact settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Invites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(),
          _buildInvitesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddContactScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search contacts...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildContactsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final contactsState = ref.watch(contactsNotifierProvider);
        
        return contactsState.when(
          data: (state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _forceSyncContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final contacts = state.registeredContacts;
            
            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.person_2,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No contacts found',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _forceSyncContacts,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Contacts'),
                    ),
                  ],
                ),
              );
            }
            
            // Filter contacts by search query
            final filteredContacts = _searchQuery.isEmpty
                ? contacts
                : contacts.where((contact) => 
                    contact.name.toLowerCase().contains(_searchQuery) ||
                    contact.phoneNumber.toLowerCase().contains(_searchQuery))
                    .toList();
            
            return RefreshIndicator(
              onRefresh: _forceSyncContacts,
              child: Column(
                children: [
                  // Show sync status at top
                  if (state.lastSyncTime != null)
                    _buildSyncStatus(state.lastSyncTime, state.syncStatus),
                  
                  // Contacts list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return _buildContactItem(contact);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _forceSyncContacts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final contactsState = ref.watch(contactsNotifierProvider);
        
        return contactsState.when(
          data: (state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _forceSyncContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final contacts = state.unregisteredContacts;
            
            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.person_badge_plus,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No contacts to invite',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _forceSyncContacts,
                      icon: const Icon(Icons.sync),
                      label: const Text('Refresh Contacts'),
                    ),
                  ],
                ),
              );
            }
            
            // Filter contacts by search query
            final filteredContacts = _searchQuery.isEmpty
                ? contacts
                : contacts.where((contact) => 
                    contact.displayName.toLowerCase().contains(_searchQuery) ||
                    contact.phones.any((phone) => 
                        phone.number.toLowerCase().contains(_searchQuery)))
                    .toList();
            
            return RefreshIndicator(
              onRefresh: _forceSyncContacts,
              child: Column(
                children: [
                  // Show sync status at top
                  if (state.lastSyncTime != null)
                    _buildSyncStatus(state.lastSyncTime, state.syncStatus),
                  
                  // Unregistered contacts list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return _buildInviteItem(contact);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _forceSyncContacts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactItem(UserModel contact) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return ListTile(
      leading: userImageWidget(
        imageUrl: contact.image,
        radius: 24,
        onTap: () {
          // View profile
        },
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(contact.phoneNumber),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble_text),
            onPressed: () {
              // Start new chat with contact
              _startChatWithContact(contact);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'block':
                  await ref.read(contactsNotifierProvider.notifier)
                      .blockContact(contact);
                  if (mounted) {
                    showSnackBar(context, 'Contact blocked');
                  }
                  break;
                case 'remove':
                  await ref.read(contactsNotifierProvider.notifier)
                      .removeContact(contact);
                  if (mounted) {
                    showSnackBar(context, 'Contact removed');
                  }
                  break;
                case 'info':
                  // Navigate to contact info screen
                  if (mounted) {
                    Navigator.pushNamed(
                      context, 
                      Constants.contactProfileScreen,
                      arguments: contact,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Text('Contact info'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block),
                    SizedBox(width: 10),
                    Text('Block contact'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 10),
                    Text('Remove contact'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () {
        // Navigate to chat or contact info based on preference
        // For now, start a chat
        _startChatWithContact(contact);
      },
    );
  }

  Widget _buildInviteItem(Contact contact) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    final primaryColor = modernTheme.primaryColor!;
    
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          contact.displayName.isNotEmpty ? contact.displayName[0] : '?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark 
                ? Colors.black54 
                : Colors.white,
          ),
        ),
      ),
      title: Text(
        contact.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        contact.phones.isNotEmpty 
            ? contact.phones.first.number 
            : 'No phone number',
      ),
      trailing: ElevatedButton(
        onPressed: () async {
          final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
          final message = contactsNotifier.generateInviteMessage();
          
          try {
            await Share.share(
              message,
              subject: 'Join me on TexGB!',
            );
          } catch (e) {
            if (mounted) {
              showSnackBar(context, 'Failed to share invitation: $e');
            }
          }
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text('Invite'),
      ),
      onTap: () {
        // Show contact details
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => _buildContactDetailsSheet(contact),
        );
      },
    );
  }

  Widget _buildContactDetailsSheet(Contact contact) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Name: ${contact.displayName}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...contact.phones.map((phone) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Phone: ${phone.number}',
              style: const TextStyle(fontSize: 16),
            ),
          )),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
                  final message = contactsNotifier.generateInviteMessage();
                  
                  try {
                    await Share.share(
                      message,
                      subject: 'Join me on TexGB!',
                    );
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      showSnackBar(context, 'Failed to share invitation: $e');
                    }
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Invite'),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}