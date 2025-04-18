import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/group_provider.dart';
import 'package:textgb/utilities/global_methods.dart';

class ContactWidget extends StatelessWidget {
  const ContactWidget({
    super.key,
    required this.contact,
    required this.viewType,
    this.isAdminView = false,
    this.groupId = '',
  });

  final UserModel contact;
  final ContactViewType viewType;
  final bool isAdminView;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthenticationProvider>().userModel!;
    final name = currentUser.uid == contact.uid ? 'You' : contact.name;
    
    // For group view, check if contact is in members or admins list
    bool isSelected = false;
    if (viewType == ContactViewType.groupView) {
      isSelected = isAdminView
          ? context.watch<GroupProvider>().groupAdminsList.contains(contact)
          : context.watch<GroupProvider>().groupMembersList.contains(contact);
    }

    return ListTile(
      minLeadingWidth: 0.0,
      contentPadding: const EdgeInsets.only(left: 4.0, right: 4.0),
      leading:
          userImageWidget(imageUrl: contact.image, radius: 24, onTap: () {}),
      title: Text(name),
      subtitle: Text(
        contact.aboutMe,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _buildTrailingWidget(context, isSelected),
      onTap: () {
        _handleTap(context);
      },
      onLongPress: viewType == ContactViewType.contacts
          ? () => _showContactActions(context)
          : null,
    );
  }

  Widget _buildTrailingWidget(BuildContext context, bool isSelected) {
    switch (viewType) {
      case ContactViewType.contacts:
        return IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            // Navigate to chat screen with contact
            Navigator.pushNamed(context, Constants.chatScreen, arguments: {
              Constants.contactUID: contact.uid,
              Constants.contactName: contact.name,
              Constants.contactImage: contact.image,
              Constants.groupId: '',
            });
          },
        );
      case ContactViewType.blocked:
        return TextButton(
          onPressed: () async {
            final authProvider = context.read<AuthenticationProvider>();
            await authProvider.unblockContact(contactID: contact.uid);
            showSnackBar(context, '${contact.name} has been unblocked');
          },
          child: const Text('Unblock'),
        );
      case ContactViewType.groupView:
        return Checkbox(
          value: isSelected,
          onChanged: (value) {
            // Check the checkbox
            if (isAdminView) {
              if (value == true) {
                context
                    .read<GroupProvider>()
                    .addMemberToAdmins(groupAdmin: contact);
              } else {
                context
                    .read<GroupProvider>()
                    .removeGroupAdmin(groupAdmin: contact);
              }
            } else {
              if (value == true) {
                context
                    .read<GroupProvider>()
                    .addMemberToGroup(groupMember: contact);
              } else {
                context
                    .read<GroupProvider>()
                    .removeGroupMember(groupMember: contact);
              }
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleTap(BuildContext context) {
    switch (viewType) {
      case ContactViewType.contacts:
        // Navigate to profile screen
        Navigator.pushNamed(
          context,
          Constants.profileScreen,
          arguments: contact.uid,
        );
        break;
      case ContactViewType.blocked:
        // Navigate to profile screen
        Navigator.pushNamed(
          context,
          Constants.profileScreen,
          arguments: contact.uid,
        );
        break;
      case ContactViewType.groupView:
        if (groupId.isNotEmpty) {
          // Navigate to profile screen
          Navigator.pushNamed(
            context,
            Constants.profileScreen,
            arguments: contact.uid,
          );
        }
        break;
      default:
        break;
    }
  }

  void _showContactActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Message'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Constants.chatScreen, arguments: {
                    Constants.contactUID: contact.uid,
                    Constants.contactName: contact.name,
                    Constants.contactImage: contact.image,
                    Constants.groupId: '',
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    Constants.profileScreen,
                    arguments: contact.uid,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block Contact', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Contact', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Contact'),
        content: Text(
          'Are you sure you want to block ${contact.name}? They will not be able to message you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthenticationProvider>();
              await authProvider.blockContact(contactID: contact.uid);
              showSnackBar(context, '${contact.name} has been blocked');
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
          'Are you sure you want to remove ${contact.name} from your contacts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthenticationProvider>();
              await authProvider.removeContact(contactID: contact.uid);
              showSnackBar(context, '${contact.name} has been removed from your contacts');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}