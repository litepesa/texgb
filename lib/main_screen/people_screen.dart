import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // cupertino search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                placeholder: 'Search by name',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // list of users
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: context
                    .read<AuthenticationProvider>()
                    .getAllUsersStream(userID: currentUser.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No users found',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2),
                      ),
                    );
                  }

                  // Filter users by search query if provided
                  final users = _searchQuery.isEmpty
                      ? snapshot.data!.docs
                      : snapshot.data!.docs.where((doc) {
                          final name = (doc.data() as Map<String, dynamic>)[Constants.name].toString().toLowerCase();
                          return name.contains(_searchQuery.toLowerCase());
                        }).toList();

                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'No users matching "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      
                      // Check if user is already in contacts
                      final isContact = currentUser.contactsUIDs.contains(userId);
                      final isBlocked = currentUser.blockedUIDs.contains(userId);

                      return ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(0.7),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: userImageWidget(
                              imageUrl: userData[Constants.image],
                              radius: 24,
                              onTap: () {},
                            ),
                          ),
                        ),
                        title: Text(userData[Constants.name]),
                        subtitle: Text(
                          userData[Constants.aboutMe],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isBlocked
                          ? TextButton(
                              onPressed: () async {
                                await context.read<AuthenticationProvider>().unblockContact(contactID: userId);
                                showSnackBar(context, 'User unblocked');
                              },
                              child: const Text('Unblock'),
                            )
                          : isContact
                            ? IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () {
                                  // Navigate to chat
                                  Navigator.pushNamed(
                                    context,
                                    Constants.chatScreen,
                                    arguments: {
                                      Constants.contactUID: userId,
                                      Constants.contactName: userData[Constants.name],
                                      Constants.contactImage: userData[Constants.image],
                                      Constants.groupId: '',
                                    },
                                  );
                                },
                              )
                            : TextButton(
                                onPressed: () async {
                                  await context.read<AuthenticationProvider>().addContact(contactID: userId);
                                  showSnackBar(context, 'Contact added');
                                },
                                child: const Text('Add'),
                              ),
                        onTap: () {
                          // navigate to this user's profile screen
                          Navigator.pushNamed(
                            context,
                            Constants.profileScreen,
                            arguments: userId,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}