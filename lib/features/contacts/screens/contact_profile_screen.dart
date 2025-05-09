import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  const ContactProfileScreen({super.key});

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // get user data from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final authNotifier = ref.read(authenticationProvider.notifier);
              if (value == 'block') {
                // Show confirmation dialog
                bool confirmed = await _showBlockConfirmation(context);
                if (confirmed) {
                  await authNotifier.blockContact(contactID: uid);
                  showSnackBar(context, 'User has been blocked');
                  Navigator.pop(context);
                }
              } else if (value == 'remove') {
                // Show confirmation dialog
                bool confirmed = await _showRemoveConfirmation(context);
                if (confirmed) {
                  await authNotifier.removeContact(contactID: uid);
                  showSnackBar(context, 'Contact has been removed');
                }
              } else if (value == 'unblock') {
                await authNotifier.unblockContact(contactID: uid);
                showSnackBar(context, 'User has been unblocked');
              }
            },
            itemBuilder: (BuildContext context) {
              final isBlocked = currentUser.blockedUIDs.contains(uid);
              final isContact = currentUser.contactsUIDs.contains(uid);
              
              return <PopupMenuEntry<String>>[
                if (isBlocked)
                  const PopupMenuItem<String>(
                    value: 'unblock',
                    child: Text('Unblock user'),
                  )
                else ...[
                  if (isContact)
                    const PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove from contacts'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'block',
                    child: Text('Block user'),
                  ),
                ],
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: ref.read(authenticationProvider.notifier).userStream(userID: uid),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userModel =
              UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          // Check relationship status
          final bool isBlocked = currentUser.blockedUIDs.contains(uid);
          final bool isContact = currentUser.contactsUIDs.contains(uid);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(userModel),
                  if (isBlocked) 
                    _buildBlockedBanner(uid),
                  
                  _buildContactActionButton(context, userModel, isContact),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(UserModel userModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                userImageWidget(
                  imageUrl: userModel.image,
                  radius: 50,
                  onTap: () {},
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Phone number removed for privacy
                      // Online status indicator removed for privacy
                    ],
                  ),
                ),
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              height: 32,
            ),
            const Text(
              'About Me',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userModel.aboutMe.isEmpty ? 'No about information provided' : userModel.aboutMe,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedBanner(String uid) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.red),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You have blocked this user',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final authNotifier = ref.read(authenticationProvider.notifier);
              await authNotifier.unblockContact(contactID: uid);
              showSnackBar(context, 'User has been unblocked');
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActionButton(BuildContext context, UserModel userModel, bool isContact) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final authNotifier = ref.read(authenticationProvider.notifier);
          if (isContact) {
            // Show confirmation dialog
            bool confirmed = await _showRemoveConfirmation(context);
            if (confirmed) {
              await authNotifier.removeContact(contactID: userModel.uid);
              showSnackBar(context, 'Contact has been removed');
            }
          } else {
            // Add contact
            await authNotifier.addContact(contactID: userModel.uid);
            showSnackBar(context, '${userModel.name} added to your contacts');
          }
        },
        icon: Icon(isContact ? Icons.person_remove : Icons.person_add),
        label: Text(isContact ? 'Remove from Contacts' : 'Add to Contacts'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isContact ? Colors.red : null,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<bool> _showBlockConfirmation(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'When you block someone, they won\'t be able to message you or see your status updates. Are you sure you want to block this user?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              result = true;
              Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result;
  }

  Future<bool> _showRemoveConfirmation(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text(
          'Are you sure you want to remove this person from your contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              result = true;
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result;
  }
}