import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';

class BlockedContactsScreen extends StatefulWidget {
  const BlockedContactsScreen({super.key});

  @override
  State<BlockedContactsScreen> createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
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

    final authProvider = context.read<AuthenticationProvider>();
    final blockedContacts = await authProvider.getBlockedContactsList(
      uid: authProvider.uid!,
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
              final authProvider = context.read<AuthenticationProvider>();
              await authProvider.unblockContact(contactID: contact.uid);
              
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