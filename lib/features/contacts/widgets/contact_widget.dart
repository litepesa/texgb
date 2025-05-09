import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ContactWidget extends ConsumerWidget {
  const ContactWidget({
    super.key,
    required this.contact,
    required this.viewType,
  });

  final UserModel contact;
  final ContactViewType viewType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();
    
    final name = currentUser.uid == contact.uid ? 'You' : contact.name;

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
      trailing: _buildTrailingWidget(context, ref),
      onTap: () {
        _handleTap(context);
      },
      onLongPress: viewType == ContactViewType.contacts
          ? () => _showContactActions(context, ref)
          : null,
    );
  }

  Widget _buildTrailingWidget(BuildContext context, WidgetRef ref) {
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
            final authNotifier = ref.read(authenticationProvider.notifier);
            await authNotifier.unblockContact(contactID: contact.uid);
            showSnackBar(context, '${contact.name} has been unblocked');
          },
          child: const Text('Unblock'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleTap(BuildContext context) {
    switch (viewType) {
      case ContactViewType.contacts:
      case ContactViewType.blocked:
        // Navigate to profile screen
        Navigator.pushNamed(
          context,
          Constants.contactProfileScreen,
          arguments: contact.uid,
        );
        break;
      default:
        break;
    }
  }

  void _showContactActions(BuildContext context, WidgetRef ref) {
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
                    Constants.contactProfileScreen,
                    arguments: contact.uid,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block Contact', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Contact', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBlockConfirmation(BuildContext context, WidgetRef ref) {
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
              final authNotifier = ref.read(authenticationProvider.notifier);
              await authNotifier.blockContact(contactID: contact.uid);
              showSnackBar(context, '${contact.name} has been blocked');
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
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
              final authNotifier = ref.read(authenticationProvider.notifier);
              await authNotifier.removeContact(contactID: contact.uid);
              showSnackBar(context, '${contact.name} has been removed from your contacts');
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}