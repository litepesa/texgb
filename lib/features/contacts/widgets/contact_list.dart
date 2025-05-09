import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/contacts/contacts_provider.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/contacts/widgets/contact_widget.dart';

class ContactList extends ConsumerWidget {
  const ContactList({
    super.key,
    required this.viewType,
    this.searchQuery = '',
  });

  final ContactViewType viewType;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isContactsLoadingProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Center(child: Text("You must be logged in to view contacts"));
    }
    
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Use the appropriate provider based on view type
    List<UserModel> contacts;
    if (viewType == ContactViewType.contacts) {
      contacts = ref.watch(appContactsProvider);
    } else if (viewType == ContactViewType.blocked) {
      // For blocked contacts, we need to get them from the auth provider
      // since we don't have a separate provider for blocked contacts
      // This will cause a UI refresh, but it's a less common use case
      return FutureBuilder<List<UserModel>>(
        future: ref.read(authenticationProvider.notifier).getBlockedContactsList(
              uid: currentUser.uid,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          return _buildContactList(snapshot.data ?? [], context);
        },
      );
    } else {
      // For other view types, just use app contacts for now
      contacts = ref.watch(appContactsProvider);
    }
    
    return _buildContactList(contacts, context);
  }
  
  Widget _buildContactList(List<UserModel> contacts, BuildContext context) {
    // Filter contacts by search query if provided
    final List<UserModel> filteredContacts = searchQuery.isEmpty
        ? contacts
        : contacts
            .where((contact) => contact.name
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();

    if (filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              viewType == ContactViewType.contacts
                  ? Icons.person_outline
                  : Icons.block,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              viewType == ContactViewType.contacts
                  ? "No contacts yet"
                  : "No blocked contacts",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewType == ContactViewType.contacts
                  ? "Add contacts to start chatting"
                  : "Blocked contacts will appear here",
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
        return ContactWidget(
          contact: contact,
          viewType: viewType,
        );
      },
    );
  }
}