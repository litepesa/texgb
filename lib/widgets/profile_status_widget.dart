import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ProfileStatusWidget extends StatelessWidget {
  const ProfileStatusWidget({
    Key? key,
    required this.userModel,
    required this.currentUser,
  }) : super(key: key);

  final UserModel userModel;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    // If viewing our own profile
    if (currentUser.uid == userModel.uid) {
      return const SizedBox.shrink();
    }

    // Check relationship status with the user
    final bool isContact = currentUser.contactsUIDs.contains(userModel.uid);
    final bool isBlocked = currentUser.blockedUIDs.contains(userModel.uid);

    if (isBlocked) {
      // Show unblock button for blocked contacts
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip('Blocked', Colors.red),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              final authProvider = context.read<AuthenticationProvider>();
              await authProvider.unblockContact(contactID: userModel.uid);
              showSnackBar(context, '${userModel.name} has been unblocked');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Unblock', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    } else if (isContact) {
      // Show contact status and action buttons for contacts
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip('Contact', Colors.green),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                Constants.chatScreen,
                arguments: {
                  Constants.contactUID: userModel.uid,
                  Constants.contactName: userModel.name,
                  Constants.contactImage: userModel.image,
                  Constants.groupId: '',
                },
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'Message',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      );
    } else {
      // Show add contact button for non-contacts
      return OutlinedButton.icon(
        onPressed: () async {
          final authProvider = context.read<AuthenticationProvider>();
          await authProvider.addContact(contactID: userModel.uid);
          showSnackBar(context, '${userModel.name} added to your contacts');
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Contact'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}