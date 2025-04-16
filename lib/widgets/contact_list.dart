import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/widgets/contact_widget.dart';

class ContactList extends StatefulWidget {
  const ContactList({
    super.key,
    required this.viewType,
    this.groupId = '',
    this.groupMembersUIDs = const [],
    this.searchQuery = '',
  });

  final ContactViewType viewType;
  final String groupId;
  final List<String> groupMembersUIDs;
  final String searchQuery;

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;

    final future = widget.viewType == ContactViewType.contacts
        ? context.read<AuthenticationProvider>().getContactsList(
              uid,
              widget.groupMembersUIDs,
            )
        : widget.viewType == ContactViewType.blocked
            ? context.read<AuthenticationProvider>().getBlockedContactsList(
                  uid: uid,
                )
            : context.read<AuthenticationProvider>().getContactsList(
                  uid,
                  widget.groupMembersUIDs,
                );

    return FutureBuilder<List<UserModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.viewType == ContactViewType.contacts
                      ? Icons.person_outline
                      : Icons.block,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.viewType == ContactViewType.contacts
                      ? "No contacts yet"
                      : "No blocked contacts",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.viewType == ContactViewType.contacts
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

        // Filter contacts by search query if provided
        final List<UserModel> filteredContacts = widget.searchQuery.isEmpty
            ? snapshot.data!
            : snapshot.data!
                .where((contact) => contact.name
                    .toLowerCase()
                    .contains(widget.searchQuery.toLowerCase()))
                .toList();

        if (filteredContacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  "No matching contacts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try a different search term",
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
              viewType: widget.viewType,
              groupId: widget.groupId,
            );
          },
        );
      },
    );
  }
}