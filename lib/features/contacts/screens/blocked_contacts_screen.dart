import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class BlockedContactsScreen extends ConsumerStatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  ConsumerState<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends ConsumerState<BlockedContactsScreen> {
  bool _isLoading = true;
  List<UserModel> _blockedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedContacts();
  }

  Future<void> _loadBlockedContacts() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final authNotifier = ref.read(authenticationProvider.notifier);
    final blockedContacts = await authNotifier.getBlockedContactsList(
      uid: currentUser.uid,
    );

    setState(() {
      _blockedContacts = blockedContacts;
      _isLoading = false;
    });
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
        title: const Text('Blocked Contacts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedContacts.isEmpty
              ? _buildEmptyState()
              : _buildContactsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No blocked contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contacts you block will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _blockedContacts.length,
      itemBuilder: (context, index) {
        final contact = _blockedContacts[index];
        return ListTile(
          leading: userImageWidget(
            imageUrl: contact.image,
            radius: 20,
            onTap: () {},
          ),
          title: Text(contact.name),
          subtitle: Text(contact.phoneNumber),
          trailing: TextButton(
            onPressed: () async {
              final authNotifier = ref.read(authenticationProvider.notifier);
              await authNotifier.unblockContact(contactID: contact.uid);
              
              // Refresh the list
              setState(() {
                _blockedContacts.removeAt(index);
              });
              
              showSnackBar(context, '${contact.name} has been unblocked');
            },
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}