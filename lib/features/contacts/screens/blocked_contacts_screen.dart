import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class BlockedContactsScreen extends ConsumerStatefulWidget {
  const BlockedContactsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends ConsumerState<BlockedContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedContacts();
  }

  Future<void> _loadBlockedContacts() async {
    final contactsNotifier = ref.read(contactsNotifierProvider.notifier);
    await contactsNotifier.loadBlockedContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? _buildSearchField()
          : const Text('Blocked Contacts'),
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
        ],
      ),
      body: _buildBlockedContactsList(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search blocked contacts...',
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

  Widget _buildBlockedContactsList() {
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
                      onPressed: _loadBlockedContacts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            final blockedContacts = state.blockedContacts;
            
            if (blockedContacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.person_crop_circle_badge_xmark,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No blocked contacts',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contacts you block will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Filter contacts by search query
            final filteredContacts = _searchQuery.isEmpty
                ? blockedContacts
                : blockedContacts.where((contact) => 
                    contact.name.toLowerCase().contains(_searchQuery) ||
                    contact.phoneNumber.toLowerCase().contains(_searchQuery))
                    .toList();
            
            return RefreshIndicator(
              onRefresh: _loadBlockedContacts,
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return _buildBlockedContactItem(contact);
                },
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
                  onPressed: _loadBlockedContacts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockedContactItem(UserModel contact) {
    final theme = Theme.of(context);
    final modernTheme = context.modernTheme;
    
    return ListTile(
      leading: userImageWidget(
        imageUrl: contact.image,
        radius: 24,
        onTap: () {},
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(contact.phoneNumber),
      trailing: TextButton(
        onPressed: () async {
          final confirmed = await _showUnblockConfirmationDialog(contact);
          
          if (confirmed && mounted) {
            try {
              await ref.read(contactsNotifierProvider.notifier)
                  .unblockContact(contact);
              if (mounted) {
                showSnackBar(context, 'Contact unblocked');
              }
            } catch (e) {
              if (mounted) {
                showSnackBar(context, 'Failed to unblock contact: $e');
              }
            }
          }
        },
        child: const Text('Unblock'),
      ),
    );
  }
  
  Future<bool> _showUnblockConfirmationDialog(UserModel contact) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock Contact'),
        content: Text(
          'Are you sure you want to unblock ${contact.name}?\n\n'
          'They will be able to send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}