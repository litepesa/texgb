import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';
import 'package:textgb/widgets/contact_list.dart';
import 'package:textgb/providers/authentication_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('Contacts'),
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
            ],
            onSelected: (value) {
              if (value == 'blocked') {
                Navigator.pushNamed(context, Constants.blockedContactsScreen);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar
            CupertinoSearchTextField(
              placeholder: 'Search',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            // Contact list
            Expanded(
              child: ContactList(
                viewType: ContactViewType.contacts,
                searchQuery: _searchQuery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}