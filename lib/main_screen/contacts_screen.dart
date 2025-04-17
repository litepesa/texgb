import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';

// Import the new ContactsProvider (you'll need to create this file)
// This would typically be in lib/providers/contacts_provider.dart
import 'package:textgb/providers/contacts_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
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
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Navigate to the new device contacts screen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const DeviceContactsScreen(),
              ));
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
                child: Text('Refresh contacts'),
              ),
            ],
            onSelected: (value) {
              if (value == 'blocked') {
                Navigator.pushNamed(context, Constants.blockedContactsScreen);
              } else if (value == 'refresh') {
                // Refresh the contacts using the provider
                context.read<ContactsProvider>().loadContacts(context);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ContactsProvider>(
          builder: (context, contactsProvider, child) {
            if (contactsProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final appContacts = contactsProvider.appContacts;
            
            if (appContacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No contacts yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add contacts to start chatting',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DeviceContactsScreen(),
                        ));
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Contacts'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                // Optional: Search box for filtering contacts
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) {
                      // Implement search functionality here
                    },
                  ),
                ),
                
                // Contact suggestions section (favorites or frequent)
                if (appContacts.length > 3) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Frequent Contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: appContacts.length > 5 ? 5 : appContacts.length,
                      itemBuilder: (context, index) {
                        final contact = appContacts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
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
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: contact.image.isNotEmpty
                                      ? NetworkImage(contact.image)
                                      : null,
                                  child: contact.image.isEmpty
                                      ? Text(
                                          contact.name[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 24),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                contact.name,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(),
                ],
                
                // All contacts list
                Expanded(
                  child: ListView.builder(
                    itemCount: appContacts.length,
                    itemBuilder: (context, index) {
                      final contact = appContacts[index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: contact.image.isNotEmpty
                              ? NetworkImage(contact.image)
                              : null,
                          child: contact.image.isEmpty
                              ? Text(contact.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(contact.name),
                        subtitle: Text(
                          contact.aboutMe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
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
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Constants.profileScreen,
                            arguments: contact.uid,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const DeviceContactsScreen(),
          ));
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}