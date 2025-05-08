import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({
    super.key,
    required this.userModel,
    this.onTap,
    this.showActions = true,
  });

  final UserModel userModel;
  final Function()? onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final bool isCurrentUser = currentUser.uid == userModel.uid;
    final bool isContact = currentUser.contactsUIDs.contains(userModel.uid);
    final bool isBlocked = currentUser.blockedUIDs.contains(userModel.uid);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap ?? () {
          // Route to the appropriate profile screen based on whether it's current user or not
          if (isCurrentUser) {
            Navigator.pushNamed(
              context,
              Constants.myProfileScreen, // Use MyProfileScreen for current user
            );
          } else {
            Navigator.pushNamed(
              context,
              Constants.contactProfileScreen, // Use ContactProfileScreen for other users
              arguments: userModel.uid,
            );
          }
        },
        child: Column(
          children: [
            // User header with image and name
            ListTile(
              leading: userImageWidget(
                imageUrl: userModel.image,
                radius: 24,
                onTap: () {},
              ),
              title: Text(
                isCurrentUser ? '${userModel.name} (You)' : userModel.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                userModel.aboutMe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isBlocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Blocked',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            
            // Removed online status indicator for privacy
            // Removed phone number display for privacy

            // Action buttons - No direct message option for privacy
            if (showActions && !isCurrentUser)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (isBlocked)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context
                                .read<AuthenticationProvider>()
                                .unblockContact(contactID: userModel.uid);
                            showSnackBar(
                                context, '${userModel.name} has been unblocked');
                          },
                          icon: const Icon(Icons.block),
                          label: const Text('Unblock'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      )
                    else ...[
                      // Removed message button for privacy
                      // Only show add/remove contact button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (isContact) {
                              // Show confirmation dialog
                              bool confirmed =
                                  await _showRemoveConfirmation(context);
                              if (confirmed) {
                                await context
                                    .read<AuthenticationProvider>()
                                    .removeContact(contactID: userModel.uid);
                                showSnackBar(context,
                                    '${userModel.name} removed from contacts');
                              }
                            } else {
                              await context
                                  .read<AuthenticationProvider>()
                                  .addContact(contactID: userModel.uid);
                              showSnackBar(context,
                                  '${userModel.name} added to contacts');
                            }
                          },
                          icon: Icon(
                              isContact ? Icons.person_remove : Icons.person_add),
                          label: Text(isContact ? 'Remove' : 'Add Contact'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isContact ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showRemoveConfirmation(BuildContext context) async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
          'Are you sure you want to remove ${userModel.name} from your contacts?',
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